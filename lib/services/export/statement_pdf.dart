// =============================================================================
// توليد كشف حساب الشخص كملف PDF أو صورة PNG (UC-15 / الشاشة 12).
// لكل اتجاه (لي / عليّ) قسم مستقل: رصيد افتتاحي، ثم الحركات بعمود رصيد
// جارٍ، ثم الرصيد الختامي — ولا يُخصم أحد الاتجاهين من الآخر.
//
// - PDF بصفحات A4 (للطباعة والكشوف الطويلة).
// - صورة لواتساب بتصميم مخصص للهاتف: صفحة واحدة بعرض 1080 بكسل وطول يتسع
//   لكل الحركات (لا تُقصّ أي حركة مهما طال الكشف)، بترتيب واضح: الترويسة
//   (دفتري • صاحب الدفتر) ← الشخص والفترة ← لكل اتجاه: الافتتاحي ← جدول
//   (التاريخ | البيان | الحركة | الرصيد) بصفوف متناوبة ← الختامي = المتبقي.
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
import 'document_owner.dart';
import 'pdf_fonts.dart';
import 'pdf_text.dart';

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
    required this.describe,
    required this.sectionTitle,
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

  /// وصف السطر بلغة المستخدم (مثل «بيع بالآجل» أو «استلام» أو «مسامحة»).
  final String Function(DebtDirection direction, StatementLine line) describe;

  /// عنوان قسم الاتجاه (مثل «لي عند أحمد»).
  final String Function(DebtDirection direction) sectionTitle;

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
    this.owner,
  });

  final PdfFonts fonts;
  final StatementLabels labels;
  final MoneyFormatter money;
  final String locale;
  final bool rtl;

  /// صاحب الدفتر (اسمه ورقمه) في ترويسة الكشف.
  final DocumentOwner? owner;

  /// أرقام التواريخ تتبع إعداد الأرقام (intl يكتب العربية بالأرقام الهندية افتراضياً).
  String _date(DateFormat format, DateTime d) {
    final text = format.format(d);
    return money.useArabicDigits ? text : MoneyParser.normalizeDigits(text);
  }

  /// تاريخ رقمي (1/8/2026): لا يختلط باسم الشهر العربي، فلا تضيع المسافات
  /// أو يختل الترتيب عند مزج الأرقام بالنص العربي في ملفات PDF.
  String _numericDate(DateTime d) => _date(DateFormat('d/M/y', locale), d);

  pw.TextDirection get _dir =>
      rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  /// جداول مكتبة PDF تُرتَّب دائماً من اليسار: نعكس الأعمدة في العربية حتى
  /// يكون «التاريخ» أول عمود من اليمين.
  List<T> _ordered<T>(List<T> cells) => rtl ? cells.reversed.toList() : cells;

  Map<int, pw.TableColumnWidth> _widths(List<pw.TableColumnWidth> logical) {
    final list = _ordered(logical);
    return {for (var i = 0; i < list.length; i++) i: list[i]};
  }

  /// نص خلية بالاتجاه الصحيح (الجداول لا ترث اتجاه الصفحة).
  pw.Widget _cellText(String text, {pw.TextStyle? style, int? maxLines}) =>
      pdfTextWidget(
        text,
        textDirection: _dir,
        textAlign: rtl ? pw.TextAlign.right : pw.TextAlign.left,
        maxLines: maxLines,
        style: style,
      );

  static const _primary = PdfColor.fromInt(0xFF0F766E);
  static const _green = PdfColor.fromInt(0xFF15803D);
  static const _red = PdfColor.fromInt(0xFFDC2626);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _line = PdfColor.fromInt(0xFFE2E8F0);
  static const _onPrimary = PdfColor.fromInt(0xFFD1FAF4);
  static const _headerFill = PdfColor.fromInt(0xFFF1F5F9);
  static const _zebra = PdfColor.fromInt(0xFFF8FAFC);
  static const _greenFill = PdfColor.fromInt(0xFFF0FDF4);
  static const _redFill = PdfColor.fromInt(0xFFFEF2F2);

  Future<Uint8List> build(StatementData data) async {
    final doc = pw.Document(title: '${labels.title} — ${data.contact.name}');
    final dir = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final range =
        '${_numericDate(data.range.start)} — '
        '${_numericDate(data.range.end.subtract(const Duration(days: 1)))}';

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
            pdfTextWidget(
              '${labels.generatedAt}: ${_numericDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pdfTextWidget(
              '${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
        build: (ctx) => [
          if (data.sections.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Center(
                child: pdfTextWidget(
                  labels.noMovements,
                  style: const pw.TextStyle(color: _muted),
                ),
              ),
            ),
          for (final section in data.sections) ...[
            if (data.sections.length > 1)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pdfTextWidget(
                  labels.sectionTitle(section.direction),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: section.direction == DebtDirection.owedToMe
                        ? _green
                        : _red,
                  ),
                ),
              ),
            _summaryRow(labels.openingBalance, section.opening),
            pw.SizedBox(height: 8),
            if (section.lines.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Center(
                  child: pdfTextWidget(
                    labels.noMovements,
                    style: const pw.TextStyle(color: _muted),
                  ),
                ),
              )
            else
              _table(section),
            pw.SizedBox(height: 12),
            _closing(section),
            pw.SizedBox(height: 18),
          ],
        ],
      ),
    );
    return doc.save();
  }

  // ---------------------------------------------------------------------------
  // الصورة (واتساب)
  // ---------------------------------------------------------------------------

  /// عرض صفحة الصورة بالنقاط: 360 نقطة × 3 (216 dpi) = 1080 بكسل.
  static const imageWidth = 360.0;
  static const imageDpi = 216.0;

  /// كشف بصفحة واحدة بعرض الهاتف وطول يتسع لكل الحركات (تُحوَّل إلى صورة
  /// بـ [rasterImage]).
  Future<Uint8List> buildImage(StatementData data) async {
    final doc = pw.Document(title: '${labels.title} — ${data.contact.name}');
    final dir = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final rowDate = DateFormat.MMMd(locale);
    final range =
        '${_numericDate(data.range.start)} — '
        '${_numericDate(data.range.end.subtract(const Duration(days: 1)))}';

    doc.addPage(
      pw.Page(
        theme: fonts.theme(),
        textDirection: dir,
        // الطول غير محدود: الصفحة تتسع للمحتوى كله.
        pageFormat: const PdfPageFormat(imageWidth, double.infinity),
        build: (ctx) => pw.Container(
          color: PdfColors.white,
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _imageHeader(range),
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pdfTextWidget(
                      data.contact.name,
                      style: pw.TextStyle(
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (data.contact.phone != null)
                      pdfTextWidget(
                        data.contact.phone!,
                        textDirection: pw.TextDirection.ltr,
                        style: const pw.TextStyle(fontSize: 10, color: _muted),
                      ),
                  ],
                ),
              ),
              if (data.sections.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.all(24),
                  child: pw.Center(
                    child: pdfTextWidget(
                      labels.noMovements,
                      style: const pw.TextStyle(color: _muted),
                    ),
                  ),
                ),
              for (final section in data.sections)
                _imageSection(section, rowDate),
              _imageFooter(),
            ],
          ),
        ),
      ),
    );
    return doc.save();
  }

  pw.Widget _imageHeader(String range) => pw.Container(
    color: _primary,
    padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pdfTextWidget(
                labels.appName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              if (owner != null)
                pdfTextWidget(
                  owner!.label,
                  style: const pw.TextStyle(fontSize: 10, color: _onPrimary),
                ),
              if (owner?.phone != null)
                pdfTextWidget(
                  owner!.phone!,
                  textDirection: pw.TextDirection.ltr,
                  style: const pw.TextStyle(fontSize: 10, color: _onPrimary),
                ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pdfTextWidget(
              labels.title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pdfTextWidget(
              '${labels.period}: $range',
              style: const pw.TextStyle(fontSize: 9, color: _onPrimary),
            ),
          ],
        ),
      ],
    ),
  );

  pw.Widget _imageSection(StatementSection section, DateFormat rowDate) {
    final owedToMe = section.direction == DebtDirection.owedToMe;
    final accent = owedToMe ? _green : _red;
    final head = pw.TextStyle(
      fontSize: 8.5,
      fontWeight: pw.FontWeight.bold,
      color: _muted,
    );
    pw.Widget cell(pw.Widget child) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Align(
        alignment: rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: child,
      ),
    );
    final symbol = money.symbol;

    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pdfTextWidget(
            labels.sectionTitle(section.direction),
            style: pw.TextStyle(
              fontSize: 12.5,
              fontWeight: pw.FontWeight.bold,
              color: accent,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pdfTextWidget(
                labels.openingBalance,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              _amount(section.opening, bold: true, size: 10.5),
            ],
          ),
          pw.SizedBox(height: 6),
          if (section.lines.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Center(
                child: pdfTextWidget(
                  labels.noMovements,
                  style: const pw.TextStyle(fontSize: 10, color: _muted),
                ),
              ),
            )
          else
            pw.Table(
              columnWidths: _widths(const [
                pw.FixedColumnWidth(58),
                pw.FlexColumnWidth(),
                pw.FixedColumnWidth(76),
                pw.FixedColumnWidth(76),
              ]),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _headerFill),
                  children: _ordered([
                    cell(_cellText(labels.date, style: head)),
                    cell(_cellText(labels.description, style: head)),
                    cell(_cellText('${labels.amount} ($symbol)', style: head)),
                    cell(_cellText('${labels.balance} ($symbol)', style: head)),
                  ]),
                ),
                for (final (i, line) in section.lines.indexed)
                  pw.TableRow(
                    // صفوف متناوبة الخلفية لسهولة تتبّع السطر بالعين.
                    decoration: pw.BoxDecoration(
                      color: i.isOdd ? _zebra : PdfColors.white,
                    ),
                    children: _ordered([
                      cell(
                        _cellText(
                          _date(rowDate, line.date),
                          style: const pw.TextStyle(fontSize: 9, color: _muted),
                        ),
                      ),
                      cell(
                        _cellText(
                          [
                            labels.describe(section.direction, line),
                            if (line.note != null) line.note!,
                          ].join(' — '),
                          maxLines: 2,
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                      ),
                      cell(
                        _amount(
                          line.movement,
                          size: 9.5,
                          bold: true,
                          signed: true,
                          withSymbol: false,
                          color: line.kind == StatementLineKind.debt
                              ? _red
                              : _green,
                        ),
                      ),
                      cell(_amount(line.balance, size: 9.5, withSymbol: false)),
                    ]),
                  ),
              ],
            ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: owedToMe ? _greenFill : _redFill,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pdfTextWidget(
                        labels.closingBalance,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      if (section.closing != 0)
                        pdfTextWidget(
                          owedToMe ? labels.owedToMeHint : labels.iOweHint,
                          style: const pw.TextStyle(fontSize: 9, color: _muted),
                        ),
                    ],
                  ),
                ),
                _amount(section.closing, bold: true, size: 15, color: accent),
              ],
            ),
          ),
          pw.SizedBox(height: 6),
        ],
      ),
    );
  }

  pw.Widget _imageFooter() => pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    padding: const pw.EdgeInsets.fromLTRB(16, 8, 16, 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _line)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pdfTextWidget(
          '${labels.generatedAt}: ${_numericDate(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
        pdfTextWidget(
          labels.appName,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
      ],
    ),
  );

  /// يحوّل كشف [buildImage] (صفحة واحدة بطول المحتوى) إلى صورة PNG واضحة
  /// بعرض 1080 بكسل — مناسبة لواتساب دون قصّ أي حركة.
  static Future<Uint8List> rasterImage(
    Uint8List pdf, {
    double dpi = imageDpi,
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
            pdfTextWidget(
              '${labels.title} — ${data.contact.name}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            if (data.contact.phone != null)
              pdfTextWidget(
                data.contact.phone!,
                style: const pw.TextStyle(fontSize: 10, color: _muted),
                textDirection: pw.TextDirection.ltr,
              ),
            pdfTextWidget(
              '${labels.period}: $range',
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            ),
          ],
        ),
        _brand(labels.appName, owner),
      ],
    ),
  );

  /// اسم التطبيق وتحته صاحب الدفتر ورقمه.
  static pw.Widget _brand(String appName, DocumentOwner? owner) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pdfTextWidget(
        appName,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: _primary,
        ),
      ),
      if (owner != null)
        pdfTextWidget(
          owner.label,
          style: const pw.TextStyle(fontSize: 10, color: _muted),
        ),
      if (owner?.phone != null)
        pdfTextWidget(
          owner!.phone!,
          style: const pw.TextStyle(fontSize: 10, color: _muted),
          textDirection: pw.TextDirection.ltr,
        ),
    ],
  );

  pw.Widget _summaryRow(String label, int value) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pdfTextWidget(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      _amount(value, bold: true),
    ],
  );

  pw.Widget _table(StatementSection section) {
    // التاريخ مختصر بالأرقام (1/8/2026) لوضوحه داخل الجدول.
    final dateFmt = DateFormat('d/M/y', locale);
    final headerStyle = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    pw.Widget cell(pw.Widget child) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Align(
        alignment: rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: child,
      ),
    );

    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
      ),
      columnWidths: _widths(const [
        pw.FlexColumnWidth(1.3),
        pw.FlexColumnWidth(3),
        pw.FlexColumnWidth(1.6),
        pw.FlexColumnWidth(1.6),
      ]),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: _ordered([
            cell(_cellText(labels.date, style: headerStyle)),
            cell(_cellText(labels.description, style: headerStyle)),
            cell(_cellText(labels.amount, style: headerStyle)),
            cell(_cellText(labels.balance, style: headerStyle)),
          ]),
        ),
        for (final line in section.lines)
          pw.TableRow(
            children: _ordered([
              cell(
                _cellText(
                  _date(dateFmt, line.date),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              cell(
                _cellText(
                  [
                    labels.describe(section.direction, line),
                    if (line.note != null) line.note!,
                  ].join(' — '),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              cell(
                _amount(
                  line.movement,
                  size: 9,
                  signed: true,
                  color: line.kind == StatementLineKind.debt ? _red : _green,
                ),
              ),
              cell(_amount(line.balance, size: 9)),
            ]),
          ),
      ],
    );
  }

  pw.Widget _closing(StatementSection section) {
    final value = section.closing;
    final owedToMe = section.direction == DebtDirection.owedToMe;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: owedToMe ? _greenFill : _redFill,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pdfTextWidget(
                labels.closingBalance,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              if (value != 0)
                pdfTextWidget(
                  owedToMe ? labels.owedToMeHint : labels.iOweHint,
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                ),
            ],
          ),
          _amount(value, bold: true, size: 14, color: owedToMe ? _green : _red),
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
    bool withSymbol = true,
    PdfColor? color,
  }) => pdfTextWidget(
    money.format(value, withSymbol: withSymbol, showSign: signed),
    textDirection: pw.TextDirection.ltr,
    style: pw.TextStyle(
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    ),
  );
}
