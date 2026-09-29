// =============================================================================
// واجهة جدولة التذكيرات.
//
// خدمة الديون لا تعرف كيف تُعرض الإشعارات؛ فقط تطلب «ذكّر بهذا الدين».
// التنفيذ الفعلي في notification_service.dart (flutter_local_notifications)،
// وفي الاختبارات نستخدم تنفيذاً فارغاً. هذا الفصل يجعل المنطق قابلاً للاختبار.
// =============================================================================

abstract interface class ReminderScheduler {
  /// جدولة تذكير قبل موعد الاستحقاق.
  Future<void> scheduleDebtReminder({
    required int debtId,
    required DateTime dueDate,
    required String contactName,
    required int remaining,
    required bool owedToMe,
  });

  /// إلغاء تذكير دين (عند السداد الكامل أو الحذف).
  Future<void> cancelDebtReminder(int debtId);
}

/// تنفيذ لا يفعل شيئاً (للاختبارات أو عند رفض إذن الإشعارات).
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> scheduleDebtReminder({
    required int debtId,
    required DateTime dueDate,
    required String contactName,
    required int remaining,
    required bool owedToMe,
  }) async {}

  @override
  Future<void> cancelDebtReminder(int debtId) async {}
}
