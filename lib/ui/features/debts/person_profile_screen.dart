// =============================================================================
// الشاشة 11: الملف المالي للشخص (FR-18).
//
// - بطاقة مستقلة لكل اتجاه (لي / عليّ): المتبقي، شريط السداد مع «نسبة السداد»
//   نصاً (والمُسامَح منفصلاً)، الحالة، الاستحقاق، وزر حسب الاتجاه: «استلام
//   مبلغ» لديون «لي» و«سداد مبلغ» لديون «عليّ»، مع «مسامحة بالمتبقي».
// - الصافي كمعلومة فقط عند وجود الاتجاهين (لا مقاصة تلقائية).
// - الخط الزمني مع «الرصيد بعد العملية» لكل سطر، والدفعات الملغاة مشطوبة.
// - القائمة (⋮): كشف الحساب، الأرشفة (بشرط المتبقي صفر)، الحذف (بلا حركات).
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
import 'debt_actions.dart';
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
        final archived = p.contact.isArchived;
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
                onSelected: (v) => _onMenu(context, ref, p, v),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'statement',
                    child: Text(l10n.statement),
                  ),
                  if (archived)
                    PopupMenuItem(
                      value: 'unarchive',
                      child: Text(l10n.unarchive),
                    )
                  else if (p.canArchive)
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(l10n.archivePerson),
                    ),
                  if (p.canDelete)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        l10n.deletePerson,
                        style: TextStyle(color: c.expense),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(Insets.screen),
            children: [
              if (archived)
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: Pill(l10n.personArchivedBanner, color: c.archive),
                ),
              if (p.debts.isEmpty)
                EmptyState(
                  icon: Icons.people_outline_rounded,
                  message: l10n.noDebts,
                ),
              for (final d in DebtDirection.values)
                if (p.summary(d) case final summary?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.sm),
                    child: _DirectionCard(
                      profile: p,
                      summary: summary,
                      canAct: !archived,
                    ),
                  ),
              if (p.hasBothDirections) _NetInfo(profile: p),
              const SizedBox(height: Insets.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.newDebt),
                      onPressed: archived
                          ? null
                          : () => context.push(
                              AppRoutes.newDebt(contactId: contactId),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: Text(l10n.statement),
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

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    PersonProfile p,
    String action,
  ) async {
    final l10n = context.l10n;
    final contacts = ref.read(contactServiceProvider);
    try {
      switch (action) {
        case 'statement':
          await context.push(AppRoutes.personStatement(contactId));
        case 'archive':
          if (await confirmAction(
            context,
            title: l10n.archivePerson,
            message: l10n.archivePersonBody,
            confirmLabel: l10n.archive,
            destructive: false,
            icon: Icons.inventory_2_outlined,
          )) {
            await contacts.archive(contactId);
            if (context.mounted) context.pop();
          }
        case 'unarchive':
          await contacts.unarchive(contactId);
        case 'delete':
          if (await confirmAction(
            context,
            title: l10n.deletePerson,
            message: l10n.deletePersonBody,
            confirmLabel: l10n.delete,
          )) {
            await contacts.delete(contactId);
            if (context.mounted) context.pop();
          }
      }
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

/// بطاقة اتجاه واحد (لي أو عليّ) — منفصلة عن الاتجاه الآخر.
class _DirectionCard extends ConsumerWidget {
  const _DirectionCard({
    required this.profile,
    required this.summary,
    required this.canAct,
  });

  final PersonProfile profile;
  final DirectionSummary summary;
  final bool canAct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final money = ref.watch(moneyFormatterProvider);
    final dates = ref.watch(dateLabelsProvider);
    final direction = summary.direction;
    final owedToMe = direction == DebtDirection.owedToMe;
    final color = owedToMe ? c.income : c.expense;
    final status = summary.status;
    final statusColor = switch (status) {
      DebtStatus.closed => c.income,
      DebtStatus.partial => c.warning,
      DebtStatus.open => c.expense,
    };
    final name = profile.contact.name.split(' ').first;
    final open = summary.remaining > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.directionTitle(direction, name),
                  style: TextStyle(color: c.textSecondary),
                ),
              ),
              if (summary.overdueDebts > 0) ...[
                Pill(l10n.statusOverdue, color: c.expense),
                const SizedBox(width: 6),
              ],
              Pill(l10n.debtStatusName(status), color: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          AmountText(
            summary.remaining,
            color: open ? color : c.textSecondary,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          AppProgressBar(value: summary.progress / 100, color: c.income),
          const SizedBox(height: 6),
          // مصطلح «نسبة السداد» نصاً تحت الشريط، والمسامحة منفصلة.
          Text(
            [
              l10n.paymentRate('${summary.progress}'),
              if (summary.writtenOff > 0)
                l10n.writtenOffRate('${summary.writtenOffPercent}'),
            ].join(' • '),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                l10n.paidAmount(money.inline(summary.paid, withSymbol: false)),
                style: TextStyle(fontSize: 12.5, color: c.textSecondary),
              ),
              Text(
                l10n.totalDebtsAmount(
                  money.inline(summary.total, withSymbol: false),
                ),
                style: TextStyle(fontSize: 12.5, color: c.textSecondary),
              ),
              if (summary.nearestDue != null)
                Text(
                  l10n.dueOn(dates.day(summary.nearestDue!)),
                  style: TextStyle(fontSize: 12.5, color: c.textSecondary),
                ),
            ],
          ),
          if (open && canAct) ...[
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: color),
                    icon: Icon(
                      owedToMe
                          ? Icons.call_received_rounded
                          : Icons.call_made_rounded,
                      size: 18,
                    ),
                    label: Text(l10n.settleAction(direction)),
                    onPressed: () => showPaymentSheet(
                      context,
                      profile: profile,
                      direction: direction,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => confirmWriteOff(
                    context,
                    ref,
                    profile: profile,
                    direction: direction,
                  ),
                  child: Text(
                    owedToMe ? l10n.forgiveRemaining : l10n.forgivenRemaining,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// الصافي كمعلومة فقط — لا يُخصم أحد الاتجاهين من الآخر.
class _NetInfo extends ConsumerWidget {
  const _NetInfo({required this.profile});

  final PersonProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final money = ref.watch(moneyFormatterProvider);
    final net = profile.net;
    final name = profile.contact.name.split(' ').first;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: c.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  net == 0
                      ? l10n.netEven
                      : net > 0
                      ? l10n.netForYou(money.inline(net))
                      : l10n.netForThem(name, money.inline(-net)),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  l10n.netInfoHint,
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
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
    final money = ref.watch(moneyFormatterProvider);
    final owedToMe = entry.direction == DebtDirection.owedToMe;
    final dotColor = switch (entry.kind) {
      TimelineKind.debt => owedToMe ? c.income : c.expense,
      TimelineKind.payment => c.transfer,
      TimelineKind.writeOff => c.archive,
    };

    final debt = profile.debt(entry.debtId);
    final title = switch (entry.kind) {
      TimelineKind.debt => [
        l10n.debtSourceLabel(entry.source!, entry.direction),
        if (entry.note != null) entry.note!,
      ].join(' — '),
      TimelineKind.payment =>
        '${l10n.paymentName(entry.direction)} '
            '${money.inline(entry.amount, withSymbol: false)}',
      TimelineKind.writeOff => l10n.writeOffName(entry.direction),
    };
    final detail = entry.kind == TimelineKind.debt
        ? (entry.accountName ?? entry.categoryName)
        : entry.kind == TimelineKind.payment
        ? entry.accountName
        : entry.categoryName;
    final strike = entry.cancelled
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : const TextStyle();

    return InkWell(
      onTap: () => _showActions(context, ref, debt),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  CircleAvatar(
                    radius: 6,
                    backgroundColor: entry.cancelled ? c.border : dotColor,
                  ),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: strike.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (entry.cancelled) ...[
                          const SizedBox(width: 6),
                          Pill(l10n.cancelledBadge, color: c.textSecondary),
                        ],
                      ],
                    ),
                    Text(
                      [
                        dates.day(entry.date),
                        l10n.directionName(entry.direction),
                        ?detail,
                      ].join(' • '),
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                    // «الرصيد بعد العملية» في اتجاه السطر.
                    if (entry.balanceAfter != null)
                      Text(
                        l10n.balanceAfter(
                          money.inline(entry.balanceAfter!, withSymbol: false),
                        ),
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AmountText(
                entry.effect,
                showSign: true,
                withSymbol: false,
                color: entry.cancelled ? c.textSecondary : dotColor,
                style: strike.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// خيارات السطر: للدين (استلام/سداد، مسامحة، تعديل، حذف)، ولعملية السداد
  /// (تفصيل التوزيع وإلغاء العملية).
  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    DebtView? debt,
  ) async {
    final l10n = context.l10n;
    final c = context.colors;
    final money = ref.read(moneyFormatterProvider);
    final canAct = !profile.contact.isArchived;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.kind == TimelineKind.debt && debt != null) ...[
              if (debt.isOpen && canAct) ...[
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: Text(l10n.settleAction(debt.direction)),
                  onTap: () => Navigator.pop(ctx, 'pay'),
                ),
                ListTile(
                  leading: const Icon(Icons.handshake_outlined),
                  title: Text(
                    debt.direction == DebtDirection.owedToMe
                        ? l10n.forgiveRemaining
                        : l10n.forgivenRemaining,
                  ),
                  onTap: () => Navigator.pop(ctx, 'forgive'),
                ),
              ],
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.editDebt),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              if (!debt.hasMovements)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: c.expense),
                  title: Text(
                    l10n.deleteDebt,
                    style: TextStyle(color: c.expense),
                  ),
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
            ],
            if (entry.kind == TimelineKind.payment) ...[
              ListTile(
                title: Text(
                  l10n.distribution,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final a in entry.allocations)
                if (profile.debt(a.debtId) case final d?)
                  ListTile(
                    dense: true,
                    title: Text(debtLabel(ctx, d)),
                    trailing: Text(money.inline(a.amount)),
                  ),
              if (!entry.cancelled)
                ListTile(
                  leading: Icon(Icons.block_rounded, color: c.expense),
                  title: Text(
                    l10n.cancelOperation,
                    style: TextStyle(color: c.expense),
                  ),
                  onTap: () => Navigator.pop(ctx, 'cancel'),
                ),
            ],
            if (entry.kind == TimelineKind.writeOff)
              ListTile(
                leading: const Icon(Icons.handshake_outlined),
                title: Text(l10n.writeOffName(entry.direction)),
                subtitle: entry.categoryName == null
                    ? null
                    : Text(entry.categoryName!),
                trailing: Text(money.inline(entry.amount)),
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
            direction: debt!.direction,
            debtId: debt.id,
          );
        case 'forgive':
          await confirmWriteOff(
            context,
            ref,
            profile: profile,
            direction: debt!.direction,
            debtId: debt.id,
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
        case 'cancel':
          if (await confirmAction(
            context,
            title: l10n.cancelOperation,
            message: l10n.cancelOperationBody,
            confirmLabel: l10n.cancelOperation,
            icon: Icons.block_rounded,
          )) {
            await service.cancelOperation(entry.operationId!);
          }
      }
    } on Object catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
