// =============================================================================
// الشاشتان 4 و 7: إضافة معاملة وتعديلها (UC-02 / UC-03).
//
// صُممت لهدف «10 ثوانٍ أو أقل»: النوع ← المبلغ (بعملة التطبيق دون حقل عملة)
// ← الفئة كأيقونات ← الحساب المقترح تلقائياً ← حفظ بضغطة واحدة.
// حقل الحساب وخيار التحويل لا يظهران إذا كان للمستخدم حساب نشط واحد (FR-05).
// =============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/transaction_models.dart';
import '../../../services/providers.dart';
import '../../router/routes.dart';
import '../../state/app_state.dart';
import '../../state/data_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/inputs.dart';
import '../../widgets/labels.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.initialType = TxType.expense,
    this.transactionId,
  });

  final TxType initialType;

  /// إن وُجد فالشاشة في وضع التعديل.
  final int? transactionId;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late TxType _type = widget.initialType;
  AmountInput _amount = AmountInput.empty;
  int? _categoryId;
  int? _accountId;
  int? _toAccountId;
  DateTime _date = DateTime.now();
  String? _receiptPath;
  final _note = TextEditingController();

  /// هل اختار المستخدم الحساب يدوياً؟ (حينها لا نستبدله بالاقتراح).
  bool _accountChosenManually = false;
  bool _suggested = false;
  bool _showAllCategories = false;
  bool _saving = false;
  bool _amountError = false;

  MoneyTransaction? _original;
  bool get _isEdit => widget.transactionId != null;
  bool get _isAdjustment => _original?.type == TxType.adjustment;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _load();
    } else {
      _suggestAccount();
    }
  }

  Future<void> _load() async {
    final tx = await ref
        .read(transactionServiceProvider)
        .getById(widget.transactionId!);
    if (tx == null || !mounted) return;
    if (tx.type.isDebtMovement) {
      // حماية: حركات الديون تُعدَّل من ملف الشخص.
      final debt = await ref.read(debtServiceProvider).getDebt(tx.debtId!);
      if (!mounted) return;
      context.pop();
      if (debt != null) context.push(AppRoutes.person(debt.contactId));
      return;
    }
    final parser = ref.read(moneyParserProvider);
    setState(() {
      _original = tx;
      _type = tx.type;
      _amount = AmountInput(parser.toEditable(tx.amount.abs()));
      _categoryId = tx.categoryId;
      _accountId = tx.accountId;
      _toAccountId = tx.toAccountId;
      _date = tx.date;
      _note.text = tx.note ?? '';
      _receiptPath = tx.receiptPath;
      _accountChosenManually = true;
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// FR-06: آخر حساب استُخدم للفئة، وإلا الحساب الافتراضي.
  Future<void> _suggestAccount() async {
    if (_accountChosenManually) return;
    final account = await ref
        .read(transactionServiceProvider)
        .suggestAccount(_categoryId);
    if (!mounted || account == null || _accountChosenManually) return;
    final prefs = ref.read(preferencesProvider).value;
    setState(() {
      _accountId = account.id;
      _suggested = account.id != prefs?.defaultAccountId;
    });
  }

  Future<void> _pickReceipt() async {
    final l10n = context.l10n;
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_receiptPath != null)
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _receiptImage(size: 40),
                ),
                title: Text(l10n.viewReceipt),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewReceipt();
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.receiptCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.receiptGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (_receiptPath != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: ctx.colors.expense),
                title: Text(l10n.removeReceipt),
                onTap: () {
                  setState(() => _receiptPath = null);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 70, // ضغط الصورة لتوفير المساحة
    );
    if (image == null) return;
    // ننسخ الصورة داخل مجلد التطبيق حتى لا تضيع إن حُذفت من المعرض.
    final dir = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, 'receipts'),
    );
    await dir.create(recursive: true);
    final dest = p.join(
      dir.path,
      'r_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(image.path).copy(dest);
    if (mounted) setState(() => _receiptPath = dest);
  }

  /// صورة الإيصال، أو أيقونة بديلة إن لم يعد الملف موجوداً
  /// (مثلاً بعد الاستعادة على جهاز آخر: النسخة تحمل البيانات دون الصور).
  Widget _receiptImage({double? size}) => Image.file(
    File(_receiptPath!),
    width: size,
    height: size,
    fit: size == null ? BoxFit.contain : BoxFit.cover,
    errorBuilder: (_, _, _) =>
        Icon(Icons.broken_image_outlined, size: size ?? 64, color: Colors.grey),
  );

  /// عرض الإيصال بملء الشاشة مع إمكانية التكبير بإصبعين.
  Future<void> _viewReceipt() => showDialog<void>(
    context: context,
    builder: (ctx) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(child: _receiptImage()),
            ),
          ),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _save(List<Account> activeAccounts) async {
    final l10n = context.l10n;
    final minor = _amount.toMinor(ref.read(moneyParserProvider));
    if (!_isAdjustment && (minor == null || minor <= 0)) {
      setState(() => _amountError = true);
      return;
    }
    if (!_isAdjustment && _type != TxType.transfer && _categoryId == null) {
      showMessage(context, l10n.chooseCategory, error: true);
      return;
    }
    final accountId = _accountId ?? activeAccounts.firstOrNull?.id;
    if (accountId == null) return;

    setState(() => _saving = true);
    final service = ref.read(transactionServiceProvider);
    final draft = TransactionDraft(
      type: _type,
      amount: _isAdjustment ? _original!.amount : minor!,
      accountId: accountId,
      toAccountId: _toAccountId,
      categoryId: _categoryId,
      date: _date,
      note: _note.text,
      receiptPath: _receiptPath,
    );
    try {
      final result = _isEdit
          ? await service.update(widget.transactionId!, draft)
          : await service.add(draft);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final alert = result.budgetAlert;
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            alert == null
                ? l10n.saved
                : alert.level == BudgetLevel.exceeded
                ? l10n.budgetExceeded(alert.categoryName, '${alert.percent}')
                : l10n.budgetWarning(alert.categoryName, '${alert.percent}'),
          ),
          // 6أ: تنبيه تجاوز الميزانية بعد الحفظ.
          backgroundColor: alert == null
              ? null
              : alert.level == BudgetLevel.exceeded
              ? context.colors.expense
              : context.colors.warning,
        ),
      );
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final tx = _original;
    if (tx == null) return;
    final money = ref.read(moneyFormatterProvider);
    final accounts = ref.read(allAccountsProvider).value ?? const [];
    final accountName =
        accounts.where((a) => a.id == tx.accountId).firstOrNull?.name ?? '';
    final ok = await confirmAction(
      context,
      title: l10n.deleteTransactionTitle,
      message: l10n.deleteTransactionBody(
        tx.note ?? l10n.txTypeName(tx.type),
        money.inline(tx.amount),
        accountName,
      ),
      confirmLabel: l10n.delete,
    );
    if (!ok || !mounted) return;
    final service = ref.read(transactionServiceProvider);
    try {
      final deleted = await service.delete(tx.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.transactionDeleted),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => service.restore(deleted),
          ),
        ),
      );
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final active = ref.watch(activeAccountsProvider).value ?? const <Account>[];
    final all = ref.watch(allAccountsProvider).value ?? const <Account>[];
    final dates = ref.watch(dateLabelsProvider);
    final decimals = ref.watch(baseCurrencyProvider).value?.decimals ?? 2;

    Account? byId(int? id) => all.where((a) => a.id == id).firstOrNull;
    final account = byId(_accountId) ?? active.firstOrNull;
    final toAccount = byId(_toAccountId);
    final multiAccount = active.length > 1;
    // قاعدة الأرشفة: لا تُنقل معاملة من حساب مؤرشف أو إليه.
    final lockedAccounts =
        _isEdit &&
        ((account?.isArchived ?? false) || (toAccount?.isArchived ?? false));

    final types = [
      TxType.expense,
      TxType.income,
      if (multiAccount || _type == TxType.transfer) TxType.transfer,
    ];
    final kind = _type == TxType.income
        ? CategoryKind.income
        : CategoryKind.expense;
    final categories =
        ref.watch(categoriesByKindProvider(kind)).value ?? const <Category>[];
    final visibleCats = _showAllCategories || categories.length <= 8
        ? categories
        : categories.take(7).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEdit ? l10n.editTransaction : l10n.addTransaction),
        centerTitle: true,
        actions: [
          if (_isEdit)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: c.expense),
              tooltip: l10n.delete,
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: Insets.screen),
                children: [
                  if (!_isAdjustment)
                    SegmentedTabs<TxType>(
                      values: types,
                      selected: _type,
                      label: l10n.txTypeName,
                      colorOf: (t) => t.color(c),
                      onChanged: (t) => setState(() {
                        if (t != _type) _categoryId = null;
                        _type = t;
                        // التحويل: نقترح أول حساب آخر كوجهة.
                        if (t == TxType.transfer && _toAccountId == null) {
                          _toAccountId = active
                              .where(
                                (a) => a.id != (_accountId ?? active.first.id),
                              )
                              .firstOrNull
                              ?.id;
                        }
                        _suggestAccount();
                      }),
                    ),
                  const SizedBox(height: Insets.md),
                  BigAmountDisplay(
                    text: _isAdjustment
                        ? ref
                              .read(moneyFormatterProvider)
                              .format(_original!.amount)
                        : _amount.text,
                    color: _type.color(c),
                  ),
                  if (_amountError)
                    Center(
                      child: Text(
                        l10n.errInvalidAmount,
                        style: TextStyle(color: c.expense),
                      ),
                    ),
                  const SizedBox(height: Insets.md),

                  // الفئات كأيقونات (للدخل والمصروف)
                  if (_type != TxType.transfer && !_isAdjustment)
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.15,
                      children: [
                        for (final cat in visibleCats)
                          _CategoryCell(
                            icon: AppIcons.category(cat.icon),
                            color: Color(cat.color),
                            label: cat.name,
                            selected: cat.id == _categoryId,
                            onTap: () {
                              setState(() => _categoryId = cat.id);
                              _suggestAccount();
                            },
                          ),
                        if (visibleCats.length < categories.length)
                          _CategoryCell(
                            icon: Icons.more_horiz_rounded,
                            color: c.textSecondary,
                            label: l10n.more,
                            selected: false,
                            onTap: () =>
                                setState(() => _showAllCategories = true),
                          ),
                      ],
                    ),
                  const SizedBox(height: Insets.md),

                  // الحساب (مخفي إن وُجد حساب واحد) + التاريخ + الإيصال
                  if (_type == TxType.transfer) ...[
                    PickerTile(
                      icon: Icons.north_east_rounded,
                      title: account?.name ?? '',
                      subtitle: l10n.fromAccount,
                      onTap: lockedAccounts
                          ? null
                          : () => _chooseAccount(from: true),
                    ),
                    const SizedBox(height: 8),
                    PickerTile(
                      icon: Icons.south_west_rounded,
                      title: toAccount?.name ?? '—',
                      subtitle: l10n.toAccount,
                      onTap: lockedAccounts
                          ? null
                          : () => _chooseAccount(from: false),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      if (_type != TxType.transfer && (multiAccount || _isEdit))
                        Expanded(
                          flex: 3,
                          child: PickerTile(
                            icon: account == null
                                ? Icons.account_balance_wallet_outlined
                                : AppIcons.account(account.type),
                            title: account?.name ?? '',
                            subtitle: _suggested && !_accountChosenManually
                                ? l10n.suggestedForCategory
                                : (account?.isArchived ?? false)
                                ? l10n.archivedBadge
                                : l10n.account,
                            onTap: lockedAccounts || _isAdjustment
                                ? null
                                : () => _chooseAccount(from: true),
                          ),
                        ),
                      if (_type != TxType.transfer && (multiAccount || _isEdit))
                        const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: PickerTile(
                          icon: Icons.calendar_today_outlined,
                          title: dates.relativeDay(_date, l10n),
                          onTap: () async {
                            final d = await pickDate(context, initial: _date);
                            if (d != null) setState(() => _date = d);
                          },
                          trailing: const SizedBox.shrink(),
                        ),
                      ),
                      if (!_isAdjustment) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            onTap: _pickReceipt,
                            child: Icon(
                              _receiptPath == null
                                  ? Icons.photo_camera_outlined
                                  : Icons.receipt_long_rounded,
                              color: _receiptPath == null
                                  ? c.primary
                                  : c.income,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _note,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: '${l10n.note} (${l10n.optional})',
                      prefixIcon: const Icon(Icons.notes_rounded),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.screen - 4,
                0,
                Insets.screen - 4,
                0,
              ),
              child: _isAdjustment
                  ? const SizedBox.shrink()
                  : NumPad(
                      allowDecimal: decimals > 0,
                      onKey: (k) => setState(() {
                        _amount = _amount.press(k, decimals);
                        _amountError = false;
                      }),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.screen,
                4,
                Insets.screen,
                Insets.sm,
              ),
              child: FilledButton.icon(
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(l10n.save),
                onPressed: _saving ? null : () => _save(active),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseAccount({required bool from}) async {
    final picked = await pickAccount(
      context,
      selectedId: from ? _accountId : _toAccountId,
      exclude: {
        if (_type == TxType.transfer && from && _toAccountId != null)
          _toAccountId!,
        if (_type == TxType.transfer && !from && _accountId != null)
          _accountId!,
      },
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _accountId = picked.id;
        _accountChosenManually = true;
      } else {
        _toAccountId = picked.id;
      }
    });
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primary.withValues(alpha: 0.1) : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.button),
        side: BorderSide(
          color: selected ? c.primary : c.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.button),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? c.primary : color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
