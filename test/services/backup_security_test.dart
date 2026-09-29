// اختبارات النسخ الاحتياطي المشفر والاستعادة، وخدمة الأمان (PIN).
import 'dart:io';
import 'dart:typed_data';

import 'package:daftry/core/constants/currencies.dart';
import 'package:daftry/core/errors/app_exception.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:daftry/domain/models/transaction_models.dart';
import 'package:daftry/services/backup/backup_crypto.dart';
import 'package:daftry/services/backup/backup_service.dart';
import 'package:daftry/services/backup/cloud_provider.dart';
import 'package:daftry/services/security_service.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// مزوّد سحابي وهمي يحفظ الملفات في الذاكرة.
class FakeCloud implements CloudProvider {
  final files = <String, Uint8List>{};

  @override
  BackupProvider get kind => BackupProvider.googleDrive;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> authorize() async => true;
  @override
  Future<String> upload(Uint8List bytes, String fileName) async {
    files[fileName] = bytes;
    return fileName;
  }

  @override
  Future<List<CloudBackupFile>> list() async => [
    for (final e in files.entries)
      CloudBackupFile(
        id: e.key,
        name: e.key,
        createdAt: DateTime.now(),
        sizeBytes: e.value.length,
      ),
  ];
  @override
  Future<Uint8List> download(String id) async => files[id]!;
  @override
  Future<void> delete(String id) async => files.remove(id);
  @override
  Future<void> signOut() async {}
}

void main() {
  late TestEnv env;
  late BackupService backup;
  late FakeCloud cloud;
  late MemorySecretStore secrets;

  setUp(() async {
    env = await TestEnv.create();
    cloud = FakeCloud();
    secrets = MemorySecretStore();
    backup = BackupService(
      db: env.db,
      settings: env.settings,
      secrets: secrets,
      tempDirectory: () async => Directory.systemTemp.createTemp('daftry_test'),
      providers: {BackupProvider.googleDrive: cloud},
      // دورات أقل لتسريع الاختبارات فقط.
      crypto: const BackupCrypto(iterations: 1000),
    );
  });
  tearDown(() => env.dispose());

  Future<void> seed() async {
    final cash = await env.cash;
    final food = await env.category(CategoryKind.expense);
    await env.transactions.add(
      TransactionDraft(
        type: TxType.expense,
        amount: 24500,
        accountId: cash.id,
        categoryId: food.id,
        date: DateTime.now(),
        note: 'سوبرماركت',
      ),
    );
    final c = await env.contacts.create(name: 'أحمد');
    await env.debts.createDebt(
      DebtDraft(
        contactId: c,
        direction: DebtDirection.owedToMe,
        source: DebtSource.loan,
        amount: 100000,
        startDate: DateTime.now(),
        accountId: cash.id,
      ),
    );
  }

  group('النسخ الاحتياطي (UC-12)', () {
    test('نسخ مشفر ثم حذف كل شيء ثم استعادة كاملة', () async {
      await seed();
      final balanceBefore = (await env.cash).balance;
      final file = await backup.createEncryptedBackup('كلمة-سر');

      await env.settings.wipeAllData();
      expect(await env.settings.isOnboarded(), isFalse);

      await backup.restoreEncrypted(file, 'كلمة-سر');
      expect(await env.settings.isOnboarded(), isTrue);
      expect((await env.cash).balance, balanceBefore);
      expect(await env.db.select(env.db.transactions).get(), hasLength(2));
      expect(await env.db.select(env.db.debts).get(), hasLength(1));
      // المشغّل الذي يمنع حذف الحسابات أُعيد إنشاؤه.
      final cash = await env.cash;
      expect(
        (env.db.delete(
          env.db.accounts,
        )..where((a) => a.id.equals(cash.id))).go(),
        throwsA(anything),
      );
    });

    test('التدفقات التفاعلية تتحدث بعد الاستعادة', () async {
      await seed();
      final file = await backup.createEncryptedBackup('x');
      await env.settings.wipeAllData();
      await env.settings.completeOnboarding(
        currencyByCode('SAR')!,
        arabic: true,
      );
      final stream = env.accounts.watchTotalBalance();
      expect(await stream.first, 0);
      await backup.restoreEncrypted(file, 'x');
      expect(await env.accounts.watchTotalBalance().first, -124500);
    });

    test('كلمة مرور خاطئة تُرفض دون تغيير البيانات', () async {
      await seed();
      final file = await backup.createEncryptedBackup('صحيحة');
      expect(
        backup.restoreEncrypted(file, 'خاطئة'),
        throwsA(
          isA<BusinessException>().having(
            (e) => e.error,
            'error',
            BusinessError.backupDecryptionFailed,
          ),
        ),
      );
    });

    test('ملف ليس نسخة دفتري يُرفض', () async {
      expect(
        backup.restoreEncrypted(List.filled(100, 7), 'x'),
        throwsA(
          isA<BusinessException>().having(
            (e) => e.error,
            'error',
            BusinessError.backupInvalidFile,
          ),
        ),
      );
    });

    test('الاستعادة تحافظ على إعدادات القفل الخاصة بالجهاز', () async {
      await seed();
      final file = await backup.createEncryptedBackup('x');
      await env.settings.setFlag(SettingKeys.lockEnabled, true);
      await backup.restoreEncrypted(file, 'x');
      expect((await env.settings.getPreferences()).lockEnabled, isTrue);
    });

    test('النسخ إلى السحابة وتسجيله والاستعادة منها', () async {
      await seed();
      await env.settings.setFlag(SettingKeys.backupEnabled, true);
      await backup.savePassword('p@ss');
      final name = await backup.backupToCloud();
      expect(cloud.files.keys, contains(name));
      expect((await env.settings.getPreferences()).backupLastAt, isNotNull);
      final logs = await backup.watchLogs().first;
      expect(logs.single.status, 'success');

      final list = await backup.listCloudBackups();
      await env.settings.wipeAllData();
      await backup.restoreFromCloud(list.single.id, 'p@ss');
      expect(await env.db.select(env.db.debts).get(), hasLength(1));
    });

    test('موعد النسخ المجدول', () {
      final now = DateTime(2026, 9, 25);
      AppPreferences prefs(Map<String, String> v) => AppPreferences(v);
      expect(BackupService.isDue(prefs({}), now), isFalse);
      expect(BackupService.isDue(prefs({'backup_enabled': '1'}), now), isTrue);
      expect(
        BackupService.isDue(
          prefs({
            'backup_enabled': '1',
            'backup_frequency': 'weekly',
            'backup_last_at': DateTime(2026, 9, 20).toIso8601String(),
          }),
          now,
        ),
        isFalse,
      );
      expect(
        BackupService.isDue(
          prefs({
            'backup_enabled': '1',
            'backup_frequency': 'daily',
            'backup_last_at': DateTime(2026, 9, 24).toIso8601String(),
          }),
          now,
        ),
        isTrue,
      );
    });
  });

  group('الأمان (FR-24)', () {
    test('رمز PIN يُخزَّن كبصمة ويُتحقق منه', () async {
      final store = MemorySecretStore();
      final security = SecurityService(store: store);
      expect(await security.hasPin(), isFalse);
      await security.setPin('1234');
      expect(await security.hasPin(), isTrue);
      expect(await store.read('daftry.pin_hash'), isNot(contains('1234')));
      expect(await security.verifyPin('1234'), isTrue);
      expect(await security.verifyPin('0000'), isFalse);
      await security.clearPin();
      expect(await security.hasPin(), isFalse);
    });
  });
}
