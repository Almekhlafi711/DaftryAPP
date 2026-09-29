// اختبار ترحيل قاعدة البيانات من الإصدار 1 إلى 2 على بيانات حقيقية أنشأها
// الكود القديم نفسه (test/fixtures/daftry_v1.sql): حساب مؤرشف برصيد، أشخاص
// مخفيون (مسدد / عليه دين)، عنوان، دين بلا حساب، ودفعة «في الدفتر فقط».
// ويشمل استعادة نسخة احتياطية قديمة (الإصدار 1) عبر BackupService.
import 'dart:io';

import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/data/seed/default_categories.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/services/account_service.dart';
import 'package:daftry/services/backup/backup_service.dart';
import 'package:daftry/services/debt_service.dart';
import 'package:daftry/services/security_service.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

/// ملف SQLite بمخطط الإصدار 1 من ملف النص المرجعي.
Future<File> _v1File() async {
  final dir = await Directory.systemTemp.createTemp('daftry_v1');
  final file = File('${dir.path}/v1.sqlite');
  final conn = raw.sqlite3.open(file.path);
  conn.execute(File('test/fixtures/daftry_v1.sql').readAsStringSync());
  conn.close();
  return file;
}

AppDatabase _open(File file) => AppDatabase(
  NativeDatabase(file, setup: (raw) => raw.execute('PRAGMA foreign_keys = ON')),
);

/// يتحقق من كل ما يجب أن يصح بعد الترحيل.
Future<void> _expectMigrated(AppDatabase db) async {
  final version = await db.customSelect('PRAGMA user_version').getSingle();
  expect(version.read<int>('user_version'), 2);

  // الدفعات لم تُحذف عند إعادة بناء جدول الديون (المفاتيح الأجنبية أُوقفت).
  final payments = await db.select(db.debtPayments).get();
  expect(payments, hasLength(4));
  expect(payments.every((p) => !p.isCancelled), isTrue);
  expect(payments.map((p) => p.operationId).toSet(), hasLength(4));
  expect(payments.every((p) => p.operationId != null), isTrue);

  // الدين المرتبط بحساب ← إقراض/اقتراض، وغير المرتبط ← دين سابق.
  final debts = {
    for (final d in await db.select(db.debts).get()) d.note ?? '#${d.id}': d,
  };
  expect(debts['سلفة']!.source, DebtSource.loan);
  expect(debts['بضاعة']!.source, DebtSource.opening);
  expect(debts.values.every((d) => d.writtenOff == 0), isTrue);

  // المتبقي يُحسب من الدفعات: سلفة 1,200 − 500 = 700، بضاعة 800 − 300 = 500.
  final service = DebtService(db);
  expect((await service.debtView(debts['سلفة']!.id))!.remaining, 70000);
  expect((await service.debtView(debts['بضاعة']!.id))!.remaining, 50000);

  // الأشخاص: المخفي المسدد ← مؤرشف، والمخفي وعليه دين ← يعود ظاهراً.
  final contacts = {
    for (final c in await db.select(db.contacts).get()) c.name: c,
  };
  expect(contacts['مخفي مسدد']!.isArchived, isTrue);
  expect(contacts['مخفي مسدد']!.archivedAt, isNotNull);
  expect(contacts['مخفي عليه دين']!.isArchived, isFalse);
  // العنوان يُضم إلى الملاحظة.
  expect(contacts['أحمد علي']!.note, 'زميل عمل\nصنعاء');
  expect(contacts['صالح']!.note, 'عدن');

  // الحساب المؤرشف وله رصيد يعود نشطاً، والمؤرشف برصيد صفر يبقى مؤرشفاً.
  final accounts = {
    for (final a in await db.select(db.accounts).get()) a.name: a,
  };
  expect(accounts['المحفظة']!.isArchived, isFalse);
  expect(accounts['المحفظة']!.balance, 30000);
  expect(accounts['حساب قديم']!.isArchived, isTrue);

  // المعاملات كما هي، والفئات الافتراضية لها مفاتيح ثابتة.
  expect(await db.select(db.transactions).get(), hasLength(9));
  final sales = await (db.select(
    db.categories,
  )..where((c) => c.systemKey.equals(SystemCategoryKeys.sales))).getSingle();
  expect(sales.name, 'مبيعات');

  // المخطط سليم تماماً، ومعادلة التطابق الشاملة متحققة (بما فيها الدفعة
  // القديمة «في الدفتر فقط» والديون السابقة).
  expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  final integrity = await db.customSelect('PRAGMA integrity_check').getSingle();
  expect(integrity.data.values.single, 'ok');
  expect(await AccountService(db).reconciliationGap(), 0);
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('الترحيل 1 → 2 يحافظ على كل البيانات ويطبّق القواعد الجديدة', () async {
    final db = _open(await _v1File());
    addTearDown(db.close);
    await _expectMigrated(db);

    // والمخطط الجديد يعمل: عملية سداد موزّعة على البيانات المُرحَّلة.
    final ahmed = (await (db.select(
      db.contacts,
    )..where((c) => c.name.equals('أحمد علي'))).getSingle()).id;
    final debts = DebtService(db);
    final open = await debts.openDebts(ahmed, DebtDirection.owedToMe);
    // الأقدم أولاً: البضاعة (1 أغسطس) قبل السلفة (10 أغسطس).
    expect(open.map((o) => o.debt.note).toList(), ['بضاعة', 'سلفة']);
  });

  test('استعادة نسخة احتياطية من الإصدار 1 تُرحَّل تلقائياً', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await SettingsService(db).getPreferences(); // فتح القاعدة الحالية.
    final backup = BackupService(
      db: db,
      settings: SettingsService(db),
      secrets: MemorySecretStore(),
      tempDirectory: () async => Directory.systemTemp.createTemp('daftry_rs'),
    );
    await backup.restoreSqlite((await _v1File()).readAsBytesSync());
    await _expectMigrated(db);
    expect(await SettingsService(db).isOnboarded(), isTrue);
  });
}
