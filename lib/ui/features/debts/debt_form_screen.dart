// =============================================================================
// الشاشة 13: إضافة دين جديد / تعديله (UC-07).
// - الاتجاه: «لي (عند شخص)» أخضر و«عليّ (لشخص)» أحمر.
// - الشخص: عند الدخول من ملف شخص يكون محدداً ومقفلاً، ورابط «جهات الاتصال»
//   للاختيار من الجهاز. ثم المبلغ والاستحقاق جنباً إلى جنب.
// - «مصدر الدين» بدل سؤال «هل خرج المبلغ من حساب؟» (وثيقة الديون 1.1):
//     لي:  أقرضته من حساب | بعتُ له بالآجل | دين سابق
//     عليّ: اقترضتُ إلى حساب | اشتريتُ بالآجل | دين سابق
//   الإقراض يحتاج حساباً، والبيع/الشراء بالآجل يحتاج فئة دخل/مصروف، ويظهر
//   كل منهما داخل الخيار نفسه عند اختياره.
// - مع وجود دفعات أو مسامحة: الاتجاه والمصدر والشخص مقفلة.
// - زر الحفظ يتعطل فور الضغط (منع الحفظ المكرر).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../data/seed/default_categories.dart';
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
import 'debt_actions.dart';

class DebtFormScreen extends ConsumerStatefulWidget {
  const DebtFormScreen({super.key, this.contactId, this.debtId});

  /// شخص محدد ومقفل (عند الفتح من ملف الشخص).
  final int? contactId;

  /// إن وُجد فالشاشة في وضع التعديل.
  final int? debtId;

