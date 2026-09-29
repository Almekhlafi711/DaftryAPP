import 'package:drift/drift.dart';

/// جدول العملات: صف واحد في النسخة الأولى، يُقفل بعد الإعداد الأول.
@DataClassName('Currency')
class Currencies extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// رمز ISO من 3 أحرف مثل SAR.
  TextColumn get code => text().withLength(min: 3, max: 3)();
  TextColumn get name => text()();
  TextColumn get symbol => text()();

  /// العملة الأساسية للتطبيق (دائماً true حالياً).
  BoolColumn get isBase => boolean().withDefault(const Constant(true))();

  /// عدد الخانات العشرية (2 للريال، 3 للدينار الكويتي...).
  IntColumn get decimals => integer().withDefault(const Constant(2))();
}
