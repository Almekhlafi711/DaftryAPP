// =============================================================================
// خدمة الديون (DebtService في مخطط طبقة الخدمات).
//
// قواعد العمل (الوثيقة 3.12.4):
// - الديون منفصلة عن الدخل والمصروف: لا تدخل في التقارير ولا الميزانية.
// - إذا خرج المال فعلاً من حساب أو دخل إليه تُنشأ «حركة دين» تحرّك الرصيد
//   وتظهر في سجل المعاملات بشكل مميز.
// - البيع/الشراء بالآجل دون حركة مال يُسجَّل في الدفتر فقط (accountId = null).
// - الدفعة لا تتجاوز المتبقي، وحالة الدين تُحسب آلياً.
// - حساب الدفعة المقترح هو حساب إنشاء الدين، أو الافتراضي إن كان مؤرشفاً.
//
// اتجاه حركة الدين:
//   إنشاء دين «لي» مرتبط بحساب  → debtOut (خرج المال: أقرضت)
//   إنشاء دين «عليّ» مرتبط بحساب → debtIn  (دخل المال: اقترضت)
//   دفعة على دين «لي»            → debtIn  (استلمت)
//   دفعة على دين «عليّ»           → debtOut (دفعت)
// =============================================================================

import 'package:drift/drift.dart';

import '../core/errors/app_exception.dart';
import '../data/database/app_database.dart';
import '../domain/enums.dart';
import '../domain/models/debt_models.dart';
import 'ledger.dart';
import 'reminder_scheduler.dart';

class DebtService {
  DebtService(this.db, {ReminderScheduler? reminders})
    : _ledger = Ledger(db),
      _reminders = reminders ?? const NoopReminderScheduler();

  final AppDatabase db;
  final Ledger _ledger;
  final ReminderScheduler _reminders;

  /// نوع حركة الدين عند إنشاء الدين.
  static TxType creationMovement(DebtDirection d) =>
      d == DebtDirection.owedToMe ? TxType.debtOut : TxType.debtIn;

  /// نوع حركة الدين عند تسجيل دفعة.
  static TxType paymentMovement(DebtDirection d) =>
      d == DebtDirection.owedToMe ? TxType.debtIn : TxType.debtOut;

  /// الحالة المحسوبة من المبلغ والمدفوع.
  static DebtStatus statusFor(int amount, int paid) {
    if (paid <= 0) return DebtStatus.open;
    if (paid >= amount) return DebtStatus.settled;
    return DebtStatus.partial;
  }

  // ---------------------------------------------------------------------------
  // الديون (UC-07)
  // ---------------------------------------------------------------------------

  Future<int> createDebt(DebtDraft draft) async {
    final id = await db.transaction(() async {
      await _validateDraft(draft);
      final currencyId = await _ledger.baseCurrencyId();
      final debtId = await db
          .into(db.debts)
          .insert(
            DebtsCompanion.insert(
              contactId: draft.contactId,
              direction: draft.direction,
              amount: draft.amount,
              currencyId: currencyId,
              accountId: Value(draft.accountId),
              startDate: draft.startDate,
              dueDate: Value(draft.dueDate),
              status: DebtStatus.open,
              note: Value(_clean(draft.note)),
              remind: Value(draft.remind),
            ),
          );
      await _insertCreationMovement(debtId, draft, currencyId);
      return debtId;
    });
    await _syncReminder(id);
    return id;
  }

  /// تعديل دين: يُعاد بناء «حركة الإنشاء» حسب البيانات الجديدة.
  /// لا يُسمح بمبلغ أقل مما سُدِّد، ولا بتغيير الاتجاه بعد وجود دفعات.
  Future<void> updateDebt(int id, DebtDraft draft) async {
    await db.transaction(() async {
      final old = await _requireDebt(id);
      if (draft.amount < old.paidAmount) {
        throw BusinessException(
          BusinessError.debtAmountBelowPaid,
          old.paidAmount,
        );
      }
      final direction = old.paidAmount > 0 ? old.direction : draft.direction;
      final effective = DebtDraft(
        contactId: draft.contactId,
        direction: direction,
        amount: draft.amount,
        startDate: draft.startDate,
        dueDate: draft.dueDate,
        accountId: draft.accountId,
        note: draft.note,
        remind: draft.remind,
      );
      // الحساب القديم (حتى لو أصبح مؤرشفاً) مسموح إذا لم يتغير.
      await _validateDraft(effective, allowArchived: old.accountId);

      // عكس حركة الإنشاء القديمة وحذفها ثم إنشاء الجديدة.
      final oldMovements = await (db.select(
        db.transactions,
      )..where((t) => t.debtId.equals(id) & t.debtPaymentId.isNull())).get();
      for (final tx in oldMovements) {
        await _ledger.remove(tx);
      }

      await (db.update(db.debts)..where((d) => d.id.equals(id))).write(
        DebtsCompanion(
          contactId: Value(effective.contactId),
          direction: Value(direction),
          amount: Value(effective.amount),
          accountId: Value(effective.accountId),
          startDate: Value(effective.startDate),
          dueDate: Value(effective.dueDate),
          note: Value(_clean(effective.note)),
          remind: Value(effective.remind),
          status: Value(statusFor(effective.amount, old.paidAmount)),
        ),
      );
      await _insertCreationMovement(id, effective, old.currencyId);
    });
    await _syncReminder(id);
  }

