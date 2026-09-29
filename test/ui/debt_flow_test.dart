// اختبارات واجهة لتدفقات الديون (وثيقة «وحدة الديون — الإضافات الأخيرة»):
// دين جديد من ملف الشخص (الشخص مقفل) ← «استلام مبلغ» بكامل المتبقي،
// منع الحفظ المكرر، عرض تسجيل الزائد ديناً معاكساً، البيع بالآجل، وزر
// الإجراءات السريعة.
import 'package:daftry/core/constants/currencies.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:daftry/services/contact_service.dart';
import 'package:daftry/services/debt_service.dart';
import 'package:daftry/services/providers.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:daftry/ui/app.dart';
import 'package:daftry/ui/router/routes.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// يشغّل التطبيق بالإنجليزية مع شخص واحد «Ahmed Ali».
Future<({AppDatabase db, int contactId, dynamic router})> _start(
  WidgetTester tester,
) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final contactId = await tester.runAsync(() async {
    await SettingsService(db)
        .completeOnboarding(currencyByCode('SAR')!, arabic: false);
    return ContactService(db).create(name: 'Ahmed Ali');
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const DaftryApp(),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  final router = ProviderScope.containerOf(
    tester.element(find.byType(DaftryApp)),
  ).read(routerProvider);
  return (db: db, contactId: contactId!, router: router);
}

/// دين «لي» 1,200 من «Cash» عبر الواجهة (الشخص محدد ومقفل).
Future<void> _lend1200(
  WidgetTester tester,
  dynamic router,
  int contactId,
) async {
  router.go(AppRoutes.newDebt(contactId: contactId));
  await tester.pumpAndSettle();
  expect(find.text('Ahmed Ali'), findsOneWidget);
  expect(find.byIcon(Icons.lock_person_outlined), findsOneWidget);
  await tester.enterText(find.byType(TextField).first, '1200');
  await tester.tap(find.text('Save debt'));
  await tester.pumpAndSettle();
}

Future<void> _openReceiveSheet(
  WidgetTester tester,
  dynamic router,
  int contactId,
) async {
  router.go(AppRoutes.person(contactId));
  await tester.pumpAndSettle();
  expect(find.text('Ahmed owes me'), findsOneWidget);
  await tester.tap(find.widgetWithText(FilledButton, 'Receive payment'));
  await tester.pumpAndSettle();
  expect(find.text('Receive from Ahmed Ali'), findsOneWidget);
}

Finder get _sheetSave => find.widgetWithText(FilledButton, 'Save').last;

void main() {
  testWidgets('دين جديد ثم «استلام مبلغ» بكامل المتبقي من الملف المالي', (
    tester,
  ) async {
    final app = await _start(tester);
    await _lend1200(tester, app.router, app.contactId);

    final debt = await tester.runAsync(
      () => app.db.select(app.db.debts).getSingle(),
    );
    expect(debt!.direction, DebtDirection.owedToMe);
    expect(debt.source, DebtSource.loan);
    expect(debt.amount, 120000);
    var cash = await tester.runAsync(
      () => app.db.select(app.db.accounts).getSingle(),
    );
    expect(cash!.balance, -120000);

    await _openReceiveSheet(tester, app.router, app.contactId);
    await tester.tap(find.text('Full remaining'));
    await tester.pump();
    expect(find.textContaining('Remaining after payment'), findsOneWidget);
    await tester.tap(_sheetSave);
    await tester.pumpAndSettle();

    final view = await tester.runAsync(
      () => DebtService(app.db).debtView(debt.id),
    );
    expect(view!.status, DebtStatus.closed);
    cash = await tester.runAsync(
      () => app.db.select(app.db.accounts).getSingle(),
    );
    expect(cash!.balance, 0);
    expect(find.text('Closed'), findsWidgets);
    expect(find.text('Paid 100%'), findsOneWidget);
  });

  testWidgets('منع الحفظ المكرر: الضغط المزدوج لا ينشئ دفعتين', (tester) async {
    final app = await _start(tester);
    await _lend1200(tester, app.router, app.contactId);
    await _openReceiveSheet(tester, app.router, app.contactId);
    await tester.enterText(find.byType(TextField).last, '500');
    await tester.pump();
    await tester.tap(_sheetSave);
    await tester.tap(_sheetSave, warnIfMissed: false);
    await tester.pumpAndSettle();
    final payments = await tester.runAsync(
      () => app.db.select(app.db.debtPayments).get(),
    );
    expect(payments, hasLength(1));
    expect(payments!.single.amount, 50000);
  });

  testWidgets('الزائد عن المتبقي يُعرض تسجيله ديناً معاكساً', (tester) async {
    final app = await _start(tester);
    await _lend1200(tester, app.router, app.contactId);
    await _openReceiveSheet(tester, app.router, app.contactId);
    await tester.enterText(find.byType(TextField).last, '1500');
    await tester.pump();
    await tester.tap(_sheetSave);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('record it as a debt you owe Ahmed Ali?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Record the extra'));
    await tester.pumpAndSettle();

    final totals = await tester.runAsync(
      () => DebtService(app.db).watchTotals().first,
    );
    expect((totals!.owedToMe, totals.iOwe), (0, 30000));
    final cash = await tester.runAsync(
      () => app.db.select(app.db.accounts).getSingle(),
    );
    expect(cash!.balance, 30000);
    // بطاقتان منفصلتان مع الصافي كمعلومة فقط.
    expect(find.text('I owe Ahmed'), findsOneWidget);
    expect(find.textContaining('Net in Ahmed’s favor'), findsOneWidget);
  });

  testWidgets('بيع بالآجل من نموذج الدين: دخل بفئة «Sales» دون حركة حساب', (
    tester,
  ) async {
    final app = await _start(tester);
    app.router.go(AppRoutes.newDebt(contactId: app.contactId));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '800');
    await tester.tap(find.text('I sold on credit'));
    await tester.pumpAndSettle();
    expect(find.text('Sales'), findsOneWidget);
    await tester.tap(find.text('Save debt'));
    await tester.pumpAndSettle();

    final debt = await tester.runAsync(
      () => app.db.select(app.db.debts).getSingle(),
    );
    expect(debt!.source, DebtSource.creditSale);
    final tx = await tester.runAsync(
      () => app.db.select(app.db.transactions).getSingle(),
    );
    expect((tx!.type, tx.accountId, tx.amount), (TxType.income, null, 80000));
  });

  testWidgets('زر الإجراءات السريعة: استلام مبلغ ← الشخص ← المبلغ', (
    tester,
  ) async {
    final app = await _start(tester);
    await tester.runAsync(
      () => DebtService(app.db).createDebt(
        DebtDraft(
          contactId: app.contactId,
          direction: DebtDirection.owedToMe,
          source: DebtSource.opening,
          amount: 20000,
          startDate: DateTime.now(),
        ),
      ),
    );
    app.router.go(AppRoutes.debts);
    await tester.pumpAndSettle();
    expect(find.text('1 person'), findsOneWidget);
    await tester.tap(find.byTooltip('New debt'));
    await tester.pumpAndSettle();
    expect(find.text('Make payment'), findsOneWidget);
    await tester.tap(find.text('Receive payment'));
    await tester.pumpAndSettle();
    // شخص واحد له ديون مفتوحة: تُفتح نافذة الاستلام مباشرة.
    expect(find.text('Receive from Ahmed Ali'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '200');
    await tester.pump();
    await tester.tap(_sheetSave);
    await tester.pumpAndSettle();
    final totals = await tester.runAsync(
      () => DebtService(app.db).watchTotals().first,
    );
    expect(totals!.owedToMe, 0);
  });

  testWidgets('زر الإجراءات السريعة: «دين جديد» يفتح النموذج، و«إغلاق» يعود', (
    tester,
  ) async {
    final app = await _start(tester);
    app.router.go(AppRoutes.debts);
    await tester.pumpAndSettle();

    // الإغلاق دون اختيار لا يفعل شيئاً.
    await tester.tap(find.byTooltip('New debt'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Make payment'), findsNothing);

    await tester.tap(find.byTooltip('New debt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New debt'));
    await tester.pumpAndSettle();
    expect(find.text('Save debt'), findsOneWidget);
    expect(find.text('Where did this debt come from?'), findsOneWidget);
  });
}
