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
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createTriggers();
    },
    onUpgrade: (m, from, to) async {
      // مثال للمستقبل:
      // if (from < 2) await m.addColumn(accounts, accounts.someNewColumn);
    },
    beforeOpen: (details) async {
      // تفعيل قيود المفاتيح الأجنبية (معطلة افتراضياً في SQLite).
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

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
