// =============================================================================
// مزوّد Google Drive (GoogleDriveProvider في مخطط الفئات).
//
// يستخدم حساب Google الخاص بالمستخدم، ويحفظ النسخ في مجلد «appDataFolder»:
// مجلد مخفي خاص بالتطبيق لا يراه المستخدم في Drive ولا تصل إليه تطبيقات أخرى،
// ولا يحتاج التطبيق إلا صلاحية drive.appdata (أضيق صلاحية ممكنة).
//
// ⚙️ إعداد مطلوب مرة واحدة (خارج الكود): إنشاء OAuth Client في Google Cloud
// Console وتفعيل Drive API — التفاصيل في docs/CLOUD_BACKUP_SETUP.md.
// =============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../../core/errors/app_exception.dart';
import '../../domain/enums.dart';
import 'cloud_provider.dart';

class GoogleDriveProvider implements CloudProvider {
  GoogleDriveProvider({this.serverClientId});

  /// معرّف Web Client (مطلوب على Android للحصول على الصلاحيات).
  final String? serverClientId;

  static const _scopes = [drive.DriveApi.driveAppdataScope];
  static const _folder = 'appDataFolder';

  final _signIn = GoogleSignIn.instance;
  Future<void>? _init;

  @override
  BackupProvider get kind => BackupProvider.googleDrive;

  Future<void> _ensureInitialized() =>
      _init ??= _signIn.initialize(serverClientId: serverClientId);

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authorize() async {
    try {
      await _ensureInitialized();
      final existing = await _signIn.authorizationClient.authorizationForScopes(
        _scopes,
      );
      if (existing != null) return true;
      await _signIn.authenticate(scopeHint: _scopes);
      await _signIn.authorizationClient.authorizeScopes(_scopes);
      return true;
    } on GoogleSignInException {
      return false;
    }
  }

  /// عميل Drive جاهز بصلاحيات المستخدم (دون إظهار أي نافذة).
  Future<drive.DriveApi> _api() async {
    await _ensureInitialized();
    // محاولة صامتة لاستعادة الجلسة السابقة (للنسخ المجدول).
    await _signIn.attemptLightweightAuthentication();
    final auth = await _signIn.authorizationClient.authorizationForScopes(
      _scopes,
    );
    if (auth == null) {
      throw const BusinessException(BusinessError.cloudNotAuthorized);
    }
    return drive.DriveApi(auth.authClient(scopes: _scopes));
  }

  @override
  Future<String> upload(Uint8List bytes, String fileName) async {
    final api = await _api();
    final file = await api.files.create(
      drive.File()
        ..name = fileName
        ..parents = [_folder],
      uploadMedia: drive.Media(Stream.value(bytes), bytes.length),
    );
    return file.id!;
  }

  @override
  Future<List<CloudBackupFile>> list() async {
    final api = await _api();
    final result = await api.files.list(
      spaces: _folder,
      orderBy: 'createdTime desc',
      $fields: 'files(id,name,size,createdTime)',
      pageSize: 50,
    );
    return [
      for (final f in result.files ?? const <drive.File>[])
        CloudBackupFile(
          id: f.id!,
          name: f.name ?? '',
          createdAt: f.createdTime?.toLocal() ?? DateTime.now(),
          sizeBytes: int.tryParse(f.size ?? '') ?? 0,
        ),
    ];
  }

  @override
  Future<Uint8List> download(String id) async {
    final api = await _api();
    final media = await api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  @override
  Future<void> delete(String id) async => (await _api()).files.delete(id);

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _signIn.signOut();
  }
}
