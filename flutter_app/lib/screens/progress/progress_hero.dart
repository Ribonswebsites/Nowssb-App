/// Hero video, sticky header, and total-sessions orb for My Progress.
///
/// Scene-1 is positioned so its glowing orb midline coincides with the
/// Glass Orb UI ring (268 / svg r=130). Overlay stats sit inside that ring.
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

  /// Glowing orb midline in video pixels (center-column ring peaks).
  static const double _orbCx = 320;
  static const double _orbCy = 462.5;
  static const double _orbR = 147.5;

  /// Match Glass Orb HTML: .orbProgress 268px, svg viewBox 286, circle r=130.
  static const double _ringBox = ProgressOrbHero.ringSize;
  static const double _svgView = 286;
  static const double _svgR = 130;
  static double get uiRingRadius => _svgR * (_ringBox / _svgView);

  static const double _headerContentH = 88;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final headerH = pad.top + _headerContentH;
    final ringCx = size.width / 2;
    final ringCy = headerH + ProgressOrbHero.height * ProgressOrbHero.orbTopFrac;
    final targetR = uiRingRadius;
    // Zoom so the video orb diameter matches the UI ring — stable across
    // aspect ratios (plain BoxFit.cover left the orb too small / drifted).
    final scale = targetR / _orbR;
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
                      // Box already matches video aspect; fill without
                      // recompressing the asset.
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

  /// Compact hero matching Glass Orb mobile mock (~392).
  static const double height = 392;

  /// Public so [ProgressHeroBgVideo] can lock the scene-1 orb to this ring.
  static const double orbTopFrac = 0.38;
  static const double ringSize = 268;

  @override
  Widget build(BuildContext context) {
    final ringProgress =
        sessions == 0 ? 0.12 : (0.18 + (sessions % 40) / 50).clamp(0.18, 0.92);
    const orbTop = height * orbTopFrac - ringSize / 2;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Thin white progress ring around the bright orb core.
          Positioned(
            top: orbTop,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: ringSize,
                height: ringSize,
                child: CustomPaint(painter: _OrbRingPainter(progress: ringProgress)),
              ),
            ),
          ),
          // Stats stack — locked inside the ring.
          Positioned(
            top: orbTop,
            left: 0,
            right: 0,
            height: ringSize,
            child: Center(
              child: SizedBox(
                width: 210,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'TOTAL SESSIONS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 2.8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE6E6E2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$sessions',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 61,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -3.5,
                        height: 0.94,
                        color: MpColors.white,
                        shadows: [Shadow(blurRadius: 18, color: Colors.black)],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      timeLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFFF0F0ED),
                        shadows: [Shadow(blurRadius: 12, color: Colors.black)],
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'MEDITATION TIME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 2.4,
                        color: Color(0xFFBFC1C0),
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
    // HTML: <svg viewBox="0 0 286 286"><circle r="130"/></svg> in a 268 box.
    final r = size.width * (130 / 286);
    final track = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final arc = Paint()
      ..color = Colors.white.withOpacity(0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
    canvas.drawCircle(c, r, track);
    // HTML rotate(-86deg) ≈ -pi*0.478
    const start = -math.pi * 0.478;
    final sweep = math.pi * 2 * progress;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, sweep, false, arc);
    // Bright handle at the leading tip of the arc (matches mock).
    final tip = Offset(c.dx + r * math.cos(start + sweep), c.dy + r * math.sin(start + sweep));
    canvas.drawCircle(tip, 3.2, Paint()..color = Colors.white.withOpacity(0.95));
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
