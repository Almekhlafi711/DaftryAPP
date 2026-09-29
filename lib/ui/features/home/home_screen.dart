// =============================================================================
// الشاشة 3: الرئيسية (لوحة التحكم) — FR-22.
//
// 1) إجمالي أرصدة الحسابات النشطة بعملة واحدة + دخل ومصروف الشهر.
// 2) عمليات سريعة تبقى ثابتة عند التمرير.
// 3) بطاقة الميزانية: تظهر فقط عند وجود ميزانية.
// 4) بطاقة الديون: تظهر فقط عند وجود ديون.
// 5) آخر المعاملات.
// المستخدم الجديد يرى شاشة نظيفة؛ البطاقات تظهر عند الحاجة فقط.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/enums.dart';
import '../../../domain/models/debt_models.dart';
import '../../../services/providers.dart';
import '../../../services/settings_service.dart';
import '../../router/routes.dart';
import '../../state/app_state.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';
import '../transactions/transaction_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final recent = ref.watch(recentTransactionsProvider);
    final budget = ref.watch(budgetOverviewProvider).value;
    final debts = ref.watch(debtTotalsProvider).value;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? l10n.greetingMorning : l10n.greetingEvening;
    final userName = ref.watch(preferencesProvider).value?.userName;

    // الترويسة بلون الهوية في الوضعين: أيقونات شريط الحالة فاتحة فوقها.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle(c).copyWith(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: c.background,
        body: CustomScrollView(
          slivers: [
            // الترويسة الملونة + بطاقة الرصيد
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(height: 190, color: c.brand),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Insets.screen,
                        Insets.sm,
                        Insets.screen,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName == null
                                          ? greeting
                                          : l10n.greetingName(
                                              greeting,
                                              userName,
                                            ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Text(
                                      l10n.appName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white12,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                ),
                                onPressed: () => _showUpcoming(context, ref),
                              ),
                            ],
                          ),
                          const SizedBox(height: Insets.lg),
                          const _BalanceCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // العمليات السريعة — ثابتة عند التمرير
            SliverPersistentHeader(
              pinned: true,
              delegate: _QuickActionsHeader(
                extent: 96 + 24 * MediaQuery.textScalerOf(context).scale(1),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
              sliver: SliverList.list(
                children: [
                  if (budget != null && !budget.isEmpty) ...[
                    const SizedBox(height: Insets.md),
                    _BudgetCard(
                      spent: budget.totalSpent,
                      limit: budget.totalLimit,
                      remaining: budget.remaining,
                      daysLeft: budget.range.daysLeft(DateTime.now()),
                      level: budget.level,
                    ),
                  ],
                  if (debts != null && !debts.isEmpty) ...[
                    const SizedBox(height: Insets.md),
                    _DebtsCard(totals: debts),
                  ],
                  SectionTitle(
                    l10n.recentTransactions,
                    action: l10n.seeAll,
                    onAction: () => context.go(AppRoutes.transactions),
                  ),
                  AsyncBody(
                    value: recent,
                    builder: (items) => items.isEmpty
                        ? EmptyState(
                            icon: Icons.receipt_long_outlined,
                            message: l10n.noTransactionsYet,
                          )
                        : AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                for (final item in items)
                                  TransactionTile(
                                    item: item,
                                    onTap: () =>
                                        item.isDebtLinked &&
                                            item.contactId != null
                                        ? context.push(
                                            AppRoutes.person(item.contactId!),
                                          )
                                        : context.push(
                                            AppRoutes.editTransaction(item.id),
                                          ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: Insets.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// نافذة الاستحقاقات القريبة (زر الجرس).
  Future<void> _showUpcoming(BuildContext context, WidgetRef ref) async {
    final upcoming = await ref.read(debtServiceProvider).upcomingDue(days: 7);
    if (!context.mounted) return;
    final l10n = context.l10n;
    final c = context.colors;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: upcoming.isEmpty
            ? EmptyState(
                icon: Icons.notifications_none_rounded,
                message: l10n.noResults,
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final u in upcoming)
                    ListTile(
                      leading: IconBadge(
                        icon: Icons.event_rounded,
                        color: _dueColor(u, c),
                        size: 40,
                      ),
                      title: Text(u.contactName),
                      subtitle: Text(dueLabel(l10n, u.debt.dueDate!).$1),
                      trailing: AmountText(
                        u.remaining,
                        color: u.debt.direction == DebtDirection.owedToMe
                            ? c.income
                            : c.expense,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(AppRoutes.person(u.debt.contactId));
                      },
                    ),
                ],
              ),
      ),
    );
  }
}

Color _dueColor(UpcomingDebt u, AppColors c) =>
    u.debt.dueDate!.isBefore(DateTime.now()) ? c.expense : c.warning;

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final total = ref.watch(totalBalanceProvider).value ?? 0;
    final month = ref.watch(monthTotalsProvider).value;
    final hidden = ref.watch(hideBalancesProvider);

    return Material(
      color: c.surface,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(Radii.card + 4),
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.totalBalance,
                    style: TextStyle(color: c.textSecondary),
                  ),
                ),
                IconButton(
                  tooltip: l10n.hideBalances,
                  icon: Icon(
                    hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: c.textSecondary,
                  ),
                  onPressed: () => ref
                      .read(settingsServiceProvider)
                      .setFlag(SettingKeys.hideBalances, !hidden),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AmountText(
                total,
                respectHide: true,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: l10n.monthIncome,
                    value: month?.income ?? 0,
                    color: c.income,
                    sign: 1,
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: _MiniStat(
                    label: l10n.monthExpense,
                    value: month?.expense ?? 0,
                    color: c.expense,
                    sign: -1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.sign,
  });

  final String label;
  final int value;
  final Color color;
  final int sign;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(Radii.chip),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color)),
        AmountText(
          value * sign,
          showSign: sign > 0,
          withSymbol: false,
          compact: true,
          respectHide: true,
          color: color,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    ),
  );
}

