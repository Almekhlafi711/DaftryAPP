// =============================================================================
// خدمة الحسابات: الإنشاء، التعديل، الحساب الافتراضي، الأرشفة، التسوية،
// وإعادة احتساب الأرصدة.
//
// قواعد العمل المطبقة (الوثيقة 3.12.2):
// - لا يُحذف أي حساب؛ الأرشفة هي البديل الوحيد (ومحمية أيضاً بـ Trigger).
// - لا يمكن أرشفة آخر حساب نشط، ولا الحساب الافتراضي قبل اختيار بديل.
// - لا يُؤرشف الحساب إلا ورصيده صفر: إن كان له رصيد يُحوَّل أولاً إلى حساب
//   آخر (المال لا يختفي بالأرشفة — وثيقة الديون 1.2).
// - تصحيح الرصيد يتم بمعاملة «تسوية» وليس بالتعديل المباشر (3.12.3).
// - «إعادة احتساب الأرصدة» تفحص أيضاً معادلة التطابق الشاملة (القسم 11).
// =============================================================================

import 'package:drift/drift.dart';

import '../core/errors/app_exception.dart';
import '../data/database/app_database.dart';
import '../domain/enums.dart';
import 'ledger.dart';
import 'settings_service.dart';

class AccountService {
  AccountService(this.db) : _ledger = Ledger(db);

  final AppDatabase db;
  final Ledger _ledger;

  // ---------------------------------------------------------------------------
  // القراءة (تدفقات تفاعلية تُحدّث الواجهة تلقائياً)
  // ---------------------------------------------------------------------------

  /// الحسابات النشطة: الافتراضي أولاً ثم حسب تاريخ الإنشاء.
  Stream<List<Account>> watchActive() =>
      (db.select(db.accounts)
            ..where((a) => a.isArchived.equals(false))
            ..orderBy([
              (a) => OrderingTerm.desc(a.isDefault),
              (a) => OrderingTerm.asc(a.createdAt),
              (a) => OrderingTerm.asc(a.id),
            ]))
          .watch();

  Future<List<Account>> getActive() =>
      (db.select(db.accounts)
            ..where((a) => a.isArchived.equals(false))
            ..orderBy([(a) => OrderingTerm.desc(a.isDefault)]))
          .get();

  /// الحسابات المؤرشفة (تظهر في قسم مستقل باهت).
  Stream<List<Account>> watchArchived() =>
      (db.select(db.accounts)
            ..where((a) => a.isArchived.equals(true))
            ..orderBy([(a) => OrderingTerm.desc(a.archivedAt)]))
          .watch();

  /// كل الحسابات (للفلترة والتقارير — المؤرشفة تبقى في السجل).
  Stream<List<Account>> watchAll() =>
      (db.select(db.accounts)..orderBy([
            (a) => OrderingTerm.asc(a.isArchived),
            (a) => OrderingTerm.desc(a.isDefault),
            (a) => OrderingTerm.asc(a.id),
          ]))
          .watch();

  /// إجمالي أرصدة الحسابات النشطة — يُحسب بـ SUM داخل قاعدة البيانات.
  Stream<int> watchTotalBalance() {
    final sum = db.accounts.balance.sum();
    final query = db.selectOnly(db.accounts)
      ..addColumns([sum])
      ..where(db.accounts.isArchived.equals(false));
    return query.map((row) => row.read(sum) ?? 0).watchSingle();
  }

