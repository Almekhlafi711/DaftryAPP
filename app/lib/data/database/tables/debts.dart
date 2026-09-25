// في Drift تشير قيود check() إلى العمود نفسه، وهذا مقصود.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';

import 'accounts.dart';
import 'contacts.dart';
import 'currencies.dart';

/// جدول الديون باتجاهين (لي / عليّ).
@DataClassName('Debt')
@TableIndex(name: 'idx_debts_contact', columns: {#contactId})
@TableIndex(name: 'idx_debts_status_due', columns: {#status, #dueDate})
class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contactId => integer().references(Contacts, #id)();
  TextColumn get direction => textEnum<DebtDirection>()();

  /// أصل الدين.
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();

  /// مجموع ما سُدِّد (قيمة مشتقة مخزَّنة للأداء، تُحدَّث مع كل دفعة
  /// ويمكن إعادة احتسابها). المتبقي = amount - paid_amount.
  IntColumn get paidAmount => integer().withDefault(const Constant(0))();
  IntColumn get currencyId => integer().references(Currencies, #id)();

  /// الحساب الذي خرج منه أو دخل إليه المال (فارغ للبيع بالآجل).
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// تُحسب آلياً من الدفعات: open / partial / settled.
  TextColumn get status => textEnum<DebtStatus>()();
  TextColumn get note => text().nullable()();

  /// تذكير محلي قبل موعد الاستحقاق بيوم (FR-20).
  BoolColumn get remind => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
