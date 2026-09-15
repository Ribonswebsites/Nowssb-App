/// Today's Practice — 3-card horizontal carousel (Player → Healing → Device).
///
/// Used inside [FashPractice] / [NmPractice]. No separate "START TODAY" section.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/nwsb_icon.dart';

/// Horizontal 3-card practice carousel for the single Today's Practice block.
///
/// Card 1: [playerCard] — TODAY'S PRACTICE / NowssB Player (swirl + Enter).
/// Card 2: healing kickoff copy with icon | divider | text rows.
/// Card 3: NowssB player device graphic + white-circle SVG (top-right).
class PracticeCarousel extends StatefulWidget {
  const PracticeCarousel({
    super.key,
    required this.playerCard,
    this.onTap,
    this.fashion = false,
    this.aspectRatio = 16 / 9,
    this.height,
  });

  /// Card 1 — Fashion / Normal player UI exactly as built by the parent.
  final Widget playerCard;
  final VoidCallback? onTap;
  final bool fashion;

  /// Used when [height] is null (Fashion media cards).
  final double aspectRatio;

  /// Fixed viewport height (Normal neu player). Overrides [aspectRatio].
  final double? height;

  /// Legacy art (demoted — no longer a carousel page).
  static const practiceArt = 'assets/coach/aarogya-personal-coach.png';

  /// Player / headphone device graphic used on Card 3.
  static const playerDeviceArt = 'assets/store/nowssb-bag-headphones.webp';

  @override
  State<PracticeCarousel> createState() => _PracticeCarouselState();
}

class _PracticeCarouselState extends State<PracticeCarousel> {
  late final PageController _page;
  Timer? _timer;
  var _index = 0;

  static const _cardCount = 3;

  @override
  void initState() {
    super.initState();
    _page = PageController();
    _timer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      final next = (_index + 1) % _cardCount;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
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
    final pageView = PageView(
      controller: _page,
      onPageChanged: (i) => setState(() => _index = i),
      children: [
        widget.playerCard,
        _HealingKickoffCard(onTap: widget.onTap, fashion: widget.fashion),
        _PlayerDeviceCard(onTap: widget.onTap),
      ],
    );

    final viewport = widget.height != null
        ? SizedBox(height: widget.height, child: pageView)
        : AspectRatio(aspectRatio: widget.aspectRatio, child: pageView);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        viewport,
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_cardCount, (i) {
            final on = i == _index;
            return Container(
              width: on ? 16 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: on
                    ? (widget.fashion
                        ? Colors.white
                        : const Color(0xFF2B2D33))
                    : (widget.fashion
                        ? Colors.white.withValues(alpha: 0.35)
                        : const Color(0x552B2D33)),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Card 2 — healing kickoff: icon | thin divider | text (not gold dots).
class _HealingKickoffCard extends StatelessWidget {
  const _HealingKickoffCard({this.onTap, this.fashion = false});
  final VoidCallback? onTap;
  final bool fashion;

  /// Share mark — simple node-and-paths glyph (24 box).
  static const _share =
      '<circle cx="18" cy="5" r="2.6"/>'
      '<circle cx="6" cy="12" r="2.6"/>'
      '<circle cx="18" cy="19" r="2.6"/>'
      '<path d="M8.4 10.8l7.2-4.2M8.4 13.2l7.2 4.2"/>';

  static const _lines = <(String mark, double viewBox, String text)>[
    (NwsbMarks.flame, 24, 'Start your streak today'),
    (NwsbMarks.trending, 22, 'Get your score'),
    (_share, 24, 'Share your score'),
  ];

  @override
  Widget build(BuildContext context) {
    final ink = fashion ? Colors.white : const Color(0xFF1A1A2E);
    final soft = fashion ? const Color(0xE6FFFFFF) : const Color(0xFF4A4E5A);
    final divider = fashion ? const Color(0x33FFFFFF) : const Color(0x331A1A2E);
    final iconColor = fashion ? const Color(0xFFE8D5A3) : const Color(0xFF9C7B3A);
    final bg = fashion ? const Color(0xFF0A0A0E) : const Color(0xFFF4F5F8);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Let's start your healing today",
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              for (final line in _lines) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    NwsbIcon(
                      line.$1,
                      size: 18,
                      viewBox: line.$2,
                      color: iconColor,
                      strokeWidth: 1.7,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 22,
                      color: divider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        line.$3,
                        style: TextStyle(
                          color: soft,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Card 3 — NowssB player device graphic + small SVG in a white circle (top-right).
class _PlayerDeviceCard extends StatelessWidget {
  const _PlayerDeviceCard({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF0A0A0E)),
            // Soft swirl wash behind the device art.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.2, -0.1),
                  radius: 1.05,
                  colors: [
                    Color(0x55B978FF),
                    Color(0x332B6CFF),
                    Color(0x000A0A0E),
                  ],
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Image.asset(
                  PracticeCarousel.playerDeviceArt,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/banners/promo/player.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const NwsbIcon(
                  NwsbMarks.play,
                  size: 14,
                  viewBox: 22,
                  color: Color(0xFF0A0A12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
