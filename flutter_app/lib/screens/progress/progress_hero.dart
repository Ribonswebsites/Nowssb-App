/// Hero video, sticky header, and total-sessions orb for My Progress.
///
/// Geometry contract (contained orb, concentric ring+stats):
/// - One shared orb stage: SizedBox(d,d) + ClipOval with page margin.
/// - Video is square-cropped around the glass orb then BoxFit.cover into that
///   oval — larger crop (orbOuterR~215) zooms out so smoke is not full-bleed.
/// - Ring + stats share smoke center via a small down+right nudge.
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

/// Ambient plate behind the page — orb sphere is owned by ProgressOrbHero.
class ProgressHeroBgVideo extends StatelessWidget {
  const ProgressHeroBgVideo({super.key, this.opacity = 1});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    // Ambient plate only — the glass/smoke sphere lives INSIDE [ProgressOrbHero]
    // so ring and orb share one measured parent (no second competing circle).
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: const ColoredBox(color: MpColors.bg),
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

/// Shared orb stage: smoke video + rim ring + stats — one parent, one center.
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

  /// Tall enough for shared orb stage + VIEW INSIGHTS CTA.
  static const double height = 460;

  /// Scene-1 intrinsic size (my-progress-scene-1.mp4).
  static const double vidW = 640;
  static const double vidH = 1408;

  /// Orb center in video pixels — remeasured from my-progress-scene-1.mp4
  /// so the visible smoke outer rim coincides with the shared stage oval.
  static const double orbCx = 318;
  static const double orbCy = 445;
  /// Outer glass/smoke sphere radius in video pixels → crop square side 430.
  /// Raised from 165 (too zoomed / full-bleed) toward prior ~225 so the
  /// sphere reads as a contained circle with black margin around it.
  static const double orbOuterR = 215;

  /// Nudge ring + TOTAL SESSIONS text down+right vs smoke center only.
  static const Offset ringStatsNudge = Offset(8, 10);

  /// Vertical anchor of the shared stage center inside [height] (0–1).
  static const double stageCenterFrac = 0.42;

  /// Responsive rendered diameter of the shared orb stage.
  /// Slightly under full-bleed so the oval has visible page margin.
  static double stageDiameterForWidth(double width) =>
      (width * 0.74).clamp(280.0, 400.0);

  /// Painted stroke radius — traces outer rim of the SAME oval (inset 2px).
  static double paintedRadius(double diameter) => diameter / 2 - 2.0;

  /// Legacy aliases used by scroll math / callers.
  static const double orbTopFrac = stageCenterFrac;
  static const double ringSize = 360;

  static double ringBoxForWidth(double width) => stageDiameterForWidth(width);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final d = stageDiameterForWidth(width);
    final ringProgress =
        sessions == 0 ? 0.12 : (0.18 + (sessions % 40) / 50).clamp(0.18, 0.92);

    // Shared stage center inside this hero (absolute 50% / stageCenterFrac).
    final cx = width / 2;
    final cy = height * stageCenterFrac;

    // Square-crop the video around the glass orb, then cover-fill the oval.
    // Crop square side = 2*orbOuterR centered on (orbCx, orbCy). Ring radius
    // = d/2 on that SAME oval → one center, rim on smoke, no second circle.
    final crop = orbOuterR * 2; // 430
    final cropLeft = -(orbCx - orbOuterR);
    final cropTop = -(orbCy - orbOuterR);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // —— SHARED PARENT: smoke + ring + text, same center & diameter ——
          Positioned(
            left: cx,
            top: cy,
            child: Transform.translate(
              offset: Offset(-d / 2, -d / 2),
              child: SizedBox(
                width: d,
                height: d,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Smoke / glass orb — one ClipOval stage, crop→cover.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipOval(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: crop,
                              height: crop,
                              child: Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  Positioned(
                                    left: cropLeft,
                                    top: cropTop,
                                    width: vidW,
                                    height: vidH,
                                    child: const NwsbVideo(
                                      asset: kProgressScene1,
                                      fit: BoxFit.fill,
                                      priority: ClipPriority.feature,
                                      loop: true,
                                      autoplay: true,
                                      alignment: Alignment.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Soft center vignette for stats legibility — NOT a second ring.
                    // Full-stage radial fade (same center as oval); no hard circular edge.
                    IgnorePointer(
                      child: Container(
                        width: d,
                        height: d,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.black.withOpacity(0.38),
                              Colors.black.withOpacity(0.12),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.42, 0.78],
                          ),
                        ),
                      ),
                    ),
                    // Progress ring + stats — nudged down+right to match
                    // visible smoke center (smoke crop stays put).
                    Positioned.fill(
                      child: Transform.translate(
                        offset: ringStatsNudge,
                        child: CustomPaint(
                          painter: _OrbRingPainter(progress: ringProgress),
                        ),
                      ),
                    ),
                    // Stats — shared center + same nudge as ring.
                    Transform.translate(
                      offset: ringStatsNudge,
                      child: SizedBox(
                      width: d * 0.62,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                  ],
                ),
              ),
            ),
          ),
          // CTA under the shared stage.
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

class _OrbRingPainter extends CustomPainter {
  _OrbRingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    // Radius as % of SAME shared container → outer rim of smoke orb.
    final r = ProgressOrbHero.paintedRadius(size.width);
    final glow = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawCircle(c, r, glow);
    final track = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final arc = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.55);
    canvas.drawCircle(c, r, track);
    const start = -math.pi * 0.478;
    final sweep = math.pi * 2 * progress;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, false, arc);
    final tip = Offset(c.dx + r * math.cos(start + sweep), c.dy + r * math.sin(start + sweep));
    canvas.drawCircle(
      tip,
      3.4,
      Paint()
        ..color = Colors.white.withOpacity(0.96)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
