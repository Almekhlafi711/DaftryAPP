// اختبارات الإعداد الأول والحسابات والأرشفة والتسوية.
import 'package:daftry/core/constants/currencies.dart';
import 'package:daftry/core/errors/app_exception.dart';
import 'package:daftry/core/utils/date_range.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/transaction_models.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Matcher throwsBusiness(BusinessError e) =>
    throwsA(isA<BusinessException>().having((x) => x.error, 'error', e));

void main() {
  late TestEnv env;

  tearDown(() => env.dispose());

  group('الإعداد الأول (UC-00)', () {
    test('ينشئ العملة والحساب الافتراضي والفئات ويقفل العملة', () async {
      env = await TestEnv.create();
      final currency = await env.db.baseCurrency();
      expect(currency!.code, 'SAR');
      expect(currency.decimals, 2);

      final accounts = await env.accounts.getActive();
      expect(accounts, hasLength(1));
      expect(accounts.single.name, 'النقدية');
      expect(accounts.single.isDefault, isTrue);

      final prefs = await env.settings.getPreferences();
      expect(prefs.onboarded, isTrue);
      expect(prefs.defaultAccountId, accounts.single.id);

      final expense = await env.categories
          .watchByKind(CategoryKind.expense)
          .first;
      final income = await env.categories
          .watchByKind(CategoryKind.income)
          .first;
      expect(expense, isNotEmpty);
      expect(income, isNotEmpty);
    });

    test('لا يمكن تغيير العملة بعد التأكيد', () async {
      env = await TestEnv.create();
      expect(
        env.settings.completeOnboarding(currencyByCode('USD')!, arabic: false),
        throwsBusiness(BusinessError.currencyLocked),
      );
    });

    test('حذف جميع البيانات يسمح بالبدء من جديد بعملة أخرى', () async {
      env = await TestEnv.create();
      await env.settings.wipeAllData();
      expect(await env.settings.isOnboarded(), isFalse);
      await env.settings.completeOnboarding(
        currencyByCode('KWD')!,
        arabic: false,
      );
      final currency = await env.db.baseCurrency();
      expect(currency!.code, 'KWD');
      expect(currency.decimals, 3);
      expect((await env.cash).name, 'Cash');
    });
  });

  group('الحسابات', () {
    setUp(() async => env = await TestEnv.create());

    test('قاعدة البيانات نفسها تمنع حذف أي حساب (Trigger)', () async {
      final cash = await env.cash;
      expect(
        (env.db.delete(
          env.db.accounts,
        )..where((a) => a.id.equals(cash.id))).go(),
        throwsA(anything),
      );
    });

    test('اسم الحساب فريد', () async {
      await env.accounts.create(name: 'الراجحي', type: AccountType.bank);
      expect(
        env.accounts.create(name: 'الراجحي', type: AccountType.bank),
        throwsBusiness(BusinessError.duplicateAccountName),
      );
    });

    test('الرصيد الافتتاحي يدخل في الإجمالي', () async {
      await env.accounts.create(
        name: 'الراجحي',
        type: AccountType.bank,
        openingBalance: 1850000,
      );
      expect(await env.accounts.watchTotalBalance().first, 1850000);
    });

    test('تعيين حساب افتراضي آخر يلغي القديم', () async {
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
      );
      await env.accounts.setDefault(bank);
      expect((await env.accounts.getDefault())!.id, bank);
      final all = await env.accounts.getActive();
      expect(all.where((a) => a.isDefault), hasLength(1));
      expect((await env.settings.getPreferences()).defaultAccountId, bank);
    });
  });

  group('الأرشفة (UC-01b)', () {
    setUp(() async => env = await TestEnv.create());

    test('لا يمكن أرشفة آخر حساب نشط', () async {
      final cash = await env.cash;
      expect(
        env.accounts.archive(cash.id),
        throwsBusiness(BusinessError.cannotArchiveLastAccount),
      );
    });

    test('أرشفة الحساب الافتراضي تتطلب اختيار بديل', () async {
      final cash = await env.cash;
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
      );
      expect(
        env.accounts.archive(cash.id),
        throwsBusiness(BusinessError.mustChooseNewDefault),
      );
      await env.accounts.archive(cash.id, newDefaultId: bank);
      expect((await env.accounts.getDefault())!.id, bank);
      expect((await env.account(cash.id)).isArchived, isTrue);
    });

    test('تحويل الرصيد قبل الأرشفة يحافظ على الإجمالي', () async {
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
        openingBalance: 50000,
      );
      final cash = await env.cash;
      await env.accounts.archive(bank, transferToId: cash.id);
      expect((await env.account(bank)).balance, 0);
      expect((await env.account(cash.id)).balance, 50000);
      expect(await env.accounts.watchTotalBalance().first, 50000);
    });

    test('لا أرشفة لحساب له رصيد دون تحويله (المال لا يختفي)', () async {
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
        openingBalance: 50000,
      );
      await expectLater(
        env.accounts.archive(bank),
        throwsBusiness(BusinessError.accountHasBalance),
      );
      expect(await env.accounts.watchTotalBalance().first, 50000);
    });

    test('الحساب المؤرشف لا يُستخدم في معاملة جديدة', () async {
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
      );
      await env.accounts.archive(bank);
      final food = await env.category(CategoryKind.expense);
      expect(
        env.transactions.add(
          TransactionDraft(
            type: TxType.expense,
            amount: 100,
            accountId: bank,
            categoryId: food.id,
            date: DateTime.now(),
          ),
        ),
        throwsBusiness(BusinessError.accountArchived),
      );
    });
  });

  group('التسوية وإعادة الاحتساب', () {
    setUp(() async => env = await TestEnv.create());

    test('التسوية تنشئ معاملة بالفرق (موجب أو سالب)', () async {
      final cash = await env.cash;
      final up = await env.accounts.adjustBalance(cash.id, 30000);
      expect(up, isNotNull);
      expect((await env.account(cash.id)).balance, 30000);

      await env.accounts.adjustBalance(cash.id, 25000);
      expect((await env.account(cash.id)).balance, 25000);

      final txs = await env.db.select(env.db.transactions).get();
      expect(txs.map((t) => t.type), everyElement(TxType.adjustment));
      expect(txs.map((t) => t.amount), containsAll([30000, -5000]));

      // لا فرق = لا معاملة
      expect(await env.accounts.adjustBalance(cash.id, 25000), isNull);
    });

    test('التسوية لا تُحتسب دخلاً ولا مصروفاً', () async {
      final cash = await env.cash;
      await env.accounts.adjustBalance(cash.id, 30000);
      final totals = await env.transactions.totals(
        DateRange.month(DateTime.now()),
      );
      expect(totals.income, 0);
      expect(totals.expense, 0);
    });

    test('إعادة الاحتساب تصحح رصيداً مخزَّناً خاطئاً', () async {
      final cash = await env.cash;
      final salary = await env.category(CategoryKind.income);
      await env.transactions.add(
        TransactionDraft(
          type: TxType.income,
          amount: 100000,
          accountId: cash.id,
          categoryId: salary.id,
          date: DateTime.now(),
        ),
      );
      // نفسد الرصيد عمداً
      await (env.db.update(env.db.accounts)..where((a) => a.id.equals(cash.id)))
          .write(const AccountsCompanion(balance: Value(1)));
      final fixed = await env.accounts.recalculateAll();
      expect(fixed, 1);
      expect((await env.account(cash.id)).balance, 100000);
    });
  });
}
