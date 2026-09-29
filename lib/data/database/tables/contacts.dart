import 'package:drift/drift.dart';

/// جدول الأشخاص الذين تُسجَّل معهم الديون (الشخص نفسه هو الدفتر).
@DataClassName('Contact')
class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get note => text().nullable()();

  /// مؤرشف: يختفي من القوائم والاختيار. لا يُؤرشف إلا ومتبقّيه صفر في
  /// الاتجاهين، فلا يؤثر على أي إجمالي.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
