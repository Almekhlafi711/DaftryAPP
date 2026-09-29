// =============================================================================
// خدمة الأشخاص (جهات التعامل في دفتر الديون) — FR-14.
//
// - الشخص نفسه هو الدفتر: الاسم والهاتف والملاحظة تكفي.
// - الحذف مسموح فقط لشخص بلا أي حركة؛ وإلا فالأرشفة بشرط أن يكون متبقّيه
//   صفراً في الاتجاهين (8.4).
// - منع التكرار: عند كتابة اسم موجود تقترح الواجهة الشخص الموجود.
// =============================================================================

import 'package:drift/drift.dart';

import '../core/errors/app_exception.dart';
import '../data/database/app_database.dart';

class ContactService {
  ContactService(this.db);

  final AppDatabase db;

  /// الأشخاص غير المؤرشفين مرتبين أبجدياً، مع بحث بالاسم أو الهاتف.
  Stream<List<Contact>> watchActive({String query = ''}) {
    final q = db.select(db.contacts)
      ..where((c) => c.isArchived.equals(false))
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

  /// شخص غير مؤرشف بنفس الاسم (بعد إزالة المسافات الزائدة، ودون تمييز حالة
  /// الأحرف) — لاقتراح «أحمد علي موجود، هل تقصده؟».
  Future<Contact?> findByName(String name, {int? exceptId}) async {
    final normalized = normalizeName(name).toLowerCase();
    if (normalized.isEmpty) return null;
    final candidates = await (db.select(
      db.contacts,
    )..where((c) => c.isArchived.equals(false))).get();
    return candidates
        .where(
          (c) =>
              c.id != exceptId &&
              normalizeName(c.name).toLowerCase() == normalized,
        )
        .firstOrNull;
  }

  /// إضافة شخص يدوياً أو من جهات الاتصال.
  /// إن وُجد شخص غير مؤرشف بنفس رقم الهاتف يُعاد رقمه بدل التكرار.
  Future<int> create({
    required String name,
    String? phone,
    String? note,
  }) async {
    final trimmed = normalizeName(name);
    if (trimmed.isEmpty) throw const BusinessException(BusinessError.emptyName);
    final cleanPhone = _clean(phone);
    if (cleanPhone != null) {
      final existing =
          await (db.select(db.contacts)
                ..where(
                  (c) =>
                      c.phone.equals(cleanPhone) & c.isArchived.equals(false),
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
            note: Value(_clean(note)),
          ),
        );
  }

  /// تعديل بيانات الشخص (من شاشة مستقلة).
  Future<void> update(
    int id, {
    required String name,
    String? phone,
    String? note,
  }) async {
    final trimmed = normalizeName(name);
    if (trimmed.isEmpty) throw const BusinessException(BusinessError.emptyName);
    await (db.update(db.contacts)..where((c) => c.id.equals(id))).write(
      ContactsCompanion(
        name: Value(trimmed),
        phone: Value(_clean(phone)),
        note: Value(_clean(note)),
      ),
    );
  }

  /// مجموع المتبقي في الاتجاهين (كل دين متبقّيه ≥ 0).
  Future<int> _remaining(int id) async {
    final row = await db
        .customSelect(
          'SELECT COALESCE(SUM(${AppDatabase.remainingSql('d')}), 0) AS r '
          'FROM debts d WHERE d.contact_id = ?1',
          variables: [Variable.withInt(id)],
          readsFrom: {db.debts, db.debtPayments},
        )
        .getSingle();
    return row.read<int>('r');
  }

  /// أرشفة الشخص بدل حذفه: بشرط أن يكون متبقّيه صفراً في الاتجاهين.
  Future<void> archive(int id) => db.transaction(() async {
    final contact = await getById(id);
    if (contact == null) throw const BusinessException(BusinessError.notFound);
    if (await _remaining(id) != 0) {
      throw BusinessException(BusinessError.personHasBalance, contact.name);
    }
    await (db.update(db.contacts)..where((c) => c.id.equals(id))).write(
      ContactsCompanion(
        isArchived: const Value(true),
        archivedAt: Value(DateTime.now()),
      ),
    );
  });

  Future<void> unarchive(int id) =>
      (db.update(db.contacts)..where((c) => c.id.equals(id))).write(
        const ContactsCompanion(
          isArchived: Value(false),
          archivedAt: Value(null),
        ),
      );

  /// حذف الشخص: مسموح فقط إن لم تكن له أي حركة (أي دين).
  Future<void> delete(int id) => db.transaction(() async {
    final count = db.debts.id.count();
    final row =
        await (db.selectOnly(db.debts)
              ..addColumns([count])
              ..where(db.debts.contactId.equals(id)))
            .getSingle();
    if ((row.read(count) ?? 0) > 0) {
      throw const BusinessException(BusinessError.personHasMovements);
    }
    await (db.delete(db.contacts)..where((c) => c.id.equals(id))).go();
  });

  /// الاسم دون مسافات زائدة في البداية والنهاية والوسط.
  static String normalizeName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String? _clean(String? s) {
    final v = s?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}
