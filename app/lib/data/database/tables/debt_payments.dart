// في Drift تشير قيود check() إلى العمود نفسه، وهذا مقصود.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import 'accounts.dart';
import 'debts.dart';

/// جدول دفعات السداد. علاقة «تركيب»: الدفعات لا توجد دون الدين (CASCADE).
@DataClassName('DebtPayment')
@TableIndex(name: 'idx_payments_debt', columns: {#debtId, #paidAt})
class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId =>
      integer().references(Debts, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  DateTimeColumn get paidAt => dateTime()();

  /// حساب الاستلام أو الدفع (اختياري).
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  TextColumn get note => text().nullable()();
}
