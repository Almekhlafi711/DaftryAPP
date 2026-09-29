// =============================================================================
// خدمة المعاملات: إضافة/تعديل/حذف الدخل والمصروف والتحويل، البحث والفلترة،
// واقتراح الحساب تلقائياً.
//
// كل عملية كتابة تتم داخل db.transaction واحدة: حفظ المعاملة + تحديث الرصيد
// معاً (ذرياً) — فلا يمكن أن يُحفظ أحدهما دون الآخر.
// =============================================================================

import 'package:drift/drift.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/date_range.dart';
import '../data/database/app_database.dart';
import '../domain/enums.dart';
import '../domain/models/transaction_models.dart';
import 'budget_service.dart';
import 'ledger.dart';

class TransactionService {
  TransactionService(this.db, this._budgets) : _ledger = Ledger(db);

  final AppDatabase db;
  final BudgetService _budgets;
  final Ledger _ledger;

  /// الأنواع التي يضيفها المستخدم مباشرة من شاشة «إضافة معاملة».
  static const _userTypes = {TxType.income, TxType.expense, TxType.transfer};

  // ---------------------------------------------------------------------------
  // الإضافة (UC-02)
  // ---------------------------------------------------------------------------

  Future<TxSaveResult> add(TransactionDraft draft) async {
    final id = await db.transaction(() async {
      await _validate(draft);
      return _ledger.insert(
        TransactionsCompanion.insert(
          type: draft.type,
          amount: draft.amount,
          currencyId: await _ledger.baseCurrencyId(),
          accountId: Value(draft.accountId),
          toAccountId: Value(
            draft.type == TxType.transfer ? draft.toAccountId : null,
          ),
          categoryId: Value(
            draft.type == TxType.transfer ? null : draft.categoryId,
          ),
          date: draft.date,
          note: Value(_clean(draft.note)),
          receiptPath: Value(draft.receiptPath),
        ),
      );
    });

    // التحقق من الميزانية بعد الحفظ (الخطوة 6 في UC-02).
    BudgetAlertInfo? alert;
    if (draft.type == TxType.expense && draft.categoryId != null) {
      alert = await _budgets.check(
        categoryId: draft.categoryId!,
        date: draft.date,
        delta: draft.amount,
      );
    }
    return TxSaveResult(id, alert);
  }

  // ---------------------------------------------------------------------------
  // التعديل (UC-03): يُعكس أثر القيمة القديمة ثم يُطبق أثر الجديدة.
  // ---------------------------------------------------------------------------

