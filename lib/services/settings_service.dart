// =============================================================================
// خدمة الإعدادات والإعداد الأول (Onboarding).
//
// الإعدادات تُخزَّن في جدول settings بصيغة مفتاح/قيمة، وتُقرأ كتدفق تفاعلي
// (Stream) فتتغير الواجهة فوراً عند تغيير اللغة أو المظهر مثلاً.
// =============================================================================

import 'package:drift/drift.dart';

import '../core/constants/currencies.dart';
import '../core/errors/app_exception.dart';
import '../core/money/money.dart';
import '../data/database/app_database.dart';
import '../data/seed/default_categories.dart';
import '../domain/enums.dart';

/// مفاتيح الإعدادات المخزنة. أضف المفاتيح الجديدة هنا فقط.
abstract final class SettingKeys {
  /// '1' بعد إكمال الإعداد الأول وقفل العملة.
  static const onboarded = 'onboarded';
  static const defaultAccountId = 'default_account_id';

  /// اسم صاحب الدفتر (مطلوب في الإعداد الأول) — يظهر في التقارير والكشوف.
  static const userName = 'user_name';

  /// رقم جوال صاحب الدفتر (اختياري).
  static const userPhone = 'user_phone';

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

  /// null إن لم يُدخل الاسم بعد (مثل نسخة احتياطية من إصدار أقدم).
  String? get userName => _nonEmpty(SettingKeys.userName);
  String? get userPhone => _nonEmpty(SettingKeys.userPhone);
  String? _nonEmpty(String key) {
    final v = _values[key]?.trim();
    return v == null || v.isEmpty ? null : v;
  }

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
  // الملف الشخصي: الاسم (مطلوب) ورقم الجوال (اختياري)
  // ---------------------------------------------------------------------------

  /// أقصى طول للاسم.
  static const maxNameLength = 40;

  /// يوحّد رقم الجوال: يحوّل الأرقام الهندية ويحذف المسافات والشرطات
  /// والأقواس. يعيد null للرقم الفارغ، ويرمي [BusinessError.invalidPhone]
  /// إن لم يكن من 6 إلى 15 رقماً (مع + اختيارية في البداية).
  static String? normalizePhone(String? raw) {
    final compact = MoneyParser.normalizeDigits(raw ?? '')
        .replaceAll(RegExp(r'[\s\-()]'), '');
    if (compact.isEmpty) return null;
    if (!RegExp(r'^\+?\d{6,15}$').hasMatch(compact)) {
      throw const BusinessException(BusinessError.invalidPhone);
    }
    return compact;
  }

  /// يتحقق من الاسم والرقم ويعيدهما بعد التنظيف.
  static ({String name, String? phone}) _validateProfile(
    String name,
    String? phone,
  ) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const BusinessException(BusinessError.emptyName);
    return (
      name: trimmed.length > maxNameLength
          ? trimmed.substring(0, maxNameLength)
          : trimmed,
      phone: normalizePhone(phone),
    );
  }

  Future<void> _writeProfile(({String name, String? phone}) profile) async {
    await set(SettingKeys.userName, profile.name);
    if (profile.phone == null) {
      await (db.delete(
        db.settings,
      )..where((s) => s.key.equals(SettingKeys.userPhone))).go();
    } else {
      await set(SettingKeys.userPhone, profile.phone!);
    }
  }

  /// حفظ الاسم ورقم الجوال (من الإعدادات). الرقم الفارغ يحذف الرقم المحفوظ.
  Future<void> saveProfile({required String name, String? phone}) {
    final profile = _validateProfile(name, phone);
    return db.transaction(() => _writeProfile(profile));
  }

  // ---------------------------------------------------------------------------
  // الإعداد الأول (UC-00)
  // ---------------------------------------------------------------------------

  /// يُكمل الإعداد الأول: يحفظ العملة ويقفلها، وينشئ الحساب الافتراضي
  /// «النقدية» والفئات الافتراضية — كل ذلك في عملية ذرية واحدة.
  ///
  /// [arabic] يحدد لغة أسماء الحساب والفئات الافتراضية.
  /// [userName] و [userPhone] يُحفظان في العملية نفسها إن مُرِّرا.
  Future<void> completeOnboarding(
    CurrencyInfo currency, {
    required bool arabic,
    String? userName,
    String? userPhone,
  }) async {
    // التحقق قبل أي كتابة حتى لا يُقفل الإعداد بملف شخصي غير صالح.
    final profile = userName == null
        ? null
        : _validateProfile(userName, userPhone);
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
              systemKey: Value(c.key),
            ),
        ]);
      });

      await set(SettingKeys.defaultAccountId, '$accountId');
      if (profile != null) await _writeProfile(profile);
      await set(SettingKeys.locale, arabic ? 'ar' : 'en');
      await set(SettingKeys.onboarded, '1');
    });
  }

  /// «حذف جميع البيانات»: الطريق الوحيد لتغيير العملة (يعود للإعداد الأول).
  Future<void> wipeAllData() => db.wipeAllData();
}
