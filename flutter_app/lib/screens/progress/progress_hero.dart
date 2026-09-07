/// Hero video, sticky header, and total-sessions orb for My Progress.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import 'progress_tokens.dart';

const kProgressScene1 = 'assets/video/my-progress-scene-1.mp4';
const kProgressScene2 = 'assets/video/my-progress-scene-2.mp4';
/// Same clip as progress-scroll-bg / my-progress-scene-2 — page backdrop after the hero.
const kProgressScrollBg = 'assets/video/player-bg-loop.mp4';

/// Full-screen scroll backdrop (water / silk loop). Visible once the hero scrolls away.
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
              priority: ClipPriority.decoration,
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
              InkWell(
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
                    placeholderBuilder: (_) => const Icon(Icons.chevron_left, size: 28, color: Color(0xFF080909)),
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

/// Scene-1 orb + centered stats + VIEW INSIGHTS.
///
/// Video lives *inside* this box (not full-screen) so the text stack stays
/// locked to the bright orb core. Height is tight so YOUR NUMBERS sits close.
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

  /// Compact hero — was 545; mock puts Your Numbers just under the CTA.
  static const double height = 392;

  /// Alignment of the bright orb core within the clipped scene-1 frame.
  static const Alignment orbCore = Alignment(0, -0.42);

  @override
  Widget build(BuildContext context) {
    final ringProgress =
        sessions == 0 ? 0.12 : (0.18 + (sessions % 40) / 50).clamp(0.18, 0.92);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Scene-1 orb video — framed to this hero only.
          const Positioned.fill(
            child: Opacity(
              opacity: 0.96,
              child: ColoredBox(
                color: MpColors.bg,
                child: NwsbVideo(
                  asset: kProgressScene1,
                  fit: BoxFit.cover,
                  priority: ClipPriority.feature,
                  alignment: Alignment(0, -0.15),
                ),
              ),
            ),
          ),
          // Soft vignette so lower CTA / next section read cleanly.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x99020304),
                    ],
                    stops: [0, 0.22, 0.62, 1],
                  ),
                ),
              ),
            ),
          ),
          // Progress ring around the orb core.
          Align(
            alignment: orbCore,
            child: SizedBox(
              width: 268,
              height: 268,
              child: CustomPaint(painter: _OrbRingPainter(progress: ringProgress)),
            ),
          ),
          // Stats stack — truly centered in the bright orb core.
          Align(
            alignment: orbCore,
            child: SizedBox(
              width: 210,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
          // CTA sits just under the orb — little dead space below.
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
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
    final r = size.width / 2 - 8;
    final track = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final arc = Paint()
      ..color = Colors.white.withOpacity(0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, track);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi * 0.48,
      math.pi * 2 * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class ProgressSceneTwo extends StatelessWidget {
  const ProgressSceneTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const NwsbVideo(
              asset: kProgressScene2,
              fit: BoxFit.cover,
              priority: ClipPriority.decoration,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC020304)],
                ),
              ),
            ),
            const Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Text(
                'Your practice, moving forward.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFEDEDEB),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
