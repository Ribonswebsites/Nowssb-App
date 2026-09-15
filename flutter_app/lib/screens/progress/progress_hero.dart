/// Hero video, sticky header, and total-sessions orb for My Progress.
///
/// Geometry contract (full-bleed scene-1, text-only overlay):
/// - Scene-1 plays edge-to-edge via [ProgressHeroBgVideo] (BoxFit.cover) so
///   the glass orb + water ripple fill naturally — no ClipOval stage, no
///   width×0.74 margin shrink, no oversized square crop.
/// - [ProgressOrbHero] is a transparent overlay: text stack only (no white
///   progress ring / track / tip). Text is nudged down+right into the orb's
///   natural dark void.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import 'progress_tokens.dart';

const kProgressScene1 = 'assets/video/my-progress-scene-1.mp4';
/// Scroll-up page backdrop (smoke / silk) — full bleed, not a card.
const kProgressScrollBg = 'assets/video/player-bg-loop.mp4';

/// Full-screen hero (scene-1) backdrop. Crossfades out as user scrolls.
/// Natural cover fill — orb + ripple visible as authored in the film.
class ProgressHeroBgVideo extends StatelessWidget {
  const ProgressHeroBgVideo({super.key, this.opacity = 1});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: const ColoredBox(
            color: MpColors.bg,
            child: NwsbVideo(
              asset: kProgressScene1,
              fit: BoxFit.cover,
              priority: ClipPriority.feature,
              loop: true,
              autoplay: true,
              // Slight top bias so the orb sits under the header and the
              // water ripple under the sphere stays in frame.
              alignment: Alignment(0, -0.12),
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressScrollBgVideo extends StatelessWidget {
  const ProgressScrollBgVideo({super.key, this.opacity = 1});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: const ColoredBox(
            color: MpColors.bg,
            child: NwsbVideo(
              asset: kProgressScrollBg,
              fit: BoxFit.cover,
              // Page film — must not lose its decoder to a banner strip.
              priority: ClipPriority.feature,
              loop: true,
              autoplay: true,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressVideoShade extends StatelessWidget {
  const ProgressVideoShade({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xBD000000),
                Color(0x2E000000),
                Color(0x1A000000),
                Color(0xCC000000),
                Color(0xFF020304),
              ],
              stops: [0, 0.24, 0.48, 0.86, 1],
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressGrain extends StatelessWidget {
  const ProgressGrain({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Opacity(opacity: 0.035, child: CustomPaint(painter: _GrainPainter())),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(3);
    final p = Paint();
    for (var i = 0; i < 1600; i++) {
      p.color = Colors.white.withOpacity(0.02 + r.nextDouble() * 0.03);
      canvas.drawRect(
        Rect.fromLTWH(r.nextDouble() * size.width, r.nextDouble() * size.height, 0.8, 0.8),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x8C020405),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x17FFFFFF))),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBack,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xF2FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/icon_01.svg',
                      width: 22,
                      height: 22,
                      colorFilter: const ColorFilter.mode(Color(0xFF080909), BlendMode.srcIn),
                      placeholderBuilder: (_) =>
                          const Icon(Icons.chevron_left, size: 28, color: Color(0xFF080909)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Progress',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -1.1,
                      color: MpColors.white,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'HEALING JOURNEY',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 3.0,
                      color: MpColors.soft,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transparent overlay — TOTAL SESSIONS text floats in the scene-1 dark void.
/// No ClipOval video stage, no white progress ring.
class ProgressOrbHero extends StatelessWidget {
  const ProgressOrbHero({
    super.key,
    required this.sessions,
    required this.timeLabel,
    required this.onViewInsights,
  });

  final int sessions;
  final String timeLabel;
  final VoidCallback onViewInsights;

  /// Tall enough for orb void + VIEW INSIGHTS; page video shows through.
  static const double height = 420;

  /// Vertical anchor of the text block center inside [height] (0–1).
  static const double textCenterFrac = 0.40;

  /// Orb smoke void sits slightly below + right of geometric center —
  /// nudge the text stack into that natural dark hole (dx right, dy down).
  static const Offset textVoidNudge = Offset(40, 24);

  /// Legacy aliases used by scroll math / callers.
  static const double orbTopFrac = textCenterFrac;
  static const double ringSize = 268;

  static double stageDiameterForWidth(double width) =>
      (width * 0.92).clamp(300.0, 420.0);

  static double ringBoxForWidth(double width) => stageDiameterForWidth(width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Stats only — no ring, no circle container. Page scene-1 shows through.
          // Anchor at geometric center of hero, then nudge into the smoke void.
          Positioned(
            left: 0,
            right: 0,
            top: height * textCenterFrac - 100,
            height: 200,
            child: Transform.translate(
              offset: textVoidNudge,
              child: Center(
                child: SizedBox(
                  width: 210,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Text(
                      'TOTAL SESSIONS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 2.8,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE6E6E2),
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black.withOpacity(0.85),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$sessions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -3.5,
                        height: 0.94,
                        color: MpColors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 22,
                            color: Colors.black.withOpacity(0.9),
                          ),
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black.withOpacity(0.7),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      timeLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFFF0F0ED),
                        shadows: [
                          Shadow(
                            blurRadius: 14,
                            color: Colors.black.withOpacity(0.85),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'MEDITATION TIME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 2.4,
                        color: const Color(0xFFBFC1C0),
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
          // CTA under the orb void.
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: TextButton(
                onPressed: onViewInsights,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEDEDEB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: StadiumBorder(
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                  backgroundColor: const Color(0x7A050607),
                ),
                child: const Text.rich(
                  TextSpan(
                    text: 'VIEW INSIGHTS ',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2.0),
                    children: [
                      TextSpan(text: '\u2197', style: TextStyle(fontSize: 13, letterSpacing: 0)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tagline overlay only — NO empty video card. Page scroll bg shows through.
class ProgressPracticeForward extends StatelessWidget {
  const ProgressPracticeForward({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(
        'Your practice, moving forward.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFEDEDEB),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.35,
          shadows: [Shadow(blurRadius: 14, color: Colors.black)],
        ),
      ),
    );
  }
}
