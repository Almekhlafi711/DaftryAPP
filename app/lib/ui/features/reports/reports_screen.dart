// =============================================================================
// الشاشة 15: التقارير (FR-23).
// ملخص الفترة، مقارنة ستة أشهر (أو أشهر السنة)، توزيع المصروف حسب الفئات،
// مع التصدير إلى PDF و Excel. حركات الديون والتسويات مستبعدة من هذه الأرقام.
//
// الرسوم (fl_chart): أعمدة رفيعة بحواف علوية مستديرة 4 وفجوة 2 بين العمودين،
// شبكة أفقية خفيفة، وسيلة إيضاح دائمة، وتلميح عند اللمس. ألوان الدخل/المصروف
// مُتحقق منها لعمى الألوان (الوضع الداكن بدرجات خاصة به).
// =============================================================================

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_range.dart';
import '../../../domain/models/budget_report_models.dart';
import '../../../domain/models/transaction_models.dart';
import '../../../services/export/pdf_fonts.dart';
import '../../../services/export/report_exporter.dart';
import '../../../services/providers.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/labels.dart';

enum _View { monthly, yearly }

final _reportProvider = StreamProvider.autoDispose
    .family<PeriodReport, (DateRange, int)>(
      (ref, key) =>
          ref.watch(reportServiceProvider).watchReport(key.$1, months: key.$2),
    );

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _View _view = _View.monthly;
  DateTime _anchor = DateTime.now();
  bool _exporting = false;

  DateRange get _range => _view == _View.monthly
      ? DateRange.month(_anchor)
      : DateRange.year(_anchor);

  int get _months => _view == _View.monthly ? 6 : 12;

  void _shift(int delta) => setState(() {
    _anchor = _view == _View.monthly
        ? DateTime(_anchor.year, _anchor.month + delta)
        : DateTime(_anchor.year + delta, _anchor.month);
  });

  Future<void> _export(PeriodReport report, {required bool excel}) async {
    setState(() => _exporting = true);
    final l10n = context.l10n;
    final locale = ref.read(localeProvider).languageCode;
    final exporter = ReportExporter(
      money: ref.read(moneyFormatterProvider),
      locale: locale,
      rtl: locale == 'ar',
      labels: ReportLabels(
        appName: l10n.appName,
        title: l10n.reportTitle,
        period: l10n.period,
        income: l10n.income,
        expense: l10n.expense,
        net: l10n.net,
        month: l10n.month,
        category: l10n.category,
        share: l10n.shareOfTotal,
        expenseByCategory: l10n.expenseByCategory,
        incomeByCategory: l10n.incomeByCategory,
        monthsComparison: l10n.incomeVsExpense,
        transactions: l10n.transactions,
        date: l10n.date,
        type: l10n.type,
        account: l10n.account,
        amount: l10n.amount,
        note: l10n.note,
        typeName: l10n.txTypeName,
        excludedNote: l10n.reportsExcludedNote,
      ),
    );
    final share = ref.read(fileShareServiceProvider);
    final stamp =
        '${_range.start.year}-${_range.start.month.toString().padLeft(2, '0')}';
    try {
      if (excel) {
        final txs = await ref
            .read(transactionServiceProvider)
            .getFiltered(
              TransactionFilter(range: _range, sort: TransactionSort.oldest),
              amountFactor: ref.read(moneyParserProvider).factor,
            );
        await share.share(
          exporter.buildExcel(report, txs),
          'daftari-report-$stamp.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      } else {
        await share.share(
          await exporter.buildPdf(report, await PdfFonts.load()),
          'daftari-report-$stamp.pdf',
          mimeType: 'application/pdf',
        );
      }
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final dates = ref.watch(dateLabelsProvider);
    final report = ref.watch(_reportProvider((_range, _months)));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: AsyncBody(
        value: report,
        builder: (r) => ListView(
          padding: const EdgeInsets.all(Insets.screen),
          children: [
            SegmentedTabs<_View>(
              values: _View.values,
              selected: _view,
              label: (v) =>
                  v == _View.monthly ? l10n.monthlyView : l10n.yearlyView,
              onChanged: (v) => setState(() => _view = v),
            ),
            const SizedBox(height: Insets.sm),
            // التنقل بين الفترات — الأسهم تتبع اتجاه اللغة تلقائياً.
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _shift(-1),
                ),
                Expanded(
                  child: Text(
                    _view == _View.monthly
                        ? dates.month(_anchor)
                        : '${_anchor.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => _shift(1),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: l10n.income,
                    value: r.income,
                    color: c.income,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    label: l10n.expense,
                    value: r.expense,
                    color: c.expense,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    label: l10n.net,
                    value: r.net,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.incomeVsExpense,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _Legend(
                    items: [
                      (l10n.income, _chartIncome(context)),
                      (l10n.expense, _chartExpense(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: _MonthsBarChart(months: r.months),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.md),
            if (r.expenseByCategory.isNotEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.expenseByCategory,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _CategoryDonut(items: r.expenseByCategory),
                  ],
                ),
              ),
            const SizedBox(height: Insets.md),
            if (_exporting) const LinearProgressIndicator(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Excel'),
                    onPressed: _exporting
                        ? null
                        : () => _export(r, excel: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF'),
                    onPressed: _exporting
                        ? null
                        : () => _export(r, excel: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            Text(
              l10n.reportsExcludedNote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// ألوان الأعمدة: الفاتح من لوحة الوثيقة؛ الداكن بدرجات مُتحقق منها للوضع الداكن.
Color _chartIncome(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF16A34A)
    : const Color(0xFF15803D);

Color _chartExpense(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFF66D75)
    : const Color(0xFFDC2626);

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        ),
        AmountText(
          value,
          withSymbol: false,
          compact: true,
          color: color,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ],
    ),
  );
}

/// وسيلة إيضاح: مربع لون بجانب نص بلون النص (الهوية لا تعتمد على اللون وحده).
class _Legend extends StatelessWidget {
  const _Legend({required this.items});

  final List<(String, Color)> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 6,
    children: [
      for (final (label, color) in items)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
    ],
  );
}

class _MonthsBarChart extends ConsumerWidget {
  const _MonthsBarChart({required this.months});

  final List<MonthTotals> months;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;
    final money = ref.watch(moneyFormatterProvider);
    final dates = ref.watch(dateLabelsProvider);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // في العربية يسير الزمن من اليمين لليسار: الأحدث على اليسار.
    final data = rtl ? months.reversed.toList() : months;
    final maxValue = data.fold<int>(
      0,
      (m, e) => math.max(m, math.max(e.income, e.expense)),
    );
    final maxY = maxValue == 0 ? 1.0 : money.toDouble(maxValue) * 1.15;
    final income = _chartIncome(context);
    final expense = _chartExpense(context);
    final barWidth = data.length > 6 ? 7.0 : 11.0;

    BarChartRodData rod(int v, Color color) => BarChartRodData(
      toY: money.toDouble(v),
      color: color,
      width: barWidth,
      // حافة علوية مستديرة، وقاعدة مربعة عند خط الصفر.
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: c.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  // لا نكرر تسمية الحد الأعلى إن لم تكن على خطوة الشبكة.
                  if (value == meta.max && value % meta.appliedInterval != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _compact(value),
                      style: TextStyle(fontSize: 10, color: c.textSecondary),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      dates.monthShort(data[i].month),
                      style: TextStyle(fontSize: 10.5, color: c.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => c.textPrimary,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                '${dates.monthShort(data[groupIndex].month)}\n'
                '${rodIndex == 0 ? l10n.income : l10n.expense}: '
                '${money.format(rodIndex == 0 ? data[groupIndex].income : data[groupIndex].expense, compact: true)}',
                TextStyle(
                  color: c.surface,
                  fontSize: 12,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 2,
                barRods: [
                  rod(data[i].income, income),
                  rod(data[i].expense, expense),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// تنسيق مختصر لمحور القيم: 1.5K ، 12K ، 1.2M
  static String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}K';
    return v.toStringAsFixed(0);
  }
}

/// حلقة توزيع المصروف: أكبر 4 فئات + «أخرى» — مع قائمة بالأسماء والنسب
/// والمبالغ (الهوية لا تعتمد على اللون وحده، والقائمة تعمل كجدول).
class _CategoryDonut extends ConsumerWidget {
  const _CategoryDonut({required this.items});

  final List<CategoryTotal> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = context.l10n;
    final top = items.take(4).toList();
    final rest = items.skip(4).fold<int>(0, (s, e) => s + e.total);
    final restShare = items.skip(4).fold<double>(0, (s, e) => s + e.share);
    final slices = [
      for (final t in top)
        (
          t.category.name,
          Color(t.category.color),
          t.total,
          t.share,
          AppIcons.category(t.category.icon),
        ),
      if (rest > 0)
        (l10n.more, c.textSecondary, rest, restShare, Icons.more_horiz_rounded),
    ];

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 50,
              sectionsSpace: 2, // فجوة بلون السطح بين الشرائح
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.$3.toDouble(),
                    color: s.$2,
                    radius: 24,
                    showTitle: false,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final s in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.$2,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(s.$5, size: 18, color: c.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text(s.$1)),
                Text(
                  '${(s.$4 * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(width: 12),
                AmountText(
                  s.$3,
                  withSymbol: false,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
