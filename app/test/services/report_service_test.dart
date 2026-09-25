// اختبارات التقارير.
import 'package:daftry/core/utils/date_range.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/transaction_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late TestEnv env;
  setUp(() async => env = await TestEnv.create());
  tearDown(() => env.dispose());

  test('مقارنة الأشهر تملأ الأشهر الفارغة بالصفر', () async {
    final cash = await env.cash;
    final food = await env.category(CategoryKind.expense);
    final now = DateTime.now();
    await env.transactions.add(
      TransactionDraft(
        type: TxType.expense,
        amount: 5000,
        accountId: cash.id,
        categoryId: food.id,
        date: DateTime(now.year, now.month - 2, 15),
      ),
    );
    final months = await env.reports.monthlyTotals(DateRange.lastMonths(6));
    expect(months, hasLength(6));
    expect(months.where((m) => m.expense > 0), hasLength(1));
    expect(months[3].expense, 5000);
  });

  test('توزيع المصروف حسب الفئة بنسب صحيحة', () async {
    final cash = await env.cash;
    final expenses = await env.categories
        .watchByKind(CategoryKind.expense)
        .first;
    Future<void> spend(int categoryId, int amount) => env.transactions.add(
      TransactionDraft(
        type: TxType.expense,
        amount: amount,
        accountId: cash.id,
        categoryId: categoryId,
        date: DateTime.now(),
      ),
    );
    await spend(expenses[0].id, 3000);
    await spend(expenses[1].id, 1000);
    await spend(expenses[0].id, 0 + 1000);

    final report = await env.reports.report(DateRange.month(DateTime.now()));
    expect(report.expense, 5000);
    expect(report.income, 0);
    expect(report.expenseByCategory.first.category.id, expenses[0].id);
    expect(report.expenseByCategory.first.share, closeTo(0.8, 0.0001));
  });
}
