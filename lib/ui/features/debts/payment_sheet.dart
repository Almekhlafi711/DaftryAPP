// =============================================================================
// الشاشة 14: «استلام مبلغ» (لي) أو «سداد مبلغ» (عليّ) — نافذة سفلية (UC-08).
//
// - لا يُسأل عن الدين: المبلغ يُوزَّع تلقائياً على ديون الشخص المفتوحة في
//   نفس الاتجاه، الأقدم أولاً، مع معاينة التوزيع وسطر «المتبقي بعد الدفعة»
//   بدل شاشة مراجعة منفصلة. ويبقى خيار صغير «اختيار دين معيّن».
// - الزائد عن المتبقي لا يُرفض بصمت: يُعرض تسجيله ديناً معاكساً.
// - حساب الاستلام/الدفع المقترح: حساب إقراض أقدم دين، أو الافتراضي.
// - زر الحفظ يتعطل فور الضغط (منع الحفظ المكرر).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/debt_models.dart';
import '../../../services/debt_service.dart';
import '../../../services/providers.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/inputs.dart';
import '../../widgets/labels.dart';
import 'debt_actions.dart';

Future<void> showPaymentSheet(
  BuildContext context, {
  required PersonProfile profile,
  required DebtDirection direction,
  int? debtId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _PaymentSheet(
    profile: profile,
    direction: direction,
    initialDebtId: debtId,
  ),
);

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({
    required this.profile,
    required this.direction,
    this.initialDebtId,
  });

  final PersonProfile profile;
  final DebtDirection direction;
  final int? initialDebtId;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late final List<DebtView> _open = widget.profile.openDebts(widget.direction);
  late bool _specific = widget.initialDebtId != null;
  late int _debtId = widget.initialDebtId ?? _open.first.id;
  final _amount = TextEditingController();
  Account? _account;
  DateTime _date = DateTime.now();
  String? _error;
  bool _saving = false;

  bool get _owedToMe => widget.direction == DebtDirection.owedToMe;

  /// الديون التي يُوزَّع عليها المبلغ.
  List<DebtView> get _scope =>
      _specific ? _open.where((d) => d.id == _debtId).toList() : _open;

  int get _total => _scope.fold(0, (s, d) => s + d.remaining);

  int? get _minor => ref.read(moneyParserProvider).parse(_amount.text);

  @override
  void initState() {
    super.initState();
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
        .suggestPaymentAccount(
          widget.profile.contact.id,
          widget.direction,
          debtId: _specific ? _debtId : null,
        );
    if (mounted) setState(() => _account = account);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = context.l10n;
    final money = ref.read(moneyFormatterProvider);
    final messenger = ScaffoldMessenger.of(context);
    final minor = _minor;
    void fail(String message) => setState(() {
      _error = message;
      _saving = false;
    });
    if (minor == null || minor <= 0) return fail(l10n.errInvalidAmount);
    if (_account == null) return fail(l10n.errAccountRequired);

    // الزائد عن المتبقي: يُعرض تسجيله ديناً معاكساً بدل الرفض الصامت.
    final excess = minor - _total;
    if (excess > 0) {
      final name = widget.profile.contact.name;
      final record = await confirmAction(
        context,
        title: l10n.excessTitle,
        message: _owedToMe
            ? l10n.excessOwedToMe(money.inline(excess), name)
            : l10n.excessIOwe(money.inline(excess), name),
        confirmLabel: l10n.recordExcess,
        destructive: false,
        icon: Icons.swap_vert_rounded,
      );
      if (!record) {
        if (mounted) setState(() => _saving = false);
        return;
      }
    }
    try {
      await ref
          .read(debtServiceProvider)
          .recordPayment(
            PaymentDraft(
              contactId: widget.profile.contact.id,
              direction: widget.direction,
              amount: minor,
              paidAt: _date,
              accountId: _account!.id,
              debtId: _specific ? _debtId : null,
              excessNote: l10n.excessNote,
            ),
            excessAsOppositeDebt: excess > 0,
          );
      if (!mounted) return;
      Navigator.pop(context);
      final warned = await warnIfCashNegative(
        messenger,
        ref,
        _account!.id,
        message: l10n.negativeCashWarning,
      );
      if (!warned) messenger.showSnackBar(SnackBar(content: Text(l10n.saved)));
    } on Object catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showError(context, e, formatAmount: (m) => money.inline(m));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final money = ref.watch(moneyFormatterProvider);
    final dates = ref.watch(dateLabelsProvider);
    final color = _owedToMe ? c.income : c.expense;
    final name = widget.profile.contact.name;
    final minor = _minor ?? 0;
    final allocations = DebtService.allocate([
      for (final d in _scope) (debtId: d.id, remaining: d.remaining),
    ], minor);
    final after = (_total - minor).clamp(0, _total);
    String labelOf(int debtId) {
      final d = _open.firstWhere((x) => x.id == debtId);
      return debtLabel(context, d);
    }

    final today = DateTime.now();

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
              _owedToMe ? l10n.receiveFrom(name) : l10n.payTo(name),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.remainingAmount(money.inline(_total)),
              style: TextStyle(color: color),
            ),
            const SizedBox(height: Insets.md),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: l10n.amount,
                errorText: _error,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6),
                  child: TextButton(
                    onPressed: () => setState(() {
                      _amount.text = ref
                          .read(moneyParserProvider)
                          .toEditable(_total);
                      _error = null;
                    }),
                    child: Text(l10n.fullRemaining),
                  ),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 6),
            // سطر «المتبقي بعد الدفعة» بدل شاشة مراجعة منفصلة.
            Text(
              minor > _total
                  ? l10n.excessTitle
                  : l10n.remainingAfterPayment(money.inline(after)),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: minor > _total ? c.warning : c.textPrimary,
              ),
            ),
            if (allocations.length > 1)
              Text(
                l10n.distributedOldestFirst(
                  allocations
                      .map(
                        (a) =>
                            '${labelOf(a.debtId)} '
                            '${money.format(a.amount, compact: true)}',
                      )
                      .join(' • '),
                ),
                style: TextStyle(fontSize: 12, color: c.textSecondary),
              ),
            if (_open.length > 1) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  icon: Icon(
                    _specific
                        ? Icons.auto_mode_rounded
                        : Icons.checklist_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _specific ? l10n.autoDistribute : l10n.chooseSpecificDebt,
                  ),
                  onPressed: () {
                    setState(() => _specific = !_specific);
                    _loadSuggestion();
                  },
                ),
              ),
              if (_specific)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final d in _open)
                      ChoiceChip(
                        label: Text(
                          '${debtLabel(context, d)} · '
                          '${money.format(d.remaining, compact: true)}',
                        ),
                        selected: d.id == _debtId,
                        labelStyle: TextStyle(
                          color: d.id == _debtId ? Colors.white : c.textPrimary,
                        ),
                        onSelected: (_) {
                          setState(() => _debtId = d.id);
                          _loadSuggestion();
                        },
                      ),
                  ],
                ),
            ],
            const SizedBox(height: Insets.md),
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _owedToMe ? l10n.receivedIntoAccount : l10n.paidFromAccount,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  PickerTile(
                    icon: _account == null
                        ? Icons.account_balance_wallet_outlined
                        : AppIcons.account(_account!.type),
                    title: _account?.name ?? l10n.errAccountRequired,
                    subtitle: _owedToMe
                        ? l10n.increasesBalanceNotIncome
                        : l10n.decreasesBalanceNotExpense,
                    onTap: () async {
                      final picked = await pickAccount(
                        context,
                        selectedId: _account?.id,
                      );
                      if (picked != null) setState(() => _account = picked);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.sm),
            PickerTile(
              icon: Icons.calendar_today_outlined,
              title: dates.relativeDay(_date, l10n),
              subtitle: l10n.date,
              onTap: () async {
                // القاعدة 5: تاريخ الدفعة ≤ اليوم.
                final d = await pickDate(
                  context,
                  initial: _date.isAfter(today) ? today : _date,
                  last: today,
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: Insets.lg),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: color),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(l10n.settleAction(widget.direction)),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
