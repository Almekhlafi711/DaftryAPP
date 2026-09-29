// اختبارات التصدير: كشف الحساب PDF، والتقرير PDF و Excel (بخط عربي مضمَّن).
import 'dart:convert';
import 'dart:io';

import 'package:daftry/core/money/money.dart';
import 'package:daftry/core/utils/date_range.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/budget_report_models.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:daftry/domain/models/transaction_models.dart';
import 'package:daftry/services/export/document_owner.dart';
import 'package:daftry/services/export/pdf_fonts.dart';
import 'package:daftry/services/export/report_exporter.dart';
import 'package:daftry/services/export/statement_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestEnv env;
  final money = MoneyFormatter(decimals: 2, symbol: 'ر.س');

  setUpAll(initializeDateFormatting);
  setUp(() async => env = await TestEnv.create());
  tearDown(() => env.dispose());

  test('كشف الحساب يُولَّد PDF بالعربية', () async {
    final cash = await env.cash;
    final contact = await env.contacts.create(
      name: 'أحمد علي',
      phone: '0551234567',
    );
    await env.debts.createDebt(
      DebtDraft(
        contactId: contact,
        direction: DebtDirection.owedToMe,
        source: DebtSource.loan,
        amount: 120000,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        accountId: cash.id,
        note: 'سلفة جهاز',
      ),
    );
    await env.debts.recordPayment(
      PaymentDraft(
        contactId: contact,
        direction: DebtDirection.owedToMe,
        amount: 50000,
        paidAt: DateTime.now(),
        accountId: cash.id,
      ),
    );
    final data = await env.statements.build(contact, DateRange.lastDays(30));

    final pdf = await StatementPdf(
      fonts: await PdfFonts.load(),
      money: money,
      locale: 'ar',
      rtl: true,
      owner: const DocumentOwner(
        label: 'صادر من: محمد',
        phone: '+967777953434',
      ),
      labels: StatementLabels(
        appName: 'دفتري',
        title: 'كشف حساب',
        period: 'الفترة',
        openingBalance: 'الرصيد الافتتاحي',
        closingBalance: 'الرصيد الختامي = المتبقي',
        date: 'التاريخ',
        description: 'البيان',
        amount: 'المبلغ',
        balance: 'الرصيد',
        describe: (direction, line) => line.kind.name,
        sectionTitle: (direction) => direction.name,
        owedToMeHint: 'المستحق على أحمد',
        iOweHint: 'المستحق لأحمد',
        noMovements: 'لا توجد حركات',
        generatedAt: 'أُنشئ في',
      ),
    ).build(data);

    expect(ascii.decode(pdf.sublist(0, 4)), '%PDF');
    expect(pdf.length, greaterThan(1000));
  });

  test('التقرير يُصدَّر PDF و Excel', () async {
    final cash = await env.cash;
    final food = await env.category(CategoryKind.expense);
    final salary = await env.category(CategoryKind.income);
    await env.transactions.add(
      TransactionDraft(
        type: TxType.income,
        amount: 1200000,
        accountId: cash.id,
        categoryId: salary.id,
        date: DateTime.now(),
      ),
    );
    await env.transactions.add(
      TransactionDraft(
        type: TxType.expense,
        amount: 24500,
        accountId: cash.id,
        categoryId: food.id,
        date: DateTime.now(),
        note: 'سوبرماركت',
      ),
    );
    final range = DateRange.month(DateTime.now());
    final report = await env.reports.report(range);
    final exporter = ReportExporter(
      money: money,
      locale: 'ar',
      rtl: true,
      owner: const DocumentOwner(label: 'صادر من: محمد'),
      labels: ReportLabels(
        appName: 'دفتري',
        title: 'تقرير',
        period: 'الفترة',
        income: 'الدخل',
        expense: 'المصروف',
        net: 'الصافي',
        month: 'الشهر',
        category: 'الفئة',
        share: 'النسبة',
        expenseByCategory: 'المصروف حسب الفئة',
        incomeByCategory: 'الدخل حسب الفئة',
        monthsComparison: 'مقارنة الأشهر',
        transactions: 'المعاملات',
        date: 'التاريخ',
        type: 'النوع',
        account: 'الحساب',
        amount: 'المبلغ',
        note: 'ملاحظة',
        typeName: (t) => t.name,
        excludedNote: 'حركات الديون مستبعدة',
      ),
    );

    final pdf = await exporter.buildPdf(report, await PdfFonts.load());
    expect(ascii.decode(pdf.sublist(0, 4)), '%PDF');
    final out = Platform.environment['REPORT_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(pdf);

    final txs = await env.transactions.getFiltered(
      TransactionFilter(range: range),
    );
    final xlsx = exporter.buildExcel(report, txs);
    // ملف xlsx هو أرشيف ZIP يبدأ بالحرفين PK.
    expect(ascii.decode(xlsx.sublist(0, 2)), 'PK');
  });

  test('صورة واتساب: صفحة واحدة بعرض الهاتف تتسع لكل الحركات', () async {
    final cash = await env.cash;
    final contact = await env.contacts.create(
      name: 'أحمد علي',
      phone: '0551234567',
    );
    final start = DateTime.now().subtract(const Duration(days: 40));
    // 40 حركة: أكثر مما تتسع له صفحة A4 واحدة.
    for (var i = 0; i < 20; i++) {
      final id = await env.debts.createDebt(
        DebtDraft(
          contactId: contact,
          direction: DebtDirection.owedToMe,
          source: i.isEven ? DebtSource.loan : DebtSource.opening,
          amount: 100000 + i * 12345,
          startDate: start.add(Duration(days: i)),
          accountId: i.isEven ? cash.id : null,
          note: i % 3 == 0 ? 'بضاعة رقم $i' : null,
        ),
      );
      await env.debts.recordPayment(
        PaymentDraft(
          contactId: contact,
          direction: DebtDirection.owedToMe,
          debtId: id,
          amount: 40000,
          paidAt: start.add(Duration(days: i, hours: 3)),
          accountId: cash.id,
        ),
      );
    }
    await env.debts.createDebt(
      DebtDraft(
        contactId: contact,
        direction: DebtDirection.iOwe,
        source: DebtSource.opening,
        amount: 15000,
        startDate: start,
      ),
    );
    final data = await env.statements.build(contact, DateRange.lastDays(60));
    final statement = StatementPdf(
      fonts: await PdfFonts.load(),
      money: money,
      locale: 'ar',
      rtl: true,
      owner: const DocumentOwner(
        label: 'صادر من: سالم محمد',
        phone: '+967777953434',
      ),
      labels: StatementLabels(
        appName: 'دفتري',
        title: 'كشف حساب',
        period: 'الفترة',
        openingBalance: 'الرصيد الافتتاحي',
        closingBalance: 'الرصيد الختامي = المتبقي',
        date: 'التاريخ',
        description: 'البيان',
        amount: 'الحركة',
        balance: 'الرصيد',
        describe: (direction, line) => switch (line.kind) {
          StatementLineKind.debt => 'سلفة نقدية',
          StatementLineKind.payment => 'استلام',
          StatementLineKind.writeOff => 'مسامحة',
        },
        sectionTitle: (d) => d == DebtDirection.owedToMe
            ? 'المتبقي لي عند أحمد علي'
            : 'المتبقي عليّ لـ أحمد علي',
        owedToMeHint: 'المستحق على أحمد',
        iOweHint: 'المستحق لأحمد',
        noMovements: 'لا توجد حركات',
        generatedAt: 'أُنشئ في',
      ),
    );
    final image = await statement.buildImage(data);
    final text = latin1.decode(image);
    // صفحة واحدة فقط، بعرض 360 نقطة (1080 بكسل عند 216 dpi) وطول أكبر من A4.
    expect(RegExp(r'/Type\s*/Page\b').allMatches(text), hasLength(1));
    final box = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]')
        .firstMatch(text)!;
    expect(double.parse(box.group(1)!), StatementPdf.imageWidth);
    expect(double.parse(box.group(2)!), greaterThan(842));
    // مقارنة: ملف A4 يحتاج أكثر من صفحة لنفس الحركات.
    final a4 = latin1.decode(await statement.build(data));
    expect(RegExp(r'/Type\s*/Page\b').allMatches(a4).length, greaterThan(1));
    // لحفظ الملف ومعاينته: STATEMENT_IMAGE_OUT=/مسار/ملف.pdf
    final out = Platform.environment['STATEMENT_IMAGE_OUT'];
    if (out != null) {
      File(out).writeAsBytesSync(image);
      File('$out.a4.pdf').writeAsBytesSync(await statement.build(data));
    }
  });
}
