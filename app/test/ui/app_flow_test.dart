// اختبار واجهة شامل: تشغيل التطبيق كاملاً فوق قاعدة بيانات في الذاكرة،
// ثم المرور بالإعداد الأول وإضافة مصروف والتحقق من تحديث الرئيسية.
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/services/providers.dart';
import 'package:daftry/ui/app.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaftryApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('الإعداد الأول ثم إضافة مصروف يظهر في الرئيسية', (tester) async {
    await pumpApp(tester);

    // لغة جهاز الاختبار الإنجليزية ← الواجهة بالإنجليزية (LTR).
    expect(find.text('Welcome to Daftari'), findsOneWidget);

    // زر المتابعة معطّل حتى تُختار عملة.
    final continueButton = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

    await tester.tap(find.text('Saudi Riyal'));
    await tester.pumpAndSettle();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    // نافذة تأكيد العملة قبل القفل.
    expect(find.text('Confirm app currency'), findsOneWidget);
    await tester.tap(find.text('Confirm & start'));
    await tester.pumpAndSettle();

    // الرئيسية: بطاقة الرصيد والعمليات السريعة (بدون «تحويل» لوجود حساب واحد).
    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('Transfer'), findsNothing);

    // إضافة مصروف 245 من زر الإضافة الدائم.
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Add transaction'), findsOneWidget);
    for (final key in ['2', '4', '5']) {
      await tester.tap(find.text(key).last);
      await tester.pump();
    }
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    // عادت الرئيسية وظهر المصروف في «آخر المعاملات» والرصيد تحدّث.
    expect(find.text('Food'), findsWidgets);
    expect(find.textContaining('-245.00'), findsWidgets);
    final cash = await db.select(db.accounts).getSingle();
    expect(cash.balance, -24500);
  });

  testWidgets('الواجهة العربية تعمل من اليمين لليسار', (tester) async {
    await db
        .into(db.settings)
        .insert(SettingsCompanion.insert(key: 'locale', value: 'ar'));
    await pumpApp(tester);
    expect(find.text('مرحباً بك في دفتري'), findsOneWidget);
    final context = tester.element(find.text('مرحباً بك في دفتري'));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
