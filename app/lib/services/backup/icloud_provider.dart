// =============================================================================
// مزوّد iCloud (ICloudProvider في مخطط الفئات).
//
// يحفظ النسخ في حاوية iCloud Documents الخاصة بالتطبيق على حساب Apple
// للمستخدم. التنفيذ الأصلي (Swift) موجود في ios/Runner/AppDelegate.swift
// ويتواصل معه هذا الصنف عبر MethodChannel.
//
// ⚙️ إعداد مطلوب مرة واحدة في Xcode: تفعيل قدرة iCloud + iCloud Documents
// وإنشاء حاوية — التفاصيل في docs/CLOUD_BACKUP_SETUP.md.
// =============================================================================

import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/enums.dart';
import 'cloud_provider.dart';

class ICloudProvider implements CloudProvider {
  static const _channel = MethodChannel('daftry/icloud_backup');

  @override
  BackupProvider get kind => BackupProvider.iCloud;

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// iCloud لا يحتاج نافذة إذن: يكفي أن يكون المستخدم مسجلاً في iCloud.
  @override
  Future<bool> authorize() => isAvailable();

  @override
  Future<String> upload(Uint8List bytes, String fileName) async {
    await _requireAvailable();
    await _channel.invokeMethod<void>('upload', {
      'name': fileName,
      'bytes': bytes,
    });
    return fileName;
  }

  @override
  Future<List<CloudBackupFile>> list() async {
    await _requireAvailable();
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('list');
    final files = [
      for (final m in raw ?? const <Map<Object?, Object?>>[])
        CloudBackupFile(
          id: m['name']! as String,
          name: m['name']! as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            (m['modified']! as num).toInt(),
          ),
          sizeBytes: (m['size']! as num).toInt(),
        ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return files;
  }

  @override
  Future<Uint8List> download(String id) async {
    await _requireAvailable();
    final bytes = await _channel.invokeMethod<Uint8List>('download', {
      'name': id,
    });
    if (bytes == null) throw const BusinessException(BusinessError.notFound);
    return bytes;
  }

  @override
  Future<void> delete(String id) =>
      _channel.invokeMethod<void>('delete', {'name': id});

  @override
  Future<void> signOut() async {}

  Future<void> _requireAvailable() async {
    if (!await isAvailable()) {
      throw const BusinessException(BusinessError.cloudNotAuthorized);
    }
  }
}
