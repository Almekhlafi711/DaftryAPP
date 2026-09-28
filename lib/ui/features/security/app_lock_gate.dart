// =============================================================================
// بوابة قفل التطبيق (FR-24): تُظهر شاشة القفل فوق كل التطبيق عند الفتح،
// وعند العودة إليه بعد دقيقة أو أكثر في الخلفية (المتطلبات غير الوظيفية).
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

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final prefs = ref.read(preferencesProvider).value;
    if (!(prefs?.biometricEnabled ?? false) || !mounted) return;
    final ok = await ref
        .read(securityServiceProvider)
        .authenticateBiometric(context.l10n.unlockReason);
    if (ok) widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final biometric =
        ref.watch(preferencesProvider).value?.biometricEnabled ?? false;
    return Material(
      color: c.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                IconBadge(icon: Icons.lock_rounded, color: c.primary, size: 64),
                const SizedBox(height: 12),
                Text(
                  l10n.lockedTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
                    final ok = await ref
                        .read(securityServiceProvider)
                        .verifyPin(pin);
                    if (ok) {
                      widget.onUnlocked();
                      return false;
                    }
                    setState(() => _error = l10n.wrongPin);
                    return true;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