  /// حذف دين مع كل دفعاته وحركاته (وتُعاد الأرصدة كما كانت).
  Future<void> deleteDebt(int id) async {
    await db.transaction(() async {
      await _requireDebt(id);
      final movements = await (db.select(
        db.transactions,
      )..where((t) => t.debtId.equals(id))).get();
      for (final tx in movements) {
        await _ledger.remove(tx);
      }
      await (db.delete(
        db.debtPayments,
      )..where((p) => p.debtId.equals(id))).go();
      await (db.delete(db.debts)..where((d) => d.id.equals(id))).go();
    });
    await _reminders.cancelDebtReminder(id);
  }

  // ---------------------------------------------------------------------------
  // الدفعات (UC-08)
  // ---------------------------------------------------------------------------

  Future<int> recordPayment(int debtId, PaymentDraft draft) async {
    final id = await db.transaction(() async {
      final debt = await _requireDebt(debtId);
      if (debt.status == DebtStatus.settled) {
        throw const BusinessException(BusinessError.debtAlreadySettled);
      }
      if (draft.amount <= 0) {
        throw const BusinessException(BusinessError.invalidAmount);
      }
      final remaining = debt.amount - debt.paidAmount;
      if (draft.amount > remaining) {
        throw BusinessException(
          BusinessError.paymentExceedsRemaining,
          remaining,
        );
      }
      if (draft.accountId != null) {
        await _ledger.requireActiveAccount(draft.accountId!);
      }

      final paymentId = await db
          .into(db.debtPayments)
          .insert(
            DebtPaymentsCompanion.insert(
              debtId: debtId,
              amount: draft.amount,
              paidAt: draft.paidAt,
              accountId: Value(draft.accountId),
              note: Value(_clean(draft.note)),
            ),
          );

      if (draft.accountId != null) {
        await _ledger.insert(
          TransactionsCompanion.insert(
            type: paymentMovement(debt.direction),
            amount: draft.amount,
            currencyId: debt.currencyId,
            accountId: draft.accountId!,
            debtId: Value(debtId),
            debtPaymentId: Value(paymentId),
            date: draft.paidAt,
            note: Value(_clean(draft.note)),
          ),
        );
      }

      await _setPaid(debt, debt.paidAmount + draft.amount);
      return paymentId;
    });
    await _syncReminder(debtId);
    return id;
  }

  /// حذف دفعة: تُعكس حركتها ويُعاد حساب حالة الدين.
  Future<void> deletePayment(int paymentId) async {
    final debtId = await db.transaction(() async {
      final payment = await (db.select(
        db.debtPayments,
      )..where((p) => p.id.equals(paymentId))).getSingleOrNull();
      if (payment == null) {
        throw const BusinessException(BusinessError.notFound);
      }
      final debt = await _requireDebt(payment.debtId);
      final movements = await (db.select(
        db.transactions,
      )..where((t) => t.debtPaymentId.equals(paymentId))).get();
      for (final tx in movements) {
        await _ledger.remove(tx);
      }
      await (db.delete(
        db.debtPayments,
      )..where((p) => p.id.equals(paymentId))).go();
      await _setPaid(debt, debt.paidAmount - payment.amount);
      return debt.id;
    });
    await _syncReminder(debtId);
  }

