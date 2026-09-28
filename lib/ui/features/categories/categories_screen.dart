// =============================================================================
// إدارة الفئات (FR-13): افتراضية ومخصصة بأيقونة ولون، منفصلة للدخل والمصروف.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/enums.dart';
import '../../../services/providers.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryKind _kind = CategoryKind.expense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final categories = ref.watch(categoriesByKindProvider(_kind));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesTitle),
        actions: [
          IconButton.filled(
            tooltip: l10n.addCategory,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showForm(context, kind: _kind),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.screen),
        children: [
          SegmentedTabs<CategoryKind>(
            values: CategoryKind.values.reversed.toList(),
            selected: _kind,
            label: (k) => k == CategoryKind.expense
                ? l10n.expenseCategories
                : l10n.incomeCategories,
            colorOf: (k) => k == CategoryKind.expense ? c.expense : c.income,
            onChanged: (k) => setState(() => _kind = k),
          ),
          const SizedBox(height: Insets.md),
          AsyncBody(
            value: categories,
            builder: (list) => AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final cat in list)
                    ListTile(
                      leading: IconBadge(
                        icon: AppIcons.category(cat.icon),
                        color: Color(cat.color),
                        size: 40,
                      ),
                      title: Text(cat.name),
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                      onTap: () =>
                          _showForm(context, kind: _kind, category: cat),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showForm(
    BuildContext context, {
    required CategoryKind kind,
    Category? category,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CategoryForm(kind: kind, category: category),
  );
}

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({required this.kind, this.category});

  final CategoryKind kind;
  final Category? category;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  late final _name = TextEditingController(text: widget.category?.name);
  late String _icon = widget.category?.icon ?? 'other';
  late int _color = widget.category?.color ?? AppIcons.palette.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final service = ref.read(categoryServiceProvider);
    try {
      if (widget.category == null) {
        await service.create(
          name: _name.text,
          kind: widget.kind,
          icon: _icon,
          color: _color,
        );
      } else {
        await service.update(
          widget.category!.id,
          name: _name.text,
          icon: _icon,
          color: _color,
        );
      }
      if (mounted) Navigator.pop(context);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _delete() async {
    try {
      await ref.read(categoryServiceProvider).delete(widget.category!.id);
      if (mounted) Navigator.pop(context);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Insets.screen,
        0,
        Insets.screen,
        MediaQuery.viewInsetsOf(context).bottom + Insets.screen,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconBadge(
                  icon: AppIcons.category(_icon),
                  color: Color(_color),
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _name,
                    autofocus: widget.category == null,
                    decoration: InputDecoration(labelText: l10n.categoryName),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            Text(l10n.icon, style: TextStyle(color: c.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in AppIcons.categoryIcons.entries)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _icon = entry.key),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _icon == entry.key
                            ? Color(_color).withValues(alpha: 0.15)
                            : c.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: _icon == entry.key
                            ? Border.all(color: Color(_color))
                            : null,
                      ),
                      child: Icon(entry.value, color: Color(_color)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.md),
            Text(l10n.color, style: TextStyle(color: c.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in AppIcons.palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(color),
                      child: _color == color
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            FilledButton(onPressed: _save, child: Text(l10n.save)),
            if (widget.category != null)
              TextButton.icon(
                icon: Icon(Icons.delete_outline_rounded, color: c.expense),
                label: Text(l10n.delete, style: TextStyle(color: c.expense)),
                onPressed: _delete,
              ),
          ],
        ),
      ),
    );
  }
}
