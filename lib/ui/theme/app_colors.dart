// =============================================================================
// لوحة الألوان (جدول 4-1 في الوثيقة) كـ ThemeExtension.
//
// الألوان «الدلالية» ثابتة المعنى في كل التطبيق:
//   الأخضر = دخل / لي / آمن     الأحمر = مصروف / عليّ / حذف / تجاوز
//   الأزرق = تحويل / تعديل / سحابة    الكهرماني = تحذير / استحقاق / حركة دين
//   البنفسجي = أرشفة
// الاستخدام في أي Widget:  context.colors.income
//
// الوضع الداكن يتبع معايير Material 3 الموحّدة:
//   - أسطح رمادية داكنة محايدة بلمسة خفيفة من لون الهوية (ليست سوداء تماماً)،
//     وكل مستوى أعلى أفتح قليلاً (الخلفية ← البطاقة ← العناصر الثانوية).
//   - ألوان الدلالة بدرجات فاتحة هادئة (Tone 75–80) بدل الألوان المشبعة التي
//     «تهتز» على الخلفية الداكنة وتتعب العين.
//   - النص الأساسي ~87% والثانوي ~65% من السطوع، بتباين WCAG AA على الأقل.
//   - الأزرار الممتلئة بلون فاتح ونص داكن من نفس اللون ([onColor]).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.brand,
    required this.income,
    required this.expense,
    required this.warning,
    required this.transfer,
    required this.archive,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onPrimary,
    required this.isDark,
  });

  /// اللون الأساسي للنصوص والأيقونات والعناصر النشطة.
  final Color primary;

  /// اللون الأساسي للأسطح الممتلئة التي يُكتب عليها بالأبيض (الترويسة، زر
  /// الإضافة...). يبقى داكناً في الوضعين ليحقق تباين WCAG AA مع النص الأبيض.
  final Color brand;
  final Color income;
  final Color expense;
  final Color warning;
  final Color transfer;
  final Color archive;
  final Color background;
  final Color surface;

  /// خلفية العناصر الثانوية (الحقول، المفتاح المقسّم).
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  /// النص والأيقونات فوق [primary] الممتلئ (الأزرار والشرائح المختارة).
  final Color onPrimary;

  final bool isDark;

  /// الوضع الفاتح — جدول الألوان في الوثيقة (النص الثانوي أغمق درجة ليحقق AA).
  static const light = AppColors(
    primary: Color(0xFF0F766E),
    brand: Color(0xFF0F766E),
    income: Color(0xFF15803D),
    expense: Color(0xFFDC2626),
    warning: Color(0xFFD97706),
    transfer: Color(0xFF2563EB),
    archive: Color(0xFF6D28D9),
    background: Color(0xFFF3F6F5),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE9EEED),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    // أغمق قليلاً من #64748B ليحقق AA على الخلفية.
    textSecondary: Color(0xFF607086),
    onPrimary: Color(0xFFFFFFFF),
    isDark: false,
  );

  /// الوضع الداكن — مشتق من لون الهوية بنظام Material 3 (HCT):
  /// الأسطح من درجات Surface / SurfaceContainer، والألوان بدرجة 75–80.
  static const dark = AppColors(
    primary: Color(0xFF81D5CB), // Primary (Tone 80)
    brand: Color(0xFF00504A), // PrimaryContainer (Tone 30) — نص أبيض فوقه
    income: Color(0xFF6CCD80), // أخضر Tone 75
    expense: Color(0xFFFF9F95), // أحمر Tone 75
    warning: Color(0xFFFFB77D), // كهرماني Tone 80
    transfer: Color(0xFFA0B6FF), // أزرق Tone 75
    archive: Color(0xFFC7AAFF), // بنفسجي Tone 75
    background: Color(0xFF0E1514), // Surface
    surface: Color(0xFF1A2120), // SurfaceContainer
    surfaceMuted: Color(0xFF252B2A), // SurfaceContainerHigh
    border: Color(0xFF2E3634),
    textPrimary: Color(0xFFDDE4E2), // OnSurface
    textSecondary: Color(0xFFA9B4B1),
    onPrimary: Color(0xFF003733), // OnPrimary (Tone 20)
    isDark: true,
  );

  /// خلفية فاتحة شفافة للون (مربعات الأيقونات والشارات).
  Color tint(Color c) => c.withValues(alpha: isDark ? 0.16 : 0.12);

  /// يكيّف لوناً حراً (ألوان الفئات والرسوم البيانية) مع الوضع الحالي: في
  /// الداكن يصبح بدرجة Tone 75 وتشبّع معتدل حتى لا «يهتز» على الخلفية الداكنة،
  /// وفي الفاتح يبقى كما هو.
  Color accent(Color c) {
    if (!isDark) return c;
    final hct = Hct.fromInt(c.toARGB32());
    return Color(Hct.from(hct.hue, hct.chroma.clamp(0, 48), 75).toInt());
  }

  /// لون النص والأيقونات فوق خلفية ممتلئة بلون [bg]: داكن من نفس اللون فوق
  /// الألوان الفاتحة (مثل أزرار الوضع الداكن)، وأبيض فوق الألوان الداكنة.
  Color onColor(Color bg) {
    if (bg.computeLuminance() < 0.3) return Colors.white;
    final hct = Hct.fromInt(bg.toARGB32());
    return Color(Hct.from(hct.hue, hct.chroma.clamp(0, 40), 15).toInt());
  }

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      primary: l(primary, other.primary),
      brand: l(brand, other.brand),
      income: l(income, other.income),
      expense: l(expense, other.expense),
      warning: l(warning, other.warning),
      transfer: l(transfer, other.transfer),
      archive: l(archive, other.archive),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      onPrimary: l(onPrimary, other.onPrimary),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
