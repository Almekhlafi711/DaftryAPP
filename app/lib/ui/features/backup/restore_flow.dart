// =============================================================================
// تدفقات مشتركة للنسخ الاحتياطي: إدخال كلمة المرور، واستعادة نسخة من ملف محلي
// أو من السحابة. تُستخدم في شاشة الإعداد الأول وشاشة النسخ الاحتياطي.
// =============================================================================

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums.dart';
import '../../../services/backup/cloud_provider.dart';
import '../../../services/providers.dart';
import '../../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/labels.dart';

/// نافذة إدخال كلمة مرور التشفير. [confirm] لطلب إعادة إدخالها (عند الإنشاء).
Future<String?> askBackupPassword(
  BuildContext context, {
  bool confirm = false,
}) {
  final first = TextEditingController();
  final second = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final l10n = ctx.l10n;
        void submit() {
          if (first.text.length < 6) {
            setState(() => error = l10n.passwordTooShort);
            return;
          }
          if (confirm && first.text != second.text) {
            setState(() => error = l10n.pinMismatch);
            return;
          }
          Navigator.pop(ctx, first.text);
        }

        return AlertDialog(
          title: Text(l10n.backupPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.backupPasswordHint,
                style: TextStyle(
                  fontSize: 12.5,
                  color: ctx.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: first,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  errorText: error,
                ),
                onSubmitted: (_) => confirm ? null : submit(),
              ),
              if (confirm) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: second,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.confirm),
                  onSubmitted: (_) => submit(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(onPressed: submit, child: Text(l10n.confirm)),
          ],
        );
      },
    ),
  );
}

/// خيارات الاستعادة: ملف محلي، Google Drive، iCloud.
Future<void> showRestoreOptions(BuildContext context, WidgetRef ref) async {
  final providers = ref.read(cloudProvidersProvider);
  final available = <BackupProvider>[BackupProvider.local];
  for (final entry in providers.entries) {
    if (await entry.value.isAvailable()) available.add(entry.key);
  }
  if (!context.mounted) return;
  final choice = await showModalBottomSheet<BackupProvider>(
    context: context,
    builder: (ctx) {
      final l10n = ctx.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.restore, style: Theme.of(ctx).textTheme.titleMedium),
            for (final p in available)
              ListTile(
                leading: Icon(switch (p) {
                  BackupProvider.local => Icons.folder_open_rounded,
                  BackupProvider.googleDrive => Icons.add_to_drive_rounded,
                  BackupProvider.iCloud => Icons.cloud_outlined,
                }),
                title: Text(switch (p) {
                  BackupProvider.local => l10n.importLocalFile,
                  BackupProvider.googleDrive => l10n.googleDrive,
                  BackupProvider.iCloud => l10n.iCloud,
                }),
                onTap: () => Navigator.pop(ctx, p),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return;
  if (choice == BackupProvider.local) {
    await restoreFromLocalFile(context, ref);
  } else {
    await restoreFromCloud(context, ref, providers[choice]!);
  }
}

/// استعادة من ملف .dftry يختاره المستخدم.
Future<void> restoreFromLocalFile(BuildContext context, WidgetRef ref) async {
  final file = await FilePicker.pickFile();
  if (file == null || !context.mounted) return;
  final bytes = await file.readAsBytes();
  if (!context.mounted) return;
  await _restoreBytes(context, ref, () async => bytes);
}

/// استعادة من السحابة: الإذن ← اختيار نسخة ← كلمة المرور ← الاستعادة.
Future<void> restoreFromCloud(
  BuildContext context,
  WidgetRef ref,
  CloudProvider provider,
) async {
  final l10n = context.l10n;
  try {
    if (!await provider.authorize()) {
      if (context.mounted) {
        showMessage(context, l10n.errCloudNotAuthorized, error: true);
      }
      return;
    }
    await ref
        .read(settingsServiceProvider)
        .set(SettingKeys.backupProvider, provider.kind.name);
    final files = await provider.list();
    if (!context.mounted) return;
    if (files.isEmpty) {
      showMessage(context, l10n.noCloudBackups, error: true);
      return;
    }
    final dates = DateLabels(Localizations.localeOf(context).languageCode);
    final picked = await showModalBottomSheet<CloudBackupFile>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(l10n.chooseBackup)),
            for (final f in files)
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text(dates.dateTime(f.createdAt)),
                subtitle: Text('${(f.sizeBytes / 1024).ceil()} KB'),
                onTap: () => Navigator.pop(ctx, f),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    await _restoreBytes(context, ref, () => provider.download(picked.id));
  } on Object catch (e) {
    if (context.mounted) showError(context, e);
  }
}

Future<void> _restoreBytes(
  BuildContext context,
  WidgetRef ref,
  Future<List<int>> Function() load,
) async {
  final l10n = context.l10n;
  final password = await askBackupPassword(context);
  if (password == null || !context.mounted) return;
  final ok = await confirmAction(
    context,
    title: l10n.restore,
    message: l10n.restoreConfirm,
    confirmLabel: l10n.restore,
    icon: Icons.settings_backup_restore_rounded,
  );
  if (!ok || !context.mounted) return;
  try {
    final bytes = await load();
    await ref.read(backupServiceProvider).restoreEncrypted(bytes, password);
    // نحفظ كلمة المرور للنسخ المجدول لاحقاً على هذا الجهاز.
    await ref.read(backupServiceProvider).savePassword(password);
    if (context.mounted) showMessage(context, l10n.restoreDone);
  } on Object catch (e) {
    if (context.mounted) showError(context, e);
  }
}
