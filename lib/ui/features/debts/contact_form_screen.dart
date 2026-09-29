// =============================================================================
// إضافة شخص يدوياً أو تعديل بياناته (شاشة مستقلة — FR-14).
// - الاسم والهاتف والملاحظة تكفي (الشخص نفسه هو الدفتر).
// - منع التكرار: عند كتابة اسم موجود يظهر «أحمد علي موجود، هل تقصده؟».
// عند الإضافة تُغلق الشاشة وتعيد رقم الشخص (الجديد أو الموجود) لمن فتحها.
// =============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../services/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

class ContactFormScreen extends ConsumerStatefulWidget {
  const ContactFormScreen({super.key, this.contactId});

  final int? contactId;

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  Contact? _duplicate;
  Timer? _debounce;
  bool _saving = false;

  bool get _isNew => widget.contactId == null;

  @override
  void initState() {
    super.initState();
    if (!_isNew) {
      ref.read(contactServiceProvider).getById(widget.contactId!).then((c) {
        if (c == null || !mounted) return;
        _name.text = c.name;
        _phone.text = c.phone ?? '';
        _note.text = c.note ?? '';
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_name, _phone, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  /// يبحث عن شخص بنفس الاسم بعد توقف الكتابة قليلاً.
  void _onNameChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final found = await ref
          .read(contactServiceProvider)
          .findByName(value, exceptId: widget.contactId);
      if (mounted) setState(() => _duplicate = found);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final service = ref.read(contactServiceProvider);
    try {
      if (_isNew) {
        final id = await service.create(
          name: _name.text,
          phone: _phone.text,
          note: _note.text,
        );
        if (mounted) context.pop(id);
      } else {
        await service.update(
          widget.contactId!,
          name: _name.text,
          phone: _phone.text,
          note: _note.text,
        );
        if (mounted) context.pop();
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
    final c = context.colors;
    final duplicate = _duplicate;
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? l10n.addPerson : l10n.editPerson)),
      body: ListView(
        padding: const EdgeInsets.all(Insets.screen),
        children: [
          TextField(
            controller: _name,
            autofocus: _isNew,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.name,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            onChanged: _onNameChanged,
          ),
          if (duplicate != null) ...[
            const SizedBox(height: Insets.sm),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              decoration: BoxDecoration(
                color: c.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: c.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.duplicatePerson(duplicate.name),
                      style: TextStyle(color: c.warning, fontSize: 13),
                    ),
                  ),
                  if (_isNew)
                    TextButton(
                      onPressed: () => context.pop(duplicate.id),
                      child: Text(l10n.useExisting),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Insets.md),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: '${l10n.phone} (${l10n.optional})',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '${l10n.note} (${l10n.optional})',
            ),
          ),
          const SizedBox(height: Insets.xl),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
