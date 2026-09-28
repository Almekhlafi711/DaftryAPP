// =============================================================================
// خدمة كشف الحساب (FR-19 / UC-15).
//
// الكشف يُولَّد من بيانات الشخص عند الطلب ولا يُخزَّن داخل التطبيق
// (قاعدة 3.12.4). يحتوي: الرصيد الافتتاحي قبل الفترة، ثم الحركات داخل
// الفترة مع الرصيد الجاري بعد كل حركة، ثم المتبقي.
// الإخراج (PDF / صورة) في services/export/statement_pdf.dart.
// =============================================================================

import '../core/errors/app_exception.dart';
import '../core/utils/date_range.dart';
import '../data/database/app_database.dart';
import '../domain/enums.dart';
import '../domain/models/budget_report_models.dart';

class StatementService {
  StatementService(this.db);

  final AppDatabase db;

  Future<StatementData> build(int contactId, DateRange range) async {
    final contact = await (db.select(
      db.contacts,
    )..where((c) => c.id.equals(contactId))).getSingleOrNull();
    if (contact == null) throw const BusinessException(BusinessError.notFound);

    final debts = await (db.select(
      db.debts,
    )..where((d) => d.contactId.equals(contactId))).get();
    final directions = {for (final d in debts) d.id: d.direction};
    final payments = debts.isEmpty
        ? <DebtPayment>[]
        : await (db.select(
            db.debtPayments,
          )..where((p) => p.debtId.isIn(directions.keys))).get();

    // كل الحركات كعناصر موحدة: (التاريخ، هل هي دفعة، الاتجاه، المبلغ، الملاحظة)
    final events = [
      for (final d in debts)
        (
          date: d.startDate,
          isPayment: false,
          dir: d.direction,
          amount: d.amount,
          note: d.note,
        ),
      for (final p in payments)
        (
          date: p.paidAt,
          isPayment: true,
          dir: directions[p.debtId]!,
          amount: p.amount,
          note: p.note,
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    // أثر الحركة على الصافي من منظور المستخدم (موجب = لي).
    int effect(bool isPayment, DebtDirection dir, int amount) {
      final base = isPayment ? -amount : amount;
      return dir == DebtDirection.owedToMe ? base : -base;
    }

    var opening = 0;
    for (final e in events.where((e) => e.date.isBefore(range.start))) {
      opening += effect(e.isPayment, e.dir, e.amount);
    }

    var running = opening;
    final lines = <StatementLine>[];
    for (final e in events.where((e) => range.contains(e.date))) {
      final eff = effect(e.isPayment, e.dir, e.amount);
      running += eff;
      lines.add(
        StatementLine(
          date: e.date,
          isPayment: e.isPayment,
          direction: e.dir,
          amount: e.amount,
          effect: eff,
          runningBalance: running,
          note: e.note,
        ),
      );
    }

    return StatementData(
      contact: contact,
      range: range,
      openingBalance: opening,
      lines: lines,
    );
  }
}
