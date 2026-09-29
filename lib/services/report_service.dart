// =============================================================================
// خدمة التقارير (FR-23): ملخص الفترة، مقارنة 6 أشهر، توزيع حسب الفئات.
//
// ⚡ الأداء: كل التجميعات (SUM / GROUP BY) تتم داخل SQLite مستفيدة من
// الفهارس، ولا نجلب آلاف المعاملات إلى Dart لجمعها.
//
// يُحتسب (وثيقة الديون 5.5): الدخل والمصروف العاديان، البيع والشراء بالآجل،
// والمسامحة والإعفاء. لا يُحتسب: التحويلات، وحركات الديون النقدية (إقراض،
// اقتراض، استلام، سداد)، والتسويات (تُعرض في سطر مستقل «فروقات تسوية»).
// =============================================================================

import 'package:drift/drift.dart';

import '../core/utils/date_range.dart';
import '../data/database/app_database.dart';
import '../domain/enums.dart';
import '../domain/models/budget_report_models.dart';

class ReportService {
  ReportService(this.db);

  final AppDatabase db;

  static final _income = TxType.incomeNames.map((n) => "'$n'").join(', ');
  static final _expense = TxType.expenseNames.map((n) => "'$n'").join(', ');

  /// تقرير كامل لفترة — تفاعلي.
  Stream<PeriodReport> watchReport(DateRange range, {int months = 6}) =>
      db.watchTables({
        db.transactions,
        db.categories,
      }, () => report(range, months: months));

  Future<PeriodReport> report(DateRange range, {int months = 6}) async {
    final expense = await byCategory(range, CategoryKind.expense);
    final income = await byCategory(range, CategoryKind.income);
    return PeriodReport(
      range: range,
      income: income.fold(0, (s, c) => s + c.total),
      expense: expense.fold(0, (s, c) => s + c.total),
      adjustments: await adjustmentsTotal(range),
      months: await monthlyTotals(
        DateRange.lastMonths(
          months,
          now: range.end.subtract(const Duration(days: 1)),
        ),
      ),
      expenseByCategory: expense,
      incomeByCategory: income,
    );
  }

  /// «فروقات تسوية»: صافي معاملات التسوية في الفترة (موجب أو سالب).
  Future<int> adjustmentsTotal(DateRange range) async {
    final row = await db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions '
          'WHERE type = ?1 AND date >= ?2 AND date < ?3',
          variables: [
            Variable.withString(TxType.adjustment.name),
            Variable.withDateTime(range.start),
            Variable.withDateTime(range.end),
          ],
          readsFrom: {db.transactions},
        )
        .getSingle();
    return row.read<int>('total');
  }

  /// مجموع الدخل والمصروف لكل شهر في النطاق — استعلام واحد مجمّع بالشهر.
  /// الأشهر الخالية تظهر بقيمة صفر حتى يبقى المخطط متصلاً.
  Future<List<MonthTotals>> monthlyTotals(DateRange range) async {
    final rows = await db
        .customSelect(
          '''
      SELECT strftime('%Y-%m', date, 'unixepoch', 'localtime') AS ym,
        COALESCE(SUM(CASE WHEN type IN ($_income) THEN amount END), 0) AS income,
        COALESCE(SUM(CASE WHEN type IN ($_expense) THEN amount END), 0) AS expense
      FROM transactions
      WHERE date >= ?1 AND date < ?2
        AND type IN ($_income, $_expense)
      GROUP BY ym
      ''',
          variables: [
            Variable.withDateTime(range.start),
            Variable.withDateTime(range.end),
          ],
          readsFrom: {db.transactions},
        )
        .get();

    final byMonth = {
      for (final r in rows)
        r.read<String>('ym'): (r.read<int>('income'), r.read<int>('expense')),
    };
    final result = <MonthTotals>[];
    var cursor = DateTime(range.start.year, range.start.month);
    while (cursor.isBefore(range.end)) {
      final key =
          '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}';
      final v = byMonth[key];
      result.add(
        MonthTotals(month: cursor, income: v?.$1 ?? 0, expense: v?.$2 ?? 0),
      );
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return result;
  }

  /// توزيع الدخل أو المصروف حسب الفئات في فترة، مرتباً من الأكبر.
  Future<List<CategoryTotal>> byCategory(
    DateRange range,
    CategoryKind kind,
  ) async {
    final t = db.transactions;
    final sum = t.amount.sum();
    final types = kind == CategoryKind.income
        ? TxType.incomeNames
        : TxType.expenseNames;
    final rows =
        await (db.select(db.categories).join([
                innerJoin(t, t.categoryId.equalsExp(db.categories.id)),
              ])
              ..addColumns([sum])
              ..where(
                t.type.isIn(types) &
                    t.date.isBiggerOrEqualValue(range.start) &
                    t.date.isSmallerThanValue(range.end),
              )
              ..groupBy([db.categories.id])
              ..orderBy([OrderingTerm.desc(sum)]))
            .get();

    final total = rows.fold<int>(0, (s, r) => s + (r.read(sum) ?? 0));
    return [
      for (final r in rows)
        CategoryTotal(
          category: r.readTable(db.categories),
          total: r.read(sum) ?? 0,
          share: total == 0 ? 0 : (r.read(sum) ?? 0) / total,
        ),
    ];
  }
}
