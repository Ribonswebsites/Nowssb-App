/// The four banner styles that belong on a page: the three-card earn row,
/// a split promo, a black glass row, and a sideways poster shelf.
library;

import 'dart:async';

import 'package:flutter/material.dart';

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
        const SizedBox(height: 12),
        ProgramShelf(current: current),
      ],
    );
  }
}

Programme _next(Programme? p) => switch (p) {
      Programme.coupons => Programme.gifts,
      Programme.gifts => Programme.rewards,
      Programme.rewards => Programme.coupons,
      Programme.reference => Programme.partner,
      Programme.partner => Programme.reference,
      Programme.earn => Programme.reference,
      _ => Programme.rewards,
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
  const _RailFace(this.label, this.mark, this.programme, [this.tab]);
  final String label;
  final String mark;
  final Programme programme;
  final String? tab;
  void open(BuildContext context) => Programmes.open(context, programme, tab: tab);
}

class _TrioRailState extends State<TrioRail> {
  static const _loop = 80;
  static const _all = <_RailFace>[
    _RailFace('NowssB Gifts', NwsbMarks.gift, Programme.gifts),
    _RailFace('NowssB Rewards', NwsbMarks.rewards, Programme.rewards),
    _RailFace('Your Earning', NwsbMarks.piggy, Programme.earnings),
    _RailFace('Coins earned', NwsbMarks.earn, Programme.rewards, 'wallet'),
    _RailFace('NowssB Coupons', NwsbMarks.coupon, Programme.coupons),
    _RailFace('Reference', NwsbMarks.reference, Programme.reference),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            'Your programs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.05,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        GlassWrap(
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
                      image: AssetImage('assets/banners/earn/yoga-light.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment(0, -0.15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 132,
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
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF000000),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0x33FFFFFF)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: NwsbIcon(
                                        face.mark,
                                        size: 20,
                                        color: const Color(0xFF0A0A0C),
                                        strokeWidth: 1.8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      face.label,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        height: 1.12,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
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
        ),
      ],
    );
  }
}

