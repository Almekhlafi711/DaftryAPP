// =============================================================================
// نماذج المعاملات المستخدمة بين طبقة الخدمات والواجهة.
// =============================================================================

import '../../core/utils/date_range.dart';
import '../../data/database/app_database.dart';
import '../enums.dart';

/// البيانات التي يُدخلها المستخدم لإضافة أو تعديل معاملة (دخل/مصروف/تحويل).
class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.amount,
    required this.accountId,
    required this.date,
    this.toAccountId,
    this.categoryId,
    this.note,
    this.receiptPath,
  });

  final TxType type;

  /// المبلغ بأصغر وحدة للعملة (موجب).
  final int amount;
  final int accountId;
  final int? toAccountId;
  final int? categoryId;
  final DateTime date;
  final String? note;
  final String? receiptPath;
}

/// معاملة جاهزة للعرض: المعاملة + أسماء الفئة والحساب والشخص (عبر JOIN واحد
/// في قاعدة البيانات بدلاً من استعلام لكل عنصر — أسرع بكثير في القوائم).
class TransactionView {
  const TransactionView({
    required this.tx,
    required this.accountName,
    required this.accountArchived,
    this.toAccountName,
    this.category,
    this.contactName,
    this.contactId,
    this.debtDirection,
    this.debtSource,
  });

  final MoneyTransaction tx;

  /// null لقيود الديون التي لا تحرّك حساباً (البيع/الشراء بالآجل، المسامحة).
  final String? accountName;

  /// يظهر بجانب اسم الحساب شارة «مؤرشف».
  final bool accountArchived;
  final String? toAccountName;
  final Category? category;

  /// اسم الشخص — لقيود الديون فقط.
  final String? contactName;
  final int? contactId;
  final DebtDirection? debtDirection;
  final DebtSource? debtSource;

  int get id => tx.id;
  TxType get type => tx.type;
  bool get isDebtMovement => tx.type.isDebtMovement;

  /// قيد من وحدة الديون (يُفتح منه ملف الشخص بدل التعديل).
  bool get isDebtLinked =>
      tx.type.isDebtEntry || tx.debtId != null || tx.debtPaymentId != null;

  /// بيع أو شراء بالآجل (دخل/مصروف بلا حساب).
  bool get isCredit =>
      (tx.type == TxType.income || tx.type == TxType.expense) &&
      tx.debtId != null;

  /// الأثر الموقَّع للعرض: الدخل والإعفاء +، المصروف والمسامحة −.
  int get signedAmount => switch (tx.type) {
    TxType.income || TxType.debtIn || TxType.debtForgiven => tx.amount,
    TxType.expense || TxType.debtOut || TxType.writeOff => -tx.amount,
    TxType.adjustment => tx.amount,
    TxType.transfer => 0,
  };
}

/// ترتيب نتائج سجل المعاملات.
enum TransactionSort { newest, oldest, amountDesc, amountAsc }

/// معايير الفلترة في نافذة الفلترة (زر فلترة واحد — FR-12).
class TransactionFilter {
  const TransactionFilter({
    this.range,
    this.accountIds = const {},
    this.types = const {},
    this.categoryIds = const {},
    this.showDebtMovements = true,
    this.query = '',
    this.sort = TransactionSort.newest,
  });

  /// الفترة (null = كل الفترات).
  final DateRange? range;

  /// الحسابات المختارة (فارغة = الكل).
  final Set<int> accountIds;

  /// الأنواع المختارة من (دخل، مصروف، تحويل، تسوية) — فارغة = الكل.
  final Set<TxType> types;
  final Set<int> categoryIds;

  /// إظهار حركات الديون أو إخفاؤها.
  final bool showDebtMovements;

  /// نص البحث الفوري (في الملاحظة واسم الفئة والحساب والشخص والمبلغ).
  final String query;
  final TransactionSort sort;

  /// عدد الفلاتر المفعّلة (يظهر كرقم على زر الفلترة).
  int get activeCount =>
      (range != null ? 1 : 0) +
      (accountIds.isNotEmpty ? 1 : 0) +
      (types.isNotEmpty ? 1 : 0) +
      (categoryIds.isNotEmpty ? 1 : 0) +
      (showDebtMovements ? 0 : 1) +
      (sort != TransactionSort.newest ? 1 : 0);

  TransactionFilter copyWith({
    DateRange? range,
    bool clearRange = false,
    Set<int>? accountIds,
    Set<TxType>? types,
    Set<int>? categoryIds,
    bool? showDebtMovements,
    String? query,
    TransactionSort? sort,
  }) => TransactionFilter(
    range: clearRange ? null : (range ?? this.range),
    accountIds: accountIds ?? this.accountIds,
    types: types ?? this.types,
    categoryIds: categoryIds ?? this.categoryIds,
    showDebtMovements: showDebtMovements ?? this.showDebtMovements,
    query: query ?? this.query,
    sort: sort ?? this.sort,
  );
}

/// نتيجة حفظ معاملة: رقمها + تنبيه الميزانية إن تجاوزت الحد.
class TxSaveResult {
  const TxSaveResult(this.id, [this.budgetAlert]);

  final int id;
  final BudgetAlertInfo? budgetAlert;
}

/// تنبيه ميزانية يظهر بعد الحفظ (عند 75% و 100%).
class BudgetAlertInfo {
  const BudgetAlertInfo({
    required this.categoryName,
    required this.spent,
    required this.limit,
    required this.level,
  });

  final String categoryName;
  final int spent;
  final int limit;
  final BudgetLevel level;

  int get percent => limit == 0 ? 0 : (spent * 100 ~/ limit);
}

/// مجموع الدخل والمصروف لفترة (حركات الديون والتسوية والتحويل مستبعدة).
class PeriodTotals {
  const PeriodTotals({required this.income, required this.expense});

  static const zero = PeriodTotals(income: 0, expense: 0);

  final int income;
  final int expense;

  /// الصافي = الدخل − المصروف.
  int get net => income - expense;
}
