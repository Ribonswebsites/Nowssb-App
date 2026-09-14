/// Normal-home promo rail — Store · Player · Earn · Streak.
///
/// White neumorphism (or white glass when Normal Glass is on). Horizontal
/// auto-scroll carousel. Every tile uses the same layout:
/// circle SVG | vertical divider | bold title + subtitle | arrow.
/// Animation only changes scroll position — never colors or styles.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import 'glassmorphism_theme.dart';

class NormalPromoRail extends StatefulWidget {
  const NormalPromoRail({
    super.key,
    required this.onStore,
    required this.onPlayer,
    required this.onEarn,
    required this.onStreak,
  });

  final VoidCallback onStore;
  final VoidCallback onPlayer;
  final VoidCallback onEarn;
  final VoidCallback onStreak;

  @override
  State<NormalPromoRail> createState() => _NormalPromoRailState();
}

class _NormalPromoRailState extends State<NormalPromoRail> {
  late final PageController _page;
  Timer? _timer;
  var _index = 0;

  List<_PromoTile> get _tiles => [
        _PromoTile(
          title: 'Store',
          subtitle: 'Words that heal',
          mark: NwsbMarks.bag,
          onTap: widget.onStore,
        ),
        _PromoTile(
          title: 'Player',
          subtitle: 'Your word ritual',
          mark: NwsbMarks.play,
          markViewBox: 22,
          onTap: widget.onPlayer,
        ),
        _PromoTile(
          title: 'Earn',
          subtitle: 'Grow with NowssB',
          mark: NwsbMarks.earn,
          onTap: widget.onEarn,
        ),
        _PromoTile(
          title: 'Streak',
          subtitle: 'Keep your healing streak alive',
          mark: NwsbMarks.flame,
          onTap: widget.onStreak,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.92);
    _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      final next = (_index + 1) % _tiles.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context);
    final tiles = _tiles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              'More ways to keep your rhythm',
              style: TextStyle(
                color: NwsbColors.inkSoft,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
          ),
          SizedBox(
            height: 108,
            child: PageView.builder(
              controller: _page,
              itemCount: tiles.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _WhitePromoBanner(tile: tiles[i], glass: glass),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < tiles.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: i == _index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? NwsbColors.gold
                          : const Color(0x332B2D33),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoTile {
  const _PromoTile({
    required this.title,
    required this.subtitle,
    required this.mark,
    required this.onTap,
    this.markViewBox = 24,
  });

  final String title;
  final String subtitle;
  final String mark;
  final double markViewBox;
  final VoidCallback onTap;
}

/// White neu / white glass banner — circle SVG | vertical rule | title+sub.
/// Identical chrome for every tile (no rainbow / color-cycling rings).
class _WhitePromoBanner extends StatelessWidget {
  const _WhitePromoBanner({required this.tile, required this.glass});

  final _PromoTile tile;
  final bool glass;

  static const double _circle = 52;
  static const double _icon = 22;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return GestureDetector(
      onTap: tile.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 96,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: glass ? const Color(0xD9FFFFFF) : const Color(0xFFF2F3F7),
          borderRadius: radius,
          border: glass
              ? Border.all(color: const Color(0xF2FFFFFF), width: 1.5)
              : null,
          boxShadow: glass
              ? null
              : const [
                  BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 16,
                      offset: Offset(7, 7)),
                  BoxShadow(
                      color: Color(0xF7FFFFFF),
                      blurRadius: 12,
                      offset: Offset(-5, -5)),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: _circle,
              height: _circle,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: glass
                      ? const Color(0x33FFFFFF)
                      : const Color(0x14FFFFFF),
                ),
                boxShadow: glass
                    ? const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : const [
                        BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 10,
                            offset: Offset(3, 3)),
                        BoxShadow(
                            color: Color(0xF2FFFFFF),
                            blurRadius: 8,
                            offset: Offset(-3, -3)),
                      ],
              ),
              child: Center(
                child: NwsbIcon(
                  tile.mark,
                  size: _icon,
                  viewBox: tile.markViewBox,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 36, color: const Color(0x332B2D33)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tile.title,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tile.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0x992B2D33),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF060C18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small semantic hooks for focused widget tests.
class NormalPromoRailLabels {
  static const store = 'Store';
  static const player = 'Player';
  static const earn = 'Earn';
  static const streak = 'Streak';
}
