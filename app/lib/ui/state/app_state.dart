// =============================================================================
// حالة التطبيق العامة التي تحتاجها كل الشاشات: الإعدادات، اللغة، المظهر،
// عملة التطبيق، ومنسّق المبالغ.
// كلها «تفاعلية»: تغيير اللغة من الإعدادات يعيد بناء الواجهة فوراً.
// =============================================================================

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/currencies.dart';
import '../../core/money/money.dart';
import '../../data/database/app_database.dart';
import '../../services/providers.dart';
import '../../services/settings_service.dart';

/// كل الإعدادات (تدفق من جدول settings).
final preferencesProvider = StreamProvider<AppPreferences>(
  (ref) => ref.watch(settingsServiceProvider).watchPreferences(),
);

/// عملة التطبيق المقفلة (null قبل الإعداد الأول).
final baseCurrencyProvider = StreamProvider<Currency?>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.currencies)
        ..orderBy([(c) => OrderingTerm.asc(c.id)])
        ..limit(1))
      .watchSingleOrNull();
});

/// لغة التطبيق: اختيار المستخدم، أو لغة الجهاز (العربية افتراضياً إن لم تكن
/// لغة الجهاز مدعومة).
final localeProvider = Provider<Locale>((ref) {
  final pref = ref.watch(preferencesProvider).value?.locale ?? 'system';
  if (pref == 'ar' || pref == 'en') return Locale(pref);
  final device = WidgetsBinding.instance.platformDispatcher.locale;
  return device.languageCode == 'en' ? const Locale('en') : const Locale('ar');
});

final isArabicProvider = Provider<bool>(
  (ref) => ref.watch(localeProvider).languageCode == 'ar',
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  return switch (ref.watch(preferencesProvider).value?.themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

/// معلومات العملة (الرمز بلغة الواجهة الحالية).
final currencyInfoProvider = Provider<CurrencyInfo?>((ref) {
  final currency = ref.watch(baseCurrencyProvider).value;
  return currency == null ? null : currencyByCode(currency.code);
});

/// منسّق المبالغ حسب العملة واللغة وخيار الأرقام الهندية.
final moneyFormatterProvider = Provider<MoneyFormatter>((ref) {
  final currency = ref.watch(baseCurrencyProvider).value;
  final info = ref.watch(currencyInfoProvider);
  final arabic = ref.watch(isArabicProvider);
  final digits = ref.watch(preferencesProvider).value?.arabicDigits ?? false;
  return MoneyFormatter(
    decimals: currency?.decimals ?? 2,
    symbol: info?.symbol(arabic) ?? currency?.symbol ?? '',
    useArabicDigits: digits,
  );
});

/// محلّل المبالغ المدخلة حسب خانات العملة.
final moneyParserProvider = Provider<MoneyParser>(
  (ref) => MoneyParser(ref.watch(baseCurrencyProvider).value?.decimals ?? 2),
);

/// إخفاء الأرصدة في الرئيسية (زر العين).
final hideBalancesProvider = Provider<bool>(
  (ref) => ref.watch(preferencesProvider).value?.hideBalances ?? false,
);

/// الحسابات النشطة (مستخدمة في عدة شاشات: الإضافة، الدين، الفلترة...).
final activeAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountServiceProvider).watchActive(),
);

/// كل الحسابات (بما فيها المؤرشفة) — للفلترة والعرض التاريخي.
final allAccountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountServiceProvider).watchAll(),
);
