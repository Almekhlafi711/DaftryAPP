// =============================================================================
// مشاركة الملفات وطباعتها (واتساب، البريد، الطباعة عبر AirPrint/Android).
//
// تُكتب الملفات في المجلد المؤقت فقط ولا تُحفظ داخل التطبيق إلا إذا اختار
// المستخدم ذلك (الشروط اللاحقة لـ UC-15).
// =============================================================================

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class FileShareService {
  const FileShareService();

  /// يكتب البيانات في ملف مؤقت ويعيد مساره.
  Future<File> writeTemp(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, _safe(fileName)));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// فتح ورقة المشاركة في النظام (يختار المستخدم واتساب أو غيره).
  Future<void> share(
    Uint8List bytes,
    String fileName, {
    required String mimeType,
    String? text,
  }) async {
    final file = await writeTemp(bytes, fileName);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        text: text,
        subject: text,
      ),
    );
  }

  /// طباعة PDF عبر نافذة الطباعة في النظام.
  Future<void> printPdf(Uint8List pdf, String name) =>
      Printing.layoutPdf(onLayout: (_) async => pdf, name: name);

  /// إزالة الأحرف غير المسموحة في أسماء الملفات.
  static String _safe(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}
