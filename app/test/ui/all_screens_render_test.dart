// اختبار دخاني: كل شاشات التطبيق تُعرض ببيانات حقيقية باللغتين (RTL و LTR)
// دون أي استثناء أو تجاوز للحدود (overflow).
import 'package:daftry/core/constants/currencies.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:daftry/domain/models/transaction_models.dart';
import 'package:daftry/services/account_service.dart';
import 'package:daftry/services/budget_service.dart';
import 'package:daftry/services/contact_service.dart';
import 'package:daftry/services/debt_service.dart';
import 'package:daftry/services/providers.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:daftry/services/transaction_service.dart';
import 'package:daftry/ui/app.dart';
import 'package:daftry/ui/router/routes.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// بيانات نموذجية قريبة من شاشات الوثيقة.
Future<({int contactId, int txId, int debtId})> seed(
  AppDatabase db, {
  required bool arabic,
}) async {
  await SettingsService(db)
      .completeOnboarding(currencyByCode('SAR')!, arabic: arabic);
  await SettingsService(db).set(SettingKeys.locale, arabic ? 'ar' : 'en');
  final accounts = AccountService(db);
  final cash = (await accounts.getDefault())!;
  final bank = await accounts.create(
    name: arabic ? 'الراجحي' : 'Al Rajhi',
    type: AccountType.bank,
    openingBalance: 1850000,
  );
  final budgets = BudgetService(db);
  final txs = TransactionService(db, budgets);
  final cats = await db.select(db.categories).get();
  final food = cats.firstWhere((c) => c.kind == CategoryKind.expense);
  final salary = cats.firstWhere((c) => c.kind == CategoryKind.income);
  await txs.add(
    TransactionDraft(
      type: TxType.income,
      amount: 1200000,
      accountId: bank,
      categoryId: salary.id,
      date: DateTime.now().subtract(const Duration(days: 40)),
    ),
  );
  final tx = await txs.add(
    TransactionDraft(
      type: TxType.expense,
      amount: 24500,
      accountId: cash.id,
      categoryId: food.id,
      date: DateTime.now(),
      note: arabic ? 'سوبرماركت' : 'Supermarket',
    ),
  );
  await txs.add(
    TransactionDraft(
      type: TxType.transfer,
      amount: 50000,
      accountId: bank,
      toAccountId: cash.id,
      date: DateTime.now(),
    ),
  );
  await budgets.upsert(categoryId: food.id, limit: 650000);
  final contact = await ContactService(db)
      .create(name: arabic ? 'أحمد علي' : 'Ahmed Ali', phone: '0551234567');
  final debts = DebtService(db);
  final debtId = await debts.createDebt(
    DebtDraft(
      contactId: contact,
      direction: DebtDirection.owedToMe,
      amount: 120000,
      startDate: DateTime.now().subtract(const Duration(days: 20)),
      dueDate: DateTime.now().add(const Duration(days: 5)),
      accountId: cash.id,
      note: arabic ? 'سلفة جهاز' : 'Device loan',
    ),
  );
  await debts.recordPayment(
    debtId,
    PaymentDraft(amount: 50000, paidAt: DateTime.now(), accountId: cash.id),
  );
  return (contactId: contact, txId: tx.id, debtId: debtId);
}

void main() {
  for (final arabic in [true, false]) {
    testWidgets('كل الشاشات تُعرض دون أخطاء (${arabic ? 'ar' : 'en'})', (
      tester,
    ) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(db.close);
      // شاشة هاتف حديث 390×844 كما في تصاميم الوثيقة.
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final ids = await tester.runAsync(() => seed(db, arabic: arabic));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const DaftryApp(),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DaftryApp)),
      );
      final router = container.read(routerProvider);

      final routes = [
        AppRoutes.home,
        AppRoutes.transactions,
        AppRoutes.debts,
        AppRoutes.more,
        AppRoutes.accounts,
        AppRoutes.reports,
        AppRoutes.budget,
        AppRoutes.categories,
        AppRoutes.backup,
        AppRoutes.security,
        AppRoutes.person(ids!.contactId),
        AppRoutes.personStatement(ids.contactId),
        AppRoutes.editPerson(ids.contactId),
        AppRoutes.newTransaction(),
        AppRoutes.newTransaction(TxType.transfer),
        AppRoutes.editTransaction(ids.txId),
        AppRoutes.newDebt(),
        AppRoutes.editDebt(ids.debtId),
        AppRoutes.newPerson,
      ];
      // نجمع كل أخطاء العرض مع اسم الشاشة بدل التوقف عند أول خطأ.
      final errors = <String>[];
      var current = '';
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.toString();
        final widget = RegExp(r'lib/ui/[^\s:]+:\d+').firstMatch(text)?.group(0);
        errors.add(
          '$current → ${details.exceptionAsString().split('\n').first} ($widget)',
        );
      };
      try {
        for (final route in routes) {
          current = route;
          router.go(route);
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 20),
          );
        }
      } finally {
        FlutterError.onError = previous;
      }
      expect(errors, isEmpty, reason: errors.join('\n'));
    });
  }
}
