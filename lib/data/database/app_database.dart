// =============================================================================
// قاعدة البيانات المحلية للتطبيق (LocalDatabase في مخطط الفئات).
//
// - تعمل على SQLite عبر مكتبة Drift: استعلامات آمنة الأنواع (Type-safe)
//   وتدفقات تفاعلية (Streams) تُحدّث الواجهة تلقائياً عند تغيّر البيانات.
// - تُفتح في Isolate خلفي (انظر connection.dart) حتى لا تتأثر سلاسة الواجهة.
// - كل عملية حفظ مركّبة تتم داخل transaction واحدة (ACID) في طبقة الخدمات.
//
// بعد تعديل أي جدول شغّل:
//   dart run build_runner build --delete-conflicting-outputs
// وارفع [schemaVersion] وأضف خطوة ترحيل في [migration].
// =============================================================================

import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../seed/default_categories.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Currencies,
    Accounts,
    Categories,
    Transactions,
    Contacts,
    Debts,
    DebtPayments,
    Budgets,
    Settings,
    BackupLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] يُمرَّر من connection.dart (ملف على الجهاز) أو من الاختبارات
  /// (قاعدة بيانات في الذاكرة).
  AppDatabase(super.executor);

  /// رقم إصدار المخطط. ارفعه عند أي تغيير في الجداول.
  ///
  /// 2: وحدة الديون — مصدر الدين، المسامحة، إلغاء الدفعات وتوزيعها، أرشفة
  ///    الأشخاص، وقيود الديون التي لا تحرّك حساباً.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createTriggers();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) await _migrateToV2(m);
    },
    beforeOpen: (details) async {
      // تفعيل قيود المفاتيح الأجنبية (معطلة افتراضياً في SQLite).
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// الترحيل إلى الإصدار 2. يُطبَّق على قاعدة الجهاز وعلى أي نسخة احتياطية
  /// قديمة عند استعادتها، ولا يغيّر أي رقم من أرقام الماضي:
  /// - الدين المرتبط بحساب ← «إقراض/اقتراض»، وغير المرتبط ← «دين سابق»
  ///   (الدفتر فقط، كما كان يُعامَل تماماً).
  /// - الحالة والمدفوع لم يعودا مخزَّنَين (يُحسبان من الدفعات).
  /// - الشخص المخفي يصبح مؤرشفاً فقط إن كان متبقّيه صفراً؛ وإلا يعود ظاهراً.
  /// - العنوان يُضم إلى الملاحظة (لم يعد حقلاً مستقلاً).
  /// - الحساب المؤرشف وله رصيد يعود نشطاً (المال لا يختفي بالأرشفة).
  ///
  /// alterTable يعيد بناء الجدول مع إيقاف المفاتيح الأجنبية مؤقتاً، فلا تُحذف
  /// الدفعات المرتبطة عند إعادة بناء جدول الديون.
  Future<void> _migrateToV2(Migrator m) async {
    await customStatement('DROP INDEX IF EXISTS idx_debts_status_due');

    // المتبقي من كل دين ≥ 0، فمجموعه صفر فقط إن كان كل دين صفراً.
    const remaining =
        '(SELECT COALESCE(SUM(d.amount - COALESCE((SELECT SUM(p.amount) '
        'FROM debt_payments p WHERE p.debt_id = d.id), 0)), 0) '
        'FROM debts d WHERE d.contact_id = contacts.id)';
    const archived = 'is_active = 0 AND $remaining = 0';
    await m.alterTable(
      TableMigration(
        contacts,
        columnTransformer: {
          contacts.isArchived: const CustomExpression<bool>(
            'CASE WHEN $archived THEN 1 ELSE 0 END',
          ),
          contacts.archivedAt: const CustomExpression<DateTime>(
            "CASE WHEN $archived THEN CAST(strftime('%s', 'now') AS INTEGER) "
            'END',
          ),
          contacts.note: const CustomExpression<String>(
            "CASE WHEN address IS NULL OR trim(address) = '' THEN note "
            "WHEN note IS NULL OR trim(note) = '' THEN address "
            'ELSE note || char(10) || address END',
          ),
        },
        newColumns: [contacts.isArchived, contacts.archivedAt],
      ),
    );

    await m.alterTable(
      TableMigration(
        debts,
        columnTransformer: {
          debts.source: CustomExpression<String>(
            'CASE WHEN account_id IS NULL '
            "THEN '${DebtSource.opening.name}' "
            "ELSE '${DebtSource.loan.name}' END",
          ),
          debts.updatedAt: const CustomExpression<DateTime>('created_at'),
        },
        newColumns: [debts.source, debts.writtenOff, debts.updatedAt],
      ),
    );
    await m.createIndex(idxDebtsDue);

    await m.addColumn(debtPayments, debtPayments.isCancelled);
    await m.addColumn(debtPayments, debtPayments.cancelledAt);
    await m.addColumn(debtPayments, debtPayments.operationId);
    // كل دفعة قديمة عملية مستقلة بمعرّف خاص بها.
    await customStatement(
      'UPDATE debt_payments SET operation_id = lower(hex(randomblob(16))) '
      'WHERE operation_id IS NULL',
    );
    await m.createIndex(idxPaymentsOperation);

    // account_id يصبح اختيارياً لقيود الديون التي لا تحرّك حساباً.
    await m.alterTable(TableMigration(transactions));

    await m.addColumn(categories, categories.systemKey);
    for (final seed in kDefaultCategories) {
      await customStatement(
        'UPDATE categories SET system_key = ? WHERE id = ('
        'SELECT MIN(id) FROM categories WHERE is_default = 1 AND kind = ? '
        'AND icon = ? AND system_key IS NULL) '
        'AND NOT EXISTS (SELECT 1 FROM categories WHERE system_key = ?)',
        [seed.key, seed.kind.name, seed.icon, seed.key],
      );
    }
    await m.createIndex(idxCategoriesSystemKey);

    await customStatement(
      'UPDATE accounts SET balance = opening_balance + '
      '${balanceEffectSql('accounts.id')}',
    );
    await customStatement(
      'UPDATE accounts SET is_archived = 0, archived_at = NULL '
      'WHERE is_archived = 1 AND balance != 0',
    );
  }

  /// المشغّلات (Triggers) التي تحمي قواعد العمل على مستوى قاعدة البيانات نفسها،
  /// فلا يمكن كسرها حتى لو أخطأ الكود.
  Future<void> _createTriggers() async {
    // قاعدة 3.12.2: لا يمكن حذف أي حساب إطلاقاً؛ الأرشفة هي البديل الوحيد.
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS trg_accounts_no_delete
      BEFORE DELETE ON accounts
      BEGIN
        SELECT RAISE(ABORT, 'accounts_cannot_be_deleted');
      END
    ''');
  }

  /// حذف جميع البيانات والعودة لحالة التثبيت الأول.
  /// هذا هو الطريق الوحيد لتغيير العملة المقفلة (قاعدة 3.12.1).
  Future<void> wipeAllData() async {
    await transaction(() async {
      // نوقف مشغّل منع حذف الحسابات مؤقتاً داخل نفس العملية الذرية.
      await customStatement('DROP TRIGGER IF EXISTS trg_accounts_no_delete');
      // الترتيب مهم بسبب المفاتيح الأجنبية: الأبناء أولاً.
      for (final TableInfo<Table, Object?> table in [
        transactions,
        debtPayments,
        debts,
        contacts,
        budgets,
        categories,
        accounts,
        currencies,
        settings,
        backupLogs,
      ]) {
        await delete(table).go();
      }
      await _createTriggers();
    });
  }

  /// إعادة إنشاء المشغّلات (تُستخدم بعد استعادة نسخة احتياطية).
  Future<void> ensureTriggers() => _createTriggers();

  /// كل الجداول بالترتيب الصحيح للإدراج (الآباء قبل الأبناء).
  /// تُستخدم في النسخ الاحتياطي والاستعادة.
  List<TableInfo<Table, Object?>> get tablesInInsertOrder => [
    currencies,
    accounts,
    categories,
    contacts,
    debts,
    debtPayments,
    transactions,
    budgets,
    settings,
    backupLogs,
  ];

  // ---------------------------------------------------------------------------
  // استعلامات مساعدة مشتركة بين الخدمات
  // ---------------------------------------------------------------------------

  /// تدفق تفاعلي لأي حساب مركّب: يعيد تشغيل [load] كلما تغيّرت أي من
  /// الجداول [tables]. مفيد للتقارير والملخصات التي تجمع عدة استعلامات،
  /// فتبقى الواجهة محدَّثة دون أي تحديث يدوي.
  Stream<T> watchTables<T>(
    Set<ResultSetImplementation<dynamic, dynamic>> tables,
    Future<T> Function() load,
  ) async* {
    yield await load();
    await for (final _ in tableUpdates(TableUpdateQuery.onAllTables(tables))) {
      yield await load();
    }
  }

  /// عملة التطبيق (الأساسية). null إن لم يكتمل الإعداد الأول.
  Future<Currency?> baseCurrency() =>
      (select(currencies)
            ..where((c) => c.isBase.equals(true))
            ..limit(1))
          .getSingleOrNull();

  /// المدفوع الفعلي من الدين [alias] (الدفعات غير الملغاة) — تعبير SQL.
  static String paidSql(String alias) =>
      '(SELECT COALESCE(SUM(p.amount), 0) FROM debt_payments p '
      'WHERE p.debt_id = $alias.id AND p.is_cancelled = 0)';

  /// المتبقي من الدين [alias]: R = A − Paid − W — تعبير SQL.
  static String remainingSql(String alias) =>
      '($alias.amount - ${paidSql(alias)} - $alias.written_off)';

  /// تعبير SQL يحسب «أثر» المعاملة على حساب معيّن — يُستخدم لإعادة احتساب
  /// الأرصدة بالكامل داخل قاعدة البيانات (أسرع بكثير من الحساب في Dart).
  ///
  /// income/debtIn/adjustment: +amount ، expense/debtOut: -amount ،
  /// transfer: -amount للمصدر و +amount للوجهة.
  static String balanceEffectSql(String accountIdExpr) =>
      '''
    COALESCE((SELECT SUM(
      CASE
        WHEN t.type IN ('${TxType.income.name}', '${TxType.debtIn.name}', '${TxType.adjustment.name}')
             AND t.account_id = $accountIdExpr THEN t.amount
        WHEN t.type IN ('${TxType.expense.name}', '${TxType.debtOut.name}')
             AND t.account_id = $accountIdExpr THEN -t.amount
        WHEN t.type = '${TxType.transfer.name}' AND t.account_id = $accountIdExpr THEN -t.amount
        WHEN t.type = '${TxType.transfer.name}' AND t.to_account_id = $accountIdExpr THEN t.amount
        ELSE 0
      END)
      FROM transactions t
      WHERE t.account_id = $accountIdExpr OR t.to_account_id = $accountIdExpr), 0)
  ''';
}
