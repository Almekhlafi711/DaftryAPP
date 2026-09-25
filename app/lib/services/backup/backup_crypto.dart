// =============================================================================
// تشفير ملف النسخة الاحتياطية (Encryptor في مخطط الفئات).
//
// الخوارزمية: AES-256-GCM (تشفير + تحقق من سلامة الملف في خطوة واحدة).
// المفتاح: مشتق من كلمة مرور المستخدم عبر PBKDF2-HMAC-SHA256 مع ملح عشوائي،
// لذلك يمكن استعادة النسخة على جهاز جديد بمعرفة كلمة المرور فقط، ولا يستطيع
// مزوّد السحابة (Google / Apple) قراءة البيانات.
//
// تنسيق الملف (.dftry):
//   [8 بايت: DAFTRY01] [16: ملح] [12: nonce] [16: MAC] [البيانات المشفرة]
// والبيانات قبل التشفير هي ملف SQLite مضغوط بـ GZip.
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/errors/app_exception.dart';

class BackupCrypto {
  const BackupCrypto({this.iterations = 120000});

  /// عدد دورات PBKDF2: كلما زاد صعُب تخمين كلمة المرور (مع بطء بسيط).
  final int iterations;

  static final _magic = ascii.encode('DAFTRY01');
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;
  static const _headerLength = 8 + _saltLength + _nonceLength + _macLength;

  /// يضغط ثم يشفّر.
  Future<Uint8List> encrypt(List<int> plain, String password) async {
    final salt = _randomBytes(_saltLength);
    final algorithm = AesGcm.with256bits();
    final key = await _deriveKey(password, salt);
    final nonce = algorithm.newNonce();
    final box = await algorithm.encrypt(
      gzip.encode(plain),
      secretKey: key,
      nonce: nonce,
    );
    return Uint8List.fromList([
      ..._magic,
      ...salt,
      ...box.nonce,
      ...box.mac.bytes,
      ...box.cipherText,
    ]);
  }

  /// يفك التشفير ثم يفك الضغط. يرمي [BusinessException] إن كانت كلمة المرور
  /// خاطئة أو الملف تالفاً أو ليس نسخة «دفتري».
  Future<Uint8List> decrypt(List<int> data, String password) async {
    if (data.length <= _headerLength || !_startsWithMagic(data)) {
      throw const BusinessException(BusinessError.backupInvalidFile);
    }
    var offset = _magic.length;
    List<int> take(int n) {
      final part = data.sublist(offset, offset + n);
      offset += n;
      return part;
    }

    final salt = take(_saltLength);
    final nonce = take(_nonceLength);
    final mac = take(_macLength);
    final cipherText = data.sublist(offset);
    try {
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: await _deriveKey(password, salt),
      );
      return Uint8List.fromList(gzip.decode(clear));
    } on SecretBoxAuthenticationError {
      throw const BusinessException(BusinessError.backupDecryptionFailed);
    } on FormatException {
      throw const BusinessException(BusinessError.backupInvalidFile);
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) => Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: password, nonce: salt);

  static bool _startsWithMagic(List<int> data) {
    for (var i = 0; i < _magic.length; i++) {
      if (data[i] != _magic[i]) return false;
    }
    return true;
  }

  static List<int> _randomBytes(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }
}
