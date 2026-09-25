// اختبارات تحويل وتنسيق المبالغ.
import 'package:daftry/core/money/money.dart';
import 'package:daftry/core/utils/date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyParser', () {
    const sar = MoneyParser(2);
    test('يحوّل النص إلى أصغر وحدة', () {
      expect(sar.parse('245'), 24500);
      expect(sar.parse('245.5'), 24550);
      expect(sar.parse('245.555'), 24555);
      expect(sar.parse('1,200.00'), 120000);
      expect(sar.parse('-5'), -500);
      expect(sar.parse(''), isNull);
      expect(sar.parse('abc'), isNull);
    });

    test('يدعم الأرقام العربية الهندية', () {
      expect(sar.parse('٢٤٥٫٥'), 24550);
    });

    test('العملات بدون كسور أو بثلاث خانات', () {
      expect(const MoneyParser(0).parse('1500'), 1500);
      expect(const MoneyParser(3).parse('1.5'), 1500);
    });

    test('toEditable', () {
      expect(sar.toEditable(24550), '245.50');
      expect(sar.toEditable(-5), '-0.05');
      expect(const MoneyParser(0).toEditable(12), '12');
    });
  });

  group('MoneyFormatter', () {
    final f = MoneyFormatter(decimals: 2, symbol: 'ر.س');
    test('فواصل الآلاف والخانات العشرية', () {
      expect(f.format(2485000), '24,850.00');
      expect(f.format(-642000), '-6,420.00');
      expect(f.format(1200000, showSign: true), '+12,000.00');
      expect(f.format(1200000, compact: true), '12,000');
      expect(f.format(24550, withSymbol: true), '245.50 ر.س');
    });

    test('الأرقام الهندية', () {
      final ar = MoneyFormatter(
        decimals: 2,
        symbol: 'ر.س',
        useArabicDigits: true,
      );
      expect(ar.format(123450), '١٬٢٣٤٫٥٠');
    });
  });

  group('DateRange', () {
    test('الشهر نصف مفتوح', () {
      final r = DateRange.month(DateTime(2026, 9, 15));
      expect(r.start, DateTime(2026, 9));
      expect(r.end, DateTime(2026, 10));
      expect(r.contains(DateTime(2026, 9, 30, 23, 59)), isTrue);
      expect(r.contains(DateTime(2026, 10)), isFalse);
    });

    test('الأسبوع يبدأ السبت', () {
      final r = DateRange.week(DateTime(2026, 9, 24)); // خميس
      expect(r.start, DateTime(2026, 9, 19)); // سبت
      expect(r.end, DateTime(2026, 9, 26));
    });

    test('الأيام المتبقية', () {
      final r = DateRange.month(DateTime(2026, 9, 1));
      expect(r.daysLeft(DateTime(2026, 9, 25, 10)), 6);
    });
  });
}
