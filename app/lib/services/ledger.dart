// =============================================================================
// «دفتر الأستاذ» الداخلي: المكان الوحيد الذي يغيّر أرصدة الحسابات.
//
// قاعدة العمل 3.12.3: لا يتغير رصيد أي حساب إلا عبر معاملة.
// لذلك كل الخدمات (المعاملات، الديون، الحسابات) تستخدم هذا الصنف لإدراج
// المعاملة وتحديث الرصيد معاً — ويجب استدعاؤه دائماً داخل db.transaction()
// حتى يكون الحفظ ذرياً (إما أن ينجح كله أو يُلغى كله).
// =============================================================================

import 'package:drift/drift.dart';

import '../core/errors/app_exception.dart';
import '../data/database/app_database.dart';
import '../domain/enums.dart';

class Ledger {
  Ledger(this.db);

  final AppDatabase db;

  /// يُدرج معاملة ويطبّق أثرها على الرصيد. يعيد رقم المعاملة.
  Future<int> insert(TransactionsCompanion row) async {
    final id = await db.into(db.transactions).insert(row);
    await applyEffect(
      type: row.type.value,
      amount: row.amount.value,
      accountId: row.accountId.value,
      toAccountId: row.toAccountId.present ? row.toAccountId.value : null,
    );
    return id;
  }

  /// يعكس أثر المعاملة على الرصيد ثم يحذفها.
  Future<void> remove(MoneyTransaction tx) async {
    await applyTx(tx, sign: -1);
    await (db.delete(db.transactions)..where((t) => t.id.equals(tx.id))).go();
  }

  /// يطبّق أثر معاملة موجودة ([sign] = 1) أو يعكسه ([sign] = -1).
  Future<void> applyTx(MoneyTransaction tx, {int sign = 1}) => applyEffect(
    type: tx.type,
    amount: tx.amount,
    accountId: tx.accountId,
    toAccountId: tx.toAccountId,
    sign: sign,
  );

  /// أثر كل نوع معاملة على الرصيد (انظر توثيق TxType).
  Future<void> applyEffect({
    required TxType type,
    required int amount,
    required int accountId,
    int? toAccountId,
    int sign = 1,
  }) async {
    switch (type) {
      case TxType.income:
      case TxType.debtIn:
      case TxType.adjustment:
        await _addToBalance(accountId, amount * sign);
      case TxType.expense:
      case TxType.debtOut:
        await _addToBalance(accountId, -amount * sign);
      case TxType.transfer:
        await _addToBalance(accountId, -amount * sign);
        await _addToBalance(toAccountId!, amount * sign);
    }
  }

  /// تحديث الرصيد بعبارة SQL واحدة (balance = balance + delta) بدلاً من
  /// قراءة الرصيد ثم كتابته — أسرع ويمنع أخطاء التزامن.
  Future<void> _addToBalance(int accountId, int delta) async {
    if (delta == 0) return;
    await db.customUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      variables: [Variable.withInt(delta), Variable.withInt(accountId)],
      updates: {db.accounts},
      updateKind: UpdateKind.update,
    );
  }

  /// يجلب حساباً ويتأكد أنه نشط (غير مؤرشف) — للعمليات الجديدة.
  Future<Account> requireActiveAccount(int id) async {
    final account = await (db.select(
      db.accounts,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    if (account == null) throw const BusinessException(BusinessError.notFound);
    if (account.isArchived) {
      throw BusinessException(BusinessError.accountArchived, account.name);
    }
    return account;
  }

  /// رقم عملة التطبيق (يُحفظ مع كل معاملة للتوسع المستقبلي لتعدد العملات).
  Future<int> baseCurrencyId() async {
    final currency = await db.baseCurrency();
    if (currency == null) {
      throw const BusinessException(BusinessError.notOnboarded);
    }
    return currency.id;
  }
}
