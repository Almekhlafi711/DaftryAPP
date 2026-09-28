import 'package:drift/drift.dart';

/// جدول الإعدادات بصيغة مفتاح/قيمة (انظر services/settings_service.dart
/// لقائمة المفاتيح).
@DataClassName('SettingEntry')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
