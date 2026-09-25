// =============================================================================
// نماذج وحدة الديون: المسودات (للإدخال)، ملخص الشخص، الملف المالي، الخط الزمني.
// =============================================================================

import '../../data/database/app_database.dart';
import '../enums.dart';

/// بيانات دين جديد أو معدَّل.
class DebtDraft {
  const DebtDraft({
    required this.contactId,
    required this.direction,
    required this.amount,
    required this.startDate,
    this.dueDate,
    this.accountId,
    this.note,
    this.remind = false,
  });

  final int contactId;
  final DebtDirection direction;
  final int amount;
  final DateTime startDate;
  final DateTime? dueDate;

  /// الحساب الذي خرج منه/دخل إليه المال. null = «بيع/شراء بالآجل» (دفتر فقط).
  final int? accountId;
  final String? note;
  final bool remind;
}

/// بيانات دفعة سداد.
class PaymentDraft {
  const PaymentDraft({
    required this.amount,
    required this.paidAt,
    this.accountId,
    this.note,
  });

  final int amount;
  final DateTime paidAt;

  /// حساب الاستلام أو الدفع. null = الدفعة في الدفتر فقط.
  final int? accountId;
  final String? note;
}

/// مجموع الديون المتبقية في الاتجاهين (أعلى شاشة الديون وبطاقة الرئيسية).
class DebtTotals {
  const DebtTotals({required this.owedToMe, required this.iOwe});

  static const zero = DebtTotals(owedToMe: 0, iOwe: 0);

  /// «لي عند الناس».
  final int owedToMe;

  /// «عليّ للناس».
  final int iOwe;

  bool get isEmpty => owedToMe == 0 && iOwe == 0;
}

/// سطر شخص في قائمة دفتر الديون.
class PersonSummary {
  const PersonSummary({
    required this.contact,
    required this.owedToMeRemaining,
    required this.iOweRemaining,
    required this.totalAmount,
    required this.paidAmount,
    required this.openDebts,
    this.nearestDue,
  });

  final Contact contact;
  final int owedToMeRemaining;
  final int iOweRemaining;

  /// إجمالي أصل الديون (للاتجاه المعروض).
  final int totalAmount;
  final int paidAmount;
  final int openDebts;

  /// أقرب تاريخ استحقاق لدين غير مسدَّد.
  final DateTime? nearestDue;

  /// الصافي من منظور المستخدم: موجب = لي، سالب = عليّ.
  int get net => owedToMeRemaining - iOweRemaining;

  /// نسبة السداد لشريط التقدم (0..1).
  double get progress => totalAmount == 0 ? 0 : paidAmount / totalAmount;

  bool isOverdue(DateTime now) =>
      nearestDue != null &&
      nearestDue!.isBefore(DateTime(now.year, now.month, now.day));
}

/// نوع عنصر في الخط الزمني للشخص.
enum TimelineKind { debt, payment }

/// عنصر في الخط الزمني للملف المالي للشخص.
class TimelineEntry {
  const TimelineEntry({
    required this.kind,
    required this.date,
    required this.amount,
    required this.direction,
    required this.debtId,
    this.paymentId,
    this.note,
    this.accountName,
  });

  final TimelineKind kind;
  final DateTime date;

  /// المبلغ (موجب دائماً)؛ الإشارة تُحسب في [signedEffect].
  final int amount;
  final DebtDirection direction;
  final int debtId;
  final int? paymentId;
  final String? note;

  /// اسم الحساب المرتبط، أو null إذا كانت الحركة في الدفتر فقط.
  final String? accountName;

  /// أثر العنصر على «صافي» العلاقة من منظور المستخدم (موجب = لي):
  /// دين لي +، دفعة مستلمة −، دين عليّ −، دفعة مدفوعة +.
  int get signedEffect {
    final base = kind == TimelineKind.debt ? amount : -amount;
    return direction == DebtDirection.owedToMe ? base : -base;
  }
}

/// الملف المالي الكامل لشخص (FR-18).
class PersonProfile {
  const PersonProfile({
    required this.contact,
    required this.debts,
    required this.timeline,
  });

  final Contact contact;
  final List<Debt> debts;

  /// كل الحركات مرتبة من الأحدث للأقدم.
  final List<TimelineEntry> timeline;

  int _remaining(DebtDirection d) => debts
      .where((x) => x.direction == d)
      .fold(0, (s, x) => s + (x.amount - x.paidAmount));

  int get owedToMeRemaining => _remaining(DebtDirection.owedToMe);
  int get iOweRemaining => _remaining(DebtDirection.iOwe);

  /// الصافي: موجب = المتبقي لي عنده، سالب = المتبقي عليّ له.
  int get net => owedToMeRemaining - iOweRemaining;
  int get totalDebts => debts.fold(0, (s, x) => s + x.amount);
  int get totalPaid => debts.fold(0, (s, x) => s + x.paidAmount);

  /// أقرب استحقاق لدين غير مسدَّد.
  DateTime? get nearestDue {
    DateTime? best;
    for (final d in debts) {
      if (d.status == DebtStatus.settled || d.dueDate == null) continue;
      if (best == null || d.dueDate!.isBefore(best)) best = d.dueDate;
    }
    return best;
  }

  /// الحالة الإجمالية للعلاقة.
  DebtStatus get status {
    if (debts.isEmpty || debts.every((d) => d.status == DebtStatus.settled)) {
      return DebtStatus.settled;
    }
    if (totalPaid == 0) return DebtStatus.open;
    return DebtStatus.partial;
  }

  /// الديون المفتوحة (لاختيار الدين عند تسجيل دفعة).
  List<Debt> get openDebts =>
      debts.where((d) => d.status != DebtStatus.settled).toList();
}

/// دين قريب الاستحقاق (للتذكير وبطاقة الرئيسية).
class UpcomingDebt {
  const UpcomingDebt({required this.debt, required this.contactName});

  final Debt debt;
  final String contactName;

  int get remaining => debt.amount - debt.paidAmount;
}
