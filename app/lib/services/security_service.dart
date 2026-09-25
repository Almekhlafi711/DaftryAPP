// =============================================================================
// خدمة الأمان (FR-24): قفل التطبيق برمز PIN و/أو البصمة والوجه.
//
// - رمز PIN لا يُخزَّن أبداً كنص صريح؛ نخزن «بصمته» (PBKDF2-SHA256 مع ملح
//   عشوائي) داخل التخزين الآمن للنظام (Keychain في iOS و Keystore في Android).
// - البصمة/الوجه عبر local_auth (BiometricPrompt / Face ID / Touch ID).
// - مهلة القفل: دقيقة واحدة بعد الخروج من التطبيق (المتطلبات غير الوظيفية).
// =============================================================================

import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// واجهة تخزين الأسرار — تسمح باستبدال التخزين الآمن بتخزين في الذاكرة
/// أثناء الاختبارات.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// التنفيذ الحقيقي فوق Keychain / Keystore.
class SecureSecretStore implements SecretStore {
  const SecureSecretStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// تخزين في الذاكرة (للاختبارات).
class MemorySecretStore implements SecretStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

class SecurityService {
  SecurityService({SecretStore? store, LocalAuthentication? localAuth})
    : _store = store ?? const SecureSecretStore(),
      _localAuth = localAuth ?? LocalAuthentication();

  final SecretStore _store;
  final LocalAuthentication _localAuth;

  static const _pinKey = 'daftry.pin_hash';

  /// كلمة مرور تشفير النسخ الاحتياطي (للنسخ المجدول دون سؤال المستخدم).
  static const backupPasswordKey = 'daftry.backup_password';

  /// المدة التي يبقى فيها التطبيق مفتوحاً بعد الخروج منه قبل طلب القفل.
  static const lockTimeout = Duration(minutes: 1);

  static const _iterations = 20000;

  SecretStore get store => _store;

  Future<bool> hasPin() async => (await _store.read(_pinKey)) != null;

  /// حفظ رمز PIN جديد (يُخزَّن كـ salt:hash بصيغة Base64).
  Future<void> setPin(String pin) async {
    final salt = _randomBytes(16);
    final hash = await _hash(pin, salt);
    await _store.write(_pinKey, '${base64Encode(salt)}:${base64Encode(hash)}');
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _store.read(_pinKey);
    if (stored == null) return false;
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final expected = base64Decode(parts[1]);
    final actual = await _hash(pin, base64Decode(parts[0]));
    // مقارنة بزمن ثابت لتفادي هجمات التوقيت.
    if (expected.length != actual.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= expected[i] ^ actual[i];
    }
    return diff == 0;
  }

  Future<void> clearPin() => _store.delete(_pinKey);

  /// هل يدعم الجهاز البصمة أو الوجه؟
  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } on Exception {
      return false;
    }
  }

  /// طلب التحقق بالبصمة/الوجه. يعيد false عند الإلغاء أو الخطأ.
  Future<bool> authenticateBiometric(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on Exception {
      return false;
    }
  }

  Future<List<int>> _hash(String pin, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    );
    final key = await pbkdf2.deriveKeyFromPassword(password: pin, nonce: salt);
    return key.extractBytes();
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
