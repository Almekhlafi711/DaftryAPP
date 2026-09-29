// =============================================================================
// خدمة النسخ الاحتياطي (BackupService في مخطط الفئات) — FR-25 / UC-12.
//
// 1) النسخ: VACUUM INTO يأخذ لقطة متسقة من قاعدة البيانات (حتى أثناء
//    الاستخدام) ← ضغط GZip ← تشفير AES-256 ← حفظ محلي أو رفع للسحابة.
// 2) الاستعادة: فك التشفير ← التحقق من الملف وإصداره ← نسخ الجداول داخل
//    عملية ذرية واحدة (إما أن تُستعاد كل البيانات أو لا يتغير شيء).
// 3) الجدولة: عند فتح التطبيق نتحقق إن كان موعد النسخ قد حان (يومي/أسبوعي/
//    شهري) فننسخ بصمت — دون خوادم خاصة ولا مهام خلفية معقدة.
//
// النسخ السحابي اختياري بالكامل: إن لم يُفعَّل لا يُرسل التطبيق أي طلب شبكة.
// =============================================================================

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as raw;

import '../../core/errors/app_exception.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../security_service.dart';
import '../settings_service.dart';
import 'backup_crypto.dart';
import 'cloud_provider.dart';

/// امتداد ملفات النسخ الاحتياطي الخاصة بالتطبيق.
const kBackupExtension = 'dftry';

class BackupService {
  BackupService({
    required this.db,
    required this.settings,
    required this.secrets,
    required this.tempDirectory,
    this.providers = const {},
    this.crypto = const BackupCrypto(),
    this.isOnWifi,
  });

  final AppDatabase db;
  final SettingsService settings;
  final SecretStore secrets;

  /// مجلد مؤقت لكتابة اللقطات (path_provider في التطبيق، مجلد النظام في الاختبارات).
  final Future<Directory> Function() tempDirectory;
  final Map<BackupProvider, CloudProvider> providers;
  final BackupCrypto crypto;

  /// فحص الاتصال بشبكة Wi-Fi (لخيار «النسخ عبر Wi-Fi فقط»).
  final Future<bool> Function()? isOnWifi;

  /// إعدادات خاصة بهذا الجهاز لا تُستبدل عند الاستعادة (مثل القفل؛ لأن رمز
  /// PIN محفوظ في التخزين الآمن للجهاز القديم وليس في النسخة).
  static const _deviceSettingKeys = [
    SettingKeys.lockEnabled,
    SettingKeys.biometricEnabled,
    SettingKeys.backupEnabled,
    SettingKeys.backupProvider,
    SettingKeys.backupFrequency,
    SettingKeys.backupWifiOnly,
    SettingKeys.backupLastAt,
  ];

  /// اسم ملف مثل: daftry-backup-20260925-2130.dftry
  static String fileNameFor(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'daftry-backup-${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}.$kBackupExtension';
  }

  // ---------------------------------------------------------------------------
  // كلمة مرور التشفير (تُحفظ في التخزين الآمن للنسخ المجدول)
  // ---------------------------------------------------------------------------

  Future<String?> savedPassword() =>
      secrets.read(SecurityService.backupPasswordKey);

  Future<void> savePassword(String password) =>
      secrets.write(SecurityService.backupPasswordKey, password);

  // ---------------------------------------------------------------------------
  // النسخ
  // ---------------------------------------------------------------------------

