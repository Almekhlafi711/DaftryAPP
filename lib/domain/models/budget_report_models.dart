// =============================================================================
// نماذج الميزانية والتقارير وكشف الحساب.
// =============================================================================

import '../../core/utils/date_range.dart';
import '../../data/database/app_database.dart';
import '../enums.dart';

/// تقدّم ميزانية فئة واحدة في فترة.
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.category,
    required this.spent,
  });

  final Budget budget;
  final Category category;
  final int spent;

  int get limit => budget.limitAmount;
  int get remaining => limit - spent;

  /// النسبة المئوية المستهلكة (قد تتجاوز 100).
  int get percent => limit == 0 ? 0 : spent * 100 ~/ limit;

  /// اللون الدلالي: أخضر أقل من حد التنبيه، كهرماني حتى 99%، أحمر عند التجاوز.
  BudgetLevel get level => levelFor(percent, budget.alertPercent);

  static BudgetLevel levelFor(int percent, int alertPercent) {
    if (percent >= 100) return BudgetLevel.exceeded;
    if (percent >= alertPercent) return BudgetLevel.warning;
    return BudgetLevel.safe;
  }
}

/// ملخص كل الميزانيات لشهر (لبطاقة الرئيسية وشاشة الميزانية).
class BudgetOverview {
  const BudgetOverview({required this.range, required this.items});

  final DateRange range;
  final List<BudgetProgress> items;

  int get totalLimit => items.fold(0, (s, b) => s + b.limit);
  int get totalSpent => items.fold(0, (s, b) => s + b.spent);
  int get remaining => totalLimit - totalSpent;
  bool get isEmpty => items.isEmpty;
  int get percent => totalLimit == 0 ? 0 : totalSpent * 100 ~/ totalLimit;
  BudgetLevel get level => BudgetProgress.levelFor(percent, 75);
}

/// مجموع الدخل والمصروف لشهر واحد (لمخطط مقارنة الأشهر).
class MonthTotals {
  const MonthTotals({
    required this.month,
    required this.income,
    required this.expense,
  });

  /// أول يوم في الشهر.
  final DateTime month;
  final int income;
  final int expense;
  int get net => income - expense;
}

/// مجموع فئة في فترة (لمخطط الدائرة في التقارير).
class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.total,
    required this.share,
  });

  final Category category;
  final int total;

  /// النسبة من الإجمالي (0..1).
  final double share;
}

/// تقرير كامل لفترة (يُستخدم في الشاشة والتصدير).
class PeriodReport {
  const PeriodReport({
    required this.range,
    required this.income,
    required this.expense,
    required this.months,
    required this.expenseByCategory,
    required this.incomeByCategory,
    this.adjustments = 0,
  });

  final DateRange range;

  /// الدخل: العادي + البيع بالآجل + الإعفاء من الديون.
  final int income;

  /// المصروف: العادي + الشراء بالآجل + مسامحة الديون.
  final int expense;
  int get net => income - expense;

  /// «فروقات تسوية»: صافي التسويات في الفترة (سطر مستقل خارج الدخل والمصروف).
  final int adjustments;

  /// آخر 6 أشهر للمقارنة.
  final List<MonthTotals> months;
  final List<CategoryTotal> expenseByCategory;
  final List<CategoryTotal> incomeByCategory;
}

/// نوع سطر في كشف الحساب.
enum StatementLineKind { debt, payment, writeOff }

/// سطر في كشف الحساب (7.2): الحركة موقَّعة على رصيد اتجاهها.
class StatementLine {
  const StatementLine({
    required this.date,
    required this.kind,
    required this.amount,
    required this.balance,
    this.source,
    this.note,
  });

  final DateTime date;
  final StatementLineKind kind;

  /// المبلغ (موجب دائماً).
  final int amount;

  /// الرصيد بعد هذا السطر.
  final int balance;

  /// مصدر الدين — لسطور الديون.
  final DebtSource? source;
  final String? note;

  /// الحركة: الدين +، الاستلام/السداد والمسامحة −.
  int get movement => kind == StatementLineKind.debt ? amount : -amount;
}

/// كشف اتجاه واحد (لي أو عليّ) لفترة من S إلى E.
class StatementSection {
  const StatementSection({
    required this.direction,
    required this.opening,
    required this.lines,
  });

  final DebtDirection direction;

  /// Opening = ΣA قبل S − Σالدفعات قبل S − Σالمسامحة قبل S.
  final int opening;
  final List<StatementLine> lines;

  /// Closing = Opening + ديون الفترة − دفعاتها − مسامحتها.
  int get closing => lines.isEmpty ? opening : lines.last.balance;

  int _sum(StatementLineKind k) =>
      lines.where((l) => l.kind == k).fold(0, (s, l) => s + l.amount);
  int get newDebts => _sum(StatementLineKind.debt);
  int get payments => _sum(StatementLineKind.payment);
  int get writeOffs => _sum(StatementLineKind.writeOff);
}

/// بيانات كشف حساب شخص لفترة (يُولَّد عند الطلب ولا يُخزَّن — قاعدة 3.12.4).
/// لكل اتجاه قسم مستقل: «لي» و«عليّ» لا يُخصم أحدهما من الآخر.
class StatementData {
  const StatementData({
    required this.contact,
    required this.range,
    required this.sections,
  });

  final Contact contact;
  final DateRange range;
  final List<StatementSection> sections;

  StatementSection? section(DebtDirection d) =>
      sections.where((s) => s.direction == d).firstOrNull;
}
