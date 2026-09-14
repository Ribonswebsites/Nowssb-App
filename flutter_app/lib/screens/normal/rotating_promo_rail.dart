/// Normal-home promo rail — Store · Player · Earn · Streak.
///
/// White neumorphism (or white glass when Normal Glass is on). One focused
/// tile at a time, auto-advancing. Each tile is circle SVG | divider | copy.
/// The Streak page also shows the streak film directly under its banner,
/// outside any white section wrapper.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import 'glassmorphism_theme.dart';

/// Streak film — same asset as [NmStreakVideo] / website herovid.
const kStreakPromoVideo =
    'assets/videos/415dd447da33973b_grok_video_2026-07-30-14-35-05_q3tyzk.mp4';

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
          showStreakVideo: true,
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
    final focused = tiles[_index];

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
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: SizedBox(
            height: focused.showStreakVideo ? 268 : 108,
            child: PageView.builder(
              controller: _page,
              itemCount: tiles.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final tile = tiles[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WhitePromoBanner(tile: tile, glass: glass),
                      if (tile.showStreakVideo) ...[
                        const SizedBox(height: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: tile.onTap,
                            behavior: HitTestBehavior.opaque,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              clipBehavior: Clip.antiAlias,
                              child: const ColoredBox(
                                color: Colors.black,
                                child: NwsbVideo(
                                  asset: kStreakPromoVideo,
                                  priority: ClipPriority.decoration,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
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
    this.showStreakVideo = false,
  });

  final String title;
  final String subtitle;
  final String mark;
  final double markViewBox;
  final VoidCallback onTap;
  final bool showStreakVideo;
}

/// White neu / white glass banner — circle SVG | vertical rule | title+sub.
class _WhitePromoBanner extends StatelessWidget {
  const _WhitePromoBanner({required this.tile, required this.glass});

  final _PromoTile tile;
  final bool glass;

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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: glass
                    ? null
                    : const [
                        BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 8,
                            offset: Offset(2, 2)),
                      ],
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Center(
                child: NwsbIcon(
                  tile.mark,
                  size: 22,
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
