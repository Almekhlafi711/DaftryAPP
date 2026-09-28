// =============================================================================
// الشاشة 14: تسجيل دفعة سداد (UC-08) — نافذة سفلية.
// تُظهر المتبقي، ومبلغ الدفعة مع زر «كامل المتبقي»، وحساب الاستلام المقترح
// (حساب إنشاء الدين، أو الافتراضي إن كان مؤرشفاً) مع توضيح أنه ليس دخلاً.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

Future<void> showPaymentSheet(
  BuildContext context, {
  required PersonProfile profile,
  int? debtId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _PaymentSheet(profile: profile, initialDebtId: debtId),
);

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.profile, this.initialDebtId});

  final PersonProfile profile;
  final int? initialDebtId;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late List<Debt> _open;
  late Debt _debt;
  final _amount = TextEditingController();
  bool _useAccount = true;
  Account? _account;
  DateTime _date = DateTime.now();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // الديون المفتوحة من الأقدم للأحدث (نسدد الأقدم أولاً افتراضياً).
    _open = widget.profile.openDebts
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    _debt = _open.firstWhere(
      (d) => d.id == widget.initialDebtId,
      orElse: () => _open.first,
    );
    _loadSuggestion();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestion() async {
    final account = await ref
        .read(debtServiceProvider)
        .suggestPaymentAccount(_debt.id);
    if (mounted) setState(() => _account = account);
  }

  int get _remaining => _debt.amount - _debt.paidAmount;

  Future<void> _save() async {
    final minor = ref.read(moneyParserProvider).parse(_amount.text);
    final l10n = context.l10n;
    final money = ref.read(moneyFormatterProvider);
    if (minor == null || minor <= 0) {
      setState(() => _error = l10n.errInvalidAmount);
      return;
    }
    if (minor > _remaining) {
      // 4أ: المبلغ أكبر من المتبقي.
      setState(() => _error = l10n.errPaymentExceeds(money.inline(_remaining)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(debtServiceProvider)
          .recordPayment(
            _debt.id,
            PaymentDraft(
              amount: minor,
              paidAt: _date,
              accountId: _useAccount ? _account?.id : null,
            ),
          );
      if (mounted) Navigator.pop(context);
    } on Object catch (e) {
      if (mounted) showError(context, e, formatAmount: (m) => money.inline(m));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final money = ref.watch(moneyFormatterProvider);
    final dates = ref.watch(dateLabelsProvider);
    final owedToMe = _debt.direction == DebtDirection.owedToMe;

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
            Text(
              l10n.paymentFor(widget.profile.contact.name),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.remainingAmount(money.inline(_remaining)),
              style: TextStyle(color: owedToMe ? c.income : c.expense),
            ),
            // اختيار الدين إن وُجد أكثر من دين مفتوح.
            if (_open.length > 1) ...[
              const SizedBox(height: Insets.md),
              Text(l10n.whichDebt, style: TextStyle(color: c.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final d in _open)
                    ChoiceChip(
                      label: Text(
                        '${d.note ?? dates.day(d.startDate)} · '
                        '${money.format(d.amount - d.paidAmount, compact: true)}',
                      ),
                      selected: d.id == _debt.id,
                      labelStyle: TextStyle(
                        color: d.id == _debt.id ? Colors.white : c.textPrimary,
                      ),
                      onSelected: (_) {
                        setState(() => _debt = d);
                        _loadSuggestion();
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: Insets.md),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: l10n.paymentAmount,
                errorText: _error,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6),
                  child: TextButton(
                    onPressed: () => setState(() {
                      _amount.text = ref
                          .read(moneyParserProvider)
                          .toEditable(_remaining);
                      _error = null;
                    }),
                    child: Text(l10n.fullRemaining),
                  ),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: Insets.md),
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          owedToMe
                              ? l10n.receivedIntoAccount
                              : l10n.paidFromAccount,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Switch(
                        value: _useAccount,
                        onChanged: (v) => setState(() => _useAccount = v),
                      ),
                    ],
                  ),
                  if (_useAccount && _account != null) ...[
                    const SizedBox(height: 6),
                    PickerTile(
                      icon: AppIcons.account(_account!.type),
                      title: _account!.name,
                      subtitle: _account!.id == _debt.accountId
                          ? l10n.suggestedCreationAccount
                          : l10n.account,
                      onTap: () async {
                        final picked = await pickAccount(
                          context,
                          selectedId: _account!.id,
                        );
                        if (picked != null) setState(() => _account = picked);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      owedToMe
                          ? l10n.increasesBalanceNotIncome
                          : l10n.decreasesBalanceNotExpense,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Insets.sm),
            PickerTile(
              icon: Icons.calendar_today_outlined,
              title: dates.relativeDay(_date, l10n),
              subtitle: l10n.date,
              onTap: () async {
                final d = await pickDate(context, initial: _date);
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: Insets.lg),
            FilledButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.savePayment),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
