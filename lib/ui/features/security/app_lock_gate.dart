// =============================================================================
// بوابة قفل التطبيق (FR-24): تُظهر شاشة القفل فوق كل التطبيق عند الفتح،
// وعند العودة إليه بعد دقيقة أو أكثر في الخلفية (المتطلبات غير الوظيفية).
// وتوفّر verifyIdentity لتأكيد الهوية قبل العمليات الحساسة (حذف كل البيانات).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/providers.dart';
import '../../../services/security_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import 'pin_pad.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;
  DateTime? _leftAt;
  late bool _locked = ref.read(preferencesProvider).value?.lockEnabled ?? false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _leftAt ??= DateTime.now(),
      onShow: () {
        final left = _leftAt;
        _leftAt = null;
        final enabled =
            ref.read(preferencesProvider).value?.lockEnabled ?? false;
        if (enabled &&
            left != null &&
            DateTime.now().difference(left) >= SecurityService.lockTimeout) {
          setState(() => _locked = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إن أُلغي القفل من الإعدادات نفتح فوراً.
    final enabled = ref.watch(preferencesProvider).value?.lockEnabled ?? false;
    final showLock = _locked && enabled;
    return Stack(
      children: [
        // نُبقي التطبيق حياً تحت شاشة القفل لكن نخفيه تماماً عن النظر.
        Offstage(offstage: showLock, child: widget.child),
        if (showLock)
          _LockScreen(onUnlocked: () => setState(() => _locked = false)),
      ],
    );
  }
}

/// شاشة القفل التي تغطي التطبيق كله.
class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.background,
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: UnlockPanel(
            title: context.l10n.lockedTitle,
            reason: context.l10n.unlockReason,
            onUnlocked: onUnlocked,
          ),
        ),
      ),
    ),
  );
}

/// يطلب من صاحب التطبيق إثبات هويته قبل عملية حساسة: البصمة/الوجه تُطلب
/// تلقائياً إن كانت مفعّلة، ورمز PIN متاح دائماً. يعيد true عند النجاح.
Future<bool> verifyIdentity(
  BuildContext context, {
  required String reason,
}) async {
  final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: SingleChildScrollView(
            child: UnlockPanel(
              title: ctx.l10n.verifyIdentity,
              reason: reason,
              onUnlocked: () => Navigator.pop(ctx, true),
            ),
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// لوحة فتح القفل: رمز PIN مع زر البصمة (وتُطلب البصمة تلقائياً عند الظهور).
class UnlockPanel extends ConsumerStatefulWidget {
  const UnlockPanel({
    super.key,
    required this.title,
    required this.reason,
    required this.onUnlocked,
  });

  final String title;

  /// السبب الظاهر في نافذة البصمة الخاصة بالنظام.
  final String reason;
  final VoidCallback onUnlocked;

  @override
  ConsumerState<UnlockPanel> createState() => _UnlockPanelState();
}

class _UnlockPanelState extends ConsumerState<UnlockPanel> {
  String? _error;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  /// مرة واحدة فقط، حتى لو نجحت البصمة والرمز معاً.
  void _unlock() {
    if (_unlocked || !mounted) return;
    _unlocked = true;
    widget.onUnlocked();
  }

  Future<void> _tryBiometric() async {
    final prefs = ref.read(preferencesProvider).value;
    if (!(prefs?.biometricEnabled ?? false) || !mounted) return;
    final ok = await ref
        .read(securityServiceProvider)
        .authenticateBiometric(widget.reason);
    if (ok) _unlock();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final biometric =
        ref.watch(preferencesProvider).value?.biometricEnabled ?? false;
    return Column(
      children: [
        IconBadge(icon: Icons.lock_rounded, color: c.primary, size: 64),
        const SizedBox(height: 12),
        Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        PinPad(
          title: l10n.enterPin,
          error: _error,
          extraAction: biometric
              ? IconButton(
                  tooltip: l10n.useBiometrics,
                  icon: Icon(
                    Icons.fingerprint_rounded,
                    color: c.primary,
                    size: 36,
                  ),
                  onPressed: _tryBiometric,
                )
              : null,
          onCompleted: (pin) async {
            final ok = await ref.read(securityServiceProvider).verifyPin(pin);
            if (ok) {
              _unlock();
              return false;
            }
            if (mounted) setState(() => _error = l10n.wrongPin);
            return true;
          },
        ),
      ],
    );
  }
}
