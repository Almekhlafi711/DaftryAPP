// =============================================================================
// أخطاء قواعد العمل.
//
// عندما يخالف المستخدم قاعدة (مثل دفعة أكبر من المتبقي) ترمي الخدمة
// [BusinessException] برمز محدد. الواجهة تترجم الرمز إلى رسالة بلغة المستخدم
// (انظر ui/widgets/error_messages.dart). بهذا تبقى طبقة الخدمات مستقلة عن اللغة.
// =============================================================================

/// رموز أخطاء قواعد العمل.
enum BusinessError {
  /// المبلغ صفر أو سالب أو فارغ.
  invalidAmount,

  /// الاسم فارغ.
  emptyName,

  /// يوجد حساب آخر بنفس الاسم.
  duplicateAccountName,

  /// الحساب مؤرشف ولا يمكن استخدامه في عملية جديدة.
  accountArchived,

  /// لا يمكن أرشفة آخر حساب نشط.
  cannotArchiveLastAccount,

  /// يجب اختيار حساب افتراضي بديل قبل أرشفة الحساب الافتراضي.
  mustChooseNewDefault,

  /// التحويل يحتاج حسابين مختلفين.
  sameAccountTransfer,

  /// الفئة لا تناسب نوع المعاملة (فئة دخل في مصروف مثلاً).
  categoryKindMismatch,

  /// الفئة مطلوبة للدخل والمصروف.
  categoryRequired,

  /// لا يمكن تعديل حركات الديون من سجل المعاملات (تُعدّل من ملف الشخص).
  debtMovementReadOnly,

  /// لا يمكن نقل معاملة إلى حساب مؤرشف أو منه.
  cannotMoveArchivedTransaction,

  /// مبلغ الدفعة أكبر من المتبقي من الدين.
  paymentExceedsRemaining,

  /// الدين مسدَّد بالكامل.
  debtAlreadySettled,

  /// مبلغ الدين الجديد أقل مما سُدِّد منه.
  debtAmountBelowPaid,

  /// العملة مقفلة ولا يمكن تغييرها.
  currencyLocked,

  /// التطبيق لم يُهيأ بعد (لم تُختر العملة).
  notOnboarded,

  /// الفئة مستخدمة في معاملات أو ميزانية ولا يمكن حذفها.
  categoryInUse,

  /// العنصر المطلوب غير موجود.
  notFound,

  /// كلمة مرور النسخة الاحتياطية خاطئة أو الملف تالف.
  backupDecryptionFailed,

  /// ملف النسخة ليس نسخة «دفتري» صالحة أو من إصدار أحدث.
  backupInvalidFile,

  /// لا يوجد اتصال (للنسخ السحابي).
  noConnection,

  /// لم يمنح المستخدم الإذن لمزوّد السحابة.
  cloudNotAuthorized,
}

/// استثناء يمثّل مخالفة لقاعدة عمل (وليس خطأً برمجياً).
class BusinessException implements Exception {
  const BusinessException(this.error, [this.details]);

  final BusinessError error;

  /// معلومات إضافية اختيارية (مثل المبلغ المتبقي) لعرضها في الرسالة.
  final Object? details;

  @override
  String toString() => 'BusinessException(${error.name}, $details)';
}
