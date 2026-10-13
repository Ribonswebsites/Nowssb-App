import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Procedural golden mandala (spec 15.3 #8): rotating layers.
class MandalaPainter extends CustomPainter {
  MandalaPainter(this.t, {this.color = const Color(0xFFE8C46A)});
  final double t; // 0..1 loop
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    for (var layer = 0; layer < 4; layer++) {
      final petals = 6 + layer * 4;
      final rr = r * (0.35 + layer * 0.18);
      final dir = layer.isEven ? 1 : -1;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: 0.75 - layer * 0.14);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(dir * t * 2 * math.pi / (layer + 1));
      for (var i = 0; i < petals; i++) {
        canvas.rotate(2 * math.pi / petals);
        canvas.drawOval(Rect.fromCenter(center: Offset(0, -rr * 0.6), width: rr * 0.22, height: rr * 0.7), p);
      }
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.12, Paint()..color = color.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(MandalaPainter old) => old.t != t;
}

class MandalaLoop extends StatefulWidget {
  const MandalaLoop({super.key, this.size = 160, this.animate = true});
  final double size;
  final bool animate;
  @override
  State<MandalaLoop> createState() => _MandalaLoopState();
}

class _MandalaLoopState extends State<MandalaLoop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: MandalaPainter(_c.value)),
        ),
      );
}
