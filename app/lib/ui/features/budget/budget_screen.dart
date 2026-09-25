// =============================================================================
// الشاشة 16: الميزانية (FR-21).
// إجمالي مصروف الشهر مقابل السقف، ثم شريط لكل فئة بألوان دلالية
// (أخضر أقل من 75%، كهرماني 75–99%، أحمر عند التجاوز) ورسالة بمقدار التجاوز.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/budget_report_models.dart';
import '../../../services/providers.dart';
import '../../state/app_state.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

Color levelColor(BudgetLevel level, AppColors c) => switch (level) {
  BudgetLevel.safe => c.income,
  BudgetLevel.warning => c.warning,
  BudgetLevel.exceeded => c.expense,
};

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final overview = ref.watch(budgetOverviewProvider);
    final dates = ref.watch(dateLabelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgetTitle),
        actions: [
          IconButton.filled(
            tooltip: l10n.addBudget,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showBudgetForm(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AsyncBody(
        value: overview,
        builder: (o) {
          if (o.isEmpty) {
            return EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              message: l10n.noBudgets,
              action: FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addBudget),
                onPressed: () => showBudgetForm(context),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(Insets.screen),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.spentOfBudget(dates.month(DateTime.now())),
                      style: TextStyle(color: c.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    // FittedBox: يصغّر الأرقام الكبيرة جداً بدل أن تتجاوز العرض.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AmountText(
                            o.totalSpent,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('/ ', style: TextStyle(color: c.textSecondary)),
                          AmountText(
                            o.totalLimit,
                            color: c.textSecondary,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppProgressBar(
                      value: o.totalLimit == 0
                          ? 0
                          : o.totalSpent / o.totalLimit,
                      color: levelColor(o.level, c),
                      height: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Insets.md),
              for (final b in o.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BudgetTile(progress: b),
                ),
              const SizedBox(height: Insets.sm),
              // مفتاح الألوان
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                children: [
                  for (final (label, color) in [
                    (l10n.legendSafe, c.income),
                    (l10n.legendWarning, c.warning),
                    (l10n.legendExceeded, c.expense),
                  ])
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: color),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BudgetTile extends ConsumerWidget {
  const _BudgetTile({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final money = ref.watch(moneyFormatterProvider);
    final color = levelColor(progress.level, c);
    final cat = progress.category;

    return AppCard(
      onTap: () => showBudgetForm(context, existing: progress),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                AppIcons.category(cat.icon),
                color: Color(cat.color),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cat.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                l10n.budgetOf(
                  money.format(progress.spent, compact: true),
                  money.format(progress.limit, compact: true),
                ),
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(value: progress.spent / progress.limit, color: color),
          if (progress.level == BudgetLevel.exceeded) ...[
            const SizedBox(height: 6),
            Text(
              l10n.budgetOverBy(money.inline(-progress.remaining)),
              style: TextStyle(fontSize: 12, color: c.expense),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// إضافة / تعديل ميزانية فئة
// -----------------------------------------------------------------------------

Future<void> showBudgetForm(BuildContext context, {BudgetProgress? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BudgetForm(existing: existing),
    );

class _BudgetForm extends ConsumerStatefulWidget {
  const _BudgetForm({this.existing});

  final BudgetProgress? existing;

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  late int? _categoryId = widget.existing?.category.id;
  late final _limit = TextEditingController(
    text: widget.existing == null
        ? ''
        : ref.read(moneyParserProvider).toEditable(widget.existing!.limit),
  );
  late double _alert = (widget.existing?.budget.alertPercent ?? 75).toDouble();

  @override
  void dispose() {
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final limit = ref.read(moneyParserProvider).parse(_limit.text);
    if (_categoryId == null) {
      showMessage(context, context.l10n.chooseCategory, error: true);
      return;
    }
    try {
      await ref
          .read(budgetServiceProvider)
          .upsert(
            categoryId: _categoryId!,
            limit: limit ?? 0,
            alertPercent: _alert.round(),
          );
      if (mounted) Navigator.pop(context);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final categories =
        ref.watch(categoriesByKindProvider(CategoryKind.expense)).value ??
        const <Category>[];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Insets.screen,
        0,
        Insets.screen,
        MediaQuery.viewInsetsOf(context).bottom + Insets.screen,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? l10n.addBudget : l10n.editBudget,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final cat in categories)
                ChoiceChip(
                  avatar: Icon(
                    AppIcons.category(cat.icon),
                    size: 18,
                    color: Color(cat.color),
                  ),
                  label: Text(cat.name),
                  selected: _categoryId == cat.id,
                  labelStyle: TextStyle(
                    color: _categoryId == cat.id ? Colors.white : c.textPrimary,
                  ),
                  onSelected: widget.existing == null
                      ? (_) => setState(() => _categoryId = cat.id)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _limit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.budgetLimit,
              suffixText: ref.watch(moneyFormatterProvider).symbol,
            ),
          ),
          const SizedBox(height: Insets.md),
          Text(l10n.alertAtPercent('${_alert.round()}')),
          Slider(
            value: _alert,
            min: 50,
            max: 95,
            divisions: 9,
            label: '${_alert.round()}%',
            onChanged: (v) => setState(() => _alert = v),
          ),
          const SizedBox(height: Insets.sm),
          FilledButton(onPressed: _save, child: Text(l10n.save)),
          if (widget.existing != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: Icon(Icons.delete_outline_rounded, color: c.expense),
              label: Text(
                l10n.deleteBudget,
                style: TextStyle(color: c.expense),
              ),
              onPressed: () async {
                await ref
                    .read(budgetServiceProvider)
                    .delete(widget.existing!.budget.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}
