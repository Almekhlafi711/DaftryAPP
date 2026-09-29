// =============================================================================
// إعدادات قفل التطبيق: تفعيل القفل (يتطلب إنشاء PIN)، البصمة/الوجه، تغيير الرمز.
// إيقاف القفل وتغيير الرمز يتطلبان إثبات الهوية أولاً، حتى لا يُتجاوز القفل
// (مثلاً قبل حذف كل البيانات) بمجرد الوصول إلى الإعدادات.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/providers.dart';
import '../../../services/settings_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'app_lock_gate.dart';
import 'pin_pad.dart';

final _canBiometricProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(securityServiceProvider).canUseBiometrics(),
);

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  /// إنشاء PIN بخطوتين (إدخال ثم تأكيد). يعيد true عند النجاح.
  static Future<bool> createPin(BuildContext context, WidgetRef ref) async {
    final pin = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _CreatePinPage(),
      ),
    );
    if (pin == null) return false;
    await ref.read(securityServiceProvider).setPin(pin);
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final prefs = ref.watch(preferencesProvider).value;
    final settings = ref.read(settingsServiceProvider);
    final lockEnabled = prefs?.lockEnabled ?? false;
    final canBiometric = ref.watch(_canBiometricProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appLock)),
      body: ListView(
        padding: const EdgeInsets.all(Insets.screen),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.lock_outline_rounded, color: c.primary),
                  title: Text(l10n.appLock),
                  subtitle: Text(
                    l10n.lockAfterHint,
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: lockEnabled,
                  onChanged: (v) async {
                    if (v) {
                      if (await createPin(context, ref)) {
                        await settings.setFlag(SettingKeys.lockEnabled, true);
                      }
                    } else {
                      final verified = await verifyIdentity(
                        context,
                        reason: l10n.disableLockReason,
                      );
                      if (!verified) return;
                      await settings.setFlag(SettingKeys.lockEnabled, false);
                      await settings.setFlag(
                        SettingKeys.biometricEnabled,
                        false,
                      );
                      await ref.read(securityServiceProvider).clearPin();
                    }
                  },
                ),
                if (lockEnabled) ...[
                  const Divider(),
                  SwitchListTile(
                    secondary: Icon(Icons.fingerprint_rounded, color: c.income),
                    title: Text(l10n.biometricUnlock),
                    value: prefs?.biometricEnabled ?? false,
                    onChanged: canBiometric
                        ? (v) async {
                            // نتحقق مرة قبل التفعيل حتى نتأكد أن البصمة تعمل.
                            final ok =
                                !v ||
                                await ref
                                    .read(securityServiceProvider)
                                    .authenticateBiometric(l10n.unlockReason);
                            if (ok) {
                              await settings.setFlag(
                                SettingKeys.biometricEnabled,
                                v,
                              );
                            }
                          }
                        : null,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: Text(l10n.changePin),
                    onTap: () async {
                      final verified = await verifyIdentity(
                        context,
                        reason: l10n.changePinReason,
                      );
                      if (verified && context.mounted) {
                        await createPin(context, ref);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePinPage extends StatefulWidget {
  const _CreatePinPage();

  @override
  State<_CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<_CreatePinPage> {
  String? _first;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: PinPad(
          key: ValueKey(_first == null),
          title: _first == null ? l10n.createPin : l10n.confirmPin,
          error: _error,
          onCompleted: (pin) async {
            if (_first == null) {
              setState(() {
                _first = pin;
                _error = null;
              });
              return true;
            }
            if (pin == _first) {
              Navigator.pop(context, pin);
              return false;
            }
            setState(() {
              _first = null;
              _error = l10n.pinMismatch;
            });
            return true;
          },
        ),
      ),
    );
  }
}
