// =============================================================================
// نماذج وحدة الديون: المعادلات (5.1 و 5.2)، المسودات (للإدخال)، ملخصات
// الأشخاص، الملف المالي، والخط الزمني بالرصيد الجاري.
//
// المبالغ أعداد صحيحة بأصغر وحدة للعملة، فلا أخطاء تقريب في الجمع والطرح.
// التقريب يحدث مرة واحدة فقط عند حساب النسب، وللأسفل.
// =============================================================================

import '../../data/database/app_database.dart';
import '../enums.dart';

/// معادلات الدين الواحد والشخص (القسم 5 من الوثيقة).
abstract final class DebtMath {
  /// R = A − Paid − W.
  static int remaining({
    required int amount,
    required int paid,
    required int writtenOff,
  }) => amount - paid - writtenOff;

  /// مفتوح (R = A)، مسدّد جزئياً (0 < R < A)، مغلق (R = 0).
  static DebtStatus status({required int amount, required int remaining}) {
    if (remaining <= 0) return DebtStatus.closed;
    if (remaining >= amount) return DebtStatus.open;
    return DebtStatus.partial;
  }

  /// نسبة السداد = FLOOR(Paid / A × 100): لا تظهر 100% إلا عند السداد الكامل
  /// الفعلي (99.6% تظهر 99%). على مستوى الشخص تُمرَّر المجاميع فتكون مرجّحة.
  static int progress({required int paid, required int amount}) =>
      amount <= 0 ? 0 : (paid * 100) ~/ amount;

  /// نسبة المسامحة (تُعرض منفصلة: «مسدّد 58% • مُسامَح 42%»). عند الإغلاق
  /// تكون المتمم لنسبة السداد حتى يكون المجموع 100%.
  static int writtenOffPercent({
    required int paid,
    required int writtenOff,
    required int amount,
  }) {
    if (amount <= 0 || writtenOff <= 0) return 0;
    if (paid + writtenOff >= amount) {
      return 100 - progress(paid: paid, amount: amount);
    }
    return (writtenOff * 100) ~/ amount;
  }
}

/// بيانات دين جديد أو معدَّل.
class DebtDraft {
  const DebtDraft({
    required this.contactId,
    required this.direction,
    required this.source,
    required this.amount,
    required this.startDate,
    this.dueDate,
    this.accountId,
    this.categoryId,
    this.note,
    this.remind = false,
  });

  final int contactId;
  final DebtDirection direction;
  final DebtSource source;

  /// الأصل A (موجب دائماً؛ الاتجاه يحدده [direction] لا الإشارة).
  final int amount;
  final DateTime startDate;
  final DateTime? dueDate;

  /// الحساب — للإقراض والاقتراض فقط.
  final int? accountId;

  /// فئة الدخل (بيع بالآجل) أو المصروف (شراء بالآجل).
  final int? categoryId;
  final String? note;
  final bool remind;
}

/// عملية استلام (لي) أو سداد (عليّ) لشخص. تُوزَّع تلقائياً على ديونه
/// المفتوحة في نفس الاتجاه، الأقدم أولاً، ما لم يُحدَّد [debtId].
class PaymentDraft {
  const PaymentDraft({
    required this.contactId,
    required this.direction,
    required this.amount,
    required this.paidAt,
    required this.accountId,
    this.debtId,
    this.note,
    this.excessNote,
  });

  final int contactId;
  final DebtDirection direction;
  final int amount;
  final DateTime paidAt;

  /// حساب الاستلام أو الدفع.
  final int accountId;

  /// «اختيار دين معيّن» بدل التوزيع التلقائي.
  final int? debtId;
  final String? note;

  /// ملاحظة الدين المعاكس الذي يُنشأ من الزائد (إن وافق المستخدم).
  final String? excessNote;
}

/// حصة دين واحد من عملية استلام/سداد.
class PaymentAllocation {
  const PaymentAllocation({required this.debtId, required this.amount});

  final int debtId;
  final int amount;
}

/// نتيجة عملية استلام/سداد.
class PaymentResult {
  const PaymentResult({
    required this.operationId,
    required this.allocations,
    this.excessDebtId,
  });

