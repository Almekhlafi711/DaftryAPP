// فحص تباين الألوان وفق WCAG 2.1 (المعيار الموحّد لسهولة القراءة):
// - النص العادي ≥ 4.5:1 (المستوى AA)، والنص الكبير والأيقونات ≥ 3:1.
// - في الوضع الداكن: كل ألوان الدلالة (المبالغ الخضراء والحمراء، التحذير،
//   التحويل، الأرشفة) مقروءة فوق الخلفية والبطاقات، والنص فوق الأزرار
//   الممتلئة مقروء، والأسطح متدرجة (الخلفية أغمق من البطاقة).
import 'package:daftry/ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('الوضع الداكن (Material 3 + WCAG AA)', () {
    const c = AppColors.dark;
    final semantic = {
      'primary': c.primary,
      'income': c.income,
      'expense': c.expense,
      'warning': c.warning,
      'transfer': c.transfer,
      'archive': c.archive,
    };

    test('النص الأساسي والثانوي مقروءان على كل الأسطح', () {
      for (final bg in [c.background, c.surface, c.surfaceMuted]) {
        expect(contrast(c.textPrimary, bg), greaterThanOrEqualTo(10));
        expect(contrast(c.textSecondary, bg), greaterThanOrEqualTo(4.5));
      }
    });

    test('ألوان الدلالة مقروءة كنص على الخلفية والبطاقات', () {
      semantic.forEach((name, color) {
        for (final bg in [c.background, c.surface]) {
          expect(
            contrast(color, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$name على ${bg.toARGB32().toRadixString(16)}',
          );
        }
      });
    });

    test('ليست ألواناً مشبعة «تهتز»: درجات فاتحة هادئة', () {
      semantic.forEach((name, color) {
        final hsl = HSLColor.fromColor(color);
        expect(hsl.lightness, greaterThan(0.55), reason: name);
      });
    });

    test('النص فوق الأزرار الممتلئة مقروء', () {
      expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
      semantic.forEach((name, color) {
        expect(
          contrast(c.onColor(color), color),
          greaterThanOrEqualTo(4.5),
          reason: name,
        );
      });
      // أسطح الهوية (الترويسة والزر العائم) بنص أبيض.
      expect(contrast(Colors.white, c.brand), greaterThanOrEqualTo(7));
    });

    test('الأسطح متدرجة: الخلفية أغمق من البطاقة ثم العناصر الثانوية', () {
      final bg = c.background.computeLuminance();
      final card = c.surface.computeLuminance();
      final muted = c.surfaceMuted.computeLuminance();
      expect(bg, lessThan(card));
      expect(card, lessThan(muted));
      // ليست سوداء تماماً (تقليل الإجهاد والتباين المفرط).
      expect(c.background, isNot(const Color(0xFF000000)));
    });

    test('تكييف ألوان الفئات: الألوان المشبعة تصبح مقروءة وهادئة', () {
      for (final raw in const [
        Color(0xFFDC2626),
        Color(0xFF2563EB),
        Color(0xFF7C3AED),
        Color(0xFFD97706),
        Color(0xFF0891B2),
        Color(0xFFDB2777),
      ]) {
        final adapted = c.accent(raw);
        expect(contrast(adapted, c.surface), greaterThanOrEqualTo(4.5));
      }
    });
  });

  group('الوضع الفاتح', () {
    const c = AppColors.light;

    test('النص مقروء، والأزرار الممتلئة بنص أبيض', () {
      for (final bg in [c.background, c.surface]) {
        expect(contrast(c.textPrimary, bg), greaterThanOrEqualTo(10));
        expect(contrast(c.textSecondary, bg), greaterThanOrEqualTo(4.5));
      }
      expect(c.onColor(c.primary), Colors.white);
      expect(contrast(Colors.white, c.primary), greaterThanOrEqualTo(4.5));
      expect(contrast(Colors.white, c.expense), greaterThanOrEqualTo(4.5));
    });

    test('ألوان الفئات لا تتغير في الوضع الفاتح', () {
      const raw = Color(0xFFDC2626);
      expect(c.accent(raw), raw);
    });
  });
}