/// شريط العمليات السريعة الثابت عند التمرير.
/// ارتفاعه يُحسب من حجم الخط حتى لا يُقص عند تكبير الخط (الإتاحة).
class _QuickActionsHeader extends SliverPersistentHeaderDelegate {
  _QuickActionsHeader({required this.extent});

  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: Container(
        color: context.colors.background,
        padding: const EdgeInsets.fromLTRB(
          Insets.screen,
          Insets.md,
          Insets.screen,
          0,
        ),
        alignment: Alignment.topCenter,
        child: const _QuickActions(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _QuickActionsHeader oldDelegate) =>
      oldDelegate.extent != extent;
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    // FR-05: التحويل لا يظهر ما دام للمستخدم حساب نشط واحد.
    final multiAccount =
        (ref.watch(activeAccountsProvider).value?.length ?? 1) > 1;
    final actions = [
      (
        Icons.arrow_upward_rounded,
        l10n.quickExpense,
        c.expense,
        () => context.push(AppRoutes.newTransaction()),
      ),
      (
        Icons.arrow_downward_rounded,
        l10n.quickIncome,
        c.income,
        () => context.push(AppRoutes.newTransaction(TxType.income)),
      ),
      if (multiAccount)
        (
          Icons.swap_horiz_rounded,
          l10n.quickTransfer,
          c.transfer,
          () => context.push(AppRoutes.newTransaction(TxType.transfer)),
        ),
      (
        Icons.people_outline_rounded,
        l10n.quickDebt,
        c.warning,
        () => context.push(AppRoutes.newDebt()),
      ),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          for (final (icon, label, color, onTap) in actions)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconBadge(icon: icon, color: color, size: 48),
                    const SizedBox(height: 4),
                    // سطر واحد يتقلص عند ضيق المساحة أو تكبير الخط.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.spent,
    required this.limit,
    required this.remaining,
    required this.daysLeft,
    required this.level,
  });

  final int spent;
  final int limit;
  final int remaining;
  final int daysLeft;
  final BudgetLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final color = switch (level) {
      BudgetLevel.safe => c.income,
      BudgetLevel.warning => c.warning,
      BudgetLevel.exceeded => c.expense,
    };
    return Consumer(
      builder: (context, ref, _) {
        final money = ref.watch(moneyFormatterProvider);
        return AppCard(
          onTap: () => context.push(AppRoutes.budget),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.monthlyBudget,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    l10n.budgetOf(
                      money.format(spent, compact: true),
                      money.format(limit, compact: true),
                    ),
                    style: TextStyle(color: c.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppProgressBar(
                value: limit == 0 ? 0 : spent / limit,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                remaining >= 0
                    ? l10n.remainingForDays(
                        money.inline(remaining, withSymbol: true),
                        daysLeft,
                      )
                    : l10n.budgetOverBy(money.inline(-remaining)),
                style: TextStyle(
                  fontSize: 12.5,
                  color: remaining >= 0 ? c.textSecondary : c.expense,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DebtsCard extends StatelessWidget {
  const _DebtsCard({required this.totals});

  final DebtTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    Widget side(String label, int value, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: c.textSecondary)),
          AmountText(
            value,
            color: color,
            respectHide: true,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
    );
    return AppCard(
      onTap: () => context.go(AppRoutes.debts),
      child: Row(
        children: [
          side(l10n.owedToMe, totals.owedToMe, c.income),
          Container(width: 1, height: 36, color: c.border),
          const SizedBox(width: 12),
          side(l10n.iOwe, totals.iOwe, c.expense),
          Icon(Icons.chevron_right_rounded, color: c.textSecondary),
        ],
      ),
    );
  }
}
