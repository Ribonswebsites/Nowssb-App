import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/home_skin.dart';
import 'glassmorphism_theme.dart';

/// The video-backed three-ring component from the supplied WebView reference.
/// It intentionally has no heading: the clip and rings are the entire section.
class NmUseThisVideoSection extends StatelessWidget {
  const NmUseThisVideoSection({
    super.key,
    this.fashion = false,
    this.onPlayer,
    this.onSentence,
    this.onLibrary,
  });

  final bool fashion;
  final VoidCallback? onPlayer;
  final VoidCallback? onSentence;
  final VoidCallback? onLibrary;

  @override
  Widget build(BuildContext context) {
    final glass = NormalGlassMode.of(context) || fashion;
    return SectionPane(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),
              Positioned.fill(
                child: NwsbVideo(
                  asset: 'assets/video/grok-video-use-this.mp4',
                  priority: ClipPriority.feature,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .18),
                        Colors.black.withValues(alpha: .48),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: _RingRow(
                  glass: glass,
                  onPlayer: onPlayer,
                  onSentence: onSentence,
                  onLibrary: onLibrary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingRow extends StatefulWidget {
  const _RingRow({
    required this.glass,
    this.onPlayer,
    this.onSentence,
    this.onLibrary,
  });

  final bool glass;
  final VoidCallback? onPlayer;
  final VoidCallback? onSentence;
  final VoidCallback? onLibrary;

  @override
  State<_RingRow> createState() => _RingRowState();
}

class _RingRowState extends State<_RingRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RingAction(
            phase: _motion.value,
            asset: 'assets/banners/promo/player.png',
            title: 'Player',
            onTap: widget.onPlayer,
            glass: widget.glass,
          ),
          _DividerGlow(phase: _motion.value),
          _RingAction(
            phase: (_motion.value + .33) % 1,
            asset: 'assets/icons/icon_01.svg',
            svg: true,
            title: 'Sentence',
            onTap: widget.onSentence,
            glass: widget.glass,
          ),
          _DividerGlow(phase: (_motion.value + .5) % 1),
          _RingAction(
            phase: (_motion.value + .66) % 1,
            asset: 'assets/banners/promo/store.png',
            title: 'Library',
            onTap: widget.onLibrary,
            glass: widget.glass,
          ),
        ],
      ),
    );
  }
}

class _RingAction extends StatelessWidget {
  const _RingAction({
    required this.phase,
    required this.asset,
    required this.title,
    required this.glass,
    this.svg = false,
    this.onTap,
  });

  final double phase;
  final String asset;
  final String title;
  final bool glass;
  final bool svg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 82,
        height: 150,
        child: CustomPaint(
          painter: _OuterRipplePainter(phase: phase),
          child: Center(
            child: Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: glass ? .34 : .52),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .9),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB978FF).withValues(alpha: .7),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: svg
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(asset, fit: BoxFit.contain),
                      )
                    : Image.asset(asset, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerGlow extends StatelessWidget {
  const _DividerGlow({required this.phase});
  final double phase;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 72,
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFFFF4C9A), Colors.white, phase)!,
        boxShadow: const [
          BoxShadow(color: Color(0xFFFF4CBA), blurRadius: 12, spreadRadius: 2),
        ],
      ),
    );
  }
}

class _OuterRipplePainter extends CustomPainter {
  const _OuterRipplePainter({required this.phase});
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = 31.0;
    for (var i = 0; i < 3; i++) {
      final wave = (phase + i / 3) % 1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: .78 * (1 - wave));
      canvas.drawCircle(center, base + wave * 23, paint);
    }
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..shader = SweepGradient(
        startAngle: phase * math.pi * 2,
        colors: const [
          Color(0xFFFF4D77),
          Color(0xFFFFC24D),
          Color(0xFF71E3A6),
          Color(0xFF55B8FF),
          Color(0xFFB879FF),
          Color(0xFFFF4D77),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, base + 4, ring);
  }

  @override
  bool shouldRepaint(_OuterRipplePainter oldDelegate) =>
      oldDelegate.phase != phase;
}
