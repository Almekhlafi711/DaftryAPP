// =============================================================================
// الشاشتان 1 و 2: الإعداد الأول واختيار العملة ثم تأكيدها قبل القفل (UC-00).
//
// - بدون تسجيل دخول أو إنشاء حساب.
// - اختيار العملة إلزامي؛ زر «متابعة» معطّل حتى تُختار عملة.
// - نافذة تأكيد أخيرة توضح أن العملة لا يمكن تغييرها لاحقاً.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/currencies.dart';
import '../../../services/providers.dart';
import '../../../services/settings_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../backup/restore_flow.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  CurrencyInfo? _selected;
  String _query = '';
  bool _saving = false;

  List<CurrencyInfo> _filtered(bool arabic) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kSupportedCurrencies;
    return kSupportedCurrencies
        .where(
          (c) =>
              c.code.toLowerCase().contains(q) ||
              c.nameAr.contains(q) ||
              c.nameEn.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _confirm() async {
    final currency = _selected;
    if (currency == null) return;
    final arabic = ref.read(isArabicProvider);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => _ConfirmCurrencySheet(currency: currency, arabic: arabic),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(settingsServiceProvider)
          .completeOnboarding(currency, arabic: arabic);
      // المُوجّه ينقل المستخدم للرئيسية تلقائياً بعد تغيّر حالة الإعداد.
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final arabic = ref.watch(isArabicProvider);
    final currencies = _filtered(arabic);

    return Scaffold(
      appBar: AppBar(
        actions: [
          // تبديل اللغة من أول شاشة.
          TextButton.icon(
            icon: const Icon(Icons.language_rounded, size: 20),
            label: Text(arabic ? 'English' : 'العربية'),
            onPressed: () => ref
                .read(settingsServiceProvider)
                .set(SettingKeys.locale, arabic ? 'en' : 'ar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: c.brand,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  Text(
                    l10n.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textSecondary),
                  ),
                  const SizedBox(height: Insets.xl),
                  Text.rich(
                    TextSpan(
                      text: l10n.chooseCurrency,
                      children: [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: c.expense),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: Insets.sm),
                  // تنبيه واضح: العملة لا تتغير لاحقاً.
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: c.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.currencyWarning,
                            style: TextStyle(fontSize: 12.5, color: c.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchCurrency,
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: Insets.sm),
                  for (final currency in currencies)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _CurrencyTile(
                        currency: currency,
                        arabic: arabic,
                        selected: _selected?.code == currency.code,
                        onTap: () => setState(() => _selected = currency),
                      ),
                    ),
                  const SizedBox(height: Insets.md),
                  // النسخ السحابي خيار لا شرط — يظهر مُطفأً.
                  AppCard(
                    child: Row(
                      children: [
                        Icon(Icons.cloud_outlined, color: c.transfer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.cloudBackup,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                l10n.cloudBackupOptionalHint,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Switch(value: false, onChanged: null),
                      ],
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.settings_backup_restore_rounded),
                      label: Text(l10n.restoreExisting),
                      onPressed: () => showRestoreOptions(context, ref),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Insets.screen),
              child: FilledButton(
                onPressed: _selected == null || _saving ? null : _confirm,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.continueLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.currency,
    required this.arabic,
    required this.selected,
    required this.onTap,
  });

  final CurrencyInfo currency;
  final bool arabic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      color: selected ? c.primary.withValues(alpha: 0.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              currency.symbol(arabic),
              style: TextStyle(fontWeight: FontWeight.w700, color: c.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency.name(arabic),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  currency.code,
                  style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                ),
              ],
            ),
          ),
          if (selected) Icon(Icons.check_circle_rounded, color: c.primary),
        ],
      ),
    );
  }
}

/// الشاشة 2: نافذة التأكيد الأخيرة قبل قفل العملة.
class _ConfirmCurrencySheet extends StatelessWidget {
  const _ConfirmCurrencySheet({required this.currency, required this.arabic});

  final CurrencyInfo currency;
  final bool arabic;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBadge(
              icon: Icons.lock_outline_rounded,
              color: c.warning,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.confirmCurrencyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Pill(
              '${currency.code} — ${currency.name(arabic)}  ${currency.symbol(arabic)}',
              color: c.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.confirmCurrencyBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.confirmCurrencyWarning,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.expense, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.confirmAndStart),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.backAndChange),
            ),
          ],
        ),
      ),
    );
  }
}
