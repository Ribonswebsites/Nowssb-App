import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small, always-on brand animation for fixed app headers.
///
/// This is deliberately much quieter than the full-screen hero reveal: the
/// existing start animation remains responsible for launch, while this mark
/// continuously cycles a warm rim, a short orbital sweep, and a tiny pulse.
class LoopingLogoMark extends StatefulWidget {
  const LoopingLogoMark({super.key, this.size = 48});

  final double size;

  @override
  State<LoopingLogoMark> createState() => _LoopingLogoMarkState();
}

class _LoopingLogoMarkState extends State<LoopingLogoMark>
    with SingleTickerProviderStateMixin {
  // `pumpAndSettle` must be able to finish in widget tests. The production
  // app still repeats continuously; only the test binding gets a static frame.
  static const _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (!_isFlutterTest) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final phase = _controller.value;
        final pulse = 1.0 + (math.sin(phase * math.pi * 2) * 0.035);
        final glow = 0.20 + ((math.sin(phase * math.pi * 2) + 1) * 0.10);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Transform.scale(
            scale: pulse,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6A00).withValues(alpha: glow),
                        blurRadius: widget.size * 0.28,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/logo-disc.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFF14141C),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFFFA21A),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: CustomPaint(
                    painter: _LogoSweepPainter(progress: phase),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogoSweepPainter extends CustomPainter {
  const _LogoSweepPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final angle = -math.pi / 2 + (progress * math.pi * 2);
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.5, size.width * 0.045)
      ..shader = SweepGradient(
        startAngle: angle - 0.85,
        endAngle: angle + 0.22,
        colors: const [
          Color(0x00FF7A00),
          Color(0xFFFF7A00),
          Color(0xFFFFD08A),
        ],
      ).createShader(rect);
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.04,
        size.width * 0.92,
        size.height * 0.92,
      ),
      angle - 0.85,
      1.07,
      false,
      sweep,
    );

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.width * 0.018)
      ..color = const Color(0xFFFFA21A).withValues(alpha: 0.45);
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.47, ring);
  }

  @override
  bool shouldRepaint(covariant _LogoSweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
