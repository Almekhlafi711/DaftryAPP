// =============================================================================
// الشاشتان 1 و 2: الإعداد الأول (UC-00) بثلاث مراحل:
//   1) ثلاث شاشات ترحيب: التعريف، المزايا، الخطوات المهمة (يمكن تخطيها).
//   2) الملف الشخصي: الاسم مطلوب (للتقارير والكشوف) ورقم الجوال اختياري.
//   3) اختيار العملة ثم تأكيدها قبل القفل.
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
import '../profile/profile_form.dart';
import 'intro_pages.dart';

enum _Step { intro, profile, currency }

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.intro;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _phoneError;
  CurrencyInfo? _selected;
  String _query = '';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _goTo(_Step step) => setState(() => _step = step);

  void _back() => _goTo(_Step.values[_step.index - 1]);

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

  /// من الملف الشخصي إلى العملة بعد التحقق من رقم الجوال.
  void _submitProfile() {
    if (_name.text.trim().isEmpty) return;
    final error = phoneErrorFor(context, _phone.text);
    if (error != null) {
      setState(() => _phoneError = error);
      return;
    }
    FocusScope.of(context).unfocus();
    _goTo(_Step.currency);
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
          .completeOnboarding(
            currency,
            arabic: arabic,
            userName: _name.text,
            userPhone: _phone.text,
          );
      // المُوجّه ينقل المستخدم للرئيسية تلقائياً بعد تغيّر حالة الإعداد.
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// الاستعادة من نسخة احتياطية بدل البدء من جديد. إن كانت النسخة من إصدار
  /// أقدم بلا اسم، نحفظ الاسم الذي أدخله المستخدم للتو.
  Future<void> _restore() async {
    final settings = ref.read(settingsServiceProvider);
    final name = _name.text;
    final phone = _phone.text;
    await showRestoreOptions(context, ref);
    // الشاشة قد تُغلق بعد الاستعادة (ينقل المُوجّه للرئيسية)، لذا لا نستخدم
    // ref أو context هنا.
    try {
      final prefs = await settings.getPreferences();
      if (prefs.onboarded && prefs.userName == null) {
        await settings.saveProfile(name: name, phone: phone);
      }
    } on Object {
      // الاسم يمكن إضافته لاحقاً من الإعدادات.
    }
  }

  @override
  Widget build(BuildContext context) {
    const language = _LanguageToggle();
    // زر الرجوع في النظام يعود خطوة بدل إغلاق التطبيق.
    return PopScope(
      canPop: _step == _Step.intro,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: switch (_step) {
        _Step.intro => IntroPages(
          topAction: language,
          onDone: () => _goTo(_Step.profile),
        ),
        _Step.profile => _buildProfile(context, language),
        _Step.currency => _buildCurrency(context, language),
      },
    );
  }

  Widget _buildProfile(BuildContext context, Widget language) {
    final l10n = context.l10n;
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _back),
        actions: [language],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
                children: [
                  Center(
                    child: IconBadge(
                      icon: Icons.person_rounded,
                      color: c.primary,
                      size: 72,
                    ),
                  ),
                  const SizedBox(height: Insets.lg),
                  Text(
                    l10n.profileTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.profileSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.textSecondary),
                  ),
                  const SizedBox(height: Insets.xl),
                  ProfileFields(
                    name: _name,
                    phone: _phone,
                    phoneError: _phoneError,
                    onChanged: () => setState(() => _phoneError = null),
                    onSubmitted: _submitProfile,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Insets.screen),
              child: FilledButton(
                onPressed: _name.text.trim().isEmpty ? null : _submitProfile,
                child: Text(l10n.continueLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrency(BuildContext context, Widget language) {
    final l10n = context.l10n;
    final c = context.colors;
    final arabic = ref.watch(isArabicProvider);
    final currencies = _filtered(arabic);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _back),
        actions: [language],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
                children: [
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
                    style: Theme.of(context).textTheme.titleLarge,
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
                      onPressed: _restore,
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

/// تبديل اللغة من أول شاشة.
class _LanguageToggle extends ConsumerWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arabic = ref.watch(isArabicProvider);
    return TextButton.icon(
      icon: const Icon(Icons.language_rounded, size: 20),
      label: Text(arabic ? 'English' : 'العربية'),
      onPressed: () => ref
          .read(settingsServiceProvider)
          .set(SettingKeys.locale, arabic ? 'en' : 'ar'),
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
