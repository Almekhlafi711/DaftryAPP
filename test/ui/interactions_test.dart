// اختبارات تفاعل: الحسابات والأرشفة، نافذة الفلترة، قفل التطبيق برمز PIN،
// وعرض الإيصال المرفق.
import 'package:daftry/core/constants/currencies.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/services/providers.dart';
import 'package:daftry/services/security_service.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:daftry/ui/app.dart';
import 'package:daftry/ui/router/routes.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// يشغّل التطبيق بالإنجليزية بعد إكمال الإعداد الأول، ويعيد المُوجّه.
Future<({AppDatabase db, dynamic router})> startApp(
  WidgetTester tester, {
  SecurityService? security,
}) async {
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
  await tester.runAsync(
    () =>
        SettingsService(db)
            .completeOnboarding(currencyByCode('SAR')!, arabic: false),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        if (security != null)
          securityServiceProvider.overrideWithValue(security),
      ],
      child: const DaftryApp(),
    ),
  );
  await tester.pumpAndSettle();
  // نفكّ الواجهة قبل إغلاق قاعدة البيانات (التنظيف يعمل بترتيب عكسي).
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  final router = ProviderScope.containerOf(
    tester.element(find.byType(DaftryApp)),
  ).read(routerProvider);
  return (db: db, router: router);
}

void main() {
  testWidgets('إضافة حساب ثم أرشفته دون تحويل', (tester) async {
    final app = await startApp(tester);
    app.router.go(AppRoutes.accounts);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Account name'),
      'Al Rajhi',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Opening balance'),
      '500',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Al Rajhi'), findsOneWidget);
    expect(find.text('Active (2)'), findsOneWidget);

    // قائمة الحساب: لا يوجد خيار حذف، فقط أرشفة.
    await tester.tap(find.byIcon(Icons.more_vert_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsNothing);
    await tester.tap(find.text('Archive').last);
    await tester.pumpAndSettle();
    expect(find.text('Archive “Al Rajhi”?'), findsOneWidget);
    await tester.tap(find.text('Archive without transfer'));
    await tester.pumpAndSettle();

    expect(find.text('Archived (1)'), findsOneWidget);
    final bank = await tester.runAsync(
      () => (app.db.select(
        app.db.accounts,
      )..where((a) => a.name.equals('Al Rajhi'))).getSingle(),
    );
    expect(bank!.isArchived, isTrue);

    // رفع الأرشفة يعيده نشطاً.
    await tester.tap(find.text('Unarchive'));
    await tester.pumpAndSettle();
    expect(find.text('Active (2)'), findsOneWidget);
  });

  testWidgets('نافذة الفلترة: كل الفترات وإخفاء حركات الديون', (tester) async {
    final app = await startApp(tester);
    app.router.go(AppRoutes.transactions);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Filter transactions'), findsOneWidget);
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    // عناصر النافذة أسفل الشاشة: نمرر حتى تظهر.
    final sheetScroll = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text('Show debt movements'),
      200,
      scrollable: sheetScroll,
    );
    await tester.tap(find.text('Show debt movements'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Highest amount'),
      200,
      scrollable: sheetScroll,
    );
    await tester.tap(find.text('Highest amount'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    // شارة عدد الفلاتر المفعّلة (إخفاء الديون + الترتيب).
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.filter_alt_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget); // الفترة الافتراضية: هذا الشهر
  });

  testWidgets('تفعيل القفل بإنشاء PIN ثم فتح التطبيق به', (tester) async {
    final security = SecurityService(store: MemorySecretStore());
    final app = await startApp(tester, security: security);
    app.router.go(AppRoutes.security);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    Future<void> enter(String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.widgetWithText(TextButton, d));
        await tester.pump();
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    expect(find.text('Create a 4-digit PIN'), findsOneWidget);
    await enter('1234');
    expect(find.text('Re-enter to confirm'), findsOneWidget);
    await enter('1234');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    final prefs = await tester.runAsync(
      () => SettingsService(app.db).getPreferences(),
    );
    expect(prefs!.lockEnabled, isTrue);
    expect(await tester.runAsync(() => security.verifyPin('1234')), isTrue);
  });

  testWidgets(
    'عرض الإيصال: ملف مفقود (بعد النقل لجهاز آخر) يظهر كأيقونة بديلة',
    (tester) async {
      final app = await startApp(tester);
      final id = await tester.runAsync(() async {
        final cash = await (app.db.select(
          app.db.accounts,
        )..limit(1)).getSingle();
        final food =
            await (app.db.select(app.db.categories)
                  ..where((c) => c.kind.equals(CategoryKind.expense.name))
                  ..limit(1))
                .getSingle();
        return app.db
            .into(app.db.transactions)
            .insert(
              TransactionsCompanion.insert(
                type: TxType.expense,
                amount: 1000,
                currencyId: 1,
                accountId: cash.id,
                categoryId: Value(food.id),
                date: DateTime.now(),
                receiptPath: const Value('/missing/receipt.jpg'),
              ),
            );
      });
      app.router.push(AppRoutes.editTransaction(id!));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.receipt_long_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Remove receipt'), findsOneWidget);
      await tester.tap(find.text('View receipt'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
    },
  );
}
