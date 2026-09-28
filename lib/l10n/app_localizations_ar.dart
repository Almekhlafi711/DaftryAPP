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
  String get address => 'العنوان';

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
  String get archiveWithoutTransfer => 'أرشفة دون تحويل';

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
  String get statusSettled => 'مسدَّد';

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
  String get moneyLeftAccount => 'هل خرج المبلغ من حساب؟';

  @override
  String get moneyEnteredAccount => 'هل دخل المبلغ إلى حساب؟';

  @override
  String get bookOnlyHint => 'أطفئه عند البيع أو الشراء بالآجل (دفتر فقط)';

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
      'ستُحذف كل دفعاته وحركاته وتعود الأرصدة كما كانت.';

  @override
  String get recordPayment => 'تسجيل دفعة';

  @override
  String paymentFor(String name) {
    return 'تسجيل دفعة — $name';
  }

  @override
  String remainingAmount(String amount) {
    return 'المتبقي: $amount';
  }

  @override
  String get paymentAmount => 'مبلغ الدفعة';

  @override
  String get fullRemaining => 'كامل المتبقي';

  @override
  String get receivedIntoAccount => 'استلمت المبلغ في حساب';

  @override
  String get paidFromAccount => 'دفعت المبلغ من حساب';

  @override
  String get suggestedCreationAccount => 'مقترح: حساب إنشاء الدين';

  @override
  String get savePayment => 'حفظ الدفعة';

  @override
  String get whichDebt => 'الدين';

  @override
  String profileOwedToMe(String name) {
    return 'المتبقي لي عند $name';
  }

  @override
  String profileIOwe(String name) {
    return 'المتبقي عليّ لـ $name';
  }

  @override
  String get profileSettled => 'لا يوجد متبقٍ — الحساب مسدَّد';

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
  String get paymentReceived => 'دفعة مستلمة';

  @override
  String get paymentMade => 'دفعة مدفوعة';

  @override
  String get newDebtEntry => 'دين جديد';

  @override
  String debtWithNote(String note) {
    return 'دين: $note';
  }

  @override
  String inAccount(String account) {
    return 'في $account';
  }

  @override
  String fromAccountName(String account) {
    return 'من $account';
  }

  @override
  String get withoutAccount => 'بدون حساب';

  @override
  String get editPerson => 'تعديل بيانات الشخص';

  @override
  String get hidePerson => 'إخفاء من القائمة';

  @override
  String get deletePayment => 'حذف الدفعة';

  @override
  String get deletePaymentBody =>
      'ستُعكس حركتها على الرصيد ويُعاد حساب حالة الدين.';

  @override
  String get searchPeople => 'ابحث عن شخص';

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
  String get errDebtMovementReadOnly => 'حركات الديون تُعدَّل من ملف الشخص';

  @override
  String get errCannotMoveArchived =>
      'لا يمكن نقل معاملة من حساب مؤرشف أو إليه';

  @override
  String errPaymentExceeds(String amount) {
    return 'المبلغ أكبر من المتبقي ($amount)';
  }

  @override
  String get errDebtSettled => 'هذا الدين مسدَّد بالكامل';

  @override
  String errDebtAmountBelowPaid(String amount) {
    return 'لا يمكن أن يقل المبلغ عن المسدَّد ($amount)';
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
}
