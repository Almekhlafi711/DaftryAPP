// =============================================================================
// الشاشة 13: إضافة دين جديد / تعديله (UC-07).
// - الاتجاه بلونين واضحين: «لي» (أخضر) و«عليّ» (أحمر).
// - الشخص والمبلغ والتاريخ والاستحقاق.
// - السؤال المحوري «هل خرج/دخل المبلغ من حساب؟»: إن فُعّل يُختار الحساب
//   ويتحرك رصيده دون احتسابه مصروفاً/دخلاً، وإن أُطفئ (بيع بالآجل)
//   يُسجَّل الدين في الدفتر فقط.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/debt_models.dart';
import '../../../services/providers.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/inputs.dart';
import '../../widgets/labels.dart';
import 'contact_picker.dart';

class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({super.key, this.contactId, this.debtId});

  /// شخص محدد مسبقاً (عند الفتح من ملف الشخص).
  final int? contactId;

  /// إن وُجد فالشاشة في وضع التعديل.
  final int? debtId;

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  DebtDirection _direction = DebtDirection.owedToMe;
  Contact? _contact;
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime? _due;
  bool _useAccount = true;
  Account? _account;
  bool _remind = false;
  bool _saving = false;
  String? _amountError;
  Debt? _original;

  bool get _isEdit => widget.debtId != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final contacts = ref.read(contactServiceProvider);
    if (_isEdit) {
      final debt = await ref.read(debtServiceProvider).getDebt(widget.debtId!);
      if (debt == null || !mounted) return;
      final contact = await contacts.getById(debt.contactId);
      final account = debt.accountId == null
          ? null
          : await ref.read(accountServiceProvider).getById(debt.accountId!);
      if (!mounted) return;
      setState(() {
        _original = debt;
        _direction = debt.direction;
        _contact = contact;
        _amount.text = ref.read(moneyParserProvider).toEditable(debt.amount);
        _note.text = debt.note ?? '';
        _start = debt.startDate;
        _due = debt.dueDate;
        _useAccount = debt.accountId != null;
        _account = account;
        _remind = debt.remind;
      });
      return;
    }
    if (widget.contactId != null) {
      final contact = await contacts.getById(widget.contactId!);
      if (mounted) setState(() => _contact = contact);
    }
    final account = await ref.read(accountServiceProvider).getDefault();
    if (mounted) setState(() => _account = account);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final minor = ref.read(moneyParserProvider).parse(_amount.text);
    if (minor == null || minor <= 0) {
      setState(() => _amountError = l10n.errInvalidAmount);
      return;
    }
    if (_contact == null) {
      showMessage(context, l10n.choosePerson, error: true);
      return;
    }
    if (_remind && _due != null) {
      await ref.read(notificationServiceProvider).requestPermission();
    }
    final draft = DebtDraft(
      contactId: _contact!.id,
      direction: _direction,
      amount: minor,
      startDate: _start,
      dueDate: _due,
      accountId: _useAccount ? _account?.id : null,
      note: _note.text,
      remind: _remind && _due != null,
    );
    setState(() => _saving = true);
    final money = ref.read(moneyFormatterProvider);
    try {
      final service = ref.read(debtServiceProvider);
      if (_isEdit) {
        await service.updateDebt(widget.debtId!, draft);
      } else {
        await service.createDebt(draft);
      }
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        context.pop();
        messenger.showSnackBar(SnackBar(content: Text(l10n.saved)));
      }
    } on Object catch (e) {
      if (mounted) showError(context, e, formatAmount: (m) => money.inline(m));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    if (!await confirmAction(
      context,
      title: l10n.deleteDebt,
      message: l10n.deleteDebtBody,
      confirmLabel: l10n.delete,
    )) {
      return;
    }
    await ref.read(debtServiceProvider).deleteDebt(widget.debtId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final dates = DateLabels(ref.watch(localeProvider).languageCode);
    final owedToMe = _direction == DebtDirection.owedToMe;
    // لا يتغير الاتجاه بعد وجود دفعات.
    final directionLocked = (_original?.paidAmount ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(_isEdit ? l10n.editDebt : l10n.newDebt),
        actions: [
          if (_isEdit)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: c.expense),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Insets.screen),
          children: [
            Row(
              children: [
                for (final d in DebtDirection.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: _DirectionCard(
                        title: l10n.directionName(d),
                        subtitle: d == DebtDirection.owedToMe
                            ? l10n.directionOwedToMeHint
                            : l10n.directionIOweHint,
                        color: d == DebtDirection.owedToMe
                            ? c.income
                            : c.expense,
                        selected: _direction == d,
                        onTap: directionLocked
                            ? null
                            : () => setState(() => _direction = d),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.md),
            PickerTile(
              icon: Icons.person_outline_rounded,
              title: _contact?.name ?? l10n.choosePerson,
              subtitle: _contact?.phone ?? l10n.person,
              onTap: () async {
                final picked = await pickContact(context, ref);
                if (picked != null) setState(() => _contact = picked);
              },
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: l10n.amount,
                errorText: _amountError,
                suffixText: ref.watch(moneyFormatterProvider).symbol,
              ),
              onChanged: (_) => setState(() => _amountError = null),
            ),
            const SizedBox(height: Insets.sm),
            Row(
              children: [
                Expanded(
                  child: PickerTile(
                    icon: Icons.calendar_today_outlined,
                    title: dates.full(_start),
                    subtitle: l10n.date,
                    onTap: () async {
                      final d = await pickDate(context, initial: _start);
                      if (d != null) setState(() => _start = d);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PickerTile(
                    icon: Icons.event_outlined,
                    title: _due == null ? '—' : dates.full(_due!),
                    subtitle: l10n.dueDateOptional,
                    onTap: () async {
                      final d = await pickDate(
                        context,
                        initial: _due ?? _start.add(const Duration(days: 30)),
                        first: _start,
                      );
                      setState(() => _due = d);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            // السؤال المحوري: هل تحرك المال فعلاً؟
            AppCard(
              color: _useAccount ? c.primary.withValues(alpha: 0.05) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              owedToMe
                                  ? l10n.moneyLeftAccount
                                  : l10n.moneyEnteredAccount,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              l10n.bookOnlyHint,
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useAccount,
                        onChanged: (v) => setState(() => _useAccount = v),
                      ),
                    ],
                  ),
                  if (_useAccount) ...[
                    const SizedBox(height: 8),
                    PickerTile(
                      icon: _account == null
                          ? Icons.account_balance_wallet_outlined
                          : AppIcons.account(_account!.type),
                      title: _account?.name ?? '—',
                      subtitle: owedToMe
                          ? l10n.decreasesBalanceNotExpense
                          : l10n.increasesBalanceNotIncome,
                      onTap: () async {
                        final picked = await pickAccount(
                          context,
                          selectedId: _account?.id,
                        );
                        if (picked != null) setState(() => _account = picked);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Insets.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                title: Text(l10n.remindBeforeDue),
                value: _remind && _due != null,
                onChanged: _due == null
                    ? null
                    : (v) => setState(() => _remind = v),
              ),
            ),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                hintText: '${l10n.note} (${l10n.optional})',
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: Insets.xl),
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.saveDebt),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionCard extends StatelessWidget {
  const _DirectionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? color.withValues(alpha: 0.1) : context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.button),
      side: BorderSide(
        color: selected ? color : context.colors.border,
        width: selected ? 2 : 1,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(Radii.button),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: selected ? color : context.colors.textSecondary,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