  /// الحساب المقترح للدفعة: حساب إنشاء الدين إن كان نشطاً، وإلا الافتراضي.
  Future<Account?> suggestPaymentAccount(int debtId) async {
    final debt = await _requireDebt(debtId);
    if (debt.accountId != null) {
      final account = await (db.select(
        db.accounts,
      )..where((a) => a.id.equals(debt.accountId!))).getSingleOrNull();
      if (account != null && !account.isArchived) return account;
    }
    return (db.select(db.accounts)
          ..where((a) => a.isDefault.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // القراءة
  // ---------------------------------------------------------------------------

  Future<Debt?> getDebt(int id) =>
      (db.select(db.debts)..where((d) => d.id.equals(id))).getSingleOrNull();

  /// مجموع «لي» و«عليّ» المتبقي — تجميع داخل قاعدة البيانات.
  Stream<DebtTotals> watchTotals() => db
      .customSelect(
        '''
        SELECT
          COALESCE(SUM(CASE WHEN direction = '${DebtDirection.owedToMe.name}'
                            THEN amount - paid_amount END), 0) AS owed,
          COALESCE(SUM(CASE WHEN direction = '${DebtDirection.iOwe.name}'
                            THEN amount - paid_amount END), 0) AS owe
        FROM debts
        ''',
        readsFrom: {db.debts},
      )
      .map(
        (r) =>
            DebtTotals(owedToMe: r.read<int>('owed'), iOwe: r.read<int>('owe')),
      )
      .watchSingle();

  /// قائمة الأشخاص في دفتر الديون مع المتبقي والتقدم وأقرب استحقاق.
  /// [direction]: لتبويبات «لي» / «عليّ» (null = الكل).
  Stream<List<PersonSummary>> watchPeople({
    DebtDirection? direction,
    String query = '',
  }) {
    final d = db.debts;
    final c = db.contacts;
    final notSettled = d.status.equals(DebtStatus.settled.name).not();
    Expression<int> remainingFor(DebtDirection dir) => CaseWhenExpression(
      cases: [
        CaseWhen(d.direction.equals(dir.name), then: d.amount - d.paidAmount),
      ],
      orElse: const Constant(0),
    );
    final owed = remainingFor(DebtDirection.owedToMe).sum();
    final owe = remainingFor(DebtDirection.iOwe).sum();
    final total = d.amount.sum();
    final paid = d.paidAmount.sum();
    final openCount = CaseWhenExpression<int>(
      cases: [CaseWhen(notSettled, then: const Constant(1))],
      orElse: const Constant(0),
    ).sum();
    final nearest = CaseWhenExpression<DateTime>(
      cases: [CaseWhen(notSettled, then: d.dueDate)],
    ).min();

    final q = db.select(c).join([innerJoin(d, d.contactId.equalsExp(c.id))])
      ..addColumns([owed, owe, total, paid, openCount, nearest])
      ..where(c.isActive.equals(true))
      ..groupBy([c.id]);
    if (direction != null) q.where(d.direction.equals(direction.name));
    final text = query.trim();
    if (text.isNotEmpty) {
      q.where(c.name.like('%$text%') | c.phone.like('%$text%'));
    }
    q.orderBy([
      // المفتوحة أولاً، ثم الأقرب استحقاقاً، ثم أبجدياً.
      OrderingTerm.desc(openCount),
      OrderingTerm(expression: nearest, nulls: NullsOrder.last),
      OrderingTerm.asc(c.name),
    ]);

    return q.watch().map(
      (rows) => [
        for (final r in rows)
          PersonSummary(
            contact: r.readTable(c),
            owedToMeRemaining: r.read(owed) ?? 0,
            iOweRemaining: r.read(owe) ?? 0,
            totalAmount: r.read(total) ?? 0,
            paidAmount: r.read(paid) ?? 0,
            openDebts: r.read(openCount) ?? 0,
            nearestDue: r.read(nearest),
          ),
      ],
    );
  }

  /// الملف المالي للشخص مع الخط الزمني (FR-18) — يتحدث تلقائياً.
  Stream<PersonProfile?> watchProfile(int contactId) => db.watchTables({
    db.contacts,
    db.debts,
    db.debtPayments,
    db.accounts,
  }, () => profile(contactId));

  Future<PersonProfile?> profile(int contactId) async {
    final contact = await (db.select(
      db.contacts,
    )..where((c) => c.id.equals(contactId))).getSingleOrNull();
    if (contact == null) return null;

    final debtRows =
        await (db.select(db.debts).join([
                leftOuterJoin(
                  db.accounts,
                  db.accounts.id.equalsExp(db.debts.accountId),
                ),
              ])
              ..where(db.debts.contactId.equals(contactId))
              ..orderBy([OrderingTerm.desc(db.debts.startDate)]))
            .get();
    final debts = [for (final r in debtRows) r.readTable(db.debts)];

    final payAccount = db.alias(db.accounts, 'pay_acc');
    final paymentRows = await (db.select(db.debtPayments).join([
      innerJoin(db.debts, db.debts.id.equalsExp(db.debtPayments.debtId)),
      leftOuterJoin(
        payAccount,
        payAccount.id.equalsExp(db.debtPayments.accountId),
      ),
    ])..where(db.debts.contactId.equals(contactId))).get();

    final timeline = <TimelineEntry>[
      for (final r in debtRows)
        () {
          final debt = r.readTable(db.debts);
          return TimelineEntry(
            kind: TimelineKind.debt,
            date: debt.startDate,
            amount: debt.amount,
            direction: debt.direction,
            debtId: debt.id,
            note: debt.note,
            accountName: r.readTableOrNull(db.accounts)?.name,
          );
        }(),
      for (final r in paymentRows)
        () {
          final p = r.readTable(db.debtPayments);
          return TimelineEntry(
            kind: TimelineKind.payment,
            date: p.paidAt,
            amount: p.amount,
            direction: r.readTable(db.debts).direction,
            debtId: p.debtId,
            paymentId: p.id,
            note: p.note,
            accountName: r.readTableOrNull(payAccount)?.name,
          );
        }(),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return PersonProfile(contact: contact, debts: debts, timeline: timeline);
  }

  /// ديون غير مسددة يحل استحقاقها خلال [days] يوماً (أو متأخرة).
  Future<List<UpcomingDebt>> upcomingDue({int days = 7, DateTime? now}) async {
    final n = now ?? DateTime.now();
    final limit = DateTime(n.year, n.month, n.day + days + 1);
    final rows =
        await (db.select(db.debts).join([
                innerJoin(
                  db.contacts,
                  db.contacts.id.equalsExp(db.debts.contactId),
                ),
              ])
              ..where(
                db.debts.status.equals(DebtStatus.settled.name).not() &
                    db.debts.dueDate.isNotNull() &
                    db.debts.dueDate.isSmallerThanValue(limit),
              )
              ..orderBy([OrderingTerm.asc(db.debts.dueDate)]))
            .get();
    return [
      for (final r in rows)
        UpcomingDebt(
          debt: r.readTable(db.debts),
          contactName: r.readTable(db.contacts).name,
        ),
    ];
  }

  // ---------------------------------------------------------------------------
  // أدوات داخلية
  // ---------------------------------------------------------------------------

  Future<void> _insertCreationMovement(
    int debtId,
    DebtDraft draft,
    int currencyId,
  ) async {
    if (draft.accountId == null) return; // بيع/شراء بالآجل: الدفتر فقط.
    await _ledger.insert(
      TransactionsCompanion.insert(
        type: creationMovement(draft.direction),
        amount: draft.amount,
        currencyId: currencyId,
        accountId: draft.accountId!,
        debtId: Value(debtId),
        date: draft.startDate,
        note: Value(_clean(draft.note)),
      ),
    );
  }

  Future<void> _setPaid(Debt debt, int paid) =>
      (db.update(db.debts)..where((d) => d.id.equals(debt.id))).write(
        DebtsCompanion(
          paidAmount: Value(paid),
          status: Value(statusFor(debt.amount, paid)),
        ),
      );

  Future<void> _validateDraft(DebtDraft draft, {int? allowArchived}) async {
    if (draft.amount <= 0) {
      throw const BusinessException(BusinessError.invalidAmount);
    }
    final contact = await (db.select(
      db.contacts,
    )..where((c) => c.id.equals(draft.contactId))).getSingleOrNull();
    if (contact == null) throw const BusinessException(BusinessError.notFound);
    final accountId = draft.accountId;
    if (accountId != null && accountId != allowArchived) {
      await _ledger.requireActiveAccount(accountId);
    }
  }

  Future<Debt> _requireDebt(int id) async {
    final debt = await getDebt(id);
    if (debt == null) throw const BusinessException(BusinessError.notFound);
    return debt;
  }

  /// يجدول أو يلغي تذكير الدين حسب حالته الحالية.
  Future<void> _syncReminder(int debtId) async {
    final debt = await getDebt(debtId);
    if (debt == null) return;
    if (!debt.remind ||
        debt.dueDate == null ||
        debt.status == DebtStatus.settled) {
      await _reminders.cancelDebtReminder(debtId);
      return;
    }
    final contact = await (db.select(
      db.contacts,
    )..where((c) => c.id.equals(debt.contactId))).getSingle();
    await _reminders.scheduleDebtReminder(
      debtId: debtId,
      dueDate: debt.dueDate!,
      contactName: contact.name,
      remaining: debt.amount - debt.paidAmount,
      owedToMe: debt.direction == DebtDirection.owedToMe,
    );
  }

  static String? _clean(String? s) {
    final v = s?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}
