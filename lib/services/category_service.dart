// =============================================================================
// خدمة الفئات (FR-13): افتراضية ومخصصة بأيقونة ولون، منفصلة للدخل والمصروف.
// =============================================================================

import 'package:drift/drift.dart';

import '../core/errors/app_exception.dart';
import '../data/database/app_database.dart';
import '../domain/enums.dart';

class CategoryService {
  CategoryService(this.db);

  final AppDatabase db;

  /// فئات نوع معيّن مرتبة كما تظهر في شبكة الأيقونات.
  Stream<List<Category>> watchByKind(CategoryKind kind) =>
      (db.select(db.categories)
            ..where((c) => c.kind.equals(kind.name))
            ..orderBy([
              (c) => OrderingTerm.asc(c.sortOrder),
              (c) => OrderingTerm.asc(c.id),
            ]))
          .watch();

  Stream<List<Category>> watchAll() =>
      (db.select(db.categories)..orderBy([
            (c) => OrderingTerm.asc(c.kind),
            (c) => OrderingTerm.asc(c.sortOrder),
          ]))
          .watch();

  Future<Category?> getById(int id) => (db.select(
    db.categories,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> create({
    required String name,
    required CategoryKind kind,
    required String icon,
    required int color,
    int? parentId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const BusinessException(BusinessError.emptyName);
    // الفئة الجديدة تُضاف في آخر الترتيب.
    final maxOrder = db.categories.sortOrder.max();
    final row =
        await (db.selectOnly(db.categories)
              ..addColumns([maxOrder])
              ..where(db.categories.kind.equals(kind.name)))
            .getSingle();
    return db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: trimmed,
            kind: kind,
            icon: icon,
            color: color,
            parentId: Value(parentId),
            sortOrder: Value((row.read(maxOrder) ?? 0) + 1),
          ),
        );
  }

  /// تعديل الاسم والأيقونة واللون (rename في مخطط الفئات).
  Future<void> update(
    int id, {
    required String name,
    required String icon,
    required int color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const BusinessException(BusinessError.emptyName);
    await (db.update(db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(trimmed),
        icon: Value(icon),
        color: Value(color),
      ),
    );
  }

  /// حذف فئة غير مستخدمة. الفئة المستخدمة في معاملات لا تُحذف حفاظاً
  /// على السجل التاريخي والتقارير.
  Future<void> delete(int id) => db.transaction(() async {
    final used =
        await (db.select(db.transactions)
              ..where((t) => t.categoryId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    final child =
        await (db.select(db.categories)
              ..where((c) => c.parentId.equals(id))
              ..limit(1))
            .getSingleOrNull();
    if (used != null || child != null) {
      throw const BusinessException(BusinessError.categoryInUse);
    }
    await (db.delete(db.categories)..where((c) => c.id.equals(id))).go();
  });
}
