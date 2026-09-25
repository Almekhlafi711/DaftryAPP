// =============================================================================
// الشاشة 10: دفتر الديون — قائمة الأشخاص.
// مجموع «لي» و«عليّ» في الأعلى، ثم تبويبات الاتجاه، ثم كل شخص في سطر واحد
// بالمتبقي وشريط السداد وشارة الاستحقاق (المتأخر بالأحمر).
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

final _peopleProvider = StreamProvider.autoDispose<List<PersonSummary>>(
  (ref) => ref
      .watch(debtServiceProvider)
      .watchPeople(
        direction: ref.watch(_directionProvider),
        query: ref.watch(_queryProvider),
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
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              if (_searching) ref.read(_queryProvider.notifier).set('');
              setState(() => _searching = !_searching);
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-debt',
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newDebt),
        onPressed: () => context.push(AppRoutes.newDebt()),
      ),
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
                    message: l10n.noDebts,
                  )
                : Column(
                    children: [
                      for (final p in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PersonTile(summary: p),
                        ),
                    ],
                  ),
          ),
        ],
      ),
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

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.summary});

  final PersonSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final net = summary.net;
    final color = net >= 0 ? c.income : c.expense;
    final settled = summary.openDebts == 0;
    final due = summary.nearestDue;
    final dueInfo = due == null ? null : dueLabel(l10n, due);

    return AppCard(
      onTap: () => context.push(AppRoutes.person(summary.contact.id)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  summary.contact.name.characters.first,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
                    if (settled)
                      Pill(l10n.statusSettled, color: c.income)
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
                  AmountText(
                    net.abs(),
                    color: settled ? c.textSecondary : color,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, _) => Text(
                      l10n.ofTotal(
                        ref
                            .watch(moneyFormatterProvider)
                            .format(summary.totalAmount, compact: true),
                      ),
                      style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppProgressBar(value: summary.progress, color: c.income, height: 6),
        ],
      ),
    );
  }
}
