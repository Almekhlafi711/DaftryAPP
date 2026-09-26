// البيانات التجريبية تُبنى عبر الخدمات فتبقى الأرصدة والحالات متسقة.
import 'package:daftry/domain/enums.dart';
import 'package:daftry/services/demo_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  test(
    'البيانات التجريبية متسقة: الأرصدة المخزنة = المحسوبة من المعاملات',
    () async {
      final env = await TestEnv.create();
      addTearDown(env.dispose);
      await DemoDataService(
        db: env.db,
        accounts: env.accounts,
        transactions: env.transactions,
        budgets: env.budgets,
        contacts: env.contacts,
        debts: env.debts,
      ).load(arabic: true, now: DateTime(2026, 9, 25));

      expect(await env.accounts.getActive(), hasLength(3));
      expect(
        (await env.db.select(env.db.transactions).get()).length,
        greaterThan(60),
      );
      expect(await env.db.select(env.db.budgets).get(), hasLength(4));

      // إعادة الاحتساب لا تجد أي فرق: كل رصيد مخزَّن صحيح.
      expect(await env.accounts.recalculateAll(), 0);

      final debts = await env.db.select(env.db.debts).get();
      expect(
        debts.map((d) => d.status),
        containsAll([DebtStatus.partial, DebtStatus.open, DebtStatus.settled]),
      );
      final totals = await env.debts.watchTotals().first;
      expect(totals.owedToMe, 150000); // 700 + 800
      expect(totals.iOwe, 150000);
    },
  );
}
