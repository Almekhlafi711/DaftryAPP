// في Drift تشير قيود check() إلى العمود نفسه، وهذا مقصود.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import 'accounts.dart';
import 'debts.dart';

/// جدول دفعات السداد. علاقة «تركيب»: الدفعات لا توجد دون الدين (CASCADE).
///
/// - الدفعة لا تُحذف: تُلغى ([isCancelled]) وتبقى في الخط الزمني مشطوبة.
/// - الدفعات الناتجة عن عملية استلام/سداد واحدة موزّعة على عدة ديون تحمل
///   نفس [operationId]، وتُلغى معاً.
@DataClassName('DebtPayment')
@TableIndex(name: 'idx_payments_debt', columns: {#debtId, #paidAt})
@TableIndex(name: 'idx_payments_operation', columns: {#operationId})
class DebtPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get debtId =>
      integer().references(Debts, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();
  DateTimeColumn get paidAt => dateTime()();

  /// حساب الاستلام أو الدفع. (null فقط لدفعات قديمة سُجِّلت في الدفتر.)
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  TextColumn get note => text().nullable()();
  BoolColumn get isCancelled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cancelledAt => dateTime().nullable()();

  /// معرّف العملية (UUID) المشترك بين دفعات التوزيع الواحدة.
  TextColumn get operationId => text().nullable()();
}
