// =============================================================================
// الشاشة 10: دفتر الديون — قائمة الأشخاص.
// - بطاقة الملخص: مجموع «لي» و«عليّ» ومؤشرات (عدد الأشخاص والديون المتأخرة).
// - تبويبات لي / عليّ / الكل ظاهرة دائماً، وبحث بالاسم أو الهاتف.
// - زر فلترة واحد: الحالة (مفتوح، متأخر، مغلق، مؤرشف) والترتيب فقط.
// - زر إجراءات سريعة: «دين جديد»، «استلام مبلغ»، «سداد مبلغ».
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
import '../../widgets/labels.dart';
import 'debt_actions.dart';

/// التبويب المختار: null = الكل.
class _DirectionTab extends Notifier<DebtDirection?> {
  @override
  DebtDirection? build() => null;

  void select(DebtDirection? d) => state = d;
}

final _directionProvider = NotifierProvider<_DirectionTab, DebtDirection?>(
  _DirectionTab.new,
);

class _Query extends Notifier<String> {
  @override
  String build() => '';

  void set(String q) => state = q;
}

final _queryProvider = NotifierProvider<_Query, String>(_Query.new);

class _Filter extends Notifier<PeopleFilter> {
  @override
  PeopleFilter build() => const PeopleFilter();

  void set(PeopleFilter f) => state = f;
}

final _filterProvider = NotifierProvider<_Filter, PeopleFilter>(_Filter.new);

