// اختبارات تحويل وتنسيق المبالغ.
import 'package:daftry/core/money/money.dart';
import 'package:daftry/core/utils/date_range.dart';
import 'package:daftry/ui/widgets/inputs.dart';
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

  group('AmountInputFormatter (حقول المبالغ النصية)', () {
    const sar = AmountInputFormatter(2);
    test('فاصلة واحدة، وخانات لا تتجاوز خانات العملة', () {
      expect(sar.clean('245.555'), '245.55');
      expect(sar.clean('1.2.3'), '1.23');
      expect(sar.clean('.5'), '0.5');
      expect(sar.clean('abc12x'), '12');
      expect(sar.clean('-5'), '5'); // السالب غير مسموح في المبالغ
    });

    test('«,» و«٫» فاصلة عشرية والأرقام العربية تُحوَّل', () {
      expect(sar.clean('12,5'), '12.5');
      expect(sar.clean('١٢٫٧٥'), '12.75');
      // ما يُعرض هو ما يُحفظ بالضبط.
      expect(const MoneyParser(2).parse(sar.clean('12,5')), 1250);
    });

    test('العملات بدون كسور وبثلاث خانات', () {
      expect(const AmountInputFormatter(0).clean('1500.75'), '150075');
      expect(const AmountInputFormatter(3).clean('1.23456'), '1.234');
      expect(const MoneyParser(3).parse('1.234'), 1234);
    });

    test('الرصيد الفعلي والافتتاحي يقبلان السالب في البداية فقط', () {
      const f = AmountInputFormatter(2, allowNegative: true);
      expect(f.clean('-12.5'), '-12.5');
      expect(f.clean('1-2'), '12');
    });

    test('حد 12 خانة صحيحة (لا تجاوز لسعة الأعداد)', () {
      expect(sar.clean('12345678901234.5'), '123456789012.5');
      final big = const MoneyParser(2).parse('999999999999.99')!;
      expect(big, 99999999999999);
      expect(const MoneyParser(2).toEditable(big), '999999999999.99');
    });
  });

  group('دقة الجمع (أعداد صحيحة بأصغر وحدة)', () {
    test('0.1 + 0.2 = 0.30 تماماً، ولا أخطاء تقريب مع التكرار', () {
      const p = MoneyParser(2);
      expect(p.parse('0.1')! + p.parse('0.2')!, p.parse('0.3'));
      var total = 0;
      for (var i = 0; i < 1000; i++) {
        total += p.parse('0.01')!;
      }
      expect(total, p.parse('10'));
      expect(p.toEditable(total), '10.00');
    });
  });
}
