// =============================================================================
// رسائل للمستخدم: ترجمة أخطاء قواعد العمل، التأكيد قبل الحذف، رسائل النجاح.
// طبقة الخدمات ترمي BusinessException برمز؛ هنا فقط يتحول الرمز إلى نص.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'common.dart';

/// نص الخطأ بلغة المستخدم. [formatAmount] لتنسيق المبالغ في التفاصيل.
String errorMessage(
  AppLocalizations l10n,
  Object error, {
  String Function(int minor)? formatAmount,
}) {
  if (error is! BusinessException) return l10n.errUnexpected;
  String amount() => error.details is int && formatAmount != null
      ? formatAmount(error.details! as int)
      : '${error.details ?? ''}';
  return switch (error.error) {
    BusinessError.invalidAmount => l10n.errInvalidAmount,
    BusinessError.emptyName => l10n.errEmptyName,
    BusinessError.invalidPhone => l10n.errInvalidPhone,
    BusinessError.duplicateAccountName => l10n.errDuplicateAccountName,
    BusinessError.accountArchived => l10n.errAccountArchived,
    BusinessError.cannotArchiveLastAccount => l10n.errCannotArchiveLast,
    BusinessError.mustChooseNewDefault => l10n.errMustChooseNewDefault,
    BusinessError.sameAccountTransfer => l10n.errSameAccountTransfer,
    BusinessError.categoryKindMismatch => l10n.errCategoryKindMismatch,
    BusinessError.categoryRequired => l10n.errCategoryRequired,
    BusinessError.debtMovementReadOnly => l10n.errDebtMovementReadOnly,
    BusinessError.cannotMoveArchivedTransaction => l10n.errCannotMoveArchived,
    BusinessError.paymentExceedsRemaining => l10n.errPaymentExceeds(amount()),
    BusinessError.debtAlreadySettled => l10n.errDebtSettled,
    BusinessError.debtAmountBelowPaid => l10n.errDebtAmountBelowPaid(amount()),
    BusinessError.currencyLocked => l10n.errCurrencyLocked,
    BusinessError.notOnboarded => l10n.errNotOnboarded,
    BusinessError.categoryInUse => l10n.errCategoryInUse,
    BusinessError.notFound => l10n.errNotFound,
    BusinessError.backupDecryptionFailed => l10n.errBackupDecryption,
    BusinessError.backupInvalidFile => l10n.errBackupInvalid,
    BusinessError.noConnection => l10n.errNoConnection,
    BusinessError.cloudNotAuthorized => l10n.errCloudNotAuthorized,
    BusinessError.contactArchived => l10n.errContactArchived,
    BusinessError.invalidDebtSource => l10n.errInvalidDebtSource,
    BusinessError.accountRequired => l10n.errAccountRequired,
    BusinessError.dateInFuture => l10n.errDateInFuture,
    BusinessError.dueBeforeStart => l10n.errDueBeforeStart,
    BusinessError.paymentBeforeDebt => l10n.errPaymentBeforeDebt,
    BusinessError.debtHasMovements => l10n.errDebtHasMovements,
    BusinessError.paymentAlreadyCancelled => l10n.errPaymentAlreadyCancelled,
    BusinessError.accountHasBalance => l10n.errAccountHasBalance,
    BusinessError.personHasBalance => l10n.errPersonHasBalance,
    BusinessError.personHasMovements => l10n.errPersonHasMovements,
  };
}

/// شريط رسالة سفلي (Snackbar) موحّد.
void showMessage(
  BuildContext context,
  String message, {
  bool error = false,
  IconData? icon,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            icon ?? (error ? Icons.error_outline : Icons.check_circle_outline),
            color: icon != null
                ? context.colors.warning
                : error
                ? context.colors.expense
                : context.colors.income,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      action: action,
      duration: duration,
    ),
  );
}

void showError(
  BuildContext context,
  Object error, {
  String Function(int minor)? formatAmount,
}) => showMessage(
  context,
  errorMessage(context.l10n, error, formatAmount: formatAmount),
  error: true,
);

/// نافذة تأكيد (قبل الحذف مثلاً). تعيد true إذا أكد المستخدم.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
  IconData icon = Icons.delete_outline_rounded,
}) async {
  final c = context.colors;
  final result = await showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(
              icon: icon,
              color: destructive ? c.expense : c.primary,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: c.expense)
                  : null,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
