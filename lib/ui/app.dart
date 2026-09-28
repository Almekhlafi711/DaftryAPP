// =============================================================================
// ودجت التطبيق الجذري: الثيم، اللغة واتجاه الكتابة، التنقل، وقفل التطبيق.
// الاتجاه (RTL/LTR) يتبع اللغة تلقائياً — التصميم واحد (الشاشة 19).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../services/providers.dart';
import 'features/security/app_lock_gate.dart';
import 'router/routes.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class DaftryApp extends ConsumerWidget {
  const DaftryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);

    // شاشة بداية قصيرة حتى تُقرأ الإعدادات (أجزاء من الثانية).
    if (!prefs.hasValue) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const Scaffold(body: SizedBox.shrink()),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      routerConfig: ref.watch(routerProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      builder: (context, child) => _AppEffects(
        child: AppLockGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// مهام تعمل مرة عند فتح التطبيق وعند تغيير اللغة:
/// - تجهيز نصوص الإشعارات بلغة المستخدم.
/// - النسخ الاحتياطي المجدول إن حان موعده (وكان مفعّلاً).
class _AppEffects extends ConsumerStatefulWidget {
  const _AppEffects({required this.child});

  final Widget child;

  @override
  ConsumerState<_AppEffects> createState() => _AppEffectsState();
}

class _AppEffectsState extends ConsumerState<_AppEffects> {
  @override
  void initState() {
    super.initState();
    // بعد أول إطار حتى لا نؤخر ظهور الواجهة.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupServiceProvider).runScheduledIfDue();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context);
    final money = ref.read(moneyFormatterProvider);
    ref.read(notificationServiceProvider).texts = ReminderTexts(
      channelName: l10n.notifChannel,
      title: l10n.notifTitle,
      owedToMeBody: (name, amount) => l10n.notifOwedToMe(amount, name),
      iOweBody: (name, amount) => l10n.notifIOwe(amount, name),
      formatAmount: (minor) => money.format(minor, withSymbol: true),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
