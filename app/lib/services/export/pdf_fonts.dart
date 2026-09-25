// =============================================================================
// تحميل الخط العربي المضمَّن لملفات PDF.
//
// نستخدم خط IBM Plex Sans Arabic (رخصة OFL) مضمَّناً في التطبيق بدلاً من
// تحميله من الإنترنت — حفاظاً على مبدأ «صفر طلبات شبكة» وعمل التطبيق دون اتصال.
// =============================================================================

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfFonts {
  const PdfFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;

  static PdfFonts? _cache;

  /// يحمّل الخطوط مرة واحدة ويحتفظ بها في الذاكرة.
  static Future<PdfFonts> load() async {
    return _cache ??= PdfFonts(
      regular: pw.Font.ttf(
        await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
      ),
      bold: pw.Font.ttf(
        await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'),
      ),
    );
  }

  pw.ThemeData theme() => pw.ThemeData.withFont(base: regular, bold: bold);
}
