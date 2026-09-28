// =============================================================================
// فحوص خاصة بالجهاز الحقيقي: مكونات لا تعمل إلا على Android/iOS فعلياً.
// - قاعدة البيانات عبر الاتصال الحقيقي (Isolate خلفي + WAL) على ملف.
// - التخزين الآمن (Keystore/Keychain) لرمز PIN.
// - النسخ الاحتياطي المشفّر والاستعادة بملف على الجهاز (نقل البيانات).
// - كشف حساب 100 حركة PDF وصورة في أقل من 3 ثوانٍ (المتطلبات غير الوظيفية).
// =============================================================================

import 'dart:io';

import 'package:daftry/core/constants/currencies.dart';
import 'package:daftry/core/money/money.dart';
import 'package:daftry/core/utils/date_range.dart';
import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:daftry/services/account_service.dart';
import 'package:daftry/services/backup/backup_service.dart';
import 'package:daftry/services/budget_service.dart';
import 'package:daftry/services/contact_service.dart';
import 'package:daftry/services/debt_service.dart';
import 'package:daftry/services/demo_data_service.dart';
import 'package:daftry/services/export/pdf_fonts.dart';
import 'package:daftry/services/export/statement_pdf.dart';
import 'package:daftry/services/security_service.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:daftry/services/statement_service.dart';
import 'package:daftry/services/transaction_service.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// قاعدة بيانات حقيقية على ملف مؤقت (نفس طريقة فتح التطبيق، باسم مختلف).
Future<AppDatabase> openFileDatabase(String name) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, '$name.sqlite'));
  if (await file.exists()) await file.delete();
  return AppDatabase(
    driftDatabase(
      name: name,
      native: DriftNativeOptions(databaseDirectory: getTemporaryDirectory),
    ),
  );
}

Future<void> loadDemo(AppDatabase db) async {
  await SettingsService(db)
      .completeOnboarding(currencyByCode('SAR')!, arabic: true);
  final budgets = BudgetService(db);
  await DemoDataService(
    db: db,
    accounts: AccountService(db),
    transactions: TransactionService(db, budgets),
    budgets: budgets,
    contacts: ContactService(db),
    debts: DebtService(db),
  ).load(arabic: true);
}

