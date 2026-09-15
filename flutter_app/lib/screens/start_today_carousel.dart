/// Today's Practice — 3-card horizontal carousel (Player → Practice Today → Device).
///
/// Used inside [FashPractice] / [NmPractice]. No separate "START TODAY" section.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/nwsb_icon.dart';

/// Horizontal 3-card practice carousel for the single Today's Practice block.
///
/// Card 1: [playerCard] — TODAY'S PRACTICE / NowssB Player (swirl + Enter).
/// Card 2: PRACTICE TODAY lifestyle art (edge-to-edge, rounded, no stroke).
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

  /// Card 2 — PRACTICE TODAY lifestyle (woman + headphones + phone).
  static const practiceTodayArt = 'assets/coach/practice-today.png';

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
        _PracticeTodayArtCard(onTap: widget.onTap),
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

/// Card 2 — PRACTICE TODAY lifestyle art, edge-to-edge, rounded, no stroke.
class _PracticeTodayArtCard extends StatelessWidget {
  const _PracticeTodayArtCard({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          PracticeCarousel.practiceTodayArt,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: Color(0xFF0A0A0E),
            child: Center(
              child: Icon(Icons.headphones, color: Colors.white54, size: 42),
            ),
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
