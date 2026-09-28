// =============================================================================
// قنوات التواصل مع فريق الدعم (تظهر في الإعدادات كشعارات فقط).
// =============================================================================

abstract final class SupportContacts {
  /// اسم المستخدم في واتساب — يفتح المحادثة مباشرة عبر رابط `wa.me/<username>`.
  static const whatsappUsername = 'ec9';

  /// رقم الاتصال بالصيغة الدولية (اليمن +967) ليعمل من أي دولة.
  static const phone = '+967777953434';

  static const instagramUsername = 'mo.div';

  static final whatsappUri = Uri.https('wa.me', '/$whatsappUsername');
  static final phoneUri = Uri(scheme: 'tel', path: phone);
  static final instagramUri = Uri.https(
    'www.instagram.com',
    '/$instagramUsername/',
  );
}