void main() {
  testWidgets(
    'قاعدة البيانات الحقيقية: Isolate خلفي + WAL + منع حذف الحسابات',
    (tester) async {
      await tester.runAsync(() async {
        final db = await openFileDatabase('daftry_device_check');
        await loadDemo(db);
        final mode = await db.customSelect('PRAGMA journal_mode').getSingle();
        expect(mode.data.values.first.toString().toLowerCase(), 'wal');
        expect(await AccountService(db).recalculateAll(), 0);
        final cash = await AccountService(db).getDefault();
        await expectLater(
          (db.delete(db.accounts)..where((a) => a.id.equals(cash!.id))).go(),
          throwsA(anything),
        );
        await db.close();
      });
    },
  );

  testWidgets('التخزين الآمن للجهاز: رمز PIN يُحفظ كبصمة ويُتحقق منه', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const store = SecureSecretStore();
      final security = SecurityService(store: store);
      await security.setPin('2468');
      expect(await security.hasPin(), isTrue);
      final stored = await store.read('daftry.pin_hash');
      expect(stored, isNot(contains('2468')));
      expect(await security.verifyPin('2468'), isTrue);
      expect(await security.verifyPin('1111'), isFalse);
      await security.clearPin();
      expect(await security.hasPin(), isFalse);
    });
  });

  testWidgets('نقل البيانات: نسخة مشفّرة في ملف ← حذف كل شيء ← استعادة كاملة', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final db = await openFileDatabase('daftry_backup_check');
      await loadDemo(db);
      final settings = SettingsService(db);
      final backup = BackupService(
        db: db,
        settings: settings,
        secrets: MemorySecretStore(),
        tempDirectory: getTemporaryDirectory,
      );
      Future<(int, int, int)> snapshot() async => (
        await AccountService(db).watchTotalBalance().first,
        (await db.select(db.transactions).get()).length,
        (await db.select(db.debts).get()).length,
      );
      final before = await snapshot();

      // كما يفعل المستخدم: تصدير ملف .dftry بكلمة مرور (تشفير كامل 120 ألف دورة).
      final watch = Stopwatch()..start();
      final bytes = await backup.createEncryptedBackup('كلمة-سر-قوية');
      final docs = await getApplicationDocumentsDirectory();
      final file = File(
        p.join(docs.path, BackupService.fileNameFor(DateTime.now())),
      );
      await file.writeAsBytes(bytes, flush: true);
      debugPrint(
        'backup: ${bytes.length ~/ 1024} KB in ${watch.elapsedMilliseconds} ms',
      );

      // كلمة مرور خاطئة تُرفض ولا تغيّر شيئاً.
      await expectLater(
        backup.restoreEncrypted(await file.readAsBytes(), 'خطأ'),
        throwsA(anything),
      );
      expect(await snapshot(), before);

      // «جهاز جديد»: حذف كل البيانات ثم الاستعادة من الملف.
      await settings.wipeAllData();
      expect(await settings.isOnboarded(), isFalse);
      watch.reset();
      await backup.restoreEncrypted(await file.readAsBytes(), 'كلمة-سر-قوية');
      debugPrint('restore: ${watch.elapsedMilliseconds} ms');
      expect(await settings.isOnboarded(), isTrue);
      expect(await snapshot(), before);
      expect(await AccountService(db).recalculateAll(), 0);

      await file.delete();
      await db.close();
    });
  });

  testWidgets('الأداء: كشف حساب 100 حركة PDF + صورة في أقل من 3 ثوانٍ', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await initializeDateFormatting();
      final db = await openFileDatabase('daftry_perf_check');
      await SettingsService(db)
          .completeOnboarding(currencyByCode('SAR')!, arabic: true);
      final contact = await ContactService(db).create(name: 'أحمد علي');
      final debts = DebtService(db);
      final start = DateTime.now().subtract(const Duration(days: 60));
      for (var i = 0; i < 50; i++) {
        final id = await debts.createDebt(
          DebtDraft(
            contactId: contact,
            direction: DebtDirection.owedToMe,
            amount: 10000 + i * 100,
            startDate: start.add(Duration(days: i)),
            note: 'فاتورة $i',
          ),
        );
        await debts.recordPayment(
          id,
          PaymentDraft(
            amount: 5000,
            paidAt: start.add(Duration(days: i, hours: 5)),
          ),
        );
      }

      final watch = Stopwatch()..start();
      final data = await StatementService(db)
          .build(contact, DateRange.lastDays(90));
      expect(data.lines, hasLength(100));
      final pdf = await StatementPdf(
        fonts: await PdfFonts.load(),
        money: MoneyFormatter(decimals: 2, symbol: 'ر.س'),
        locale: 'ar',
        rtl: true,
        labels: const StatementLabels(
          appName: 'دفتري',
          title: 'كشف حساب',
          period: 'الفترة',
          openingBalance: 'الرصيد الافتتاحي',
          closingBalance: 'المتبقي',
          date: 'التاريخ',
          description: 'البيان',
          amount: 'المبلغ',
          balance: 'الرصيد',
          newDebt: 'دين جديد',
          paymentReceived: 'دفعة مستلمة',
          paymentMade: 'دفعة مدفوعة',
          owedToMeHint: 'المستحق على أحمد',
          iOweHint: 'المستحق لأحمد',
          noMovements: 'لا توجد حركات',
          generatedAt: 'أُنشئ في',
        ),
      ).build(data);
      final png = await StatementPdf.rasterFirstPage(pdf);
      watch.stop();
      debugPrint('statement 100 lines: ${watch.elapsedMilliseconds} ms');
      expect(pdf.length, greaterThan(1000));
      expect(png.length, greaterThan(1000));
      expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
      await db.close();
    });
  });
}
