// =============================================================================
// تصدير التقارير إلى PDF و Excel (FR-23 — ReportService.exportPdf/exportExcel).
// =============================================================================

import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/money/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/budget_report_models.dart';
import '../../domain/models/transaction_models.dart';
import 'document_owner.dart';
import 'pdf_fonts.dart';
import 'pdf_text.dart';

/// نصوص التقرير بلغة المستخدم.
class ReportLabels {
  const ReportLabels({
    required this.appName,
    required this.title,
    required this.period,
    required this.income,
    required this.expense,
    required this.net,
    required this.month,
    required this.category,
    required this.share,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.monthsComparison,
    required this.transactions,
    required this.date,
    required this.type,
    required this.account,
    required this.amount,
    required this.note,
    required this.typeName,
    required this.excludedNote,
  });

  final String appName;
  final String title;
  final String period;
  final String income;
  final String expense;
  final String net;
  final String month;
  final String category;
  final String share;
  final String expenseByCategory;
  final String incomeByCategory;
  final String monthsComparison;
  final String transactions;
  final String date;
  final String type;
  final String account;
  final String amount;
  final String note;

  /// اسم نوع المعاملة المترجم.
  final String Function(TxType) typeName;

  /// «حركات الديون والتسويات مستبعدة من هذه الأرقام».
  final String excludedNote;
}

class ReportExporter {
  ReportExporter({
    required this.labels,
    required this.money,
    required this.locale,
    required this.rtl,
    this.owner,
  });

  final ReportLabels labels;
  final MoneyFormatter money;
  final String locale;
  final bool rtl;

  /// صاحب الدفتر (اسمه ورقمه) في ترويسة التقرير.
  final DocumentOwner? owner;

  /// أرقام التواريخ تتبع إعداد الأرقام (intl يكتب العربية بالأرقام الهندية افتراضياً).
  String _date(DateFormat format, DateTime d) {
    final text = format.format(d);
    return money.useArabicDigits ? text : MoneyParser.normalizeDigits(text);
  }

  static const _primary = PdfColor.fromInt(0xFF0F766E);
  static const _green = PdfColor.fromInt(0xFF15803D);
  static const _red = PdfColor.fromInt(0xFFDC2626);
  static const _muted = PdfColor.fromInt(0xFF64748B);

