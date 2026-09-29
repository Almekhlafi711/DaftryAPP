// =============================================================================
// نصوص ملفات PDF.
//
// مكتبة pdf لا تطبّق جداول تموضع الحروف في الخط (GPOS)، فذيل «ر» و«ز» في آخر
// الكلمة يغطي المسافة التالية فتبدو الكلمتان ملتصقتين («صادرمن»،
// «سبتمبر2026»). نضاعف المسافة بعد هذين الحرفين فقط فتظهر بعرضها الطبيعي.
// (واجهة التطبيق نفسها لا تحتاج هذا؛ محرك النص فيها يطبّق التموضع.)
// =============================================================================

import 'package:pdf/widgets.dart' as pw;

final _tailBeforeSpace = RegExp('([رزژ]) ');

/// النص بعد إصلاح المسافة بعد «ر» و«ز».
String pdfText(String text) =>
    text.replaceAllMapped(_tailBeforeSpace, (m) => '${m[1]}  ');

/// بديل pw.Text يطبّق [pdfText] تلقائياً.
pw.Text pdfTextWidget(
  String text, {
  pw.TextStyle? style,
  pw.TextDirection? textDirection,
  pw.TextAlign? textAlign,
  int? maxLines,
}) => pw.Text(
  pdfText(text),
  style: style,
  textDirection: textDirection,
  textAlign: textAlign,
  maxLines: maxLines,
);
