// =============================================================================
// الشاشة 5: سجل المعاملات (FR-12).
// - بحث فوري + زر فلترة واحد يحمل عدد الفلاتر المفعّلة.
// - ملخص الدخل والمصروف (حركات الديون لا تدخل فيه).
// - تجميع حسب اليوم، والتعديل/الحذف بسحب العنصر (UC-03) مع «تراجع» 5 ثوانٍ.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/transaction_models.dart';
import '../../../services/providers.dart';
import '../../router/routes.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/labels.dart';
import 'filter_sheet.dart';
import 'transaction_tile.dart';
import 'transactions_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // تحميل المزيد عند الاقتراب من نهاية القائمة.
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) {
        final loaded =
            ref.read(filteredTransactionsProvider).value?.length ?? 0;
        if (loaded >= ref.read(transactionPageSizeProvider)) {
          ref.read(transactionPageSizeProvider.notifier).more();
        }
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final filter = ref.watch(transactionFilterProvider);
    final items = ref.watch(filteredTransactionsProvider);
    final totals = ref.watch(filteredTotalsProvider).value;
    final dates = DateLabels(ref.watch(localeProvider).languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchTransactions,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                    onChanged: ref
                        .read(transactionFilterProvider.notifier)
                        .search,
                  ),
                ),
                const SizedBox(width: Insets.sm),
                // زر الفلترة الواحد مع عدد الفلاتر المفعّلة
                Badge(
                  isLabelVisible: filter.activeCount > 0,
                  label: Text('${filter.activeCount}'),
                  backgroundColor: c.warning,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: c.primary,
                      minimumSize: const Size(50, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.button),
                      ),
                    ),
                    icon: const Icon(
                      Icons.filter_alt_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () => showFilterSheet(context),
                  ),
                ),
              ],
            ),
          ),
          if (totals != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.screen,
                Insets.md,
                Insets.screen,
                0,
              ),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _Summary(
                        label: l10n.income,
                        value: totals.income,
                        color: c.income,
                      ),
                    ),
                    Expanded(
                      child: _Summary(
                        label: l10n.expense,
                        value: -totals.expense,
                        color: c.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: AsyncBody(
              value: items,
              builder: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    message: filter.query.isEmpty && filter.activeCount <= 1
                        ? l10n.noTransactionsYet
                        : l10n.noResults,
                  );
                }
                final rows = _groupByDay(list);
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(
                    Insets.screen,
                    8,
                    Insets.screen,
                    96,
                  ),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    if (row is DateTime) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                        child: Text(
                          dates.relativeDay(row, l10n),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: c.textSecondary,
                          ),
                        ),
                      );
                    }
                    return _SwipeableTransaction(item: row as TransactionView);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// قائمة مسطحة: تاريخ اليوم ثم معاملاته (أسرع من قوائم متداخلة).
  List<Object> _groupByDay(List<TransactionView> list) {
    final rows = <Object>[];
    DateTime? current;
    for (final item in list) {
      final d = item.tx.date;
      final day = DateTime(d.year, d.month, d.day);
      if (current != day) {
        rows.add(day);
        current = day;
      }
      rows.add(item);
    }
    return rows;
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label  ', style: TextStyle(color: context.colors.textSecondary)),
      Flexible(
        child: AmountText(
          value,
          showSign: value > 0,
          withSymbol: false,
          color: color,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

/// عنصر يدعم السحب: للبداية = تعديل، للنهاية = حذف (بعد تأكيد) ثم «تراجع».
class _SwipeableTransaction extends ConsumerWidget {
  const _SwipeableTransaction({required this.item});

  final TransactionView item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;
    final tile = TransactionTile(
      item: item,
      onTap: () => item.isDebtMovement
          ? context.push(AppRoutes.person(item.contactId!))
          : context.push(AppRoutes.editTransaction(item.id)),
    );
    // حركات الديون تُعدَّل من ملف الشخص فقط.
    if (item.isDebtMovement) return tile;

    Widget background(
      Color color,
      IconData icon,
      String label,
      Alignment align,
    ) => Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey(item.id),
      background: background(
        c.transfer,
        Icons.edit_outlined,
        l10n.edit,
        AlignmentDirectional.centerStart.resolve(Directionality.of(context)),
      ),
      secondaryBackground: background(
        c.expense,
        Icons.delete_outline_rounded,
        l10n.delete,
        AlignmentDirectional.centerEnd.resolve(Directionality.of(context)),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await context.push(AppRoutes.editTransaction(item.id));
          return false;
        }
        await deleteTransactionWithUndo(context, ref, item);
        return false; // القائمة تتحدث تلقائياً من قاعدة البيانات.
      },
      child: tile,
    );
  }
}

/// حذف مع تأكيد يوضح الأثر على الرصيد، ثم شريط «تراجع» لمدة 5 ثوانٍ.
Future<bool> deleteTransactionWithUndo(
  BuildContext context,
  WidgetRef ref,
  TransactionView item,
) async {
  final l10n = context.l10n;
  final money = ref.read(moneyFormatterProvider);
  final ok = await confirmAction(
    context,
    title: l10n.deleteTransactionTitle,
    message: l10n.deleteTransactionBody(
      item.tx.note ?? item.category?.name ?? l10n.txTypeName(item.type),
      money.inline(item.tx.amount),
      item.accountName,
    ),
    confirmLabel: l10n.delete,
  );
  if (!ok || !context.mounted) return false;
  final service = ref.read(transactionServiceProvider);
  try {
    final deleted = await service.delete(item.id);
    if (!context.mounted) return true;
    showMessage(
      context,
      l10n.transactionDeleted,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: () => service.restore(deleted),
      ),
    );
    return true;
  } on Object catch (e) {
    if (context.mounted) showError(context, e);
    return false;
  }
}