  String _range(PeriodReport r) {
    final f = DateFormat.yMMMd(locale);
    return '${_date(f, r.range.start)} — '
        '${_date(f, r.range.end.subtract(const Duration(days: 1)))}';
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  Future<Uint8List> buildPdf(PeriodReport report, PdfFonts fonts) async {
    final doc = pw.Document(title: labels.title);
    final monthFmt = DateFormat.yMMM(locale);

    pw.Widget amount(int v, {PdfColor? color, bool bold = false}) =>
        pdfTextWidget(
          money.format(v, withSymbol: true),
          textDirection: pw.TextDirection.ltr,
          style: pw.TextStyle(
            color: color,
            fontWeight: bold ? pw.FontWeight.bold : null,
            fontSize: 10,
          ),
        );

    final dir = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    // جداول مكتبة PDF تُرتَّب دائماً من اليسار ولا ترث اتجاه الصفحة: نعكس
    // الأعمدة في العربية (العمود الأول يميناً) ونحدد اتجاه كل نص.
    List<T> ordered<T>(List<T> cells) => rtl ? cells.reversed.toList() : cells;
    pw.Widget cell(pw.Widget child) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Align(
        alignment: rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: child,
      ),
    );

    pw.Widget table(List<String> headers, List<List<pw.Widget>> rows) =>
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _primary),
              children: ordered([
                for (final h in headers)
                  cell(
                    pdfTextWidget(
                      h,
                      textDirection: dir,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ]),
            ),
            for (final r in rows)
              pw.TableRow(children: ordered([for (final c in r) cell(c)])),
          ],
        );

    List<List<pw.Widget>> categoryRows(List<CategoryTotal> items) => [
      for (final c in items)
        [
          pdfTextWidget(
            c.category.name,
            textDirection: dir,
            style: const pw.TextStyle(fontSize: 10),
          ),
          amount(c.total),
          pdfTextWidget(
            '${(c.share * 100).toStringAsFixed(1)}%',
            textDirection: pw.TextDirection.ltr,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
    ];

    doc.addPage(
      pw.MultiPage(
        theme: fonts.theme(),
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pdfTextWidget(
                labels.title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pdfTextWidget(
                    labels.appName,
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: _primary,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (owner != null)
                    pdfTextWidget(
                      owner!.label,
                      style: const pw.TextStyle(fontSize: 10, color: _muted),
                    ),
                  if (owner?.phone != null)
                    pdfTextWidget(
                      owner!.phone!,
                      style: const pw.TextStyle(fontSize: 10, color: _muted),
                      textDirection: pw.TextDirection.ltr,
                    ),
                ],
              ),
            ],
          ),
          pdfTextWidget(
            '${labels.period}: ${_range(report)}',
            style: const pw.TextStyle(color: _muted, fontSize: 10),
          ),
          pw.SizedBox(height: 12),
          table(
            [labels.income, labels.expense, labels.net],
            [
              [
                amount(report.income, color: _green, bold: true),
                amount(report.expense, color: _red, bold: true),
                amount(report.net, bold: true),
              ],
            ],
          ),
          pw.SizedBox(height: 16),
          pdfTextWidget(
            labels.monthsComparison,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          table(
            [labels.month, labels.income, labels.expense, labels.net],
            [
              for (final m in report.months)
                [
                  pdfTextWidget(
                    _date(monthFmt, m.month),
                    textDirection: dir,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  amount(m.income),
                  amount(m.expense),
                  amount(m.net),
                ],
            ],
          ),
          if (report.expenseByCategory.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pdfTextWidget(
              labels.expenseByCategory,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            table([
              labels.category,
              labels.amount,
              labels.share,
            ], categoryRows(report.expenseByCategory)),
          ],
          if (report.incomeByCategory.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pdfTextWidget(
              labels.incomeByCategory,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            table([
              labels.category,
              labels.amount,
              labels.share,
            ], categoryRows(report.incomeByCategory)),
          ],
          pw.SizedBox(height: 12),
          pdfTextWidget(
            labels.excludedNote,
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    );
    return doc.save();
  }

  // ---------------------------------------------------------------------------
  // Excel
  // ---------------------------------------------------------------------------

  /// ملف Excel بورقتين: الملخص، وتفاصيل المعاملات في الفترة.
  Uint8List buildExcel(
    PeriodReport report,
    List<TransactionView> transactions,
  ) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();

    final summary = excel[labels.title];
    summary.isRTL = rtl;
    double v(int minor) => money.toDouble(minor);
    TextCellValue t(String s) => TextCellValue(s);

    final who = owner;
    if (who != null) {
      summary.appendRow([t(who.label), if (who.phone != null) t(who.phone!)]);
    }
    summary
      ..appendRow([t(labels.period), t(_range(report))])
      ..appendRow([t(labels.income), DoubleCellValue(v(report.income))])
      ..appendRow([t(labels.expense), DoubleCellValue(v(report.expense))])
      ..appendRow([t(labels.net), DoubleCellValue(v(report.net))])
      ..appendRow([])
      ..appendRow([
        t(labels.month),
        t(labels.income),
        t(labels.expense),
        t(labels.net),
      ]);
    final monthFmt = DateFormat('yyyy-MM');
    for (final m in report.months) {
      summary.appendRow([
        t(_date(monthFmt, m.month)),
        DoubleCellValue(v(m.income)),
        DoubleCellValue(v(m.expense)),
        DoubleCellValue(v(m.net)),
      ]);
    }
    summary
      ..appendRow([])
      ..appendRow([t(labels.expenseByCategory)])
      ..appendRow([t(labels.category), t(labels.amount), t(labels.share)]);
    for (final c in report.expenseByCategory) {
      summary.appendRow([
        t(c.category.name),
        DoubleCellValue(v(c.total)),
        DoubleCellValue(double.parse((c.share * 100).toStringAsFixed(2))),
      ]);
    }

    final details = excel[labels.transactions];
    details.isRTL = rtl;
    details.appendRow([
      t(labels.date),
      t(labels.type),
      t(labels.category),
      t(labels.account),
      t(labels.amount),
      t(labels.note),
    ]);
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    for (final tx in transactions) {
      details.appendRow([
        t(_date(dateFmt, tx.tx.date)),
        t(labels.typeName(tx.type)),
        t(tx.category?.name ?? tx.contactName ?? tx.toAccountName ?? ''),
        // قيود الديون بلا حساب (البيع/الشراء بالآجل، المسامحة) باسم الشخص.
        t(tx.accountName ?? tx.contactName ?? ''),
        DoubleCellValue(
          v(tx.signedAmount == 0 ? tx.tx.amount : tx.signedAmount),
        ),
        t(tx.tx.note ?? ''),
      ]);
    }

    if (defaultSheet != null) excel.delete(defaultSheet);
    excel.setDefaultSheet(labels.title);
    return Uint8List.fromList(excel.encode()!);
  }
}
