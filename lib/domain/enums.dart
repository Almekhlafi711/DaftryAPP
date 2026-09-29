// =============================================================================
// الأنواع الثابتة (Enums) المستخدمة في كل طبقات التطبيق.
//
// تُخزَّن هذه القيم في قاعدة البيانات كنصوص (اسم القيمة)، لذلك:
// ⚠️ لا تغيّر اسم أي قيمة موجودة بعد إطلاق التطبيق، لأن البيانات المخزنة
//    لدى المستخدمين تعتمد على هذا الاسم. أضف قيماً جديدة فقط.
// =============================================================================

/// نوع الحساب المالي.
enum AccountType {
  /// نقدي (الكاش في الجيب أو الدرج).
  cash,

  /// حساب بنكي.
  bank,

  /// محفظة إلكترونية (مثل STC Pay).
  wallet,

  /// حساب توفير.
  savings,
}

/// نوع الفئة: دخل أو مصروف (الفئات منفصلة لكل نوع).
enum CategoryKind { income, expense }

/// نوع المعاملة. كل تغيير في رصيد أي حساب يجب أن يكون معاملة من هذه الأنواع.
///
/// أثر كل نوع على الرصيد:
/// - [income]: يزيد رصيد الحساب.
/// - [expense]: ينقص رصيد الحساب.
/// - [transfer]: ينقص من الحساب المصدر ويزيد الحساب الوجهة (لا يؤثر على الإجمالي).
/// - [adjustment]: «تسوية» — مبلغها موقَّع (+ أو −) لتصحيح الرصيد دون تعديله مباشرة.
/// - [debtOut]: «حركة دين» خرج فيها المال (أقرضت شخصاً أو سددت ديناً عليّ).
/// - [debtIn]: «حركة دين» دخل فيها المال (اقترضت أو استلمت دفعة من مدين).
/// - [writeOff]: «مسامحة دين» لي — مصروف دون حركة حساب (لا يوجد مال فعلي).
/// - [debtForgiven]: «إعفاء من دين» عليّ — دخل دون حركة حساب.
///
/// البيع والشراء بالآجل يُسجَّلان [income] / [expense] بلا حساب ومرتبطين بالدين.
/// التسوية وحركات الديون النقدية والتحويل لا تُحتسب دخلاً ولا مصروفاً
/// في التقارير والميزانية (انظر [affectsReports]).
enum TxType {
  income,
  expense,
  transfer,
  adjustment,
  debtOut,
  debtIn,
  writeOff,
  debtForgiven;

  /// يُحتسب دخلاً في التقارير (الدخل العادي، والإعفاء من دين).
  bool get isIncomeLike => this == income || this == debtForgiven;

  /// يُحتسب مصروفاً في التقارير والميزانية (المصروف العادي، والمسامحة).
  bool get isExpenseLike => this == expense || this == writeOff;

  /// هل يدخل هذا النوع في مجاميع الدخل والمصروف والتقارير والميزانية؟
  bool get affectsReports => isIncomeLike || isExpenseLike;

  /// هل هذه «حركة دين» نقدية؟ (استلام، سداد، إقراض، اقتراض).
  bool get isDebtMovement => this == debtOut || this == debtIn;

  /// قيد تنشئه وحدة الديون فقط (يُعدَّل من ملف الشخص لا من سجل المعاملات).
  bool get isDebtEntry =>
      isDebtMovement || this == writeOff || this == debtForgiven;

  /// أسماء الأنواع التي تُحتسب دخلاً / مصروفاً (لاستعلامات SQL).
  static final incomeNames = [
    for (final t in values)
      if (t.isIncomeLike) t.name,
  ];
  static final expenseNames = [
    for (final t in values)
      if (t.isExpenseLike) t.name,
  ];
}

/// اتجاه الدين.
enum DebtDirection {
  /// «لي»: أنا الدائن (أقرضت أو بعت بالآجل).
  owedToMe,

  /// «عليّ»: أنا المدين (اقترضت أو اشتريت بالآجل).
  iOwe,
}

/// مصدر الدين: ما الذي حدث فعلاً عند نشوئه؟ يحدد القيد المحاسبي.
///
/// | المصدر | لي | عليّ | الأثر |
/// |---|---|---|---|
/// | [loan] | أقرضته من حساب | اقترضتُ إلى حساب | الحساب ينقص / يزيد |
/// | [creditSale] | بعتُ له بالآجل | — | دخل بفئة دون حركة حساب |
/// | [creditPurchase] | — | اشتريتُ بالآجل | مصروف بفئة دون حركة حساب |
/// | [opening] | دين سابق | دين سابق | الدفتر فقط |
enum DebtSource {
  loan,
  creditSale,
  creditPurchase,
  opening;

  /// هل يصلح هذا المصدر لهذا الاتجاه؟
  bool allows(DebtDirection d) => switch (this) {
    creditSale => d == DebtDirection.owedToMe,
    creditPurchase => d == DebtDirection.iOwe,
    loan || opening => true,
  };

  /// الإقراض والاقتراض يحتاجان حساباً.
  bool get needsAccount => this == loan;

  /// البيع والشراء بالآجل يحتاجان فئة دخل / مصروف.
  bool get needsCategory => this == creditSale || this == creditPurchase;

  /// المصادر المتاحة لاتجاه معيّن بترتيب العرض.
  static List<DebtSource> forDirection(DebtDirection d) => [
    loan,
    d == DebtDirection.owedToMe ? creditSale : creditPurchase,
    opening,
  ];
}

/// حالة الدين — تُحسب دائماً من الدفعات والمسامحة ولا تُخزَّن:
/// R = الأصل − المدفوع − المُسامَح.
enum DebtStatus {
  /// R = الأصل: لم يُسدَّد منه شيء.
  open,

  /// 0 < R < الأصل: مسدّد جزئياً.
  partial,

  /// R = 0: مغلق (بالسداد أو بالمسامحة).
  closed,
}

/// فترة الميزانية.
enum BudgetPeriod { monthly, weekly }

/// مستوى الميزانية للتلوين: أخضر آمن، كهرماني تحذير، أحمر تجاوز.
enum BudgetLevel { safe, warning, exceeded }

/// مزوّد النسخ الاحتياطي.
enum BackupProvider { local, googleDrive, iCloud }
