/// Procedural "Aura" background (spec 16): soft violet orbs that breathe.
/// Pure CustomPainter, no bundled assets. Static when animations are off.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../nowssb_ui/nowssb_ui.dart';

class StoreAura extends StatefulWidget {
  const StoreAura({super.key, required this.child});
  final Widget child;

  @override
  State<StoreAura> createState() => _StoreAuraState();
}

class _StoreAuraState extends State<StoreAura> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _AuraPainter(_c)),
          ),
        ),
        widget.child,
      ]);
}

class _AuraPainter extends CustomPainter {
  _AuraPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [NTokens.bgTop, NTokens.bgBottom],
        ).createShader(rect),
    );
    final v = Curves.easeInOut.transform(t.value);
    void orb(double x, double y, double r, Color c) {
      final center = Offset(size.width * x, size.height * y);
      final rad = r * size.shortestSide * (0.9 + .15 * v);
      canvas.drawCircle(
        center,
        rad,
        Paint()
          ..shader = RadialGradient(colors: [c.withValues(alpha: .55), c.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: rad)),
      );
    }

    orb(.15 + .04 * math.sin(v * math.pi), .12, .55, NTokens.violet);
    orb(.9, .38 - .03 * v, .45, NTokens.pink);
    orb(.3, .82, .6, NTokens.mint.withValues(alpha: .7));
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) => false;
}
