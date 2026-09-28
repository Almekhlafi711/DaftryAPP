// اختبارات وحدة الديون: حركات الدين، الدفعات، الحالة، الملف المالي، كشف الحساب.
import 'package:daftry/core/errors/app_exception.dart';
import 'package:daftry/core/utils/date_range.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Matcher throwsBusiness(BusinessError e) =>
    throwsA(isA<BusinessException>().having((x) => x.error, 'error', e));

void main() {
  late TestEnv env;
  late Account cash;
  late int ahmed;

  setUp(() async {
    env = await TestEnv.create();
    cash = await env.cash;
    ahmed = await env.contacts.create(name: 'أحمد علي', phone: '0551234567');
  });
  tearDown(() => env.dispose());

  Future<int> balance(int id) async => (await env.account(id)).balance;

  Future<int> lend(int amount, {int? account, DateTime? date, DateTime? due}) =>
      env.debts.createDebt(
        DebtDraft(
          contactId: ahmed,
          direction: DebtDirection.owedToMe,
          amount: amount,
          startDate: date ?? DateTime.now(),
          dueDate: due,
          accountId: account,
        ),
      );

  group('تسجيل دين (UC-07)', () {
    test('دين «لي» مرتبط بحساب ينقص الرصيد دون أن يكون مصروفاً', () async {
      await lend(120000, account: cash.id);
      expect(await balance(cash.id), -120000);
      final tx = (await env.db.select(env.db.transactions).get()).single;
      expect(tx.type, TxType.debtOut);
      final totals = await env.transactions.totals(
        DateRange.month(DateTime.now()),
      );
      expect(totals.expense, 0);
    });

    test('دين «عليّ» مرتبط بحساب يزيد الرصيد', () async {
      await env.debts.createDebt(
        DebtDraft(
          contactId: ahmed,
          direction: DebtDirection.iOwe,
          amount: 50000,
          startDate: DateTime.now(),
          accountId: cash.id,
        ),
      );
      expect(await balance(cash.id), 50000);
    });

    test('البيع بالآجل (بدون حساب) يُسجَّل في الدفتر فقط', () async {
      await lend(80000);
      expect(await balance(cash.id), 0);
      expect(await env.db.select(env.db.transactions).get(), isEmpty);
      expect((await env.debts.watchTotals().first).owedToMe, 80000);
    });

    test('لا يُربط دين بحساب مؤرشف', () async {
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
      );
      await env.accounts.archive(bank);
      expect(
        lend(100, account: bank),
        throwsBusiness(BusinessError.accountArchived),
      );
    });
  });

  group('الدفعات (UC-08)', () {
    test('الحالة تتغير آلياً: مفتوح ← جزئي ← مسدَّد', () async {
      final debt = await lend(200000, account: cash.id);
      expect((await env.debts.getDebt(debt))!.status, DebtStatus.open);

      await env.debts.recordPayment(
        debt,
        PaymentDraft(amount: 50000, paidAt: DateTime.now(), accountId: cash.id),
      );
      var d = (await env.debts.getDebt(debt))!;
      expect(d.status, DebtStatus.partial);
      expect(d.paidAmount, 50000);
      expect(await balance(cash.id), -150000);

      await env.debts.recordPayment(
        debt,
        PaymentDraft(
          amount: 150000,
          paidAt: DateTime.now(),
          accountId: cash.id,
        ),
      );
      d = (await env.debts.getDebt(debt))!;
      expect(d.status, DebtStatus.settled);
      expect(await balance(cash.id), 0);
    });

    test('الدفعة لا تتجاوز المتبقي', () async {
      final debt = await lend(1000);
      expect(
        env.debts.recordPayment(
          debt,
          PaymentDraft(amount: 1001, paidAt: DateTime.now()),
        ),
        throwsA(
          isA<BusinessException>()
              .having(
                (e) => e.error,
                'error',
                BusinessError.paymentExceedsRemaining,
              )
              .having((e) => e.details, 'remaining', 1000),
        ),
      );
    });

    test('لا دفعة على دين مسدَّد', () async {
      final debt = await lend(1000);
      await env.debts.recordPayment(
        debt,
        PaymentDraft(amount: 1000, paidAt: DateTime.now()),
      );
      expect(
        env.debts.recordPayment(
          debt,
          PaymentDraft(amount: 1, paidAt: DateTime.now()),
        ),
        throwsBusiness(BusinessError.debtAlreadySettled),
      );
    });

    test('حذف دفعة يعكس حركتها ويعيد الحالة', () async {
      final debt = await lend(1000, account: cash.id);
      final payment = await env.debts.recordPayment(
        debt,
        PaymentDraft(amount: 400, paidAt: DateTime.now(), accountId: cash.id),
      );
      await env.debts.deletePayment(payment);
      final d = (await env.debts.getDebt(debt))!;
      expect(d.status, DebtStatus.open);
      expect(d.paidAmount, 0);
      expect(await balance(cash.id), -1000);
    });

    test('حذف الدين يحذف دفعاته وحركاته ويعيد الأرصدة', () async {
      final debt = await lend(1000, account: cash.id);
      await env.debts.recordPayment(
        debt,
        PaymentDraft(amount: 400, paidAt: DateTime.now(), accountId: cash.id),
      );
      await env.debts.deleteDebt(debt);
      expect(await balance(cash.id), 0);
      expect(await env.db.select(env.db.transactions).get(), isEmpty);
      expect(await env.db.select(env.db.debtPayments).get(), isEmpty);
    });

    test(
      'الحساب المقترح للدفعة: حساب الإنشاء، أو الافتراضي إن أُرشف',
      () async {
        final bank = await env.accounts.create(
          name: 'بنك',
          type: AccountType.bank,
        );
        final debt = await lend(1000, account: bank);
        expect((await env.debts.suggestPaymentAccount(debt))!.id, bank);
        await env.accounts.archive(bank);
        expect((await env.debts.suggestPaymentAccount(debt))!.id, cash.id);
      },
    );

    test('تعديل الدين: لا يقل عن المسدَّد، ويعيد بناء حركة الإنشاء', () async {
      final bank = await env.accounts.create(
        name: 'بنك',
        type: AccountType.bank,
      );
      final debt = await lend(1000, account: cash.id);
      await env.debts.recordPayment(
        debt,
        PaymentDraft(amount: 600, paidAt: DateTime.now()),
      );
      DebtDraft edit(int amount, int? account) => DebtDraft(
        contactId: ahmed,
        direction: DebtDirection.owedToMe,
        amount: amount,
        startDate: DateTime.now(),
        accountId: account,
      );
      expect(
        env.debts.updateDebt(debt, edit(500, cash.id)),
        throwsBusiness(BusinessError.debtAmountBelowPaid),
      );
      await env.debts.updateDebt(debt, edit(1500, bank));
      expect(await balance(cash.id), 0);
      expect(await balance(bank), -1500);
      expect((await env.debts.getDebt(debt))!.status, DebtStatus.partial);
    });
  });

  group('الملف المالي والقوائم (FR-18)', () {
    test('الملف المالي والخط الزمني بالإشارات الصحيحة', () async {
      final debt = await lend(
        120000,
        account: cash.id,
        due: DateTime(2030, 9, 29),
      );
      await lend(80000);
      await env.debts.recordPayment(
        debt,
        PaymentDraft(
          amount: 50000,
          paidAt: DateTime.now().add(const Duration(minutes: 1)),
          accountId: cash.id,
        ),
      );

      final profile = (await env.debts.profile(ahmed))!;
      expect(profile.owedToMeRemaining, 150000);
      expect(profile.totalDebts, 200000);
      expect(profile.totalPaid, 50000);
      expect(profile.status, DebtStatus.partial);
      expect(profile.nearestDue, DateTime(2030, 9, 29));
      expect(profile.timeline, hasLength(3));
      expect(profile.timeline.first.kind, TimelineKind.payment);
      expect(profile.timeline.first.signedEffect, -50000);
      expect(
        profile.timeline
            .where((e) => e.kind == TimelineKind.debt)
            .map((e) => e.signedEffect),
        everyElement(greaterThan(0)),
      );
    });

    test('قائمة الأشخاص وتبويبات الاتجاه ومجموع لي/عليّ', () async {
      final khaled = await env.contacts.create(name: 'خالد');
      await lend(335000);
      await env.debts.createDebt(
        DebtDraft(
          contactId: khaled,
          direction: DebtDirection.iOwe,
          amount: 150000,
          startDate: DateTime.now(),
        ),
      );
      final totals = await env.debts.watchTotals().first;
      expect(totals.owedToMe, 335000);
      expect(totals.iOwe, 150000);

      final all = await env.debts.watchPeople().first;
      expect(all, hasLength(2));
      final mine = await env.debts
          .watchPeople(direction: DebtDirection.owedToMe)
          .first;
      expect(mine.single.contact.name, 'أحمد علي');
      expect(mine.single.net, 335000);
      final theirs = await env.debts
          .watchPeople(direction: DebtDirection.iOwe)
          .first;
      expect(theirs.single.net, -150000);
    });

    test('الديون القريبة الاستحقاق', () async {
      final now = DateTime.now();
      await lend(100, due: now.add(const Duration(days: 3)));
      await lend(100, due: now.add(const Duration(days: 30)));
      final upcoming = await env.debts.upcomingDue(days: 7);
      expect(upcoming, hasLength(1));
      expect(upcoming.single.contactName, 'أحمد علي');
    });
  });

  group('كشف الحساب (UC-15)', () {
    test('رصيد افتتاحي + حركات الفترة + المتبقي', () async {
      final now = DateTime.now();
      final old = DateTime(now.year, now.month - 2, 5);
      final debt = await lend(80000, date: old); // قبل الفترة
      await lend(120000, date: now.subtract(const Duration(days: 5)));
      await env.debts.recordPayment(
        debt,
        PaymentDraft(
          amount: 50000,
          paidAt: now.subtract(const Duration(days: 1)),
        ),
      );

      final statement = await env.statements.build(
        ahmed,
        DateRange.lastDays(30),
      );
      expect(statement.openingBalance, 80000);
      expect(statement.lines, hasLength(2));
      expect(statement.lines.first.runningBalance, 200000);
      expect(statement.closingBalance, 150000);
      expect(statement.totalPayments, 50000);
    });
  });
}
