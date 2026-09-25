// =============================================================================
// الشاشة 11: الملف المالي للشخص (FR-18).
// صفحة واحدة لكل علاقة مالية: المتبقي والمدفوع وإجمالي الديون والاستحقاق،
// ثم ثلاثة إجراءات (تسجيل دفعة، دين جديد، كشف)، ثم خط زمني لكل الحركات.
// تعديل بيانات الشخص في شاشة مستقلة (أيقونة الشخص)، وقائمة (⋮) لخيارات إضافية.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/enums.dart';
import '../../../domain/models/debt_models.dart';
import '../../../services/providers.dart';
import '../../router/routes.dart';
import '../../state/app_state.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/labels.dart';
import 'payment_sheet.dart';

class PersonProfileScreen extends ConsumerWidget {
  const PersonProfileScreen({super.key, required this.contactId});

  final int contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final profile = ref.watch(personProfileProvider(contactId));

    return AsyncBody(
      value: profile,
      builder: (p) {
        if (p == null) return Scaffold(appBar: AppBar());
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Column(
              children: [
                Text(p.contact.name),
                if (p.contact.phone != null)
                  Text(
                    p.contact.phone!,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: l10n.editPerson,
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () => context.push(AppRoutes.editPerson(contactId)),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'statement') {
                    context.push(AppRoutes.personStatement(contactId));
                  } else if (v == 'hide') {
                    await ref
                        .read(contactServiceProvider)
                        .setActive(contactId, active: false);
                    if (context.mounted) context.pop();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'statement',
                    child: Text(l10n.statement),
                  ),
                  PopupMenuItem(value: 'hide', child: Text(l10n.hidePerson)),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(Insets.screen),
            children: [
              _SummaryCard(profile: p),
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      style: _compact,
                      icon: const Icon(Icons.add_rounded),
                      label: _OneLine(l10n.recordPayment),
                      onPressed: p.openDebts.isEmpty
                          ? null
                          : () => showPaymentSheet(context, profile: p),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: _compact,
                      onPressed: () =>
                          context.push(AppRoutes.newDebt(contactId: contactId)),
                      child: _OneLine(l10n.newDebt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: _compact,
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: _OneLine(l10n.statement),
                      onPressed: () =>
                          context.push(AppRoutes.personStatement(contactId)),
                    ),
                  ),
                ],
              ),
              SectionTitle(l10n.timeline),
              if (p.timeline.isEmpty)
                EmptyState(icon: Icons.timeline_rounded, message: l10n.noDebts)
              else
                AppCard(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    children: [
                      for (var i = 0; i < p.timeline.length; i++)
                        _TimelineRow(
                          entry: p.timeline[i],
                          isLast: i == p.timeline.length - 1,
                          profile: p,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// أزرار الإجراءات الثلاثة بحشوة أصغر حتى تتسع نصوصها في سطر واحد.
final _compact = ButtonStyle(
  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10)),
);

/// نص زر بسطر واحد يتقلص عند ضيق المساحة بدل الانقسام على سطرين.
class _OneLine extends StatelessWidget {
  const _OneLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.profile});

  final PersonProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final money = ref.watch(moneyFormatterProvider);
    final dates = ref.watch(dateLabelsProvider);
    final net = profile.net;
    final color = net >= 0 ? c.income : c.expense;
    final status = profile.status;
    final statusColor = switch (status) {
      DebtStatus.settled => c.income,
      DebtStatus.partial => c.warning,
      DebtStatus.open => c.expense,
    };
    final name = profile.contact.name.split(' ').first;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  net == 0
                      ? l10n.profileSettled
                      : net > 0
                      ? l10n.profileOwedToMe(name)
                      : l10n.profileIOwe(name),
                  style: TextStyle(color: c.textSecondary),
                ),
              ),
              Pill(l10n.debtStatusName(status), color: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          AmountText(
            net.abs(),
            color: color,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          AppProgressBar(
            value: profile.totalDebts == 0
                ? 0
                : profile.totalPaid / profile.totalDebts,
            color: c.income,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                l10n.paidAmount(
                  money.inline(profile.totalPaid, withSymbol: false),
                ),
                style: TextStyle(fontSize: 12.5, color: c.textSecondary),
              ),
              Text(
                l10n.totalDebtsAmount(
                  money.inline(profile.totalDebts, withSymbol: false),
                ),
                style: TextStyle(fontSize: 12.5, color: c.textSecondary),
              ),
              if (profile.nearestDue != null)
                Text(
                  l10n.dueOn(dates.day(profile.nearestDue!)),
                  style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  const _TimelineRow({
    required this.entry,
    required this.isLast,
    required this.profile,
  });

  final TimelineEntry entry;
  final bool isLast;
  final PersonProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final dates = ref.watch(dateLabelsProvider);
    final isPayment = entry.kind == TimelineKind.payment;
    // الدفعات بالأخضر والديون بالأحمر الداكن (لون وحدة الديون).
    final dotColor = isPayment ? c.income : const Color(0xFFBE123C);

    final title = isPayment
        ? (entry.direction == DebtDirection.owedToMe
              ? l10n.paymentReceived
              : l10n.paymentMade)
        : (entry.note != null
              ? l10n.debtWithNote(entry.note!)
              : l10n.newDebtEntry);
    // هل دخل المال إلى حسابي؟ (دفعة مستلمة على دين «لي» أو دين «عليّ» اقترضته)
    final moneyIn = isPayment == (entry.direction == DebtDirection.owedToMe);
    final accountText = entry.accountName == null
        ? l10n.withoutAccount
        : moneyIn
        ? l10n.inAccount(entry.accountName!)
        : l10n.fromAccountName(entry.accountName!);

    return InkWell(
      onTap: () => _showActions(context, ref),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // النقطة والخط الرأسي
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  CircleAvatar(radius: 6, backgroundColor: dotColor),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: c.border)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${dates.day(entry.date)} • $accountText',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AmountText(
                entry.signedEffect,
                showSign: true,
                withSymbol: false,
                color: isPayment ? c.income : dotColor,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// خيارات العنصر: للدين (دفعة، تعديل، حذف) وللدفعة (حذف).
  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final c = context.colors;
    final debt = profile.debts.where((d) => d.id == entry.debtId).firstOrNull;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.kind == TimelineKind.debt) ...[
              if (debt != null && debt.status != DebtStatus.settled)
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(l10n.recordPayment),
                  onTap: () => Navigator.pop(ctx, 'pay'),
                ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.editDebt),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: c.expense),
                title: Text(
                  l10n.deleteDebt,
                  style: TextStyle(color: c.expense),
                ),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ] else
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: c.expense),
                title: Text(
                  l10n.deletePayment,
                  style: TextStyle(color: c.expense),
                ),
                onTap: () => Navigator.pop(ctx, 'deletePayment'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    final service = ref.read(debtServiceProvider);
    try {
      switch (action) {
        case 'pay':
          await showPaymentSheet(
            context,
            profile: profile,
            debtId: entry.debtId,
          );
        case 'edit':
          await context.push(AppRoutes.editDebt(entry.debtId));
        case 'delete':
          if (await confirmAction(
            context,
            title: l10n.deleteDebt,
            message: l10n.deleteDebtBody,
            confirmLabel: l10n.delete,
          )) {
            await service.deleteDebt(entry.debtId);
          }
        case 'deletePayment':
          if (await confirmAction(
            context,
            title: l10n.deletePayment,
            message: l10n.deletePaymentBody,
            confirmLabel: l10n.delete,
          )) {
            await service.deletePayment(entry.paymentId!);
          }
      }
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
