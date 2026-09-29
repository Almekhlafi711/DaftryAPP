// =============================================================================
// الشاشة 12: كشف الحساب ومشاركته (UC-15 / FR-19).
// 1) الفترة: آخر 30 يوماً، هذا الشهر، آخر 3 أشهر، أو مخصص.
// 2) الإخراج: صورة (للكشف القصير) أو PDF (للطويل).
// 3) معاينة بالرصيد الافتتاحي والحركات والمتبقي.
// 4) واتساب / مشاركة / طباعة. لا يُحفظ الكشف داخل التطبيق.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/utils/date_range.dart';
import '../../../domain/enums.dart';
import '../../../domain/models/budget_report_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/export/pdf_fonts.dart';
import '../../../services/export/statement_pdf.dart';
import '../../../services/providers.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/labels.dart';
import '../profile/profile_form.dart';

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
  Future<StatementPdf> _statementPdf(StatementData data) async {
    final l10n = context.l10n;
    final locale = ref.read(localeProvider).languageCode;
    final owner = documentOwner(context, ref);
    final pdf = StatementPdf(
      fonts: await PdfFonts.load(),
      money: ref.read(moneyFormatterProvider),
      locale: locale,
      rtl: locale == 'ar',
      owner: owner,
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
        describe: (direction, line) => _describe(l10n, direction, line),
        sectionTitle: (d) => l10n.directionTitle(d, data.contact.name),
        owedToMeHint: l10n.dueFromPerson(data.contact.name),
        iOweHint: l10n.dueToPerson(data.contact.name),
        noMovements: l10n.noMovementsInPeriod,
        generatedAt: l10n.generatedAt,
      ),
    );
    return pdf;
  }

  Future<void> _export(StatementData data, {required bool print}) async {
    setState(() => _busy = true);
    final share = ref.read(fileShareServiceProvider);
    final l10n = context.l10n;
    final name = 'statement-${data.contact.name}';
    try {
      final statement = await _statementPdf(data);
      if (print) {
        await share.printPdf(await statement.build(data), name);
      } else if (_output == _Output.pdf) {
        await share.share(
          await statement.build(data),
          '$name.pdf',
          mimeType: 'application/pdf',
          text: l10n.statementShareText(data.contact.name),
        );
      } else {
        // صورة بطول الكشف كله (لا تُقصّ أي حركة) بعرض الهاتف.
        final png = await StatementPdf.rasterImage(
          await statement.buildImage(data),
        );
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
      labelStyle: TextStyle(color: _period == p ? c.onPrimary : c.textPrimary),
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
                        // لون واتساب المعروف مع نص أبيض في الوضعين.
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                        ),
                        icon: const FaIcon(FontAwesomeIcons.whatsapp),
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

/// وصف سطر الكشف: نوع الدين (مثل «بيع بالآجل»)، أو الاستلام/السداد، أو
/// المسامحة/الإعفاء.
String _describe(
  AppLocalizations l10n,
  DebtDirection direction,
  StatementLine line,
) => switch (line.kind) {
  StatementLineKind.debt => l10n.debtSourceLabel(line.source!, direction),
  StatementLineKind.payment => l10n.paymentName(direction),
  StatementLineKind.writeOff => l10n.writeOffName(direction),
};

/// معاينة الكشف داخل التطبيق (نفس محتوى الملف المُصدَّر): قسم لكل اتجاه.
class _StatementPreview extends ConsumerWidget {
  const _StatementPreview({required this.data});

  final StatementData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final dates = ref.watch(dateLabelsProvider);
    // الترويسة تحمل اسم المستخدم: «دفتري • سالم محمد».
    final owner = ref.watch(preferencesProvider).value?.userName;
    final head = TextStyle(fontSize: 11.5, color: c.textSecondary);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                owner == null ? l10n.appName : '${l10n.appName} • $owner',
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
          // عناوين الأعمدة: التاريخ، الوصف، الحركة، الرصيد الجاري.
          if (data.sections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(width: 52, child: Text(l10n.date, style: head)),
                  Expanded(child: Text(l10n.description, style: head)),
                  Text(l10n.colMovement, style: head),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: Text(
                      l10n.balance,
                      textAlign: TextAlign.end,
                      style: head,
                    ),
                  ),
                ],
              ),
            ),
          if (data.sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l10n.noMovementsInPeriod,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary),
              ),
            ),
          for (final section in data.sections) ...[
            if (data.sections.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Text(
                  l10n.directionTitle(section.direction, data.contact.name),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: section.direction == DebtDirection.owedToMe
                        ? c.income
                        : c.expense,
                  ),
                ),
              ),
            _line(context, l10n.openingBalance, section.opening, bold: true),
            for (final line in section.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        dates.day(line.date),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        [
                          _describe(l10n, section.direction, line),
                          if (line.note != null) line.note!,
                        ].join(' — '),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    AmountText(
                      line.movement,
                      showSign: true,
                      withSymbol: false,
                      color: line.kind == StatementLineKind.debt
                          ? c.expense
                          : c.income,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // عمود الرصيد الجاري.
                    SizedBox(
                      width: 64,
                      child: AmountText(
                        line.balance,
                        withSymbol: false,
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            if (section.lines.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  l10n.noMovementsInPeriod,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                ),
              ),
            const Divider(),
            _line(
              context,
              l10n.closingBalance,
              section.closing,
              bold: true,
              color: section.direction == DebtDirection.owedToMe
                  ? c.income
                  : c.expense,
            ),
          ],
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
