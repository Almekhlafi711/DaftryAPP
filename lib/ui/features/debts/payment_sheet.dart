// =============================================================================
// الشاشة 14: «استلام مبلغ» (لي) أو «سداد مبلغ» (عليّ) — نافذة سفلية (UC-08).
//
// - لا يُسأل عن الدين: المبلغ يُوزَّع تلقائياً على ديون الشخص المفتوحة في
//   نفس الاتجاه، الأقدم أولاً، مع معاينة التوزيع لكل دين (يُغلق ✓ / يتبقى)
//   وسطر «المتبقي بعد الاستلام»
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

  /// الكتابة الفعلية جارية (يظهر المؤشر الدوّار) — وليس أثناء انتظار تأكيد.
  bool _writing = false;

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
    if (mounted) setState(() => _writing = true);
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
        setState(() => _saving = _writing = false);
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
    final allocations = {
      for (final a in DebtService.allocate([
        for (final d in _scope) (debtId: d.id, remaining: d.remaining),
      ], minor))
        a.debtId: a.amount,
    };
    final after = (_total - minor).clamp(0, _total);
    final excess = minor > _total;
    final today = DateTime.now();
    final bold = TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary);

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
            // العنوان والمتبقي الحالي.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _owedToMe ? l10n.receiveFrom(name) : l10n.payTo(name),
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        l10n.remainingAmount(money.inline(_total)),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            // المبلغ مع «كامل المتبقي».
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amount,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        labelText: _owedToMe
                            ? l10n.amountReceivedLabel
                            : l10n.amountPaidLabel,
                        hintText: '0',
                        errorText: _error,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: const StadiumBorder(),
                      side: BorderSide(color: c.border),
                      foregroundColor: c.textPrimary,
                    ),
                    onPressed: () => setState(() {
                      _amount.text = ref
                          .read(moneyParserProvider)
                          .toEditable(_total);
                      _error = null;
                    }),
                    child: Text(l10n.fullRemaining),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.sm),
            // معاينة التوزيع: لكل دين كم يأخذ، وهل يُغلق أو كم يتبقى منه.
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              decoration: BoxDecoration(
                color: c.surfaceMuted.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _specific ? l10n.selectedDebtTitle : l10n.autoDistTitle,
                    style: bold,
                  ),
                  const SizedBox(height: 6),
                  for (final d in _scope)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${debtLabel(context, d)} • '
                              '${dates.day(d.debt.startDate)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (allocations[d.id] case final part?) ...[
                            Text(
                              money.format(part, compact: true),
                              style: bold.copyWith(fontSize: 13),
                            ),
                            Text(
                              ' ← ',
                              style: TextStyle(color: c.textSecondary),
                            ),
                            if (part >= d.remaining)
                              Text(
                                '${l10n.allocCloses} ✓',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: c.income,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              Text(
                                l10n.allocLeaves(
                                  money.format(
                                    d.remaining - part,
                                    compact: true,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: c.textSecondary,
                                ),
                              ),
                          ] else
                            Text(
                              money.format(d.remaining, compact: true),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: c.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_open.length > 1)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: () {
                          setState(() => _specific = !_specific);
                          _loadSuggestion();
                        },
                        child: Text(
                          _specific
                              ? l10n.autoDistribute
                              : l10n.chooseSpecificDebt,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                  if (_specific && _open.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Wrap(
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
                                color: d.id == _debtId
                                    ? Colors.white
                                    : c.textPrimary,
                              ),
                              onSelected: (_) {
                                setState(() => _debtId = d.id);
                                _loadSuggestion();
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Insets.sm),
            // الحساب المقترح: الاستلام يزيد الرصيد وليس دخلاً.
            PickerTile(
              icon: _account == null
                  ? Icons.account_balance_wallet_outlined
                  : AppIcons.account(_account!.type),
              title: _account?.name ?? l10n.errAccountRequired,
              subtitle: _owedToMe
                  ? '${l10n.receivedIntoAccount} '
                        '(${l10n.increasesBalanceNotIncome})'
                  : '${l10n.paidFromAccount} '
                        '(${l10n.decreasesBalanceNotExpense})',
              onTap: () async {
                final picked = await pickAccount(
                  context,
                  selectedId: _account?.id,
                );
                if (picked != null) setState(() => _account = picked);
              },
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
            const SizedBox(height: Insets.sm),
            // «المتبقي بعد العملية» بدل شاشة مراجعة منفصلة.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.tint(excess ? c.warning : c.income),
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      excess
                          ? l10n.excessTitle
                          : _owedToMe
                          ? l10n.remainingAfterReceive
                          : l10n.remainingAfterPay,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: excess ? c.warning : c.income,
                      ),
                    ),
                  ),
                  if (!excess)
                    AmountText(
                      after,
                      color: c.income,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Insets.md),
            // يتعطل فور الضغط لمنع الحفظ المكرر.
            FilledButton.icon(
              icon: _writing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(l10n.save),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
