// في Drift تشير قيود check() إلى العمود نفسه، وهذا مقصود.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';

import 'accounts.dart';
import 'categories.dart';
import 'currencies.dart';
import 'debt_payments.dart';
import 'debts.dart';

/// جدول المعاملات: كل تغيير في رصيد أي حساب — دخل، مصروف، تحويل، تسوية،
/// حركة دين — وكذلك قيود الديون التي لا تحرّك حساباً (البيع والشراء بالآجل،
/// المسامحة والإعفاء). (اسم الجدول بالجمع لأن transaction كلمة محجوزة في SQL).
@DataClassName('MoneyTransaction')
@TableIndex(name: 'idx_tx_date', columns: {#date})
@TableIndex(name: 'idx_tx_account_date', columns: {#accountId, #date})
@TableIndex(name: 'idx_tx_to_account', columns: {#toAccountId})
@TableIndex(name: 'idx_tx_category_date', columns: {#categoryId, #date})
@TableIndex(name: 'idx_tx_debt', columns: {#debtId})
@TableIndex(name: 'idx_tx_debt_payment', columns: {#debtPaymentId})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<TxType>()();

  /// المبلغ: موجب دائماً، ما عدا «التسوية» فقد يكون سالباً (لا يكون صفراً).
  IntColumn get amount => integer().check(
    amount.isNotValue(0) &
        (amount.isBiggerThanValue(0) | type.equals(TxType.adjustment.name)),
  )();
  IntColumn get currencyId => integer().references(Currencies, #id)();

  /// الحساب (المصدر في حالة التحويل). فارغ فقط لقيود الديون التي لا تحرّك
  /// مالاً (البيع/الشراء بالآجل والمسامحة) — ويجب حينها أن تكون مرتبطة بدين.
  IntColumn get accountId => integer()
      .nullable()
      .references(Accounts, #id)
      .check(accountId.isNotNull() | debtId.isNotNull())();

  /// الحساب الوجهة — للتحويل فقط.
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();

  /// الفئة — للدخل والمصروف فقط.
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  /// الدين المرتبط — لقيد إنشاء الدين أو مسامحته، ولأول دين في عملية سداد.
  IntColumn get debtId => integer().nullable().references(Debts, #id)();

  /// الدفعة المرتبطة — لحركة عملية سداد (أول دفعة من دفعات العملية).
  IntColumn get debtPaymentId =>
      integer().nullable().references(DebtPayments, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();

  /// مسار صورة الإيصال داخل مجلد التطبيق (اختياري).
  TextColumn get receiptPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
