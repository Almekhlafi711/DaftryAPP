// =============================================================================
// مكوّنات الواجهة المشتركة (جدول 4-2): بطاقة، مربع أيقونة ملوّن، مبلغ،
// شريط تقدم، عنوان قسم، حالة فارغة، شارة.
// استخدمها في كل الشاشات بدل تكرار التنسيق — فيبقى التصميم موحداً.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// اختصار للوصول للنصوص المترجمة: context.l10n.save
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// بطاقة بزوايا 18 وحدود خفيفة.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.lg),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: color ?? c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// أيقونة خطية داخل مربع ملوّن فاتح (تدل على الفئة أو النوع).
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Icon(icon, color: color, size: size * 0.5),
  );
}

/// مبلغ منسّق بعملة التطبيق — يُعرض دائماً من اليسار لليمين حتى لا تنقلب
/// إشارة السالب داخل الواجهة العربية.
class AmountText extends ConsumerWidget {
  const AmountText(
    this.minor, {
    super.key,
    this.style,
    this.color,
    this.showSign = false,
    this.withSymbol = true,
    this.compact = false,
    this.respectHide = false,
  });

  final int minor;
  final TextStyle? style;
  final Color? color;
  final bool showSign;
  final bool withSymbol;
  final bool compact;

  /// إخفاء المبلغ إذا فعّل المستخدم «إخفاء الأرصدة».
  final bool respectHide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyFormatterProvider);
    final hidden = respectHide && ref.watch(hideBalancesProvider);
    final text = hidden
        ? '••••'
        : money.format(minor, showSign: showSign, compact: compact);
    final base = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            if (withSymbol && !hidden)
              TextSpan(
                text: ' ${money.symbol}',
                style: base.copyWith(
                  fontSize: (base.fontSize ?? 14) * 0.55,
                  fontWeight: FontWeight.w600,
                  color: color ?? context.colors.textSecondary,
                ),
              ),
          ],
        ),
        style: base,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// شريط تقدم بزوايا دائرية.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 8,
  });

  /// من 0 إلى 1 (القيم الأكبر تُقص).
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: LinearProgressIndicator(
      value: value.clamp(0, 1),
      minHeight: height,
      color: color,
      backgroundColor: context.colors.surfaceMuted,
    ),
  );
}

/// عنوان قسم مع زر اختياري (مثل «آخر المعاملات — عرض الكل»).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, Insets.lg, 4, Insets.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

/// حالة فارغة ودّية بدل شاشة بيضاء.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Insets.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(icon: icon, color: context.colors.primary, size: 64),
          const SizedBox(height: Insets.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: Insets.lg), action!],
        ],
      ),
    ),
  );
}

/// شارة صغيرة ملونة (مثل «افتراضي»، «مؤرشف»، «حركة دين»).
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

/// مفتاح مقسّم (Segmented) بتصميم الوثيقة: خلفية رمادية والمختار أبيض.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.colorOf,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  /// لون نص الخيار المختار (أحمر للمصروف، أخضر للدخل...).
  final Color Function(T)? colorOf;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(Radii.button),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == selected ? c.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(Radii.chip),
                    boxShadow: v == selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label(v),
                    style: TextStyle(
                      fontWeight: v == selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: v == selected
                          ? (colorOf?.call(v) ?? c.textPrimary)
                          : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// غلاف موحّد لعرض AsyncValue: تحميل / خطأ / بيانات.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.builder});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
    data: builder,
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Text(context.l10n.errUnexpected),
      ),
    ),
  );
}
