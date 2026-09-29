// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'دفتري';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get confirm => 'تأكيد';

  @override
  String get back => 'رجوع';

  @override
  String get apply => 'تطبيق';

  @override
  String get reset => 'إعادة ضبط';

  @override
  String get undo => 'تراجع';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get optional => 'اختياري';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get note => 'ملاحظة';

  @override
  String get date => 'التاريخ';

  @override
  String get amount => 'المبلغ';

  @override
  String get account => 'الحساب';

  @override
  String get category => 'الفئة';

  @override
  String get name => 'الاسم';

  @override
  String get phone => 'رقم الجوال';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get archivedBadge => 'مؤرشف';

  @override
  String get defaultBadge => 'افتراضي';

  @override
  String get all => 'الكل';

  @override
  String get more => 'المزيد';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordTooShort => '6 أحرف على الأقل';

  @override
  String get areYouSure => 'هل أنت متأكد؟';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navTransactions => 'المعاملات';

  @override
  String get navDebts => 'الديون';

  @override
  String get navMore => 'المزيد';

  @override
  String get welcomeTitle => 'مرحباً بك في دفتري';

  @override
  String get welcomeSubtitle => 'لا حساب • لا كلمة مرور • ابدأ فوراً';

  @override
  String get chooseCurrency => 'اختر عملتك';

  @override
  String get currencyWarning =>
      'ستُستخدم في كل التطبيق ولا يمكن تغييرها لاحقاً';

  @override
  String get searchCurrency => 'ابحث عن عملة';

  @override
  String get cloudBackupOptionalHint =>
      'اختياري — يمكن تفعيله لاحقاً من الإعدادات';

  @override
  String get confirmCurrencyTitle => 'تأكيد عملة التطبيق';

  @override
  String get confirmCurrencyBody =>
      'ستُسجَّل كل الحسابات والمعاملات والديون بهذه العملة.';

  @override
  String get confirmCurrencyWarning => 'لا يمكن تغييرها بعد التأكيد';

  @override
  String get confirmAndStart => 'تأكيد والبدء';

  @override
  String get backAndChange => 'رجوع وتغيير العملة';

  @override
  String get restoreExisting => 'لديك نسخة احتياطية؟ استعادة';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get totalBalance => 'إجمالي أرصدة الحسابات';

  @override
  String get monthIncome => 'دخل الشهر';

  @override
  String get monthExpense => 'مصروف الشهر';

  @override
  String get quickExpense => 'مصروف';

  @override
  String get quickIncome => 'دخل';

  @override
  String get quickTransfer => 'تحويل';

  @override
  String get quickDebt => 'دين';

  @override
  String get monthlyBudget => 'الميزانية الشهرية';

  @override
  String budgetOf(String spent, String limit) {
    return '$spent من $limit';
  }

  @override
  String remainingForDays(String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يوماً',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم واحد',
      zero: 'اليوم',
    );
    return 'متبقٍ $amount لـ $_temp0';
  }

  @override
  String get owedToMe => 'لي عند الناس';

  @override
  String get iOwe => 'عليّ للناس';

  @override
  String get recentTransactions => 'آخر المعاملات';

  @override
  String get noTransactionsYet =>
      'لا توجد معاملات بعد. اضغط + لإضافة أول معاملة.';

  @override
  String get hideBalances => 'إخفاء الأرصدة';

  @override
  String get transactionsTitle => 'المعاملات';

  @override
  String get searchTransactions => 'ابحث بالاسم أو المبلغ';

  @override
  String get addTransaction => 'إضافة معاملة';

  @override
  String get editTransaction => 'تعديل معاملة';

  @override
  String get typeExpense => 'مصروف';

  @override
  String get typeIncome => 'دخل';

  @override
  String get typeTransfer => 'تحويل';

  @override
  String get typeAdjustment => 'تسوية';

  @override
  String get typeDebtOut => 'حركة دين — خرج';

  @override
  String get typeDebtIn => 'حركة دين — دخل';

  @override
  String get debtMovement => 'حركة دين';

  @override
  String get fromAccount => 'من حساب';

  @override
  String get toAccount => 'إلى حساب';

  @override
  String get suggestedForCategory => 'مقترح: آخر حساب للفئة';

  @override
  String get attachReceipt => 'إرفاق إيصال';

  @override
  String get receiptAttached => 'تم إرفاق الإيصال';

  @override
  String get removeReceipt => 'إزالة الإيصال';

  @override
  String get viewReceipt => 'عرض الإيصال';

  @override
  String get receiptCamera => 'الكاميرا';

  @override
  String get receiptGallery => 'المعرض';

  @override
  String get chooseCategory => 'اختر فئة';

  @override
  String get deleteTransactionTitle => 'حذف هذه المعاملة؟';

  @override
  String deleteTransactionBody(
    String description,
    String amount,
    String account,
  ) {
    return '$description — $amount\nسيُعاد المبلغ إلى رصيد «$account» تلقائياً.';
  }

  @override
  String get transactionDeleted => 'تم حذف المعاملة';

  @override
  String get debtMovementHint =>
      'حركة دين تحرّك الرصيد ولا تُحتسب دخلاً ولا مصروفاً. تُعدَّل من ملف الشخص.';

  @override
  String get openPersonProfile => 'فتح ملف الشخص';

  @override
  String budgetWarning(String category, String percent) {
    return 'اقتربت من ميزانية «$category»: $percent%';
  }

  @override
  String budgetExceeded(String category, String percent) {
    return 'تجاوزت ميزانية «$category» ($percent%)';
  }

  @override
  String get filterTitle => 'فلترة المعاملات';

  @override
  String get period => 'الفترة';

  @override
  String get periodToday => 'اليوم';

  @override
  String get periodWeek => 'هذا الأسبوع';

  @override
  String get periodMonth => 'هذا الشهر';

  @override
  String get periodLast30 => 'آخر 30 يوماً';

  @override
  String get periodLast3Months => 'آخر 3 أشهر';

  @override
  String get periodYear => 'هذه السنة';

  @override
  String get periodCustom => 'مخصص';

  @override
  String get periodAll => 'كل الفترات';

  @override
  String get typeAndCategory => 'النوع والفئة';

  @override
  String get showDebtMovements => 'إظهار حركات الديون';

  @override
  String get showDebtMovementsHint =>
      'تظهر في السجل فقط ولا تدخل في الدخل والمصروف';

  @override
  String get sort => 'الترتيب';

  @override
  String get sortNewest => 'الأحدث أولاً';

  @override
  String get sortOldest => 'الأقدم أولاً';

  @override
  String get sortAmountDesc => 'الأعلى مبلغاً';

  @override
  String get sortAmountAsc => 'الأقل مبلغاً';

  @override
  String get allCategories => 'كل الفئات';

  @override
  String summaryIncome(String amount) {
    return 'دخل $amount';
  }

  @override
  String summaryExpense(String amount) {
    return 'مصروف $amount';
  }

  @override
  String get accountsTitle => 'الحسابات';

  @override
  String get totalActiveAccounts => 'إجمالي الحسابات النشطة';

  @override
  String activeAccountsCount(String count) {
    return 'نشطة ($count)';
  }

  @override
  String archivedAccountsCount(String count) {
    return 'المؤرشفة ($count)';
  }

  @override
  String archivedSince(String date) {
    return 'مؤرشف منذ $date';
  }

  @override
  String get addAccount => 'إضافة حساب';

  @override
  String get editAccount => 'تعديل الحساب';

  @override
  String get accountName => 'اسم الحساب';

  @override
  String get accountType => 'نوع الحساب';

  @override
  String get openingBalance => 'الرصيد الافتتاحي';

  @override
  String get accountTypeCash => 'نقدي';

  @override
  String get accountTypeBank => 'بنكي';

  @override
  String get accountTypeWallet => 'محفظة';

  @override
  String get accountTypeSavings => 'توفير';

  @override
  String get setAsDefault => 'تعيين كافتراضي';

  @override
  String get archive => 'أرشفة';

  @override
  String get unarchive => 'رفع الأرشفة';

  @override
  String get adjustBalance => 'تسوية الرصيد';

  @override
  String get adjustBalanceHint =>
      'أدخل الرصيد الفعلي وسيُسجَّل الفرق كمعاملة «تسوية» في السجل.';

  @override
  String get actualBalance => 'الرصيد الفعلي';

  @override
  String archiveTitle(String name) {
    return 'أرشفة «$name»؟';
  }

  @override
  String get archiveBody =>
      'لن يظهر في الرئيسية ولا عند إضافة معاملة أو دين جديد. المعاملات السابقة تبقى كما هي وتظهر في التقارير.';

  @override
  String archiveHasBalance(String amount) {
    return 'رصيده الحالي $amount';
  }

  @override
  String get transferBalanceTo => 'تحويل الرصيد إلى';

  @override
  String get transferAndArchive => 'تحويل الرصيد ثم الأرشفة';

  @override
  String get newDefaultAccount => 'الحساب الافتراضي البديل';

  @override
  String get recalculateBalances => 'إعادة احتساب الأرصدة';

  @override
  String recalculateDone(String count) {
    return 'تمت المراجعة — صُحح $count حساب';
  }

  @override
  String get debtsTitle => 'الديون';

  @override
  String get debtsSubtitle => 'منفصلة عن الدخل والمصروف';

  @override
  String get tabOwedToMe => 'لي';

  @override
  String get tabIOwe => 'عليّ';

  @override
  String get newDebt => 'دين جديد';

  @override
  String dueInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يوماً',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوم',
    );
    return 'يستحق بعد $_temp0';
  }

  @override
  String overdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يوماً',
      few: '$days أيام',
      two: 'يومين',
      one: 'يوماً',
    );
    return 'متأخر $_temp0';
  }

  @override
  String get dueToday => 'يستحق اليوم';

  @override
  String get statusClosed => 'مغلق';

  @override
  String get statusOverdue => 'متأخر';

  @override
  String get statusPartial => 'مسدَّد جزئياً';

  @override
  String get statusOpen => 'مفتوح';

  @override
  String ofTotal(String amount) {
    return 'من $amount';
  }

  @override
  String get noDebts => 'لا توجد ديون مسجلة. سجّل ديناً لتتابع ما لك وما عليك.';

  @override
  String get directionOwedToMeHint => 'أقرضت / بعت بالآجل';

  @override
  String get directionIOweHint => 'اقترضت / اشتريت بالآجل';

  @override
  String get person => 'الشخص';

  @override
  String get choosePerson => 'اختر شخصاً';

  @override
  String get fromContacts => 'من جهات الاتصال';

  @override
  String get addPerson => 'إضافة شخص';

  @override
  String get dueDateOptional => 'الاستحقاق (اختياري)';

  @override
  String get decreasesBalanceNotExpense => 'ينقص الرصيد — ليس مصروفاً';

  @override
  String get increasesBalanceNotIncome => 'يزيد الرصيد — ليس دخلاً';

  @override
  String get remindBeforeDue => 'ذكّرني قبل الموعد بيوم';

  @override
  String get saveDebt => 'حفظ الدين';

  @override
  String get editDebt => 'تعديل الدين';

  @override
  String get deleteDebt => 'حذف الدين';

  @override
  String get deleteDebtBody =>
      'يُحذف الدين مع قيده فيعود الحساب أو الدخل أو المصروف كما كان. (للديون المسجلة خطأً فقط.)';

  @override
  String remainingAmount(String amount) {
    return 'المتبقي: $amount';
  }

  @override
  String get fullRemaining => 'كامل المتبقي';

  @override
  String get receivedIntoAccount => 'استلمتُ المبلغ في';

  @override
  String get paidFromAccount => 'دفعتُ المبلغ من';

  @override
  String profileOwedToMe(String name) {
    return 'المتبقي لي عند $name';
  }

  @override
  String profileIOwe(String name) {
    return 'المتبقي عليّ لـ $name';
  }

  @override
  String paidAmount(String amount) {
    return 'مدفوع $amount';
  }

  @override
  String totalDebtsAmount(String amount) {
    return 'إجمالي الديون $amount';
  }

  @override
  String dueOn(String date) {
    return 'يستحق $date';
  }

  @override
  String get statement => 'كشف';

  @override
  String get timeline => 'الخط الزمني';

  @override
  String get paymentReceived => 'استلام';

  @override
  String get paymentMade => 'سداد';

  @override
  String get editPerson => 'تعديل بيانات الشخص';

  @override
  String get searchPeople => 'ابحث عن شخص';

  @override
  String get sourceTitle => 'مصدر الدين';

  @override
  String get sourceLoanOwed => 'أقرضته من حساب';

  @override
  String get sourceLoanOwe => 'اقترضتُ إلى حساب';

  @override
  String get sourceCreditSale => 'بعتُ له بالآجل';

  @override
  String get sourceCreditPurchase => 'اشتريتُ بالآجل';

  @override
  String get sourceOpening => 'دين سابق (قبل استخدام التطبيق)';

  @override
  String get sourceCreditSaleHint => 'يُسجَّل دخلاً بفئة — دون حركة حساب';

  @override
  String get sourceCreditPurchaseHint => 'يُسجَّل مصروفاً بفئة — دون حركة حساب';

  @override
  String get sourceOpeningHint => 'في الدفتر فقط — لا دخل ولا حركة حساب';

  @override
  String get labelLoanOwed => 'سلفة نقدية';

  @override
  String get labelLoanOwe => 'اقتراض';

  @override
  String get labelCreditSale => 'بيع بالآجل';

  @override
  String get labelCreditPurchase => 'شراء بالآجل';

  @override
  String get labelOpening => 'دين سابق';

  @override
  String get debtLockedHint =>
      'عليه دفعات أو مسامحة: الاتجاه والمصدر والشخص مقفلة';

  @override
  String get receiveAmount => 'استلام مبلغ';

  @override
  String get payAmount => 'سداد مبلغ';

  @override
  String receiveFrom(String name) {
    return 'استلام من $name';
  }

  @override
  String payTo(String name) {
    return 'سداد لـ $name';
  }

  @override
  String remainingAfterPayment(String amount) {
    return 'المتبقي بعد الدفعة: $amount';
  }

  @override
  String distributedOldestFirst(String parts) {
    return 'يُوزَّع على الأقدم أولاً: $parts';
  }

  @override
  String get chooseSpecificDebt => 'اختيار دين معيّن';

  @override
  String get autoDistribute => 'توزيع تلقائي';

  @override
  String get excessTitle => 'مبلغ زائد عن المتبقي';

  @override
  String excessOwedToMe(String amount, String name) {
    return 'الزائد $amount — هل تسجّله ديناً عليك لـ $name؟';
  }

  @override
  String excessIOwe(String amount, String name) {
    return 'الزائد $amount — هل تسجّله ديناً لك على $name؟';
  }

  @override
  String get recordExcess => 'تسجيل الزائد';

  @override
  String get editAmount => 'تعديل المبلغ';

  @override
  String get excessNote => 'زيادة عن المستحق';

  @override
  String get noOneOwesYou => 'لا توجد ديون مفتوحة لك عند أحد';

  @override
  String get youOweNoOne => 'لا توجد ديون مفتوحة عليك';

  @override
  String get distribution => 'تفصيل التوزيع';

  @override
  String get cancelOperation => 'إلغاء العملية';

  @override
  String get cancelOperationBody =>
      'تُلغى كل دفعات العملية معاً ويُعكس أثرها على الحساب، وتبقى ظاهرة مشطوبة في الخط الزمني.';

  @override
  String get cancelledBadge => 'ملغاة';

  @override
  String negativeCashWarning(String account) {
    return 'تنبيه: رصيد «$account» أصبح سالباً';
  }

  @override
  String get forgiveRemaining => 'مسامحة بالمتبقي';

  @override
  String get forgivenRemaining => 'إعفاء من المتبقي';

  @override
  String forgiveBodyOwedToMe(String amount) {
    return 'يُغلق الدين ويُسجَّل المتبقي $amount مصروفاً بفئة «مسامحة ديون». لا تتحرك أرصدة الحسابات.';
  }

  @override
  String forgiveBodyIOwe(String amount) {
    return 'يُغلق الدين ويُسجَّل المتبقي $amount دخلاً بفئة «إعفاء دين». لا تتحرك أرصدة الحسابات.';
  }

  @override
  String get writeOffEntry => 'مسامحة';

  @override
  String get forgivenEntry => 'إعفاء من الدين';

  @override
  String paymentRate(String percent) {
    return 'نسبة السداد $percent%';
  }

  @override
  String writtenOffRate(String percent) {
    return 'مُسامَح $percent%';
  }

  @override
  String netForYou(String amount) {
    return 'الصافي لصالحك $amount';
  }

  @override
  String netForThem(String name, String amount) {
    return 'الصافي لصالح $name $amount';
  }

  @override
  String get netEven => 'الصافي متعادل';

  @override
  String get netInfoHint => 'معلومة فقط — لا يُخصم أحدهما من الآخر';

  @override
  String balanceAfter(String amount) {
    return 'الرصيد بعد العملية: $amount';
  }

  @override
  String get archivePerson => 'أرشفة الشخص';

  @override
  String get archivePersonBody =>
      'يختفي من القوائم والاختيار مع بقاء سجله كاملاً، ويمكن رفع أرشفته لاحقاً.';

  @override
  String get deletePerson => 'حذف الشخص';

  @override
  String get deletePersonBody => 'لا توجد له أي حركة، وسيُحذف نهائياً.';

  @override
  String get personArchivedBanner => 'هذا الشخص مؤرشف';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شخص',
      many: '$count شخصاً',
      few: '$count أشخاص',
      two: 'شخصان',
      one: 'شخص واحد',
      zero: 'لا أحد',
    );
    return '$_temp0';
  }

  @override
  String overdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دين متأخر',
      many: '$count ديناً متأخراً',
      few: '$count ديون متأخرة',
      two: 'دينان متأخران',
      one: 'دين متأخر',
      zero: 'لا ديون متأخرة',
    );
    return '$_temp0';
  }

  @override
  String get filterDebts => 'فلترة الديون';

  @override
  String get statusFilter => 'الحالة';

  @override
  String get sortNearestDue => 'الأقرب استحقاقاً';

  @override
  String get sortLastActivity => 'آخر حركة';

  @override
  String duplicatePerson(String name) {
    return '«$name» موجود، هل تقصده؟';
  }

  @override
  String get useExisting => 'نعم، هو';

  @override
  String get reconcileOk => 'معادلة التطابق الشاملة متحققة ✓';

  @override
  String reconcileGap(String amount) {
    return 'تنبيه: فرق $amount في معادلة التطابق — راجع البيانات';
  }

  @override
  String get archiveNeedsZero =>
      'لا يُؤرشف الحساب إلا ورصيده صفر — حوّل رصيده أولاً';

  @override
  String statementTitle(String name) {
    return 'كشف حساب — $name';
  }

  @override
  String get outputFormat => 'طريقة الإخراج';

  @override
  String get outputImage => 'صورة';

  @override
  String get outputImageHint => 'للكشف القصير';

  @override
  String get outputPdf => 'PDF';

  @override
  String get outputPdfHint => 'للكشف الطويل';

  @override
  String get preview => 'معاينة';

  @override
  String get whatsapp => 'واتساب';

  @override
  String get share => 'مشاركة';

  @override
  String get print => 'طباعة';

  @override
  String get closingBalance => 'المتبقي';

  @override
  String statementShareText(String name) {
    return 'كشف حساب $name — دفتري';
  }

  @override
  String get generatedAt => 'أُنشئ في';

  @override
  String get noMovementsInPeriod => 'لا توجد حركات في هذه الفترة';

  @override
  String get description => 'البيان';

  @override
  String get balance => 'الرصيد';

  @override
  String dueFromPerson(String name) {
    return 'المبلغ المستحق على $name';
  }

  @override
  String dueToPerson(String name) {
    return 'المبلغ المستحق لـ $name';
  }

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get income => 'الدخل';

  @override
  String get expense => 'المصروف';

  @override
  String get net => 'الصافي';

  @override
  String get incomeVsExpense => 'الدخل مقابل المصروف';

  @override
  String get expenseByCategory => 'المصروف حسب الفئة';

  @override
  String get incomeByCategory => 'الدخل حسب الفئة';

  @override
  String get reportsExcludedNote =>
      'حركات الديون والتسويات والتحويلات مستبعدة من هذه الأرقام.';

  @override
  String get monthlyView => 'شهري';

  @override
  String get yearlyView => 'سنوي';

  @override
  String get reportTitle => 'تقرير دفتري';

  @override
  String get month => 'الشهر';

  @override
  String get shareOfTotal => 'النسبة';

  @override
  String get transactions => 'المعاملات';

  @override
  String get type => 'النوع';

  @override
  String get export => 'تصدير';

  @override
  String get budgetTitle => 'الميزانية';

  @override
  String spentOfBudget(String month) {
    return 'مصروف $month من الميزانية';
  }

  @override
  String get addBudget => 'إضافة ميزانية';

  @override
  String get editBudget => 'تعديل الميزانية';

  @override
  String get budgetLimit => 'سقف الإنفاق الشهري';

  @override
  String alertAtPercent(String percent) {
    return 'التنبيه عند $percent%';
  }

  @override
  String budgetOverBy(String amount) {
    return 'تجاوزت الميزانية بـ $amount';
  }

  @override
  String get legendSafe => 'أقل من 75%';

  @override
  String get legendWarning => '75–99%';

  @override
  String get legendExceeded => 'تجاوز';

  @override
  String get noBudgets => 'لا توجد ميزانيات. أضف سقفاً لفئة لتتابع إنفاقك.';

  @override
  String get deleteBudget => 'حذف الميزانية';

  @override
  String get categoriesTitle => 'الفئات';

  @override
  String get addCategory => 'إضافة فئة';

  @override
  String get editCategory => 'تعديل الفئة';

  @override
  String get categoryName => 'اسم الفئة';

  @override
  String get icon => 'الأيقونة';

  @override
  String get color => 'اللون';

  @override
  String get expenseCategories => 'فئات المصروف';

  @override
  String get incomeCategories => 'فئات الدخل';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get sectionCurrency => 'العملة';

  @override
  String get appCurrencyLocked => 'عملة التطبيق (مقفلة)';

  @override
  String get addCurrency => 'إضافة عملة جديدة';

  @override
  String get sectionGeneral => 'عام';

  @override
  String get defaultAccount => 'الحساب الافتراضي';

  @override
  String get languageAndAppearance => 'اللغة والمظهر';

  @override
  String get language => 'اللغة';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get followDevice => 'حسب الجهاز';

  @override
  String get theme => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get arabicDigits => 'الأرقام الهندية (١٢٣)';

  @override
  String get sectionSecurityData => 'الأمان والبيانات';

  @override
  String get appLock => 'قفل التطبيق بالبصمة / PIN';

  @override
  String get cloudBackup => 'النسخ السحابي';

  @override
  String get localBackup => 'تصدير / استيراد ملف محلي';

  @override
  String get deleteAllData => 'حذف جميع البيانات';

  @override
  String get deleteAllDataBody =>
      'سيُحذف كل شيء نهائياً وتعود للإعداد الأول. هذه هي الطريقة الوحيدة لتغيير العملة.';

  @override
  String get sectionManage => 'الإدارة';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get contactSupport => 'تواصل مع فريق الدعم';

  @override
  String get supportWhatsApp => 'واتساب';

  @override
  String get supportCall => 'اتصال';

  @override
  String get supportInstagram => 'إنستغرام';

  @override
  String get linkOpenFailed => 'تعذّر فتح الرابط';

  @override
  String get developedBy => 'تم التطوير من قبل محمد المخلافي';

  @override
  String get lockedTitle => 'دفتري مقفل';

  @override
  String get enterPin => 'أدخل رمز PIN';

  @override
  String get wrongPin => 'رمز غير صحيح';

  @override
  String get useBiometrics => 'استخدام البصمة / الوجه';

  @override
  String get unlockReason => 'افتح دفتري';

  @override
  String get verifyIdentity => 'تأكيد هويتك';

  @override
  String get deleteAllDataReason => 'تأكيد حذف جميع البيانات';

  @override
  String get disableLockReason => 'تأكيد إيقاف قفل التطبيق';

  @override
  String get changePinReason => 'تأكيد تغيير رمز PIN';

  @override
  String get createPin => 'أنشئ رمز PIN من 4 أرقام';

  @override
  String get confirmPin => 'أعد إدخال الرمز للتأكيد';

  @override
  String get pinMismatch => 'الرمزان غير متطابقين';

  @override
  String get biometricUnlock => 'الفتح بالبصمة / الوجه';

  @override
  String get changePin => 'تغيير رمز PIN';

  @override
  String get lockAfterHint => 'يُقفل التطبيق بعد دقيقة من الخروج منه';

  @override
  String get backupTitle => 'النسخ الاحتياطي';

  @override
  String get cloudBackupOff => 'النسخ السحابي معطّل';

  @override
  String get cloudBackupOn => 'النسخ السحابي مفعّل';

  @override
  String get cloudBackupHint => 'بحسابك الشخصي، مشفّر، دون خوادم خاصة بالتطبيق';

  @override
  String get storageProvider => 'مزوّد التخزين (حسابك الشخصي)';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get iCloud => 'iCloud';

  @override
  String get appleDevicesOnly => 'لأجهزة Apple';

  @override
  String get connected => 'متصل';

  @override
  String get frequency => 'التكرار';

  @override
  String get daily => 'يومي';

  @override
  String get weekly => 'أسبوعي';

  @override
  String get monthly => 'شهري';

  @override
  String get wifiOnly => 'النسخ عبر Wi-Fi فقط';

  @override
  String get encryptionInfo => 'تشفير النسخة AES-256';

  @override
  String lastBackup(String date) {
    return 'آخر نسخة: $date';
  }

  @override
  String get neverBackedUp => 'لم تُنسخ بعد';

  @override
  String get backupNow => 'نسخ الآن';

  @override
  String get restore => 'استعادة';

  @override
  String get backupPassword => 'كلمة مرور التشفير';

  @override
  String get backupPasswordHint =>
      'تحتاجها لاستعادة النسخة على جهاز جديد. لا يمكن استرجاعها إن نسيتها.';

  @override
  String get backupDone => 'تم النسخ بنجاح';

  @override
  String get restoreDone => 'تمت الاستعادة بنجاح';

  @override
  String get restoreConfirm =>
      'ستُستبدل كل البيانات الحالية بمحتوى النسخة. متابعة؟';

  @override
  String get chooseBackup => 'اختر نسخة';

  @override
  String get exportLocalFile => 'تصدير ملف نسخة مشفّر';

  @override
  String get importLocalFile => 'استيراد ملف نسخة';

  @override
  String get noCloudBackups => 'لا توجد نسخ في السحابة';

  @override
  String get errInvalidAmount => 'أدخل مبلغاً أكبر من صفر';

  @override
  String get errEmptyName => 'الاسم مطلوب';

  @override
  String get errInvalidPhone => 'رقم الجوال غير صحيح';

  @override
  String get errContactArchived => 'الشخص مؤرشف — ارفع أرشفته أولاً';

  @override
  String get errInvalidDebtSource => 'مصدر الدين لا يناسب اتجاهه';

  @override
  String get errAccountRequired => 'اختر الحساب';

  @override
  String get errDateInFuture => 'التاريخ لا يكون بعد اليوم';

  @override
  String get errDueBeforeStart => 'تاريخ الاستحقاق قبل تاريخ الدين';

  @override
  String get errPaymentBeforeDebt =>
      'التاريخ يسبق تاريخ الدين — غيّره أو اختر ديناً معيّناً';

  @override
  String get errDebtHasMovements =>
      'على الدين دفعات أو مسامحة — ألغِ الدفعات أولاً';

  @override
  String get errPaymentAlreadyCancelled => 'العملية ملغاة مسبقاً';

  @override
  String get errAccountHasBalance =>
      'لا يُؤرشف الحساب إلا ورصيده صفر — حوّل رصيده أولاً';

  @override
  String get errPersonHasBalance =>
      'لا يُؤرشف الشخص إلا ومتبقّيه صفر في الاتجاهين';

  @override
  String get errPersonHasMovements => 'للشخص حركات مسجلة — يمكن أرشفته فقط';

  @override
  String get errDuplicateAccountName => 'يوجد حساب بنفس الاسم';

  @override
  String get errAccountArchived => 'الحساب مؤرشف — ارفع أرشفته أولاً';

  @override
  String get errCannotArchiveLast => 'لا يمكن أرشفة آخر حساب نشط';

  @override
  String get errMustChooseNewDefault => 'اختر حساباً افتراضياً بديلاً أولاً';

  @override
  String get errSameAccountTransfer => 'اختر حسابين مختلفين للتحويل';

  @override
  String get errCategoryKindMismatch => 'الفئة لا تناسب نوع المعاملة';

  @override
  String get errCategoryRequired => 'اختر فئة';

  @override
  String get errDebtMovementReadOnly => 'قيود الديون تُعدَّل من ملف الشخص';

  @override
  String get errCannotMoveArchived =>
      'لا يمكن نقل معاملة من حساب مؤرشف أو إليه';

  @override
  String errPaymentExceeds(String amount) {
    return 'المبلغ أكبر من المتبقي ($amount)';
  }

  @override
  String get errDebtSettled => 'لا توجد ديون مفتوحة لهذه العملية';

  @override
  String errDebtAmountBelowPaid(String amount) {
    return 'الأصل لا يقل عن المدفوع والمُسامَح ($amount)';
  }

  @override
  String get errCurrencyLocked => 'العملة مقفلة ولا يمكن تغييرها';

  @override
  String get errNotOnboarded => 'أكمل الإعداد الأول أولاً';

  @override
  String get errCategoryInUse => 'الفئة مستخدمة في معاملات ولا يمكن حذفها';

  @override
  String get errNotFound => 'العنصر غير موجود';

  @override
  String get errBackupDecryption => 'كلمة المرور خاطئة أو الملف تالف';

  @override
  String get errBackupInvalid => 'الملف ليس نسخة دفتري صالحة';

  @override
  String get errNoConnection => 'لا يوجد اتصال — سيُعاد المحاولة لاحقاً';

  @override
  String get errCloudNotAuthorized => 'لم يتم منح الإذن لحساب التخزين';

  @override
  String get errUnexpected => 'حدث خطأ غير متوقع';

  @override
  String get notifChannel => 'تذكير الديون';

  @override
  String get notifTitle => 'تذكير بدين';

  @override
  String notifOwedToMe(String amount, String name) {
    return 'غداً موعد استحقاق $amount على $name';
  }

  @override
  String notifIOwe(String amount, String name) {
    return 'غداً موعد سداد $amount لـ $name';
  }

  @override
  String get introSkip => 'تخطي';

  @override
  String get introNext => 'التالي';

  @override
  String get introStart => 'ابدأ الآن';

  @override
  String get intro1Body =>
      'دفتر حساباتك الشخصي وديونك في مكان واحد. يعمل بدون إنترنت وبدون تسجيل دخول، وبياناتك تبقى على جهازك.';

  @override
  String get introOffline => 'بدون إنترنت';

  @override
  String get introNoAccount => 'بدون حساب';

  @override
  String get introPrivate => 'خصوصية تامة';

  @override
  String get intro2Title => 'كل ما تحتاجه لإدارة أموالك';

  @override
  String get intro2Body => 'أدوات بسيطة وواضحة لكل يوم.';

  @override
  String get featTxTitle => 'المعاملات والحسابات';

  @override
  String get featTxBody => 'سجّل الدخل والمصروف والتحويل بين حساباتك';

  @override
  String get featDebtsTitle => 'الديون والتذكير';

  @override
  String get featDebtsBody => 'تابع ما لك وما عليك مع تذكير قبل الاستحقاق';

  @override
  String get featBudgetTitle => 'الميزانية والتقارير';

  @override
  String get featBudgetBody => 'حدود شهرية ورسوم بيانية وتصدير PDF و Excel';

  @override
  String get featStatementTitle => 'كشف حساب جاهز';

  @override
  String get featStatementBody => 'أرسل كشف حساب أي شخص عبر واتساب بضغطة';

  @override
  String get intro3Title => 'خطوات مهمة للبدء';

  @override
  String get intro3Body => 'ثلاث خطوات تحمي بياناتك من البداية.';

  @override
  String get stepCurrencyTitle => 'اختر عملتك بعناية';

  @override
  String get stepLockTitle => 'احمِ بياناتك';

  @override
  String get stepLockBody => 'فعّل قفل التطبيق بالبصمة أو رمز PIN من الإعدادات';

  @override
  String get stepBackupTitle => 'خذ نسخة احتياطية';

  @override
  String get stepBackupBody =>
      'صدّر نسخة مشفّرة أو فعّل النسخ السحابي لتنقل بياناتك بأمان';

  @override
  String get profileTitle => 'عرّفنا بنفسك';

  @override
  String get profileSubtitle =>
      'يظهر اسمك في التقارير وكشوف الحساب التي تشاركها.';

  @override
  String get yourName => 'اسمك';

  @override
  String get phoneOptional => 'رقم الجوال (اختياري)';

  @override
  String get sectionProfile => 'الملف الشخصي';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get addYourName => 'أضف اسمك';

  @override
  String get noPhone => 'بدون رقم جوال';

  @override
  String greetingName(String greeting, String name) {
    return '$greeting، $name';
  }

  @override
  String issuedBy(String name) {
    return 'صادر من: $name';
  }
}
