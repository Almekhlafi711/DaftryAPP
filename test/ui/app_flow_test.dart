// اختبار واجهة شامل: تشغيل التطبيق كاملاً فوق قاعدة بيانات في الذاكرة،
// ثم المرور بالإعداد الأول (شاشات الترحيب ← الاسم ← العملة) وإضافة مصروف
// والتحقق من تحديث الرئيسية.
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/services/providers.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:daftry/ui/app.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  Future<void> pumpApp(WidgetTester tester, {String locale = 'en'}) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // نثبّت اللغة حتى لا يعتمد الاختبار على لغة الجهاز/المحاكي.
    await tester.runAsync(
      () => db
          .into(db.settings)
          .insert(SettingsCompanion.insert(key: 'locale', value: locale)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const DaftryApp(),
      ),
    );
    await tester.pumpAndSettle();
    // نفكّ الواجهة قبل إغلاق قاعدة البيانات (التنظيف يعمل بترتيب عكسي).
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  }

  Finder filled(String text) => find.widgetWithText(FilledButton, text);

  testWidgets('الإعداد الأول ثم إضافة مصروف يظهر في الرئيسية', (tester) async {
    await pumpApp(tester);

    // 1) شاشات الترحيب (يمكن تخطيها).
    expect(find.text('Welcome to Daftari'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // 2) الملف الشخصي: الاسم مطلوب ورقم الجوال اختياري.
    expect(find.text('Tell us about you'), findsOneWidget);
    expect(tester.widget<FilledButton>(filled('Continue')).onPressed, isNull);
    await tester.enterText(
      find.widgetWithText(TextField, 'Your name *'),
      'Mohammed',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone (optional)'),
      '+967 777 953 434',
    );
    await tester.pump();
    await tester.tap(filled('Continue'));
    await tester.pumpAndSettle();

    // 3) العملة: زر المتابعة معطّل حتى تُختار عملة.
    expect(
      find.text('Choose your currency *', findRichText: true),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(filled('Continue')).onPressed, isNull);
    await tester.tap(find.text('Saudi Riyal'));
    await tester.pumpAndSettle();
    await tester.tap(filled('Continue'));
    await tester.pumpAndSettle();

    // نافذة تأكيد العملة قبل القفل.
    expect(find.text('Confirm app currency'), findsOneWidget);
    await tester.tap(find.text('Confirm & start'));
    await tester.pumpAndSettle();

    // الاسم والرقم محفوظان (الرقم موحّد)، والتحية باسم المستخدم.
    final prefs = await tester.runAsync(
      () => SettingsService(db).getPreferences(),
    );
    expect(prefs!.userName, 'Mohammed');
    expect(prefs.userPhone, '+967777953434');
    expect(find.textContaining('Mohammed'), findsOneWidget);

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
    await tester.tap(filled('Save'));
    await tester.pumpAndSettle();

    // عادت الرئيسية وظهر المصروف في «آخر المعاملات» والرصيد تحدّث.
    expect(find.text('Food'), findsWidgets);
    expect(find.textContaining('-245.00'), findsWidgets);
    final cash = await tester.runAsync(
      () => db.select(db.accounts).getSingle(),
    );
    expect(cash!.balance, -24500);
  });

  testWidgets('شاشات الترحيب الثلاث ثم رقم جوال غير صحيح', (tester) async {
    await pumpApp(tester);
    expect(find.text('Welcome to Daftari'), findsOneWidget);
    await tester.tap(filled('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Everything to manage your money'), findsOneWidget);
    await tester.tap(filled('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Key steps to get started'), findsOneWidget);
    expect(find.text('Choose your currency carefully'), findsOneWidget);
    // الصفحة الأخيرة: «ابدأ الآن» بدل «التالي».
    await tester.tap(filled('Get started'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Your name *'),
      'Mohammed',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone (optional)'),
      '12',
    );
    await tester.pump();
    await tester.tap(filled('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid phone number'), findsOneWidget);
    expect(find.text('Tell us about you'), findsOneWidget);

    // زر الرجوع يعود لشاشات الترحيب.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Daftari'), findsOneWidget);
  });

  testWidgets('الواجهة العربية تعمل من اليمين لليسار', (tester) async {
    await pumpApp(tester, locale: 'ar');
    expect(find.text('مرحباً بك في دفتري'), findsOneWidget);
    final context = tester.element(find.text('مرحباً بك في دفتري'));
    expect(Directionality.of(context), TextDirection.rtl);
  });
}
