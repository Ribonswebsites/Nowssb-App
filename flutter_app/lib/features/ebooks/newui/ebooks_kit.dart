import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Page-local stand-ins for the shared widget kit (spec 14.2). Replace with
/// Bug Hunter's GlassWrapper / OutlineCard / PriceStrip when they land.
class EbColors {
  static const bg = Color(0xFF140F2B);
  static const violet = Color(0xFF8E7CFF);
  static const lilac = Color(0xFFD9CCFF);
  static const gold = Color(0xFFE8D5A3);
  static const ink = Color(0xFFF5F2FF);
  static const dim = Color(0xB3F5F2FF);
}

/// Frosted violet glass around any item (spec 0.5).
class EbGlass extends StatelessWidget {
  const EbGlass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 22, this.outline});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? outline;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x33FFFFFF), Color(0x14FFFFFF)],
              ),
              border: Border.all(color: outline ?? const Color(0x33FFFFFF), width: outline == null ? 1 : 1.6),
            ),
            child: child,
          ),
        ),
      );
}

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

/// Pill button: outlined or filled, with a "what happens next" line.
class EbPill extends StatelessWidget {
  const EbPill({super.key, required this.label, required this.onTap, this.filled = false, this.icon});
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: filled ? EbColors.violet : Colors.transparent,
              border: Border.all(color: filled ? EbColors.violet : EbColors.lilac),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: EbColors.ink), const SizedBox(width: 6)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EbColors.ink, fontWeight: FontWeight.w700))),
            ]),
          ),
        ),
      );
}

/// ⓘ icon that opens a black-card-in-glass pop-up (spec 19.3).
class EbInfo extends StatelessWidget {
  const EbInfo({super.key, required this.title, required this.text, required this.example});
  final String title, text, example;
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'What is $title?',
        iconSize: 18,
        icon: const Icon(Icons.info_outline_rounded, color: EbColors.lilac),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (c) => Dialog(
            backgroundColor: Colors.transparent,
            child: EbGlass(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xE6000000), borderRadius: BorderRadius.circular(16)),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: EbColors.ink, fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(text, style: const TextStyle(color: EbColors.dim, height: 1.5)),
                  const SizedBox(height: 8),
                  Text(example, style: const TextStyle(color: EbColors.gold, height: 1.5)),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.pop(c), child: const Text('Got it'))),
                ]),
              ),
            ),
          ),
        ),
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
        Paint()..shader = RadialGradient(colors: [EbColors.violet.withValues(alpha: 0.35), Colors.transparent]).createShader(Rect.fromCircle(center: c, radius: size.height * 0.45)));
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
      canvas.drawRRect(r, Paint()..color = EbColors.lilac.withValues(alpha: alpha * (0.4 + 0.6 * scaleX.abs())));
      canvas.restore();
      // dust butterflies leaving the page edge
      final rnd = math.Random(i * 31);
      for (var k = 0; k < 7; k++) {
        final d = (p + k * 0.07) % 1.0;
        final x = c.dx + scaleX * w + (rnd.nextDouble() - 0.3) * size.width * 0.5 * d;
        final y = c.dy - h * rnd.nextDouble() - d * size.height * 0.5;
        final flap = 2 + 2 * math.sin((t * 40 + k) * math.pi).abs();
        final paint = Paint()..color = EbColors.gold.withValues(alpha: (1 - d) * 0.8);
        canvas.drawOval(Rect.fromCenter(center: Offset(x - flap, y), width: flap * 1.6, height: 3), paint);
        canvas.drawOval(Rect.fromCenter(center: Offset(x + flap, y), width: flap * 1.6, height: 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PagesPainter old) => old.t != t;
}
