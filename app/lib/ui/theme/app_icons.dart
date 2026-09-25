// =============================================================================
// ربط «مفاتيح الأيقونات» المخزنة في قاعدة البيانات بأيقونات فعلية.
// نخزّن مفتاحاً نصياً (مثل 'food') بدل رقم الأيقونة حتى لا تتأثر البيانات
// بتغيير مكتبة الأيقونات مستقبلاً. لإضافة أيقونة: أضف سطراً في [categoryIcons].
// =============================================================================

import 'package:flutter/material.dart';

import '../../domain/enums.dart';

abstract final class AppIcons {
  /// أيقونات الفئات المتاحة للاختيار (خطية بسماكة موحدة).
  static const Map<String, IconData> categoryIcons = {
    'food': Icons.restaurant_rounded,
    'transport': Icons.directions_car_outlined,
    'bills': Icons.bolt_outlined,
    'shopping': Icons.shopping_cart_outlined,
    'health': Icons.favorite_border_rounded,
    'entertainment': Icons.sports_esports_outlined,
    'education': Icons.menu_book_outlined,
    'housing': Icons.home_outlined,
    'salary': Icons.work_outline_rounded,
    'sales': Icons.storefront_outlined,
    'freelance': Icons.laptop_mac_outlined,
    'gift': Icons.card_giftcard_outlined,
    'coffee': Icons.local_cafe_outlined,
    'phone': Icons.phone_iphone_outlined,
    'fuel': Icons.local_gas_station_outlined,
    'travel': Icons.flight_outlined,
    'kids': Icons.child_care_outlined,
    'clothes': Icons.checkroom_outlined,
    'sport': Icons.fitness_center_outlined,
    'charity': Icons.volunteer_activism_outlined,
    'investment': Icons.trending_up_rounded,
    'rent': Icons.key_outlined,
    'pets': Icons.pets_outlined,
    'other': Icons.more_horiz_rounded,
  };

  /// ألوان مقترحة للفئات والحسابات الجديدة.
  static const List<int> palette = [
    0xFFDC2626, 0xFFEA580C, 0xFFD97706, 0xFF65A30D, 0xFF15803D, 0xFF059669,
    0xFF0F766E, 0xFF0891B2, 0xFF2563EB, 0xFF4F46E5, 0xFF7C3AED, 0xFFDB2777,
    0xFF64748B,
  ];

  static IconData category(String key) =>
      categoryIcons[key] ?? Icons.more_horiz_rounded;

  static IconData account(AccountType type) => switch (type) {
    AccountType.cash => Icons.payments_outlined,
    AccountType.bank => Icons.account_balance_outlined,
    AccountType.wallet => Icons.account_balance_wallet_outlined,
    AccountType.savings => Icons.savings_outlined,
  };

  static const expense = Icons.arrow_upward_rounded;
  static const income = Icons.arrow_downward_rounded;
  static const transfer = Icons.swap_horiz_rounded;
  static const debt = Icons.people_outline_rounded;
  static const adjustment = Icons.tune_rounded;
  static const archive = Icons.inventory_2_outlined;
}
