import 'package:drift/drift.dart';

import '../../../domain/enums.dart';

/// جدول الفئات: منفصلة للدخل والمصروف، ويمكن أن تكون فرعية (parent_id).
@DataClassName('Category')
@TableIndex(name: 'idx_categories_kind', columns: {#kind, #sortOrder})
@TableIndex(
  name: 'idx_categories_system_key',
  columns: {#systemKey},
  unique: true,
)
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();

  /// مفتاح الأيقونة (انظر ui/theme/app_icons.dart).
  TextColumn get icon => text()();

  /// اللون بصيغة ARGB.
  IntColumn get color => integer()();

  /// فئة افتراضية أنشأها التطبيق (يمكن تعديلها).
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// ترتيب العرض في شبكة الفئات.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// مفتاح ثابت لفئات التطبيق التي تحتاجها الخدمات (مثل «مبيعات» للبيع
  /// بالآجل و«مسامحة ديون»)، فتُعرف مهما غيّر المستخدم اسمها.
  TextColumn get systemKey => text().nullable()();
}
