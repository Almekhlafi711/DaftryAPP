// =============================================================================
// خدمة الإعدادات والإعداد الأول (Onboarding).
//
// الإعدادات تُخزَّن في جدول settings بصيغة مفتاح/قيمة، وتُقرأ كتدفق تفاعلي
// (Stream) فتتغير الواجهة فوراً عند تغيير اللغة أو المظهر مثلاً.
// =============================================================================

import 'package:drift/drift.dart';

import '../core/constants/currencies.dart';
import '../core/errors/app_exception.dart';
import '../data/database/app_database.dart';
import '../data/seed/default_categories.dart';
import '../domain/enums.dart';

/// مفاتيح الإعدادات المخزنة. أضف المفاتيح الجديدة هنا فقط.
abstract final class SettingKeys {
  /// '1' بعد إكمال الإعداد الأول وقفل العملة.
  static const onboarded = 'onboarded';
  static const defaultAccountId = 'default_account_id';

  /// ar | en | system
  static const locale = 'locale';

  /// light | dark | system
  static const themeMode = 'theme_mode';

  /// '1' لعرض الأرقام الهندية (٠١٢٣).
  static const arabicDigits = 'arabic_digits';

  /// '1' لإخفاء الأرصدة في الرئيسية (زر العين).
  static const hideBalances = 'hide_balances';
  static const lockEnabled = 'lock_enabled';
  static const biometricEnabled = 'biometric_enabled';

  // --- النسخ الاحتياطي السحابي (اختياري) ---
  static const backupEnabled = 'backup_enabled';
  static const backupProvider = 'backup_provider';

  /// daily | weekly | monthly
  static const backupFrequency = 'backup_frequency';
  static const backupWifiOnly = 'backup_wifi_only';

  /// تاريخ آخر نسخة ناجحة بصيغة ISO-8601.
  static const backupLastAt = 'backup_last_at';
}

/// إعدادات العرض والتفضيلات بشكل منظم (تُبنى من جدول الإعدادات).
class AppPreferences {
  const AppPreferences(this._values);

  final Map<String, String> _values;

  String? operator [](String key) => _values[key];

  bool _flag(String key) => _values[key] == '1';

  bool get onboarded => _flag(SettingKeys.onboarded);
  String get locale => _values[SettingKeys.locale] ?? 'system';
  String get themeMode => _values[SettingKeys.themeMode] ?? 'system';
  bool get arabicDigits => _flag(SettingKeys.arabicDigits);
  bool get hideBalances => _flag(SettingKeys.hideBalances);
  bool get lockEnabled => _flag(SettingKeys.lockEnabled);
  bool get biometricEnabled => _flag(SettingKeys.biometricEnabled);
  int? get defaultAccountId =>
      int.tryParse(_values[SettingKeys.defaultAccountId] ?? '');

  bool get backupEnabled => _flag(SettingKeys.backupEnabled);
  BackupProvider get backupProvider => BackupProvider.values.firstWhere(
    (p) => p.name == _values[SettingKeys.backupProvider],
    orElse: () => BackupProvider.googleDrive,
  );
  String get backupFrequency =>
      _values[SettingKeys.backupFrequency] ?? 'weekly';
  bool get backupWifiOnly => _values[SettingKeys.backupWifiOnly] != '0';
  DateTime? get backupLastAt =>
      DateTime.tryParse(_values[SettingKeys.backupLastAt] ?? '');
}

class SettingsService {
  SettingsService(this.db);

  final AppDatabase db;

  /// كل الإعدادات كتدفق تفاعلي.
  Stream<AppPreferences> watchPreferences() => db
      .select(db.settings)
      .watch()
      .map((rows) => AppPreferences({for (final r in rows) r.key: r.value}));

  Future<AppPreferences> getPreferences() async {
    final rows = await db.select(db.settings).get();
    return AppPreferences({for (final r in rows) r.key: r.value});
  }

  Future<String?> get(String key) async {
    final row = await (db.select(
      db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) => db
      .into(db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<void> setFlag(String key, bool value) => set(key, value ? '1' : '0');

  Future<bool> isOnboarded() async => (await get(SettingKeys.onboarded)) == '1';

  // ---------------------------------------------------------------------------
  // الإعداد الأول (UC-00)
  // ---------------------------------------------------------------------------

  /// يُكمل الإعداد الأول: يحفظ العملة ويقفلها، وينشئ الحساب الافتراضي
  /// «النقدية» والفئات الافتراضية — كل ذلك في عملية ذرية واحدة.
  ///
  /// [arabic] يحدد لغة أسماء الحساب والفئات الافتراضية.
  Future<void> completeOnboarding(
    CurrencyInfo currency, {
    required bool arabic,
  }) async {
    await db.transaction(() async {
      // قاعدة 3.12.1: لا يمكن تغيير العملة بعد التأكيد.
      if (await isOnboarded()) {
        throw const BusinessException(BusinessError.currencyLocked);
      }

      final currencyId = await db
          .into(db.currencies)
          .insert(
            CurrenciesCompanion.insert(
              code: currency.code,
              name: currency.name(arabic),
              symbol: currency.symbol(arabic),
              decimals: Value(currency.decimals),
            ),
          );

      final accountId = await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              name: arabic ? 'النقدية' : 'Cash',
              type: AccountType.cash,
              currencyId: currencyId,
              isDefault: const Value(true),
            ),
          );

      // إدراج الفئات دفعة واحدة (batch) أسرع من إدراجها واحدة واحدة.
      await db.batch((b) {
        var order = 0;
        b.insertAll(db.categories, [
          for (final c in kDefaultCategories)
            CategoriesCompanion.insert(
              name: arabic ? c.nameAr : c.nameEn,
              kind: c.kind,
              icon: c.icon,
              color: c.color,
              isDefault: const Value(true),
              sortOrder: Value(order++),
            ),
        ]);
      });

      await set(SettingKeys.defaultAccountId, '$accountId');
      await set(SettingKeys.locale, arabic ? 'ar' : 'en');
      await set(SettingKeys.onboarded, '1');
    });
  }

  /// «حذف جميع البيانات»: الطريق الوحيد لتغيير العملة (يعود للإعداد الأول).
  Future<void> wipeAllData() => db.wipeAllData();
}
