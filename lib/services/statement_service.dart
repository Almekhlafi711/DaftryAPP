// =============================================================================
// خدمة كشف الحساب (FR-19 / UC-15) — القسم 7.2 من وثيقة الديون.
//
// الكشف يُولَّد من بيانات الشخص عند الطلب ولا يُخزَّن داخل التطبيق
// (قاعدة 3.12.4). لكل اتجاه (لي / عليّ) قسم مستقل:
//   Opening = ΣA قبل S − Σالدفعات قبل S − Σالمسامحة قبل S
//   Closing = Opening + ديون الفترة − دفعات الفترة − مسامحة الفترة
// والدفعات الملغاة لا تدخل. شرط التطابق: إذا كانت E هي اليوم فإن Closing
// يساوي المتبقي الحالي.
// الإخراج (PDF / صورة) في services/export/statement_pdf.dart.
// =============================================================================

import 'package:drift/drift.dart';

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
    final byId = {for (final d in debts) d.id: d};
    final ids = byId.keys.toList();

    final payments = ids.isEmpty
        ? <DebtPayment>[]
        : await (db.select(db.debtPayments)
                ..where((p) => p.debtId.isIn(ids) & p.isCancelled.equals(false))
                ..orderBy([(p) => OrderingTerm.asc(p.id)]))
              .get();
    final writeOffs = ids.isEmpty
        ? <MoneyTransaction>[]
        : await (db.select(db.transactions)..where(
                (t) =>
                    t.debtId.isIn(ids) &
                    t.type.isIn([
                      TxType.writeOff.name,
                      TxType.debtForgiven.name,
                    ]),
              ))
              .get();

    // الأحداث: ديون، عمليات سداد (دفعات العملية الواحدة سطر واحد)، مسامحة.
    final events =
        <
          ({
            DebtDirection dir,
            DateTime date,
            StatementLineKind kind,
            int amount,
            int seq,
            DebtSource? source,
            String? note,
          })
        >[
          for (final d in debts)
            (
              dir: d.direction,
              date: d.startDate,
              kind: StatementLineKind.debt,
              amount: d.amount,
              seq: d.id,
              source: d.source,
              note: d.note,
            ),
          for (final t in writeOffs)
            (
              dir: byId[t.debtId]!.direction,
              date: t.date,
              kind: StatementLineKind.writeOff,
              amount: t.amount,
              seq: t.id,
              source: null,
              note: t.note,
            ),
        ];
    final operations = <String, List<DebtPayment>>{};
    for (final p in payments) {
      operations.putIfAbsent(p.operationId ?? 'p${p.id}', () => []).add(p);
    }
    for (final op in operations.values) {
      final first = op.first;
      events.add((
        dir: byId[first.debtId]!.direction,
        date: first.paidAt,
        kind: StatementLineKind.payment,
        amount: op.fold(0, (s, p) => s + p.amount),
        seq: first.id,
        source: null,
        note: first.note,
      ));
    }

    // الترتيب: حسب التاريخ، وعند التساوي الدين قبل الدفعة ثم المسامحة،
    // ثم حسب وقت الإدخال.
    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    events.sort((a, b) {
      final byDay = day(a.date).compareTo(day(b.date));
      if (byDay != 0) return byDay;
      final byKind = a.kind.index.compareTo(b.kind.index);
      if (byKind != 0) return byKind;
      return a.seq.compareTo(b.seq);
    });

    final sections = <StatementSection>[];
    for (final dir in DebtDirection.values) {
      final list = events.where((e) => e.dir == dir).toList();
      if (list.isEmpty) continue;
      int movement(StatementLineKind k, int amount) =>
          k == StatementLineKind.debt ? amount : -amount;
      var opening = 0;
      for (final e in list.where((e) => e.date.isBefore(range.start))) {
        opening += movement(e.kind, e.amount);
      }
      var running = opening;
      final lines = <StatementLine>[];
      for (final e in list.where((e) => range.contains(e.date))) {
        running += movement(e.kind, e.amount);
        lines.add(
          StatementLine(
            date: e.date,
            kind: e.kind,
            amount: e.amount,
            balance: running,
            source: e.source,
            note: e.note,
          ),
        );
      }
      sections.add(
        StatementSection(direction: dir, opening: opening, lines: lines),
      );
    }

    return StatementData(contact: contact, range: range, sections: sections);
  }
}
