// أدوات مشتركة للاختبارات: قاعدة بيانات في الذاكرة + كل الخدمات جاهزة.
import 'package:daftry/core/constants/currencies.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/services/account_service.dart';
import 'package:daftry/services/budget_service.dart';
import 'package:daftry/services/category_service.dart';
import 'package:daftry/services/contact_service.dart';
import 'package:daftry/services/debt_service.dart';
import 'package:daftry/services/report_service.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:daftry/services/statement_service.dart';
import 'package:daftry/services/transaction_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// بيئة اختبار كاملة فوق قاعدة بيانات SQLite في الذاكرة.
class TestEnv {
  TestEnv._(this.db)
    : settings = SettingsService(db),
      accounts = AccountService(db),
      categories = CategoryService(db),
      contacts = ContactService(db),
      budgets = BudgetService(db),
      reports = ReportService(db),
      statements = StatementService(db),
      debts = DebtService(db) {
    transactions = TransactionService(db, budgets);
  }

  final AppDatabase db;
  final SettingsService settings;
  final AccountService accounts;
  final CategoryService categories;
  final ContactService contacts;
  final BudgetService budgets;
  final ReportService reports;
  final StatementService statements;
  final DebtService debts;
  late final TransactionService transactions;

  /// ينشئ بيئة جديدة، ويُكمل الإعداد الأول بالريال السعودي افتراضياً.
  static Future<TestEnv> create({bool onboard = true}) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final env = TestEnv._(AppDatabase(NativeDatabase.memory()));
    if (onboard) {
      await env.settings.completeOnboarding(
        currencyByCode('SAR')!,
        arabic: true,
      );
    }
    return env;
  }

  Future<void> dispose() => db.close();

  /// الحساب الافتراضي «النقدية».
  Future<Account> get cash async => (await accounts.getDefault())!;

  Future<Account> account(int id) async => (await accounts.getById(id))!;

  /// أول فئة من النوع المطلوب.
  Future<Category> category(CategoryKind kind) async =>
      (await categories.watchByKind(kind).first).first;
}
