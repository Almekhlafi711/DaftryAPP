// =============================================================================
// شاشات الترحيب الثلاث قبل الإعداد الأول:
//   1) التعريف بالتطبيق وخصوصيته.
//   2) أهم المزايا.
//   3) الخطوات المهمة (العملة لا تتغير، القفل، النسخ الاحتياطي).
// تُعرض قبل إدخال الاسم واختيار العملة، ويمكن تخطيها.
// =============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class IntroPages extends StatefulWidget {
  const IntroPages({super.key, required this.onDone, required this.topAction});

  /// عند الضغط على «ابدأ الآن» أو «تخطي».
  final VoidCallback onDone;

  /// زر أعلى الشاشة (تبديل اللغة).
  final Widget topAction;

  @override
  State<IntroPages> createState() => _IntroPagesState();
}

class _IntroPagesState extends State<IntroPages> {
  static const _count = 3;
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _last => _page == _count - 1;

  void _next() {
    if (_last) return widget.onDone();
    _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;

    final slides = [
      _Slide(
        icon: Icons.menu_book_rounded,
        bubbles: const [
          Icons.account_balance_wallet_rounded,
          Icons.handshake_rounded,
        ],
        chips: [
          (Icons.wifi_off_rounded, l10n.introOffline),
          (Icons.person_off_outlined, l10n.introNoAccount),
          (Icons.verified_user_outlined, l10n.introPrivate),
        ],
        title: l10n.welcomeTitle,
        body: l10n.intro1Body,
      ),
      _Slide(
        icon: Icons.auto_awesome_rounded,
        bubbles: const [
          Icons.receipt_long_rounded,
          Icons.pie_chart_rounded,
          Icons.notifications_active_rounded,
          Icons.picture_as_pdf_rounded,
        ],
        title: l10n.intro2Title,
        body: l10n.intro2Body,
        details: [
          _FeatureRow(
            icon: Icons.swap_horiz_rounded,
            color: c.primary,
            title: l10n.featTxTitle,
            body: l10n.featTxBody,
          ),
          _FeatureRow(
            icon: Icons.handshake_outlined,
            color: c.warning,
            title: l10n.featDebtsTitle,
            body: l10n.featDebtsBody,
          ),
          _FeatureRow(
            icon: Icons.bar_chart_rounded,
            color: c.transfer,
            title: l10n.featBudgetTitle,
            body: l10n.featBudgetBody,
          ),
          _FeatureRow(
            icon: Icons.ios_share_rounded,
            color: c.income,
            title: l10n.featStatementTitle,
            body: l10n.featStatementBody,
          ),
        ],
      ),
      _Slide(
        icon: Icons.rocket_launch_rounded,
        bubbles: const [
          Icons.currency_exchange_rounded,
          Icons.fingerprint_rounded,
          Icons.lock_rounded,
          Icons.cloud_done_rounded,
        ],
        title: l10n.intro3Title,
        body: l10n.intro3Body,
        details: [
          _StepRow(
            number: 1,
            title: l10n.stepCurrencyTitle,
            body: l10n.currencyWarning,
          ),
          _StepRow(
            number: 2,
            title: l10n.stepLockTitle,
            body: l10n.stepLockBody,
          ),
          _StepRow(
            number: 3,
            title: l10n.stepBackupTitle,
            body: l10n.stepBackupBody,
          ),
        ],
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  widget.topAction,
                  const Spacer(),
                  // يبقى مكانه محجوزاً في الصفحة الأخيرة حتى لا يقفز التصميم.
                  Visibility(
                    visible: !_last,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: widget.onDone,
                      child: Text(l10n.introSkip),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _count,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    // مدى ابتعاد الصفحة عن المنتصف (0 = ظاهرة بالكامل).
                    final page = _controller.hasClients
                        ? (_controller.page ?? _page.toDouble())
                        : _page.toDouble();
                    final delta = (page - i).abs().clamp(0.0, 1.0);
                    return Opacity(opacity: 1 - delta * 0.6, child: child);
                  },
                  child: slides[i],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.screen,
                Insets.md,
                Insets.screen,
                Insets.screen,
              ),
              child: Column(
                children: [
                  _Dots(count: _count, active: _page),
                  const SizedBox(height: Insets.lg),
                  FilledButton(
                    onPressed: _next,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_last ? l10n.introStart : l10n.introNext),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// صفحة واحدة: لوحة ملونة في الأعلى، ثم العنوان والشرح والتفاصيل.
class _Slide extends StatelessWidget {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    this.bubbles = const [],
    this.chips = const [],
    this.details = const [],
  });

  final IconData icon;
  final String title;
  final String body;
  final List<IconData> bubbles;
  final List<(IconData, String)> chips;
  final List<Widget> details;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Insets.screen,
        Insets.sm,
        Insets.screen,
        Insets.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Hero(icon: icon, bubbles: bubbles, chips: chips),
          const SizedBox(height: Insets.xl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 15, height: 1.6),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: Insets.lg),
            for (final d in details)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: d),
          ],
        ],
      ),
    );
  }
}

/// اللوحة الملونة: أيقونة كبيرة داخل حلقات شفافة، وأيقونات صغيرة حولها،
/// وشارات قصيرة في الأسفل (للصفحة الأولى).
class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.bubbles, required this.chips});

  final IconData icon;
  final List<IconData> bubbles;
  final List<(IconData, String)> chips;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // مواضع ثابتة للأيقونات الصغيرة في الزوايا بعيداً عن الأيقونة الكبيرة.
    const spots = [
      (top: 22.0, start: 26.0, bottom: null, end: null),
      (top: 34.0, start: null, bottom: null, end: 30.0),
      (top: null, start: 40.0, bottom: 30.0, end: null),
      (top: null, start: null, bottom: 24.0, end: 38.0),
    ];
    Widget circle(double size, double alpha) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );

    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.lerp(c.brand, Colors.white, 0.12)!,
            c.brand,
            Color.lerp(c.brand, Colors.black, 0.35)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: c.brand.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            PositionedDirectional(top: -70, end: -50, child: circle(190, 0.07)),
            PositionedDirectional(
              bottom: -80,
              start: -60,
              child: circle(210, 0.06),
            ),
            for (var i = 0; i < bubbles.length && i < spots.length; i++)
              PositionedDirectional(
                top: spots[i].top,
                start: spots[i].start,
                bottom: spots[i].bottom,
                end: spots[i].end,
                child: _Bubble(icon: bubbles[i]),
              ),
            Column(
              children: [
                Expanded(
                  child: Center(
                    // دخول ناعم مرة واحدة عند ظهور الصفحة.
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.85, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      builder: (_, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: c.brand, size: 42),
                        ),
                      ),
                    ),
                  ),
                ),
                if (chips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (icon, label) in chips)
                          _Chip(icon: icon, label: label),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
    ),
    child: Icon(icon, color: Colors.white, size: 22),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.brand),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c.brand,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ميزة: أيقونة ملونة + عنوان + وصف قصير.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        IconBadge(icon: icon, color: color, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: _TitleBody(title: title, body: body),
        ),
      ],
    ),
  );
}

/// خطوة مرقّمة.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.body,
  });

  final int number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TitleBody(title: title, body: body),
          ),
        ],
      ),
    );
  }
}

class _TitleBody extends StatelessWidget {
  const _TitleBody({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(
        body,
        style: TextStyle(
          color: context.colors.textSecondary,
          fontSize: 12.5,
          height: 1.5,
        ),
      ),
    ],
  );
}

/// مؤشر الصفحات: نقطة ممتدة للصفحة الحالية.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? c.primary : c.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}