  final String operationId;
  final List<PaymentAllocation> allocations;

  /// الدين المعاكس المُنشأ من الزائد (إن وُجد).
  final int? excessDebtId;

  int get applied => allocations.fold(0, (s, a) => s + a.amount);
}

/// دين مع أرقامه المحسوبة (المدفوع والمتبقي والحالة لا تُخزَّن).
class DebtView {
  const DebtView({
    required this.debt,
    required this.paid,
    this.accountName,
    this.categoryId,
    this.categoryName,
  });

  final Debt debt;

  /// مجموع الدفعات غير الملغاة.
  final int paid;

  /// حساب الإقراض/الاقتراض.
  final String? accountName;

  /// فئة البيع/الشراء بالآجل.
  final int? categoryId;
  final String? categoryName;

  int get id => debt.id;
  int get amount => debt.amount;
  int get writtenOff => debt.writtenOff;
  DebtDirection get direction => debt.direction;
  DebtSource get source => debt.source;

  int get remaining =>
      DebtMath.remaining(amount: amount, paid: paid, writtenOff: writtenOff);
  DebtStatus get status =>
      DebtMath.status(amount: amount, remaining: remaining);
  int get progress => DebtMath.progress(paid: paid, amount: amount);
  int get writtenOffPercent => DebtMath.writtenOffPercent(
    paid: paid,
    writtenOff: writtenOff,
    amount: amount,
  );
  bool get isOpen => remaining > 0;

  /// متأخر: R > 0 وتاريخ الاستحقاق قبل اليوم (علامة إضافية لا حالة رابعة).
  bool isOverdue(DateTime now) =>
      isOpen &&
      debt.dueDate != null &&
      debt.dueDate!.isBefore(DateTime(now.year, now.month, now.day));

  /// عليه دفعات أو مسامحة: لا يُحذف، ولا يتغير اتجاهه أو مصدره أو شخصه.
  bool get hasMovements => paid > 0 || writtenOff > 0;
}

/// مجاميع اتجاه واحد لشخص (لي أو عليّ) — تُعرض في بطاقة مستقلة.
class DirectionSummary {
  const DirectionSummary({
    required this.direction,
    required this.remaining,
    required this.total,
    required this.paid,
    required this.writtenOff,
    required this.openDebts,
    required this.overdueDebts,
    this.nearestDue,
  });

  final DebtDirection direction;

  /// Receivable(P) أو Payable(P).
  final int remaining;

  /// مجموع الأصول ΣA.
  final int total;
  final int paid;
  final int writtenOff;
  final int openDebts;
  final int overdueDebts;
  final DateTime? nearestDue;

  /// نسبة السداد المرجّحة FLOOR(ΣPaid / ΣA × 100) — وليست متوسط النسب.
  int get progress => DebtMath.progress(paid: paid, amount: total);
  int get writtenOffPercent => DebtMath.writtenOffPercent(
    paid: paid,
    writtenOff: writtenOff,
    amount: total,
  );
  DebtStatus get status => DebtMath.status(amount: total, remaining: remaining);

  static DirectionSummary? of(
    DebtDirection direction,
    List<DebtView> debts,
    DateTime now,
  ) {
    final list = debts.where((d) => d.direction == direction).toList();
    if (list.isEmpty) return null;
    DateTime? nearest;
    for (final d in list) {
      final due = d.debt.dueDate;
      if (!d.isOpen || due == null) continue;
      if (nearest == null || due.isBefore(nearest)) nearest = due;
    }
    return DirectionSummary(
      direction: direction,
      remaining: list.fold(0, (s, d) => s + d.remaining),
      total: list.fold(0, (s, d) => s + d.amount),
      paid: list.fold(0, (s, d) => s + d.paid),
      writtenOff: list.fold(0, (s, d) => s + d.writtenOff),
      openDebts: list.where((d) => d.isOpen).length,
      overdueDebts: list.where((d) => d.isOverdue(now)).length,
      nearestDue: nearest,
    );
  }
}

