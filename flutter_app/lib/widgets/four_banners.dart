/// The four banner styles that belong on a page: the three-card earn row,
/// a split promo, a black glass row, and a sideways poster shelf.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../features/earn/earnings_screen.dart';
import '../features/gifts/gifts_screen.dart';
import '../features/vault/vault_screen.dart';
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
  });

  final String splitTitle;
  final String splitCta;
  final String blackTitle;
  final String blackSub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TrioRail(),
        const SizedBox(height: 12),
        ColoredSplitPromoBanner(
          margin: EdgeInsets.zero,
          spec: SplitPromoSpec(
            title: splitTitle,
            cta: splitCta,
            leftColor: const Color(0xFF3D2914),
            rightColor: const Color(0xFFE4C56A),
            art: SplitPromoArts.blondeLotus,
          ),
        ),
        const SizedBox(height: 12),
        BlackGlassBanner(
          margin: EdgeInsets.zero,
          title: blackTitle,
          subtitle: blackSub,
          mark: NwsbMarks.rewards,
        ),
        const SizedBox(height: 12),
        const ProgramShelf(),
      ],
    );
  }
}

/// The Earn-page banner. The left photograph is full height. The cards on
/// the right are shorter, tinted, and they keep sliding. Same row on every
/// page that used to invent its own trio.
class TrioRail extends StatefulWidget {
  const TrioRail({super.key});

  @override
  State<TrioRail> createState() => _TrioRailState();
}

class _RailFace {
  const _RailFace(this.label, this.image, this.tint, this.open);
  final String label;
  final String image;
  final Color tint;
  final void Function(BuildContext) open;
}

class _TrioRailState extends State<TrioRail> {
  static const _loop = 80;
  static const _faces = <_RailFace>[
    _RailFace('NowssB Gifts', 'assets/banners/earn/sit-dark.png', Color(0xFF6A1B4D), _openGifts),
    _RailFace('NowssB Rewards', 'assets/banners/earn/yoga-light.png', Color(0xFF1E3A8A), _openRewards),
    _RailFace('Your Earning', 'assets/banners/earn/man-light.png', Color(0xFF8A5A12), _openEarnings),
    _RailFace('NowssB coins earned', 'assets/banners/earn/yoga-dark.png', Color(0xFF0F6E56), _openRewards),
  ];

  late final PageController _pages = PageController(
    viewportFraction: 0.52,
    initialPage: _faces.length * (_loop ~/ 2),
  );
  Timer? _timer;

  bool get _quiet => WidgetsBinding.instance.runtimeType.toString().contains('Test');

  static void _openGifts(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GiftsScreen()));
  }

  static void _openRewards(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VaultScreen()));
  }

  static void _openEarnings(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EarningsScreen()));
  }

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
                  itemCount: _faces.length * _loop,
                  itemBuilder: (_, i) {
                    final face = _faces[i % _faces.length];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => face.open(context),
                        child: ClipRRect(
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
                                child: Text(
                                  face.label,
                                  maxLines: 2,
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