  /// لقطة متسقة من قاعدة البيانات كملف SQLite (غير مشفرة).
  Future<Uint8List> snapshot() async {
    final dir = await tempDirectory();
    final file = File(
      p.join(
        dir.path,
        'snapshot-${DateTime.now().microsecondsSinceEpoch}.sqlite',
      ),
    );
    try {
      await db.customStatement('VACUUM INTO ?', [file.path]);
      return await file.readAsBytes();
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  /// نسخة مشفرة جاهزة للحفظ أو الرفع.
  Future<Uint8List> createEncryptedBackup(String password) async =>
      crypto.encrypt(await snapshot(), password);

  /// «نسخ الآن» إلى السحابة. يعيد اسم الملف المرفوع.
  Future<String> backupToCloud({String? password}) async {
    final prefs = await settings.getPreferences();
    final provider = _provider(prefs.backupProvider);
    final pass = password ?? await savedPassword();
    if (pass == null || pass.isEmpty) {
      throw const BusinessException(BusinessError.backupDecryptionFailed);
    }
    final bytes = await createEncryptedBackup(pass);
    final name = fileNameFor(DateTime.now());
    try {
      await provider.upload(bytes, name);
    } on BusinessException catch (e) {
      await _log(provider.kind, bytes.length, e.error.name);
      rethrow;
    } on Exception catch (e) {
      await _log(provider.kind, bytes.length, 'error: $e');
      throw const BusinessException(BusinessError.noConnection);
    }
    await _log(provider.kind, bytes.length, 'success');
    await settings.set(
      SettingKeys.backupLastAt,
      DateTime.now().toIso8601String(),
    );
    return name;
  }

  /// هل حان موعد النسخ المجدول؟
  static bool isDue(AppPreferences prefs, DateTime now) {
    if (!prefs.backupEnabled) return false;
    final last = prefs.backupLastAt;
    if (last == null) return true;
    final interval = switch (prefs.backupFrequency) {
      'daily' => const Duration(days: 1),
      'monthly' => const Duration(days: 30),
      _ => const Duration(days: 7),
    };
    return !now.isBefore(last.add(interval));
  }

  /// يُستدعى عند فتح التطبيق: ينسخ بصمت إن حان الموعد (ولا يرمي أخطاء).
  /// إن لم يوجد اتصال يُؤجَّل النسخ للمرة القادمة (UC-12 / 4أ).
  Future<void> runScheduledIfDue() async {
    try {
      final prefs = await settings.getPreferences();
      if (!isDue(prefs, DateTime.now())) return;
      if (prefs.backupWifiOnly && isOnWifi != null && !await isOnWifi!()) {
        return;
      }
      await backupToCloud();
    } on Object {
      // صامت: سيُعاد المحاولة عند الفتح القادم، والخطأ مسجل في backup_logs.
    }
  }

  Future<List<CloudBackupFile>> listCloudBackups() async {
    final prefs = await settings.getPreferences();
    return _provider(prefs.backupProvider).list();
  }

  Stream<List<BackupLog>> watchLogs() =>
      (db.select(db.backupLogs)
            ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
            ..limit(20))
          .watch();

  // ---------------------------------------------------------------------------
  // الاستعادة
  // ---------------------------------------------------------------------------

  Future<void> restoreFromCloud(String fileId, String password) async {
    final prefs = await settings.getPreferences();
    final bytes = await _provider(prefs.backupProvider).download(fileId);
    await restoreEncrypted(bytes, password);
  }

  /// استعادة ملف .dftry مشفر (من السحابة أو من ملف محلي).
  Future<void> restoreEncrypted(List<int> data, String password) async {
    final plain = await crypto.decrypt(data, password);
    await restoreSqlite(plain);
  }

  /// استعادة لقطة SQLite: تستبدل كل البيانات الحالية ذرياً.
  Future<void> restoreSqlite(Uint8List sqliteBytes) async {
    final dir = await tempDirectory();
    final file = File(
      p.join(
        dir.path,
        'restore-${DateTime.now().microsecondsSinceEpoch}.sqlite',
      ),
    );
    await file.writeAsBytes(sqliteBytes, flush: true);
    try {
      final version = _inspect(file.path);
      if (version > db.schemaVersion) {
        // نسخة من إصدار أحدث من التطبيق: يجب تحديث التطبيق أولاً.
        throw const BusinessException(BusinessError.backupInvalidFile);
      }
      if (version < db.schemaVersion) {
        // نسخة قديمة: نفتحها بـ Drift ليطبق خطوات الترحيل عليها أولاً.
        final old = AppDatabase(NativeDatabase(file));
        await old.customSelect('SELECT 1').get();
        await old.close();
      }
      await _copyFrom(file.path);
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  /// يتحقق أن الملف قاعدة «دفتري» صالحة ويعيد رقم إصدار مخططها.
  int _inspect(String path) {
    final raw.Database conn;
    try {
      conn = raw.sqlite3.open(path, mode: raw.OpenMode.readOnly);
    } on Object {
      throw const BusinessException(BusinessError.backupInvalidFile);
    }
    try {
      final tables = conn
          .select("SELECT name FROM sqlite_master WHERE type = 'table'")
          .map((r) => r['name'] as String)
          .toSet();
      const required = {'accounts', 'transactions', 'debts', 'settings'};
      if (!tables.containsAll(required)) {
        throw const BusinessException(BusinessError.backupInvalidFile);
      }
      return conn.userVersion;
    } on raw.SqliteException {
      throw const BusinessException(BusinessError.backupInvalidFile);
    } finally {
      conn.close();
    }
  }

  Future<void> _copyFrom(String path) async {
    final tables = db.tablesInInsertOrder;
    await db.customStatement('ATTACH DATABASE ? AS bk', [path]);
    try {
      await db.transaction(() async {
        final keep = await (db.select(
          db.settings,
        )..where((s) => s.key.isIn(_deviceSettingKeys))).get();

        await db.customStatement(
          'DROP TRIGGER IF EXISTS trg_accounts_no_delete',
        );
        // الحذف بعكس ترتيب الإدراج (الأبناء أولاً) بسبب المفاتيح الأجنبية.
        for (final t in tables.reversed) {
          await db.customStatement('DELETE FROM main."${t.actualTableName}"');
        }
        for (final t in tables) {
          final cols = t.$columns.map((c) => '"${c.name}"').join(', ');
          await db.customStatement(
            'INSERT INTO main."${t.actualTableName}" ($cols) '
            'SELECT $cols FROM bk."${t.actualTableName}"',
          );
        }
        // إعادة إعدادات الجهاز الحالي كما كانت.
        await (db.delete(
          db.settings,
        )..where((s) => s.key.isIn(_deviceSettingKeys))).go();
        for (final s in keep) {
          await db.into(db.settings).insert(s);
        }
        await db.ensureTriggers();
      });
    } finally {
      await db.customStatement('DETACH DATABASE bk');
    }
    // إبلاغ كل التدفقات التفاعلية بأن البيانات تغيّرت لتُحدَّث الواجهة.
    db.notifyUpdates({for (final t in tables) TableUpdate.onTable(t)});
  }

  CloudProvider _provider(BackupProvider kind) {
    final provider = providers[kind];
    if (provider == null) {
      throw const BusinessException(BusinessError.cloudNotAuthorized);
    }
    return provider;
  }

  Future<void> _log(BackupProvider provider, int bytes, String status) => db
      .into(db.backupLogs)
      .insert(
        BackupLogsCompanion.insert(
          provider: provider,
          sizeKb: Value((bytes / 1024).ceil()),
          status: status,
        ),
      );
}
