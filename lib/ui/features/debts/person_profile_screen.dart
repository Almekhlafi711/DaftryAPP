// =============================================================================
// الشاشة 11: الملف المالي للشخص (FR-18، الشكل 4-19 في الوثيقة).
//
// - الشريط العلوي: رجوع، الاسم والهاتف، زر «تعديل» بيانات الشخص، والقائمة (⋮)
//   للأرشفة (بشرط المتبقي صفر) والحذف (بلا حركات).
// - بطاقة مستقلة لكل اتجاه (لي / عليّ): «المتبقي لي عند أحمد» مع شارة
//   الاستحقاق، المتبقي بخط كبير، الشريط، ثم الإجمالي والمدفوع ونسبة السداد
//   (والمُسامَح منفصلاً).
// - صف الأزرار: الزر الرئيسي يتبع الاتجاه («استلام مبلغ» لديون لي، «سداد
//   مبلغ» لديون عليّ)، ثم «دين جديد» و«كشف».
// - الصافي كمعلومة فقط عند وجود الاتجاهين (لا مقاصة تلقائية).
// - «الخط الزمني والرصيد بعد كل عملية»: الدفعة الملغاة تبقى مشطوبة ولا تُحتسب.
// - في الأسفل «مسامحة بالمتبقي» لإغلاق دين لن يُسدَّد بدل حذفه.
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
        // الاتجاهات التي عليها متبقٍ: إن كان واحداً فقط، يظهر زره الرئيسي
        // في صف الأزرار و«مسامحة بالمتبقي» في الأسفل.
        final openDirections = [
          for (final d in DebtDirection.values)
            if ((p.summary(d)?.remaining ?? 0) > 0) d,
        ];
        final single = !archived && openDirections.length == 1
            ? openDirections.single
            : null;
        const compact = EdgeInsets.symmetric(horizontal: 8);
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
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(AppRoutes.editPerson(contactId)),
              ),
              if (archived || p.canArchive || p.canDelete)
                PopupMenuButton<String>(
                  onSelected: (v) => _onMenu(context, ref, p, v),
                  itemBuilder: (_) => [
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
                      // مع وجود الاتجاهين المفتوحين يبقى زر كل اتجاه في بطاقته.
                      showActions: !archived && openDirections.length > 1,
                    ),
                  ),
              if (p.hasBothDirections) ...[
                _NetInfo(profile: p),
                const SizedBox(height: Insets.sm),
              ],
              // صف الأزرار: الزر الرئيسي يتبع الاتجاه، ثم دين جديد، ثم كشف.
              Row(
                children: [
                  if (single != null) ...[
                    Expanded(
                      flex: 5,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: single == DebtDirection.owedToMe
                              ? c.income
                              : c.expense,
                          padding: compact,
                        ),
                        onPressed: () => showPaymentSheet(
                          context,
                          profile: p,
                          direction: single,
                        ),
                        child: _IconLabel(
                          icon: single == DebtDirection.owedToMe
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          label: l10n.settleAction(single),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: compact),
                      onPressed: archived
                          ? null
                          : () => context.push(
                              AppRoutes.newDebt(contactId: contactId),
                            ),
                      child: Text(
                        l10n.newDebt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: compact),
                      onPressed: () =>
                          context.push(AppRoutes.personStatement(contactId)),
                      child: _IconLabel(
                        icon: Icons.description_outlined,
                        label: l10n.statement,
                      ),
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
              // «مسامحة بالمتبقي» لإغلاق دين لن يُسدَّد بدل حذفه.
              if (single != null) ...[
                const SizedBox(height: Insets.sm),
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: c.warning),
                    icon: const Icon(Icons.back_hand_outlined, size: 18),
                    label: Text(
                      single == DebtDirection.owedToMe
                          ? l10n.forgiveRemaining
                          : l10n.forgivenRemaining,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => confirmWriteOff(
                      context,
                      ref,
                      profile: p,
                      direction: single,
                    ),
                  ),
                ),
              ],
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
    required this.showActions,
  });

  final PersonProfile profile;
  final DirectionSummary summary;

  /// زر الاستلام/السداد والمسامحة داخل البطاقة (عند وجود الاتجاهين).
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final money = ref.watch(moneyFormatterProvider);
    final dates = ref.watch(dateLabelsProvider);
    final direction = summary.direction;
    final owedToMe = direction == DebtDirection.owedToMe;
    final color = owedToMe ? c.income : c.expense;
    final name = profile.contact.name.split(' ').first;
    final open = summary.remaining > 0;
    final due = summary.nearestDue;
    final overdue = summary.overdueDebts > 0;
    final secondary = TextStyle(fontSize: 12.5, color: c.textSecondary);

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
              // شارة الاستحقاق، أو الحالة إن لم يكن هناك موعد.
              if (!open)
                Pill(l10n.statusClosed, color: c.income)
              else if (overdue)
                Pill(l10n.statusOverdue, color: c.expense)
              else if (due != null)
                Pill(l10n.dueOn(dates.day(due)), color: c.warning)
              else
                Pill(l10n.noDueDate, color: c.textSecondary),
            ],
          ),
          const SizedBox(height: 6),
          AmountText(
            summary.remaining,
            color: open ? color : c.textSecondary,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          AppProgressBar(value: summary.progress / 100, color: c.income),
          const SizedBox(height: 8),
          // الإجمالي — المدفوع — نسبة السداد (والمُسامَح منفصلاً).
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.totalDebtsAmount(
                    money.inline(summary.total, withSymbol: false),
                  ),
                  style: secondary,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.paidAmount(
                    money.inline(summary.paid, withSymbol: false),
                  ),
                  textAlign: TextAlign.center,
                  style: secondary,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.paymentRate('${summary.progress}'),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (summary.writtenOff > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.writtenOffRate('${summary.writtenOffPercent}'),
              style: TextStyle(fontSize: 12, color: c.warning),
            ),
          ],
          if (open && showActions) ...[
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () => showPaymentSheet(
                      context,
                      profile: profile,
                      direction: direction,
                    ),
                    child: _IconLabel(
                      icon: owedToMe
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      label: l10n.settleAction(direction),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: c.warning,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => confirmWriteOff(
                      context,
                      ref,
                      profile: profile,
                      direction: direction,
                    ),
                    child: Text(
                      owedToMe ? l10n.forgiveRemaining : l10n.forgivenRemaining,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
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
    // الأحمر = عملية تزيد الرصيد (دين)، والأخضر = استلام/سداد يُنقصه،
    // والبرتقالي = مسامحة.
    final dotColor = switch (entry.kind) {
      TimelineKind.debt => c.expense,
      TimelineKind.payment => c.income,
      TimelineKind.writeOff => c.warning,
    };
    final owedToMe = entry.direction == DebtDirection.owedToMe;

    final debt = profile.debt(entry.debtId);
    final title = switch (entry.kind) {
      TimelineKind.debt => [
        l10n.debtSourceLabel(entry.source!, entry.direction),
        if (entry.note != null) entry.note!,
      ].join(' — '),
      TimelineKind.payment => l10n.paymentName(entry.direction),
      TimelineKind.writeOff => l10n.writeOffName(entry.direction),
    };
    // أثر العملية على الحسابات بلغة بسيطة: من/في الحساب، أو دخل/مصروف فئة
    // بدون حساب، أو «الدفتر فقط».
    final account = entry.accountName;
    final category = entry.categoryName;
    final effect = switch (entry.kind) {
      TimelineKind.debt => switch (entry.source) {
        DebtSource.loan when account != null =>
          owedToMe ? l10n.tlFrom(account) : l10n.tlInto(account),
        DebtSource.creditSale => [
          if (category != null) l10n.tlIncomeCat(category),
          l10n.tlNoAccount,
        ].join(' • '),
        DebtSource.creditPurchase => [
          if (category != null) l10n.tlExpenseCat(category),
          l10n.tlNoAccount,
        ].join(' • '),
        _ => l10n.tlLedgerOnly,
      },
      TimelineKind.payment =>
        account == null
            ? l10n.tlLedgerOnly
            : owedToMe
            ? l10n.tlInto(account)
            : l10n.tlFrom(account),
      TimelineKind.writeOff => category,
    };
    final strike = entry.cancelled
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : const TextStyle();
    final muted = entry.cancelled ? c.textSecondary : null;

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
                  const SizedBox(height: 13),
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
                    Text(
                      title,
                      style: strike.copyWith(
                        fontWeight: FontWeight.w700,
                        color: muted,
                      ),
                    ),
                    Text(
                      [
                        dates.day(entry.date),
                        if (entry.cancelled) l10n.tlCancelled else ?effect,
                      ].join(' • '),
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(
                    entry.effect,
                    showSign: true,
                    withSymbol: false,
                    color: entry.cancelled ? c.textSecondary : dotColor,
                    style: strike.copyWith(fontWeight: FontWeight.w800),
                  ),
                  // «الرصيد بعد العملية» في اتجاه السطر.
                  if (entry.balanceAfter != null)
                    Text(
                      l10n.balanceShort(
                        money.inline(entry.balanceAfter!, withSymbol: false),
                      ),
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                ],
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

/// أيقونة ونص يتقلّص بنقاط عند ضيق المساحة (أزرار الصف في الشاشات الصغيرة
/// وباللغة الإنجليزية الأطول).
class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18),
      const SizedBox(width: 6),
      Flexible(
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}
