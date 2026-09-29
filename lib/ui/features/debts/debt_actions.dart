// =============================================================================
// إجراءات مشتركة بين شاشات الديون: الاستلام/السداد من زر الإجراءات السريعة،
// المسامحة بالمتبقي، وتنبيه الرصيد النقدي السالب (القاعدة 9).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/seed/default_categories.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/debt_models.dart';
import '../../../services/providers.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/labels.dart';
import 'payment_sheet.dart';

/// القاعدة 9: عملية تجعل رصيد حساب نقدي سالباً تُنبِّه دون أن تُمنع
/// (البنك قد يسمح بالسحب على المكشوف). يعيد true إن ظهر التنبيه.
Future<bool> warnIfCashNegative(
  ScaffoldMessengerState messenger,
  WidgetRef ref,
  int? accountId, {
  required String Function(String account) message,
}) async {
  if (accountId == null) return false;
  final account = await ref.read(accountServiceProvider).getById(accountId);
  if (account == null ||
      account.type != AccountType.cash ||
      account.balance >= 0) {
    return false;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text(message(account.name))),
          ],
        ),
      ),
    );
  return true;
}

/// وصف الدين في القوائم: ملاحظته، أو نوع مصدره.
String debtLabel(BuildContext context, DebtView d) =>
    d.debt.note ?? context.l10n.debtSourceLabel(d.source, d.direction);

/// «استلام مبلغ» / «سداد مبلغ» من زر الإجراءات السريعة: الشخص ← المبلغ ← حفظ.
/// يُعرض فقط من لهم ديون مفتوحة في هذا الاتجاه.
Future<void> startSettle(
  BuildContext context,
  WidgetRef ref,
  DebtDirection direction,
) async {
  final l10n = context.l10n;
  final service = ref.read(debtServiceProvider);
  final people =
      (await service
              .watchPeople(
                direction: direction,
                filter: const PeopleFilter(status: PeopleStatus.open),
              )
              .first)
          .where(
            (p) =>
                (direction == DebtDirection.owedToMe
                    ? p.receivable
                    : p.payable) >
                0,
          )
          .toList();
  if (!context.mounted) return;
  if (people.isEmpty) {
    showMessage(
      context,
      direction == DebtDirection.owedToMe
          ? l10n.noOneOwesYou
          : l10n.youOweNoOne,
      error: true,
    );
    return;
  }
  final picked = people.length == 1
      ? people.single
      : await showModalBottomSheet<PersonSummary>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) =>
              _PersonChooser(people: people, direction: direction),
        );
  if (picked == null || !context.mounted) return;
  final profile = await service.profile(picked.contact.id);
  if (profile == null || !context.mounted) return;
  await showPaymentSheet(context, profile: profile, direction: direction);
}

class _PersonChooser extends ConsumerWidget {
  const _PersonChooser({required this.people, required this.direction});

  final List<PersonSummary> people;
  final DebtDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final color = direction == DebtDirection.owedToMe ? c.income : c.expense;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              l10n.settleAction(direction),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(l10n.choosePerson, style: TextStyle(color: c.textSecondary)),
            const SizedBox(height: 8),
            for (final p in people)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    p.contact.name.characters.first,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(p.contact.name),
                trailing: AmountText(
                  direction == DebtDirection.owedToMe
                      ? p.receivable
                      : p.payable,
                  color: color,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(context, p),
              ),
          ],
        ),
      ),
    );
  }
}

/// «مسامحة بالمتبقي» (لي) أو «إعفاء من المتبقي» (عليّ) مع تأكيد يوضح الأثر.
/// [debtId] لدين واحد، وإلا كل ديون الاتجاه المفتوحة.
Future<void> confirmWriteOff(
  BuildContext context,
  WidgetRef ref, {
  required PersonProfile profile,
  required DebtDirection direction,
  int? debtId,
}) async {
  final l10n = context.l10n;
  final money = ref.read(moneyFormatterProvider);
  final open = profile
      .openDebts(direction)
      .where((d) => debtId == null || d.id == debtId);
  final amount = open.fold(0, (s, d) => s + d.remaining);
  if (amount == 0) return;
  final owedToMe = direction == DebtDirection.owedToMe;
  final ok = await confirmAction(
    context,
    title: owedToMe ? l10n.forgiveRemaining : l10n.forgivenRemaining,
    message: owedToMe
        ? l10n.forgiveBodyOwedToMe(money.inline(amount))
        : l10n.forgiveBodyIOwe(money.inline(amount)),
    confirmLabel: owedToMe ? l10n.forgiveRemaining : l10n.forgivenRemaining,
    destructive: owedToMe,
    icon: Icons.handshake_outlined,
  );
  if (!ok || !context.mounted) return;
  try {
    final category = await ref
        .read(categoryServiceProvider)
        .ensureSystemCategory(
          owedToMe ? kWriteOffCategory : kForgivenCategory,
          arabic: ref.read(isArabicProvider),
        );
    await ref
        .read(debtServiceProvider)
        .writeOffRemaining(
          contactId: profile.contact.id,
          direction: direction,
          debtId: debtId,
          date: DateTime.now(),
          categoryId: category.id,
        );
    if (context.mounted) showMessage(context, l10n.saved);
  } on Object catch (e) {
    if (context.mounted) showError(context, e);
  }
}
