// =============================================================================
// مكوّنات الإدخال: لوحة الأرقام، عرض المبلغ الكبير، اختيار الحساب، اختيار التاريخ.
// صُممت لتحقيق هدف «إضافة معاملة في 10 ثوانٍ أو أقل».
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/money.dart';
import '../../data/database/app_database.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'labels.dart';

/// حالة نص المبلغ الذي يكتبه المستخدم على لوحة الأرقام.
class AmountInput {
  const AmountInput(this.text);

  final String text;

  static const empty = AmountInput('');

  /// يضيف رقماً أو فاصلة مع احترام عدد الخانات العشرية للعملة.
  AmountInput press(String key, int decimals) {
    if (key == '⌫') {
      return AmountInput(
        text.isEmpty ? '' : text.substring(0, text.length - 1),
      );
    }
    if (key == '.') {
      if (decimals == 0 || text.contains('.')) return this;
      return AmountInput(text.isEmpty ? '0.' : '$text.');
    }
    if (text.contains('.') && text.split('.')[1].length >= decimals) {
      return this;
    }
    if (text == '0') return AmountInput(key);
    if (text.replaceAll('.', '').length >= 12) return this; // حد معقول
    return AmountInput('$text$key');
  }

  int? toMinor(MoneyParser parser) => parser.parse(text);
}

/// لوحة أرقام كبيرة مريحة للإبهام.
class NumPad extends StatelessWidget {
  const NumPad({super.key, required this.onKey, this.allowDecimal = true});

  final ValueChanged<String> onKey;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];
    final c = context.colors;
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Material(
                        color: c.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.chip),
                          side: BorderSide(color: c.border),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(Radii.chip),
                          onTap: key == '.' && !allowDecimal
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  onKey(key);
                                },
                          child: SizedBox(
                            height: 52,
                            child: Center(
                              child: key == '⌫'
                                  ? Icon(
                                      Icons.backspace_outlined,
                                      color: c.textPrimary,
                                    )
                                  : Text(
                                      key,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: key == '.' && !allowDecimal
                                            ? c.border
                                            : c.textPrimary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// عرض المبلغ الكبير مع رمز العملة الثابت (لا حقل لاختيار العملة).
class BigAmountDisplay extends ConsumerWidget {
  const BigAmountDisplay({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyFormatterProvider);
    final c = context.colors;
    final shown = text.isEmpty ? '0' : text;
    // الرمز يتبع اتجاه الواجهة: يسار الرقم في العربية ويمينه في الإنجليزية.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            money.useArabicDigits
                ? MoneyFormatter.toArabicDigits(shown)
                : shown,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: text.isEmpty ? c.textSecondary : (color ?? c.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            money.symbol,
            style: TextStyle(fontSize: 18, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// زر اختيار (حساب / تاريخ) بأيقونة وعنوان فرعي، بتصميم الوثيقة.
class PickerTile extends StatelessWidget {
  const PickerTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: c.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                  ),
              ],
            ),
          ),
          ?trailing,
          if (onTap != null && trailing == null)
            Icon(Icons.expand_more_rounded, color: c.textSecondary, size: 20),
        ],
      ),
    );
  }
}

/// نافذة سفلية لاختيار حساب من الحسابات النشطة فقط (المؤرشف لا يظهر).
Future<Account?> pickAccount(
  BuildContext context, {
  int? selectedId,
  Set<int> exclude = const {},
}) {
  return showModalBottomSheet<Account>(
    context: context,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final accounts = ref.watch(activeAccountsProvider).value ?? const [];
        final c = ctx.colors;
        final l10n = ctx.l10n;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(l10n.account, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final a in accounts.where((a) => !exclude.contains(a.id)))
                ListTile(
                  leading: IconBadge(
                    icon: AppIcons.account(a.type),
                    color: a.color != null ? Color(a.color!) : c.primary,
                    size: 40,
                  ),
                  title: Text(a.name),
                  subtitle: Text(l10n.accountTypeName(a.type)),
                  trailing: a.id == selectedId
                      ? Icon(Icons.check_circle, color: c.primary)
                      : AmountText(
                          a.balance,
                          style: const TextStyle(fontSize: 13),
                        ),
                  onTap: () => Navigator.pop(ctx, a),
                ),
            ],
          ),
        );
      },
    ),
  );
}

/// اختيار تاريخ بمنتقي النظام.
Future<DateTime?> pickDate(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(2000),
    lastDate: last ?? DateTime(2100),
  );
  if (picked == null) return null;
  // نحافظ على الوقت الحالي حتى يبقى ترتيب المعاملات في نفس اليوم منطقياً.
  final now = DateTime.now();
  return DateTime(
    picked.year,
    picked.month,
    picked.day,
    now.hour,
    now.minute,
    now.second,
  );
}
