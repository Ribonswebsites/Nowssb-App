/// Today's Practice — 3-card horizontal carousel (practice art → Player → healing).
///
/// Used inside [FashPractice] / [NmPractice]. No separate "START TODAY" section.
library;

import 'dart:async';

import 'package:flutter/material.dart';

/// Horizontal 3-card practice carousel for the single Today's Practice block.
///
/// Card 1: PRACTICE TODAY art (edge-to-edge, no stroke).
/// Card 2: [playerCard] — the existing Player treatment, unchanged.
/// Card 3: healing kickoff copy.
class PracticeCarousel extends StatefulWidget {
  const PracticeCarousel({
    super.key,
    required this.playerCard,
    this.onTap,
    this.fashion = false,
    this.aspectRatio = 16 / 9,
    this.height,
  });

  /// Card 2 — Fashion / Normal player UI exactly as built by the parent.
  final Widget playerCard;
  final VoidCallback? onTap;
  final bool fashion;

  /// Used when [height] is null (Fashion media cards).
  final double aspectRatio;

  /// Fixed viewport height (Normal neu player). Overrides [aspectRatio].
  final double? height;

  static const practiceArt = 'assets/coach/aarogya-personal-coach.png';

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
        _PracticeImageCard(onTap: widget.onTap),
        widget.playerCard,
        _HealingKickoffCard(onTap: widget.onTap),
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

/// Card 1 — full PRACTICE TODAY artwork, edge-to-edge, no border/stroke.
class _PracticeImageCard extends StatelessWidget {
  const _PracticeImageCard({this.onTap});
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
          PracticeCarousel.practiceArt,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// Card 3 — healing kickoff copy.
class _HealingKickoffCard extends StatelessWidget {
  const _HealingKickoffCard({this.onTap});
  final VoidCallback? onTap;

  static const _lines = <String>[
    'Start your streak today',
    'Get your score',
    'Share your score',
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: const Color(0xFF0A0A0E),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Let's start your healing today",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              for (final line in _lines) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8D5A3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
