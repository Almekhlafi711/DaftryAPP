// اختبارات التصدير: كشف الحساب PDF، والتقرير PDF و Excel (بخط عربي مضمَّن).
import 'dart:convert';

import 'package:daftry/core/money/money.dart';
import 'package:daftry/core/utils/date_range.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:daftry/domain/models/transaction_models.dart';
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
    final debt = await env.debts.createDebt(
      DebtDraft(
        contactId: contact,
        direction: DebtDirection.owedToMe,
        amount: 120000,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        accountId: cash.id,
        note: 'سلفة جهاز',
      ),
    );
    await env.debts.recordPayment(
      debt,
      PaymentDraft(amount: 50000, paidAt: DateTime.now()),
    );
    final data = await env.statements.build(contact, DateRange.lastDays(30));

    final pdf = await StatementPdf(
      fonts: await PdfFonts.load(),
      money: money,
      locale: 'ar',
      rtl: true,
      labels: const StatementLabels(
        appName: 'دفتري',
        title: 'كشف حساب',
        period: 'الفترة',
        openingBalance: 'الرصيد الافتتاحي',
        closingBalance: 'المتبقي',
        date: 'التاريخ',
        description: 'البيان',
        amount: 'المبلغ',
        balance: 'الرصيد',
        newDebt: 'دين جديد',
        paymentReceived: 'دفعة مستلمة',
        paymentMade: 'دفعة مدفوعة',
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

    final txs = await env.transactions.getFiltered(
      TransactionFilter(range: range),
    );
    final xlsx = exporter.buildExcel(report, txs);
    // ملف xlsx هو أرشيف ZIP يبدأ بالحرفين PK.
    expect(ascii.decode(xlsx.sublist(0, 2)), 'PK');
  });
}
