// في Drift تشير قيود check() إلى العمود نفسه، وهذا مقصود.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../../domain/enums.dart';

import 'categories.dart';

/// جدول الميزانيات: سقف إنفاق لكل فئة في فترة.
@DataClassName('Budget')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get limitAmount =>
      integer().check(limitAmount.isBiggerThanValue(0))();
  TextColumn get period => textEnum<BudgetPeriod>()();

  /// نسبة التنبيه الأولى (75% افتراضياً). التنبيه الثاني دائماً عند 100%.
  IntColumn get alertPercent => integer().withDefault(const Constant(75))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {categoryId, period},
  ];
}
