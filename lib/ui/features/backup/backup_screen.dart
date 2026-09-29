// =============================================================================
// الشاشة 18: النسخ الاحتياطي السحابي (اختياري) + النسخ المحلي (FR-25 / UC-12).
//
// إعدادات السحابة تظهر فقط بعد تفعيل الخيار: المزوّد (Google Drive / iCloud
// بحساب المستخدم)، التكرار، Wi-Fi فقط، التشفير، حالة آخر نسخة، نسخ الآن/استعادة.
// =============================================================================

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums.dart';
import '../../../services/backup/backup_service.dart';
import '../../../services/providers.dart';
import '../../../services/settings_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import 'restore_flow.dart';

final _backupLogsProvider = StreamProvider(
  (ref) => ref.watch(backupServiceProvider).watchLogs(),
);

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  SettingsService get _settings => ref.read(settingsServiceProvider);
  BackupService get _backup => ref.read(backupServiceProvider);

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// كلمة المرور المحفوظة، أو طلب إنشائها أول مرة.
  Future<String?> _ensurePassword() async {
    final saved = await _backup.savedPassword();
    if (saved != null) return saved;
    if (!mounted) return null;
    final created = await askBackupPassword(context, confirm: true);
    if (created != null) await _backup.savePassword(created);
    return created;
  }

  Future<void> _toggleCloud(bool enable, AppPreferences prefs) => _run(
    () async {
      if (!enable) {
        await _settings.setFlag(SettingKeys.backupEnabled, false);
        return;
      }
      if (await _ensurePassword() == null) return;
      final provider = ref.read(cloudProvidersProvider)[prefs.backupProvider]!;
      if (!await provider.authorize()) {
        if (mounted) {
          showMessage(context, context.l10n.errCloudNotAuthorized, error: true);
        }
        return;
      }
      await _settings.setFlag(SettingKeys.backupEnabled, true);
    },
  );

  Future<void> _selectProvider(BackupProvider kind) => _run(() async {
    final provider = ref.read(cloudProvidersProvider)[kind]!;
    if (!await provider.isAvailable() || !await provider.authorize()) {
      if (mounted) {
        showMessage(context, context.l10n.errCloudNotAuthorized, error: true);
      }
      return;
    }
    await _settings.set(SettingKeys.backupProvider, kind.name);
  });

  Future<void> _backupNow() => _run(() async {
    final password = await _ensurePassword();
    if (password == null) return;
    await _backup.backupToCloud(password: password);
    if (mounted) showMessage(context, context.l10n.backupDone);
  });

  Future<void> _exportLocal() => _run(() async {
    final password = await _ensurePassword();
    if (password == null) return;
    final bytes = await _backup.createEncryptedBackup(password);
    await FilePicker.saveFile(
      fileName: BackupService.fileNameFor(DateTime.now()),
      bytes: bytes,
    );
  });

  Future<void> _changePassword() async {
    final created = await askBackupPassword(context, confirm: true);
    if (created != null) {
      await _backup.savePassword(created);
      if (mounted) showMessage(context, context.l10n.saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final prefs = ref.watch(preferencesProvider).value;
    if (prefs == null) return const Scaffold();
    final dates = ref.watch(dateLabelsProvider);
    final enabled = prefs.backupEnabled;
    final logs = ref.watch(_backupLogsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(Insets.screen),
          children: [
            if (_busy) const LinearProgressIndicator(),
            // مفتاح التفعيل الرئيسي
            AppCard(
              color: enabled ? c.brand : null,
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    color: enabled ? Colors.white : c.transfer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enabled ? l10n.cloudBackupOn : l10n.cloudBackupOff,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: enabled ? Colors.white : null,
                          ),
                        ),
                        Text(
                          l10n.cloudBackupHint,
                          style: TextStyle(
                            fontSize: 12,
                            color: enabled ? Colors.white70 : c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    activeTrackColor: Colors.white24,
                    onChanged: (v) => _toggleCloud(v, prefs),
                  ),
                ],
              ),
            ),
            if (enabled) ...[
              SectionTitle(l10n.storageProvider),
              Row(
                children: [
                  for (final kind in [
                    BackupProvider.googleDrive,
                    BackupProvider.iCloud,
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: _ProviderCard(
                          icon: kind == BackupProvider.googleDrive
                              ? Icons.add_to_drive_rounded
                              : Icons.cloud_rounded,
                          title: kind == BackupProvider.googleDrive
                              ? l10n.googleDrive
                              : l10n.iCloud,
                          subtitle: kind == BackupProvider.iCloud
                              ? l10n.appleDevicesOnly
                              : null,
                          selected: prefs.backupProvider == kind,
                          enabled:
                              kind != BackupProvider.iCloud || Platform.isIOS,
                          connectedLabel: l10n.connected,
                          onTap: () => _selectProvider(kind),
                        ),
                      ),
                    ),
                ],
              ),
              SectionTitle(l10n.frequency),
              SegmentedTabs<String>(
                values: const ['daily', 'weekly', 'monthly'],
                selected: prefs.backupFrequency,
                label: (v) => switch (v) {
                  'daily' => l10n.daily,
                  'monthly' => l10n.monthly,
                  _ => l10n.weekly,
                },
                onChanged: (v) => _settings.set(SettingKeys.backupFrequency, v),
              ),
              const SizedBox(height: Insets.md),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.wifi_rounded, color: c.transfer),
                      title: Text(l10n.wifiOnly),
                      value: prefs.backupWifiOnly,
                      onChanged: (v) =>
                          _settings.setFlag(SettingKeys.backupWifiOnly, v),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.lock_outline_rounded,
                        color: c.income,
                      ),
                      title: Text(l10n.encryptionInfo),
                      trailing: Icon(
                        Icons.check_circle_rounded,
                        color: c.income,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.key_rounded),
                      title: Text(l10n.backupPassword),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _changePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Insets.md),
              AppCard(
                child: Row(
                  children: [
                    Icon(
                      prefs.backupLastAt != null
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      color: prefs.backupLastAt != null ? c.income : c.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        prefs.backupLastAt != null
                            ? l10n.lastBackup(
                                dates.dateTime(prefs.backupLastAt!),
                              )
                            : l10n.neverBackedUp,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Insets.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(l10n.backupNow),
                      onPressed: _backupNow,
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.settings_backup_restore_rounded),
                      label: Text(l10n.restore),
                      onPressed: () => restoreFromCloud(
                        context,
                        ref,
                        ref.read(cloudProvidersProvider)[prefs.backupProvider]!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // النسخ المحلي متاح دائماً (دون إنترنت).
            SectionTitle(l10n.localBackup),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: Text(l10n.exportLocalFile),
                    onTap: _exportLocal,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: Text(l10n.importLocalFile),
                    onTap: () => restoreFromLocalFile(context, ref),
                  ),
                ],
              ),
            ),
            if (logs.isNotEmpty) ...[
              const SizedBox(height: Insets.lg),
              for (final log in logs.take(5))
                ListTile(
                  dense: true,
                  leading: Icon(
                    log.status == 'success'
                        ? Icons.check_rounded
                        : Icons.error_outline,
                    color: log.status == 'success' ? c.income : c.expense,
                    size: 18,
                  ),
                  title: Text(dates.dateTime(log.createdAt)),
                  trailing: Text('${log.sizeKb} KB'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.enabled,
    required this.connectedLabel,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final String connectedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: AppCard(
        onTap: enabled ? onTap : null,
        color: selected ? c.primary.withValues(alpha: 0.08) : null,
        child: Column(
          children: [
            Icon(icon, color: selected ? c.primary : c.textSecondary, size: 30),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (selected)
              Text(
                connectedLabel,
                style: TextStyle(fontSize: 11.5, color: c.income),
              )
            else if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11.5, color: c.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
