import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Page-local glass kit for the Gifts rebuild. Swap for NowssB Bug Hunter's
/// shared kit (GlassWrapper, GiftTile, BreathingGlow) once it lands on main.
class GiftsPalette {
  static const bgTop = Color(0xFF2A1E5C);
  static const bgBottom = Color(0xFF120C2E);
  static const violet = Color(0xFF9B8CFF);
  static const pink = Color(0xFFFF8FC7); // gifts = pink, everywhere
  static const amber = Color(0xFFFFC56B);
  static const teal = Color(0xFF7FE3D4);
  static const text = Color(0xFFF4F1FF);
  static const soft = Color(0xB3F4F1FF);
  static const glassFill = Color(0x1FFFFFFF);
  static const glassLine = Color(0x33FFFFFF);
}

class GiftsGlass extends StatelessWidget {
  const GiftsGlass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 22, this.tint});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            color: tint?.withValues(alpha: .16) ?? GiftsPalette.glassFill,
            border: Border.all(color: GiftsPalette.glassLine),
          ),
          child: Material(type: MaterialType.transparency, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

/// Slow breathing glow behind the hero gift box (section 16). Procedural.
class GiftsBreathingGlow extends StatefulWidget {
  const GiftsBreathingGlow({super.key, required this.child, this.color = GiftsPalette.pink, this.animate = true});
  final Widget child;
  final Color color;
  final bool animate;

  @override
  State<GiftsBreathingGlow> createState() => _GiftsBreathingGlowState();
}

class _GiftsBreathingGlowState extends State<GiftsBreathingGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = reduce ? .5 : Curves.easeInOut.transform(_c.value);
        return CustomPaint(painter: _GlowPainter(widget.color, .25 + .35 * t), child: child);
      },
      child: widget.child,
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.color, this.strength);
  final Color color;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.max(size.width, size.height) * .55;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: strength), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter o) => o.strength != strength || o.color != color;
}

/// Soft violet backdrop with floating blurred orbs (glass-meditation ref).
class GiftsBackdrop extends StatelessWidget {
  const GiftsBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [GiftsPalette.bgTop, GiftsPalette.bgBottom]),
        ),
        child: CustomPaint(painter: _OrbsPainter(), child: child),
      );
}

class _OrbsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    void orb(Offset o, double r, Color c) => canvas.drawCircle(
          o,
          r,
          Paint()..shader = RadialGradient(colors: [c.withValues(alpha: .35), c.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: r)),
        );
    orb(Offset(s.width * .85, s.height * .12), s.width * .45, GiftsPalette.violet);
    orb(Offset(s.width * .1, s.height * .55), s.width * .4, GiftsPalette.pink);
  }

  @override
  bool shouldRepaint(_OrbsPainter oldDelegate) => false;
}

/// Gift tile (spec ref 12): colored tile, big circle gift icon, caption,
/// valid-till and a colored bottom strip. Expired shows greyed with overlay.
class GiftTile extends StatelessWidget {
  const GiftTile(
      {super.key, required this.title, required this.caption, this.validTill = '', this.color = GiftsPalette.pink, this.expired = false, this.onTap});
  final String title;
  final String caption;
  final String validTill;
  final Color color;
  final bool expired;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Semantics(
      button: onTap != null,
      label: '$title. $caption${expired ? '. Expired' : ''}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: GiftsGlass(
          padding: EdgeInsets.zero,
          radius: 20,
          tint: color,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(radius: 22, backgroundColor: color.withValues(alpha: .3), child: Icon(Icons.card_giftcard_rounded, color: color)),
                const SizedBox(height: 10),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: GiftsPalette.text, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: GiftsPalette.soft, fontSize: 12)),
              ]),
            ),
            Container(
              height: 26,
              color: color.withValues(alpha: .45),
              alignment: Alignment.center,
              child: Text(validTill.isEmpty ? ' ' : validTill, style: const TextStyle(color: GiftsPalette.text, fontSize: 11)),
            ),
          ]),
        ),
      ),
    );
    if (!expired) return tile;
    return Stack(children: [
      Opacity(opacity: .45, child: ColorFiltered(colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation), child: tile)),
      const Positioned(top: 10, right: 10, child: _ExpiredChip()),
    ]);
  }
}

class _ExpiredChip extends StatelessWidget {
  const _ExpiredChip();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
        child: const Text('Expired', style: TextStyle(color: Colors.white, fontSize: 11)),
      );
}

class GiftsShortcut extends StatelessWidget {
  const GiftsShortcut({super.key, required this.icon, required this.label, required this.onTap, this.color = GiftsPalette.pink});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 76,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GiftsGlass(padding: const EdgeInsets.all(14), radius: 18, tint: color, child: Icon(icon, color: color, size: 26)),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: GiftsPalette.text, fontSize: 12)),
            ]),
          ),
        ),
      );
}
