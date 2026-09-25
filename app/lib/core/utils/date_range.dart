// =============================================================================
// نطاقات التاريخ المستخدمة في الفلترة والتقارير وكشف الحساب.
// كل النطاقات «نصف مفتوحة»: تشمل البداية ولا تشمل النهاية [start, end)
// وهذا يجعل الاستعلامات دقيقة دون مشاكل الساعة 23:59:59.
// =============================================================================

class DateRange {
  const DateRange(this.start, this.end);

  /// بداية النطاق (مشمولة).
  final DateTime start;

  /// نهاية النطاق (غير مشمولة).
  final DateTime end;

  /// اليوم الحالي كاملاً.
  factory DateRange.day(DateTime d) {
    final s = DateTime(d.year, d.month, d.day);
    return DateRange(s, DateTime(d.year, d.month, d.day + 1));
  }

  /// الشهر الذي يقع فيه التاريخ [d].
  factory DateRange.month(DateTime d) =>
      DateRange(DateTime(d.year, d.month), DateTime(d.year, d.month + 1));

  /// السنة التي يقع فيها التاريخ [d].
  factory DateRange.year(DateTime d) =>
      DateRange(DateTime(d.year), DateTime(d.year + 1));

  /// الأسبوع (يبدأ السبت كما هو شائع في المنطقة العربية).
  factory DateRange.week(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    // DateTime.saturday = 6 ؛ نحسب كم يوماً مضى منذ السبت.
    final diff = (day.weekday - DateTime.saturday) % 7;
    final start = DateTime(day.year, day.month, day.day - diff);
    return DateRange(start, DateTime(start.year, start.month, start.day + 7));
  }

  /// آخر [days] يوماً حتى نهاية اليوم الحالي.
  factory DateRange.lastDays(int days, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final end = DateTime(n.year, n.month, n.day + 1);
    return DateRange(DateTime(end.year, end.month, end.day - days), end);
  }

  /// آخر [months] أشهر بما فيها الشهر الحالي.
  factory DateRange.lastMonths(int months, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return DateRange(
      DateTime(n.year, n.month - months + 1),
      DateTime(n.year, n.month + 1),
    );
  }

  /// من بداية يوم [from] حتى نهاية يوم [to] (للنطاق المخصص من المستخدم).
  factory DateRange.inclusiveDays(DateTime from, DateTime to) => DateRange(
    DateTime(from.year, from.month, from.day),
    DateTime(to.year, to.month, to.day + 1),
  );

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  /// عدد الأيام المتبقية من النطاق ابتداءً من [now] (للميزانية: «متبقٍ 6 أيام»).
  int daysLeft(DateTime now) {
    if (!now.isBefore(end)) return 0;
    final today = DateTime(now.year, now.month, now.day);
    return end.difference(today).inDays;
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start → $end)';
}