  Future<Account?> getById(int id) =>
      (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Stream<Account?> watchById(int id) => (db.select(
    db.accounts,
  )..where((a) => a.id.equals(id))).watchSingleOrNull();

  /// الحساب الافتراضي الحالي.
  Future<Account?> getDefault() =>
      (db.select(db.accounts)
            ..where((a) => a.isDefault.equals(true))
            ..limit(1))
          .getSingleOrNull();

  Future<int> activeCount() async {
    final count = db.accounts.id.count();
    final row =
        await (db.selectOnly(db.accounts)
              ..addColumns([count])
              ..where(db.accounts.isArchived.equals(false)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // الكتابة
  // ---------------------------------------------------------------------------

  /// إنشاء حساب جديد برصيد افتتاحي.
  Future<int> create({
    required String name,
    required AccountType type,
    int openingBalance = 0,
    String? icon,
    int? color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const BusinessException(BusinessError.emptyName);
    return db.transaction(() async {
      await _ensureUniqueName(trimmed);
      return db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              name: trimmed,
              type: type,
              currencyId: await _ledger.baseCurrencyId(),
              openingBalance: Value(openingBalance),
              balance: Value(openingBalance),
              icon: Value(icon),
              color: Value(color),
            ),
          );
    });
  }

  /// تعديل بيانات الحساب (الاسم والنوع والمظهر) — الرصيد لا يُعدَّل هنا.
  Future<void> update(
    int id, {
    required String name,
    required AccountType type,
    String? icon,
    int? color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const BusinessException(BusinessError.emptyName);
    await db.transaction(() async {
      await _ensureUniqueName(trimmed, exceptId: id);
      await (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
        AccountsCompanion(
          name: Value(trimmed),
          type: Value(type),
          icon: Value(icon),
          color: Value(color),
        ),
      );
    });
  }

  /// تعيين حساب كافتراضي (يجب أن يكون نشطاً).
  Future<void> setDefault(int id) => db.transaction(() async {
    await _ledger.requireActiveAccount(id);
    await _setDefaultUnchecked(id);
  });

  Future<void> _setDefaultUnchecked(int id) async {
    // نلغي الافتراضي القديم أولاً بسبب الفهرس الفريد (حساب افتراضي واحد فقط).
    await (db.update(db.accounts)..where((a) => a.isDefault.equals(true)))
        .write(const AccountsCompanion(isDefault: Value(false)));
    await (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
      const AccountsCompanion(isDefault: Value(true)),
    );
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: SettingKeys.defaultAccountId,
            value: '$id',
          ),
        );
  }

  /// أرشفة حساب (UC-01b).
  ///
  /// - [transferToId]: مطلوب إن كان للحساب رصيد؛ يُحوَّل إليه الرصيد أولاً.
  /// - [newDefaultId]: مطلوب إذا كان الحساب هو الافتراضي.
  Future<void> archive(int id, {int? transferToId, int? newDefaultId}) =>
      db.transaction(() async {
        final account = await _ledger.requireActiveAccount(id);

        if (await activeCount() <= 1) {
          throw const BusinessException(BusinessError.cannotArchiveLastAccount);
        }
        if (account.isDefault) {
          if (newDefaultId == null || newDefaultId == id) {
            throw const BusinessException(BusinessError.mustChooseNewDefault);
          }
          await _ledger.requireActiveAccount(newDefaultId);
          await _setDefaultUnchecked(newDefaultId);
        }

        if (account.balance != 0 && transferToId == null) {
          throw const BusinessException(BusinessError.accountHasBalance);
        }
        if (transferToId != null && account.balance != 0) {
          if (transferToId == id) {
            throw const BusinessException(BusinessError.sameAccountTransfer);
          }
          await _ledger.requireActiveAccount(transferToId);
          // رصيد موجب: من هذا الحساب إلى الوجهة. رصيد سالب: العكس.
          final positive = account.balance > 0;
          await _ledger.insert(
            TransactionsCompanion.insert(
              type: TxType.transfer,
              amount: account.balance.abs(),
              currencyId: account.currencyId,
              accountId: Value(positive ? id : transferToId),
              toAccountId: Value(positive ? transferToId : id),
              date: DateTime.now(),
            ),
          );
        }

        await (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
          AccountsCompanion(
            isArchived: const Value(true),
            archivedAt: Value(DateTime.now()),
          ),
        );
      });

  /// رفع الأرشفة: يعود الحساب نشطاً فوراً بكل بياناته.
  Future<void> unarchive(int id) =>
      (db.update(db.accounts)..where((a) => a.id.equals(id))).write(
        const AccountsCompanion(
          isArchived: Value(false),
          archivedAt: Value(null),
        ),
      );

  /// تسوية الرصيد (FR-10): ينشئ معاملة «تسوية» بالفرق بين الرصيد الحقيقي
  /// والمسجَّل. يعيد رقم المعاملة، أو null إن لم يكن هناك فرق.
  Future<int?> adjustBalance(int id, int realBalance, {String? note}) =>
      db.transaction(() async {
        final account = await _ledger.requireActiveAccount(id);
        final diff = realBalance - account.balance;
        if (diff == 0) return null;
        return _ledger.insert(
          TransactionsCompanion.insert(
            type: TxType.adjustment,
            amount: diff,
            currencyId: account.currencyId,
            accountId: Value(id),
            date: DateTime.now(),
            note: Value(note),
          ),
        );
      });

  /// إعادة احتساب كل الأرصدة من المعاملات للتدقيق (FR-27).
  /// يعيد عدد الحسابات التي كان رصيدها المخزَّن مختلفاً وتم تصحيحه.
  Future<int> recalculateAll() => db.transaction(() async {
    final before = {
      for (final a in await db.select(db.accounts).get()) a.id: a.balance,
    };
    // عبارة SQL واحدة تعيد حساب كل الأرصدة داخل قاعدة البيانات.
    await db.customUpdate(
      'UPDATE accounts SET balance = opening_balance + '
      '${AppDatabase.balanceEffectSql('accounts.id')}',
      updates: {db.accounts},
      updateKind: UpdateKind.update,
    );
    // المُسامَح من كل دين = مجموع قيود المسامحة/الإعفاء عليه. (المدفوع
    // والمتبقي والحالة لا تُخزَّن أصلاً، فلا تحتاج تصحيحاً.)
    await db.customUpdate(
      '''
          UPDATE debts SET written_off = COALESCE((
            SELECT SUM(t.amount) FROM transactions t
            WHERE t.debt_id = debts.id
              AND t.type IN ('${TxType.writeOff.name}', '${TxType.debtForgiven.name}')
          ), 0)
          ''',
      updates: {db.debts},
      updateKind: UpdateKind.update,
    );
    final after = await db.select(db.accounts).get();
    return after.where((a) => before[a.id] != a.balance).length;
  });

  /// معادلة التطابق الشاملة (القسم 11) لكل البيانات منذ البداية:
  ///
  ///   Δ(أرصدة الحسابات) + Δ(لي) − Δ(عليّ) = الدخل − المصروف + صافي التسويات
  ///
  /// حيث Δ(الأرصدة) = الأرصدة − الأرصدة الافتتاحية، ويُستبعد ما هو خارج
  /// الدفتر أصلاً كما تُستبعد الأرصدة الافتتاحية: الديون السابقة (قبل استخدام
  /// التطبيق) والدفعات القديمة المسجلة «في الدفتر فقط» (الإصدار 1).
  ///
  /// تعيد الفرق: صفر يعني أن البيانات متسقة، وغير ذلك يعني وجود خطأ.
  Future<int> reconciliationGap() async {
    final r = AppDatabase.remainingSql('d');
    const owed = DebtDirection.owedToMe;
    final row = await db
        .customSelect(
          '''
          SELECT
            (SELECT COALESCE(SUM(balance - opening_balance), 0) FROM accounts)
              AS accounts_delta,
            (SELECT COALESCE(SUM(CASE WHEN d.direction = '${owed.name}'
                                      THEN $r ELSE -$r END), 0)
               FROM debts d) AS debts_net,
            (SELECT COALESCE(SUM(CASE WHEN d.direction = '${owed.name}'
                                      THEN d.amount ELSE -d.amount END), 0)
               FROM debts d WHERE d.source = '${DebtSource.opening.name}')
              AS opening_debts,
            (SELECT COALESCE(SUM(CASE WHEN d.direction = '${owed.name}'
                                      THEN -p.amount ELSE p.amount END), 0)
               FROM debt_payments p JOIN debts d ON d.id = p.debt_id
              WHERE p.is_cancelled = 0 AND p.account_id IS NULL)
              AS book_only_payments,
            (SELECT COALESCE(SUM(CASE
                WHEN type IN (${_names(TxType.incomeNames)}) THEN amount
                WHEN type IN (${_names(TxType.expenseNames)}) THEN -amount
                WHEN type = '${TxType.adjustment.name}' THEN amount
                ELSE 0 END), 0)
               FROM transactions) AS income_statement
          ''',
          readsFrom: {db.accounts, db.debts, db.debtPayments, db.transactions},
        )
        .getSingle();
    final left =
        row.read<int>('accounts_delta') +
        row.read<int>('debts_net') -
        row.read<int>('opening_debts') -
        row.read<int>('book_only_payments');
    return left - row.read<int>('income_statement');
  }

  static String _names(List<String> names) =>
      names.map((n) => "'$n'").join(', ');

  Future<void> _ensureUniqueName(String name, {int? exceptId}) async {
    final query = db.select(db.accounts)
      ..where((a) => a.name.lower().equals(name.toLowerCase()));
    if (exceptId != null) query.where((a) => a.id.equals(exceptId).not());
    if (await query.getSingleOrNull() != null) {
      throw BusinessException(BusinessError.duplicateAccountName, name);
    }
  }
}