  Future<TxSaveResult> update(int id, TransactionDraft draft) async {
    final old = await _require(id);

    await db.transaction(() async {
      // قيود الديون تُعدَّل من ملف الشخص وليس من سجل المعاملات.
      if (isDebtLinked(old)) {
        throw const BusinessException(BusinessError.debtMovementReadOnly);
      }

      // التسوية: يُسمح بتعديل التاريخ والملاحظة فقط.
      if (old.type == TxType.adjustment) {
        await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
          TransactionsCompanion(
            date: Value(draft.date),
            note: Value(_clean(draft.note)),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return;
      }

      // قاعدة الأرشفة: معاملة على حساب مؤرشف يُعدَّل مبلغها وتاريخها
      // وملاحظتها فقط، ولا تُنقل إلى حساب آخر أو إليه.
      final oldAccounts = {
        old.accountId!,
        if (old.toAccountId != null) old.toAccountId!,
      };
      final newAccounts = {
        draft.accountId,
        if (draft.type == TxType.transfer && draft.toAccountId != null)
          draft.toAccountId!,
      };
      final touchesArchived = await _anyArchived(oldAccounts);
      if (touchesArchived && !_sameSet(oldAccounts, newAccounts)) {
        throw const BusinessException(
          BusinessError.cannotMoveArchivedTransaction,
        );
      }

      await _validate(
        draft,
        // الحسابات المؤرشفة الأصلية مسموحة فقط إذا لم تتغير.
        allowArchived: touchesArchived ? oldAccounts : const {},
      );

      await _ledger.applyTx(old, sign: -1);
      await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          type: Value(draft.type),
          amount: Value(draft.amount),
          accountId: Value(draft.accountId),
          toAccountId: Value(
            draft.type == TxType.transfer ? draft.toAccountId : null,
          ),
          categoryId: Value(
            draft.type == TxType.transfer ? null : draft.categoryId,
          ),
          date: Value(draft.date),
          note: Value(_clean(draft.note)),
          receiptPath: Value(draft.receiptPath),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _ledger.applyEffect(
        type: draft.type,
        amount: draft.amount,
        accountId: draft.accountId,
        toAccountId: draft.toAccountId,
      );
    });

    BudgetAlertInfo? alert;
    if (draft.type == TxType.expense && draft.categoryId != null) {
      final sameBucket =
          old.type == TxType.expense && old.categoryId == draft.categoryId;
      alert = await _budgets.check(
        categoryId: draft.categoryId!,
        date: draft.date,
        delta: sameBucket ? draft.amount - old.amount : draft.amount,
      );
    }
    return TxSaveResult(id, alert);
  }

  // ---------------------------------------------------------------------------
  // الحذف مع إمكانية التراجع خلال 5 ثوانٍ
  // ---------------------------------------------------------------------------

  /// يحذف المعاملة ويعيد المبلغ للحساب. يعيد الصف المحذوف لاستخدامه في
  /// [restore] إذا ضغط المستخدم «تراجع».
  Future<MoneyTransaction> delete(int id) => db.transaction(() async {
    final tx = await _require(id);
    if (isDebtLinked(tx)) {
      throw const BusinessException(BusinessError.debtMovementReadOnly);
    }
    await _ledger.remove(tx);
    return tx;
  });

  /// التراجع عن الحذف: يعيد نفس المعاملة (بنفس الرقم) ويطبق أثرها مجدداً.
  Future<void> restore(MoneyTransaction tx) => db.transaction(() async {
    await db.into(db.transactions).insert(tx);
    await _ledger.applyTx(tx);
  });

  /// قيد أنشأته وحدة الديون (حركة دين، بيع/شراء بالآجل، مسامحة): يُعدَّل من
  /// ملف الشخص فقط حتى لا يتناقض مع الدين.
  static bool isDebtLinked(MoneyTransaction tx) =>
      tx.type.isDebtEntry || tx.debtId != null || tx.debtPaymentId != null;

  // ---------------------------------------------------------------------------
  // القراءة
  // ---------------------------------------------------------------------------

  Future<MoneyTransaction?> getById(int id) => (db.select(
    db.transactions,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// آخر المعاملات (لقسم «آخر المعاملات» في الرئيسية).
  Stream<List<TransactionView>> watchRecent({int limit = 5}) =>
      watchFiltered(const TransactionFilter(), limit: limit);

  /// سجل المعاملات بعد الفلترة والبحث — استعلام JOIN واحد مع حد (limit)
  /// للتحميل التدريجي عند التمرير.
  ///
  /// [amountFactor]: 10^decimals لعملة التطبيق، لمطابقة البحث بالمبلغ.
  Stream<List<TransactionView>> watchFiltered(
    TransactionFilter filter, {
    int limit = 50,
    int amountFactor = 100,
  }) => _viewQuery(filter, limit: limit, amountFactor: amountFactor).watch();

  Future<List<TransactionView>> getFiltered(
    TransactionFilter filter, {
    int limit = 100000,
    int amountFactor = 100,
  }) => _viewQuery(filter, limit: limit, amountFactor: amountFactor).get();

  Selectable<TransactionView> _viewQuery(
    TransactionFilter f, {
    required int limit,
    required int amountFactor,
  }) {
    final t = db.transactions;
    final toAcc = db.alias(db.accounts, 'to_acc');
    final query = db.select(t).join([
      // قيود الديون التي لا تحرّك مالاً ليس لها حساب.
      leftOuterJoin(db.accounts, db.accounts.id.equalsExp(t.accountId)),
      leftOuterJoin(toAcc, toAcc.id.equalsExp(t.toAccountId)),
      leftOuterJoin(db.categories, db.categories.id.equalsExp(t.categoryId)),
      leftOuterJoin(db.debts, db.debts.id.equalsExp(t.debtId)),
      leftOuterJoin(db.contacts, db.contacts.id.equalsExp(db.debts.contactId)),
    ]);

    final conditions = <Expression<bool>>[];
    if (f.range case final r?) {
      conditions.add(
        t.date.isBiggerOrEqualValue(r.start) & t.date.isSmallerThanValue(r.end),
      );
    }
    if (f.accountIds.isNotEmpty) {
      conditions.add(
        t.accountId.isIn(f.accountIds) | t.toAccountId.isIn(f.accountIds),
      );
    }
    // الأنواع: إن اختار المستخدم أنواعاً نعرضها + حركات الديون إن كانت مفعّلة.
    // «دخل» يشمل الإعفاء من دين، و«مصروف» يشمل مسامحة دين.
    final types = <String>{
      for (final type in f.types) type.name,
      if (f.types.contains(TxType.income)) TxType.debtForgiven.name,
      if (f.types.contains(TxType.expense)) TxType.writeOff.name,
    };
    if (types.isNotEmpty) {
      if (f.showDebtMovements) {
        types.addAll([TxType.debtIn.name, TxType.debtOut.name]);
      }
      conditions.add(t.type.isIn(types));
    } else if (!f.showDebtMovements) {
      conditions.add(t.type.isNotIn([TxType.debtIn.name, TxType.debtOut.name]));
    }
    if (f.categoryIds.isNotEmpty) {
      conditions.add(t.categoryId.isIn(f.categoryIds));
    }
    final q = f.query.trim();
    if (q.isNotEmpty) {
      final like = '%$q%';
      var search =
          t.note.like(like) |
          db.categories.name.like(like) |
          db.accounts.name.like(like) |
          db.contacts.name.like(like);
      // (الحقول الفارغة في الربط الخارجي لا تطابق، فلا تُستبعد القيود بلا حساب.)
      // إن كان النص رقماً نبحث بالمبلغ أيضاً (245 تطابق 245.00).
      final number = double.tryParse(q.replaceAll(',', ''));
      if (number != null) {
        search =
            search | t.amount.abs().equals((number * amountFactor).round());
      }
      conditions.add(search);
    }
    if (conditions.isNotEmpty) {
      query.where(conditions.reduce((a, b) => a & b));
    }

    query.orderBy(switch (f.sort) {
      TransactionSort.newest => [
        OrderingTerm.desc(t.date),
        OrderingTerm.desc(t.id),
      ],
      TransactionSort.oldest => [
        OrderingTerm.asc(t.date),
        OrderingTerm.asc(t.id),
      ],
      TransactionSort.amountDesc => [
        OrderingTerm.desc(t.amount.abs()),
        OrderingTerm.desc(t.date),
      ],
      TransactionSort.amountAsc => [
        OrderingTerm.asc(t.amount.abs()),
        OrderingTerm.desc(t.date),
      ],
    });
    query.limit(limit);

    return query.map((row) {
      final account = row.readTableOrNull(db.accounts);
      final debt = row.readTableOrNull(db.debts);
      return TransactionView(
        tx: row.readTable(t),
        accountName: account?.name,
        accountArchived: account?.isArchived ?? false,
        toAccountName: row.readTableOrNull(toAcc)?.name,
        category: row.readTableOrNull(db.categories),
        contactName: row.readTableOrNull(db.contacts)?.name,
        contactId: debt?.contactId,
        debtDirection: debt?.direction,
        debtSource: debt?.source,
      );
    });
  }

  /// دخل ومصروف فترة: يشملان البيع/الشراء بالآجل والمسامحة والإعفاء،
  /// وتُستبعد حركات الديون النقدية والتسوية والتحويل.
  Stream<PeriodTotals> watchTotals(DateRange range) =>
      _totalsQuery(range).watchSingle();

  Future<PeriodTotals> totals(DateRange range) =>
      _totalsQuery(range).getSingle();

  Selectable<PeriodTotals> _totalsQuery(DateRange range) => db
      .customSelect(
        '''
        SELECT
          COALESCE(SUM(CASE WHEN type IN (${_quoted(TxType.incomeNames)}) THEN amount END), 0) AS income,
          COALESCE(SUM(CASE WHEN type IN (${_quoted(TxType.expenseNames)}) THEN amount END), 0) AS expense
        FROM transactions
        WHERE date >= ?1 AND date < ?2
        ''',
        variables: [
          Variable.withDateTime(range.start),
          Variable.withDateTime(range.end),
        ],
        readsFrom: {db.transactions},
      )
      .map(
        (row) => PeriodTotals(
          income: row.read<int>('income'),
          expense: row.read<int>('expense'),
        ),
      );

  /// اقتراح الحساب (FR-06): آخر حساب نشط استُخدم لنفس الفئة، وإلا الافتراضي.
  Future<Account?> suggestAccount(int? categoryId) async {
    if (categoryId != null) {
      final row = await db
          .customSelect(
            '''
        SELECT t.account_id AS id FROM transactions t
        JOIN accounts a ON a.id = t.account_id
        WHERE t.category_id = ?1 AND a.is_archived = 0
        ORDER BY t.date DESC, t.id DESC LIMIT 1
        ''',
            variables: [Variable.withInt(categoryId)],
            readsFrom: {db.transactions, db.accounts},
          )
          .getSingleOrNull();
      if (row != null) {
        final id = row.read<int>('id');
        return (db.select(
          db.accounts,
        )..where((a) => a.id.equals(id))).getSingleOrNull();
      }
    }
    return (db.select(db.accounts)
          ..where((a) => a.isDefault.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // التحقق من صحة البيانات
  // ---------------------------------------------------------------------------

  Future<void> _validate(
    TransactionDraft d, {
    Set<int> allowArchived = const {},
  }) async {
    if (!_userTypes.contains(d.type)) {
      throw const BusinessException(BusinessError.debtMovementReadOnly);
    }
    if (d.amount <= 0) {
      throw const BusinessException(BusinessError.invalidAmount);
    }
    await _requireUsableAccount(d.accountId, allowArchived);

    if (d.type == TxType.transfer) {
      final to = d.toAccountId;
      if (to == null || to == d.accountId) {
        throw const BusinessException(BusinessError.sameAccountTransfer);
      }
      await _requireUsableAccount(to, allowArchived);
      return;
    }

    // الدخل والمصروف يحتاجان فئة من نفس النوع.
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
    final expected = d.type == TxType.income
        ? CategoryKind.income
        : CategoryKind.expense;
    if (category.kind != expected) {
      throw const BusinessException(BusinessError.categoryKindMismatch);
    }
  }

  Future<void> _requireUsableAccount(int id, Set<int> allowArchived) async {
    if (allowArchived.contains(id)) {
      final exists = await (db.select(
        db.accounts,
      )..where((a) => a.id.equals(id))).getSingleOrNull();
      if (exists == null) throw const BusinessException(BusinessError.notFound);
      return;
    }
    await _ledger.requireActiveAccount(id);
  }

  Future<bool> _anyArchived(Set<int> ids) async {
    final rows = await (db.select(
      db.accounts,
    )..where((a) => a.id.isIn(ids) & a.isArchived.equals(true))).get();
    return rows.isNotEmpty;
  }

  Future<MoneyTransaction> _require(int id) async {
    final tx = await getById(id);
    if (tx == null) throw const BusinessException(BusinessError.notFound);
    return tx;
  }

  static String _quoted(List<String> names) =>
      names.map((n) => "'$n'").join(', ');

  static bool _sameSet(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  static String? _clean(String? s) {
    final v = s?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}
