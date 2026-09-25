// =============================================================================
// إضافة شخص يدوياً أو تعديل بياناته (شاشة مستقلة — FR-14).
// عند الإضافة تُغلق الشاشة وتعيد رقم الشخص الجديد لمن فتحها.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/providers.dart';
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
  final _address = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.contactId != null) {
      ref.read(contactServiceProvider).getById(widget.contactId!).then((c) {
        if (c == null || !mounted) return;
        _name.text = c.name;
        _phone.text = c.phone ?? '';
        _address.text = c.address ?? '';
        _note.text = c.note ?? '';
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final service = ref.read(contactServiceProvider);
    try {
      if (widget.contactId == null) {
        final id = await service.create(
          name: _name.text,
          phone: _phone.text,
          address: _address.text,
          note: _note.text,
        );
        if (mounted) context.pop(id);
      } else {
        await service.update(
          widget.contactId!,
          name: _name.text,
          phone: _phone.text,
          address: _address.text,
          note: _note.text,
        );
        if (mounted) context.pop();
      }
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.contactId == null ? l10n.addPerson : l10n.editPerson,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.screen),
        children: [
          TextField(
            controller: _name,
            autofocus: widget.contactId == null,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.name,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: l10n.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _address,
            decoration: InputDecoration(
              labelText: '${l10n.address} (${l10n.optional})',
              prefixIcon: const Icon(Icons.place_outlined),
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
          FilledButton(onPressed: _save, child: Text(l10n.save)),
        ],
      ),
    );
  }
}
