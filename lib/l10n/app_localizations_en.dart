// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Daftari';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get undo => 'Undo';

  @override
  String get continueLabel => 'Continue';

  @override
  String get optional => 'Optional';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get saved => 'Saved';

  @override
  String get seeAll => 'See all';

  @override
  String get note => 'Note';

  @override
  String get date => 'Date';

  @override
  String get amount => 'Amount';

  @override
  String get account => 'Account';

  @override
  String get category => 'Category';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get comingSoon => 'Soon';

  @override
  String get archivedBadge => 'Archived';

  @override
  String get defaultBadge => 'Default';

  @override
  String get all => 'All';

  @override
  String get more => 'More';

  @override
  String get noResults => 'No results';

  @override
  String get password => 'Password';

  @override
  String get passwordTooShort => 'At least 6 characters';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get navHome => 'Home';

  @override
  String get navTransactions => 'Activity';

  @override
  String get navDebts => 'Debts';

  @override
  String get navMore => 'More';

  @override
  String get welcomeTitle => 'Welcome to Daftari';

  @override
  String get welcomeSubtitle => 'No account • No password • Start now';

  @override
  String get chooseCurrency => 'Choose your currency';

  @override
  String get currencyWarning =>
      'Used across the app and cannot be changed later';

  @override
  String get searchCurrency => 'Search currency';

  @override
  String get cloudBackupOptionalHint =>
      'Optional — enable it later from settings';

  @override
  String get confirmCurrencyTitle => 'Confirm app currency';

  @override
  String get confirmCurrencyBody =>
      'All accounts, transactions and debts will be recorded in this currency.';

  @override
  String get confirmCurrencyWarning => 'It cannot be changed after confirming';

  @override
  String get confirmAndStart => 'Confirm & start';

  @override
  String get backAndChange => 'Back & change currency';

  @override
  String get restoreExisting => 'Have a backup? Restore';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get monthIncome => 'Income';

  @override
  String get monthExpense => 'Expenses';

  @override
  String get quickExpense => 'Expense';

  @override
  String get quickIncome => 'Income';

  @override
  String get quickTransfer => 'Transfer';

  @override
  String get quickDebt => 'Debt';

  @override
  String get monthlyBudget => 'Monthly budget';

  @override
  String budgetOf(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String remainingForDays(String amount, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'today',
    );
    return '$amount left for $_temp0';
  }

  @override
  String get owedToMe => 'Owed to me';

  @override
  String get iOwe => 'I owe';

  @override
  String get recentTransactions => 'Recent';

  @override
  String get noTransactionsYet =>
      'No transactions yet. Tap + to add your first one.';

  @override
  String get hideBalances => 'Hide balances';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get searchTransactions => 'Search by name or amount';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get typeExpense => 'Expense';

  @override
  String get typeIncome => 'Income';

  @override
  String get typeTransfer => 'Transfer';

  @override
  String get typeAdjustment => 'Adjustment';

  @override
  String get typeDebtOut => 'Debt movement — out';

  @override
  String get typeDebtIn => 'Debt movement — in';

  @override
  String get debtMovement => 'Debt movement';

  @override
  String get fromAccount => 'From account';

  @override
  String get toAccount => 'To account';

  @override
  String get suggestedForCategory => 'Suggested: last used for category';

  @override
  String get attachReceipt => 'Attach receipt';

  @override
  String get receiptAttached => 'Receipt attached';

  @override
  String get removeReceipt => 'Remove receipt';

  @override
  String get viewReceipt => 'View receipt';

  @override
  String get receiptCamera => 'Camera';

  @override
  String get receiptGallery => 'Gallery';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get deleteTransactionTitle => 'Delete this transaction?';

  @override
  String deleteTransactionBody(
    String description,
    String amount,
    String account,
  ) {
    return '$description — $amount\nThe amount will be returned to “$account” automatically.';
  }

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get debtMovementHint =>
      'A debt movement changes the balance but is not income or expense. Edit it from the person’s profile.';

  @override
  String get openPersonProfile => 'Open profile';

  @override
  String budgetWarning(String category, String percent) {
    return 'Close to the “$category” budget: $percent%';
  }

  @override
  String budgetExceeded(String category, String percent) {
    return 'Over the “$category” budget ($percent%)';
  }

  @override
  String get filterTitle => 'Filter transactions';

  @override
  String get period => 'Period';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'This week';

  @override
  String get periodMonth => 'This month';

  @override
  String get periodLast30 => 'Last 30 days';

  @override
  String get periodLast3Months => 'Last 3 months';

  @override
  String get periodYear => 'This year';

  @override
  String get periodCustom => 'Custom';

  @override
  String get periodAll => 'All time';

  @override
  String get typeAndCategory => 'Type & category';

  @override
  String get showDebtMovements => 'Show debt movements';

  @override
  String get showDebtMovementsHint =>
      'Listed only — not counted as income or expense';

  @override
  String get sort => 'Sort';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortAmountDesc => 'Highest amount';

  @override
  String get sortAmountAsc => 'Lowest amount';

  @override
  String get allCategories => 'All categories';

  @override
  String summaryIncome(String amount) {
    return 'Income $amount';
  }

  @override
  String summaryExpense(String amount) {
    return 'Expense $amount';
  }

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get totalActiveAccounts => 'Total of active accounts';

  @override
  String activeAccountsCount(String count) {
    return 'Active ($count)';
  }

  @override
  String archivedAccountsCount(String count) {
    return 'Archived ($count)';
  }

  @override
  String archivedSince(String date) {
    return 'Archived since $date';
  }

  @override
  String get addAccount => 'Add account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get accountName => 'Account name';

  @override
  String get accountType => 'Account type';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeWallet => 'Wallet';

  @override
  String get accountTypeSavings => 'Savings';

  @override
  String get setAsDefault => 'Set as default';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get adjustBalance => 'Adjust balance';

  @override
  String get adjustBalanceHint =>
      'Enter the real balance; the difference is recorded as an “Adjustment”.';

  @override
  String get actualBalance => 'Actual balance';

  @override
  String archiveTitle(String name) {
    return 'Archive “$name”?';
  }

  @override
  String get archiveBody =>
      'It will be hidden from home and from new transactions or debts. Past records stay in history and reports.';

  @override
  String archiveHasBalance(String amount) {
    return 'Current balance $amount';
  }

  @override
  String get transferBalanceTo => 'Transfer balance to';

  @override
  String get transferAndArchive => 'Transfer balance & archive';

  @override
  String get newDefaultAccount => 'New default account';

  @override
  String get recalculateBalances => 'Recalculate balances';

  @override
  String recalculateDone(String count) {
    return 'Audit done — $count account(s) corrected';
  }

  @override
  String get debtsTitle => 'Debts';

  @override
  String get debtsSubtitle => 'Separate from income and expenses';

  @override
  String get tabOwedToMe => 'Owed to me';

  @override
  String get tabIOwe => 'I owe';

  @override
  String get newDebt => 'New debt';

  @override
  String dueInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Due in $_temp0';
  }

  @override
  String overdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Overdue $_temp0';
  }

  @override
  String get dueToday => 'Due today';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusPartial => 'Partially paid';

  @override
  String get statusOpen => 'Open';

  @override
  String ofTotal(String amount) {
    return 'of $amount';
  }

  @override
  String get noDebts =>
      'No debts yet. Record one to track what you are owed and what you owe.';

  @override
  String get directionOwedToMeHint => 'I lent / sold on credit';

  @override
  String get directionIOweHint => 'I borrowed / bought on credit';

  @override
  String get person => 'Person';

  @override
  String get choosePerson => 'Choose a person';

  @override
  String get fromContacts => 'From contacts';

  @override
  String get addPerson => 'Add person';

  @override
  String get dueDateOptional => 'Due date (optional)';

  @override
  String get decreasesBalanceNotExpense => 'Decreases balance — not an expense';

  @override
  String get increasesBalanceNotIncome => 'Increases balance — not income';

  @override
  String get remindBeforeDue => 'Remind me a day before';

  @override
  String get saveDebt => 'Save debt';

  @override
  String get editDebt => 'Edit debt';

  @override
  String get deleteDebt => 'Delete debt';

  @override
  String get deleteDebtBody =>
      'The debt and its entry are removed, restoring the account, income or expense. (For debts entered by mistake only.)';

  @override
  String remainingAmount(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String get fullRemaining => 'Full remaining';

  @override
  String get receivedIntoAccount => 'Received into';

  @override
  String get paidFromAccount => 'Paid from';

  @override
  String profileOwedToMe(String name) {
    return '$name owes me';
  }

  @override
  String profileIOwe(String name) {
    return 'I owe $name';
  }

  @override
  String paidAmount(String amount) {
    return 'Paid $amount';
  }

  @override
  String totalDebtsAmount(String amount) {
    return 'Total $amount';
  }

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String get statement => 'Statement';

  @override
  String get timeline => 'Timeline';

  @override
  String get paymentReceived => 'Received';

  @override
  String get paymentMade => 'Paid';

  @override
  String get editPerson => 'Edit person';

  @override
  String get searchPeople => 'Search people';

  @override
  String get sourceTitle => 'Where did this debt come from?';

  @override
  String get sourceLoanOwed => 'I lent from an account';

  @override
  String get sourceLoanOwe => 'I borrowed into an account';

  @override
  String get sourceCreditSale => 'I sold on credit';

  @override
  String get sourceCreditPurchase => 'I bought on credit';

  @override
  String get sourceOpening => 'Earlier debt (before using the app)';

  @override
  String get sourceCreditSaleHint =>
      'Recorded as income in a category — no account movement';

  @override
  String get sourceCreditPurchaseHint =>
      'Recorded as an expense in a category — no account movement';

  @override
  String get sourceOpeningHint =>
      'Ledger only — no income and no account movement';

  @override
  String get labelLoanOwed => 'Cash loan';

  @override
  String get labelLoanOwe => 'Borrowed';

  @override
  String get labelCreditSale => 'Credit sale';

  @override
  String get labelCreditPurchase => 'Credit purchase';

  @override
  String get labelOpening => 'Earlier debt';

  @override
  String get debtLockedHint =>
      'It has payments or write-offs: direction, source and person are locked';

  @override
  String get receiveAmount => 'Receive payment';

  @override
  String get payAmount => 'Make payment';

  @override
  String receiveFrom(String name) {
    return 'Receive from $name';
  }

  @override
  String payTo(String name) {
    return 'Pay $name';
  }

  @override
  String remainingAfterPayment(String amount) {
    return 'Remaining after payment: $amount';
  }

  @override
  String distributedOldestFirst(String parts) {
    return 'Applied oldest first: $parts';
  }

  @override
  String get chooseSpecificDebt => 'Choose a specific debt';

  @override
  String get autoDistribute => 'Automatic';

  @override
  String get excessTitle => 'More than the remaining';

  @override
  String excessOwedToMe(String amount, String name) {
    return 'The extra $amount — record it as a debt you owe $name?';
  }

  @override
  String excessIOwe(String amount, String name) {
    return 'The extra $amount — record it as a debt $name owes you?';
  }

  @override
  String get recordExcess => 'Record the extra';

  @override
  String get editAmount => 'Change amount';

  @override
  String get excessNote => 'Overpayment';

  @override
  String get noOneOwesYou => 'No one owes you anything right now';

  @override
  String get youOweNoOne => 'You don’t owe anyone right now';

  @override
  String get distribution => 'Breakdown';

  @override
  String get cancelOperation => 'Cancel operation';

  @override
  String get cancelOperationBody =>
      'All payments in this operation are cancelled together and the account movement is reversed. They stay visible, struck through, in the timeline.';

  @override
  String get cancelledBadge => 'Cancelled';

  @override
  String negativeCashWarning(String account) {
    return 'Heads up: “$account” balance is now negative';
  }

  @override
  String get forgiveRemaining => 'Write off the rest';

  @override
  String get forgivenRemaining => 'Mark the rest as forgiven';

  @override
  String forgiveBodyOwedToMe(String amount) {
    return 'Closes the debt and records the remaining $amount as an expense under “Debt write-off”. No account balance changes.';
  }

  @override
  String forgiveBodyIOwe(String amount) {
    return 'Closes the debt and records the remaining $amount as income under “Debt relief”. No account balance changes.';
  }

  @override
  String get writeOffEntry => 'Written off';

  @override
  String get forgivenEntry => 'Forgiven by creditor';

  @override
  String paymentRate(String percent) {
    return 'Paid $percent%';
  }

  @override
  String writtenOffRate(String percent) {
    return 'Written off $percent%';
  }

  @override
  String netForYou(String amount) {
    return 'Net in your favor: $amount';
  }

  @override
  String netForThem(String name, String amount) {
    return 'Net in $name’s favor: $amount';
  }

  @override
  String get netEven => 'Net: even';

  @override
  String get netInfoHint => 'For information only — the two are not offset';

  @override
  String balanceAfter(String amount) {
    return 'Balance after: $amount';
  }

  @override
  String get archivePerson => 'Archive person';

  @override
  String get archivePersonBody =>
      'Hidden from lists and pickers; the full history is kept and you can unarchive later.';

  @override
  String get deletePerson => 'Delete person';

  @override
  String get deletePersonBody =>
      'This person has no activity and will be deleted permanently.';

  @override
  String get personArchivedBanner => 'This person is archived';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
      zero: 'no one',
    );
    return '$_temp0';
  }

  @override
  String overdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdue',
      one: '1 overdue',
      zero: 'none overdue',
    );
    return '$_temp0';
  }

  @override
  String get filterDebts => 'Filter debts';

  @override
  String get statusFilter => 'Status';

  @override
  String get sortNearestDue => 'Nearest due';

  @override
  String get sortLastActivity => 'Latest activity';

  @override
  String duplicatePerson(String name) {
    return '“$name” already exists — did you mean them?';
  }

  @override
  String get useExisting => 'Yes, that’s them';

  @override
  String get reconcileOk => 'Global reconciliation check passed ✓';

  @override
  String reconcileGap(String amount) {
    return 'Warning: reconciliation gap of $amount — please review your data';
  }

  @override
  String get archiveNeedsZero =>
      'An account can only be archived with a zero balance — transfer it first';

  @override
  String statementTitle(String name) {
    return 'Statement — $name';
  }

  @override
  String get outputFormat => 'Output';

  @override
  String get outputImage => 'Image';

  @override
  String get outputImageHint => 'Short statements';

  @override
  String get outputPdf => 'PDF';

  @override
  String get outputPdfHint => 'Long statements';

  @override
  String get preview => 'Preview';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get share => 'Share';

  @override
  String get print => 'Print';

  @override
  String get closingBalance => 'Balance due';

  @override
  String statementShareText(String name) {
    return 'Statement for $name — Daftari';
  }

  @override
  String get generatedAt => 'Generated';

  @override
  String get noMovementsInPeriod => 'No movements in this period';

  @override
  String get description => 'Description';

  @override
  String get balance => 'Balance';

  @override
  String dueFromPerson(String name) {
    return 'Amount due from $name';
  }

  @override
  String dueToPerson(String name) {
    return 'Amount due to $name';
  }

  @override
  String get reportsTitle => 'Reports';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expenses';

  @override
  String get net => 'Net';

  @override
  String get incomeVsExpense => 'Income vs expenses';

  @override
  String get expenseByCategory => 'Expenses by category';

  @override
  String get incomeByCategory => 'Income by category';

  @override
  String get reportsExcludedNote =>
      'Debt movements, adjustments and transfers are excluded.';

  @override
  String get monthlyView => 'Monthly';

  @override
  String get yearlyView => 'Yearly';

  @override
  String get reportTitle => 'Daftari report';

  @override
  String get month => 'Month';

  @override
  String get shareOfTotal => 'Share';

  @override
  String get transactions => 'Transactions';

  @override
  String get type => 'Type';

  @override
  String get export => 'Export';

  @override
  String get budgetTitle => 'Budget';

  @override
  String spentOfBudget(String month) {
    return '$month spending vs budget';
  }

  @override
  String get addBudget => 'Add budget';

  @override
  String get editBudget => 'Edit budget';

  @override
  String get budgetLimit => 'Monthly limit';

  @override
  String alertAtPercent(String percent) {
    return 'Alert at $percent%';
  }

  @override
  String budgetOverBy(String amount) {
    return 'Over budget by $amount';
  }

  @override
  String get legendSafe => 'Under 75%';

  @override
  String get legendWarning => '75–99%';

  @override
  String get legendExceeded => 'Over';

  @override
  String get noBudgets =>
      'No budgets yet. Add a limit to a category to track spending.';

  @override
  String get deleteBudget => 'Delete budget';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get addCategory => 'Add category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get expenseCategories => 'Expense categories';

  @override
  String get incomeCategories => 'Income categories';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionCurrency => 'Currency';

  @override
  String get appCurrencyLocked => 'App currency (locked)';

  @override
  String get addCurrency => 'Add a currency';

  @override
  String get sectionGeneral => 'General';

  @override
  String get defaultAccount => 'Default account';

  @override
  String get languageAndAppearance => 'Language & appearance';

  @override
  String get language => 'Language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get followDevice => 'System';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get arabicDigits => 'Arabic-Indic digits (١٢٣)';

  @override
  String get sectionSecurityData => 'Security & data';

  @override
  String get appLock => 'App lock (biometric / PIN)';

  @override
  String get cloudBackup => 'Cloud backup';

  @override
  String get localBackup => 'Export / import local file';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllDataBody =>
      'Everything will be permanently deleted and you will return to setup. This is the only way to change the currency.';

  @override
  String get sectionManage => 'Manage';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get contactSupport => 'Contact support';

  @override
  String get supportWhatsApp => 'WhatsApp';

  @override
  String get supportCall => 'Call';

  @override
  String get supportInstagram => 'Instagram';

  @override
  String get linkOpenFailed => 'Couldn\'t open the link';

  @override
  String get developedBy => 'Developed by Mohammed Al-Mekhlafi';

  @override
  String get lockedTitle => 'Daftari is locked';

  @override
  String get enterPin => 'Enter your PIN';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get useBiometrics => 'Use biometrics';

  @override
  String get unlockReason => 'Unlock Daftari';

  @override
  String get verifyIdentity => 'Verify it\'s you';

  @override
  String get deleteAllDataReason => 'Confirm deleting all data';

  @override
  String get disableLockReason => 'Confirm turning off app lock';

  @override
  String get changePinReason => 'Confirm changing your PIN';

  @override
  String get createPin => 'Create a 4-digit PIN';

  @override
  String get confirmPin => 'Re-enter to confirm';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get biometricUnlock => 'Unlock with biometrics';

  @override
  String get changePin => 'Change PIN';

  @override
  String get lockAfterHint => 'Locks one minute after leaving the app';

  @override
  String get backupTitle => 'Backup';

  @override
  String get cloudBackupOff => 'Cloud backup is off';

  @override
  String get cloudBackupOn => 'Cloud backup is on';

  @override
  String get cloudBackupHint => 'Your own account, encrypted, no app servers';

  @override
  String get storageProvider => 'Storage (your personal account)';

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get iCloud => 'iCloud';

  @override
  String get appleDevicesOnly => 'Apple devices';

  @override
  String get connected => 'Connected';

  @override
  String get frequency => 'Frequency';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get wifiOnly => 'Wi-Fi only';

  @override
  String get encryptionInfo => 'AES-256 encryption';

  @override
  String lastBackup(String date) {
    return 'Last backup: $date';
  }

  @override
  String get neverBackedUp => 'Never backed up';

  @override
  String get backupNow => 'Back up now';

  @override
  String get restore => 'Restore';

  @override
  String get backupPassword => 'Encryption password';

  @override
  String get backupPasswordHint =>
      'Needed to restore on a new device. It cannot be recovered if forgotten.';

  @override
  String get backupDone => 'Backup completed';

  @override
  String get restoreDone => 'Restore completed';

  @override
  String get restoreConfirm =>
      'All current data will be replaced by the backup. Continue?';

  @override
  String get chooseBackup => 'Choose a backup';

  @override
  String get exportLocalFile => 'Export encrypted backup file';

  @override
  String get importLocalFile => 'Import backup file';

  @override
  String get noCloudBackups => 'No cloud backups found';

  @override
  String get errInvalidAmount => 'Enter an amount greater than zero';

  @override
  String get errEmptyName => 'Name is required';

  @override
  String get errInvalidPhone => 'Invalid phone number';

  @override
  String get errContactArchived =>
      'This person is archived — unarchive them first';

  @override
  String get errInvalidDebtSource =>
      'This source does not match the debt direction';

  @override
  String get errAccountRequired => 'Choose an account';

  @override
  String get errDateInFuture => 'The date cannot be in the future';

  @override
  String get errDueBeforeStart => 'The due date is before the debt date';

  @override
  String get errPaymentBeforeDebt =>
      'The date is before the debt date — change it or choose a specific debt';

  @override
  String get errDebtHasMovements =>
      'This debt has payments or a write-off — cancel the payments first';

  @override
  String get errPaymentAlreadyCancelled =>
      'This operation is already cancelled';

  @override
  String get errAccountHasBalance =>
      'An account can only be archived with a zero balance — transfer it first';

  @override
  String get errPersonHasBalance =>
      'A person can only be archived when nothing is owed either way';

  @override
  String get errPersonHasMovements =>
      'This person has recorded activity — archive them instead';

  @override
  String get errDuplicateAccountName => 'An account with this name exists';

  @override
  String get errAccountArchived =>
      'The account is archived — unarchive it first';

  @override
  String get errCannotArchiveLast =>
      'You cannot archive the last active account';

  @override
  String get errMustChooseNewDefault => 'Choose a new default account first';

  @override
  String get errSameAccountTransfer => 'Choose two different accounts';

  @override
  String get errCategoryKindMismatch => 'The category does not match the type';

  @override
  String get errCategoryRequired => 'Choose a category';

  @override
  String get errDebtMovementReadOnly =>
      'Debt entries are edited from the person’s profile';

  @override
  String get errCannotMoveArchived =>
      'Cannot move a transaction to or from an archived account';

  @override
  String errPaymentExceeds(String amount) {
    return 'Amount exceeds the remaining ($amount)';
  }

  @override
  String get errDebtSettled => 'There is no open debt for this operation';

  @override
  String errDebtAmountBelowPaid(String amount) {
    return 'The amount cannot be less than what was paid and written off ($amount)';
  }

  @override
  String get errCurrencyLocked => 'The currency is locked';

  @override
  String get errNotOnboarded => 'Complete setup first';

  @override
  String get errCategoryInUse => 'The category is in use and cannot be deleted';

  @override
  String get errNotFound => 'Item not found';

  @override
  String get errBackupDecryption => 'Wrong password or corrupted file';

  @override
  String get errBackupInvalid => 'Not a valid Daftari backup';

  @override
  String get errNoConnection => 'No connection — will retry later';

  @override
  String get errCloudNotAuthorized => 'Storage account not authorized';

  @override
  String get errUnexpected => 'Something went wrong';

  @override
  String get notifChannel => 'Debt reminders';

  @override
  String get notifTitle => 'Debt reminder';

  @override
  String notifOwedToMe(String amount, String name) {
    return '$name owes you $amount, due tomorrow';
  }

  @override
  String notifIOwe(String amount, String name) {
    return 'You owe $name $amount, due tomorrow';
  }

  @override
  String get introSkip => 'Skip';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Get started';

  @override
  String get intro1Body =>
      'Your personal ledger and debts in one place. Works offline with no sign-up, and your data stays on your device.';

  @override
  String get introOffline => 'Offline';

  @override
  String get introNoAccount => 'No sign-up';

  @override
  String get introPrivate => 'Fully private';

  @override
  String get intro2Title => 'Everything to manage your money';

  @override
  String get intro2Body => 'Simple, clear tools for every day.';

  @override
  String get featTxTitle => 'Transactions & accounts';

  @override
  String get featTxBody =>
      'Record income, expenses and transfers between accounts';

  @override
  String get featDebtsTitle => 'Debts & reminders';

  @override
  String get featDebtsBody =>
      'Track what you are owed and what you owe, with due-date reminders';

  @override
  String get featBudgetTitle => 'Budgets & reports';

  @override
  String get featBudgetBody => 'Monthly limits, charts, and PDF & Excel export';

  @override
  String get featStatementTitle => 'Ready-made statements';

  @override
  String get featStatementBody =>
      'Send anyone their statement on WhatsApp in one tap';

  @override
  String get intro3Title => 'Key steps to get started';

  @override
  String get intro3Body => 'Three steps that protect your data from day one.';

  @override
  String get stepCurrencyTitle => 'Choose your currency carefully';

  @override
  String get stepLockTitle => 'Protect your data';

  @override
  String get stepLockBody =>
      'Turn on app lock with biometrics or a PIN in Settings';

  @override
  String get stepBackupTitle => 'Back up regularly';

  @override
  String get stepBackupBody =>
      'Export an encrypted copy or turn on cloud backup to move your data safely';

  @override
  String get profileTitle => 'Tell us about you';

  @override
  String get profileSubtitle =>
      'Your name appears on the reports and statements you share.';

  @override
  String get yourName => 'Your name';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get sectionProfile => 'Profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get addYourName => 'Add your name';

  @override
  String get noPhone => 'No phone number';

  @override
  String greetingName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String issuedBy(String name) {
    return 'Issued by: $name';
  }
}
