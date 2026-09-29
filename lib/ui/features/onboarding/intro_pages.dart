// =============================================================================
// شاشات الترحيب الثلاث قبل الإعداد الأول (الأشكال 4-4 إلى 4-6 في الوثيقة):
//   1) الفكرة: «دفترك المالي في جيبك» مع بطاقات الرصيد والمعاملة والميزانية.
//   2) الديون: «ديونك منظمة… وحقك محفوظ» مع قائمة الأشخاص والكشف والاستلام.
//   3) الخصوصية والخطوات: «خصوصية كاملة وبداية سهلة» والخطوات الثلاث.
// أعلى الشاشة بلون الهوية ورسومات أصلية، وأسفلها لوحة بيضاء مستديرة فيها
// العنوان والشرح ومؤشر الصفحات وزر «التالي» / «ابدأ الآن». زر «تخطي» في
// الأعلى، والتنقل بالسحب أو بالزر. ولا تزيد الشاشات على ثلاث.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      (
        art: const _BalanceArt(),
        title: l10n.intro1Title,
        body: l10n.intro1Body,
      ),
      (art: const _DebtsArt(), title: l10n.intro2Title, body: l10n.intro2Body),
      (
        art: const _PrivacyArt(),
        title: l10n.intro3Title,
        body: l10n.intro3Body,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.surface,
        body: Stack(
          children: [
            // خلفية الهوية بدوائر شفافة ناعمة.
            Positioned.fill(child: _BrandBackground(color: c.brand)),
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      Insets.xl,
                      Insets.sm,
                      Insets.sm,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Theme(
                          data: Theme.of(context).copyWith(
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ),
                          child: widget.topAction,
                        ),
                        // يبقى مكانه محجوزاً في الصفحة الأخيرة حتى لا يقفز.
                        Visibility(
                          visible: !_last,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withValues(
                                alpha: 0.85,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: widget.onDone,
                            child: Text(l10n.introSkip),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _count,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _Slide(
                      art: slides[i].art,
                      title: slides[i].title,
                      body: slides[i].body,
                    ),
                  ),
                ),
                // الجزء الثابت من اللوحة البيضاء: المؤشر والزر.
                ColoredBox(
                  color: c.surface,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Insets.xl,
                        Insets.sm,
                        Insets.xl,
                        Insets.lg,
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
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _BrandBackground extends StatelessWidget {
  const _BrandBackground({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget circle(double size, double alpha) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.08)!,
            Color.lerp(color, Colors.black, 0.3)!,
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          PositionedDirectional(top: -90, end: -60, child: circle(300, 0.06)),
          PositionedDirectional(top: 300, start: -80, child: circle(220, 0.05)),
        ],
      ),
    );
  }
}

/// صفحة واحدة: الرسم في الأعلى، ثم بداية اللوحة البيضاء بالعنوان والشرح.
class _Slide extends StatelessWidget {
  const _Slide({required this.art, required this.title, required this.body});

  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
            // الرسم مصمم بمقاس ثابت ويُصغَّر في الشاشات الصغيرة.
            child: FittedBox(
              child: SizedBox(width: 320, height: 300, child: art),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            Insets.xl,
            Insets.xl,
            Insets.xl,
            Insets.sm,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, height: 1.35),
              ),
              const SizedBox(height: Insets.sm),
              Text(
                body,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: Insets.md),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// الرسومات: بطاقات مصغّرة مائلة قليلاً فوق لون الهوية.
// ----------------------------------------------------------------------------

/// بطاقة بيضاء مائلة بظل خفيف.
class _ArtCard extends StatelessWidget {
  const _ArtCard({
    required this.child,
    this.angle = 0,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final double angle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    ),
  );
}

/// أرقام الرسومات تُعرض من اليسار لليمين دائماً.
Text _num(String text, {Color? color, double size = 14}) => Text(
  text,
  textDirection: TextDirection.ltr,
  style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w700),
);

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: LinearProgressIndicator(
      value: value,
      minHeight: 7,
      color: color,
      backgroundColor: context.colors.surfaceMuted,
    ),
  );
}

/// الشاشة 1: الرصيد، معاملة، الميزانية.
class _BalanceArt extends StatelessWidget {
  const _BalanceArt();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    Widget chip(String label, String amount, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.tint(color),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, color: color)),
            _num(amount, color: color, size: 13),
          ],
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 30,
          child: _ArtCard(
            angle: -0.04,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.introSampleBalance,
                  style: TextStyle(fontSize: 11, color: c.textSecondary),
                ),
                _num('24,850.00', size: 24, color: c.textPrimary),
                const SizedBox(height: 8),
                Row(
                  children: [
                    chip(l10n.introSampleIncome, '+12,000', c.income),
                    const SizedBox(width: 8),
                    chip(l10n.introSampleExpense, '-6,420', c.expense),
                  ],
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 150,
          start: -6,
          end: 70,
          child: _ArtCard(
            angle: 0.03,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.tint(c.expense),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: c.expense,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.introSampleShop,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        l10n.introSampleFood,
                        style: TextStyle(fontSize: 11, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                _num('-245', color: c.expense, size: 16),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 232,
          start: 50,
          end: 20,
          child: _ArtCard(
            angle: -0.02,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      l10n.budgetTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _num('63%', color: c.textSecondary, size: 11),
                  ],
                ),
                const SizedBox(height: 6),
                _MiniBar(value: 0.63, color: c.income),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// الشاشة 2: قائمة الأشخاص بنسب السداد، كشف حساب، واستلام موزّع.
class _DebtsArt extends StatelessWidget {
  const _DebtsArt();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final people = [
      (l10n.introSamplePerson1, '1,500', 0.2),
      (l10n.introSamplePerson2, '650', 0.0),
      (l10n.introSamplePerson3, '1,200', 0.25),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 20,
          child: _ArtCard(
            angle: -0.03,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                for (final (i, (name, amount, progress)) in people.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: c.tint(c.primary),
                          child: Text(
                            name.characters.first,
                            style: TextStyle(
                              color: c.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _MiniBar(value: progress, color: c.income),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _num(amount, color: c.income, size: 13),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 168,
          end: -4,
          width: 178,
          child: _ArtCard(
            angle: 0.04,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      color: c.expense,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.introSampleStatement,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${l10n.introSamplePerson1} • PDF',
                            style: TextStyle(
                              fontSize: 10,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: c.income,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.share,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 232,
          start: 6,
          width: 160,
          child: _ArtCard(
            angle: -0.05,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.check_rounded, color: c.income, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.introSampleReceive,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        l10n.introSampleSplit,
                        style: TextStyle(fontSize: 9.5, color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// الشاشة 3: درع الخصوصية والخطوات الثلاث.
class _PrivacyArt extends StatelessWidget {
  const _PrivacyArt();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final steps = [
      l10n.introStepName,
      l10n.introStepCurrency,
      l10n.introStepFirstTx,
    ];
    return Column(
      children: [
        Container(
          width: 118,
          height: 118,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(36),
          ),
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: c.primary,
              size: 40,
            ),
          ),
        ),
        const Spacer(),
        _ArtCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              for (final (i, step) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.brand,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
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
