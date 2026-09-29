// =============================================================================
// اختيار شخص للدين (FR-14): من القائمة، أو من جهات اتصال الجهاز، أو إضافة يدوية.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as device;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../services/providers.dart';
import '../../router/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

/// يعيد الشخص المختار أو null.
Future<Contact?> pickContact(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<Contact>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ContactPickerSheet(),
    );

/// اختيار شخص من جهات اتصال الجهاز مباشرة (منتقي النظام — لا يحتاج إذناً
/// للاسم) وإضافته إلى الأشخاص. يعيد null عند الإلغاء أو الخطأ.
Future<Contact?> pickDeviceContact(BuildContext context, WidgetRef ref) async {
  device.Contact? picked;
  try {
    await device.FlutterContacts.permissions.request(
      device.PermissionType.read,
    );
    picked = await device.FlutterContacts.native.showPicker(
      properties: {device.ContactProperty.phone},
    );
  } on PlatformException {
    // بدون إذن: نكتفي بالاسم.
    picked = await device.FlutterContacts.native.showPicker();
  }
  if (picked == null || !context.mounted) return null;
  final service = ref.read(contactServiceProvider);
  try {
    final id = await service.create(
      name: picked.displayName ?? '',
      phone: picked.phones.firstOrNull?.number,
    );
    return await service.getById(id);
  } on Object catch (e) {
    if (context.mounted) showError(context, e);
    return null;
  }
}

class _ContactPickerSheet extends ConsumerStatefulWidget {
  const _ContactPickerSheet();

  @override
  ConsumerState<_ContactPickerSheet> createState() =>
      _ContactPickerSheetState();
}

class _ContactPickerSheetState extends ConsumerState<_ContactPickerSheet> {
  String _query = '';

  Future<void> _fromDevice() async {
    final contact = await pickDeviceContact(context, ref);
    if (contact != null && mounted) Navigator.pop(context, contact);
  }

  Future<void> _addManually() async {
    final id = await context.push<int>(AppRoutes.newPerson);
    if (id == null || !mounted) return;
    final contact = await ref.read(contactServiceProvider).getById(id);
    if (mounted) Navigator.pop(context, contact);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final contacts = ref.watch(_searchProvider(_query));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchPeople,
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Insets.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.contacts_outlined),
                    label: Text(l10n.fromContacts),
                    onPressed: _fromDevice,
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: Text(l10n.addPerson),
                    onPressed: _addManually,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                for (final p in contacts.value ?? const <Contact>[])
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.primary.withValues(alpha: 0.1),
                      child: Text(
                        p.name.characters.first,
                        style: TextStyle(
                          color: c.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(p.name),
                    subtitle: p.phone == null
                        ? null
                        : Text(p.phone!, textDirection: TextDirection.ltr),
                    onTap: () => Navigator.pop(context, p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _searchProvider = StreamProvider.autoDispose
    .family<List<Contact>, String>(
      (ref, q) => ref.watch(contactServiceProvider).watchActive(query: q),
    );
