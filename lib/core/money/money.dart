// =============================================================================
// التعامل مع المبالغ المالية.
//
// ✅ قرار تصميمي مهم: كل المبالغ تُخزَّن وتُحسب كأعداد صحيحة (int) بأصغر وحدة
//    للعملة (الهللة للريال، السنت للدولار، الفلس للدينار...).
//    مثال: 245.50 ر.س تُخزَّن 24550.
//
// السبب: الأعداد العشرية (double) تسبب أخطاء تقريب في الحسابات المالية
// (مثل 0.1 + 0.2 = 0.30000000000000004)، وSQLite لا يملك نوع DECIMAL حقيقياً.
// الأعداد الصحيحة دقيقة 100% وأسرع في الجمع والمقارنة داخل قاعدة البيانات.
// =============================================================================

import 'package:intl/intl.dart';

/// أدوات التحويل بين النص الذي يكتبه المستخدم والقيمة المخزنة.
class MoneyParser {
  const MoneyParser(this.decimals);

  /// عدد الخانات العشرية للعملة.
  final int decimals;

  /// معامل التحويل: 10^decimals (مثلاً 100 للريال).
  int get factor {
    var f = 1;
    for (var i = 0; i < decimals; i++) {
      f *= 10;
    }
    return f;
  }

  /// يحوّل نصاً مثل "245.5" أو "٢٤٥٫٥" إلى أصغر وحدة (24550).
  /// يعيد null إن كان النص غير صالح.
  int? parse(String input) {
    var text = normalizeDigits(input).trim().replaceAll(',', '');
    if (text.isEmpty) return null;
    final negative = text.startsWith('-');
    if (negative) text = text.substring(1);
    final parts = text.split('.');
    if (parts.length > 2) return null;
    final whole = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
    if (whole == null) return null;
    var fraction = 0;
    if (parts.length == 2 && decimals > 0) {
      // نأخذ عدد الخانات المسموح فقط ونكمل بالأصفار: "5" → "50".
      var frac = parts[1];
      if (frac.length > decimals) frac = frac.substring(0, decimals);
      frac = frac.padRight(decimals, '0');
      final parsed = int.tryParse(frac);
      if (parsed == null) return null;
      fraction = parsed;
    }
    final value = whole * factor + fraction;
    return negative ? -value : value;
  }

  /// يحوّل القيمة المخزنة إلى نص قابل للتعديل بدون فواصل الآلاف: 24550 → "245.50".
  String toEditable(int minor) {
    if (decimals == 0) return minor.toString();
    final abs = minor.abs();
    final whole = abs ~/ factor;
    final frac = (abs % factor).toString().padLeft(decimals, '0');
    return '${minor < 0 ? '-' : ''}$whole.$frac';
  }

  /// تحويل الأرقام العربية/الهندية (٠١٢...) والفاصلة العشرية العربية (٫) إلى
  /// الأرقام اللاتينية حتى يمكن تحليلها.
  static String normalizeDigits(String input) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    const easternArabic = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      final i1 = arabicIndic.indexOf(ch);
      final i2 = easternArabic.indexOf(ch);
      if (i1 >= 0) {
        buffer.write(i1);
      } else if (i2 >= 0) {
        buffer.write(i2);
      } else if (ch == '٫') {
        buffer.write('.');
      } else if (ch == '٬') {
        buffer.write(',');
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }
}

/// تنسيق المبالغ للعرض حسب عملة التطبيق وإعدادات المستخدم.
class MoneyFormatter {
  MoneyFormatter({
    required this.decimals,
    required this.symbol,
    this.useArabicDigits = false,
  }) : _format = NumberFormat.decimalPatternDigits(
         locale: 'en',
         decimalDigits: decimals,
       );

  final int decimals;

  /// رمز العملة المعروض بجانب المبلغ (مثل «ر.س»).
  final String symbol;

  /// عرض الأرقام بالشكل الهندي (٠١٢٣) بدل (0123) — خيار في الإعدادات.
  final bool useArabicDigits;

  final NumberFormat _format;

  late final MoneyParser _parser = MoneyParser(decimals);

  /// القيمة العشرية للعرض فقط (لا تُستخدم في الحسابات).
  double toDouble(int minor) => minor / _parser.factor;

  /// تنسيق المبلغ مثل "24,850.00".
  /// - [showSign]: إظهار + للموجب (مفيد لعرض الدخل).
  /// - [withSymbol]: إضافة رمز العملة.
  /// - [compact]: حذف الخانات العشرية إذا كانت أصفاراً (مثل 12,000 بدل 12,000.00).
  String format(
    int minor, {
    bool showSign = false,
    bool withSymbol = false,
    bool compact = false,
  }) {
    final isWhole = minor % _parser.factor == 0;
    final value = toDouble(minor.abs());
    final body = compact && isWhole
        ? NumberFormat.decimalPattern('en').format(value)
        : _format.format(value);
    final sign = minor < 0 ? '-' : (showSign && minor > 0 ? '+' : '');
    var text = '$sign$body';
    if (useArabicDigits) text = toArabicDigits(text);
    return withSymbol ? '$text $symbol' : text;
  }

  /// مبلغ لاستخدامه داخل جملة: الرقم معزول باتجاه LTR حتى لا تنقلب إشارة
  /// السالب، والرمز يتبع اتجاه الجملة (بعد الرقم في القراءة العربية).
  String inline(int minor, {bool withSymbol = true, bool showSign = false}) {
    final number = '\u2066${format(minor, showSign: showSign)}\u2069';
    return withSymbol ? '$number $symbol' : number;
  }

  /// تحويل الأرقام اللاتينية إلى الأرقام الهندية المستخدمة في المشرق.
  static String toArabicDigits(String input) {
    const digits = '٠١٢٣٤٥٦٧٨٩';
    return input.split('').map((ch) {
      final code = ch.codeUnitAt(0);
      if (code >= 48 && code <= 57) return digits[code - 48];
      if (ch == '.') return '٫';
      if (ch == ',') return '٬';
      return ch;
    }).join();
  }
}