final _peopleProvider = StreamProvider.autoDispose<List<PersonSummary>>(
  (ref) => ref
      .watch(debtServiceProvider)
      .watchPeople(
        direction: ref.watch(_directionProvider),
        query: ref.watch(_queryProvider),
        filter: ref.watch(_filterProvider),
      ),
);

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final totals = ref.watch(debtTotalsProvider).value ?? DebtTotals.zero;
    final direction = ref.watch(_directionProvider);
    final filter = ref.watch(_filterProvider);
    final people = ref.watch(_peopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchPeople,
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: ref.read(_queryProvider.notifier).set,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.debtsTitle),
                  Text(
                    l10n.debtsSubtitle,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: l10n.searchPeople,
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              if (_searching) ref.read(_queryProvider.notifier).set('');
              setState(() => _searching = !_searching);
            },
          ),
          IconButton(
            tooltip: l10n.filterDebts,
            icon: Badge(
              isLabelVisible: filter.activeCount > 0,
              label: Text('${filter.activeCount}'),
              child: const Icon(Icons.filter_alt_outlined),
            ),
            onPressed: () => _showFilter(context),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: const _SpeedDial(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.screen, 0, Insets.screen, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: _TotalBox(
                  label: l10n.owedToMe,
                  value: totals.owedToMe,
                  color: c.income,
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: _TotalBox(
                  label: l10n.iOwe,
                  value: totals.iOwe,
                  color: c.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // مؤشرات الملخص: عدد الأشخاص وعدد الديون المتأخرة.
          Row(
            children: [
              Icon(Icons.people_alt_outlined, size: 16, color: c.textSecondary),
              const SizedBox(width: 4),
              Text(
                l10n.peopleCount(totals.people),
                style: TextStyle(fontSize: 12.5, color: c.textSecondary),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: totals.overdueDebts > 0 ? c.expense : c.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.overdueCount(totals.overdueDebts),
                style: TextStyle(
                  fontSize: 12.5,
                  color: totals.overdueDebts > 0 ? c.expense : c.textSecondary,
                  fontWeight: totals.overdueDebts > 0
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          SegmentedTabs<DebtDirection?>(
            values: const [null, DebtDirection.owedToMe, DebtDirection.iOwe],
            selected: direction,
            label: (d) => d == null ? l10n.all : l10n.directionName(d),
            colorOf: (d) => switch (d) {
              DebtDirection.owedToMe => c.income,
              DebtDirection.iOwe => c.expense,
              null => c.textPrimary,
            },
            onChanged: ref.read(_directionProvider.notifier).select,
          ),
          const SizedBox(height: Insets.md),
          AsyncBody(
            value: people,
            builder: (list) => list.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline_rounded,
                    message:
                        filter.activeCount > 0 ||
                            ref.watch(_queryProvider).isNotEmpty
                        ? l10n.noResults
                        : l10n.noDebts,
                  )
                : Column(
                    children: [
                      for (final p in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PersonTile(summary: p, direction: direction),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilter(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final l10n = ctx.l10n;
        final filter = ref.watch(_filterProvider);
        final notifier = ref.read(_filterProvider.notifier);
        Widget chip(String label, bool selected, VoidCallback onTap) =>
            ChoiceChip(
              label: Text(label),
              selected: selected,
              labelStyle: TextStyle(
                color: selected ? Colors.white : ctx.colors.textPrimary,
              ),
              onSelected: (_) => onTap(),
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.screen,
              0,
              Insets.screen,
              Insets.screen,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.filterDebts,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: Insets.md),
                Text(l10n.statusFilter),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in PeopleStatus.values)
                      chip(
                        switch (s) {
                          PeopleStatus.all => l10n.all,
                          PeopleStatus.open => l10n.statusOpen,
                          PeopleStatus.overdue => l10n.statusOverdue,
                          PeopleStatus.closed => l10n.statusClosed,
                          PeopleStatus.archived => l10n.archivedBadge,
                        },
                        filter.status == s,
                        () => notifier.set(
                          PeopleFilter(status: s, sort: filter.sort),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Insets.md),
                Text(l10n.sort),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in PeopleSort.values)
                      chip(
                        switch (s) {
                          PeopleSort.nearestDue => l10n.sortNearestDue,
                          PeopleSort.amountDesc => l10n.sortAmountDesc,
                          PeopleSort.lastActivity => l10n.sortLastActivity,
                        },
                        filter.sort == s,
                        () => notifier.set(
                          PeopleFilter(status: filter.status, sort: s),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Insets.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          notifier.set(const PeopleFilter());
                          Navigator.pop(ctx);
                        },
                        child: Text(l10n.reset),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.apply),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// زر الإجراءات السريعة (Speed Dial): دين جديد، استلام مبلغ، سداد مبلغ.
class _SpeedDial extends ConsumerStatefulWidget {
  const _SpeedDial();

  @override
  ConsumerState<_SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends ConsumerState<_SpeedDial> {
  bool _open = false;

  void _run(Future<void> Function() action) {
    setState(() => _open = false);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    Widget action({
      required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingActionButton.extended(
        heroTag: label,
        elevation: 2,
        backgroundColor: c.surface,
        foregroundColor: color,
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: _open
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    action(
                      label: l10n.receiveAmount,
                      icon: Icons.call_received_rounded,
                      color: c.income,
                      onTap: () => _run(
                        () => startSettle(context, ref, DebtDirection.owedToMe),
                      ),
                    ),
                    action(
                      label: l10n.payAmount,
                      icon: Icons.call_made_rounded,
                      color: c.expense,
                      onTap: () => _run(
                        () => startSettle(context, ref, DebtDirection.iOwe),
                      ),
                    ),
                    action(
                      label: l10n.newDebt,
                      icon: Icons.add_rounded,
                      color: c.primary,
                      onTap: () =>
                          _run(() => context.push(AppRoutes.newDebt())),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        FloatingActionButton(
          heroTag: 'debts-speed-dial',
          backgroundColor: c.brand,
          foregroundColor: Colors.white,
          tooltip: l10n.newDebt,
          onPressed: () => setState(() => _open = !_open),
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }
}

class _TotalBox extends StatelessWidget {
  const _TotalBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(Radii.card),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12.5)),
        AmountText(
          value,
          color: color,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ],
    ),
  );
}

class _PersonTile extends ConsumerWidget {
  const _PersonTile({required this.summary, required this.direction});

  final PersonSummary summary;
  final DebtDirection? direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final money = ref.watch(moneyFormatterProvider);
    final archived = summary.contact.isArchived;
    final closed = summary.isClosed;
    final due = summary.nearestDue;
    final dueInfo = due == null || closed ? null : dueLabel(l10n, due);
    final avatarColor = summary.receivable >= summary.payable
        ? c.income
        : c.expense;

    // «لي» و«عليّ» يُعرضان منفصلين (لا مقاصة تلقائية).
    final amounts = [
      if (summary.receivable > 0 || (closed && summary.payable == 0))
        (summary.receivable, c.income),
      if (summary.payable > 0) (summary.payable, c.expense),
    ];

    return AppCard(
      onTap: () => context.push(AppRoutes.person(summary.contact.id)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor.withValues(alpha: 0.12),
                child: Text(
                  summary.contact.name.characters.first,
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.contact.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    if (archived)
                      Pill(l10n.archivedBadge, color: c.archive)
                    else if (closed)
                      Pill(l10n.statusClosed, color: c.income)
                    else if (dueInfo != null)
                      Pill(
                        dueInfo.$1,
                        color: dueInfo.$2 ? c.expense : c.warning,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (value, color) in amounts)
                    AmountText(
                      value,
                      color: closed ? c.textSecondary : color,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  Text(
                    l10n.ofTotal(money.format(summary.total, compact: true)),
                    style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppProgressBar(
            value: summary.progress / 100,
            color: c.income,
            height: 6,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.paymentRate('${summary.progress}'),
              style: TextStyle(fontSize: 11.5, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
