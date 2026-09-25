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
  });

  final DateRange range;
  final int income;
  final int expense;
  int get net => income - expense;

  /// آخر 6 أشهر للمقارنة.
  final List<MonthTotals> months;
  final List<CategoryTotal> expenseByCategory;
  final List<CategoryTotal> incomeByCategory;
}

/// سطر في كشف الحساب.
class StatementLine {
  const StatementLine({
    required this.date,
    required this.isPayment,
    required this.direction,
    required this.amount,
    required this.effect,
    required this.runningBalance,
    this.note,
  });

  final DateTime date;
  final bool isPayment;
  final DebtDirection direction;
  final int amount;

  /// الأثر الموقَّع على الصافي (موجب = لي).
  final int effect;

  /// الرصيد بعد هذه الحركة.
  final int runningBalance;
  final String? note;
}

/// بيانات كشف حساب شخص لفترة (يُولَّد عند الطلب ولا يُخزَّن — قاعدة 3.12.4).
class StatementData {
  const StatementData({
    required this.contact,
    required this.range,
    required this.openingBalance,
    required this.lines,
  });

  final Contact contact;
  final DateRange range;

  /// الرصيد الافتتاحي: صافي العلاقة قبل بداية الفترة.
  final int openingBalance;
  final List<StatementLine> lines;

  /// المتبقي في نهاية الفترة.
  int get closingBalance =>
      lines.isEmpty ? openingBalance : lines.last.runningBalance;

  int get totalDebts =>
      lines.where((l) => !l.isPayment).fold(0, (s, l) => s + l.amount);
  int get totalPayments =>
      lines.where((l) => l.isPayment).fold(0, (s, l) => s + l.amount);
}