/// مجاميع صفحة الديون والرئيسية (5.3) مع مؤشرات بطاقة الملخص.
class DebtTotals {
  const DebtTotals({
    required this.owedToMe,
    required this.iOwe,
    this.people = 0,
    this.overdueDebts = 0,
  });

  static const zero = DebtTotals(owedToMe: 0, iOwe: 0);

  /// Total owed to me = SUM(Receivable(P)).
  final int owedToMe;

  /// Total I owe = SUM(Payable(P)).
  final int iOwe;

  /// عدد الأشخاص الذين لهم أو عليهم متبقٍ.
  final int people;

  /// عدد الديون المتأخرة.
  final int overdueDebts;

  bool get isEmpty => owedToMe == 0 && iOwe == 0;
}

/// حالة الأشخاص في فلتر صفحة الديون.
enum PeopleStatus { all, open, overdue, closed, archived }

/// ترتيب قائمة الأشخاص.
enum PeopleSort { nearestDue, amountDesc, lastActivity }

/// فلتر صفحة الديون: الحالة والترتيب فقط (التبويبات والبحث منفصلة).
class PeopleFilter {
  const PeopleFilter({
    this.status = PeopleStatus.all,
    this.sort = PeopleSort.nearestDue,
  });

  final PeopleStatus status;
  final PeopleSort sort;

  int get activeCount =>
      (status != PeopleStatus.all ? 1 : 0) +
      (sort != PeopleSort.nearestDue ? 1 : 0);

  @override
  bool operator ==(Object other) =>
      other is PeopleFilter && other.status == status && other.sort == sort;

  @override
  int get hashCode => Object.hash(status, sort);
}

/// سطر شخص في قائمة دفتر الديون.
class PersonSummary {
  const PersonSummary({
    required this.contact,
    required this.receivable,
    required this.payable,
    required this.total,
    required this.paid,
    required this.writtenOff,
    required this.openDebts,
    required this.overdueDebts,
    this.nearestDue,
    this.lastActivity,
  });

  final Contact contact;

  /// المتبقي «لي» عنده.
  final int receivable;

  /// المتبقي «عليّ» له.
  final int payable;

  /// مجموع أصول ديونه (في نطاق التبويب المعروض).
  final int total;
  final int paid;
  final int writtenOff;
  final int openDebts;
  final int overdueDebts;

  /// أقرب تاريخ استحقاق لدين مفتوح.
  final DateTime? nearestDue;
  final DateTime? lastActivity;

  /// الصافي كمعلومة فقط (لا مقاصة تلقائية): موجب = لصالحي.
  int get net => receivable - payable;
  int get remaining => receivable + payable;
  bool get isClosed => remaining == 0;

  /// نسبة السداد المرجّحة.
  int get progress => DebtMath.progress(paid: paid, amount: total);
}

/// نوع عنصر في الخط الزمني.
enum TimelineKind { debt, payment, writeOff }

/// عنصر في الخط الزمني للشخص (7.1).
class TimelineEntry {
  const TimelineEntry({
    required this.kind,
    required this.date,
    required this.direction,
    required this.amount,
    required this.debtId,
    required this.sequence,
    this.source,
    this.operationId,
    this.allocations = const [],
    this.accountName,
    this.categoryName,
    this.note,
    this.cancelled = false,
    this.balanceAfter,
  });

  final TimelineKind kind;
  final DateTime date;
  final DebtDirection direction;

  /// المبلغ (موجب دائماً).
  final int amount;

  /// الدين (أو أول دين في عملية السداد).
  final int debtId;

  /// ترتيب الإدخال لكسر التعادل (بعد التاريخ ونوع العنصر).
  final int sequence;

  /// مصدر الدين — لعناصر الديون.
  final DebtSource? source;

  /// معرّف عملية الاستلام/السداد.
  final String? operationId;

  /// توزيع عملية السداد على الديون.
  final List<PaymentAllocation> allocations;
  final String? accountName;
  final String? categoryName;
  final String? note;

  /// دفعة ملغاة: تُعرض مشطوبة ولا تدخل في الرصيد.
  final bool cancelled;

