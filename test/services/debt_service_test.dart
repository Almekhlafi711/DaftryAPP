// اختبارات وحدة الديون وفق وثيقة «وحدة الديون — الإضافات الأخيرة»:
// القيود حسب مصدر الدين، المعادلات، التوزيع، الإلغاء والتعديل والحذف،
// الخط الزمني وكشف الحساب، معادلة التطابق الشاملة، الذرية والأرشفة،
// والمثال الكامل «أحمد» (القسم 12).
import 'package:daftry/core/errors/app_exception.dart';
import 'package:daftry/core/money/money.dart';
import 'package:daftry/core/utils/date_range.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/data/seed/default_categories.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/budget_report_models.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:daftry/services/debt_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

Matcher throwsBusiness(BusinessError e) =>
    throwsA(isA<BusinessException>().having((x) => x.error, 'error', e));

void main() {
  late TestEnv env;
  late DebtService debts;
  late Account cash;
  late int bank;
  late int ahmed;
  late Category sales;
  late Category shopping;
  late Category writeOffCat;
  late Category reliefCat;

  // «اليوم» ثابت في الاختبارات حتى لا تعتمد قواعد التاريخ على وقت التشغيل.
  final today = DateTime(2026, 10, 15, 12);
  DateTime day(int month, int d) => DateTime(2026, month, d, 10);

  setUp(() async {
    env = await TestEnv.create();
    debts = DebtService(env.db, clock: () => today);
    cash = await env.cash;
    bank = await env.accounts.create(
      name: 'البنك',
      type: AccountType.bank,
      openingBalance: 1000000,
    );
    ahmed = await env.contacts.create(name: 'أحمد علي', phone: '0551234567');
    sales = (await env.categories.bySystemKey(SystemCategoryKeys.sales))!;
    shopping = (await env.categories.bySystemKey(SystemCategoryKeys.shopping))!;
    writeOffCat = await env.categories.ensureSystemCategory(
      kWriteOffCategory,
      arabic: true,
    );
    reliefCat = await env.categories.ensureSystemCategory(
      kForgivenCategory,
      arabic: true,
    );
  });
  tearDown(() => env.dispose());

  Future<int> balance(int id) async => (await env.account(id)).balance;
  Future<DebtView> view(int id) async => (await debts.debtView(id))!;
  Future<({int income, int expense})> incomeStatement() async {
    final t = await env.transactions.totals(
      DateRange(DateTime(2000), DateTime(2100)),
    );
    return (income: t.income, expense: t.expense);
  }

  Future<DebtTotals> totals() => debts.watchTotals().first;
  Future<void> expectReconciled() async =>
      expect(await env.accounts.reconciliationGap(), 0);

  Future<int> createDebt({
    DebtDirection direction = DebtDirection.owedToMe,
    DebtSource source = DebtSource.loan,
    required int amount,
    DateTime? date,
    DateTime? due,
    int? account,
    int? category,
    int? contact,
    String? note,
  }) => debts.createDebt(
    DebtDraft(
      contactId: contact ?? ahmed,
      direction: direction,
      source: source,
      amount: amount,
      startDate: date ?? day(9, 1),
      dueDate: due,
      accountId: source.needsAccount ? (account ?? cash.id) : null,
      categoryId:
          category ??
          (source == DebtSource.creditSale
              ? sales.id
              : source == DebtSource.creditPurchase
              ? shopping.id
              : null),
      note: note,
    ),
  );

  Future<PaymentResult> pay(
    int amount, {
    DebtDirection direction = DebtDirection.owedToMe,
    DateTime? date,
    int? account,
    int? debtId,
    bool excess = false,
    int? contact,
  }) => debts.recordPayment(
    PaymentDraft(
      contactId: contact ?? ahmed,
      direction: direction,
      amount: amount,
      paidAt: date ?? day(10, 1),
      accountId: account ?? cash.id,
      debtId: debtId,
    ),
    excessAsOppositeDebt: excess,
  );

  Future<void> writeOff({
    DebtDirection direction = DebtDirection.owedToMe,
    int? debtId,
    DateTime? date,
  }) => debts.writeOffRemaining(
    contactId: ahmed,
    direction: direction,
    debtId: debtId,
    date: date ?? day(10, 2),
    categoryId: direction == DebtDirection.owedToMe
        ? writeOffCat.id
        : reliefCat.id,
  );

  // ---------------------------------------------------------------------------
  group('القيود حسب مصدر الدين (1.1، 3، 16.3)', () {
    test('إقراض من حساب: الحساب ينقص، ولا دخل ولا مصروف', () async {
      await createDebt(amount: 100000);
      expect(await balance(cash.id), -100000);
      expect((await totals()).owedToMe, 100000);
      expect(await incomeStatement(), (income: 0, expense: 0));
      await expectReconciled();
    });

    test('اقتراض إلى حساب: الحساب يزيد، ولا دخل', () async {
      await createDebt(
        direction: DebtDirection.iOwe,
        amount: 200000,
        account: bank,
      );
      expect(await balance(bank), 1200000);
      expect((await totals()).iOwe, 200000);
      expect(await incomeStatement(), (income: 0, expense: 0));
      await expectReconciled();
    });

    test('بيع بالآجل: دخل بفئة دون حركة حساب', () async {
      await createDebt(source: DebtSource.creditSale, amount: 80000);
      expect(await balance(cash.id), 0);
      expect(await incomeStatement(), (income: 80000, expense: 0));
      final report = await env.reports.report(
        DateRange.month(DateTime(2026, 9)),
      );
      expect(report.incomeByCategory.single.category.id, sales.id);
      await expectReconciled();
    });

    test(
      'استلام سداد بيع بالآجل: الحساب يزيد والدخل لا يتغير مرة ثانية',
      () async {
        await createDebt(source: DebtSource.creditSale, amount: 80000);
        await pay(80000);
        expect(await balance(cash.id), 80000);
        expect(await incomeStatement(), (income: 80000, expense: 0));
        await expectReconciled();
      },
    );

    test('شراء بالآجل: مصروف بفئة دون حركة حساب', () async {
      await createDebt(
        direction: DebtDirection.iOwe,
        source: DebtSource.creditPurchase,
        amount: 40000,
      );
      expect(await balance(cash.id), 0);
      expect(await incomeStatement(), (income: 0, expense: 40000));
      await expectReconciled();
    });

    test('دين سابق: الدفتر فقط', () async {
      await createDebt(source: DebtSource.opening, amount: 50000);
      await createDebt(
        direction: DebtDirection.iOwe,
        source: DebtSource.opening,
        amount: 70000,
      );
      expect(await env.db.select(env.db.transactions).get(), isEmpty);
      expect(await totals(), isA<DebtTotals>());
      expect((await totals()).owedToMe, 50000);
      expect((await totals()).iOwe, 70000);
      await expectReconciled();
    });

    test('المصدر يجب أن يناسب الاتجاه، والفئة تناسب النوع', () async {
      expect(
        createDebt(
          direction: DebtDirection.iOwe,
          source: DebtSource.creditSale,
          amount: 100,
        ),
        throwsBusiness(BusinessError.invalidDebtSource),
      );
      expect(
        createDebt(
          source: DebtSource.creditSale,
          amount: 100,
          category: shopping.id,
        ),
        throwsBusiness(BusinessError.categoryKindMismatch),
      );
    });

    test('قواعد التاريخ: الدين ≤ اليوم، والاستحقاق ≥ تاريخ الدين', () async {
      expect(
        createDebt(amount: 100, date: today.add(const Duration(days: 1))),
        throwsBusiness(BusinessError.dateInFuture),
      );
      expect(
        createDebt(amount: 100, date: day(9, 10), due: day(9, 9)),
        throwsBusiness(BusinessError.dueBeforeStart),
      );
    });

    test('لا عمليات جديدة على شخص مؤرشف أو حساب مؤرشف (القاعدة 7)', () async {
      final saleh = await env.contacts.create(name: 'صالح');
      await env.contacts.archive(saleh);
      expect(
        createDebt(amount: 100, contact: saleh),
        throwsBusiness(BusinessError.contactArchived),
      );
      final old = await env.accounts.create(
        name: 'قديم',
        type: AccountType.bank,
      );
      await env.accounts.archive(old);
      expect(
        createDebt(amount: 100, account: old),
        throwsBusiness(BusinessError.accountArchived),
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('المعادلات (5، 16.1)', () {
    test('R = A − Paid − W بعد كل عملية، والحالات الثلاث', () async {
      final id = await createDebt(amount: 100000);
      var v = await view(id);
      expect((v.remaining, v.status), (100000, DebtStatus.open));
      await pay(30000);
      v = await view(id);
      expect(
        (v.paid, v.remaining, v.status),
        (30000, 70000, DebtStatus.partial),
      );
      await writeOff(debtId: id);
      v = await view(id);
      expect(
        (v.writtenOff, v.remaining, v.status),
        (70000, 0, DebtStatus.closed),
      );
      await expectReconciled();
    });

    test('نسبة السداد للأسفل: 99.6% تظهر 99%، و100% عند السداد الكامل فقط', () {
      expect(DebtMath.progress(paid: 996, amount: 1000), 99);
      expect(DebtMath.progress(paid: 999, amount: 1000), 99);
      expect(DebtMath.progress(paid: 1000, amount: 1000), 100);
      expect(DebtMath.progress(paid: 0, amount: 1000), 0);
    });

    test('نسبة الشخص مرجّحة وليست متوسطاً (90% و 0% ← 9%)', () async {
      final first = await createDebt(amount: 1000, date: day(9, 1));
      await createDebt(amount: 9000, date: day(9, 2));
      await pay(900, debtId: first);
      final profile = (await debts.profile(ahmed))!;
      expect(profile.owedToMe!.progress, 9);
      final people = await debts.watchPeople().first;
      expect(people.single.progress, 9);
    });

    test('الجمع على أعداد صحيحة: 0.10 + 0.20 = 0.30 بالضبط', () {
      const parser = MoneyParser(2);
      final sum = parser.parse('0.10')! + parser.parse('0.20')!;
      expect(sum, parser.parse('0.30'));
      expect(sum, 30);
    });
  });

  // ---------------------------------------------------------------------------
  group('توزيع الدفعة على عدة ديون (6، 16.2)', () {
    late int oldest;
    late int newer;

    setUp(() async {
      oldest = await createDebt(amount: 80000, date: day(8, 1));
      newer = await createDebt(amount: 120000, date: day(9, 1));
    });

    test('دفعة أقل من الدين الأقدم: تُسجَّل عليه فقط', () async {
      final r = await pay(50000);
      expect(r.allocations.single.debtId, oldest);
      expect((await view(oldest)).remaining, 30000);
      expect((await view(newer)).remaining, 120000);
    });

    test(
      'دفعة تغطي الأقدم وجزءاً من التالي: دفعتان بمعرّف عملية واحد',
      () async {
        final r = await pay(150000);
        expect(r.allocations.map((a) => (a.debtId, a.amount)).toList(), [
          (oldest, 80000),
          (newer, 70000),
        ]);
        final payments = await env.db.select(env.db.debtPayments).get();
        expect(payments, hasLength(2));
        expect(payments.map((p) => p.operationId).toSet(), {r.operationId});
        // حركة حساب واحدة للعملية كلها.
        final moves = await (env.db.select(
          env.db.transactions,
        )..where((t) => t.type.equals(TxType.debtIn.name))).get();
        expect(moves.single.amount, 150000);
        expect(await balance(cash.id), -200000 + 150000);
        await expectReconciled();
      },
    );

    test('دفعة تساوي مجموع المتبقي: كل الديون مغلقة', () async {
      await pay(200000);
      expect((await view(oldest)).status, DebtStatus.closed);
      expect((await view(newer)).status, DebtStatus.closed);
      expect((await totals()).owedToMe, 0);
    });

    test(
      'دفعة زائدة: لا تُرفض بصمت، ويُعرض تسجيل الزائد ديناً معاكساً',
      () async {
        expect(
          pay(210000),
          throwsA(
            isA<BusinessException>()
                .having(
                  (e) => e.error,
                  'error',
                  BusinessError.paymentExceedsRemaining,
                )
                .having((e) => e.details, 'remaining', 200000),
          ),
        );
        final r = await pay(210000, excess: true);
        final extra = await view(r.excessDebtId!);
        expect(extra.direction, DebtDirection.iOwe);
        expect(extra.source, DebtSource.loan);
        expect(extra.amount, 10000);
        expect((await totals()).owedToMe, 0);
        expect((await totals()).iOwe, 10000);
        // المال دخل فعلاً كاملاً: 210,000.
        expect(await balance(cash.id), -200000 + 210000);
        await expectReconciled();
      },
    );

    test('إلغاء دفعة موزّعة: تُلغى كل أجزائها معاً ويُعكس الحساب', () async {
      final r = await pay(150000);
      final firstPayment =
          (await env.db.select(env.db.debtPayments).get()).first;
      await debts.cancelPayment(firstPayment.id);
      final payments = await env.db.select(env.db.debtPayments).get();
      expect(payments.every((p) => p.isCancelled), isTrue);
      expect(payments.every((p) => p.cancelledAt != null), isTrue);
      expect((await view(oldest)).remaining, 80000);
      expect((await view(newer)).remaining, 120000);
      expect(await balance(cash.id), -200000);
      expect(
        debts.cancelOperation(r.operationId),
        throwsBusiness(BusinessError.paymentAlreadyCancelled),
      );
      await expectReconciled();
    });

    test('«اختيار دين معيّن» يوجّه الدفعة يدوياً', () async {
      final r = await pay(10000, debtId: newer);
      expect(r.allocations.single.debtId, newer);
      expect((await view(oldest)).remaining, 80000);
    });

    test('قواعد تاريخ الدفعة (القاعدة 5)', () async {
      expect(
        pay(1000, date: today.add(const Duration(days: 1))),
        throwsBusiness(BusinessError.dateInFuture),
      );
      // دفعة في 15 أغسطس تغطي دين سبتمبر أيضاً: ترفض.
      expect(
        pay(100000, date: day(8, 15)),
        throwsBusiness(BusinessError.paymentBeforeDebt),
      );
      // وأقل من الدين الأقدم في نفس التاريخ: مقبولة.
      await pay(10000, date: day(8, 15));
    });

    test('لا عمليات جديدة على دين مغلق (القاعدة 6)', () async {
      await pay(80000, debtId: oldest);
      expect(
        pay(1, debtId: oldest),
        throwsBusiness(BusinessError.debtAlreadySettled),
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('الإلغاء والتعديل والحذف (8)', () {
    test('تعديل الأصل بالفرق فقط، ولا يقل عن المدفوع + المُسامَح', () async {
      final loan = await createDebt(amount: 100000);
      final sale = await createDebt(
        source: DebtSource.creditSale,
        amount: 50000,
        date: day(9, 2),
      );
      await pay(30000, debtId: loan);

      DebtDraft edit(int amount, DebtSource source) => DebtDraft(
        contactId: ahmed,
        direction: DebtDirection.owedToMe,
        source: source,
        amount: amount,
        startDate: source == DebtSource.loan ? day(9, 1) : day(9, 2),
        accountId: source == DebtSource.loan ? cash.id : null,
        categoryId: source == DebtSource.creditSale ? sales.id : null,
      );

      // إقراض: الحساب يتغير بـ −Δ.
      await debts.updateDebt(loan, edit(120000, DebtSource.loan));
      expect(await balance(cash.id), -120000 + 30000);
      // بيع بالآجل: الدخل يتغير بـ +Δ.
      await debts.updateDebt(sale, edit(60000, DebtSource.creditSale));
      expect((await incomeStatement()).income, 60000);
      // A_new ≥ Paid + W.
      expect(
        debts.updateDebt(loan, edit(20000, DebtSource.loan)),
        throwsBusiness(BusinessError.debtAmountBelowPaid),
      );
      // مع وجود دفعات: المصدر مقفل.
      expect(
        debts.updateDebt(loan, edit(120000, DebtSource.opening)),
        throwsBusiness(BusinessError.debtHasMovements),
      );
      await expectReconciled();
    });

    test('حذف الدين: فقط دون دفعات ولا مسامحة، ويعود القيد كما كان', () async {
      final loan = await createDebt(amount: 100000);
      await pay(10000);
      expect(
        debts.deleteDebt(loan),
        throwsBusiness(BusinessError.debtHasMovements),
      );
      // بعد إلغاء الدفعة يصبح خطأ إدخال قابلاً للحذف.
      await debts.cancelPayment(
        (await env.db.select(env.db.debtPayments).get()).single.id,
      );
      await debts.deleteDebt(loan);
      expect(await balance(cash.id), 0);
      expect(await env.db.select(env.db.debts).get(), isEmpty);
      expect(await env.db.select(env.db.transactions).get(), isEmpty);

      final sale = await createDebt(source: DebtSource.creditSale, amount: 500);
      await debts.deleteDebt(sale);
      expect((await incomeStatement()).income, 0);
      await expectReconciled();
    });

    test('الشخص: حذف دون حركات فقط، وأرشفة بشرط المتبقي صفر', () async {
      final empty = await env.contacts.create(name: 'بلا حركات');
      await env.contacts.delete(empty);
      expect(await env.contacts.getById(empty), isNull);

      await createDebt(amount: 1000);
      expect(
        env.contacts.delete(ahmed),
        throwsBusiness(BusinessError.personHasMovements),
      );
      expect(
        env.contacts.archive(ahmed),
        throwsBusiness(BusinessError.personHasBalance),
      );
      await pay(1000);
      await env.contacts.archive(ahmed);
      expect((await env.contacts.getById(ahmed))!.isArchived, isTrue);
      // المؤرشف لا يظهر في القائمة الافتراضية، ويظهر في فلتر «مؤرشف».
      expect(await debts.watchPeople().first, isEmpty);
      expect(
        await debts
            .watchPeople(
              filter: const PeopleFilter(status: PeopleStatus.archived),
            )
            .first,
        hasLength(1),
      );
      await env.contacts.unarchive(ahmed);
      expect((await env.contacts.getById(ahmed))!.isArchived, isFalse);
    });

    test('الحساب لا يُؤرشف إلا ورصيده صفر (1.2)', () async {
      final wallet = await env.accounts.create(
        name: 'محفظة',
        type: AccountType.wallet,
        openingBalance: 5000,
      );
      expect(
        env.accounts.archive(wallet),
        throwsBusiness(BusinessError.accountHasBalance),
      );
      await env.accounts.archive(wallet, transferToId: cash.id);
      expect((await env.account(wallet)).balance, 0);
      expect(await balance(cash.id), 5000);
    });
  });

  // ---------------------------------------------------------------------------
  group('المسامحة (4، 16.3)', () {
    test('مسامحة دين لي: مصروف «مسامحة ديون» والحسابات لا تتغير', () async {
      await createDebt(amount: 30000);
      final before = await balance(cash.id);
      await writeOff();
      expect(await balance(cash.id), before);
      expect(await incomeStatement(), (income: 0, expense: 30000));
      final tx = await (env.db.select(
        env.db.transactions,
      )..where((t) => t.type.equals(TxType.writeOff.name))).getSingle();
      expect((tx.accountId, tx.categoryId), (null, writeOffCat.id));
      await expectReconciled();
    });

    test('إعفاء من دين عليّ: دخل «إعفاء دين»', () async {
      await createDebt(direction: DebtDirection.iOwe, amount: 20000);
      await writeOff(direction: DebtDirection.iOwe);
      expect(await incomeStatement(), (income: 20000, expense: 0));
      expect((await totals()).iOwe, 0);
      await expectReconciled();
    });

    test('فئة المسامحة يجب أن تكون من النوع الصحيح', () async {
      await createDebt(amount: 1000);
      expect(
        debts.writeOffRemaining(
          contactId: ahmed,
          direction: DebtDirection.owedToMe,
          date: day(10, 2),
          categoryId: reliefCat.id,
        ),
        throwsBusiness(BusinessError.categoryKindMismatch),
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('الخط الزمني وكشف الحساب (7، 16.4)', () {
    test(
      'آخر رصيد جاري في كل اتجاه = المتبقي الكلي، والملغاة لا تدخل',
      () async {
        await createDebt(amount: 80000, date: day(8, 1));
        await createDebt(amount: 120000, date: day(9, 1));
        await createDebt(
          direction: DebtDirection.iOwe,
          amount: 5000,
          date: day(9, 3),
        );
        final r = await pay(50000, date: day(9, 5));
        await pay(10000, date: day(9, 6));
        await debts.cancelOperation(r.operationId);

        final p = (await debts.profile(ahmed))!;
        final latest = {
          for (final d in DebtDirection.values)
            d: p.timeline
                .firstWhere((e) => e.direction == d && !e.cancelled)
                .balanceAfter,
        };
        expect(latest[DebtDirection.owedToMe], p.receivable);
        expect(latest[DebtDirection.iOwe], p.payable);
        final cancelled = p.timeline.where((e) => e.cancelled).single;
        expect(cancelled.balanceAfter, isNull);
        expect(cancelled.amount, 50000);
      },
    );

    test('نفس اليوم: الدين قبل الدفعة', () async {
      final a = TimelineEntry(
        kind: TimelineKind.payment,
        date: DateTime(2026, 9, 1, 8),
        direction: DebtDirection.owedToMe,
        amount: 100,
        debtId: 1,
        sequence: 1,
      );
      final b = TimelineEntry(
        kind: TimelineKind.debt,
        date: DateTime(2026, 9, 1, 20),
        direction: DebtDirection.owedToMe,
        amount: 100,
        debtId: 1,
        sequence: 1,
      );
      final list = TimelineEntry.withRunningBalances([a, b]);
      // من الأحدث للأقدم: الدفعة أولاً (رصيدها 0) ثم الدين (رصيده 100).
      expect(list.map((e) => (e.kind, e.balanceAfter)).toList(), [
        (TimelineKind.payment, 0),
        (TimelineKind.debt, 100),
      ]);
    });

    test(
      'الكشف: افتتاحي وختامي، والختامي حتى اليوم = المتبقي الحالي',
      () async {
        await createDebt(
          source: DebtSource.creditSale,
          amount: 80000,
          date: day(8, 1),
        );
        await createDebt(amount: 120000, date: day(9, 1));
        await pay(150000, date: day(9, 24));
        await writeOff(date: day(9, 30));

        final september = await env.statements.build(
          ahmed,
          DateRange.month(DateTime(2026, 9)),
        );
        final s = september.section(DebtDirection.owedToMe)!;
        expect(s.opening, 80000);
        expect(s.lines.map((l) => (l.kind, l.movement, l.balance)).toList(), [
          (StatementLineKind.debt, 120000, 200000),
          (StatementLineKind.payment, -150000, 50000),
          (StatementLineKind.writeOff, -50000, 0),
        ]);
        expect(s.closing, 0);

        final untilToday = await env.statements.build(
          ahmed,
          DateRange(DateTime(2026, 1, 1), today.add(const Duration(days: 1))),
        );
        expect(
          untilToday.section(DebtDirection.owedToMe)!.closing,
          (await totals()).owedToMe,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  group('معادلة التطابق الشاملة والذرية (11، 16.4، 16.5)', () {
    test('تتحقق بعد سيناريو كامل، وتكشف البيانات الخاطئة', () async {
      await createDebt(amount: 100000);
      await createDebt(source: DebtSource.creditSale, amount: 80000);
      await createDebt(source: DebtSource.opening, amount: 50000);
      await createDebt(
        direction: DebtDirection.iOwe,
        amount: 200000,
        account: bank,
      );
      await createDebt(
        direction: DebtDirection.iOwe,
        source: DebtSource.creditPurchase,
        amount: 40000,
      );
      await pay(120000);
      await pay(100000, direction: DebtDirection.iOwe, account: bank);
      await writeOff();
      await writeOff(direction: DebtDirection.iOwe);
      await env.accounts.adjustBalance(cash.id, 999);
      await expectReconciled();

      // خطأ متعمد: حذف قيد إنشاء دين مباشرة من قاعدة البيانات.
      await (env.db.delete(env.db.transactions)..where(
            (t) =>
                t.type.equals(TxType.debtOut.name) & t.debtPaymentId.isNull(),
          ))
          .go();
      await env.accounts.recalculateAll();
      expect(await env.accounts.reconciliationGap(), isNot(0));
    });

    test('فشل أي جزء من عملية السداد يُرجع كل شيء كما كان', () async {
      await createDebt(amount: 80000, date: day(8, 1));
      await createDebt(amount: 120000, date: day(9, 1));
      // نُفشل إدراج حركة الحساب (بعد إدراج الدفعات) بمشغّل مؤقت.
      await env.db.customStatement('''
        CREATE TEMP TRIGGER fail_movement BEFORE INSERT ON transactions
        WHEN NEW.type = '${TxType.debtIn.name}'
        BEGIN SELECT RAISE(ABORT, 'boom'); END
      ''');
      await expectLater(pay(150000), throwsA(anything));
      expect(await env.db.select(env.db.debtPayments).get(), isEmpty);
      expect(await balance(cash.id), -200000);
      expect((await totals()).owedToMe, 200000);
      await env.db.customStatement('DROP TRIGGER fail_movement');
      await expectReconciled();
    });
  });

  // ---------------------------------------------------------------------------
  test('المثال الكامل — أحمد (القسم 12)', () async {
    // 1 أغسطس: بيع بضاعة بالآجل 800.
    final goods = await createDebt(
      source: DebtSource.creditSale,
      amount: 80000,
      date: day(8, 1),
      note: 'بضاعة',
    );
    // 1 سبتمبر: إقراض 1,200 من النقدية.
    final loan = await createDebt(
      amount: 120000,
      date: day(9, 1),
      note: 'سلفة',
    );
    expect(await balance(cash.id), -120000);
    expect((await totals()).owedToMe, 200000);
    // 24 سبتمبر: استلام 1,500 (الأول 800 + من الثاني 700).
    final r = await pay(150000, date: day(9, 24));
    expect(r.allocations.map((a) => (a.debtId, a.amount)).toList(), [
      (goods, 80000),
      (loan, 70000),
    ]);
    expect((await totals()).owedToMe, 50000);
    // 30 سبتمبر: مسامحة بالمتبقي 500.
    await writeOff(date: day(9, 30));

    // التحقق: تغيّر النقدية +300، «لي» 0، والدخل − المصروف = +300.
    expect(await balance(cash.id), 30000);
    expect((await totals()).owedToMe, 0);
    final pl = await incomeStatement();
    expect(
      (pl.income, pl.expense, pl.income - pl.expense),
      (80000, 50000, 30000),
    );
    await expectReconciled();

    // حالة الديون.
    final g = await view(goods);
    expect(
      (g.paid, g.writtenOff, g.remaining, g.progress, g.status),
      (80000, 0, 0, 100, DebtStatus.closed),
    );
    final l = await view(loan);
    expect(
      (l.paid, l.writtenOff, l.remaining, l.progress),
      (70000, 50000, 0, 58),
    );
    expect((l.status, l.writtenOffPercent), (DebtStatus.closed, 42));

    // نسبة سداد أحمد المرجّحة = 1,500 ÷ 2,000 = 75%.
    final p = (await debts.profile(ahmed))!;
    expect(p.owedToMe!.progress, 75);
    expect(p.owedToMe!.writtenOffPercent, 25);

    // الخط الزمني: آخر رصيد = المتبقي (0).
    expect(p.timeline.first.kind, TimelineKind.writeOff);
    expect(p.timeline.first.balanceAfter, 0);
    // جدول الكشف كما في الوثيقة (7.2).
    final st = await env.statements.build(
      ahmed,
      DateRange(DateTime(2026, 8, 1), DateTime(2026, 10, 1)),
    );
    expect(
      st
          .section(DebtDirection.owedToMe)!
          .lines
          .map((x) => (x.movement, x.balance))
          .toList(),
      [(80000, 80000), (120000, 200000), (-150000, 50000), (-50000, 0)],
    );
  });

  test('الترتيب والفلترة في قائمة الأشخاص', () async {
    final saleh = await env.contacts.create(name: 'صالح', phone: '0500000000');
    await createDebt(amount: 1000, due: day(9, 10));
    await createDebt(contact: saleh, amount: 5000, due: day(12, 1));
    final byAmount = await debts
        .watchPeople(filter: const PeopleFilter(sort: PeopleSort.amountDesc))
        .first;
    expect(byAmount.map((p) => p.contact.id).toList(), [saleh, ahmed]);
    final overdue = await debts
        .watchPeople(filter: const PeopleFilter(status: PeopleStatus.overdue))
        .first;
    expect(overdue.single.contact.id, ahmed);
    expect((await totals()).overdueDebts, 1);
    expect((await totals()).people, 2);
    final byPhone = await debts.watchPeople(query: '050000').first;
    expect(byPhone.single.contact.id, saleh);
  });
}
