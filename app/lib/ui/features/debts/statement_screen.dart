// =============================================================================
// الشاشة 12: كشف الحساب ومشاركته (UC-15 / FR-19).
// 1) الفترة: آخر 30 يوماً، هذا الشهر، آخر 3 أشهر، أو مخصص.
// 2) الإخراج: صورة (للكشف القصير) أو PDF (للطويل).
// 3) معاينة بالرصيد الافتتاحي والحركات والمتبقي.
// 4) واتساب / مشاركة / طباعة. لا يُحفظ الكشف داخل التطبيق.
// =============================================================================

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_range.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/budget_report_models.dart';
import '../../../services/export/pdf_fonts.dart';
import '../../../services/export/statement_pdf.dart';
import '../../../services/providers.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';

enum _Period { last30, month, last3Months, custom }

enum _Output { image, pdf }

final _statementProvider = FutureProvider.autoDispose
    .family<StatementData, (int, DateRange)>(
      (ref, key) => ref.watch(statementServiceProvider).build(key.$1, key.$2),
    );

class StatementScreen extends ConsumerStatefulWidget {
  const StatementScreen({super.key, required this.contactId});

  final int contactId;

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  _Period _period = _Period.last3Months;
  DateRange _range = DateRange.lastMonths(3);
  _Output _output = _Output.image;
  bool _busy = false;

  Future<void> _setPeriod(_Period p) async {
    DateRange? range;
    switch (p) {
      case _Period.last30:
        range = DateRange.lastDays(30);
      case _Period.month:
        range = DateRange.month(DateTime.now());
      case _Period.last3Months:
        range = DateRange.lastMonths(3);
      case _Period.custom:
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked == null) return;
        range = DateRange.inclusiveDays(picked.start, picked.end);
    }
    setState(() {
      _period = p;
      _range = range!;
    });
  }

  /// توليد ملف PDF بنصوص لغة المستخدم.
  Future<Uint8List> _buildPdf(StatementData data) async {
    final l10n = context.l10n;
    final locale = ref.read(localeProvider).languageCode;
    final pdf = StatementPdf(
      fonts: await PdfFonts.load(),
      money: ref.read(moneyFormatterProvider),
      locale: locale,
      rtl: locale == 'ar',
      labels: StatementLabels(
        appName: l10n.appName,
        title: l10n.statement,
        period: l10n.period,
        openingBalance: l10n.openingBalance,
        closingBalance: l10n.closingBalance,
        date: l10n.date,
        description: l10n.description,
        amount: l10n.amount,
        balance: l10n.balance,
        newDebt: l10n.newDebtEntry,
        paymentReceived: l10n.paymentReceived,
        paymentMade: l10n.paymentMade,
        owedToMeHint: l10n.dueFromPerson(data.contact.name),
        iOweHint: l10n.dueToPerson(data.contact.name),
        noMovements: l10n.noMovementsInPeriod,
        generatedAt: l10n.generatedAt,
      ),
    );
    return pdf.build(data);
  }

  Future<void> _export(StatementData data, {required bool print}) async {
    setState(() => _busy = true);
    final share = ref.read(fileShareServiceProvider);
    final l10n = context.l10n;
    final name = 'statement-${data.contact.name}';
    try {
      final pdf = await _buildPdf(data);
      if (print) {
        await share.printPdf(pdf, name);
      } else if (_output == _Output.pdf) {
        await share.share(
          pdf,
          '$name.pdf',
          mimeType: 'application/pdf',
          text: l10n.statementShareText(data.contact.name),
        );
      } else {
        final png = await StatementPdf.rasterFirstPage(pdf);
        await share.share(
          png,
          '$name.png',
          mimeType: 'image/png',
          text: l10n.statementShareText(data.contact.name),
        );
      }
    } on Object catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final data = ref.watch(_statementProvider((widget.contactId, _range)));

    Widget chip(_Period p, String label) => ChoiceChip(
      label: Text(label),
      selected: _period == p,
      onSelected: (_) => _setPeriod(p),
      labelStyle: TextStyle(color: _period == p ? Colors.white : c.textPrimary),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data.hasValue
              ? l10n.statementTitle(data.value!.contact.name)
              : l10n.statement,
        ),
      ),
      body: AsyncBody(
        value: data,
        builder: (d) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Insets.screen),
                children: [
                  Text(l10n.period, style: TextStyle(color: c.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      chip(_Period.last30, l10n.periodLast30),
                      chip(_Period.month, l10n.periodMonth),
                      chip(_Period.last3Months, l10n.periodLast3Months),
                      chip(_Period.custom, l10n.periodCustom),
                    ],
                  ),
                  const SizedBox(height: Insets.md),
                  Text(
                    l10n.outputFormat,
                    style: TextStyle(color: c.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _OutputCard(
                          icon: Icons.image_outlined,
                          title: l10n.outputImage,
                          subtitle: l10n.outputImageHint,
                          selected: _output == _Output.image,
                          onTap: () => setState(() => _output = _Output.image),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OutputCard(
                          icon: Icons.picture_as_pdf_outlined,
                          title: l10n.outputPdf,
                          subtitle: l10n.outputPdfHint,
                          selected: _output == _Output.pdf,
                          onTap: () => setState(() => _output = _Output.pdf),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.md),
                  Text(l10n.preview, style: TextStyle(color: c.textSecondary)),
                  const SizedBox(height: 6),
                  _StatementPreview(data: d),
                ],
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Insets.screen),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                        icon: const Icon(Icons.chat_outlined),
                        label: Text(l10n.whatsapp),
                        // يفتح ورقة المشاركة ويظهر فيها واتساب.
                        onPressed: _busy
                            ? null
                            : () => _export(d, print: false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: l10n.share,
                      icon: const Icon(Icons.share_outlined),
                      onPressed: _busy ? null : () => _export(d, print: false),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      tooltip: l10n.print,
                      icon: const Icon(Icons.print_outlined),
                      onPressed: _busy ? null : () => _export(d, print: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      color: selected ? c.primary.withValues(alpha: 0.08) : null,
      child: Column(
        children: [
          Icon(icon, color: selected ? c.primary : c.textSecondary),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11.5, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// معاينة الكشف داخل التطبيق (نفس محتوى الملف المُصدَّر).
class _StatementPreview extends ConsumerWidget {
  const _StatementPreview({required this.data});

  final StatementData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final dates = ref.watch(dateLabelsProvider);
    final closing = data.closingBalance;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.appName,
                style: TextStyle(color: c.primary, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '${data.contact.name} • ${dates.monthShort(data.range.start)} – '
                  '${dates.month(data.range.end.subtract(const Duration(days: 1)))}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                ),
              ),
            ],
          ),
          Divider(color: c.primary, thickness: 2, height: 16),
          _line(context, l10n.openingBalance, data.openingBalance, bold: true),
          for (final line in data.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      dates.day(line.date),
                      style: TextStyle(fontSize: 11.5, color: c.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line.isPayment
                          ? (line.direction == DebtDirection.owedToMe
                                ? l10n.paymentReceived
                                : l10n.paymentMade)
                          : (line.note ?? l10n.newDebtEntry),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  AmountText(
                    line.effect,
                    showSign: true,
                    withSymbol: false,
                    color: line.isPayment ? c.income : c.expense,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          if (data.lines.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.noMovementsInPeriod,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary),
              ),
            ),
          const Divider(),
          _line(
            context,
            l10n.closingBalance,
            closing.abs(),
            bold: true,
            color: closing >= 0 ? c.income : c.expense,
          ),
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context,
    String label,
    int value, {
    bool bold = false,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        AmountText(
          value,
          color: color,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
