// =============================================================================
// الشاشة 6: نافذة الفلترة — كل خيارات التصفية في نافذة سفلية واحدة:
// الفترة، الحساب، النوع والفئة، إظهار حركات الديون، الترتيب؛ مع «تطبيق» و«إعادة ضبط».
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_range.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/transaction_models.dart';
import '../../state/app_state.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';
import 'transactions_providers.dart';

Future<void> showFilterSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );

enum _Period { today, week, month, last30, last3Months, year, all, custom }

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TransactionFilter _draft = ref.read(transactionFilterProvider);
  late _Period _period = _detectPeriod(_draft.range);

  static _Period _detectPeriod(DateRange? r) {
    if (r == null) return _Period.all;
    final now = DateTime.now();
    if (r == DateRange.day(now)) return _Period.today;
    if (r == DateRange.week(now)) return _Period.week;
    if (r == DateRange.month(now)) return _Period.month;
    if (r == DateRange.lastDays(30)) return _Period.last30;
    if (r == DateRange.lastMonths(3)) return _Period.last3Months;
    if (r == DateRange.year(now)) return _Period.year;
    return _Period.custom;
  }

  Future<void> _setPeriod(_Period p) async {
    final now = DateTime.now();
    DateRange? range;
    switch (p) {
      case _Period.today:
        range = DateRange.day(now);
      case _Period.week:
        range = DateRange.week(now);
      case _Period.month:
        range = DateRange.month(now);
      case _Period.last30:
        range = DateRange.lastDays(30);
      case _Period.last3Months:
        range = DateRange.lastMonths(3);
      case _Period.year:
        range = DateRange.year(now);
      case _Period.all:
        range = null;
      case _Period.custom:
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked == null) return;
        range = DateRange.inclusiveDays(picked.start, picked.end);
    }
    setState(() {
      _period = p;
      _draft = _draft.copyWith(range: range, clearRange: range == null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final accounts = ref.watch(allAccountsProvider).value ?? const [];
    final expenseCats =
        ref.watch(categoriesByKindProvider(CategoryKind.expense)).value ??
        const [];
    final incomeCats =
        ref.watch(categoriesByKindProvider(CategoryKind.income)).value ??
        const [];
    final categories = [
      if (_draft.types.isEmpty || _draft.types.contains(TxType.expense))
        ...expenseCats,
      if (_draft.types.isEmpty || _draft.types.contains(TxType.income))
        ...incomeCats,
    ];

    Widget chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? c.onPrimary : c.textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );

    Widget section(String title, List<Widget> chips) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Insets.md, bottom: 6),
          child: Text(
            title,
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
        ),
        Wrap(spacing: 6, runSpacing: 6, children: chips),
      ],
    );

    Set<T> toggle<T>(Set<T> set, T v) =>
        set.contains(v) ? ({...set}..remove(v)) : {...set, v};

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, controller) => SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
                children: [
                  Text(
                    l10n.filterTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  section(l10n.period, [
                    for (final p in _Period.values)
                      chip(
                        switch (p) {
                          _Period.today => l10n.periodToday,
                          _Period.week => l10n.periodWeek,
                          _Period.month => l10n.periodMonth,
                          _Period.last30 => l10n.periodLast30,
                          _Period.last3Months => l10n.periodLast3Months,
                          _Period.year => l10n.periodYear,
                          _Period.all => l10n.periodAll,
                          _Period.custom => l10n.periodCustom,
                        },
                        _period == p,
                        () => _setPeriod(p),
                      ),
                  ]),
                  section(l10n.account, [
                    chip(
                      l10n.all,
                      _draft.accountIds.isEmpty,
                      () => setState(
                        () => _draft = _draft.copyWith(accountIds: {}),
                      ),
                    ),
                    for (final a in accounts)
                      chip(
                        a.isArchived
                            ? '${a.name} (${l10n.archivedBadge})'
                            : a.name,
                        _draft.accountIds.contains(a.id),
                        () => setState(
                          () => _draft = _draft.copyWith(
                            accountIds: toggle(_draft.accountIds, a.id),
                          ),
                        ),
                      ),
                  ]),
                  section(l10n.typeAndCategory, [
                    for (final t in [
                      TxType.expense,
                      TxType.income,
                      TxType.transfer,
                      TxType.adjustment,
                    ])
                      chip(
                        l10n.txTypeName(t),
                        _draft.types.contains(t),
                        () => setState(
                          () => _draft = _draft.copyWith(
                            types: toggle(_draft.types, t),
                            categoryIds: {},
                          ),
                        ),
                      ),
                  ]),
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final cat in categories)
                          chip(
                            cat.name,
                            _draft.categoryIds.contains(cat.id),
                            () => setState(
                              () => _draft = _draft.copyWith(
                                categoryIds: toggle(_draft.categoryIds, cat.id),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: Insets.md),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: SwitchListTile(
                      title: Text(l10n.showDebtMovements),
                      subtitle: Text(
                        l10n.showDebtMovementsHint,
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _draft.showDebtMovements,
                      onChanged: (v) => setState(
                        () => _draft = _draft.copyWith(showDebtMovements: v),
                      ),
                    ),
                  ),
                  section(l10n.sort, [
                    for (final s in TransactionSort.values)
                      chip(
                        switch (s) {
                          TransactionSort.newest => l10n.sortNewest,
                          TransactionSort.oldest => l10n.sortOldest,
                          TransactionSort.amountDesc => l10n.sortAmountDesc,
                          TransactionSort.amountAsc => l10n.sortAmountAsc,
                        },
                        _draft.sort == s,
                        () => setState(() => _draft = _draft.copyWith(sort: s)),
                      ),
                  ]),
                  const SizedBox(height: Insets.lg),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Insets.screen),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        ref
                            .read(transactionFilterProvider.notifier)
                            .set(_draft);
                        Navigator.pop(context);
                      },
                      child: Text(l10n.apply),
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(transactionFilterProvider.notifier).reset();
                        Navigator.pop(context);
                      },
                      child: Text(l10n.reset),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
