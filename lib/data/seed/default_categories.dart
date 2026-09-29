// =============================================================================
// الفئات الافتراضية التي تُنشأ في الإعداد الأول.
// تُنشأ بلغة الواجهة وقت الإعداد، ويمكن للمستخدم تعديلها أو إضافة غيرها.
// مفاتيح الأيقونات تُترجم إلى أيقونات فعلية في ui/theme/app_icons.dart.
// =============================================================================

import '../../domain/enums.dart';

class SeedCategory {
  const SeedCategory(
    this.nameAr,
    this.nameEn,
    this.kind,
    this.icon,
    this.color, {
    this.systemKey,
  });

  final String nameAr;
  final String nameEn;
  final CategoryKind kind;
  final String icon;

  /// اللون بصيغة ARGB.
  final int color;

  /// مفتاح ثابت مختلف عن الأيقونة (إن لزم).
  final String? systemKey;

  /// المفتاح الثابت للفئة (system_key) — الأيقونة إن لم يُحدَّد غيرها.
  String get key => systemKey ?? icon;
}

/// مفاتيح فئات يحتاجها التطبيق نفسه (تُنشأ عند الحاجة إن حُذفت).
abstract final class SystemCategoryKeys {
  /// «مبيعات»: الفئة المقترحة للبيع بالآجل.
  static const sales = 'sales';

  /// «تسوق»: الفئة المقترحة للشراء بالآجل.
  static const shopping = 'shopping';

  /// «مسامحة ديون»: مصروف عند مسامحة دين لي.
  static const debtWriteOff = 'debt_write_off';

  /// «إعفاء دين»: دخل عند إعفائي من دين عليّ.
  static const debtForgiven = 'debt_forgiven';
}

/// فئتا المسامحة والإعفاء (تُنشآن عند أول استخدام بلغة الواجهة).
const kWriteOffCategory = SeedCategory(
  'مسامحة ديون',
  'Debt write-off',
  CategoryKind.expense,
  'forgive',
  0xFFBE123C,
  systemKey: SystemCategoryKeys.debtWriteOff,
);
const kForgivenCategory = SeedCategory(
  'إعفاء دين',
  'Debt relief',
  CategoryKind.income,
  'relief',
  0xFF0D9488,
  systemKey: SystemCategoryKeys.debtForgiven,
);

const List<SeedCategory> kDefaultCategories = [
  // --- فئات المصروف ---
  SeedCategory('طعام', 'Food', CategoryKind.expense, 'food', 0xFFDC2626),
  SeedCategory(
    'مواصلات',
    'Transport',
    CategoryKind.expense,
    'transport',
    0xFF2563EB,
  ),
  SeedCategory('فواتير', 'Bills', CategoryKind.expense, 'bills', 0xFFD97706),
  SeedCategory(
    'تسوق',
    'Shopping',
    CategoryKind.expense,
    'shopping',
    0xFFDB2777,
  ),
  SeedCategory('صحة', 'Health', CategoryKind.expense, 'health', 0xFF059669),
  SeedCategory(
    'ترفيه',
    'Entertainment',
    CategoryKind.expense,
    'entertainment',
    0xFF7C3AED,
  ),
  SeedCategory(
    'تعليم',
    'Education',
    CategoryKind.expense,
    'education',
    0xFF0891B2,
  ),
  SeedCategory('سكن', 'Housing', CategoryKind.expense, 'housing', 0xFF65A30D),
  SeedCategory(
    'أخرى',
    'Other',
    CategoryKind.expense,
    'other',
    0xFF64748B,
    systemKey: 'other_expense',
  ),
  // --- فئات الدخل ---
  SeedCategory('راتب', 'Salary', CategoryKind.income, 'salary', 0xFF15803D),
  SeedCategory('مبيعات', 'Sales', CategoryKind.income, 'sales', 0xFF0F766E),
  SeedCategory(
    'عمل حر',
    'Freelance',
    CategoryKind.income,
    'freelance',
    0xFF2563EB,
  ),
  SeedCategory('هدية', 'Gift', CategoryKind.income, 'gift', 0xFFDB2777),
  SeedCategory(
    'أخرى',
    'Other',
    CategoryKind.income,
    'other',
    0xFF64748B,
    systemKey: 'other_income',
  ),
];
