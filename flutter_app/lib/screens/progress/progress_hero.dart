/// Hero video, sticky header, and total-sessions orb for My Progress.
///
/// Scene-1 is positioned so its **outer glass/smoke sphere rim** coincides
/// with the UI progress ring. The ring is painted near the full box edge and
/// sized large enough to read as the orb's own rim — not a smaller circle
/// floating in the dark core. Overlay stats sit at the shared center.
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
class ProgressHeroBgVideo extends StatelessWidget {
  const ProgressHeroBgVideo({super.key, this.opacity = 1});
  final double opacity;

  /// Scene-1 intrinsic size (my-progress-scene-1.mp4).
  static const double _vidW = 640;
  static const double _vidH = 1408;

  /// Orb center in video pixels.
  static const double _orbCx = 320;
  static const double _orbCy = 462.5;

  /// Outer glass/smoke sphere rim in video pixels (NOT the bright core).
  /// Prior "fix" locked to ~147.5 (core) which left the visible rim far
  /// outside the UI ring — the floating-ring gap in screenshots.
  static const double orbOuterR = 225;

  static const double _headerContentH = 88;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final headerH = pad.top + _headerContentH;
    final ringBox = ProgressOrbHero.ringBoxForWidth(size.width);
    final ringCx = size.width / 2;
    final ringCy = headerH + ProgressOrbHero.height * ProgressOrbHero.orbTopFrac;
    // Lock the *outer* rim to the painted UI ring radius.
    final targetR = ProgressOrbHero.paintedRadius(ringBox);
    final scale = targetR / orbOuterR;
    final left = ringCx - _orbCx * scale;
    final top = ringCy - _orbCy * scale;
    final dw = _vidW * scale;
    final dh = _vidH * scale;

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: ColoredBox(
            color: MpColors.bg,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: left,
                    top: top,
                    width: dw,
                    height: dh,
                    child: const NwsbVideo(
                      asset: kProgressScene1,
                      // Geometry is applied by the Positioned box — no
                      // asset recompress; fill the laid-out rect.
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
    );
  }
}

/// Full-screen scroll backdrop. Fades in once the hero leaves.
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

/// Transparent orb overlay — NO video inside. Page bg shows through.
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

  /// Tall enough for a large rim-aligned ring + VIEW INSIGHTS CTA.
  static const double height = 420;

  /// Public so [ProgressHeroBgVideo] can lock the scene-1 outer rim here.
  static const double orbTopFrac = 0.38;

  /// Legacy constant — prefer [ringBoxForWidth] for layout.
  static const double ringSize = 328;

  /// Responsive ring box: large enough to sit on the outer smoke rim.
  static double ringBoxForWidth(double width) =>
      (width * 0.84).clamp(300.0, 348.0);

  /// Painted stroke radius — near the box edge (not the old 130/286 inset
  /// that left a dark gap inside the sphere).
  static double paintedRadius(double ringBox) => ringBox / 2 - 2.5;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final ringBox = ringBoxForWidth(width);
    final ringProgress =
        sessions == 0 ? 0.12 : (0.18 + (sessions % 40) / 50).clamp(0.18, 0.92);
    final orbTop = height * orbTopFrac - ringBox / 2;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft depth plate — reads as glass interior behind the copy.
          Positioned(
            top: orbTop + ringBox * 0.18,
            left: 0,
            right: 0,
            height: ringBox * 0.64,
            child: Center(
              child: IgnorePointer(
                child: Container(
                  width: ringBox * 0.55,
                  height: ringBox * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.black.withOpacity(0.38),
                        Colors.black.withOpacity(0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Thin white progress ring on the orb's outer rim.
          Positioned(
            top: orbTop,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: ringBox,
                height: ringBox,
                child: CustomPaint(painter: _OrbRingPainter(progress: ringProgress)),
              ),
            ),
          ),
          // Stats stack — exact orb center, depth shadows for in-glass read.
          Positioned(
            top: orbTop,
            left: 0,
            right: 0,
            height: ringBox,
            child: Center(
              child: SizedBox(
                width: ringBox * 0.62,
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
          ),
          // CTA under the orb.
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
    // Sit on the box rim — traces the video's outer smoke/glass sphere.
    final r = ProgressOrbHero.paintedRadius(size.width);
    // Soft outer glow so the stroke reads as part of the glass highlight.
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
