// =============================================================================
// خدمة الإشعارات المحلية (FR-20): تذكير الديون قبل الاستحقاق — دون أي خادم.
//
// تحقق واجهة ReminderScheduler التي تستخدمها خدمة الديون.
// النصوص تُمرَّر من طبقة الواجهة (بلغة المستخدم) عبر [ReminderTexts].
// =============================================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_scheduler.dart';

/// نصوص الإشعار بلغة المستخدم (تُحدَّث عند تغيير اللغة).
class ReminderTexts {
  const ReminderTexts({
    required this.channelName,
    required this.title,
    required this.owedToMeBody,
    required this.iOweBody,
    required this.formatAmount,
  });

  final String channelName;
  final String title;

  /// مثل: «يستحق غداً على {name} مبلغ {amount}».
  final String Function(String name, String amount) owedToMeBody;
  final String Function(String name, String amount) iOweBody;
  final String Function(int minor) formatAmount;
}

class NotificationService implements ReminderScheduler {
  NotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// النصوص الحالية؛ تُضبط من الواجهة بعد تحميل اللغة.
  ReminderTexts? texts;

  /// التذكير في الساعة 9 صباحاً قبل الاستحقاق بيوم.
  static const _reminderHour = 9;

  /// معرّف الإشعار = معرّف الدين + إزاحة ثابتة (لتجنب التعارض مستقبلاً).
  static int _idFor(int debtId) => 100000 + debtId;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } on Object {
      // نبقى على UTC إن تعذر معرفة المنطقة الزمنية.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // نطلب الإذن عند أول تفعيل لتذكير، وليس عند فتح التطبيق.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// طلب إذن الإشعارات (يُستدعى عند تفعيل «ذكّرني» لأول مرة).
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  @override
  Future<void> scheduleDebtReminder({
    required int debtId,
    required DateTime dueDate,
    required String contactName,
    required int remaining,
    required bool owedToMe,
  }) async {
    final t = texts;
    if (t == null) return;
    await init();
    final when = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day - 1,
      _reminderHour,
    );
    await _plugin.cancel(id: _idFor(debtId));
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;

    final amount = t.formatAmount(remaining);
    await _plugin.zonedSchedule(
      id: _idFor(debtId),
      scheduledDate: when,
      title: t.title,
      body: owedToMe
          ? t.owedToMeBody(contactName, amount)
          : t.iOweBody(contactName, amount),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_reminders',
          t.channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // تذكير غير حرج: لا يحتاج صلاحية المنبّه الدقيق في Android.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'debt:$debtId',
    );
  }

  @override
  Future<void> cancelDebtReminder(int debtId) async {
    await init();
    await _plugin.cancel(id: _idFor(debtId));
  }
}
