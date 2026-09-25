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
    this.color,
  );

  final String nameAr;
  final String nameEn;
  final CategoryKind kind;
  final String icon;

  /// اللون بصيغة ARGB.
  final int color;
}

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
  SeedCategory('أخرى', 'Other', CategoryKind.expense, 'other', 0xFF64748B),
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
  SeedCategory('أخرى', 'Other', CategoryKind.income, 'other', 0xFF64748B),
];
