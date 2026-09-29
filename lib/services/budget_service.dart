// =============================================================================
// خدمة الميزانية: سقف إنفاق شهري (أو أسبوعي) لكل فئة، مع تنبيه عند 75% و100%.
//
// المصروف المحسوب هنا هو معاملات «المصروف» فقط؛ حركات الديون والتسويات
// والتحويلات لا تدخل في الميزانية (قاعدة 3.12.4).
// =============================================================================

import 'package:drift/drift.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/date_range.dart';
import '../data/database/app_database.dart';
import '../domain/enums.dart';
import '../domain/models/budget_report_models.dart';
import '../domain/models/transaction_models.dart';

class BudgetService {
  BudgetService(this.db);

  final AppDatabase db;

  /// نطاق الفترة لميزانية حسب نوعها والتاريخ المرجعي.
  static DateRange rangeFor(BudgetPeriod period, DateTime ref) =>
      period == BudgetPeriod.monthly
      ? DateRange.month(ref)
      : DateRange.week(ref);

  /// إضافة ميزانية أو تحديثها إن كانت موجودة لنفس الفئة والفترة.
  Future<int> upsert({
    required int categoryId,
    required int limit,
    BudgetPeriod period = BudgetPeriod.monthly,
    int alertPercent = 75,
  }) async {
    if (limit <= 0) throw const BusinessException(BusinessError.invalidAmount);
    return db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            categoryId: categoryId,
            limitAmount: limit,
            period: period,
            alertPercent: Value(alertPercent),
          ),
          onConflict: DoUpdate(
            (old) => BudgetsCompanion(
              limitAmount: Value(limit),
              alertPercent: Value(alertPercent),
            ),
            target: [db.budgets.categoryId, db.budgets.period],
          ),
        );
  }

  Future<void> delete(int id) =>
      (db.delete(db.budgets)..where((b) => b.id.equals(id))).go();

  /// ملخص الميزانيات لشهر [month] — تفاعلي: يتحدث عند أي معاملة جديدة.
  Stream<BudgetOverview> watchOverview(DateTime month) => db.watchTables({
    db.budgets,
    db.categories,
    db.transactions,
  }, () => overview(month));

  Future<BudgetOverview> overview(DateTime month) async {
    final rows = await (db.select(db.budgets).join([
      innerJoin(
        db.categories,
        db.categories.id.equalsExp(db.budgets.categoryId),
      ),
    ])..orderBy([OrderingTerm.asc(db.categories.sortOrder)])).get();

    // نجمع المصروف لكل الفئات في استعلام واحد لكل نوع فترة
    // بدلاً من استعلام لكل ميزانية.
    final monthly = await spentByCategory(DateRange.month(month));
    final weekly = await spentByCategory(DateRange.week(DateTime.now()));

    final items = [
      for (final row in rows)
        () {
          final budget = row.readTable(db.budgets);
          final spentMap = budget.period == BudgetPeriod.monthly
              ? monthly
              : weekly;
          return BudgetProgress(
            budget: budget,
            category: row.readTable(db.categories),
            spent: spentMap[budget.categoryId] ?? 0,
          );
        }(),
    ];
    return BudgetOverview(range: DateRange.month(month), items: items);
  }

  /// مجموع المصروف لكل فئة في نطاق — استعلام GROUP BY واحد.
  Future<Map<int, int>> spentByCategory(DateRange range) async {
    final t = db.transactions;
    final sum = t.amount.sum();
    final rows =
        await (db.selectOnly(t)
              ..addColumns([t.categoryId, sum])
              ..where(
                // المصروف العادي والشراء بالآجل ومسامحة الديون.
                t.type.isIn(TxType.expenseNames) &
                    t.date.isBiggerOrEqualValue(range.start) &
                    t.date.isSmallerThanValue(range.end),
              )
              ..groupBy([t.categoryId]))
            .get();
    return {
      for (final r in rows)
        if (r.read(t.categoryId) != null)
          r.read(t.categoryId)!: r.read(sum) ?? 0,
    };
  }

  /// يُستدعى بعد حفظ مصروف: هل عبَر هذا المصروف حد التنبيه أو السقف؟
  ///
  /// [delta] هو التغير الذي أحدثته العملية في مصروف الفئة (المبلغ الجديد
  /// للإضافة، أو الفرق عند التعديل). يعيد التنبيه فقط لحظة «عبور» الحد
  /// حتى لا يزعج المستخدم بتنبيه مع كل مصروف لاحق.
  Future<BudgetAlertInfo?> check({
    required int categoryId,
    required DateTime date,
    required int delta,
  }) async {
    if (delta <= 0) return null;
    final rows = await (db.select(db.budgets).join([
      innerJoin(
        db.categories,
        db.categories.id.equalsExp(db.budgets.categoryId),
      ),
    ])..where(db.budgets.categoryId.equals(categoryId))).get();

    BudgetAlertInfo? worst;
    for (final row in rows) {
      final budget = row.readTable(db.budgets);
      final category = row.readTable(db.categories);
      final range = rangeFor(budget.period, date);
      final after = (await spentByCategory(range))[categoryId] ?? 0;
      final before = after - delta;
      final levelBefore = BudgetProgress.levelFor(
        budget.limitAmount == 0 ? 0 : before * 100 ~/ budget.limitAmount,
        budget.alertPercent,
      );
      final levelAfter = BudgetProgress.levelFor(
        budget.limitAmount == 0 ? 0 : after * 100 ~/ budget.limitAmount,
        budget.alertPercent,
      );
      if (levelAfter.index > levelBefore.index) {
        final alert = BudgetAlertInfo(
          categoryName: category.name,
          spent: after,
          limit: budget.limitAmount,
          level: levelAfter,
        );
        if (worst == null || alert.level.index > worst.level.index) {
          worst = alert;
        }
      }
    }
    return worst;
  }
}
