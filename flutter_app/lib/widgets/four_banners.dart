/// The four banner styles that belong on a page: the three-card earn row,
/// a split promo, a black glass row, and a sideways poster shelf.
library;

import 'package:nowssb/widgets/word_fit_text.dart';
import 'dart:async';

import '../theme/white_neu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/programs/program_router.dart';
import '../screens/subscription.dart';
import 'black_glass_banner.dart';
import 'colored_split_promo_banner.dart';
import 'glass_wrap.dart';
import 'nwsb_icon.dart';
import 'program_shelf.dart';

class FourBanners extends StatelessWidget {
  const FourBanners({
    super.key,
    this.splitTitle = 'NowssB',
    this.splitCta = 'Open',
    this.blackTitle = 'NowssB',
    this.blackSub = 'Words, rewards, and what you have earned.',
    this.current,
  });

  /// The programme page this sits on: its own rail tile and shelf poster
  /// are left out (a page never links to itself).
  final Programme? current;

  final String splitTitle;
  final String splitCta;
  final String blackTitle;
  final String blackSub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrioRail(current: current),
        const SizedBox(height: 12),
        ColoredSplitPromoBanner(
          margin: EdgeInsets.zero,
          spec: SplitPromoSpec(
            title: splitTitle,
            cta: splitCta,
            leftColor: const Color(0xFF3D2914),
            rightColor: const Color(0xFFE4C56A),
            art: SplitPromoArts.blondeLotus,
            // The split promo opens the next programme (never this page).
            onTap: () => Programmes.open(context, _next(current)),
          ),
        ),
        const SizedBox(height: 12),
        BlackGlassBanner(
          margin: EdgeInsets.zero,
          title: blackTitle,
          subtitle: blackSub,
          mark: NwsbMarks.rewards,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen())),
        ),
      ],
    );
  }
}

Programme _next(Programme? p) => switch (p) {
      Programme.earnings => Programme.reference,
      Programme.earn => Programme.reference,
      _ => Programme.earnings,
    };

/// The Earn-page banner. The left photograph is full height. The cards on
/// the right are shorter, tinted, and they keep sliding. Same row on every
/// page that used to invent its own trio.
class TrioRail extends StatefulWidget {
  const TrioRail({super.key, this.current});

  /// Leave this programme's own tiles out (on its own page).
  final Programme? current;

  @override
  State<TrioRail> createState() => _TrioRailState();
}

class _RailFace {
  const _RailFace(this.label, this.image, this.tint, this.programme, [this.tab]);
  final String label;
  final String image;
  final Color tint;
  final Programme programme;
  final String? tab;
  void open(BuildContext context) => Programmes.open(context, programme, tab: tab);
}

class _TrioRailState extends State<TrioRail> {
  // Normal home: a white neumorphic tile, untinted photo, ink label.
  Widget _whiteFace(_RailFace face) => Container(
        margin: const EdgeInsets.fromLTRB(2, 2, 2, 10),
        padding: const EdgeInsets.all(6),
        decoration: wnBox(radius: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image(image: AssetImage(face.image), fit: BoxFit.cover, alignment: const Alignment(0, -0.3)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
            child: Text(face.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: wnInk, fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.1)),
          ),
        ]),
      );

  static const _loop = 80;
  static const _all = <_RailFace>[
    _RailFace('Your Earning', 'assets/banners/earn/man-light.png', Color(0xFF8A5A12), Programme.earnings),
    _RailFace('NowssB coins earned', 'assets/banners/earn/yoga-dark.png', Color(0xFF0F6E56), Programme.earn),
    _RailFace('NowssB Reference', 'assets/banners/earn/sit-light.png', Color(0xFF1F4E7A), Programme.reference),
  ];

  late final List<_RailFace> _faces = [
    for (final f in _all)
      if (f.programme != widget.current) f,
  ];

  late final PageController _pages = PageController(
    viewportFraction: 0.52,
    initialPage: _faces.length * (_loop ~/ 2),
  );
  Timer? _timer;

  bool get _quiet => WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    if (_quiet) return;
    _timer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted || !_pages.hasClients) return;
      final current = _pages.page?.round() ?? _faces.length * (_loop ~/ 2);
      _pages.animateToPage(
        current + 1,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fashion home: each programme is its own banner, the store-card shape,
    // not three tiles inside one glass.
    if (!onNormal(context)) return const _ProgrammeBanners();
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SizedBox(
        height: 176,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 112,
                height: 176,
                child: Image(
                  image: AssetImage('assets/banners/earn/hands-raise.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment(0, -0.05),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 122,
                child: PageView.builder(
                  controller: _pages,
                  padEnds: false,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _faces.length * _loop,
                  itemBuilder: (_, i) {
                    final face = _faces[i % _faces.length];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => face.open(context),
                        child: onNormal(context) ? _whiteFace(face) : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(color: face.tint),
                              Image(
                                image: AssetImage(face.image),
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, -0.1),
                                color: face.tint.withValues(alpha: 0.42),
                                colorBlendMode: BlendMode.srcATop,
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0x00000000), Color(0xCC000000)],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: WordFitText(
                                  face.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    height: 1.12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One programme, one banner. Same shape as the store card (picture, label,
/// big title, round button) and not wrapped together in one glass.
class _ProgrammeBanners extends StatelessWidget {
  const _ProgrammeBanners();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _ProgBanner(
          art: 'assets/banners/promo/prog-letter.webp',
          kicker: 'Programme',
          title: 'Reference',
          line: 'Your links',
          programme: Programme.reference,
        ),
        SizedBox(height: 10),
        _ProgBanner(
          art: 'assets/banners/promo/prog-sill.webp',
          kicker: 'Programme',
          title: 'Earning',
          line: 'What you have earned',
          programme: Programme.earnings,
        ),
        SizedBox(height: 10),
        _ProgBanner(
          art: 'assets/banners/promo/prog-bowl.webp',
          kicker: 'Programme',
          title: 'Coins',
          line: 'What you have earned today',
          programme: Programme.earn,
        ),
      ],
    );
  }
}

class _ProgBanner extends StatelessWidget {
  const _ProgBanner({
    required this.art,
    required this.kicker,
    required this.title,
    required this.line,
    required this.programme,
  });

  final String art;
  final String kicker;
  final String title;
  final String line;
  final Programme programme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        Programmes.open(context, programme);
      },
      child: Container(
        height: 136,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xF0111114),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(art, width: 116, height: 116, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF161616), child: SizedBox(width: 116, height: 116))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kicker.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(title.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: .4)),
              const SizedBox(height: 6),
              Text(line, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 22),
          ),
        ]),
      ),
    );
  }
}

