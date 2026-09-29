import 'package:drift/drift.dart';

import '../../../domain/enums.dart';

/// سجل عمليات النسخ الاحتياطي.
@DataClassName('BackupLog')
class BackupLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get provider => textEnum<BackupProvider>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get sizeKb => integer().withDefault(const Constant(0))();

  /// success أو رسالة الخطأ.
  TextColumn get status => text()();
}
