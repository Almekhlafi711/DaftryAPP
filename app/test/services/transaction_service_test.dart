// اختبارات المعاملات: الإضافة والتعديل والحذف والتراجع والفلترة والميزانية.
import 'package:daftry/core/errors/app_exception.dart';
import 'package:daftry/core/utils/date_range.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:daftry/domain/models/transaction_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Matcher throwsBusiness(BusinessError e) =>
    throwsA(isA<BusinessException>().having((x) => x.error, 'error', e));

void main() {
  late TestEnv env;
  late Account cash;
  late Category food;
  late Category salary;

  setUp(() async {
    env = await TestEnv.create();
    cash = await env.cash;
    food = await env.category(CategoryKind.expense);
    salary = await env.category(CategoryKind.income);
  });
  tearDown(() => env.dispose());

  TransactionDraft expense(
    int amount, {
    int? account,
    DateTime? date,
    String? note,
  }) => TransactionDraft(
    type: TxType.expense,
    amount: amount,
    accountId: account ?? cash.id,
    categoryId: food.id,
    date: date ?? DateTime.now(),
    note: note,
  );

  TransactionDraft income(int amount, {int? account}) => TransactionDraft(
    type: TxType.income,
    amount: amount,
    accountId: account ?? cash.id,
    categoryId: salary.id,
    date: DateTime.now(),
  );

  Future<int> balance(int id) async => (await env.account(id)).balance;

  group('الإضافة (UC-02)', () {
    test('المصروف ينقص الرصيد والدخل يزيده', () async {
      await env.transactions.add(income(1200000));
      await env.transactions.add(expense(24500));
      expect(await balance(cash.id), 1200000 - 24500);
    });

    test('التحويل ينقل المبلغ بين حسابين دون تغيير الإجمالي', () async {
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
      );
      await env.transactions.add(income(100000));
      await env.transactions.add(
        TransactionDraft(
          type: TxType.transfer,
          amount: 30000,
          accountId: cash.id,
          toAccountId: bank,
          date: DateTime.now(),
        ),
      );
      expect(await balance(cash.id), 70000);
      expect(await balance(bank), 30000);
      expect(await env.accounts.watchTotalBalance().first, 100000);
    });

    test('المبلغ صفر مرفوض', () async {
      expect(
        env.transactions.add(expense(0)),
        throwsBusiness(BusinessError.invalidAmount),
      );
    });

    test('فئة الدخل لا تُستخدم في مصروف', () async {
      expect(
        env.transactions.add(
          TransactionDraft(
            type: TxType.expense,
            amount: 100,
            accountId: cash.id,
            categoryId: salary.id,
            date: DateTime.now(),
          ),
        ),
        throwsBusiness(BusinessError.categoryKindMismatch),
      );
    });

    test('التحويل لنفس الحساب مرفوض', () async {
      expect(
        env.transactions.add(
          TransactionDraft(
            type: TxType.transfer,
            amount: 100,
            accountId: cash.id,
            toAccountId: cash.id,
            date: DateTime.now(),
          ),
        ),
        throwsBusiness(BusinessError.sameAccountTransfer),
      );
    });
  });

  group('التعديل والحذف (UC-03)', () {
    test('التعديل يعكس القيمة القديمة ويطبق الجديدة', () async {
      final r = await env.transactions.add(expense(10000));
      await env.transactions.update(r.id, expense(25000));
      expect(await balance(cash.id), -25000);

      // تغيير النوع إلى دخل
      await env.transactions.update(r.id, income(5000));
      expect(await balance(cash.id), 5000);
    });

    test('الحذف يعيد المبلغ والتراجع يعيد المعاملة بنفس الرقم', () async {
      final r = await env.transactions.add(expense(31000));
      final deleted = await env.transactions.delete(r.id);
      expect(await balance(cash.id), 0);
      expect(await env.transactions.getById(r.id), isNull);

      await env.transactions.restore(deleted);
      expect(await balance(cash.id), -31000);
      expect((await env.transactions.getById(r.id))!.amount, 31000);
    });

    test('معاملة على حساب مؤرشف: يُعدَّل المبلغ فقط ولا تُنقل', () async {
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
      );
      final r = await env.transactions.add(expense(1000, account: bank));
      await env.accounts.archive(bank);

      await env.transactions.update(r.id, expense(2000, account: bank));
      expect(await balance(bank), -2000);

      expect(
        env.transactions.update(r.id, expense(2000, account: cash.id)),
        throwsBusiness(BusinessError.cannotMoveArchivedTransaction),
      );
    });

    test('حركات الديون لا تُعدَّل ولا تُحذف من سجل المعاملات', () async {
      final contact = await env.contacts.create(name: 'أحمد');
      await env.debts.createDebt(
        DebtDraft(
          contactId: contact,
          direction: DebtDirection.owedToMe,
          amount: 1000,
          startDate: DateTime.now(),
          accountId: cash.id,
        ),
      );
      final movement = (await env.db.select(env.db.transactions).get()).single;
      expect(movement.type, TxType.debtOut);
      expect(
        env.transactions.delete(movement.id),
        throwsBusiness(BusinessError.debtMovementReadOnly),
      );
      expect(
        env.transactions.update(movement.id, expense(1)),
        throwsBusiness(BusinessError.debtMovementReadOnly),
      );
    });
  });

  group('القراءة والفلترة (FR-12)', () {
    test('ملخص الدخل والمصروف يستبعد الديون والتحويل والتسوية', () async {
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
      );
      await env.transactions.add(income(1200000));
      await env.transactions.add(expense(642000));
      await env.transactions.add(
        TransactionDraft(
          type: TxType.transfer,
          amount: 1000,
          accountId: cash.id,
          toAccountId: bank,
          date: DateTime.now(),
        ),
      );
      await env.accounts.adjustBalance(bank, 99999);
      final contact = await env.contacts.create(name: 'خالد');
      await env.debts.createDebt(
        DebtDraft(
          contactId: contact,
          direction: DebtDirection.iOwe,
          amount: 50000,
          startDate: DateTime.now(),
          accountId: cash.id,
        ),
      );

      final totals = await env.transactions.totals(
        DateRange.month(DateTime.now()),
      );
      expect(totals.income, 1200000);
      expect(totals.expense, 642000);
      expect(totals.net, 558000);
    });

    test('البحث بالملاحظة وبالمبلغ وإخفاء حركات الديون', () async {
      await env.transactions.add(expense(24500, note: 'سوبرماركت'));
      await env.transactions.add(expense(31000, note: 'كهرباء'));
      final contact = await env.contacts.create(name: 'أحمد علي');
      await env.debts.createDebt(
        DebtDraft(
          contactId: contact,
          direction: DebtDirection.owedToMe,
          amount: 50000,
          startDate: DateTime.now(),
          accountId: cash.id,
        ),
      );

      var list = await env.transactions.getFiltered(
        const TransactionFilter(query: 'سوبر'),
      );
      expect(list.single.tx.note, 'سوبرماركت');

      list = await env.transactions.getFiltered(
        const TransactionFilter(query: '310'),
      );
      expect(list.single.tx.amount, 31000);

      list = await env.transactions.getFiltered(
        const TransactionFilter(query: 'أحمد'),
      );
      expect(list.single.isDebtMovement, isTrue);
      expect(list.single.contactName, 'أحمد علي');

      list = await env.transactions.getFiltered(
        const TransactionFilter(showDebtMovements: false),
      );
      expect(list, hasLength(2));

      list = await env.transactions.getFiltered(
        const TransactionFilter(
          sort: TransactionSort.amountDesc,
          showDebtMovements: false,
        ),
      );
      expect(list.first.tx.amount, 31000);
    });

    test('فلترة بالفترة', () async {
      final lastMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month - 1,
        10,
      );
      await env.transactions.add(expense(100, date: lastMonth));
      await env.transactions.add(expense(200));
      final list = await env.transactions.getFiltered(
        TransactionFilter(range: DateRange.month(DateTime.now())),
      );
      expect(list.single.tx.amount, 200);
    });

    test('اقتراح الحساب: آخر حساب للفئة وإلا الافتراضي', () async {
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
      );
      expect((await env.transactions.suggestAccount(food.id))!.id, cash.id);
      await env.transactions.add(expense(100, account: bank));
      expect((await env.transactions.suggestAccount(food.id))!.id, bank);
      // المؤرشف لا يُقترح
      await env.accounts.archive(bank);
      expect((await env.transactions.suggestAccount(food.id))!.id, cash.id);
    });
  });

  group('الميزانية (FR-21)', () {
    test('تنبيه عند عبور 75% ثم عند 100% فقط', () async {
      await env.budgets.upsert(categoryId: food.id, limit: 100000);

      var r = await env.transactions.add(expense(50000));
      expect(r.budgetAlert, isNull);

      r = await env.transactions.add(expense(30000)); // 80%
      expect(r.budgetAlert!.level, BudgetLevel.warning);

      r = await env.transactions.add(expense(5000)); // 85% — لا تنبيه مكرر
      expect(r.budgetAlert, isNull);

      r = await env.transactions.add(expense(20000)); // 105%
      expect(r.budgetAlert!.level, BudgetLevel.exceeded);
      expect(r.budgetAlert!.percent, 105);
    });

    test('ملخص الميزانيات للشهر', () async {
      await env.budgets.upsert(categoryId: food.id, limit: 200000);
      await env.transactions.add(expense(150000));
      final overview = await env.budgets.overview(DateTime.now());
      expect(overview.totalLimit, 200000);
      expect(overview.totalSpent, 150000);
      expect(overview.items.single.level, BudgetLevel.warning);
      expect(overview.remaining, 50000);
    });
  });
}
