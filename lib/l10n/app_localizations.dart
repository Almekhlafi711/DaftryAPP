import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'دفتري'**
  String get appName;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @apply.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ضبط'**
  String get reset;

  /// No description provided for @undo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get undo;

  /// No description provided for @continueLabel.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueLabel;

  /// No description provided for @optional.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get optional;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get yesterday;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get saved;

  /// No description provided for @seeAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get seeAll;

  /// No description provided for @note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get note;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @amount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get amount;

  /// No description provided for @account.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get account;

  /// No description provided for @category.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get category;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال'**
  String get phone;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً'**
  String get comingSoon;

  /// No description provided for @archivedBadge.
  ///
  /// In ar, this message translates to:
  /// **'مؤرشف'**
  String get archivedBadge;

  /// No description provided for @defaultBadge.
  ///
  /// In ar, this message translates to:
  /// **'افتراضي'**
  String get defaultBadge;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get more;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'6 أحرف على الأقل'**
  String get passwordTooShort;

  /// No description provided for @areYouSure.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد؟'**
  String get areYouSure;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navTransactions.
  ///
  /// In ar, this message translates to:
  /// **'المعاملات'**
  String get navTransactions;

  /// No description provided for @navDebts.
  ///
  /// In ar, this message translates to:
  /// **'الديون'**
  String get navDebts;

  /// No description provided for @navMore.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get navMore;

  /// No description provided for @welcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في دفتري'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لا حساب • لا كلمة مرور • ابدأ فوراً'**
  String get welcomeSubtitle;

  /// No description provided for @chooseCurrency.
  ///
  /// In ar, this message translates to:
  /// **'اختر عملتك'**
  String get chooseCurrency;

  /// No description provided for @currencyWarning.
  ///
  /// In ar, this message translates to:
  /// **'ستُستخدم في كل التطبيق ولا يمكن تغييرها لاحقاً'**
  String get currencyWarning;

  /// No description provided for @searchCurrency.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن عملة'**
  String get searchCurrency;

  /// No description provided for @cloudBackupOptionalHint.
  ///
  /// In ar, this message translates to:
  /// **'اختياري — يمكن تفعيله لاحقاً من الإعدادات'**
  String get cloudBackupOptionalHint;

  /// No description provided for @confirmCurrencyTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد عملة التطبيق'**
  String get confirmCurrencyTitle;

  /// No description provided for @confirmCurrencyBody.
  ///
  /// In ar, this message translates to:
  /// **'ستُسجَّل كل الحسابات والمعاملات والديون بهذه العملة.'**
  String get confirmCurrencyBody;

  /// No description provided for @confirmCurrencyWarning.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تغييرها بعد التأكيد'**
  String get confirmCurrencyWarning;

  /// No description provided for @confirmAndStart.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد والبدء'**
  String get confirmAndStart;

  /// No description provided for @backAndChange.
  ///
  /// In ar, this message translates to:
  /// **'رجوع وتغيير العملة'**
  String get backAndChange;

  /// No description provided for @restoreExisting.
  ///
  /// In ar, this message translates to:
  /// **'لديك نسخة احتياطية؟ استعادة'**
  String get restoreExisting;

  /// No description provided for @greetingMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير'**
  String get greetingMorning;

  /// No description provided for @greetingEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير'**
  String get greetingEvening;

  /// No description provided for @totalBalance.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي أرصدة الحسابات'**
  String get totalBalance;

  /// No description provided for @monthIncome.
  ///
  /// In ar, this message translates to:
  /// **'دخل الشهر'**
  String get monthIncome;

  /// No description provided for @monthExpense.
  ///
  /// In ar, this message translates to:
  /// **'مصروف الشهر'**
  String get monthExpense;

  /// No description provided for @quickExpense.
  ///
  /// In ar, this message translates to:
  /// **'مصروف'**
  String get quickExpense;

  /// No description provided for @quickIncome.
  ///
  /// In ar, this message translates to:
  /// **'دخل'**
  String get quickIncome;

  /// No description provided for @quickTransfer.
  ///
  /// In ar, this message translates to:
  /// **'تحويل'**
  String get quickTransfer;

  /// No description provided for @quickDebt.
  ///
  /// In ar, this message translates to:
  /// **'دين'**
  String get quickDebt;

  /// No description provided for @monthlyBudget.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية الشهرية'**
  String get monthlyBudget;

  /// No description provided for @budgetOf.
  ///
  /// In ar, this message translates to:
  /// **'{spent} من {limit}'**
  String budgetOf(String spent, String limit);

  /// No description provided for @remainingForDays.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ {amount} لـ {days, plural, =0{اليوم} =1{يوم واحد} =2{يومين} few{{days} أيام} many{{days} يوماً} other{{days} يوم}}'**
  String remainingForDays(String amount, int days);

  /// No description provided for @owedToMe.
  ///
  /// In ar, this message translates to:
  /// **'لي عند الناس'**
  String get owedToMe;

  /// No description provided for @iOwe.
  ///
  /// In ar, this message translates to:
  /// **'عليّ للناس'**
  String get iOwe;

  /// No description provided for @recentTransactions.
  ///
  /// In ar, this message translates to:
  /// **'آخر المعاملات'**
  String get recentTransactions;

  /// No description provided for @noTransactionsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد معاملات بعد. اضغط + لإضافة أول معاملة.'**
  String get noTransactionsYet;

  /// No description provided for @hideBalances.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء الأرصدة'**
  String get hideBalances;

  /// No description provided for @transactionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المعاملات'**
  String get transactionsTitle;

  /// No description provided for @searchTransactions.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو المبلغ'**
  String get searchTransactions;

  /// No description provided for @addTransaction.
  ///
  /// In ar, this message translates to:
  /// **'إضافة معاملة'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In ar, this message translates to:
  /// **'تعديل معاملة'**
  String get editTransaction;

  /// No description provided for @typeExpense.
  ///
  /// In ar, this message translates to:
  /// **'مصروف'**
  String get typeExpense;

  /// No description provided for @typeIncome.
  ///
  /// In ar, this message translates to:
  /// **'دخل'**
  String get typeIncome;

  /// No description provided for @typeTransfer.
  ///
  /// In ar, this message translates to:
  /// **'تحويل'**
  String get typeTransfer;

  /// No description provided for @typeAdjustment.
  ///
  /// In ar, this message translates to:
  /// **'تسوية'**
  String get typeAdjustment;

  /// No description provided for @typeDebtOut.
  ///
  /// In ar, this message translates to:
  /// **'حركة دين — خرج'**
  String get typeDebtOut;

  /// No description provided for @typeDebtIn.
  ///
  /// In ar, this message translates to:
  /// **'حركة دين — دخل'**
  String get typeDebtIn;

  /// No description provided for @debtMovement.
  ///
  /// In ar, this message translates to:
  /// **'حركة دين'**
  String get debtMovement;

  /// No description provided for @fromAccount.
  ///
  /// In ar, this message translates to:
  /// **'من حساب'**
  String get fromAccount;

  /// No description provided for @toAccount.
  ///
  /// In ar, this message translates to:
  /// **'إلى حساب'**
  String get toAccount;

  /// No description provided for @suggestedForCategory.
  ///
  /// In ar, this message translates to:
  /// **'مقترح: آخر حساب للفئة'**
  String get suggestedForCategory;

  /// No description provided for @attachReceipt.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق إيصال'**
  String get attachReceipt;

  /// No description provided for @receiptAttached.
  ///
  /// In ar, this message translates to:
  /// **'تم إرفاق الإيصال'**
  String get receiptAttached;

  /// No description provided for @removeReceipt.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الإيصال'**
  String get removeReceipt;

  /// No description provided for @viewReceipt.
  ///
  /// In ar, this message translates to:
  /// **'عرض الإيصال'**
  String get viewReceipt;

  /// No description provided for @receiptCamera.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا'**
  String get receiptCamera;

  /// No description provided for @receiptGallery.
  ///
  /// In ar, this message translates to:
  /// **'المعرض'**
  String get receiptGallery;

  /// No description provided for @chooseCategory.
  ///
  /// In ar, this message translates to:
  /// **'اختر فئة'**
  String get chooseCategory;

  /// No description provided for @deleteTransactionTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف هذه المعاملة؟'**
  String get deleteTransactionTitle;

  /// No description provided for @deleteTransactionBody.
  ///
  /// In ar, this message translates to:
  /// **'{description} — {amount}\nسيُعاد المبلغ إلى رصيد «{account}» تلقائياً.'**
  String deleteTransactionBody(
    String description,
    String amount,
    String account,
  );

  /// No description provided for @transactionDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المعاملة'**
  String get transactionDeleted;

  /// No description provided for @debtMovementHint.
  ///
  /// In ar, this message translates to:
  /// **'حركة دين تحرّك الرصيد ولا تُحتسب دخلاً ولا مصروفاً. تُعدَّل من ملف الشخص.'**
  String get debtMovementHint;

  /// No description provided for @openPersonProfile.
  ///
  /// In ar, this message translates to:
  /// **'فتح ملف الشخص'**
  String get openPersonProfile;

  /// No description provided for @budgetWarning.
  ///
  /// In ar, this message translates to:
  /// **'اقتربت من ميزانية «{category}»: {percent}%'**
  String budgetWarning(String category, String percent);

  /// No description provided for @budgetExceeded.
  ///
  /// In ar, this message translates to:
  /// **'تجاوزت ميزانية «{category}» ({percent}%)'**
  String budgetExceeded(String category, String percent);

  /// No description provided for @filterTitle.
  ///
  /// In ar, this message translates to:
  /// **'فلترة المعاملات'**
  String get filterTitle;

  /// No description provided for @period.
  ///
  /// In ar, this message translates to:
  /// **'الفترة'**
  String get period;

  /// No description provided for @periodToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get periodMonth;

  /// No description provided for @periodLast30.
  ///
  /// In ar, this message translates to:
  /// **'آخر 30 يوماً'**
  String get periodLast30;

  /// No description provided for @periodLast3Months.
  ///
  /// In ar, this message translates to:
  /// **'آخر 3 أشهر'**
  String get periodLast3Months;

  /// No description provided for @periodYear.
  ///
  /// In ar, this message translates to:
  /// **'هذه السنة'**
  String get periodYear;

  /// No description provided for @periodCustom.
  ///
  /// In ar, this message translates to:
  /// **'مخصص'**
  String get periodCustom;

  /// No description provided for @periodAll.
  ///
  /// In ar, this message translates to:
  /// **'كل الفترات'**
  String get periodAll;

  /// No description provided for @typeAndCategory.
  ///
  /// In ar, this message translates to:
  /// **'النوع والفئة'**
  String get typeAndCategory;

  /// No description provided for @showDebtMovements.
  ///
  /// In ar, this message translates to:
  /// **'إظهار حركات الديون'**
  String get showDebtMovements;

  /// No description provided for @showDebtMovementsHint.
  ///
  /// In ar, this message translates to:
  /// **'تظهر في السجل فقط ولا تدخل في الدخل والمصروف'**
  String get showDebtMovementsHint;

  /// No description provided for @sort.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get sort;

  /// No description provided for @sortNewest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث أولاً'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In ar, this message translates to:
  /// **'الأقدم أولاً'**
  String get sortOldest;

  /// No description provided for @sortAmountDesc.
  ///
  /// In ar, this message translates to:
  /// **'الأعلى مبلغاً'**
  String get sortAmountDesc;

  /// No description provided for @sortAmountAsc.
  ///
  /// In ar, this message translates to:
  /// **'الأقل مبلغاً'**
  String get sortAmountAsc;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'كل الفئات'**
  String get allCategories;

  /// No description provided for @summaryIncome.
  ///
  /// In ar, this message translates to:
  /// **'دخل {amount}'**
  String summaryIncome(String amount);

  /// No description provided for @summaryExpense.
  ///
  /// In ar, this message translates to:
  /// **'مصروف {amount}'**
  String summaryExpense(String amount);

  /// No description provided for @accountsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات'**
  String get accountsTitle;

  /// No description provided for @totalActiveAccounts.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الحسابات النشطة'**
  String get totalActiveAccounts;

  /// No description provided for @activeAccountsCount.
  ///
  /// In ar, this message translates to:
  /// **'نشطة ({count})'**
  String activeAccountsCount(String count);

  /// No description provided for @archivedAccountsCount.
  ///
  /// In ar, this message translates to:
  /// **'المؤرشفة ({count})'**
  String archivedAccountsCount(String count);

  /// No description provided for @archivedSince.
  ///
  /// In ar, this message translates to:
  /// **'مؤرشف منذ {date}'**
  String archivedSince(String date);

  /// No description provided for @addAccount.
  ///
  /// In ar, this message translates to:
  /// **'إضافة حساب'**
  String get addAccount;

  /// No description provided for @editAccount.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الحساب'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الحساب'**
  String get accountName;

  /// No description provided for @accountType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب'**
  String get accountType;

  /// No description provided for @openingBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد الافتتاحي'**
  String get openingBalance;

  /// No description provided for @accountTypeCash.
  ///
  /// In ar, this message translates to:
  /// **'نقدي'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In ar, this message translates to:
  /// **'بنكي'**
  String get accountTypeBank;

  /// No description provided for @accountTypeWallet.
  ///
  /// In ar, this message translates to:
  /// **'محفظة'**
  String get accountTypeWallet;

  /// No description provided for @accountTypeSavings.
  ///
  /// In ar, this message translates to:
  /// **'توفير'**
  String get accountTypeSavings;

  /// No description provided for @setAsDefault.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كافتراضي'**
  String get setAsDefault;

  /// No description provided for @archive.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In ar, this message translates to:
  /// **'رفع الأرشفة'**
  String get unarchive;

  /// No description provided for @adjustBalance.
  ///
  /// In ar, this message translates to:
  /// **'تسوية الرصيد'**
  String get adjustBalance;

  /// No description provided for @adjustBalanceHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرصيد الفعلي وسيُسجَّل الفرق كمعاملة «تسوية» في السجل.'**
  String get adjustBalanceHint;

  /// No description provided for @actualBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد الفعلي'**
  String get actualBalance;

  /// No description provided for @archiveTitle.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة «{name}»؟'**
  String archiveTitle(String name);

  /// No description provided for @archiveBody.
  ///
  /// In ar, this message translates to:
  /// **'لن يظهر في الرئيسية ولا عند إضافة معاملة أو دين جديد. المعاملات السابقة تبقى كما هي وتظهر في التقارير.'**
  String get archiveBody;

  /// No description provided for @archiveHasBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيده الحالي {amount}'**
  String archiveHasBalance(String amount);

  /// No description provided for @transferBalanceTo.
  ///
  /// In ar, this message translates to:
  /// **'تحويل الرصيد إلى'**
  String get transferBalanceTo;

  /// No description provided for @transferAndArchive.
  ///
  /// In ar, this message translates to:
  /// **'تحويل الرصيد ثم الأرشفة'**
  String get transferAndArchive;

  /// No description provided for @newDefaultAccount.
  ///
  /// In ar, this message translates to:
  /// **'الحساب الافتراضي البديل'**
  String get newDefaultAccount;

  /// No description provided for @recalculateBalances.
  ///
  /// In ar, this message translates to:
  /// **'إعادة احتساب الأرصدة'**
  String get recalculateBalances;

  /// No description provided for @recalculateDone.
  ///
  /// In ar, this message translates to:
  /// **'تمت المراجعة — صُحح {count} حساب'**
  String recalculateDone(String count);

  /// No description provided for @debtsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الديون'**
  String get debtsTitle;

  /// No description provided for @debtsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'منفصلة عن الدخل والمصروف'**
  String get debtsSubtitle;

  /// No description provided for @tabOwedToMe.
  ///
  /// In ar, this message translates to:
  /// **'لي'**
  String get tabOwedToMe;

  /// No description provided for @tabIOwe.
  ///
  /// In ar, this message translates to:
  /// **'عليّ'**
  String get tabIOwe;

  /// No description provided for @newDebt.
  ///
  /// In ar, this message translates to:
  /// **'دين جديد'**
  String get newDebt;

  /// No description provided for @dueInDays.
  ///
  /// In ar, this message translates to:
  /// **'يستحق بعد {days, plural, =1{يوم} =2{يومين} few{{days} أيام} many{{days} يوماً} other{{days} يوم}}'**
  String dueInDays(int days);

  /// No description provided for @overdueDays.
  ///
  /// In ar, this message translates to:
  /// **'متأخر {days, plural, =1{يوماً} =2{يومين} few{{days} أيام} many{{days} يوماً} other{{days} يوم}}'**
  String overdueDays(int days);

  /// No description provided for @dueToday.
  ///
  /// In ar, this message translates to:
  /// **'يستحق اليوم'**
  String get dueToday;

  /// No description provided for @statusClosed.
  ///
  /// In ar, this message translates to:
  /// **'مغلق'**
  String get statusClosed;

  /// No description provided for @statusOverdue.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get statusOverdue;

  /// No description provided for @statusPartial.
  ///
  /// In ar, this message translates to:
  /// **'مسدَّد جزئياً'**
  String get statusPartial;

  /// No description provided for @statusOpen.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get statusOpen;

  /// No description provided for @ofTotal.
  ///
  /// In ar, this message translates to:
  /// **'من {amount}'**
  String ofTotal(String amount);

  /// No description provided for @noDebts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ديون مسجلة. سجّل ديناً لتتابع ما لك وما عليك.'**
  String get noDebts;

  /// No description provided for @directionOwedToMeHint.
  ///
  /// In ar, this message translates to:
  /// **'أقرضت / بعت بالآجل'**
  String get directionOwedToMeHint;

  /// No description provided for @directionIOweHint.
  ///
  /// In ar, this message translates to:
  /// **'اقترضت / اشتريت بالآجل'**
  String get directionIOweHint;

  /// No description provided for @person.
  ///
  /// In ar, this message translates to:
  /// **'الشخص'**
  String get person;

  /// No description provided for @choosePerson.
  ///
  /// In ar, this message translates to:
  /// **'اختر شخصاً'**
  String get choosePerson;

  /// No description provided for @fromContacts.
  ///
  /// In ar, this message translates to:
  /// **'من جهات الاتصال'**
  String get fromContacts;

  /// No description provided for @addPerson.
  ///
  /// In ar, this message translates to:
  /// **'إضافة شخص'**
  String get addPerson;

  /// No description provided for @dueDateOptional.
  ///
  /// In ar, this message translates to:
  /// **'الاستحقاق (اختياري)'**
  String get dueDateOptional;

  /// No description provided for @decreasesBalanceNotExpense.
  ///
  /// In ar, this message translates to:
  /// **'ينقص الرصيد — ليس مصروفاً'**
  String get decreasesBalanceNotExpense;

  /// No description provided for @increasesBalanceNotIncome.
  ///
  /// In ar, this message translates to:
  /// **'يزيد الرصيد — ليس دخلاً'**
  String get increasesBalanceNotIncome;

  /// No description provided for @remindBeforeDue.
  ///
  /// In ar, this message translates to:
  /// **'ذكّرني قبل الموعد بيوم'**
  String get remindBeforeDue;

  /// No description provided for @saveDebt.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الدين'**
  String get saveDebt;

  /// No description provided for @editDebt.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الدين'**
  String get editDebt;

  /// No description provided for @deleteDebt.
  ///
  /// In ar, this message translates to:
  /// **'حذف الدين'**
  String get deleteDebt;

  /// No description provided for @deleteDebtBody.
  ///
  /// In ar, this message translates to:
  /// **'يُحذف الدين مع قيده فيعود الحساب أو الدخل أو المصروف كما كان. (للديون المسجلة خطأً فقط.)'**
  String get deleteDebtBody;

  /// No description provided for @remainingAmount.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي: {amount}'**
  String remainingAmount(String amount);

  /// No description provided for @fullRemaining.
  ///
  /// In ar, this message translates to:
  /// **'كامل المتبقي'**
  String get fullRemaining;

  /// No description provided for @receivedIntoAccount.
  ///
  /// In ar, this message translates to:
  /// **'استلمتُ المبلغ في'**
  String get receivedIntoAccount;

  /// No description provided for @paidFromAccount.
  ///
  /// In ar, this message translates to:
  /// **'دفعتُ المبلغ من'**
  String get paidFromAccount;

  /// No description provided for @profileOwedToMe.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي لي عند {name}'**
  String profileOwedToMe(String name);

  /// No description provided for @profileIOwe.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي عليّ لـ {name}'**
  String profileIOwe(String name);

  /// No description provided for @paidAmount.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع {amount}'**
  String paidAmount(String amount);

  /// No description provided for @totalDebtsAmount.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الديون {amount}'**
  String totalDebtsAmount(String amount);

  /// No description provided for @dueOn.
  ///
  /// In ar, this message translates to:
  /// **'يستحق {date}'**
  String dueOn(String date);

  /// No description provided for @statement.
  ///
  /// In ar, this message translates to:
  /// **'كشف'**
  String get statement;

  /// No description provided for @timeline.
  ///
  /// In ar, this message translates to:
  /// **'الخط الزمني'**
  String get timeline;

  /// No description provided for @paymentReceived.
  ///
  /// In ar, this message translates to:
  /// **'استلام'**
  String get paymentReceived;

  /// No description provided for @paymentMade.
  ///
  /// In ar, this message translates to:
  /// **'سداد'**
  String get paymentMade;

  /// No description provided for @editPerson.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات الشخص'**
  String get editPerson;

  /// No description provided for @searchPeople.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن شخص'**
  String get searchPeople;

  /// No description provided for @sourceTitle.
  ///
  /// In ar, this message translates to:
  /// **'مصدر الدين'**
  String get sourceTitle;

  /// No description provided for @sourceLoanOwed.
  ///
  /// In ar, this message translates to:
  /// **'أقرضته من حساب'**
  String get sourceLoanOwed;

  /// No description provided for @sourceLoanOwe.
  ///
  /// In ar, this message translates to:
  /// **'اقترضتُ إلى حساب'**
  String get sourceLoanOwe;

  /// No description provided for @sourceCreditSale.
  ///
  /// In ar, this message translates to:
  /// **'بعتُ له بالآجل'**
  String get sourceCreditSale;

  /// No description provided for @sourceCreditPurchase.
  ///
  /// In ar, this message translates to:
  /// **'اشتريتُ بالآجل'**
  String get sourceCreditPurchase;

  /// No description provided for @sourceOpening.
  ///
  /// In ar, this message translates to:
  /// **'دين سابق (قبل استخدام التطبيق)'**
  String get sourceOpening;

  /// No description provided for @sourceCreditSaleHint.
  ///
  /// In ar, this message translates to:
  /// **'يُسجَّل دخلاً بفئة — دون حركة حساب'**
  String get sourceCreditSaleHint;

  /// No description provided for @sourceCreditPurchaseHint.
  ///
  /// In ar, this message translates to:
  /// **'يُسجَّل مصروفاً بفئة — دون حركة حساب'**
  String get sourceCreditPurchaseHint;

  /// No description provided for @sourceOpeningHint.
  ///
  /// In ar, this message translates to:
  /// **'في الدفتر فقط — لا دخل ولا حركة حساب'**
  String get sourceOpeningHint;

  /// No description provided for @labelLoanOwed.
  ///
  /// In ar, this message translates to:
  /// **'سلفة نقدية'**
  String get labelLoanOwed;

  /// No description provided for @labelLoanOwe.
  ///
  /// In ar, this message translates to:
  /// **'اقتراض'**
  String get labelLoanOwe;

  /// No description provided for @labelCreditSale.
  ///
  /// In ar, this message translates to:
  /// **'بيع بالآجل'**
  String get labelCreditSale;

  /// No description provided for @labelCreditPurchase.
  ///
  /// In ar, this message translates to:
  /// **'شراء بالآجل'**
  String get labelCreditPurchase;

  /// No description provided for @labelOpening.
  ///
  /// In ar, this message translates to:
  /// **'دين سابق'**
  String get labelOpening;

  /// No description provided for @debtLockedHint.
  ///
  /// In ar, this message translates to:
  /// **'عليه دفعات أو مسامحة: الاتجاه والمصدر والشخص مقفلة'**
  String get debtLockedHint;

  /// No description provided for @receiveAmount.
  ///
  /// In ar, this message translates to:
  /// **'استلام مبلغ'**
  String get receiveAmount;

  /// No description provided for @payAmount.
  ///
  /// In ar, this message translates to:
  /// **'سداد مبلغ'**
  String get payAmount;

  /// No description provided for @receiveFrom.
  ///
  /// In ar, this message translates to:
  /// **'استلام من {name}'**
  String receiveFrom(String name);

  /// No description provided for @payTo.
  ///
  /// In ar, this message translates to:
  /// **'سداد لـ {name}'**
  String payTo(String name);

  /// No description provided for @remainingAfterPayment.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي بعد الدفعة: {amount}'**
  String remainingAfterPayment(String amount);

  /// No description provided for @distributedOldestFirst.
  ///
  /// In ar, this message translates to:
  /// **'يُوزَّع على الأقدم أولاً: {parts}'**
  String distributedOldestFirst(String parts);

  /// No description provided for @chooseSpecificDebt.
  ///
  /// In ar, this message translates to:
  /// **'اختيار دين معيّن'**
  String get chooseSpecificDebt;

  /// No description provided for @autoDistribute.
  ///
  /// In ar, this message translates to:
  /// **'توزيع تلقائي'**
  String get autoDistribute;

  /// No description provided for @excessTitle.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ زائد عن المتبقي'**
  String get excessTitle;

  /// No description provided for @excessOwedToMe.
  ///
  /// In ar, this message translates to:
  /// **'الزائد {amount} — هل تسجّله ديناً عليك لـ {name}؟'**
  String excessOwedToMe(String amount, String name);

  /// No description provided for @excessIOwe.
  ///
  /// In ar, this message translates to:
  /// **'الزائد {amount} — هل تسجّله ديناً لك على {name}؟'**
  String excessIOwe(String amount, String name);

  /// No description provided for @recordExcess.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الزائد'**
  String get recordExcess;

  /// No description provided for @editAmount.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المبلغ'**
  String get editAmount;

  /// No description provided for @excessNote.
  ///
  /// In ar, this message translates to:
  /// **'زيادة عن المستحق'**
  String get excessNote;

  /// No description provided for @noOneOwesYou.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ديون مفتوحة لك عند أحد'**
  String get noOneOwesYou;

  /// No description provided for @youOweNoOne.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ديون مفتوحة عليك'**
  String get youOweNoOne;

  /// No description provided for @distribution.
  ///
  /// In ar, this message translates to:
  /// **'تفصيل التوزيع'**
  String get distribution;

  /// No description provided for @cancelOperation.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء العملية'**
  String get cancelOperation;

  /// No description provided for @cancelOperationBody.
  ///
  /// In ar, this message translates to:
  /// **'تُلغى كل دفعات العملية معاً ويُعكس أثرها على الحساب، وتبقى ظاهرة مشطوبة في الخط الزمني.'**
  String get cancelOperationBody;

  /// No description provided for @cancelledBadge.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get cancelledBadge;

  /// No description provided for @negativeCashWarning.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه: رصيد «{account}» أصبح سالباً'**
  String negativeCashWarning(String account);

  /// No description provided for @forgiveRemaining.
  ///
  /// In ar, this message translates to:
  /// **'مسامحة بالمتبقي'**
  String get forgiveRemaining;

  /// No description provided for @forgivenRemaining.
  ///
  /// In ar, this message translates to:
  /// **'إعفاء من المتبقي'**
  String get forgivenRemaining;

  /// No description provided for @forgiveBodyOwedToMe.
  ///
  /// In ar, this message translates to:
  /// **'يُغلق الدين ويُسجَّل المتبقي {amount} مصروفاً بفئة «مسامحة ديون». لا تتحرك أرصدة الحسابات.'**
  String forgiveBodyOwedToMe(String amount);

  /// No description provided for @forgiveBodyIOwe.
  ///
  /// In ar, this message translates to:
  /// **'يُغلق الدين ويُسجَّل المتبقي {amount} دخلاً بفئة «إعفاء دين». لا تتحرك أرصدة الحسابات.'**
  String forgiveBodyIOwe(String amount);

  /// No description provided for @writeOffEntry.
  ///
  /// In ar, this message translates to:
  /// **'مسامحة'**
  String get writeOffEntry;

  /// No description provided for @forgivenEntry.
  ///
  /// In ar, this message translates to:
  /// **'إعفاء من الدين'**
  String get forgivenEntry;

  /// No description provided for @paymentRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة السداد {percent}%'**
  String paymentRate(String percent);

  /// No description provided for @writtenOffRate.
  ///
  /// In ar, this message translates to:
  /// **'مُسامَح {percent}%'**
  String writtenOffRate(String percent);

  /// No description provided for @netForYou.
  ///
  /// In ar, this message translates to:
  /// **'الصافي لصالحك {amount}'**
  String netForYou(String amount);

  /// No description provided for @netForThem.
  ///
  /// In ar, this message translates to:
  /// **'الصافي لصالح {name} {amount}'**
  String netForThem(String name, String amount);

  /// No description provided for @netEven.
  ///
  /// In ar, this message translates to:
  /// **'الصافي متعادل'**
  String get netEven;

  /// No description provided for @netInfoHint.
  ///
  /// In ar, this message translates to:
  /// **'معلومة فقط — لا يُخصم أحدهما من الآخر'**
  String get netInfoHint;

  /// No description provided for @balanceAfter.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد بعد العملية: {amount}'**
  String balanceAfter(String amount);

  /// No description provided for @archivePerson.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة الشخص'**
  String get archivePerson;

  /// No description provided for @archivePersonBody.
  ///
  /// In ar, this message translates to:
  /// **'يختفي من القوائم والاختيار مع بقاء سجله كاملاً، ويمكن رفع أرشفته لاحقاً.'**
  String get archivePersonBody;

  /// No description provided for @deletePerson.
  ///
  /// In ar, this message translates to:
  /// **'حذف الشخص'**
  String get deletePerson;

  /// No description provided for @deletePersonBody.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد له أي حركة، وسيُحذف نهائياً.'**
  String get deletePersonBody;

  /// No description provided for @personArchivedBanner.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشخص مؤرشف'**
  String get personArchivedBanner;

  /// No description provided for @peopleCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا أحد} =1{شخص واحد} =2{شخصان} few{{count} أشخاص} many{{count} شخصاً} other{{count} شخص}}'**
  String peopleCount(int count);

  /// No description provided for @overdueCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا ديون متأخرة} =1{دين متأخر} =2{دينان متأخران} few{{count} ديون متأخرة} many{{count} ديناً متأخراً} other{{count} دين متأخر}}'**
  String overdueCount(int count);

  /// No description provided for @filterDebts.
  ///
  /// In ar, this message translates to:
  /// **'فلترة الديون'**
  String get filterDebts;

  /// No description provided for @statusFilter.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get statusFilter;

  /// No description provided for @sortNearestDue.
  ///
  /// In ar, this message translates to:
  /// **'الأقرب استحقاقاً'**
  String get sortNearestDue;

  /// No description provided for @sortLastActivity.
  ///
  /// In ar, this message translates to:
  /// **'آخر حركة'**
  String get sortLastActivity;

  /// No description provided for @duplicatePerson.
  ///
  /// In ar, this message translates to:
  /// **'«{name}» موجود، هل تقصده؟'**
  String duplicatePerson(String name);

  /// No description provided for @useExisting.
  ///
  /// In ar, this message translates to:
  /// **'نعم، هو'**
  String get useExisting;

  /// No description provided for @reconcileOk.
  ///
  /// In ar, this message translates to:
  /// **'معادلة التطابق الشاملة متحققة ✓'**
  String get reconcileOk;

  /// No description provided for @reconcileGap.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه: فرق {amount} في معادلة التطابق — راجع البيانات'**
  String reconcileGap(String amount);

  /// No description provided for @archiveNeedsZero.
  ///
  /// In ar, this message translates to:
  /// **'لا يُؤرشف الحساب إلا ورصيده صفر — حوّل رصيده أولاً'**
  String get archiveNeedsZero;

  /// No description provided for @statementTitle.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب — {name}'**
  String statementTitle(String name);

  /// No description provided for @outputFormat.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الإخراج'**
  String get outputFormat;

  /// No description provided for @outputImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get outputImage;

  /// No description provided for @outputImageHint.
  ///
  /// In ar, this message translates to:
  /// **'للكشف القصير'**
  String get outputImageHint;

  /// No description provided for @outputPdf.
  ///
  /// In ar, this message translates to:
  /// **'PDF'**
  String get outputPdf;

  /// No description provided for @outputPdfHint.
  ///
  /// In ar, this message translates to:
  /// **'للكشف الطويل'**
  String get outputPdfHint;

  /// No description provided for @preview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get preview;

  /// No description provided for @whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get whatsapp;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @print.
  ///
  /// In ar, this message translates to:
  /// **'طباعة'**
  String get print;

  /// No description provided for @closingBalance.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي'**
  String get closingBalance;

  /// No description provided for @statementShareText.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب {name} — دفتري'**
  String statementShareText(String name);

  /// No description provided for @generatedAt.
  ///
  /// In ar, this message translates to:
  /// **'أُنشئ في'**
  String get generatedAt;

  /// No description provided for @noMovementsInPeriod.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حركات في هذه الفترة'**
  String get noMovementsInPeriod;

  /// No description provided for @description.
  ///
  /// In ar, this message translates to:
  /// **'البيان'**
  String get description;

  /// No description provided for @balance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد'**
  String get balance;

  /// No description provided for @dueFromPerson.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المستحق على {name}'**
  String dueFromPerson(String name);

  /// No description provided for @dueToPerson.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المستحق لـ {name}'**
  String dueToPerson(String name);

  /// No description provided for @reportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reportsTitle;

  /// No description provided for @income.
  ///
  /// In ar, this message translates to:
  /// **'الدخل'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In ar, this message translates to:
  /// **'المصروف'**
  String get expense;

  /// No description provided for @net.
  ///
  /// In ar, this message translates to:
  /// **'الصافي'**
  String get net;

  /// No description provided for @incomeVsExpense.
  ///
  /// In ar, this message translates to:
  /// **'الدخل مقابل المصروف'**
  String get incomeVsExpense;

  /// No description provided for @expenseByCategory.
  ///
  /// In ar, this message translates to:
  /// **'المصروف حسب الفئة'**
  String get expenseByCategory;

  /// No description provided for @incomeByCategory.
  ///
  /// In ar, this message translates to:
  /// **'الدخل حسب الفئة'**
  String get incomeByCategory;

  /// No description provided for @reportsExcludedNote.
  ///
  /// In ar, this message translates to:
  /// **'حركات الديون والتسويات والتحويلات مستبعدة من هذه الأرقام.'**
  String get reportsExcludedNote;

  /// No description provided for @monthlyView.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get monthlyView;

  /// No description provided for @yearlyView.
  ///
  /// In ar, this message translates to:
  /// **'سنوي'**
  String get yearlyView;

  /// No description provided for @reportTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقرير دفتري'**
  String get reportTitle;

  /// No description provided for @month.
  ///
  /// In ar, this message translates to:
  /// **'الشهر'**
  String get month;

  /// No description provided for @shareOfTotal.
  ///
  /// In ar, this message translates to:
  /// **'النسبة'**
  String get shareOfTotal;

  /// No description provided for @transactions.
  ///
  /// In ar, this message translates to:
  /// **'المعاملات'**
  String get transactions;

  /// No description provided for @type.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get type;

  /// No description provided for @export.
  ///
  /// In ar, this message translates to:
  /// **'تصدير'**
  String get export;

  /// No description provided for @budgetTitle.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية'**
  String get budgetTitle;

  /// No description provided for @spentOfBudget.
  ///
  /// In ar, this message translates to:
  /// **'مصروف {month} من الميزانية'**
  String spentOfBudget(String month);

  /// No description provided for @addBudget.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ميزانية'**
  String get addBudget;

  /// No description provided for @editBudget.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الميزانية'**
  String get editBudget;

  /// No description provided for @budgetLimit.
  ///
  /// In ar, this message translates to:
  /// **'سقف الإنفاق الشهري'**
  String get budgetLimit;

  /// No description provided for @alertAtPercent.
  ///
  /// In ar, this message translates to:
  /// **'التنبيه عند {percent}%'**
  String alertAtPercent(String percent);

  /// No description provided for @budgetOverBy.
  ///
  /// In ar, this message translates to:
  /// **'تجاوزت الميزانية بـ {amount}'**
  String budgetOverBy(String amount);

  /// No description provided for @legendSafe.
  ///
  /// In ar, this message translates to:
  /// **'أقل من 75%'**
  String get legendSafe;

  /// No description provided for @legendWarning.
  ///
  /// In ar, this message translates to:
  /// **'75–99%'**
  String get legendWarning;

  /// No description provided for @legendExceeded.
  ///
  /// In ar, this message translates to:
  /// **'تجاوز'**
  String get legendExceeded;

  /// No description provided for @noBudgets.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ميزانيات. أضف سقفاً لفئة لتتابع إنفاقك.'**
  String get noBudgets;

  /// No description provided for @deleteBudget.
  ///
  /// In ar, this message translates to:
  /// **'حذف الميزانية'**
  String get deleteBudget;

  /// No description provided for @categoriesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفئات'**
  String get categoriesTitle;

  /// No description provided for @addCategory.
  ///
  /// In ar, this message translates to:
  /// **'إضافة فئة'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الفئة'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الفئة'**
  String get categoryName;

  /// No description provided for @icon.
  ///
  /// In ar, this message translates to:
  /// **'الأيقونة'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In ar, this message translates to:
  /// **'اللون'**
  String get color;

  /// No description provided for @expenseCategories.
  ///
  /// In ar, this message translates to:
  /// **'فئات المصروف'**
  String get expenseCategories;

  /// No description provided for @incomeCategories.
  ///
  /// In ar, this message translates to:
  /// **'فئات الدخل'**
  String get incomeCategories;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @sectionCurrency.
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get sectionCurrency;

  /// No description provided for @appCurrencyLocked.
  ///
  /// In ar, this message translates to:
  /// **'عملة التطبيق (مقفلة)'**
  String get appCurrencyLocked;

  /// No description provided for @addCurrency.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عملة جديدة'**
  String get addCurrency;

  /// No description provided for @sectionGeneral.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get sectionGeneral;

  /// No description provided for @defaultAccount.
  ///
  /// In ar, this message translates to:
  /// **'الحساب الافتراضي'**
  String get defaultAccount;

  /// No description provided for @languageAndAppearance.
  ///
  /// In ar, this message translates to:
  /// **'اللغة والمظهر'**
  String get languageAndAppearance;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @followDevice.
  ///
  /// In ar, this message translates to:
  /// **'حسب الجهاز'**
  String get followDevice;

  /// No description provided for @theme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @arabicDigits.
  ///
  /// In ar, this message translates to:
  /// **'الأرقام الهندية (١٢٣)'**
  String get arabicDigits;

  /// No description provided for @sectionSecurityData.
  ///
  /// In ar, this message translates to:
  /// **'الأمان والبيانات'**
  String get sectionSecurityData;

  /// No description provided for @appLock.
  ///
  /// In ar, this message translates to:
  /// **'قفل التطبيق بالبصمة / PIN'**
  String get appLock;

  /// No description provided for @cloudBackup.
  ///
  /// In ar, this message translates to:
  /// **'النسخ السحابي'**
  String get cloudBackup;

  /// No description provided for @localBackup.
  ///
  /// In ar, this message translates to:
  /// **'تصدير / استيراد ملف محلي'**
  String get localBackup;

  /// No description provided for @deleteAllData.
  ///
  /// In ar, this message translates to:
  /// **'حذف جميع البيانات'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataBody.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف كل شيء نهائياً وتعود للإعداد الأول. هذه هي الطريقة الوحيدة لتغيير العملة.'**
  String get deleteAllDataBody;

  /// No description provided for @sectionManage.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get sectionManage;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String version(String version);

  /// No description provided for @contactSupport.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع فريق الدعم'**
  String get contactSupport;

  /// No description provided for @supportWhatsApp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get supportWhatsApp;

  /// No description provided for @supportCall.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get supportCall;

  /// No description provided for @supportInstagram.
  ///
  /// In ar, this message translates to:
  /// **'إنستغرام'**
  String get supportInstagram;

  /// No description provided for @linkOpenFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الرابط'**
  String get linkOpenFailed;

  /// No description provided for @developedBy.
  ///
  /// In ar, this message translates to:
  /// **'تم التطوير من قبل محمد المخلافي'**
  String get developedBy;

  /// No description provided for @lockedTitle.
  ///
  /// In ar, this message translates to:
  /// **'دفتري مقفل'**
  String get lockedTitle;

  /// No description provided for @enterPin.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز PIN'**
  String get enterPin;

  /// No description provided for @wrongPin.
  ///
  /// In ar, this message translates to:
  /// **'رمز غير صحيح'**
  String get wrongPin;

  /// No description provided for @useBiometrics.
  ///
  /// In ar, this message translates to:
  /// **'استخدام البصمة / الوجه'**
  String get useBiometrics;

  /// No description provided for @unlockReason.
  ///
  /// In ar, this message translates to:
  /// **'افتح دفتري'**
  String get unlockReason;

  /// No description provided for @verifyIdentity.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد هويتك'**
  String get verifyIdentity;

  /// No description provided for @deleteAllDataReason.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد حذف جميع البيانات'**
  String get deleteAllDataReason;

  /// No description provided for @disableLockReason.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد إيقاف قفل التطبيق'**
  String get disableLockReason;

  /// No description provided for @changePinReason.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد تغيير رمز PIN'**
  String get changePinReason;

  /// No description provided for @createPin.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ رمز PIN من 4 أرقام'**
  String get createPin;

  /// No description provided for @confirmPin.
  ///
  /// In ar, this message translates to:
  /// **'أعد إدخال الرمز للتأكيد'**
  String get confirmPin;

  /// No description provided for @pinMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الرمزان غير متطابقين'**
  String get pinMismatch;

  /// No description provided for @biometricUnlock.
  ///
  /// In ar, this message translates to:
  /// **'الفتح بالبصمة / الوجه'**
  String get biometricUnlock;

  /// No description provided for @changePin.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رمز PIN'**
  String get changePin;

  /// No description provided for @lockAfterHint.
  ///
  /// In ar, this message translates to:
  /// **'يُقفل التطبيق بعد دقيقة من الخروج منه'**
  String get lockAfterHint;

  /// No description provided for @backupTitle.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي'**
  String get backupTitle;

  /// No description provided for @cloudBackupOff.
  ///
  /// In ar, this message translates to:
  /// **'النسخ السحابي معطّل'**
  String get cloudBackupOff;

  /// No description provided for @cloudBackupOn.
  ///
  /// In ar, this message translates to:
  /// **'النسخ السحابي مفعّل'**
  String get cloudBackupOn;

  /// No description provided for @cloudBackupHint.
  ///
  /// In ar, this message translates to:
  /// **'بحسابك الشخصي، مشفّر، دون خوادم خاصة بالتطبيق'**
  String get cloudBackupHint;

  /// No description provided for @storageProvider.
  ///
  /// In ar, this message translates to:
  /// **'مزوّد التخزين (حسابك الشخصي)'**
  String get storageProvider;

  /// No description provided for @googleDrive.
  ///
  /// In ar, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// No description provided for @iCloud.
  ///
  /// In ar, this message translates to:
  /// **'iCloud'**
  String get iCloud;

  /// No description provided for @appleDevicesOnly.
  ///
  /// In ar, this message translates to:
  /// **'لأجهزة Apple'**
  String get appleDevicesOnly;

  /// No description provided for @connected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get connected;

  /// No description provided for @frequency.
  ///
  /// In ar, this message translates to:
  /// **'التكرار'**
  String get frequency;

  /// No description provided for @daily.
  ///
  /// In ar, this message translates to:
  /// **'يومي'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعي'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get monthly;

  /// No description provided for @wifiOnly.
  ///
  /// In ar, this message translates to:
  /// **'النسخ عبر Wi-Fi فقط'**
  String get wifiOnly;

  /// No description provided for @encryptionInfo.
  ///
  /// In ar, this message translates to:
  /// **'تشفير النسخة AES-256'**
  String get encryptionInfo;

  /// No description provided for @lastBackup.
  ///
  /// In ar, this message translates to:
  /// **'آخر نسخة: {date}'**
  String lastBackup(String date);

  /// No description provided for @neverBackedUp.
  ///
  /// In ar, this message translates to:
  /// **'لم تُنسخ بعد'**
  String get neverBackedUp;

  /// No description provided for @backupNow.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الآن'**
  String get backupNow;

  /// No description provided for @restore.
  ///
  /// In ar, this message translates to:
  /// **'استعادة'**
  String get restore;

  /// No description provided for @backupPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة مرور التشفير'**
  String get backupPassword;

  /// No description provided for @backupPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'تحتاجها لاستعادة النسخة على جهاز جديد. لا يمكن استرجاعها إن نسيتها.'**
  String get backupPasswordHint;

  /// No description provided for @backupDone.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ بنجاح'**
  String get backupDone;

  /// No description provided for @restoreDone.
  ///
  /// In ar, this message translates to:
  /// **'تمت الاستعادة بنجاح'**
  String get restoreDone;

  /// No description provided for @restoreConfirm.
  ///
  /// In ar, this message translates to:
  /// **'ستُستبدل كل البيانات الحالية بمحتوى النسخة. متابعة؟'**
  String get restoreConfirm;

  /// No description provided for @chooseBackup.
  ///
  /// In ar, this message translates to:
  /// **'اختر نسخة'**
  String get chooseBackup;

  /// No description provided for @exportLocalFile.
  ///
  /// In ar, this message translates to:
  /// **'تصدير ملف نسخة مشفّر'**
  String get exportLocalFile;

  /// No description provided for @importLocalFile.
  ///
  /// In ar, this message translates to:
  /// **'استيراد ملف نسخة'**
  String get importLocalFile;

  /// No description provided for @noCloudBackups.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نسخ في السحابة'**
  String get noCloudBackups;

  /// No description provided for @errInvalidAmount.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغاً أكبر من صفر'**
  String get errInvalidAmount;

  /// No description provided for @errEmptyName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم مطلوب'**
  String get errEmptyName;

  /// No description provided for @errInvalidPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال غير صحيح'**
  String get errInvalidPhone;

  /// No description provided for @errContactArchived.
  ///
  /// In ar, this message translates to:
  /// **'الشخص مؤرشف — ارفع أرشفته أولاً'**
  String get errContactArchived;

  /// No description provided for @errInvalidDebtSource.
  ///
  /// In ar, this message translates to:
  /// **'مصدر الدين لا يناسب اتجاهه'**
  String get errInvalidDebtSource;

  /// No description provided for @errAccountRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر الحساب'**
  String get errAccountRequired;

  /// No description provided for @errDateInFuture.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ لا يكون بعد اليوم'**
  String get errDateInFuture;

  /// No description provided for @errDueBeforeStart.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الاستحقاق قبل تاريخ الدين'**
  String get errDueBeforeStart;

  /// No description provided for @errPaymentBeforeDebt.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ يسبق تاريخ الدين — غيّره أو اختر ديناً معيّناً'**
  String get errPaymentBeforeDebt;

  /// No description provided for @errDebtHasMovements.
  ///
  /// In ar, this message translates to:
  /// **'على الدين دفعات أو مسامحة — ألغِ الدفعات أولاً'**
  String get errDebtHasMovements;

  /// No description provided for @errPaymentAlreadyCancelled.
  ///
  /// In ar, this message translates to:
  /// **'العملية ملغاة مسبقاً'**
  String get errPaymentAlreadyCancelled;

  /// No description provided for @errAccountHasBalance.
  ///
  /// In ar, this message translates to:
  /// **'لا يُؤرشف الحساب إلا ورصيده صفر — حوّل رصيده أولاً'**
  String get errAccountHasBalance;

  /// No description provided for @errPersonHasBalance.
  ///
  /// In ar, this message translates to:
  /// **'لا يُؤرشف الشخص إلا ومتبقّيه صفر في الاتجاهين'**
  String get errPersonHasBalance;

  /// No description provided for @errPersonHasMovements.
  ///
  /// In ar, this message translates to:
  /// **'للشخص حركات مسجلة — يمكن أرشفته فقط'**
  String get errPersonHasMovements;

  /// No description provided for @errDuplicateAccountName.
  ///
  /// In ar, this message translates to:
  /// **'يوجد حساب بنفس الاسم'**
  String get errDuplicateAccountName;

  /// No description provided for @errAccountArchived.
  ///
  /// In ar, this message translates to:
  /// **'الحساب مؤرشف — ارفع أرشفته أولاً'**
  String get errAccountArchived;

  /// No description provided for @errCannotArchiveLast.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن أرشفة آخر حساب نشط'**
  String get errCannotArchiveLast;

  /// No description provided for @errMustChooseNewDefault.
  ///
  /// In ar, this message translates to:
  /// **'اختر حساباً افتراضياً بديلاً أولاً'**
  String get errMustChooseNewDefault;

  /// No description provided for @errSameAccountTransfer.
  ///
  /// In ar, this message translates to:
  /// **'اختر حسابين مختلفين للتحويل'**
  String get errSameAccountTransfer;

  /// No description provided for @errCategoryKindMismatch.
  ///
  /// In ar, this message translates to:
  /// **'الفئة لا تناسب نوع المعاملة'**
  String get errCategoryKindMismatch;

  /// No description provided for @errCategoryRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر فئة'**
  String get errCategoryRequired;

  /// No description provided for @errDebtMovementReadOnly.
  ///
  /// In ar, this message translates to:
  /// **'قيود الديون تُعدَّل من ملف الشخص'**
  String get errDebtMovementReadOnly;

  /// No description provided for @errCannotMoveArchived.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن نقل معاملة من حساب مؤرشف أو إليه'**
  String get errCannotMoveArchived;

  /// No description provided for @errPaymentExceeds.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ أكبر من المتبقي ({amount})'**
  String errPaymentExceeds(String amount);

  /// No description provided for @errDebtSettled.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ديون مفتوحة لهذه العملية'**
  String get errDebtSettled;

  /// No description provided for @errDebtAmountBelowPaid.
  ///
  /// In ar, this message translates to:
  /// **'الأصل لا يقل عن المدفوع والمُسامَح ({amount})'**
  String errDebtAmountBelowPaid(String amount);

  /// No description provided for @errCurrencyLocked.
  ///
  /// In ar, this message translates to:
  /// **'العملة مقفلة ولا يمكن تغييرها'**
  String get errCurrencyLocked;

  /// No description provided for @errNotOnboarded.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الإعداد الأول أولاً'**
  String get errNotOnboarded;

  /// No description provided for @errCategoryInUse.
  ///
  /// In ar, this message translates to:
  /// **'الفئة مستخدمة في معاملات ولا يمكن حذفها'**
  String get errCategoryInUse;

  /// No description provided for @errNotFound.
  ///
  /// In ar, this message translates to:
  /// **'العنصر غير موجود'**
  String get errNotFound;

  /// No description provided for @errBackupDecryption.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور خاطئة أو الملف تالف'**
  String get errBackupDecryption;

  /// No description provided for @errBackupInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الملف ليس نسخة دفتري صالحة'**
  String get errBackupInvalid;

  /// No description provided for @errNoConnection.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال — سيُعاد المحاولة لاحقاً'**
  String get errNoConnection;

  /// No description provided for @errCloudNotAuthorized.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم منح الإذن لحساب التخزين'**
  String get errCloudNotAuthorized;

  /// No description provided for @errUnexpected.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get errUnexpected;

  /// No description provided for @notifChannel.
  ///
  /// In ar, this message translates to:
  /// **'تذكير الديون'**
  String get notifChannel;

  /// No description provided for @notifTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بدين'**
  String get notifTitle;

  /// No description provided for @notifOwedToMe.
  ///
  /// In ar, this message translates to:
  /// **'غداً موعد استحقاق {amount} على {name}'**
  String notifOwedToMe(String amount, String name);

  /// No description provided for @notifIOwe.
  ///
  /// In ar, this message translates to:
  /// **'غداً موعد سداد {amount} لـ {name}'**
  String notifIOwe(String amount, String name);

  /// No description provided for @introSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get introSkip;

  /// No description provided for @introNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get introNext;

  /// No description provided for @introStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get introStart;

  /// No description provided for @intro1Body.
  ///
  /// In ar, this message translates to:
  /// **'دفتر حساباتك الشخصي وديونك في مكان واحد. يعمل بدون إنترنت وبدون تسجيل دخول، وبياناتك تبقى على جهازك.'**
  String get intro1Body;

  /// No description provided for @introOffline.
  ///
  /// In ar, this message translates to:
  /// **'بدون إنترنت'**
  String get introOffline;

  /// No description provided for @introNoAccount.
  ///
  /// In ar, this message translates to:
  /// **'بدون حساب'**
  String get introNoAccount;

  /// No description provided for @introPrivate.
  ///
  /// In ar, this message translates to:
  /// **'خصوصية تامة'**
  String get introPrivate;

  /// No description provided for @intro2Title.
  ///
  /// In ar, this message translates to:
  /// **'كل ما تحتاجه لإدارة أموالك'**
  String get intro2Title;

  /// No description provided for @intro2Body.
  ///
  /// In ar, this message translates to:
  /// **'أدوات بسيطة وواضحة لكل يوم.'**
  String get intro2Body;

  /// No description provided for @featTxTitle.
  ///
  /// In ar, this message translates to:
  /// **'المعاملات والحسابات'**
  String get featTxTitle;

  /// No description provided for @featTxBody.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخل والمصروف والتحويل بين حساباتك'**
  String get featTxBody;

  /// No description provided for @featDebtsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الديون والتذكير'**
  String get featDebtsTitle;

  /// No description provided for @featDebtsBody.
  ///
  /// In ar, this message translates to:
  /// **'تابع ما لك وما عليك مع تذكير قبل الاستحقاق'**
  String get featDebtsBody;

  /// No description provided for @featBudgetTitle.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية والتقارير'**
  String get featBudgetTitle;

  /// No description provided for @featBudgetBody.
  ///
  /// In ar, this message translates to:
  /// **'حدود شهرية ورسوم بيانية وتصدير PDF و Excel'**
  String get featBudgetBody;

  /// No description provided for @featStatementTitle.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب جاهز'**
  String get featStatementTitle;

  /// No description provided for @featStatementBody.
  ///
  /// In ar, this message translates to:
  /// **'أرسل كشف حساب أي شخص عبر واتساب بضغطة'**
  String get featStatementBody;

  /// No description provided for @intro3Title.
  ///
  /// In ar, this message translates to:
  /// **'خطوات مهمة للبدء'**
  String get intro3Title;

  /// No description provided for @intro3Body.
  ///
  /// In ar, this message translates to:
  /// **'ثلاث خطوات تحمي بياناتك من البداية.'**
  String get intro3Body;

  /// No description provided for @stepCurrencyTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر عملتك بعناية'**
  String get stepCurrencyTitle;

  /// No description provided for @stepLockTitle.
  ///
  /// In ar, this message translates to:
  /// **'احمِ بياناتك'**
  String get stepLockTitle;

  /// No description provided for @stepLockBody.
  ///
  /// In ar, this message translates to:
  /// **'فعّل قفل التطبيق بالبصمة أو رمز PIN من الإعدادات'**
  String get stepLockBody;

  /// No description provided for @stepBackupTitle.
  ///
  /// In ar, this message translates to:
  /// **'خذ نسخة احتياطية'**
  String get stepBackupTitle;

  /// No description provided for @stepBackupBody.
  ///
  /// In ar, this message translates to:
  /// **'صدّر نسخة مشفّرة أو فعّل النسخ السحابي لتنقل بياناتك بأمان'**
  String get stepBackupBody;

  /// No description provided for @profileTitle.
  ///
  /// In ar, this message translates to:
  /// **'عرّفنا بنفسك'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يظهر اسمك في التقارير وكشوف الحساب التي تشاركها.'**
  String get profileSubtitle;

  /// No description provided for @yourName.
  ///
  /// In ar, this message translates to:
  /// **'اسمك'**
  String get yourName;

  /// No description provided for @phoneOptional.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال (اختياري)'**
  String get phoneOptional;

  /// No description provided for @sectionProfile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get sectionProfile;

  /// No description provided for @editProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get editProfile;

  /// No description provided for @addYourName.
  ///
  /// In ar, this message translates to:
  /// **'أضف اسمك'**
  String get addYourName;

  /// No description provided for @noPhone.
  ///
  /// In ar, this message translates to:
  /// **'بدون رقم جوال'**
  String get noPhone;

  /// No description provided for @greetingName.
  ///
  /// In ar, this message translates to:
  /// **'{greeting}، {name}'**
  String greetingName(String greeting, String name);

  /// No description provided for @issuedBy.
  ///
  /// In ar, this message translates to:
  /// **'صادر من: {name}'**
  String issuedBy(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
