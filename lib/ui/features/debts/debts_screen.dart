// =============================================================================
// الشاشة 10: دفتر الديون — قائمة الأشخاص (الشكلان 4-17 و 4-18 في الوثيقة).
// - بطاقة الملخص: مجموع «لي عند الناس» و«عليّ للناس»، وتحتهما عدد الأشخاص
//   والمتأخرين.
// - بحث دائم بالاسم أو الهاتف وبجانبه زر فلترة واحد (الحالة والترتيب فقط).
// - تبويبات لي / عليّ / الكل، ثم الأشخاص في بطاقة واحدة: المتبقي ومن أصل كم،
//   شارة الاستحقاق («بدون موعد» إن لم يُحدَّد)، وشريط «نسبة السداد» المرجّحة.
// - زر الإجراءات السريعة: استلام مبلغ، سداد مبلغ، دين جديد، مع طبقة معتمة.
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
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.debtsTitle),
            Text(
              l10n.debtsSubtitle,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: const _SpeedDial(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.screen, 0, Insets.screen, 96),
        children: [
          _SummaryCard(totals: totals),
          const SizedBox(height: Insets.md),
          // بحث دائم + زر الفلترة بجانبه (يحمل عدد الفلاتر المفعّلة).
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchPeople,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: ref.read(_queryProvider.notifier).set,
                ),
              ),
              const SizedBox(width: Insets.sm),
              SizedBox.square(
                dimension: 52,
                child: IconButton.outlined(
                  tooltip: l10n.filterDebts,
                  style: IconButton.styleFrom(
                    backgroundColor: c.surface,
                    side: BorderSide(color: c.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.button),
                    ),
                  ),
                  icon: Badge(
                    isLabelVisible: filter.activeCount > 0,
                    label: Text('${filter.activeCount}'),
                    child: const Icon(Icons.filter_alt_outlined),
                  ),
                  onPressed: () => _showFilter(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          SegmentedTabs<DebtDirection?>(
            values: const [DebtDirection.owedToMe, DebtDirection.iOwe, null],
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
                : AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, p) in list.indexed) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: c.border,
                            ),
                          _PersonTile(summary: p),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilter(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    // بارتفاع المحتوى، ويُمرَّر إن لم يتسع (الخطوط الكبيرة أو الإنجليزية).
    isScrollControlled: true,
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
                color: selected ? ctx.colors.onPrimary : ctx.colors.textPrimary,
              ),
              onSelected: (_) => onTap(),
            );
        return SafeArea(
          child: SingleChildScrollView(
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

/// زر الإجراءات السريعة: يفتح طبقة معتمة فوق الشاشة فيها ثلاثة أزرار ملونة
/// (استلام مبلغ ↓ أخضر، سداد مبلغ ↑ أحمر، دين جديد + بلون الهوية) مع عناوينها،
/// وزر إغلاق X في مكان الزر نفسه. في الاستلام والسداد لا يُسأل عن نوع العملية:
/// الشخص ← المبلغ ← حفظ.
class _SpeedDial extends ConsumerWidget {
  const _SpeedDial();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    return FloatingActionButton(
      heroTag: 'debts-speed-dial',
      backgroundColor: c.brand,
      foregroundColor: Colors.white,
      tooltip: l10n.newDebt,
      onPressed: () => _open(context, ref),
      child: const Icon(Icons.add_rounded),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // المسافة من حافة الشاشة (البداية) ومن أسفلها حتى الزر.
    final start = rtl ? screen.width - origin.dx - box.size.width : origin.dx;
    final bottom = screen.height - origin.dy - box.size.height;
    final l10n = context.l10n;

    final choice = await showGeneralDialog<DebtDirection?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10n.closeLabel,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, _, _) =>
          _SpeedDialMenu(start: start, bottom: bottom, size: box.size.width),
      transitionBuilder: (ctx, animation, _, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case DebtDirection.owedToMe || DebtDirection.iOwe:
        await startSettle(context, ref, choice!);
      case null:
        break;
    }
  }
}

/// القائمة المفتوحة: تُعيد اتجاه الاستلام/السداد، أو تفتح «دين جديد» مباشرة.
class _SpeedDialMenu extends StatelessWidget {
  const _SpeedDialMenu({
    required this.start,
    required this.bottom,
    required this.size,
  });

  final double start;
  final double bottom;
  final double size;

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
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size - 6,
              height: size - 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(icon, color: c.onColor(color), size: 26),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      children: [
        PositionedDirectional(
          start: start,
          bottom: bottom,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                action(
                  label: l10n.receiveAmount,
                  icon: Icons.arrow_downward_rounded,
                  color: c.income,
                  onTap: () => Navigator.pop(context, DebtDirection.owedToMe),
                ),
                action(
                  label: l10n.payAmount,
                  icon: Icons.arrow_upward_rounded,
                  color: c.expense,
                  onTap: () => Navigator.pop(context, DebtDirection.iOwe),
                ),
                action(
                  label: l10n.newDebt,
                  icon: Icons.add_rounded,
                  color: c.brand,
                  onTap: () {
                    final router = GoRouter.of(context);
                    Navigator.pop(context);
                    router.push(AppRoutes.newDebt());
                  },
                ),
                // زر الإغلاق في مكان زر الإجراءات نفسه.
                SizedBox.square(
                  dimension: size,
                  child: FloatingActionButton(
                    heroTag: null,
                    elevation: 2,
                    backgroundColor: c.surface,
                    foregroundColor: c.textPrimary,
                    tooltip: l10n.closeLabel,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// بطاقة الملخص: مجموع لي وعليّ، وعدد الأشخاص والمتأخرين.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totals});

  final DebtTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    Widget total(String label, int value, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12.5)),
          const SizedBox(height: 2),
          AmountText(
            value,
            color: color,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
          ),
        ],
      ),
    );
    final overdue = totals.overdueDebts > 0;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                total(l10n.owedToMe, totals.owedToMe, c.income),
                VerticalDivider(width: 24, color: c.border),
                total(l10n.iOwe, totals.iOwe, c.expense),
              ],
            ),
          ),
          Divider(height: 22, color: c.border),
          // مؤشرات الملخص: عدد الأشخاص وعدد المتأخرات.
          Row(
            children: [
              Icon(Icons.people_alt_outlined, size: 17, color: c.textSecondary),
              const SizedBox(width: 6),
              Text(
                l10n.peopleCount(totals.people),
                style: TextStyle(fontSize: 12.5, color: c.textSecondary),
              ),
              Text(' • ', style: TextStyle(color: c.textSecondary)),
              Text(
                l10n.overdueCount(totals.overdueDebts),
                style: TextStyle(
                  fontSize: 12.5,
                  color: overdue ? c.expense : c.textSecondary,
                  fontWeight: overdue ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// صف شخص: الحرف الأول، الاسم وشارة الاستحقاق، المتبقي ومن أصل كم، ثم شريط
/// نسبة السداد المرجّحة.
class _PersonTile extends ConsumerWidget {
  const _PersonTile({required this.summary});

  final PersonSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final money = ref.watch(moneyFormatterProvider);
    final archived = summary.contact.isArchived;
    final closed = summary.isClosed;
    final due = summary.nearestDue;
    final dueInfo = due == null || closed ? null : dueLabel(l10n, due);

    // «لي» و«عليّ» يُعرضان منفصلين (لا مقاصة تلقائية).
    final amounts = [
      if (summary.receivable > 0 || (closed && summary.payable == 0))
        (summary.receivable, c.income),
      if (summary.payable > 0) (summary.payable, c.expense),
    ];

    return InkWell(
      onTap: () => context.push(AppRoutes.person(summary.contact.id)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: c.tint(c.primary),
                  child: Text(
                    summary.contact.name.characters.first,
                    style: TextStyle(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (archived)
                        Pill(l10n.archivedBadge, color: c.archive)
                      else if (closed)
                        Pill(l10n.statusClosed, color: c.income)
                      else if (dueInfo != null)
                        Pill(
                          dueInfo.$1,
                          color: dueInfo.$2 ? c.expense : c.warning,
                        )
                      else
                        Pill(l10n.noDueDate, color: c.textSecondary),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppProgressBar(
                    value: summary.progress / 100,
                    color: c.income,
                    height: 6,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.paymentRate('${summary.progress}'),
                  style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
