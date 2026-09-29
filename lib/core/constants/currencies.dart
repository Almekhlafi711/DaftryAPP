// =============================================================================
// قائمة العملات التي يمكن اختيارها في الإعداد الأول.
//
// يعمل التطبيق بعملة واحدة فقط تُقفل بعد التأكيد (قاعدة العمل 3.12.1).
// لإضافة عملة جديدة للقائمة يكفي إضافة سطر هنا.
// =============================================================================

/// معلومات عملة واحدة.
class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.symbolAr,
    required this.symbolEn,
    this.decimals = 2,
  });

  /// رمز ISO 4217 المكوّن من 3 أحرف (مثل SAR).
  final String code;
  final String nameAr;
  final String nameEn;

  /// الرمز المختصر للعرض بالعربية (مثل «ر.س»).
  final String symbolAr;

  /// الرمز المختصر للعرض بالإنجليزية (مثل «SAR»).
  final String symbolEn;

  /// عدد الخانات العشرية (2 للريال والدولار، 3 للدينار الكويتي، 0 للين).
  final int decimals;

  String name(bool arabic) => arabic ? nameAr : nameEn;
  String symbol(bool arabic) => arabic ? symbolAr : symbolEn;
}

/// العملات المدعومة، مرتبة حسب الأكثر استخداماً لدى الجمهور المستهدف.
const List<CurrencyInfo> kSupportedCurrencies = [
  CurrencyInfo(
    code: 'SAR',
    nameAr: 'ريال سعودي',
    nameEn: 'Saudi Riyal',
    symbolAr: 'ر.س',
    symbolEn: 'SAR',
  ),
  CurrencyInfo(
    code: 'YER',
    nameAr: 'ريال يمني',
    nameEn: 'Yemeni Rial',
    symbolAr: 'ر.ي',
    symbolEn: 'YER',
  ),
  CurrencyInfo(
    code: 'USD',
    nameAr: 'دولار أمريكي',
    nameEn: 'US Dollar',
    symbolAr: r'$',
    symbolEn: r'$',
  ),
  CurrencyInfo(
    code: 'AED',
    nameAr: 'درهم إماراتي',
    nameEn: 'UAE Dirham',
    symbolAr: 'د.إ',
    symbolEn: 'AED',
  ),
  CurrencyInfo(
    code: 'KWD',
    nameAr: 'دينار كويتي',
    nameEn: 'Kuwaiti Dinar',
    symbolAr: 'د.ك',
    symbolEn: 'KWD',
    decimals: 3,
  ),
  CurrencyInfo(
    code: 'QAR',
    nameAr: 'ريال قطري',
    nameEn: 'Qatari Riyal',
    symbolAr: 'ر.ق',
    symbolEn: 'QAR',
  ),
  CurrencyInfo(
    code: 'BHD',
    nameAr: 'دينار بحريني',
    nameEn: 'Bahraini Dinar',
    symbolAr: 'د.ب',
    symbolEn: 'BHD',
    decimals: 3,
  ),
  CurrencyInfo(
    code: 'OMR',
    nameAr: 'ريال عماني',
    nameEn: 'Omani Rial',
    symbolAr: 'ر.ع',
    symbolEn: 'OMR',
    decimals: 3,
  ),
  CurrencyInfo(
    code: 'EGP',
    nameAr: 'جنيه مصري',
    nameEn: 'Egyptian Pound',
    symbolAr: 'ج.م',
    symbolEn: 'EGP',
  ),
  CurrencyInfo(
    code: 'JOD',
    nameAr: 'دينار أردني',
    nameEn: 'Jordanian Dinar',
    symbolAr: 'د.أ',
    symbolEn: 'JOD',
    decimals: 3,
  ),
  CurrencyInfo(
    code: 'IQD',
    nameAr: 'دينار عراقي',
    nameEn: 'Iraqi Dinar',
    symbolAr: 'د.ع',
    symbolEn: 'IQD',
    decimals: 0,
  ),
  CurrencyInfo(
    code: 'MAD',
    nameAr: 'درهم مغربي',
    nameEn: 'Moroccan Dirham',
    symbolAr: 'د.م',
    symbolEn: 'MAD',
  ),
  CurrencyInfo(
    code: 'DZD',
    nameAr: 'دينار جزائري',
    nameEn: 'Algerian Dinar',
    symbolAr: 'د.ج',
    symbolEn: 'DZD',
  ),
  CurrencyInfo(
    code: 'TND',
    nameAr: 'دينار تونسي',
    nameEn: 'Tunisian Dinar',
    symbolAr: 'د.ت',
    symbolEn: 'TND',
    decimals: 3,
  ),
  CurrencyInfo(
    code: 'LYD',
    nameAr: 'دينار ليبي',
    nameEn: 'Libyan Dinar',
    symbolAr: 'د.ل',
    symbolEn: 'LYD',
    decimals: 3,
  ),
  CurrencyInfo(
    code: 'SDG',
    nameAr: 'جنيه سوداني',
    nameEn: 'Sudanese Pound',
    symbolAr: 'ج.س',
    symbolEn: 'SDG',
  ),
  CurrencyInfo(
    code: 'SYP',
    nameAr: 'ليرة سورية',
    nameEn: 'Syrian Pound',
    symbolAr: 'ل.س',
    symbolEn: 'SYP',
    decimals: 0,
  ),
  CurrencyInfo(
    code: 'LBP',
    nameAr: 'ليرة لبنانية',
    nameEn: 'Lebanese Pound',
    symbolAr: 'ل.ل',
    symbolEn: 'LBP',
    decimals: 0,
  ),
  CurrencyInfo(
    code: 'TRY',
    nameAr: 'ليرة تركية',
    nameEn: 'Turkish Lira',
    symbolAr: '₺',
    symbolEn: '₺',
  ),
  CurrencyInfo(
    code: 'EUR',
    nameAr: 'يورو',
    nameEn: 'Euro',
    symbolAr: '€',
    symbolEn: '€',
  ),
];

/// البحث عن عملة برمزها. يعيد null إن لم تكن مدعومة.
CurrencyInfo? currencyByCode(String code) {
  for (final c in kSupportedCurrencies) {
    if (c.code == code) return c;
  }
  return null;
}
