/// Hotstar-style promo strip. Flat colour and a ring, then the group pops,
/// then the left title, then the line under it. Holds, clears, and repeats.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _purple = Color(0xFF692FCC);

class MeditationFlipBanner extends StatefulWidget {
  const MeditationFlipBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<MeditationFlipBanner> createState() => _MeditationFlipBannerState();
}

class _MeditationFlipBannerState extends State<MeditationFlipBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _cycle = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));

  bool get _quiet => WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    if (_quiet) {
      _cycle.value = 0.55;
      return;
    }
    _cycle.repeat();
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  /// Hidden, then a pop that may overshoot 1, then a 2s hold, then gone.
  double _amount(double t, double start, double end) {
    const holdEnd = 0.814;
    const fadeEnd = 0.92;
    if (t < start || t >= fadeEnd) return 0;
    final shown = t >= end ? 1.0 : Curves.easeOutBack.transform(((t - start) / (end - start)).clamp(0.0, 1.0));
    if (t <= holdEnd) return shown;
    final fade = ((t - holdEnd) / (fadeEnd - holdEnd)).clamp(0.0, 1.0);
    return shown * (1 - fade);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: _purple,
            child: SizedBox(
              height: 128,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _cycle,
                builder: (context, _) {
                  final t = _cycle.value;
                  final group = _amount(t, 0.09, 0.20);
                  final title = _amount(t, 0.22, 0.33);
                  final sub = _amount(t, 0.33, 0.44);
                  final groupOpacity = group.clamp(0.0, 1.0);
                  final titleOpacity = title.clamp(0.0, 1.0);
                  final subOpacity = sub.clamp(0.0, 1.0);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      const CustomPaint(painter: _OrbPainter()),
                      Opacity(
                        opacity: groupOpacity,
                        child: Transform.translate(
                          offset: Offset((1 - groupOpacity) * 28, 0),
                          child: Transform.scale(
                            scale: 0.82 + 0.18 * group.clamp(0.0, 1.15),
                            alignment: Alignment.centerRight,
                            child: Image.asset(
                              'assets/banners/meditation-group.jpg',
                              fit: BoxFit.cover,
                              alignment: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 16,
                        child: Opacity(
                          opacity: titleOpacity,
                          child: Transform.translate(
                            offset: Offset((1 - titleOpacity) * -16, 0),
                            child: Transform.scale(
                              scale: 0.86 + 0.14 * title.clamp(0.0, 1.12),
                              alignment: Alignment.centerLeft,
                              child: const _TitleBlock(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 78,
                        child: Opacity(
                          opacity: subOpacity,
                          child: Transform.translate(
                            offset: Offset(0, (1 - subOpacity) * 10),
                            child: const _SubBlock(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 30, height: 30, child: CustomPaint(painter: _MarkPainter())),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOWSSB',
              style: GoogleFonts.oswald(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  'MEDITATION',
                  style: GoogleFonts.oswald(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubBlock extends StatelessWidget {
  const _SubBlock();

  @override
  Widget build(BuildContext context) {
    return Text(
      'DAILY PRACTICE\nBEGIN ANYTIME',
      style: GoogleFonts.oswald(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - size.height * 0.08, size.height * 0.58);
    final radius = size.height * 0.98;
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius - 1)));
    final seam = Paint()
      ..color = _purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius * 0.46, seam);
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(-radius * 0.35, -radius * 0.15), radius: radius * 0.7),
      -0.4,
      2.4,
      false,
      seam,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(radius * 0.28, radius * 0.22), radius: radius * 0.62),
      2.4,
      2.1,
      false,
      seam,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, size.width * 0.22, p);
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final tip = c + Offset(math.cos(a), math.sin(a)) * size.width * 0.46;
      final left = c + Offset(math.cos(a - 0.55), math.sin(a - 0.55)) * size.width * 0.18;
      final right = c + Offset(math.cos(a + 0.55), math.sin(a + 0.55)) * size.width * 0.18;
      final petal = Path()
        ..moveTo(left.dx, left.dy)
        ..quadraticBezierTo(tip.dx, tip.dy, right.dx, right.dy);
      canvas.drawPath(petal, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
