// في Drift تشير قيود check() إلى العمود نفسه، وهذا مقصود.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';

import 'accounts.dart';
import 'contacts.dart';
import 'currencies.dart';

/// جدول الديون باتجاهين (لي / عليّ).
///
/// المدفوع والمتبقي والحالة لا تُخزَّن: تُحسب دائماً من الدفعات غير الملغاة
/// والمسامحة (R = amount − Paid − written_off)، فلا يمكن أن تتناقض مع السجل.
@DataClassName('Debt')
@TableIndex(name: 'idx_debts_contact', columns: {#contactId})
@TableIndex(name: 'idx_debts_due', columns: {#dueDate})
class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get contactId => integer().references(Contacts, #id)();
  TextColumn get direction => textEnum<DebtDirection>()();

  /// مصدر الدين (إقراض، بيع/شراء بالآجل، دين سابق) — يحدد القيد المحاسبي.
  TextColumn get source => textEnum<DebtSource>()();

  /// أصل الدين (A > 0).
  IntColumn get amount => integer().check(amount.isBiggerThanValue(0))();

  /// W: مجموع ما سُومح به من هذا الدين (قيود المسامحة / الإعفاء).
  IntColumn get writtenOff => integer()
      .withDefault(const Constant(0))
      .check(writtenOff.isBiggerOrEqualValue(0))();
  IntColumn get currencyId => integer().references(Currencies, #id)();

  /// الحساب الذي خرج منه أو دخل إليه المال — للإقراض والاقتراض فقط.
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get note => text().nullable()();

  /// تذكير محلي قبل موعد الاستحقاق بيوم (FR-20).
  BoolColumn get remind => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
