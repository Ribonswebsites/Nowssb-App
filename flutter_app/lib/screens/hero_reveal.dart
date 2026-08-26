import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A lightweight app-native version of the Nowssb Blender hero reveal.
///
/// It is intentionally built with Flutter primitives so it works offline and
/// does not require a rendered video, a decoder, or a Blender runtime on the
/// phone. The same timing and visual language as the Blender source are kept:
/// amber particle convergence, Y spin, dolly-zoom scale, god-rays, impact ring,
/// and a warm landing pulse.
class HeroReveal extends StatefulWidget {
  const HeroReveal({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<HeroReveal> createState() => _HeroRevealState();
}

class _HeroRevealState extends State<HeroReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_completed) {
          _completed = true;
          widget.onDone();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020100),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final landing = Curves.elasticOut.transform(
            ((t - 0.47) / 0.18).clamp(0.0, 1.0),
          );
          final camera = 0.72 + (Curves.easeInOutCubic.transform(t) * 0.30);
          final pulse = 1.0 + (math.sin(landing * math.pi) * 0.10);
          final spin = (-math.pi * 0.60) + (Curves.easeInOutCubic.transform(
            ((t - 0.10) / 0.48).clamp(0.0, 1.0),
          ) * math.tau * 1.08);
          final logoOpacity = Curves.easeOutCubic.transform(
            ((t - 0.20) / 0.28).clamp(0.0, 1.0),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _HeroBackdropPainter(progress: t),
              ),
              Center(
                child: Transform.scale(
                  scale: camera,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(spin),
                    child: Opacity(
                      opacity: logoOpacity,
                      child: Transform.scale(
                        scale: pulse,
                        child: Container(
                          width: 252,
                          height: 252,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color.lerp(
                                const Color(0xFF2A0B00),
                                const Color(0xFFFFA21A),
                                logoOpacity,
                              )!,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6A00)
                                    .withValues(alpha: 0.18 + (logoOpacity * 0.28)),
                                blurRadius: 42,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: const Color(0xFFFFB347)
                                    .withValues(alpha: landing * 0.30),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/logo-disc.webp',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: Color(0xFF090503),
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFFFFA21A),
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _ShockwavePainter(progress: t),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBackdropPainter extends CustomPainter {
  _HeroBackdropPainter({required this.progress});

  final double progress;
  final List<_Particle> particles = _makeParticles();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.75;

    final wash = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4B1504).withValues(alpha: 0.30),
          const Color(0xFF090301).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));
    canvas.drawCircle(center, maxRadius, wash);

    final rayPaint = Paint()
      ..color = const Color(0xFFFF7A18).withValues(alpha: 0.07)
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    for (var i = 0; i < 12; i++) {
      final angle = (-math.pi / 2) + (i * math.pi / 6);
      final reach = maxRadius * (0.55 + (0.18 * math.sin(progress * math.pi)));
      canvas.drawLine(
        center + Offset(math.cos(angle) * 54, math.sin(angle) * 54),
        center + Offset(math.cos(angle) * reach, math.sin(angle) * reach),
        rayPaint,
      );
    }

    for (final particle in particles) {
      final local = ((progress - particle.delay) / (1.0 - particle.delay))
          .clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(local);
      final position = Offset.lerp(particle.start, particle.end, eased)!;
      final fadeIn = (local * 4).clamp(0.0, 1.0);
      final fadeOut = (1.0 - ((local - 0.72) / 0.28).clamp(0.0, 1.0));
      final paint = Paint()
        ..color = const Color(0xFFFF8A1C).withValues(alpha: fadeIn * fadeOut)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(position, particle.radius * (1.0 - eased * 0.35), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress;

  static List<_Particle> _makeParticles() {
    final random = math.Random(26);
    return List.generate(170, (i) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance = 160 + (random.nextDouble() * 260);
      final endAngle = random.nextDouble() * math.pi * 2;
      final endRadius = math.sqrt(random.nextDouble()) * 132;
      return _Particle(
        start: Offset(
          math.cos(angle) * distance,
          math.sin(angle) * distance,
        ),
        end: Offset(
          math.cos(endAngle) * endRadius,
          math.sin(endAngle) * endRadius,
        ),
        radius: 1.2 + (random.nextDouble() * 2.8),
        delay: (i % 28) / 70,
      );
    });
  }
}

class _ShockwavePainter extends CustomPainter {
  _ShockwavePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final impact = ((progress - 0.48) / 0.30).clamp(0.0, 1.0);
    if (impact <= 0 || impact >= 1) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 34 + (impact * size.shortestSide * 0.47);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0 - (impact * 3.5)
      ..color = const Color(0xFFFF8A1C).withValues(alpha: (1 - impact) * 0.86)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ShockwavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  const _Particle({
    required this.start,
    required this.end,
    required this.radius,
    required this.delay,
  });

  final Offset start;
  final Offset end;
  final double radius;
  final double delay;
}
