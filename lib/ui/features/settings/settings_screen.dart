// =============================================================================
// الشاشة 17: الإعدادات / المزيد.
// - الملف الشخصي: الاسم (يظهر في التقارير والكشوف) ورقم الجوال الاختياري.
// - العملة للقراءة فقط مع أيقونة قفل، و«إضافة عملة جديدة» رمادية «قريباً» (FR-02).
// - الإدارة: الحسابات، التقارير، الميزانية.
// - عام: الحساب الافتراضي، الفئات، اللغة والمظهر.
// - الأمان والبيانات: القفل، النسخ السحابي، التصدير المحلي، إعادة احتساب
//   الأرصدة، وحذف جميع البيانات (الطريقة الوحيدة لتغيير العملة).
// - في الأسفل: شعارات التواصل مع الدعم (واتساب، اتصال، إنستغرام)، ثم اسم
//   المطوّر، ثم رقم الإصدار.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
import '../profile/profile_form.dart';
import '../security/app_lock_gate.dart';

/// رقم الإصدار من ملف البناء نفسه (version في pubspec.yaml) فلا يُحدَّث يدوياً.
final _appVersionProvider = FutureProvider<String?>((ref) async {
  try {
    return (await PackageInfo.fromPlatform()).version;
  } on Exception {
    return null;
  }
});

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
    final version = ref.watch(_appVersionProvider).value;

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
          SectionTitle(l10n.sectionProfile),
          group([
            ListTile(
              leading: IconBadge(
                icon: Icons.person_outline_rounded,
                color: c.primary,
                size: 36,
              ),
              title: Text(
                prefs?.userName ?? l10n.addYourName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: prefs?.userName == null ? c.warning : null,
                ),
              ),
              subtitle: prefs?.userPhone == null
                  ? Text(l10n.noPhone)
                  : Text(prefs!.userPhone!, textDirection: TextDirection.ltr),
              trailing: Icon(Icons.edit_outlined, color: c.textSecondary),
              onTap: () => showEditProfileSheet(context),
            ),
          ]),
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
                final accounts = ref.read(accountServiceProvider);
                final money = ref.read(moneyFormatterProvider);
                final fixed = await accounts.recalculateAll();
                // فحص تلقائي بمعادلة التطابق الشاملة بعد إعادة الاحتساب.
                final gap = await accounts.reconciliationGap();
                if (context.mounted) {
                  showMessage(
                    context,
                    '${l10n.recalculateDone('$fixed')}\n'
                    '${gap == 0 ? l10n.reconcileOk : l10n.reconcileGap(money.inline(gap))}',
                    error: gap != 0,
                    duration: const Duration(seconds: 5),
                  );
                }
              },
            ),
          ]),
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
          // التذييل: التواصل مع الدعم ← المطوّر ← رقم الإصدار.
          const SizedBox(height: Insets.xl),
          const _SupportLinks(),
          const SizedBox(height: Insets.xl),
          Text(
            l10n.developedBy,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (version != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.version(version),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
          ],
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

/// شعارات التواصل مع فريق الدعم — كل شعار يفتح تطبيقه مباشرة. الشعارات
/// الثلاثة بنفس الشكل والحجم وبألوان لوحة التطبيق (مثل أيقونات الإعدادات).
class _SupportLinks extends ConsumerWidget {
  const _SupportLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;

    Future<void> open(Uri uri) async {
      final ok = await ref.read(externalLinkServiceProvider).open(uri);
      if (!ok && context.mounted) {
        showMessage(context, l10n.linkOpenFailed, error: true);
      }
    }

    return Column(
      children: [
        Text(
          l10n.contactSupport,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Insets.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SupportButton(
              label: l10n.supportWhatsApp,
              icon: const FaIcon(FontAwesomeIcons.whatsapp),
              color: c.income,
              onTap: () => open(SupportContacts.whatsappUri),
            ),
            const SizedBox(width: Insets.lg),
            _SupportButton(
              label: l10n.supportCall,
              icon: const Icon(Icons.call_rounded),
              color: c.transfer,
              onTap: () => open(SupportContacts.phoneUri),
            ),
            const SizedBox(width: Insets.lg),
            _SupportButton(
              label: l10n.supportInstagram,
              icon: const FaIcon(FontAwesomeIcons.instagram),
              color: c.archive,
              onTap: () => open(SupportContacts.instagramUri),
            ),
          ],
        ),
      ],
    );
  }
}

/// زر بشعار فقط (الاسم يظهر كتلميح ولقارئ الشاشة) بشكل IconBadge نفسه.
class _SupportButton extends StatelessWidget {
  const _SupportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  static const _size = 48.0;

  final String label;
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_size * 0.3);
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        child: Material(
          color: context.colors.tint(color),
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: SizedBox.square(
              dimension: _size,
              child: IconTheme(
                data: IconThemeData(color: color, size: 24),
                child: Center(child: icon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
