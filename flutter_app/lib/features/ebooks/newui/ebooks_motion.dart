import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../nowssb_ui/nowssb_ui.dart';

/// E-books-only pieces the shared nowssb_ui kit doesn't have: the colored
/// price strip under a cover and the spec 15 #9 hero animation.

/// Colored price strip under a card.
class EbPriceStrip extends StatelessWidget {
  const EbPriceStrip({super.key, required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
      );
}

/// Procedural hero (spec 15 subject 9): pages of light turning slowly and
/// dissolving into butterflies of glowing dust. Still when [reduce] is on.
class EbPagesOfLight extends StatefulWidget {
  const EbPagesOfLight({super.key, this.height = 200, this.reduce = false});
  final double height;
  final bool reduce;
  @override
  State<EbPagesOfLight> createState() => _EbPagesOfLightState();
}

class _EbPagesOfLightState extends State<EbPagesOfLight> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  @override
  void initState() {
    super.initState();
    if (!widget.reduce) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = widget.reduce || MediaQuery.maybeOf(context)?.disableAnimations == true;
    if (reduce && _c.isAnimating) _c.stop();
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(painter: _PagesPainter(_c.value), size: Size.infinite),
          ),
        ),
      ),
    );
  }
}

class _PagesPainter extends CustomPainter {
  _PagesPainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.62);
    canvas.drawCircle(c, size.height * 0.45,
        Paint()..shader = RadialGradient(colors: [NTokens.violet.withValues(alpha: 0.35), Colors.transparent]).createShader(Rect.fromCircle(center: c, radius: size.height * 0.45)));
    final w = size.height * 0.34, h = size.height * 0.46;
    for (var i = 0; i < 4; i++) {
      final p = (t + i / 4) % 1.0;
      final angle = -math.pi * p; // page turns right→left
      final scaleX = math.cos(angle);
      final alpha = (1 - p) * 0.55;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.transform((Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(angle)).storage);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, -h, w, h), const Radius.circular(6));
      canvas.drawRRect(r, Paint()..color = NTokens.textLo.withValues(alpha: alpha * (0.4 + 0.6 * scaleX.abs())));
      canvas.restore();
      // dust butterflies leaving the page edge
      final rnd = math.Random(i * 31);
      for (var k = 0; k < 7; k++) {
        final d = (p + k * 0.07) % 1.0;
        final x = c.dx + scaleX * w + (rnd.nextDouble() - 0.3) * size.width * 0.5 * d;
        final y = c.dy - h * rnd.nextDouble() - d * size.height * 0.5;
        final flap = 2 + 2 * math.sin((t * 40 + k) * math.pi).abs();
        final paint = Paint()..color = NTokens.gold.withValues(alpha: (1 - d) * 0.8);
        canvas.drawOval(Rect.fromCenter(center: Offset(x - flap, y), width: flap * 1.6, height: 3), paint);
        canvas.drawOval(Rect.fromCenter(center: Offset(x + flap, y), width: flap * 1.6, height: 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PagesPainter old) => old.t != t;
}
