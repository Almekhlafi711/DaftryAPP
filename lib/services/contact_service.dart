// =============================================================================
// خدمة الأشخاص (جهات التعامل في دفتر الديون) — FR-14.
// =============================================================================

import 'package:drift/drift.dart';

import '../core/errors/app_exception.dart';
import '../data/database/app_database.dart';

class ContactService {
  ContactService(this.db);

  final AppDatabase db;

  /// الأشخاص النشطون مرتبين أبجدياً، مع بحث اختياري بالاسم أو الهاتف.
  Stream<List<Contact>> watchActive({String query = ''}) {
    final q = db.select(db.contacts)
      ..where((c) => c.isActive.equals(true))
      ..orderBy([(c) => OrderingTerm.asc(c.name)]);
    final text = query.trim();
    if (text.isNotEmpty) {
      q.where((c) => c.name.like('%$text%') | c.phone.like('%$text%'));
    }
    return q.watch();
  }

  Stream<Contact?> watchById(int id) => (db.select(
    db.contacts,
  )..where((c) => c.id.equals(id))).watchSingleOrNull();

  Future<Contact?> getById(int id) =>
      (db.select(db.contacts)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// إضافة شخص يدوياً أو من جهات الاتصال.
  /// إن وُجد شخص نشط بنفس رقم الهاتف يُعاد رقمه بدل التكرار.
  Future<int> create({
    required String name,
    String? phone,
    String? address,
    String? note,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const BusinessException(BusinessError.emptyName);
    final cleanPhone = _clean(phone);
    if (cleanPhone != null) {
      final existing =
          await (db.select(db.contacts)
                ..where(
                  (c) => c.phone.equals(cleanPhone) & c.isActive.equals(true),
                )
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) return existing.id;
    }
    return db
        .into(db.contacts)
        .insert(
          ContactsCompanion.insert(
            name: trimmed,
            phone: Value(cleanPhone),
            address: Value(_clean(address)),
            note: Value(_clean(note)),
          ),
        );
  }

  /// تعديل بيانات الشخص (من شاشة مستقلة).
  Future<void> update(
    int id, {
    required String name,
    String? phone,
    String? address,
    String? note,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const BusinessException(BusinessError.emptyName);
    await (db.update(db.contacts)..where((c) => c.id.equals(id))).write(
      ContactsCompanion(
        name: Value(trimmed),
        phone: Value(_clean(phone)),
        address: Value(_clean(address)),
        note: Value(_clean(note)),
      ),
    );
  }

  /// إخفاء الشخص من القائمة (يبقى سجله وديونه في التقارير).
  Future<void> setActive(int id, {required bool active}) =>
      (db.update(db.contacts)..where((c) => c.id.equals(id))).write(
        ContactsCompanion(isActive: Value(active)),
      );

  static String? _clean(String? s) {
    final v = s?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}
