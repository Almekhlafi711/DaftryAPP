// زر الرجوع في Android (عبر رسالة النظام نفسها «popRoute»):
// - الصفحة المفتوحة فوق التبويبات ← تُغلق وتعود للصفحة السابقة.
// - التبويب غير الرئيسي ← يعود إلى «الرئيسية».
// - «الرئيسية» ← رسالة «اضغط رجوع مرة أخرى للخروج»، والثانية خلال ثانيتين تخرج.
import 'package:daftry/core/constants/currencies.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:daftry/services/contact_service.dart';
import 'package:daftry/services/debt_service.dart';
import 'package:daftry/services/providers.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:daftry/ui/app.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// طلبات الخروج من التطبيق (SystemNavigator.pop).
late List<String> _exitCalls;

Future<void> _start(WidgetTester tester) async {
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

  _exitCalls = [];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'SystemNavigator.pop') _exitCalls.add(call.method);
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );

  await tester.runAsync(() async {
    await SettingsService(db)
        .completeOnboarding(currencyByCode('SAR')!, arabic: false);
    final ahmed = await ContactService(db).create(name: 'Ahmed Ali');
    await DebtService(db).createDebt(
      DebtDraft(
        contactId: ahmed,
        direction: DebtDirection.owedToMe,
        source: DebtSource.opening,
        amount: 50000,
        startDate: DateTime.now(),
      ),
    );
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const DaftryApp(),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
}

/// ضغطة زر الرجوع في النظام كما يرسلها Android.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// تبويب في الشريط السفلي.
Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Finder get _home => find.text('Total balance');

void main() {
  testWidgets('الرئيسية: ضغطة رجوع تُظهر التنبيه، والثانية تخرج', (
    tester,
  ) async {
    await _start(tester);
    expect(_home, findsOneWidget);

    await _systemBack(tester);
    expect(find.text('Press back again to exit'), findsOneWidget);
    expect(_exitCalls, isEmpty);
    expect(_home, findsOneWidget);

    await _systemBack(tester);
    expect(_exitCalls, ['SystemNavigator.pop']);
  });

  testWidgets('بعد انتهاء المهلة تعود الضغطة الأولى تنبيهاً فقط', (
    tester,
  ) async {
    await _start(tester);
    await _systemBack(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2200)),
    );
    await _systemBack(tester);
    expect(_exitCalls, isEmpty);
    expect(find.text('Press back again to exit'), findsOneWidget);
  });

  testWidgets('من أي تبويب آخر يعود الرجوع إلى الرئيسية دون خروج', (
    tester,
  ) async {
    await _start(tester);
    for (final tab in ['Debts', 'Activity', 'More']) {
      await _tab(tester, tab);
      expect(_home, findsNothing, reason: tab);
      await _systemBack(tester);
      expect(_home, findsOneWidget, reason: tab);
      expect(find.text('Press back again to exit'), findsNothing);
    }
    expect(_exitCalls, isEmpty);
  });

  testWidgets('الصفحات الفرعية: كل رجوع يعود خطوة واحدة للصفحة السابقة', (
    tester,
  ) async {
    await _start(tester);

    // الإعدادات ← الحسابات ← رجوع ← الإعدادات ← رجوع ← الرئيسية.
    await _tab(tester, 'More');
    await tester.scrollUntilVisible(
      find.text('Accounts'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Add account'), findsOneWidget);
    await _systemBack(tester);
    expect(find.byTooltip('Add account'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    await _systemBack(tester);
    expect(_home, findsOneWidget);

    // الديون ← ملف الشخص ← كشف الحساب ← رجوع ← الملف ← رجوع ← الديون.
    await _tab(tester, 'Debts');
    await tester.tap(find.text('Ahmed Ali'));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed owes me'), findsOneWidget);
    await tester.tap(find.text('Statement'));
    await tester.pumpAndSettle();
    expect(find.text('Statement — Ahmed Ali'), findsOneWidget);
    await _systemBack(tester);
    expect(find.text('Ahmed owes me'), findsOneWidget);
    await _systemBack(tester);
    expect(find.text('Ahmed owes me'), findsNothing);
    expect(find.text('Separate from income and expenses'), findsOneWidget);

    // نافذة سفلية مفتوحة: الرجوع يغلقها فقط.
    await tester.tap(find.byTooltip('Filter debts'));
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsOneWidget);
    await _systemBack(tester);
    expect(find.text('Apply'), findsNothing);
    expect(find.text('Separate from income and expenses'), findsOneWidget);

    // زر الإضافة ← نموذج المعاملة ← رجوع يغلقه.
    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Add transaction'), findsWidgets);
    await _systemBack(tester);
    expect(find.text('Separate from income and expenses'), findsOneWidget);

    expect(_exitCalls, isEmpty);
  });
}
