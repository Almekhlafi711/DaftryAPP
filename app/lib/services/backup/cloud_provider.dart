// =============================================================================
// واجهة مزوّد التخزين السحابي (CloudProvider في مخطط الفئات).
//
// BackupService لا يعرف أي مزوّد يستخدم؛ يكفي أن يحقق المزوّد هذه الواجهة.
// لإضافة مزوّد جديد (Dropbox مثلاً): أنشئ صنفاً يحقق CloudProvider
// وأضفه في services/providers.dart — دون تعديل منطق النسخ نفسه.
// =============================================================================

import 'dart:typed_data';

import '../../domain/enums.dart';

/// ملف نسخة موجود في السحابة.
class CloudBackupFile {
  const CloudBackupFile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
  });

  /// معرّف الملف لدى المزوّد (يُستخدم في التنزيل).
  final String id;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;
}

abstract interface class CloudProvider {
  BackupProvider get kind;

  /// هل المزوّد متاح على هذا الجهاز؟ (iCloud غير متاح على Android مثلاً).
  Future<bool> isAvailable();

  /// طلب الإذن من حساب المستخدم الشخصي (قد يظهر نافذة تسجيل Google).
  Future<bool> authorize();

  /// رفع ملف ويعيد معرّفه.
  Future<String> upload(Uint8List bytes, String fileName);

  /// النسخ الموجودة من الأحدث للأقدم.
  Future<List<CloudBackupFile>> list();

  Future<Uint8List> download(String id);

  Future<void> delete(String id);

  Future<void> signOut();
}
