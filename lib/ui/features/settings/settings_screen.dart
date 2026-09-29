// =============================================================================
// الشاشة 17: الإعدادات / المزيد (الشكلان 4-25 و 4-26 في الوثيقة).
// - أعلى الصفحة: بطاقة الملف الشخصي (الاسم والهاتف وزر «تعديل»)، ثم العملة
//   المقفلة و«إضافة عملة» الرمادية (FR-02)، ثم الحساب الافتراضي والفئات
//   (بعددها) واللغة، ثم الإدارة، ثم القفل والنسخ السحابي الاختياري.
// - أسفل الصفحة: البيانات (التصدير، إعادة احتساب الأرصدة، حذف جميع البيانات)،
//   ثم «الدفع الإلكتروني» مقفلاً «قيد التطوير» (FR-35)، ثم «تواصل معنا»
//   (واتساب، اتصال، إنستغرام)، ثم «تم التطوير من قبل محمد المخلافي» وتحته
//   رقم الإصدار.
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

/// عدد الفئات (دخل ومصروف) لصف «الفئات».
final _categoryCountProvider = StreamProvider.autoDispose<int>(
  (ref) =>
      ref.watch(categoryServiceProvider).watchAll().map((list) => list.length),
);

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
    final categoryCount = ref.watch(_categoryCountProvider).value;

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
          // بطاقة الملف الشخصي: الاسم (إلزامي) والهاتف، قابلان للتعديل.
          _ProfileCard(
            name: prefs?.userName,
            phone: prefs?.userPhone,
            onEdit: () => showEditProfileSheet(context),
          ),
          const SizedBox(height: Insets.md),
          group([
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.tint(c.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currency?.symbol(arabic) ?? '',
                  style: TextStyle(
                    color: c.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                currency == null
                    ? '—'
                    : '${currency.name(arabic)} — ${currency.code}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(l10n.appCurrencyLocked),
              trailing: Icon(
                Icons.lock_outline_rounded,
                color: c.textSecondary,
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
              value: categoryCount == null ? null : '$categoryCount',
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
          SectionTitle(l10n.sectionSecurity),
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
          ]),
          SectionTitle(l10n.sectionData),
          group([
            tile(
              icon: Icons.download_rounded,
              color: c.income,
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
            tile(
              icon: Icons.delete_forever_outlined,
              color: c.expense,
              title: l10n.deleteAllData,
              titleColor: c.expense,
              onTap: () => _wipe(context, ref),
            ),
          ]),
          // FR-35: الدفع الإلكتروني ظاهر لكنه مقفل «قيد التطوير».
          const _ElectronicPayments(),
          // التذييل: تواصل معنا ← المطوّر ← رقم الإصدار.
          const _SupportLinks(),
          const SizedBox(height: Insets.lg),
          Text.rich(
            TextSpan(
              text: '${l10n.developedByPrefix} ',
              children: [
                TextSpan(
                  text: l10n.developerName,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
          if (version != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.version(version),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 12.5),
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

/// بطاقة الملف الشخصي: دائرة بأول حرف من الاسم، الاسم والهاتف، وزر «تعديل».
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.onEdit,
  });

  final String? name;
  final String? phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final hasName = name != null && name!.trim().isNotEmpty;
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: c.brand,
            child: hasName
                ? Text(
                    name!.trim().characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : const Icon(Icons.person_outline_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? name! : l10n.addYourName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: hasName ? null : c.warning,
                  ),
                ),
                const SizedBox(height: 2),
                phone == null
                    ? Text(
                        l10n.noPhone,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: c.textSecondary,
                        ),
                      )
                    : Text(
                        phone!,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: c.textSecondary,
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: const StadiumBorder(),
              side: BorderSide(color: c.border),
            ),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(l10n.edit),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// FR-35: قسم الدفع الإلكتروني مقفل — لا ينفّذ أي عملية، ويعرض رسالة
/// «قيد التطوير» عند الضغط على أي خيار.
class _ElectronicPayments extends StatelessWidget {
  const _ElectronicPayments();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final options = [
      (
        Icons.account_balance_wallet_outlined,
        l10n.payLocalWallets,
        l10n.payLocalWalletsHint,
      ),
      (Icons.credit_card_rounded, l10n.payCards, l10n.payCardsHint),
      (Icons.payments_outlined, l10n.payOtherCards, l10n.payOtherCardsHint),
    ];
    void soon() => showMessage(
      context,
      l10n.ePaymentsSoon,
      icon: Icons.lock_outline_rounded,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 20, 4, 8),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  l10n.ePayments,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pill(l10n.underDevelopment, color: c.warning),
            ],
          ),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final (i, (icon, title, hint)) in options.indexed) ...[
                if (i > 0) const Divider(indent: 64),
                ListTile(
                  onTap: soon,
                  leading: IconBadge(
                    icon: icon,
                    color: c.textSecondary,
                    size: 36,
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                  trailing: Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// «تواصل معنا»: ثلاث أيقونات موحّدة التصميم (مربع ملوّن بأيقونة بيضاء
/// واسم تحتها) — كل أيقونة تفتح تطبيقها مباشرة.
class _SupportLinks extends ConsumerWidget {
  const _SupportLinks();

  /// لون إنستغرام (الوردي المميز للعلامة).
  static const _instagram = Color(0xFFC2185B);

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 20, 4, 12),
          child: Text(
            l10n.contactSupport,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SupportButton(
              label: l10n.supportWhatsApp,
              icon: const FaIcon(FontAwesomeIcons.whatsapp),
              color: const Color(0xFF16A34A),
              onTap: () => open(SupportContacts.whatsappUri),
            ),
            const SizedBox(width: Insets.xl),
            _SupportButton(
              label: l10n.supportCall,
              icon: const Icon(Icons.call_outlined),
              color: AppColors.light.brand,
              onTap: () => open(SupportContacts.phoneUri),
            ),
            const SizedBox(width: Insets.xl),
            _SupportButton(
              label: l10n.supportInstagram,
              icon: const FaIcon(FontAwesomeIcons.instagram),
              color: _instagram,
              onTap: () => open(SupportContacts.instagramUri),
            ),
          ],
        ),
      ],
    );
  }
}

/// مربع ملوّن بأيقونة بيضاء واسم تحته — الأزرار الثلاثة بالمقاس نفسه.
class _SupportButton extends StatelessWidget {
  const _SupportButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  static const _size = 60.0;

  final String label;
  final Widget icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 28),
                  child: Center(child: icon),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
