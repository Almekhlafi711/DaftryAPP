import 'package:drift/drift.dart';

import '../../../domain/enums.dart';

import 'currencies.dart';

/// جدول الحسابات (نقدي، بنكي، محفظة، توفير).
/// ⚠️ لا يُحذف أي حساب إطلاقاً — يوجد Trigger في قاعدة البيانات يمنع DELETE.
@DataClassName('Account')
@TableIndex.sql(
  // فهرس فريد جزئي: يضمن على مستوى قاعدة البيانات وجود حساب افتراضي واحد فقط.
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_accounts_single_default '
  'ON accounts (is_default) WHERE is_default = 1',
)
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get type => textEnum<AccountType>()();
  IntColumn get currencyId => integer().references(Currencies, #id)();

  /// الرصيد الافتتاحي عند إنشاء الحساب.
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();

  /// الرصيد المخزَّن: يُحدَّث داخل نفس عملية حفظ المعاملة (ذرّياً)، ويمكن
  /// إعادة احتسابه من المعاملات للتدقيق (FR-27). تخزينه يجعل عرض الأرصدة فورياً.
  IntColumn get balance => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// مفتاح الأيقونة (اختياري؛ إن كان فارغاً تُستخدم أيقونة النوع).
  TextColumn get icon => text().nullable()();

  /// اللون بصيغة ARGB (اختياري).
  IntColumn get color => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
