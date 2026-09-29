// =============================================================================
// خدمة الديون (DebtService) — وفق وثيقة «وحدة الديون — الإضافات الأخيرة».
//
// المبدأ المحاسبي:
// - الدين «لي» أصل (مال لي عند غيري)، والدين «عليّ» التزام.
// - نقل المال بين الحساب والدين ليس دخلاً ولا مصروفاً.
// - الدخل والمصروف يظهران هنا في حالتين فقط: البيع/الشراء بالآجل،
//   والمسامحة/الإعفاء.
//
// القيد المحاسبي لكل عملية:
//   إقراض من حساب (لي)      → debtOut على الحساب
//   اقتراض إلى حساب (عليّ)   → debtIn على الحساب
//   بيع بالآجل (لي)          → income بفئة، بلا حساب
//   شراء بالآجل (عليّ)        → expense بفئة، بلا حساب
//   دين سابق                 → لا قيد (الدفتر فقط)
//   استلام (لي) / سداد (عليّ) → debtIn / debtOut: حركة واحدة للعملية كلها
//   مسامحة دين لي            → writeOff (مصروف) بلا حساب
//   إعفاء من دين عليّ         → debtForgiven (دخل) بلا حساب
//
// المدفوع والمتبقي والحالة لا تُخزَّن: تُحسب من الدفعات غير الملغاة والمسامحة.
// كل عملية داخل db.transaction واحدة: تنجح كل أجزائها معاً أو تفشل معاً.
// =============================================================================

import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';

import '../core/errors/app_exception.dart';
import '../data/database/app_database.dart';
import '../domain/enums.dart';
import '../domain/models/debt_models.dart';
import 'ledger.dart';
import 'reminder_scheduler.dart';

/// دين مفتوح مع متبقّيه (للتوزيع والمسامحة).
typedef OpenDebt = ({Debt debt, int remaining});

class DebtService {
  DebtService(
    this.db, {
    ReminderScheduler? reminders,
    DateTime Function()? clock,
  }) : _ledger = Ledger(db),
       _reminders = reminders ?? const NoopReminderScheduler(),
       _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final Ledger _ledger;
  final ReminderScheduler _reminders;

  /// الوقت الحالي (قابل للاستبدال في الاختبارات لقواعد «اليوم»).
  final DateTime Function() _clock;

  static const _entryTypes = [
    TxType.debtIn,
    TxType.debtOut,
    TxType.income,
    TxType.expense,
  ];
  static const _writeOffTypes = [TxType.writeOff, TxType.debtForgiven];

  /// حركة الحساب عند الإقراض (لي) أو الاقتراض (عليّ).
  static TxType creationMovement(DebtDirection d) =>
      d == DebtDirection.owedToMe ? TxType.debtOut : TxType.debtIn;

  /// حركة الحساب عند الاستلام (لي) أو السداد (عليّ).
  static TxType paymentMovement(DebtDirection d) =>
      d == DebtDirection.owedToMe ? TxType.debtIn : TxType.debtOut;

  /// قيد المسامحة (لي → مصروف) أو الإعفاء (عليّ → دخل).
  static TxType writeOffType(DebtDirection d) =>
      d == DebtDirection.owedToMe ? TxType.writeOff : TxType.debtForgiven;

  /// نوع فئة قيد المسامحة/الإعفاء.
  static CategoryKind writeOffCategoryKind(DebtDirection d) =>
      d == DebtDirection.owedToMe ? CategoryKind.expense : CategoryKind.income;

  static DebtDirection opposite(DebtDirection d) =>
      d == DebtDirection.owedToMe ? DebtDirection.iOwe : DebtDirection.owedToMe;

  /// توزيع [amount] على الديون المفتوحة بالترتيب المعطى (الأقدم أولاً):
  /// take = MIN(X, R(d)) حتى ينفد المبلغ.
  static List<PaymentAllocation> allocate(
    List<({int debtId, int remaining})> open,
    int amount,
  ) {
    final result = <PaymentAllocation>[];
    var left = amount;
    for (final d in open) {
      if (left <= 0) break;
      final take = min(left, d.remaining);
      if (take <= 0) continue;
      result.add(PaymentAllocation(debtId: d.debtId, amount: take));
      left -= take;
    }
    return result;
  }

