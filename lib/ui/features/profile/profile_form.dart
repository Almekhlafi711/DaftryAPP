// =============================================================================
// الملف الشخصي: الاسم (مطلوب — يظهر في التقارير وكشوف الحساب) ورقم الجوال
// (اختياري). الحقول نفسها في الإعداد الأول وفي نافذة التعديل من الإعدادات.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../services/export/document_owner.dart';
import '../../../services/providers.dart';
import '../../../services/settings_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

/// حقلا الاسم ورقم الجوال.
class ProfileFields extends StatelessWidget {
  const ProfileFields({
    super.key,
    required this.name,
    required this.phone,
    this.phoneError,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final String? phoneError;
  final VoidCallback? onChanged;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(l10n.yourName, required: true),
        TextField(
          controller: name,
          autofocus: autofocus,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            LengthLimitingTextInputFormatter(SettingsService.maxNameLength),
          ],
          style: const TextStyle(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: l10n.yourName,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            // علامة صح بعد إدخال الاسم.
            suffixIcon: name.text.trim().isEmpty
                ? null
                : Icon(Icons.check_rounded, color: c.income),
          ),
          onChanged: (_) => onChanged?.call(),
        ),
        const SizedBox(height: Insets.lg),
        FieldLabel(l10n.phoneOptional),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          // الأرقام تُكتب دائماً من اليسار لليمين.
          textDirection: TextDirection.ltr,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹+\-\s()]')),
            LengthLimitingTextInputFormatter(20),
          ],
          decoration: InputDecoration(
            hintText: l10n.phoneHint,
            hintTextDirection: TextDirection.ltr,
            prefixIcon: const Icon(Icons.phone_outlined),
            errorText: phoneError,
          ),
          onChanged: (_) => onChanged?.call(),
          onSubmitted: (_) => onSubmitted?.call(),
        ),
        const SizedBox(height: Insets.lg),
        // ملاحظة: الاسم والهاتف قابلان للتغيير من الإعدادات.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.tint(c.transfer),
            borderRadius: BorderRadius.circular(Radii.chip),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: c.transfer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.profileChangeLater,
                  style: TextStyle(fontSize: 12.5, color: c.transfer),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// عنوان الحقل فوقه، مع نجمة حمراء للحقل الإلزامي.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(color: c.expense),
              ),
          ],
        ),
        style: TextStyle(fontSize: 13, color: c.textSecondary),
      ),
    );
  }
}

/// صاحب الدفتر لترويسة الكشوف والتقارير (null إن لم يُدخل اسمه بعد).
DocumentOwner? documentOwner(BuildContext context, WidgetRef ref) {
  final prefs = ref.read(preferencesProvider).value;
  final name = prefs?.userName;
  if (name == null) return null;
  return DocumentOwner(
    label: context.l10n.issuedBy(name),
    phone: prefs?.userPhone,
  );
}

/// يعيد رسالة الخطأ إن كان الرقم غير صالح، أو null إن كان صالحاً أو فارغاً.
String? phoneErrorFor(BuildContext context, String phone) {
  try {
    SettingsService.normalizePhone(phone);
    return null;
  } on BusinessException {
    return context.l10n.errInvalidPhone;
  }
}

/// نافذة تعديل الاسم ورقم الجوال من الإعدادات.
Future<void> showEditProfileSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _EditProfileSheet(),
    );

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _prefs = ref.read(preferencesProvider).value;
  late final _name = TextEditingController(text: _prefs?.userName ?? '');
  late final _phone = TextEditingController(text: _prefs?.userPhone ?? '');
  String? _phoneError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    final error = phoneErrorFor(context, _phone.text);
    if (error != null) {
      setState(() => _phoneError = error);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(settingsServiceProvider)
          .saveProfile(name: _name.text, phone: _phone.text);
      if (mounted) {
        final l10n = context.l10n;
        Navigator.pop(context);
        showMessage(context, l10n.saved);
      }
    } on Object catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      // يرتفع فوق لوحة المفاتيح.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Insets.screen,
            0,
            Insets.screen,
            Insets.screen,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.editProfile,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Insets.lg),
              ProfileFields(
                name: _name,
                phone: _phone,
                phoneError: _phoneError,
                onChanged: () => setState(() => _phoneError = null),
                onSubmitted: _save,
              ),
              const SizedBox(height: Insets.xl),
              FilledButton(
                onPressed: _canSave ? _save : null,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
