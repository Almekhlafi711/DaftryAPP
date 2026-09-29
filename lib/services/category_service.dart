// =============================================================================
// خدمة الفئات (FR-13): افتراضية ومخصصة بأيقونة ولون، منفصلة للدخل والمصروف.
// =============================================================================

import 'package:drift/drift.dart';

import '../core/errors/app_exception.dart';
import '../data/database/app_database.dart';
import '../data/seed/default_categories.dart';
import '../domain/enums.dart';

class CategoryService {
  CategoryService(this.db);

  final AppDatabase db;

  /// فئتا المسامحة والإعفاء خاصتان بوحدة الديون (لا تُختاران لمعاملة عادية).
  static const debtOnlyKeys = [
    SystemCategoryKeys.debtWriteOff,
    SystemCategoryKeys.debtForgiven,
  ];

  /// فئات نوع معيّن مرتبة كما تظهر في شبكة الأيقونات.
  /// [forTransactions]: يستبعد فئتي المسامحة والإعفاء من شاشة المعاملة.
  Stream<List<Category>> watchByKind(
    CategoryKind kind, {
    bool forTransactions = false,
  }) {
    final q = db.select(db.categories)
      ..where((c) => c.kind.equals(kind.name))
      ..orderBy([
        (c) => OrderingTerm.asc(c.sortOrder),
        (c) => OrderingTerm.asc(c.id),
      ]);
    if (forTransactions) {
      q.where((c) => c.systemKey.isNull() | c.systemKey.isNotIn(debtOnlyKeys));
    }
    return q.watch();
  }

  /// فئة بمفتاحها الثابت (null إن حذفها المستخدم).
  Future<Category?> bySystemKey(String key) => (db.select(
    db.categories,
  )..where((c) => c.systemKey.equals(key))).getSingleOrNull();

  /// فئة يحتاجها التطبيق (مثل «مسامحة ديون»): تُعاد إن وُجدت، وإلا تُنشأ
  /// بلغة الواجهة الحالية.
  Future<Category> ensureSystemCategory(
    SeedCategory seed, {
    required bool arabic,
  }) => db.transaction(() async {
    final existing = await bySystemKey(seed.key);
    if (existing != null) return existing;
    final id = await create(
      name: arabic ? seed.nameAr : seed.nameEn,
      kind: seed.kind,
      icon: seed.icon,
      color: seed.color,
      systemKey: seed.key,
    );
    return (await getById(id))!;
  });

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
    String? systemKey,
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
            isDefault: Value(systemKey != null),
            systemKey: Value(systemKey),
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