  /// «الرصيد بعد العملية» في اتجاهها (null للعناصر الملغاة).
  final int? balanceAfter;

  /// أثر العنصر على رصيد اتجاهه: الدين +، الدفعة والمسامحة −.
  int get effect => kind == TimelineKind.debt ? amount : -amount;

  TimelineEntry withBalance(int? balance) => TimelineEntry(
    kind: kind,
    date: date,
    direction: direction,
    amount: amount,
    debtId: debtId,
    sequence: sequence,
    source: source,
    operationId: operationId,
    allocations: allocations,
    accountName: accountName,
    categoryName: categoryName,
    note: note,
    cancelled: cancelled,
    balanceAfter: balance,
  );

  /// الترتيب: حسب التاريخ (اليوم)، وعند التساوي الدين قبل الدفعة ثم
  /// المسامحة، ثم حسب وقت الإدخال.
  static int chronological(TimelineEntry a, TimelineEntry b) {
    final byDay = _day(a.date).compareTo(_day(b.date));
    if (byDay != 0) return byDay;
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    final byTime = a.date.compareTo(b.date);
    if (byTime != 0) return byTime;
    return a.sequence.compareTo(b.sequence);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// يحسب «الرصيد بعد العملية» لكل اتجاه منفصل ويعيد العناصر من الأحدث
  /// للأقدم. آخر رصيد في كل اتجاه = المتبقي الكلي للشخص فيه.
  static List<TimelineEntry> withRunningBalances(List<TimelineEntry> entries) {
    final sorted = [...entries]..sort(chronological);
    final balances = {for (final d in DebtDirection.values) d: 0};
    final result = <TimelineEntry>[];
    for (final e in sorted) {
      if (e.cancelled) {
        result.add(e.withBalance(null));
        continue;
      }
      final b = balances[e.direction]! + e.effect;
      balances[e.direction] = b;
      result.add(e.withBalance(b));
    }
    return result.reversed.toList();
  }
}

/// الملف المالي الكامل لشخص (FR-18).
class PersonProfile {
  const PersonProfile({
    required this.contact,
    required this.debts,
    required this.timeline,
    this.owedToMe,
    this.iOwe,
  });

  final Contact contact;
  final List<DebtView> debts;

  /// كل الحركات من الأحدث للأقدم مع الرصيد الجاري لكل اتجاه.
  final List<TimelineEntry> timeline;

  /// بطاقة «لي» (null إن لم تكن له ديون في هذا الاتجاه).
  final DirectionSummary? owedToMe;

  /// بطاقة «عليّ».
  final DirectionSummary? iOwe;

  DirectionSummary? summary(DebtDirection d) =>
      d == DebtDirection.owedToMe ? owedToMe : iOwe;

  int get receivable => owedToMe?.remaining ?? 0;
  int get payable => iOwe?.remaining ?? 0;

  /// الصافي كمعلومة فقط: موجب = لصالحي.
  int get net => receivable - payable;

  /// له ديون في الاتجاهين (يُعرض الصافي كمعلومة).
  bool get hasBothDirections => owedToMe != null && iOwe != null;

  /// الأرشفة بشرط المتبقي صفر في الاتجاهين.
  bool get canArchive => !contact.isArchived && receivable == 0 && payable == 0;

  /// الحذف فقط لشخص بلا أي حركة.
  bool get canDelete => debts.isEmpty;

  /// الديون المفتوحة في اتجاه، الأقدم أولاً (ترتيب التوزيع).
  List<DebtView> openDebts(DebtDirection d) =>
      debts.where((x) => x.direction == d && x.isOpen).toList()..sort((a, b) {
        final byDate = a.debt.startDate.compareTo(b.debt.startDate);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

  DebtView? debt(int id) => debts.where((d) => d.id == id).firstOrNull;
}

/// دين قريب الاستحقاق (للتذكير وبطاقة الرئيسية).
class UpcomingDebt {
  const UpcomingDebt({
    required this.debt,
    required this.contactName,
    required this.remaining,
  });

  final Debt debt;
  final String contactName;
  final int remaining;
}
