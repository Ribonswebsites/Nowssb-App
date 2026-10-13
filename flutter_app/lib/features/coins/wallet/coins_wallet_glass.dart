import 'dart:ui';
import 'package:flutter/material.dart';

/// Page-local stand-in for Bug Hunter's shared GlassWrapper (§0.5 / §14.2).
/// Same parameters so it can be swapped for the kit with a single import change.
class CoinsGlass extends StatefulWidget {
  const CoinsGlass({super.key, required this.child, this.radius = 18, this.accent = const Color(0xFFB39DFF),
      this.blur = 0, this.padding = const EdgeInsets.all(16), this.elevation = 1, this.onTap});
  final Widget child;
  final double radius;
  final Color accent;
  final double blur;
  final EdgeInsets padding;
  final double elevation;
  final VoidCallback? onTap;
  @override
  State<CoinsGlass> createState() => _CoinsGlassState();
}

class _CoinsGlassState extends State<CoinsGlass> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(widget.radius);
    final lite = widget.blur <= 0;
    Widget box = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
          Colors.white.withValues(alpha: lite ? 0.26 : 0.22),
          Color.lerp(Colors.white, widget.accent, .5)!.withValues(alpha: lite ? 0.10 : 0.06),
        ]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.27)),
        boxShadow: [BoxShadow(color: widget.accent.withValues(alpha: 0.18 * widget.elevation), blurRadius: 24)],
      ),
      child: widget.child,
    );
    if (!lite) {
      box = RepaintBoundary(
        child: ClipRRect(borderRadius: r,
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur), child: box)));
    }
    if (widget.onTap == null) return box;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _down ? 0.97 : 1, duration: const Duration(milliseconds: 120), child: box),
    );
  }
}

/// Procedural golden lotus coin (no bundled art). Slow spin, respects reduce-motion.
class LotusCoin extends StatefulWidget {
  const LotusCoin({super.key, this.size = 72});
  final double size;
  @override
  State<LotusCoin> createState() => _LotusCoinState();
}

class _LotusCoinState extends State<LotusCoin> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final sx = 0.35 + 0.65 * (0.5 + 0.5 * (1 - 2 * ((_c.value * 2) % 1 - 0.5).abs()));
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(sx, 1, 1),
            child: CustomPaint(size: Size.square(widget.size), painter: _LotusPainter()),
          );
        },
      );
}

class _LotusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2;
    canvas.drawCircle(c, r, Paint()
      ..shader = const RadialGradient(colors: [Color(0xFFFFE9A8), Color(0xFFE0A526), Color(0xFFA9700E)])
          .createShader(Rect.fromCircle(center: c, radius: r)));
    final petal = Paint()..color = const Color(0xFFFFF4CF).withValues(alpha: .85);
    for (var i = -2; i <= 2; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy + r * .25);
      canvas.rotate(i * 0.42);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -r * .32), width: r * .32, height: r * .7), petal);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
