// =============================================================================
// الشاشة 8: الحسابات — والشاشة 9: أرشفة حساب له رصيد.
//
// - إجمالي الحسابات النشطة، ثم الحسابات مع شارة «افتراضي».
// - لا يوجد خيار حذف؛ قائمة كل حساب: تعديل، تعيين كافتراضي، تسوية، أرشفة.
// - المؤرشفة في قسم مستقل باهت مع زر «رفع الأرشفة».
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/enums.dart';
import '../../../services/providers.dart';
import '../../state/app_state.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/inputs.dart';
import '../../widgets/labels.dart';

final _archivedAccountsProvider = StreamProvider.autoDispose<List<Account>>(
  (ref) => ref.watch(accountServiceProvider).watchArchived(),
);

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final active = ref.watch(activeAccountsProvider).value ?? const <Account>[];
    final archived =
        ref.watch(_archivedAccountsProvider).value ?? const <Account>[];
    final total = ref.watch(totalBalanceProvider).value ?? 0;
    final dates = DateLabels(ref.watch(localeProvider).languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsTitle),
        actions: [
          IconButton.filled(
            tooltip: l10n.addAccount,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showAccountForm(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.screen),
        children: [
          AppCard(
            color: c.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalActiveAccounts,
                  style: const TextStyle(color: Colors.white70),
                ),
                AmountText(
                  total,
                  color: Colors.white,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SectionTitle(l10n.activeAccountsCount('${active.length}')),
          for (final a in active)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AccountTile(account: a),
            ),
          if (archived.isNotEmpty) ...[
            SectionTitle(l10n.archivedAccountsCount('${archived.length}')),
            for (final a in archived)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Opacity(
                  opacity: 0.6,
                  child: AppCard(
                    child: Row(
                      children: [
                        IconBadge(icon: AppIcons.archive, color: c.archive),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (a.archivedAt != null)
                                Text(
                                  l10n.archivedSince(dates.full(a.archivedAt!)),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        AmountText(
                          a.balance,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () =>
                              ref.read(accountServiceProvider).unarchive(a.id),
                          child: Text(l10n.unarchive),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final color = account.color != null ? Color(account.color!) : c.primary;

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } on Object catch (e) {
        if (context.mounted) showError(context, e);
      }
    }

    return AppCard(
      onTap: () => showAccountForm(context, account: account),
      child: Row(
        children: [
          IconBadge(icon: AppIcons.account(account.type), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (account.isDefault)
                      Pill(l10n.defaultBadge, color: c.income),
                  ],
                ),
                Text(
                  l10n.accountTypeName(account.type),
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
              ],
            ),
          ),
          AmountText(
            account.balance,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          // لا يوجد «حذف»: تعديل، افتراضي، تسوية، أرشفة فقط.
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: c.textSecondary),
            onSelected: (v) => switch (v) {
              'edit' => showAccountForm(context, account: account),
              'default' => run(
                () => ref.read(accountServiceProvider).setDefault(account.id),
              ),
              'adjust' => showAdjustBalance(context, account),
              _ => showArchiveSheet(context, account),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              if (!account.isDefault)
                PopupMenuItem(value: 'default', child: Text(l10n.setAsDefault)),
              PopupMenuItem(value: 'adjust', child: Text(l10n.adjustBalance)),
              PopupMenuItem(
                value: 'archive',
                child: Text(l10n.archive, style: TextStyle(color: c.archive)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// إضافة / تعديل حساب
// -----------------------------------------------------------------------------

Future<void> showAccountForm(BuildContext context, {Account? account}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AccountForm(account: account),
    );

class _AccountForm extends ConsumerStatefulWidget {
  const _AccountForm({this.account});

  final Account? account;

  @override
  ConsumerState<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<_AccountForm> {
  late final _name = TextEditingController(text: widget.account?.name);
  final _opening = TextEditingController();
  late AccountType _type = widget.account?.type ?? AccountType.bank;
  late int? _color = widget.account?.color;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final service = ref.read(accountServiceProvider);
    try {
      if (widget.account == null) {
        await service.create(
          name: _name.text,
          type: _type,
          openingBalance:
              ref.read(moneyParserProvider).parse(_opening.text) ?? 0,
          color: _color,
        );
      } else {
        await service.update(
          widget.account!.id,
          name: _name.text,
          type: _type,
          color: _color,
        );
      }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.account == null ? l10n.addAccount : l10n.editAccount,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Insets.md),
          TextField(
            controller: _name,
            autofocus: widget.account == null,
            decoration: InputDecoration(labelText: l10n.accountName),
          ),
          const SizedBox(height: Insets.md),
          Text(l10n.accountType, style: TextStyle(color: c.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final t in AccountType.values)
                ChoiceChip(
                  avatar: Icon(AppIcons.account(t), size: 18),
                  label: Text(l10n.accountTypeName(t)),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                  labelStyle: TextStyle(
                    color: _type == t ? Colors.white : c.textPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in AppIcons.palette)
                GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Color(color),
                    child: _color == color
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          if (widget.account == null) ...[
            const SizedBox(height: Insets.md),
            TextField(
              controller: _opening,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.openingBalance,
                suffixText: ref.watch(moneyFormatterProvider).symbol,
              ),
            ),
          ],
          const SizedBox(height: Insets.lg),
          FilledButton(onPressed: _save, child: Text(l10n.save)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// تسوية الرصيد (FR-10)
// -----------------------------------------------------------------------------

Future<void> showAdjustBalance(BuildContext context, Account account) async {
  final controller = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final l10n = ctx.l10n;
        final money = ref.watch(moneyFormatterProvider);
        controller.text = controller.text.isEmpty
            ? ref.read(moneyParserProvider).toEditable(account.balance)
            : controller.text;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            Insets.screen,
            0,
            Insets.screen,
            MediaQuery.viewInsetsOf(ctx).bottom + Insets.screen,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${l10n.adjustBalance} — ${account.name}',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.adjustBalanceHint,
                style: TextStyle(color: ctx.colors.textSecondary),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.actualBalance,
                  suffixText: money.symbol,
                ),
              ),
              const SizedBox(height: Insets.lg),
              FilledButton(
                onPressed: () async {
                  final value = ref
                      .read(moneyParserProvider)
                      .parse(controller.text);
                  if (value == null) return;
                  try {
                    await ref
                        .read(accountServiceProvider)
                        .adjustBalance(account.id, value);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on Object catch (e) {
                    if (ctx.mounted) showError(ctx, e);
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        );
      },
    ),
  );
  controller.dispose();
}

// -----------------------------------------------------------------------------
// الشاشة 9: أرشفة حساب (UC-01b)
// -----------------------------------------------------------------------------

Future<void> showArchiveSheet(BuildContext context, Account account) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ArchiveSheet(account: account),
    );

class _ArchiveSheet extends ConsumerStatefulWidget {
  const _ArchiveSheet({required this.account});

  final Account account;

  @override
  ConsumerState<_ArchiveSheet> createState() => _ArchiveSheetState();
}

class _ArchiveSheetState extends ConsumerState<_ArchiveSheet> {
  int? _transferTo;
  int? _newDefault;

  Future<void> _archive({required bool transfer}) async {
    try {
      await ref
          .read(accountServiceProvider)
          .archive(
            widget.account.id,
            transferToId: transfer ? _transferTo : null,
            newDefaultId: _newDefault,
          );
      if (mounted) Navigator.pop(context);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final a = widget.account;
    final others =
        (ref.watch(activeAccountsProvider).value ?? const <Account>[])
            .where((x) => x.id != a.id)
            .toList();
    _transferTo ??= others.firstOrNull?.id;
    if (a.isDefault) _newDefault ??= others.firstOrNull?.id;
    final hasBalance = a.balance != 0;
    String nameOf(int? id) =>
        others.where((x) => x.id == id).firstOrNull?.name ?? '—';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Insets.xl, 0, Insets.xl, Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: IconBadge(
                icon: AppIcons.archive,
                color: c.archive,
                size: 56,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.archiveTitle(a.name),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.archiveBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            if (others.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.errCannotArchiveLast,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.expense),
              ),
            ] else ...[
              if (a.isDefault) ...[
                const SizedBox(height: 12),
                PickerTile(
                  icon: Icons.star_outline_rounded,
                  title: nameOf(_newDefault),
                  subtitle: l10n.newDefaultAccount,
                  onTap: () async {
                    final picked = await pickAccount(context, exclude: {a.id});
                    if (picked != null) setState(() => _newDefault = picked.id);
                  },
                ),
              ],
              if (hasBalance) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Radii.chip),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: c.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l10n.archiveHasBalance(
                                ref
                                    .watch(moneyFormatterProvider)
                                    .inline(a.balance),
                              ),
                              style: TextStyle(
                                color: c.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      PickerTile(
                        icon: Icons.swap_horiz_rounded,
                        title: nameOf(_transferTo),
                        subtitle: l10n.transferBalanceTo,
                        onTap: () async {
                          final picked = await pickAccount(
                            context,
                            exclude: {a.id},
                          );
                          if (picked != null) {
                            setState(() => _transferTo = picked.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: c.archive),
                  onPressed: () => _archive(transfer: true),
                  child: Text(l10n.transferAndArchive),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _archive(transfer: false),
                  child: Text(l10n.archiveWithoutTransfer),
                ),
              ] else ...[
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: c.archive),
                  onPressed: () => _archive(transfer: false),
                  child: Text(l10n.archive),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