  @override
  ConsumerState<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends ConsumerState<DebtFormScreen> {
  DebtDirection _direction = DebtDirection.owedToMe;
  DebtSource _source = DebtSource.loan;
  Contact? _contact;
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime? _due;
  Account? _account;
  Category? _saleCategory;
  Category? _purchaseCategory;
  bool _remind = false;
  bool _saving = false;
  String? _amountError;
  DebtView? _original;

  bool get _isEdit => widget.debtId != null;

  /// عليه دفعات أو مسامحة: الاتجاه والمصدر والشخص مقفلة.
  bool get _locked => _original?.hasMovements ?? false;

  bool get _personLocked => widget.contactId != null || _locked;

  Category? get _category => _source == DebtSource.creditSale
      ? _saleCategory
      : _source == DebtSource.creditPurchase
      ? _purchaseCategory
      : null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final contacts = ref.read(contactServiceProvider);
    final categories = ref.read(categoryServiceProvider);
    final accounts = ref.read(accountServiceProvider);
    // الفئات المقترحة: «مبيعات» للبيع بالآجل و«تسوق» للشراء بالآجل.
    final sale = await categories.bySystemKey(SystemCategoryKeys.sales);
    final purchase = await categories.bySystemKey(SystemCategoryKeys.shopping);
    if (!mounted) return;
    setState(() {
      _saleCategory = sale;
      _purchaseCategory = purchase;
    });

    if (_isEdit) {
      final view = await ref.read(debtServiceProvider).debtView(widget.debtId!);
      if (view == null || !mounted) return;
      final debt = view.debt;
      final contact = await contacts.getById(debt.contactId);
      final account = debt.accountId == null
          ? null
          : await accounts.getById(debt.accountId!);
      final category = view.categoryId == null
          ? null
          : await categories.getById(view.categoryId!);
      if (!mounted) return;
      setState(() {
        _original = view;
        _direction = debt.direction;
        _source = debt.source;
        _contact = contact;
        _amount.text = ref.read(moneyParserProvider).toEditable(debt.amount);
        _note.text = debt.note ?? '';
        _start = debt.startDate;
        _due = debt.dueDate;
        _account = account;
        if (debt.source == DebtSource.creditSale) _saleCategory = category;
        if (debt.source == DebtSource.creditPurchase) {
          _purchaseCategory = category;
        }
        _remind = debt.remind;
      });
      if (_account == null) {
        final fallback = await accounts.getDefault();
        if (mounted) setState(() => _account = fallback);
      }
      return;
    }
    if (widget.contactId != null) {
      final contact = await contacts.getById(widget.contactId!);
      if (mounted) setState(() => _contact = contact);
    }
    final account = await accounts.getDefault();
    if (mounted) setState(() => _account = account);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _setDirection(DebtDirection d) => setState(() {
    _direction = d;
    // البيع بالآجل «لي» فقط والشراء بالآجل «عليّ» فقط.
    if (!_source.allows(d)) {
      _source = d == DebtDirection.owedToMe
          ? DebtSource.creditSale
          : DebtSource.creditPurchase;
    }
  });

  Future<void> _save() async {
    if (_saving) return;
    // يتعطل الزر فوراً قبل أي انتظار (منع الحفظ المكرر).
    setState(() => _saving = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final minor = ref.read(moneyParserProvider).parse(_amount.text);
    if (minor == null || minor <= 0) {
      setState(() {
        _amountError = l10n.errInvalidAmount;
        _saving = false;
      });
      return;
    }
    if (_contact == null) {
      showMessage(context, l10n.choosePerson, error: true);
      setState(() => _saving = false);
      return;
    }
    if (_remind && _due != null) {
      await ref.read(notificationServiceProvider).requestPermission();
    }
    final draft = DebtDraft(
      contactId: _contact!.id,
      direction: _direction,
      source: _source,
      amount: minor,
      startDate: _start,
      dueDate: _due,
      accountId: _source.needsAccount ? _account?.id : null,
      categoryId: _category?.id,
      note: _note.text,
      remind: _remind && _due != null,
    );
    final money = ref.read(moneyFormatterProvider);
    try {
      final service = ref.read(debtServiceProvider);
      if (_isEdit) {
        await service.updateDebt(widget.debtId!, draft);
      } else {
        await service.createDebt(draft);
      }
      if (!mounted) return;
      context.pop();
      final warned = await warnIfCashNegative(
        messenger,
        ref,
        draft.accountId,
        message: l10n.negativeCashWarning,
      );
      if (!warned) messenger.showSnackBar(SnackBar(content: Text(l10n.saved)));
    } on Object catch (e) {
      if (mounted) {
        showError(context, e, formatAmount: (m) => money.inline(m));
        setState(() => _saving = false);
      }
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
    try {
      await ref.read(debtServiceProvider).deleteDebt(widget.debtId!);
      if (mounted) context.pop();
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _pickPerson() async {
    final picked = await pickContact(context, ref);
    if (picked != null) setState(() => _contact = picked);
  }

  Future<void> _pickCategory() async {
    final picked = await pickCategory(
      context,
      kind: _source == DebtSource.creditSale
          ? CategoryKind.income
          : CategoryKind.expense,
      selectedId: _category?.id,
    );
    if (picked == null) return;
    setState(() {
      if (_source == DebtSource.creditSale) {
        _saleCategory = picked;
      } else {
        _purchaseCategory = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final dates = ref.watch(dateLabelsProvider);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(_isEdit ? l10n.editDebt : l10n.newDebt),
        actions: [
          // الحذف فقط لخطأ إدخال: لا دفعات ولا مسامحة.
          if (_isEdit && _original != null && !_locked)
            IconButton(
              tooltip: l10n.deleteDebt,
              icon: Icon(Icons.delete_outline_rounded, color: c.expense),
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Insets.screen),
                children: [
                  // الاتجاه: لي (عند شخص) / عليّ (لشخص).
                  IgnorePointer(
                    ignoring: _locked,
                    child: SegmentedTabs<DebtDirection>(
                      values: DebtDirection.values,
                      selected: _direction,
                      label: (d) => d == DebtDirection.owedToMe
                          ? l10n.segOwedToMe
                          : l10n.segIOwe,
                      colorOf: (d) =>
                          d == DebtDirection.owedToMe ? c.income : c.expense,
                      onChanged: _setDirection,
                    ),
                  ),
                  if (_locked) ...[
                    const SizedBox(height: Insets.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: c.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.debtLockedHint,
                            style: TextStyle(fontSize: 12, color: c.warning),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: Insets.md),
                  // الشخص (يُقترح الموجود لمنع التكرار) مع رابط «جهات الاتصال».
                  AppCard(
                    onTap: _personLocked ? null : _pickPerson,
                    padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                    child: Row(
                      children: [
                        Icon(
                          _personLocked
                              ? Icons.lock_person_outlined
                              : Icons.person_outline_rounded,
                          color: c.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.person,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textSecondary,
                                ),
                              ),
                              Text(
                                _contact?.name ?? l10n.choosePerson,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: _contact == null
                                      ? c.textSecondary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_personLocked)
                          TextButton(
                            onPressed: () async {
                              final picked = await pickDeviceContact(
                                context,
                                ref,
                              );
                              if (picked != null) {
                                setState(() => _contact = picked);
                              }
                            },
                            child: Text(l10n.deviceContacts),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.sm),
                  // المبلغ بعملة التطبيق والاستحقاق جنباً إلى جنب.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.amount,
                            errorText: _amountError,
                            suffixText: ref
                                .watch(moneyFormatterProvider)
                                .symbol,
                          ),
                          onChanged: (_) => setState(() => _amountError = null),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          onTap: () async {
                            // القاعدة 4: الاستحقاق ≥ تاريخ الدين.
                            final d = await pickDate(
                              context,
                              initial:
                                  _due ?? _start.add(const Duration(days: 30)),
                              first: DateTime(
                                _start.year,
                                _start.month,
                                _start.day,
                              ),
                            );
                            setState(() => _due = d);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.dueDateOptional,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _due == null ? '—' : dates.day(_due!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.md),
                  Text(
                    l10n.sourceTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // مصدر الدين يحدد القيد المحاسبي؛ الحساب أو الفئة داخل الخيار.
                  for (final s in DebtSource.forDirection(_direction))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SourceOption(
                        title: l10n.debtSourceOption(s, _direction),
                        hint: l10n.debtSourceHint(
                          s,
                          _direction,
                          category: s == DebtSource.creditSale
                              ? _saleCategory?.name
                              : _purchaseCategory?.name,
                        ),
                        selected: _source == s,
                        onTap: _locked
                            ? null
                            : () => setState(() => _source = s),
                        child: _source != s
                            ? null
                            : s.needsAccount
                            ? _ChoiceChipButton(
                                icon: _account == null
                                    ? Icons.account_balance_wallet_outlined
                                    : AppIcons.account(_account!.type),
                                label:
                                    _account?.name ?? l10n.errAccountRequired,
                                onTap: () async {
                                  final picked = await pickAccount(
                                    context,
                                    selectedId: _account?.id,
                                  );
                                  if (picked != null) {
                                    setState(() => _account = picked);
                                  }
                                },
                              )
                            : s.needsCategory
                            ? _ChoiceChipButton(
                                icon: _category == null
                                    ? Icons.sell_outlined
                                    : AppIcons.category(_category!.icon),
                                label:
                                    _category?.name ?? l10n.errCategoryRequired,
                                onTap: _pickCategory,
                              )
                            : null,
                      ),
                    ),
                  const SizedBox(height: Insets.xs),
                  PickerTile(
                    icon: Icons.calendar_today_outlined,
                    title: dates.full(_start),
                    subtitle: l10n.date,
                    onTap: () async {
                      // القاعدة 3: تاريخ الدين ≤ اليوم.
                      final d = await pickDate(
                        context,
                        initial: _start.isAfter(today) ? today : _start,
                        last: today,
                      );
                      if (d == null) return;
                      setState(() {
                        _start = d;
                        if (_due != null && _due!.isBefore(d)) _due = null;
                      });
                    },
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
                ],
              ),
            ),
            // زر الحفظ ثابت أسفل الشاشة (الحفظ ذري: الدين وقيده معاً).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.screen,
                Insets.sm,
                Insets.screen,
                Insets.screen,
              ),
              child: FilledButton.icon(
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(l10n.saveDebt),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// خيار «مصدر الدين» مع أثره المحاسبي تحته، وما يلزمه (الحساب أو الفئة)
/// داخله عند اختياره.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
    this.child,
  });

  final String title;
  final String hint;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primary.withValues(alpha: 0.07) : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(
          color: selected ? c.primary : c.border,
          width: selected ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? c.primary : c.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      hint,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                    if (child != null) ...[const SizedBox(height: 8), child!],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر صغير بشكل قائمة منسدلة (الحساب أو الفئة) داخل خيار المصدر.
class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: StadiumBorder(side: BorderSide(color: c.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down_rounded, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
