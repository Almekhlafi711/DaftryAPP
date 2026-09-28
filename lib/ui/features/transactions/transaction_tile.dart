// =============================================================================
// عنصر معاملة في القوائم (الرئيسية وسجل المعاملات).
// «حركات الديون» تظهر بشكل مميز: أيقونة الشخص وشارة «حركة دين» ولون محايد،
// لأنها تحرّك الرصيد لكنها ليست دخلاً ولا مصروفاً.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../domain/enums.dart';
import '../../../domain/models/transaction_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../widgets/common.dart';
import '../../widgets/labels.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item, this.onTap});

  final TransactionView item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final type = item.type;

    final (IconData icon, Color color) = switch (type) {
      TxType.income || TxType.expense when item.category != null => (
        AppIcons.category(item.category!.icon),
        Color(item.category!.color),
      ),
      _ => (type.icon, type.color(c)),
    };

    final title = switch (type) {
      TxType.transfer => l10n.typeTransfer,
      TxType.adjustment => l10n.typeAdjustment,
      TxType.debtIn || TxType.debtOut => item.contactName ?? l10n.debtMovement,
      _ =>
        item.tx.note?.isNotEmpty == true
            ? item.tx.note!
            : (item.category?.name ?? l10n.txTypeName(type)),
    };

    // سهم التحويل يتبع اتجاه اللغة: «النقدية ← الراجحي» / «Cash → Bank».
    final arrow = Directionality.of(context) == TextDirection.rtl ? '←' : '→';
    final subtitleParts = <String>[
      if ((type == TxType.income || type == TxType.expense) &&
          item.tx.note?.isNotEmpty == true &&
          item.category != null)
        item.category!.name,
      if (type == TxType.transfer)
        '${item.accountName} $arrow ${item.toAccountName ?? ''}'
      else
        item.accountName,
    ];

    // الإشارة واللون: الدخل أخضر +، المصروف أحمر −، الديون والتحويل محايدة.
    final amountColor = switch (type) {
      TxType.income => c.income,
      TxType.expense => c.expense,
      _ => c.textPrimary,
    };
    final signed = switch (type) {
      TxType.expense || TxType.debtOut => -item.tx.amount,
      TxType.transfer => item.tx.amount,
      _ => item.tx.amount,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            IconBadge(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subtitleParts.join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                      if (item.accountArchived) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Pill(l10n.archivedBadge, color: c.archive),
                        ),
                      ],
                      if (item.isDebtMovement) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Pill(l10n.debtMovement, color: c.warning),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AmountText(
              signed,
              showSign: type == TxType.income || type == TxType.debtIn,
              withSymbol: false,
              color: amountColor,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
