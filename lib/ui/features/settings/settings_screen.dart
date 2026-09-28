// =============================================================================
// الشاشة 17: الإعدادات / المزيد.
// - العملة للقراءة فقط مع أيقونة قفل، و«إضافة عملة جديدة» رمادية «قريباً» (FR-02).
// - الإدارة: الحسابات، التقارير، الميزانية.
// - عام: الحساب الافتراضي، الفئات، اللغة والمظهر.
// - الأمان والبيانات: القفل، النسخ السحابي، التصدير المحلي، إعادة احتساب
//   الأرصدة، وحذف جميع البيانات (الطريقة الوحيدة لتغيير العملة).
// - التواصل مع فريق الدعم: شعارات واتساب والاتصال وإنستغرام.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/support.dart';
import '../../../services/providers.dart';
import '../../../services/security_service.dart';
import '../../../services/settings_service.dart';
import '../../router/routes.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/inputs.dart';
import '../security/app_lock_gate.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final prefs = ref.watch(preferencesProvider).value;
    final currency = ref.watch(currencyInfoProvider);
    final arabic = ref.watch(isArabicProvider);
    final accounts = ref.watch(activeAccountsProvider).value ?? const [];
    final defaultAccount = accounts.where((a) => a.isDefault).firstOrNull;

    Widget tile({
      required IconData icon,
      required Color color,
      required String title,
      String? value,
      Widget? trailing,
      VoidCallback? onTap,
      Color? titleColor,
    }) => ListTile(
      leading: IconBadge(icon: icon, color: color, size: 36),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
      ),
      trailing:
          trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                Text(
                  value,
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: c.textSecondary),
            ],
          ),
      onTap: onTap,
    );

    Widget group(List<Widget> children) => AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 64),
            children[i],
          ],
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.screen,
          0,
          Insets.screen,
          Insets.xxl,
        ),
        children: [
          SectionTitle(l10n.sectionCurrency),
          group([
            ListTile(
              leading: IconBadge(
                icon: Icons.lock_outline_rounded,
                color: c.primary,
                size: 36,
              ),
              title: Text(
                currency == null
                    ? '—'
                    : '${currency.name(arabic)} — ${currency.code}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(l10n.appCurrencyLocked),
              trailing: Text(
                currency?.symbol(arabic) ?? '',
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w700),
              ),
            ),
            // تعدد العملات مؤجل: الخيار ظاهر لكنه غير فعّال.
            Opacity(
              opacity: 0.5,
              child: tile(
                icon: Icons.add_rounded,
                color: c.textSecondary,
                title: l10n.addCurrency,
                trailing: Pill(l10n.comingSoon, color: c.textSecondary),
              ),
            ),
          ]),
          SectionTitle(l10n.sectionManage),
          group([
            tile(
              icon: Icons.account_balance_wallet_outlined,
              color: c.primary,
              title: l10n.accountsTitle,
              value: '${accounts.length}',
              onTap: () => context.go(AppRoutes.accounts),
            ),
            tile(
              icon: Icons.bar_chart_rounded,
              color: c.transfer,
              title: l10n.reportsTitle,
              onTap: () => context.go(AppRoutes.reports),
            ),
            tile(
              icon: Icons.pie_chart_outline_rounded,
              color: c.warning,
              title: l10n.budgetTitle,
              onTap: () => context.go(AppRoutes.budget),
            ),
          ]),
          SectionTitle(l10n.sectionGeneral),
          group([
            tile(
              icon: Icons.star_outline_rounded,
              color: c.income,
              title: l10n.defaultAccount,
              value: defaultAccount?.name,
              onTap: () async {
                final picked = await pickAccount(
                  context,
                  selectedId: defaultAccount?.id,
                );
                if (picked != null) {
                  await ref.read(accountServiceProvider).setDefault(picked.id);
                }
              },
            ),
            tile(
              icon: Icons.sell_outlined,
              color: c.warning,
              title: l10n.categoriesTitle,
              onTap: () => context.go(AppRoutes.categories),
            ),
            tile(
              icon: Icons.language_rounded,
              color: c.transfer,
              title: l10n.languageAndAppearance,
              value: [
                switch (prefs?.locale) {
                  'ar' => l10n.languageArabic,
                  'en' => l10n.languageEnglish,
                  _ => l10n.followDevice,
                },
                switch (prefs?.themeMode) {
                  'light' => l10n.themeLight,
                  'dark' => l10n.themeDark,
                  _ => l10n.followDevice,
                },
              ].join(' • '),
              onTap: () => _showAppearance(context),
            ),
          ]),
          SectionTitle(l10n.sectionSecurityData),
          group([
            tile(
              icon: Icons.fingerprint_rounded,
              color: c.income,
              title: l10n.appLock,
              trailing: Switch(
                value: prefs?.lockEnabled ?? false,
                onChanged: (_) => context.go(AppRoutes.security),
              ),
              onTap: () => context.go(AppRoutes.security),
            ),
            tile(
              icon: Icons.cloud_outlined,
              color: c.transfer,
              title: l10n.cloudBackup,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!(prefs?.backupEnabled ?? false))
                    Pill(l10n.optional, color: c.textSecondary),
                  Switch(
                    value: prefs?.backupEnabled ?? false,
                    onChanged: (_) => context.go(AppRoutes.backup),
                  ),
                ],
              ),
              onTap: () => context.go(AppRoutes.backup),
            ),
            tile(
              icon: Icons.import_export_rounded,
              color: c.primary,
              title: l10n.localBackup,
              onTap: () => context.go(AppRoutes.backup),
            ),
            tile(
              icon: Icons.refresh_rounded,
              color: c.textSecondary,
              title: l10n.recalculateBalances,
              onTap: () async {
                final fixed = await ref
                    .read(accountServiceProvider)
                    .recalculateAll();
                if (context.mounted) {
                  showMessage(context, l10n.recalculateDone('$fixed'));
                }
              },
            ),
          ]),
          SectionTitle(l10n.contactSupport),
          const _SupportLinks(),
          const SizedBox(height: Insets.lg),
          group([
            tile(
              icon: Icons.delete_forever_outlined,
              color: c.expense,
              title: l10n.deleteAllData,
              titleColor: c.expense,
              onTap: () => _wipe(context, ref),
            ),
          ]),
          const SizedBox(height: Insets.lg),
          Center(
            child: Text(
              l10n.version('0.1.0'),
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// حذف جميع البيانات بتأكيد مزدوج (عملية لا يمكن التراجع عنها). إن كان
  /// التطبيق مقفلاً برمز: تأكيد ← البصمة (أو رمز PIN) ← تأكيد أخير.
  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final first = await confirmAction(
      context,
      title: l10n.deleteAllData,
      message: l10n.deleteAllDataBody,
      confirmLabel: l10n.continueLabel,
      icon: Icons.warning_amber_rounded,
    );
    if (!first || !context.mounted) return;
    if (ref.read(preferencesProvider).value?.lockEnabled ?? false) {
      final verified = await verifyIdentity(
        context,
        reason: l10n.deleteAllDataReason,
      );
      if (!verified || !context.mounted) return;
    }
    final second = await confirmAction(
      context,
      title: l10n.areYouSure,
      message: l10n.deleteAllDataBody,
      confirmLabel: l10n.deleteAllData,
    );
    if (!second) return;
    // نمسح أسرار الجهاز أيضاً (رمز PIN وكلمة مرور النسخ الاحتياطي).
    final security = ref.read(securityServiceProvider);
    await security.clearPin();
    await security.store.delete(SecurityService.backupPasswordKey);
    await ref.read(settingsServiceProvider).wipeAllData();
    // المُوجّه ينقل المستخدم تلقائياً إلى شاشة الإعداد الأول.
  }

  Future<void> _showAppearance(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final l10n = ctx.l10n;
        final prefs = ref.watch(preferencesProvider).value;
        final settings = ref.read(settingsServiceProvider);
        return SafeArea(
          child: Padding(
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
                Text(l10n.language, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedTabs<String>(
                  values: const ['ar', 'en', 'system'],
                  selected: prefs?.locale ?? 'system',
                  label: (v) => switch (v) {
                    'ar' => l10n.languageArabic,
                    'en' => l10n.languageEnglish,
                    _ => l10n.followDevice,
                  },
                  onChanged: (v) => settings.set(SettingKeys.locale, v),
                ),
                const SizedBox(height: Insets.lg),
                Text(l10n.theme, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedTabs<String>(
                  values: const ['light', 'dark', 'system'],
                  selected: prefs?.themeMode ?? 'system',
                  label: (v) => switch (v) {
                    'light' => l10n.themeLight,
                    'dark' => l10n.themeDark,
                    _ => l10n.followDevice,
                  },
                  onChanged: (v) => settings.set(SettingKeys.themeMode, v),
                ),
                const SizedBox(height: Insets.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.arabicDigits),
                  value: prefs?.arabicDigits ?? false,
                  onChanged: (v) =>
                      settings.setFlag(SettingKeys.arabicDigits, v),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// شعارات التواصل مع فريق الدعم — كل شعار يفتح تطبيقه مباشرة.
class _SupportLinks extends ConsumerWidget {
  const _SupportLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    Future<void> open(Uri uri) async {
      final ok = await ref.read(externalLinkServiceProvider).open(uri);
      if (!ok && context.mounted) {
        showMessage(context, l10n.linkOpenFailed, error: true);
      }
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: Insets.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BrandButton(
            label: l10n.supportWhatsApp,
            icon: const FaIcon(FontAwesomeIcons.whatsapp),
            color: const Color(0xFF25D366),
            onTap: () => open(SupportContacts.whatsappUri),
          ),
          _BrandButton(
            label: l10n.supportCall,
            icon: const Icon(Icons.call_rounded),
            color: context.colors.primary,
            onTap: () => open(SupportContacts.phoneUri),
          ),
          _BrandButton(
            label: l10n.supportInstagram,
            icon: const FaIcon(FontAwesomeIcons.instagram),
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFFFEDA75),
                Color(0xFFFA7E1E),
                Color(0xFFD62976),
                Color(0xFF962FBF),
                Color(0xFF4F5BD5),
              ],
            ),
            onTap: () => open(SupportContacts.instagramUri),
          ),
        ],
      ),
    );
  }
}

/// زر دائري بشعار فقط (الاسم يظهر كتلميح ولقارئ الشاشة).
class _BrandButton extends StatelessWidget {
  const _BrandButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.gradient,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Material(
      type: MaterialType.transparency,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          gradient: gradient,
        ),
        child: InkWell(
          onTap: onTap,
          child: IconTheme(
            data: const IconThemeData(color: Colors.white, size: 28),
            child: Center(child: icon),
          ),
        ),
      ),
    ),
  );
}