  /// معرّف عملية جديد (UUID v4).
  static String newOperationId() {
    final random = Random.secure();
    final b = List<int>.generate(16, (_) => random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  // ---------------------------------------------------------------------------
  // الديون (UC-07)
  // ---------------------------------------------------------------------------

  Future<int> createDebt(DebtDraft draft) async {
    final id = await db.transaction(() async {
      await _validateDraft(draft);
      final currencyId = await _ledger.baseCurrencyId();
      final debtId = await _insertDebtRow(draft, currencyId);
      await _insertEntry(debtId, draft, currencyId);
      return debtId;
    });
    _syncReminderInBackground(id);
    return id;
  }

  /// تعديل دين (8.2):
  /// - الأصل الجديد ≥ المدفوع + المُسامَح.
  /// - الأثر يُطبَّق بالفرق فقط على نفس القيد (الحساب أو الدخل أو المصروف).
  /// - مع وجود دفعات أو مسامحة لا يتغير الاتجاه ولا المصدر ولا الشخص.
  Future<void> updateDebt(int id, DebtDraft draft) async {
    await db.transaction(() async {
      final old = await _requireDebt(id);
      final paid = await _paidOf(id);
      final hasMovements = paid > 0 || old.writtenOff > 0;
      if (hasMovements &&
          (draft.direction != old.direction ||
              draft.source != old.source ||
              draft.contactId != old.contactId)) {
        throw const BusinessException(BusinessError.debtHasMovements);
      }
      if (draft.amount < paid + old.writtenOff) {
        throw BusinessException(
          BusinessError.debtAmountBelowPaid,
          paid + old.writtenOff,
        );
      }
      await _validateDraft(draft, old: old);
      final firstMovement = await _firstMovementDate(id);
      if (firstMovement != null &&
          _day(draft.startDate).isAfter(_day(firstMovement))) {
        throw const BusinessException(BusinessError.paymentBeforeDebt);
      }

      final accountId = draft.source.needsAccount ? draft.accountId : null;
      final entry = await _entryOf(id);
      if (entry != null &&
          old.source == draft.source &&
          old.direction == draft.direction) {
        // نفس القيد يُعدَّل: عكس أثره القديم ثم تطبيق الجديد = الفرق فقط.
        await _ledger.applyTx(entry, sign: -1);
        await (db.update(
          db.transactions,
        )..where((t) => t.id.equals(entry.id))).write(
          TransactionsCompanion(
            amount: Value(draft.amount),
            accountId: Value(accountId),
            categoryId: Value(
              draft.source.needsCategory ? draft.categoryId : null,
            ),
            date: Value(draft.startDate),
            note: Value(_clean(draft.note)),
            updatedAt: Value(_clock()),
          ),
        );
        await _ledger.applyEffect(
          type: entry.type,
          amount: draft.amount,
          accountId: accountId,
        );
      } else {
        if (entry != null) await _ledger.remove(entry);
        await _insertEntry(id, draft, old.currencyId);
      }

      await (db.update(db.debts)..where((d) => d.id.equals(id))).write(
        DebtsCompanion(
          contactId: Value(draft.contactId),
          direction: Value(draft.direction),
          source: Value(draft.source),
          amount: Value(draft.amount),
          accountId: Value(accountId),
          startDate: Value(draft.startDate),
          dueDate: Value(draft.dueDate),
          note: Value(_clean(draft.note)),
          remind: Value(draft.remind && draft.dueDate != null),
          updatedAt: Value(_clock()),
        ),
      );
    });
    _syncReminderInBackground(id);
  }

  /// حذف دين (8.3): مسموح فقط إن لم تكن عليه دفعات (غير ملغاة) ولا مسامحة —
  /// أي خطأ إدخال. يُحذف مع قيده فيعود الحساب أو الدخل أو المصروف كما كان.
  Future<void> deleteDebt(int id) async {
    await db.transaction(() async {
      final debt = await _requireDebt(id);
      if (await _paidOf(id) > 0 || debt.writtenOff > 0) {
        throw const BusinessException(BusinessError.debtHasMovements);
      }
      final linked = await (db.select(
        db.transactions,
      )..where((t) => t.debtId.equals(id))).get();
      for (final tx in linked) {
        await _ledger.remove(tx);
      }
      await (db.delete(
        db.debtPayments,
      )..where((p) => p.debtId.equals(id))).go();
      await (db.delete(db.debts)..where((d) => d.id.equals(id))).go();
    });
    _inBackground(() => _reminders.cancelDebtReminder(id));
  }

  // ---------------------------------------------------------------------------
  // الاستلام والسداد (UC-08، القسم 6)
  // ---------------------------------------------------------------------------

  /// استلام مبلغ (لي) أو سداد مبلغ (عليّ): يُوزَّع تلقائياً على ديون الشخص
  /// المفتوحة في نفس الاتجاه، الأقدم أولاً، وكل الدفعات الناتجة تحمل معرّف
  /// عملية واحداً، ومعها حركة حساب واحدة.
  ///
  /// إن زاد المبلغ عن مجموع المتبقي تُرمى [BusinessError.paymentExceedsRemaining]
  /// (مع المتبقي)، إلا إذا وافق المستخدم على تسجيل الزائد ديناً معاكساً
  /// ([excessAsOppositeDebt]).
  Future<PaymentResult> recordPayment(
    PaymentDraft draft, {
    bool excessAsOppositeDebt = false,
  }) async {
    final result = await db.transaction(() async {
      if (draft.amount <= 0) {
        throw const BusinessException(BusinessError.invalidAmount);
      }
      await _requireContact(draft.contactId);
      await _ledger.requireActiveAccount(draft.accountId);
      if (_day(draft.paidAt).isAfter(_today)) {
        throw const BusinessException(BusinessError.dateInFuture);
      }
      var open = await openDebts(draft.contactId, draft.direction);
      if (draft.debtId != null) {
        open = [
          for (final o in open)
            if (o.debt.id == draft.debtId) o,
        ];
      }
      if (open.isEmpty) {
        throw const BusinessException(BusinessError.debtAlreadySettled);
      }
      final total = open.fold(0, (s, o) => s + o.remaining);
      var excess = 0;
      if (draft.amount > total) {
        if (!excessAsOppositeDebt) {
          throw BusinessException(BusinessError.paymentExceedsRemaining, total);
        }
        excess = draft.amount - total;
      }

      final allocations = allocate([
        for (final o in open) (debtId: o.debt.id, remaining: o.remaining),
      ], draft.amount - excess);
      // القاعدة 5: تاريخ الدفعة لا يسبق أي دين تُوزَّع عليه.
      final starts = {for (final o in open) o.debt.id: o.debt.startDate};
      for (final a in allocations) {
        if (_day(draft.paidAt).isBefore(_day(starts[a.debtId]!))) {
          throw const BusinessException(BusinessError.paymentBeforeDebt);
        }
      }

      final operationId = newOperationId();
      final currencyId = open.first.debt.currencyId;
      int? firstPayment;
      for (final a in allocations) {
        final paymentId = await db
            .into(db.debtPayments)
            .insert(
              DebtPaymentsCompanion.insert(
                debtId: a.debtId,
                amount: a.amount,
                paidAt: draft.paidAt,
                accountId: Value(draft.accountId),
                note: Value(_clean(draft.note)),
                operationId: Value(operationId),
              ),
            );
        firstPayment ??= paymentId;
      }
      // المال تحرك مرة واحدة: حركة حساب واحدة للعملية كلها.
      await _ledger.insert(
        TransactionsCompanion.insert(
          type: paymentMovement(draft.direction),
          amount: draft.amount - excess,
          currencyId: currencyId,
          accountId: Value(draft.accountId),
          debtId: Value(allocations.first.debtId),
          debtPaymentId: Value(firstPayment),
          date: draft.paidAt,
          note: Value(_clean(draft.note)),
        ),
      );

      int? excessDebtId;
      if (excess > 0) {
        // الزائد دين معاكس: استلمتُ أكثر من المستحق فصار عليّ الزائد لصاحبه
        // (وسددتُ أكثر مما عليّ فصار لي الزائد عنده). المال دخل/خرج فعلاً،
        // فهو إقراض/اقتراض على الحساب نفسه.
        final excessDraft = DebtDraft(
          contactId: draft.contactId,
          direction: opposite(draft.direction),
          source: DebtSource.loan,
          amount: excess,
          startDate: draft.paidAt,
          accountId: draft.accountId,
          note: draft.excessNote,
        );
        excessDebtId = await _insertDebtRow(excessDraft, currencyId);
        await _insertEntry(excessDebtId, excessDraft, currencyId);
      }
      return PaymentResult(
        operationId: operationId,
        allocations: allocations,
        excessDebtId: excessDebtId,
      );
    });
    for (final a in result.allocations) {
      _syncReminderInBackground(a.debtId);
    }
    return result;
  }

  /// إلغاء عملية استلام/سداد كاملة (8.1): الدفعات لا تُحذف بل تُعلَّم
  /// «ملغاة»، وتُعكس حركة الحساب، ويعود المتبقي والحالة تلقائياً.
  Future<void> cancelOperation(String operationId) async {
    final payments = await (db.select(
      db.debtPayments,
    )..where((p) => p.operationId.equals(operationId))).get();
    await _cancel(payments);
  }

  /// إلغاء دفعة: إن كانت جزءاً من عملية موزّعة تُلغى العملية كاملة.
  Future<void> cancelPayment(int paymentId) async {
    final payment = await (db.select(
      db.debtPayments,
    )..where((p) => p.id.equals(paymentId))).getSingleOrNull();
    if (payment == null) throw const BusinessException(BusinessError.notFound);
    if (payment.operationId == null) return _cancel([payment]);
    return cancelOperation(payment.operationId!);
  }

  Future<void> _cancel(List<DebtPayment> payments) async {
    if (payments.isEmpty) throw const BusinessException(BusinessError.notFound);
    final ids = [for (final p in payments) p.id];
    await db.transaction(() async {
      final fresh = await (db.select(
        db.debtPayments,
      )..where((p) => p.id.isIn(ids))).get();
      if (fresh.every((p) => p.isCancelled)) {
        throw const BusinessException(BusinessError.paymentAlreadyCancelled);
      }
      final movements = await (db.select(
        db.transactions,
      )..where((t) => t.debtPaymentId.isIn(ids))).get();
      for (final tx in movements) {
        await _ledger.remove(tx);
      }
      await (db.update(db.debtPayments)..where((p) => p.id.isIn(ids))).write(
        DebtPaymentsCompanion(
          isCancelled: const Value(true),
          cancelledAt: Value(_clock()),
        ),
      );
    });
    for (final debtId in {for (final p in payments) p.debtId}) {
      _syncReminderInBackground(debtId);
    }
  }

  /// الحساب المقترح للاستلام/السداد: حساب إقراض أقدم دين مفتوح إن كان نشطاً،
  /// وإلا الحساب الافتراضي.
  Future<Account?> suggestPaymentAccount(
    int contactId,
    DebtDirection direction, {
    int? debtId,
  }) async {
    for (final o in await openDebts(contactId, direction)) {
      if (debtId != null && o.debt.id != debtId) continue;
      final accountId = o.debt.accountId;
      if (accountId == null) continue;
      final account = await (db.select(
        db.accounts,
      )..where((a) => a.id.equals(accountId))).getSingleOrNull();
      if (account != null && !account.isArchived) return account;
    }
    return (db.select(db.accounts)
          ..where((a) => a.isDefault.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // المسامحة (القسم 4)
  // ---------------------------------------------------------------------------

  /// «مسامحة بالمتبقي»: يُغلق الدين (أو كل ديون الاتجاه إن لم يُحدَّد
  /// [debtId]) ويُسجَّل لكل دين قيد مستقل: مصروف «مسامحة ديون» لديون «لي»،
  /// أو دخل «إعفاء دين» لديون «عليّ». لا تتحرك أي أرصدة حسابات.
  Future<void> writeOffRemaining({
    required int contactId,
    required DebtDirection direction,
    required DateTime date,
    required int categoryId,
    int? debtId,
    String? note,
  }) async {
    final debtIds = await db.transaction(() async {
      await _requireContact(contactId);
      var open = await openDebts(contactId, direction);
      if (debtId != null) {
        open = [
          for (final o in open)
            if (o.debt.id == debtId) o,
        ];
      }
      if (open.isEmpty) {
        throw const BusinessException(BusinessError.debtAlreadySettled);
      }
      if (_day(date).isAfter(_today)) {
        throw const BusinessException(BusinessError.dateInFuture);
      }
      for (final o in open) {
        if (_day(date).isBefore(_day(o.debt.startDate))) {
          throw const BusinessException(BusinessError.paymentBeforeDebt);
        }
      }
      final category = await (db.select(
        db.categories,
      )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      if (category == null) {
        throw const BusinessException(BusinessError.categoryRequired);
      }
      if (category.kind != writeOffCategoryKind(direction)) {
        throw const BusinessException(BusinessError.categoryKindMismatch);
      }
      for (final o in open) {
        await _ledger.insert(
          TransactionsCompanion.insert(
            type: writeOffType(direction),
            amount: o.remaining,
            currencyId: o.debt.currencyId,
            categoryId: Value(categoryId),
            debtId: Value(o.debt.id),
            date: date,
            note: Value(_clean(note)),
          ),
        );
        await (db.update(db.debts)..where((d) => d.id.equals(o.debt.id))).write(
          DebtsCompanion(
            writtenOff: Value(o.debt.writtenOff + o.remaining),
            updatedAt: Value(_clock()),
          ),
        );
      }
      return [for (final o in open) o.debt.id];
    });
    for (final id in debtIds) {
      _syncReminderInBackground(id);
    }
  }

  // ---------------------------------------------------------------------------
  // القراءة
  // ---------------------------------------------------------------------------

  Future<Debt?> getDebt(int id) =>
      (db.select(db.debts)..where((d) => d.id.equals(id))).getSingleOrNull();

  /// الدين مع أرقامه المحسوبة (لشاشة التعديل).
  Future<DebtView?> debtView(int id) async =>
      (await _debtViews(debtId: id)).firstOrNull;

  /// الديون المفتوحة لشخص في اتجاه، الأقدم أولاً (ترتيب التوزيع).
  Future<List<OpenDebt>> openDebts(
    int contactId,
    DebtDirection direction,
  ) async {
    final remaining = AppDatabase.remainingSql('d');
    final rows = await db
        .customSelect(
          'SELECT d.*, $remaining AS remaining_amount FROM debts d '
          'WHERE d.contact_id = ?1 AND d.direction = ?2 AND $remaining > 0 '
          'ORDER BY d.start_date, d.id',
          variables: [
            Variable.withInt(contactId),
            Variable.withString(direction.name),
          ],
          readsFrom: {db.debts, db.debtPayments},
        )
        .get();
    return [
      for (final r in rows)
        (
          debt: db.debts.map(r.data),
          remaining: r.read<int>('remaining_amount'),
        ),
    ];
  }

  /// مجموع «لي» و«عليّ» (5.3) مع عدد الأشخاص والديون المتأخرة.
  /// لا يُستبعد أحد: الشخص المؤرشف متبقّيه صفر بالضرورة.
  Stream<DebtTotals> watchTotals() {
    final remaining = AppDatabase.remainingSql('d');
    return db
        .customSelect(
          '''
          SELECT
            COALESCE(SUM(CASE WHEN x.direction = '${DebtDirection.owedToMe.name}'
                              THEN x.r END), 0) AS owed,
            COALESCE(SUM(CASE WHEN x.direction = '${DebtDirection.iOwe.name}'
                              THEN x.r END), 0) AS owe,
            COUNT(DISTINCT CASE WHEN x.r > 0 THEN x.contact_id END) AS people,
            COALESCE(SUM(CASE WHEN x.r > 0 AND x.due_date < ?1
                              THEN 1 ELSE 0 END), 0) AS overdue
          FROM (SELECT d.direction, d.contact_id, d.due_date, $remaining AS r
                FROM debts d) x
          ''',
          variables: [Variable.withDateTime(_today)],
          readsFrom: {db.debts, db.debtPayments},
        )
        .map(
          (r) => DebtTotals(
            owedToMe: r.read<int>('owed'),
            iOwe: r.read<int>('owe'),
            people: r.read<int>('people'),
            overdueDebts: r.read<int>('overdue'),
          ),
        )
        .watchSingle();
  }

  /// قائمة الأشخاص في دفتر الديون: تبويب الاتجاه ([direction] = null للكل)،
  /// والبحث بالاسم أو الهاتف، والفلتر (الحالة والترتيب).
  Stream<List<PersonSummary>> watchPeople({
    DebtDirection? direction,
    String query = '',
    PeopleFilter filter = const PeopleFilter(),
  }) {
    final paid = AppDatabase.paidSql('x');
    final remaining = AppDatabase.remainingSql('x');
    final text = query.trim();
    final writeOffs = _writeOffTypes.map((t) => "'${t.name}'").join(', ');
    final sql =
        '''
      SELECT c.*,
        COALESCE(SUM(CASE WHEN d.direction = '${DebtDirection.owedToMe.name}'
                          THEN d.r END), 0) AS receivable,
        COALESCE(SUM(CASE WHEN d.direction = '${DebtDirection.iOwe.name}'
                          THEN d.r END), 0) AS payable,
        COALESCE(SUM(d.amount), 0) AS total_amount,
        COALESCE(SUM(d.paid), 0) AS total_paid,
        COALESCE(SUM(d.written_off), 0) AS total_written_off,
        COALESCE(SUM(CASE WHEN d.r > 0 THEN 1 ELSE 0 END), 0) AS open_count,
        COALESCE(SUM(CASE WHEN d.r > 0 AND d.due_date < ?1 THEN 1 ELSE 0 END), 0)
          AS overdue_count,
        MIN(CASE WHEN d.r > 0 THEN d.due_date END) AS nearest_due,
        MAX(d.activity) AS last_activity
      FROM contacts c
      JOIN (
        SELECT x.*, $paid AS paid, $remaining AS r,
          MAX(x.start_date,
              COALESCE((SELECT MAX(p.paid_at) FROM debt_payments p
                        WHERE p.debt_id = x.id), 0),
              COALESCE((SELECT MAX(t.date) FROM transactions t
                        WHERE t.debt_id = x.id AND t.type IN ($writeOffs)), 0))
            AS activity
        FROM debts x
        WHERE ?2 = '' OR x.direction = ?2
      ) d ON d.contact_id = c.id
      WHERE ?3 = '' OR c.name LIKE ?4 OR c.phone LIKE ?4
      GROUP BY c.id
      ''';
    return db
        .customSelect(
          sql,
          variables: [
            Variable.withDateTime(_today),
            Variable.withString(direction?.name ?? ''),
            Variable.withString(text),
            Variable.withString('%$text%'),
          ],
          readsFrom: {db.contacts, db.debts, db.debtPayments, db.transactions},
        )
        .watch()
        .map((rows) {
          final people = [
            for (final r in rows)
              PersonSummary(
                contact: db.contacts.map(r.data),
                receivable: r.read<int>('receivable'),
                payable: r.read<int>('payable'),
                total: r.read<int>('total_amount'),
                paid: r.read<int>('total_paid'),
                writtenOff: r.read<int>('total_written_off'),
                openDebts: r.read<int>('open_count'),
                overdueDebts: r.read<int>('overdue_count'),
                nearestDue: r.readNullable<DateTime>('nearest_due'),
                lastActivity: r.readNullable<DateTime>('last_activity'),
              ),
          ];
          return _filterAndSort(people, filter);
        });
  }

  static List<PersonSummary> _filterAndSort(
    List<PersonSummary> people,
    PeopleFilter filter,
  ) {
    final list = people.where((p) {
      final archived = p.contact.isArchived;
      return switch (filter.status) {
        PeopleStatus.all => !archived,
        PeopleStatus.open => !archived && !p.isClosed,
        PeopleStatus.overdue => !archived && p.overdueDebts > 0,
        PeopleStatus.closed => !archived && p.isClosed,
        PeopleStatus.archived => archived,
      };
    }).toList();
    int byName(PersonSummary a, PersonSummary b) =>
        a.contact.name.compareTo(b.contact.name);
    switch (filter.sort) {
      case PeopleSort.amountDesc:
        list.sort((a, b) {
          final c = b.remaining.compareTo(a.remaining);
          return c != 0 ? c : byName(a, b);
        });
      case PeopleSort.lastActivity:
        list.sort((a, b) {
          final ta = a.lastActivity ?? DateTime(0);
          final tb = b.lastActivity ?? DateTime(0);
          final c = tb.compareTo(ta);
          return c != 0 ? c : byName(a, b);
        });
      case PeopleSort.nearestDue:
        // المفتوحون أولاً، ثم الأقرب استحقاقاً، ثم أبجدياً.
        list.sort((a, b) {
          if (a.isClosed != b.isClosed) return a.isClosed ? 1 : -1;
          final da = a.nearestDue;
          final db = b.nearestDue;
          if (da != null && db != null) {
            final c = da.compareTo(db);
            if (c != 0) return c;
          } else if (da != null || db != null) {
            return da != null ? -1 : 1;
          }
          return byName(a, b);
        });
    }
    return list;
  }

  /// الملف المالي للشخص مع الخط الزمني (FR-18) — يتحدث تلقائياً.
  Stream<PersonProfile?> watchProfile(int contactId) => db.watchTables({
    db.contacts,
    db.debts,
    db.debtPayments,
    db.accounts,
    db.transactions,
    db.categories,
  }, () => profile(contactId));

  Future<PersonProfile?> profile(int contactId) async {
    final contact = await (db.select(
      db.contacts,
    )..where((c) => c.id.equals(contactId))).getSingleOrNull();
    if (contact == null) return null;
    final debts = await _debtViews(contactId: contactId);
    final byId = {for (final d in debts) d.id: d};

    final paymentRows = await db
        .customSelect(
          'SELECT p.*, a.name AS account_name FROM debt_payments p '
          'JOIN debts d ON d.id = p.debt_id '
          'LEFT JOIN accounts a ON a.id = p.account_id '
          'WHERE d.contact_id = ?1 ORDER BY p.id',
          variables: [Variable.withInt(contactId)],
          readsFrom: {db.debtPayments, db.debts, db.accounts},
        )
        .get();
    // دفعات العملية الواحدة سطر واحد مع تفصيل التوزيع.
    final operations =
        <String, List<({DebtPayment payment, String? account})>>{};
    for (final r in paymentRows) {
      final p = db.debtPayments.map(r.data);
      operations.putIfAbsent(p.operationId ?? 'payment-${p.id}', () => []).add((
        payment: p,
        account: r.readNullable<String>('account_name'),
      ));
    }

    final writeOffRows = await db
        .customSelect(
          'SELECT t.*, c.name AS category_name FROM transactions t '
          'JOIN debts d ON d.id = t.debt_id '
          'LEFT JOIN categories c ON c.id = t.category_id '
          'WHERE d.contact_id = ?1 AND t.type IN (?2, ?3)',
          variables: [
            Variable.withInt(contactId),
            Variable.withString(TxType.writeOff.name),
            Variable.withString(TxType.debtForgiven.name),
          ],
          readsFrom: {db.transactions, db.debts, db.categories},
        )
        .get();

    final entries = <TimelineEntry>[
      for (final d in debts)
        TimelineEntry(
          kind: TimelineKind.debt,
          date: d.debt.startDate,
          direction: d.direction,
          amount: d.amount,
          debtId: d.id,
          sequence: d.id,
          source: d.source,
          accountName: d.accountName,
          categoryName: d.categoryName,
          note: d.debt.note,
        ),
      for (final entry in operations.entries)
        () {
          final first = entry.value.first.payment;
          return TimelineEntry(
            kind: TimelineKind.payment,
            date: first.paidAt,
            direction: byId[first.debtId]!.direction,
            amount: entry.value.fold(0, (s, x) => s + x.payment.amount),
            debtId: first.debtId,
            sequence: first.id,
            operationId: entry.key,
            allocations: [
              for (final x in entry.value)
                PaymentAllocation(
                  debtId: x.payment.debtId,
                  amount: x.payment.amount,
                ),
            ],
            accountName: entry.value.first.account,
            note: first.note,
            cancelled: entry.value.every((x) => x.payment.isCancelled),
          );
        }(),
      for (final r in writeOffRows)
        () {
          final t = db.transactions.map(r.data);
          return TimelineEntry(
            kind: TimelineKind.writeOff,
            date: t.date,
            direction: byId[t.debtId]!.direction,
            amount: t.amount,
            debtId: t.debtId!,
            sequence: t.id,
            categoryName: r.readNullable<String>('category_name'),
            note: t.note,
          );
        }(),
    ];

    final now = _clock();
    return PersonProfile(
      contact: contact,
      debts: debts,
      timeline: TimelineEntry.withRunningBalances(entries),
      owedToMe: DirectionSummary.of(DebtDirection.owedToMe, debts, now),
      iOwe: DirectionSummary.of(DebtDirection.iOwe, debts, now),
    );
  }

  /// ديون مفتوحة يحل استحقاقها خلال [days] يوماً (أو متأخرة).
  Future<List<UpcomingDebt>> upcomingDue({int days = 7, DateTime? now}) async {
    final n = now ?? _clock();
    final limit = DateTime(n.year, n.month, n.day + days + 1);
    final remaining = AppDatabase.remainingSql('d');
    final rows = await db
        .customSelect(
          'SELECT d.*, c.name AS contact_name, $remaining AS remaining_amount '
          'FROM debts d JOIN contacts c ON c.id = d.contact_id '
          'WHERE d.due_date IS NOT NULL AND d.due_date < ?1 AND $remaining > 0 '
          'ORDER BY d.due_date',
          variables: [Variable.withDateTime(limit)],
          readsFrom: {db.debts, db.debtPayments, db.contacts},
        )
        .get();
    return [
      for (final r in rows)
        UpcomingDebt(
          debt: db.debts.map(r.data),
          contactName: r.read<String>('contact_name'),
          remaining: r.read<int>('remaining_amount'),
        ),
    ];
  }

  // ---------------------------------------------------------------------------
  // أدوات داخلية
  // ---------------------------------------------------------------------------

  DateTime get _today {
    final n = _clock();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<int> _insertDebtRow(DebtDraft draft, int currencyId) => db
      .into(db.debts)
      .insert(
        DebtsCompanion.insert(
          contactId: draft.contactId,
          direction: draft.direction,
          source: draft.source,
          amount: draft.amount,
          currencyId: currencyId,
          accountId: Value(draft.source.needsAccount ? draft.accountId : null),
          startDate: draft.startDate,
          dueDate: Value(draft.dueDate),
          note: Value(_clean(draft.note)),
          remind: Value(draft.remind && draft.dueDate != null),
        ),
      );

  /// القيد المحاسبي لإنشاء الدين حسب مصدره (القسم 3).
  Future<void> _insertEntry(int debtId, DebtDraft d, int currencyId) async {
    final TxType type;
    switch (d.source) {
      case DebtSource.opening:
        return; // دين سابق: الدفتر فقط.
      case DebtSource.loan:
        type = creationMovement(d.direction);
      case DebtSource.creditSale:
        type = TxType.income;
      case DebtSource.creditPurchase:
        type = TxType.expense;
    }
    await _ledger.insert(
      TransactionsCompanion.insert(
        type: type,
        amount: d.amount,
        currencyId: currencyId,
        accountId: Value(d.source.needsAccount ? d.accountId : null),
        categoryId: Value(d.source.needsCategory ? d.categoryId : null),
        debtId: Value(debtId),
        date: d.startDate,
        note: Value(_clean(d.note)),
      ),
    );
  }

  /// قيد إنشاء الدين (إن وُجد).
  Future<MoneyTransaction?> _entryOf(int debtId) async {
    final rows =
        await (db.select(db.transactions)
              ..where(
                (t) =>
                    t.debtId.equals(debtId) &
                    t.debtPaymentId.isNull() &
                    t.type.isIn([for (final x in _entryTypes) x.name]),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.id)])
              ..limit(1))
            .get();
    return rows.firstOrNull;
  }

  /// المدفوع الفعلي (الدفعات غير الملغاة).
  Future<int> _paidOf(int debtId) async {
    final sum = db.debtPayments.amount.sum();
    final row =
        await (db.selectOnly(db.debtPayments)
              ..addColumns([sum])
              ..where(
                db.debtPayments.debtId.equals(debtId) &
                    db.debtPayments.isCancelled.equals(false),
              ))
            .getSingle();
    return row.read(sum) ?? 0;
  }

  /// أقدم دفعة (غير ملغاة) أو مسامحة على الدين.
  Future<DateTime?> _firstMovementDate(int debtId) async {
    final payments =
        await (db.select(db.debtPayments)
              ..where(
                (p) => p.debtId.equals(debtId) & p.isCancelled.equals(false),
              )
              ..orderBy([(p) => OrderingTerm.asc(p.paidAt)])
              ..limit(1))
            .get();
    final writeOffs =
        await (db.select(db.transactions)
              ..where(
                (t) =>
                    t.debtId.equals(debtId) &
                    t.type.isIn([for (final x in _writeOffTypes) x.name]),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.date)])
              ..limit(1))
            .get();
    final dates = [
      if (payments.isNotEmpty) payments.first.paidAt,
      if (writeOffs.isNotEmpty) writeOffs.first.date,
    ]..sort();
    return dates.firstOrNull;
  }

  Future<List<DebtView>> _debtViews({int? contactId, int? debtId}) async {
    final entryTypes = [
      TxType.income,
      TxType.expense,
    ].map((t) => "'${t.name}'").join(', ');
    final rows = await db
        .customSelect(
          '''
          SELECT d.*, ${AppDatabase.paidSql('d')} AS paid_sum,
            a.name AS account_name,
            (SELECT t.category_id FROM transactions t
              WHERE t.debt_id = d.id AND t.debt_payment_id IS NULL
                AND t.type IN ($entryTypes)
              LIMIT 1) AS entry_category_id,
            (SELECT c.name FROM transactions t
               JOIN categories c ON c.id = t.category_id
              WHERE t.debt_id = d.id AND t.debt_payment_id IS NULL
                AND t.type IN ($entryTypes)
              LIMIT 1) AS category_name
          FROM debts d LEFT JOIN accounts a ON a.id = d.account_id
          WHERE ${contactId != null ? 'd.contact_id' : 'd.id'} = ?1
          ORDER BY d.start_date DESC, d.id DESC
          ''',
          variables: [Variable.withInt(contactId ?? debtId!)],
          readsFrom: {
            db.debts,
            db.debtPayments,
            db.accounts,
            db.transactions,
            db.categories,
          },
        )
        .get();
    return [
      for (final r in rows)
        DebtView(
          debt: db.debts.map(r.data),
          paid: r.read<int>('paid_sum'),
          accountName: r.readNullable<String>('account_name'),
          categoryId: r.readNullable<int>('entry_category_id'),
          categoryName: r.readNullable<String>('category_name'),
        ),
    ];
  }

  Future<void> _validateDraft(DebtDraft d, {Debt? old}) async {
    // القاعدة 1: المبلغ > 0 دائماً، والاتجاه تحدده العملية لا الإشارة.
    if (d.amount <= 0) {
      throw const BusinessException(BusinessError.invalidAmount);
    }
    // القاعدة 7: لا عمليات جديدة على شخص مؤرشف.
    await _requireContact(
      d.contactId,
      allowArchived: old != null && old.contactId == d.contactId,
    );
    if (!d.source.allows(d.direction)) {
      throw const BusinessException(BusinessError.invalidDebtSource);
    }
    // القاعدتان 3 و 4.
    if (_day(d.startDate).isAfter(_today)) {
      throw const BusinessException(BusinessError.dateInFuture);
    }
    if (d.dueDate != null && _day(d.dueDate!).isBefore(_day(d.startDate))) {
      throw const BusinessException(BusinessError.dueBeforeStart);
    }
    if (d.source.needsAccount) {
      final accountId = d.accountId;
      if (accountId == null) {
        throw const BusinessException(BusinessError.accountRequired);
      }
      // الحساب القديم (حتى لو أصبح مؤرشفاً) مسموح إذا لم يتغير.
      if (old?.accountId != accountId) {
        await _ledger.requireActiveAccount(accountId);
      }
    }
    if (d.source.needsCategory) {
      final categoryId = d.categoryId;
      if (categoryId == null) {
        throw const BusinessException(BusinessError.categoryRequired);
      }
      final category = await (db.select(
        db.categories,
      )..where((c) => c.id.equals(categoryId))).getSingleOrNull();
      if (category == null) {
        throw const BusinessException(BusinessError.categoryRequired);
      }
      final expected = d.source == DebtSource.creditSale
          ? CategoryKind.income
          : CategoryKind.expense;
      if (category.kind != expected) {
        throw const BusinessException(BusinessError.categoryKindMismatch);
      }
    }
  }

  Future<Contact> _requireContact(int id, {bool allowArchived = false}) async {
    final contact = await (db.select(
      db.contacts,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (contact == null) throw const BusinessException(BusinessError.notFound);
    if (contact.isArchived && !allowArchived) {
      throw BusinessException(BusinessError.contactArchived, contact.name);
    }
    return contact;
  }

  Future<Debt> _requireDebt(int id) async {
    final debt = await getDebt(id);
    if (debt == null) throw const BusinessException(BusinessError.notFound);
    return debt;
  }

  /// يجدول أو يلغي تذكير الدين حسب متبقّيه الحالي.
  /// التذكير أثر جانبي بعد حفظ العملية: لا يؤخرها ولا يُفشلها. البيانات
  /// محفوظة فعلاً، وتعذّر الإشعارات (رفض الإذن أو غياب الإضافة) لا يُظهر خطأً
  /// للمستخدم عن عملية تمت بنجاح.
  void _syncReminderInBackground(int debtId) =>
      _inBackground(() => _syncReminder(debtId));

  static void _inBackground(Future<void> Function() task) =>
      unawaited(Future(task).catchError((Object _) {}));

  Future<void> _syncReminder(int debtId) async {
    final view = await debtView(debtId);
    if (view == null) return;
    final debt = view.debt;
    if (!debt.remind || debt.dueDate == null || !view.isOpen) {
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
      remaining: view.remaining,
      owedToMe: debt.direction == DebtDirection.owedToMe,
    );
  }

  static String? _clean(String? s) {
    final v = s?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}
