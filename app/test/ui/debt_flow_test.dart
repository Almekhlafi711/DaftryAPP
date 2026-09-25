// اختبار واجهة لتدفق الديون: تسجيل دين «لي» مرتبط بحساب من الواجهة، ثم
// تسجيل دفعة «كامل المتبقي» من الملف المالي، والتحقق من الأرصدة والحالة.
import 'package:daftry/core/constants/currencies.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/services/contact_service.dart';
import 'package:daftry/services/providers.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:daftry/ui/app.dart';
import 'package:daftry/ui/router/routes.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('دين جديد ثم سداده بالكامل من الملف المالي', (tester) async {
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
    final router = ProviderScope.containerOf(
      tester.element(find.byType(DaftryApp)),
    ).read(routerProvider);

    // 1) دين جديد لشخص محدد مسبقاً، المبلغ خرج من «Cash».
    router.go(AppRoutes.newDebt(contactId: contactId));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed Ali'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '1200');
    await tester.tap(find.text('Save debt'));
    await tester.pumpAndSettle();

    final debt = await tester.runAsync(() => db.select(db.debts).getSingle());
    expect(debt!.direction, DebtDirection.owedToMe);
    expect(debt.amount, 120000);
    var cash = await tester.runAsync(() => db.select(db.accounts).getSingle());
    expect(cash!.balance, -120000);

    // 2) الملف المالي ← تسجيل دفعة ← كامل المتبقي ← حفظ.
    router.go(AppRoutes.person(contactId!));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed owes me'), findsOneWidget);
    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full remaining'));
    await tester.pump();
    await tester.tap(find.text('Save payment'));
    await tester.pumpAndSettle();

    final settled = await tester.runAsync(
      () => db.select(db.debts).getSingle(),
    );
    expect(settled!.status, DebtStatus.settled);
    cash = await tester.runAsync(() => db.select(db.accounts).getSingle());
    expect(cash!.balance, 0);
    expect(find.text('Nothing remaining — all settled'), findsOneWidget);
  });
}
