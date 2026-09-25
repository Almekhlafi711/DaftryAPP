// =============================================================================
// لوحة الألوان (جدول 4-1 في الوثيقة) كـ ThemeExtension.
//
// الألوان «الدلالية» ثابتة المعنى في كل التطبيق:
//   الأخضر = دخل / لي / آمن     الأحمر = مصروف / عليّ / حذف / تجاوز
//   الأزرق = تحويل / تعديل / سحابة    الكهرماني = تحذير / استحقاق / حركة دين
//   البنفسجي = أرشفة
// الاستخدام في أي Widget:  context.colors.income
// =============================================================================

import 'package:flutter/material.dart';

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

  /// الوضع الفاتح — مطابق تماماً لجدول الألوان في الوثيقة.
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
    textSecondary: Color(0xFF64748B),
  );

  /// الوضع الداكن — نفس الهوية بدرجات أفتح قليلاً لتباين WCAG AA.
  static const dark = AppColors(
    primary: Color(0xFF2DD4BF),
    brand: Color(0xFF115E59),
    income: Color(0xFF4ADE80),
    expense: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    transfer: Color(0xFF60A5FA),
    archive: Color(0xFFA78BFA),
    background: Color(0xFF0B1413),
    surface: Color(0xFF14201F),
    surfaceMuted: Color(0xFF1E2D2B),
    border: Color(0xFF263634),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
  );

  /// خلفية فاتحة شفافة للون (مربعات الأيقونات والشارات).
  Color tint(Color c) => c.withValues(alpha: 0.12);

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
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
