// =============================================================================
// أسماء القيم الثابتة (Enums) بلغة المستخدم، وألوانها وأيقوناتها الدلالية.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/money/money.dart';
import '../../domain/enums.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

extension EnumLabels on AppLocalizations {
  String accountTypeName(AccountType t) => switch (t) {
    AccountType.cash => accountTypeCash,
    AccountType.bank => accountTypeBank,
    AccountType.wallet => accountTypeWallet,
    AccountType.savings => accountTypeSavings,
  };

  String txTypeName(TxType t) => switch (t) {
    TxType.income => typeIncome,
    TxType.expense => typeExpense,
    TxType.transfer => typeTransfer,
    TxType.adjustment => typeAdjustment,
    TxType.debtOut => typeDebtOut,
    TxType.debtIn => typeDebtIn,
    TxType.writeOff => writeOffEntry,
    TxType.debtForgiven => forgivenEntry,
  };

  String debtStatusName(DebtStatus s) => switch (s) {
    DebtStatus.open => statusOpen,
    DebtStatus.partial => statusPartial,
    DebtStatus.closed => statusClosed,
  };

  String directionName(DebtDirection d) =>
      d == DebtDirection.owedToMe ? tabOwedToMe : tabIOwe;

  /// خيار مصدر الدين في نموذج الدين الجديد.
  String debtSourceOption(DebtSource s, DebtDirection d) => switch (s) {
    DebtSource.loan =>
      d == DebtDirection.owedToMe ? sourceLoanOwed : sourceLoanOwe,
    DebtSource.creditSale => sourceCreditSale,
    DebtSource.creditPurchase => sourceCreditPurchase,
    DebtSource.opening => sourceOpening,
  };

  /// أثر مصدر الدين (تحت الخيار).
  String debtSourceHint(DebtSource s, DebtDirection d) => switch (s) {
    DebtSource.loan =>
      d == DebtDirection.owedToMe
          ? decreasesBalanceNotExpense
          : increasesBalanceNotIncome,
    DebtSource.creditSale => sourceCreditSaleHint,
    DebtSource.creditPurchase => sourceCreditPurchaseHint,
    DebtSource.opening => sourceOpeningHint,
  };

  /// وصف قصير للدين في الخط الزمني وكشف الحساب (مثل «بيع بالآجل»).
  String debtSourceLabel(DebtSource s, DebtDirection d) => switch (s) {
    DebtSource.loan =>
      d == DebtDirection.owedToMe ? labelLoanOwed : labelLoanOwe,
    DebtSource.creditSale => labelCreditSale,
    DebtSource.creditPurchase => labelCreditPurchase,
    DebtSource.opening => labelOpening,
  };

  /// زر الاستلام (لي) أو السداد (عليّ).
  String settleAction(DebtDirection d) =>
      d == DebtDirection.owedToMe ? receiveAmount : payAmount;

  /// اسم عملية الدفع في الخط الزمني وكشف الحساب.
  String paymentName(DebtDirection d) =>
      d == DebtDirection.owedToMe ? paymentReceived : paymentMade;

  /// اسم قيد المسامحة (لي) أو الإعفاء (عليّ).
  String writeOffName(DebtDirection d) =>
      d == DebtDirection.owedToMe ? writeOffEntry : forgivenEntry;

  /// عنوان بطاقة/قسم الاتجاه لشخص.
  String directionTitle(DebtDirection d, String name) =>
      d == DebtDirection.owedToMe ? profileOwedToMe(name) : profileIOwe(name);
}

extension TxTypeVisuals on TxType {
  /// اللون الدلالي لنوع المعاملة.
  Color color(AppColors c) => switch (this) {
    TxType.income => c.income,
    TxType.expense => c.expense,
    TxType.transfer => c.transfer,
    TxType.adjustment => c.textSecondary,
    TxType.debtIn || TxType.debtOut => c.warning,
    TxType.writeOff => c.expense,
    TxType.debtForgiven => c.income,
  };

  IconData get icon => switch (this) {
    TxType.income => AppIcons.income,
    TxType.expense => AppIcons.expense,
    TxType.transfer => AppIcons.transfer,
    TxType.adjustment => AppIcons.adjustment,
    TxType.debtIn || TxType.debtOut => AppIcons.debt,
    TxType.writeOff => Icons.handshake_outlined,
    TxType.debtForgiven => Icons.money_off_rounded,
  };
}

/// تنسيق التواريخ حسب لغة الواجهة.
/// أرقام التواريخ تتبع إعداد «الأرقام الهندية» لتطابق أرقام المبالغ
/// (مكتبة intl تكتب التواريخ العربية بالأرقام الهندية افتراضياً).
class DateLabels {
  DateLabels(this.locale, {this.latinDigits = true});

  final String locale;
  final bool latinDigits;

  String _digits(String s) => latinDigits ? MoneyParser.normalizeDigits(s) : s;

  String day(DateTime d) => _digits(DateFormat.MMMd(locale).format(d));
  String full(DateTime d) => _digits(DateFormat.yMMMd(locale).format(d));
  String month(DateTime d) => _digits(DateFormat.yMMMM(locale).format(d));
  String monthShort(DateTime d) => _digits(DateFormat.MMM(locale).format(d));
  String dateTime(DateTime d) =>
      _digits(DateFormat.yMMMd(locale).add_jm().format(d));

  /// «اليوم» / «أمس» / التاريخ — لعناوين مجموعات سجل المعاملات.
  String relativeDay(DateTime d, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.yesterday;
    return that.year == today.year ? day(d) : full(d);
  }
}

/// نص الاستحقاق: «يستحق بعد 5 أيام» / «متأخر 3 أيام» / «يستحق اليوم».
/// ويعيد أيضاً هل الدين متأخر (للتلوين بالأحمر).
(String, bool) dueLabel(AppLocalizations l10n, DateTime due, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final days = DateTime(
    due.year,
    due.month,
    due.day,
  ).difference(DateTime(n.year, n.month, n.day)).inDays;
  if (days == 0) return (l10n.dueToday, false);
  return days > 0
      ? (l10n.dueInDays(days), false)
      : (l10n.overdueDays(-days), true);
}
