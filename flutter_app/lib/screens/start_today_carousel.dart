/// Start Today — 3-card horizontal carousel under Today's Practice.
///
/// Gold caps header twin of TODAY'S PRACTICE. Three equal swipe cards:
/// practice artwork (contain, no overlays), Player twin, healing kickoff.
library;

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../media/nwsb_image.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/home_parts.dart';

class StartTodayCarousel extends StatefulWidget {
  const StartTodayCarousel({super.key, this.onTap, this.fashion = false});

  final VoidCallback? onTap;
  final bool fashion;

  static const practiceArt = 'assets/coach/aarogya-personal-coach.png';
  static const practiceVid =
      'assets/videos/09a50041065bdeab_grok_video_2026-07-30-14-54-07_ddjmrr.mp4';
  static const practiceStill =
      'https://media.nowssb.com/migrated-images/4daad1a85b624fed_grok_image_1778052232385_qpdmgh.jpg';

  @override
  State<StartTodayCarousel> createState() => _StartTodayCarouselState();
}

class _StartTodayCarouselState extends State<StartTodayCarousel> {
  late final PageController _page;
  Timer? _timer;
  var _index = 0;

  static const _cardCount = 3;

  /// Twin of the TODAY'S PRACTICE gold/caps eyebrow on the Player card.
  static const _sectionLabelStyle = TextStyle(
    fontSize: 11,
    letterSpacing: 2,
    fontWeight: FontWeight.w700,
    color: Color(0xFFE8D5A3),
  );

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.88);
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
    final labelStyle = widget.fashion
        ? _sectionLabelStyle
        : _sectionLabelStyle.copyWith(color: NwsbColors.gold);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text('START TODAY', style: labelStyle),
          ),
          SizedBox(
            height: 248,
            child: PageView(
              controller: _page,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                _pad(_PracticeImageCard(onTap: widget.onTap)),
                _pad(
                  _PlayerTwinCard(
                    fashion: widget.fashion,
                    onTap: widget.onTap,
                  ),
                ),
                _pad(_HealingKickoffCard(onTap: widget.onTap)),
              ],
            ),
          ),
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
      ),
    );
  }

  Widget _pad(Widget child) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: child);
}

/// Card 1 — full PRACTICE TODAY artwork, no word-name / coach overlays.
class _PracticeImageCard extends StatelessWidget {
  const _PracticeImageCard({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassFrame(
      onTap: onTap,
      child: ColoredBox(
        color: const Color(0xFF0A0A0E),
        child: Image.asset(
          StartTodayCarousel.practiceArt,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

/// Card 2 — same NowssB Player treatment as Today's Practice (swirl + Enter).
class _PlayerTwinCard extends StatelessWidget {
  const _PlayerTwinCard({required this.fashion, this.onTap});

  final bool fashion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassFrame(
      onTap: onTap,
      child: ListenableBuilder(
        listenable: Settings.instance,
        builder: (context, _) {
          final motion = fashion && Settings.instance.fashionPlus;
          final media = motion
              ? const NwsbVideo(
                  asset: StartTodayCarousel.practiceVid,
                  priority: ClipPriority.feature,
                  fit: BoxFit.cover,
                )
              : const NwsbImage(
                  url: StartTodayCarousel.practiceStill,
                  fit: BoxFit.cover,
                );
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: media),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0x99060C18),
                      Color(0x33060C18),
                      Color(0x14060C18),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(child: GlassEnterPill(onTap: onTap)),
              ),
            ],
          );
        },
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
    return _GlassFrame(
      onTap: onTap,
      child: Container(
        color: const Color(0xFF0A0A0E),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}

class _GlassFrame extends StatelessWidget {
  const _GlassFrame({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x0EFFFFFF),
              borderRadius: radius,
              border: Border.all(color: const Color(0x55FFFFFF), width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x57000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: child,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x66FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
