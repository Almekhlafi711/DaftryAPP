// =============================================================================
// توليد كشف حساب الشخص كملف PDF أو صورة PNG (UC-15 / الشاشة 12).
//
// صورة للكشف القصير (مناسبة لواتساب) و PDF للطويل. الصورة تُولَّد من صفحة
// PDF نفسها (Raster) فيكون التصميم واحداً في الحالتين.
// الهدف غير الوظيفي: كشف 100 حركة في أقل من 3 ثوانٍ.
// =============================================================================

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/money/money.dart';
import '../../domain/enums.dart';
import '../../domain/models/budget_report_models.dart';
import 'pdf_fonts.dart';

/// نصوص الكشف بلغة المستخدم (تُملأ من ملفات الترجمة في طبقة الواجهة).
class StatementLabels {
  const StatementLabels({
    required this.appName,
    required this.title,
    required this.period,
    required this.openingBalance,
    required this.closingBalance,
    required this.date,
    required this.description,
    required this.amount,
    required this.balance,
    required this.newDebt,
    required this.paymentReceived,
    required this.paymentMade,
    required this.owedToMeHint,
    required this.iOweHint,
    required this.noMovements,
    required this.generatedAt,
  });

  final String appName;
  final String title;
  final String period;
  final String openingBalance;
  final String closingBalance;
  final String date;
  final String description;
  final String amount;
  final String balance;
  final String newDebt;
  final String paymentReceived;
  final String paymentMade;

  /// شرح الرصيد الموجب (مثل «المتبقي لي عند الشخص»).
  final String owedToMeHint;

  /// شرح الرصيد السالب (مثل «المتبقي عليّ للشخص»).
  final String iOweHint;
  final String noMovements;
  final String generatedAt;
}

class StatementPdf {
  StatementPdf({
    required this.fonts,
    required this.labels,
    required this.money,
    required this.locale,
    required this.rtl,
  });

  final PdfFonts fonts;
  final StatementLabels labels;
  final MoneyFormatter money;
  final String locale;
  final bool rtl;

  /// أرقام التواريخ تتبع إعداد الأرقام (intl يكتب العربية بالأرقام الهندية افتراضياً).
  String _date(DateFormat format, DateTime d) {
    final text = format.format(d);
    return money.useArabicDigits ? text : MoneyParser.normalizeDigits(text);
  }

  static const _primary = PdfColor.fromInt(0xFF0F766E);
  static const _green = PdfColor.fromInt(0xFF15803D);
  static const _red = PdfColor.fromInt(0xFFDC2626);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _line = PdfColor.fromInt(0xFFE2E8F0);

  Future<Uint8List> build(StatementData data) async {
    final doc = pw.Document(title: '${labels.title} — ${data.contact.name}');
    final dir = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final dateFmt = DateFormat.yMMMd(locale);
    final range =
        '${_date(dateFmt, data.range.start)} — '
        '${_date(dateFmt, data.range.end.subtract(const Duration(days: 1)))}';

    doc.addPage(
      pw.MultiPage(
        theme: fonts.theme(),
        textDirection: dir,
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 28,
          marginRight: 28,
          marginTop: 28,
          marginBottom: 28,
        ),
        header: (ctx) => _header(data, range),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${labels.generatedAt}: ${_date(DateFormat.yMMMd(locale).add_Hm(), DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Text(
              '${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
        build: (ctx) => [
          _summaryRow(labels.openingBalance, data.openingBalance),
          pw.SizedBox(height: 8),
          if (data.lines.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Center(
                child: pw.Text(
                  labels.noMovements,
                  style: const pw.TextStyle(color: _muted),
                ),
              ),
            )
          else
            _table(data, dateFmt),
          pw.SizedBox(height: 12),
          _closing(data),
        ],
      ),
    );
    return doc.save();
  }

  /// صورة PNG من الصفحة الأولى (للكشف القصير ومشاركته عبر واتساب).
  static Future<Uint8List> rasterFirstPage(
    Uint8List pdf, {
    double dpi = 160,
  }) async {
    final page = await Printing.raster(pdf, pages: const [0], dpi: dpi).first;
    return page.toPng();
  }

  pw.Widget _header(StatementData data, String range) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.only(bottom: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${labels.title} — ${data.contact.name}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (data.contact.phone != null)
              pw.Text(
                data.contact.phone!,
                style: const pw.TextStyle(fontSize: 10, color: _muted),
                textDirection: pw.TextDirection.ltr,
              ),
            pw.Text(
              '${labels.period}: $range',
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            ),
          ],
        ),
        pw.Text(
          labels.appName,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
      ],
    ),
  );

  pw.Widget _summaryRow(String label, int value) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      _amount(value, bold: true),
    ],
  );

  pw.Widget _table(StatementData data, DateFormat dateFmt) {
    final headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    pw.Widget cell(pw.Widget child) =>
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: child);

    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.6),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: [
            cell(pw.Text(labels.date, style: headerStyle)),
            cell(pw.Text(labels.description, style: headerStyle)),
            cell(pw.Text(labels.amount, style: headerStyle)),
            cell(pw.Text(labels.balance, style: headerStyle)),
          ],
        ),
        for (final line in data.lines)
          pw.TableRow(
            children: [
              cell(
                pw.Text(
                  _date(dateFmt, line.date),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              cell(
                pw.Text(
                  [
                    line.isPayment
                        ? (line.direction == DebtDirection.owedToMe
                              ? labels.paymentReceived
                              : labels.paymentMade)
                        : labels.newDebt,
                    if (line.note != null) line.note!,
                  ].join(' — '),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              cell(
                _amount(
                  line.effect,
                  size: 9,
                  signed: true,
                  color: line.isPayment ? _green : _red,
                ),
              ),
              cell(_amount(line.runningBalance, size: 9)),
            ],
          ),
      ],
    );
  }

  pw.Widget _closing(StatementData data) {
    final value = data.closingBalance;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF0FDF4),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                labels.closingBalance,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              if (value != 0)
                pw.Text(
                  value > 0 ? labels.owedToMeHint : labels.iOweHint,
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                ),
            ],
          ),
          _amount(
            value.abs(),
            bold: true,
            size: 14,
            color: value >= 0 ? _green : _red,
          ),
        ],
      ),
    );
  }

  /// الأرقام تُكتب دائماً من اليسار لليمين داخل النص العربي.
  pw.Widget _amount(
    int value, {
    bool bold = false,
    double size = 11,
    bool signed = false,
    PdfColor? color,
  }) => pw.Text(
    money.format(value, withSymbol: true, showSign: signed),
    textDirection: pw.TextDirection.ltr,
    style: pw.TextStyle(
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    ),
  );
}
