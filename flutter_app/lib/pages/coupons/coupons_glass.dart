/// Page-local glass pieces (spec 0.5 / 6). Swap for the shared
/// GlassWrapper kit (14.2) from NowssB Bug Hunter when it lands on main.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'coupon_models.dart';

const kCouponViolet = Color(0xFF8B6CF0);

Color rarityAccent(CouponRarity r) => switch (r) {
      CouponRarity.common => const Color(0xFF9FB4D8),
      CouponRarity.rare => const Color(0xFF4FD8EB),
      CouponRarity.epic => const Color(0xFFC254E8),
      CouponRarity.legendary => const Color(0xFFF2B33D),
    };

String rarityName(CouponRarity r) => switch (r) {
      CouponRarity.common => 'Common',
      CouponRarity.rare => 'Rare',
      CouponRarity.epic => 'Epic',
      CouponRarity.legendary => 'Legendary',
    };

/// Glass box. [lite] skips the blur (for nesting inside a blurred shell).
class CouponGlass extends StatelessWidget {
  const CouponGlass({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(12),
    this.tint = Colors.white,
    this.lite = true,
    this.clipper,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color tint;
  final bool lite;
  final CustomClipper<Path>? clipper;

  @override
  Widget build(BuildContext context) {
    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: clipper == null ? BorderRadius.circular(radius) : null,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.20), tint.withValues(alpha: 0.07)],
        ),
        border: clipper == null ? Border.all(color: Colors.white.withValues(alpha: 0.25)) : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (!lite) {
      box = BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: box);
    }
    return RepaintBoundary(
      child: clipper != null
          ? ClipPath(clipper: clipper, child: box)
          : ClipRRect(borderRadius: BorderRadius.circular(radius), child: box),
    );
  }
}

/// Rounded 22px ticket with circular notches mid-left and mid-right.
class TicketClipper extends CustomClipper<Path> {
  const TicketClipper({this.radius = 22, this.notch = 10});
  final double radius, notch;

  @override
  Path getClip(Size s) {
    final body = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(radius)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, s.height / 2), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(s.width, s.height / 2), radius: notch));
    return Path.combine(PathOperation.difference, body, holes);
  }

  @override
  bool shouldReclip(TicketClipper old) => old.radius != radius || old.notch != notch;
}

/// Procedural 3D-ish coupon art (no bundled images).
class CouponArtPainter extends CustomPainter {
  const CouponArtPainter({this.t = 0});
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final ctr = Offset(s.width / 2, s.height / 2);
    c.save();
    c.translate(ctr.dx, ctr.dy);
    c.rotate(-0.18 + 0.06 * t);
    final r = Rect.fromCenter(center: Offset.zero, width: s.width * 0.7, height: s.height * 0.5);
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(6, 10)), const Radius.circular(16)), shadow);
    final fill = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFE6D9FF), Color(0xFFA48BF5), Color(0xFF7A5AE6)])
          .createShader(r);
    final path = const TicketClipper(radius: 16, notch: 12).getClip(r.size).shift(r.topLeft);
    c.drawPath(path, fill);
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2;
    for (var y = r.top + 6; y < r.bottom - 6; y += 8) {
      c.drawLine(Offset(r.left + r.width * 0.32, y), Offset(r.left + r.width * 0.32, y + 4), dash);
    }
    final tp = TextPainter(
      text: const TextSpan(text: '%', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(r.left + r.width * 0.62 - tp.width / 2, -tp.height / 2));
    c.restore();
  }

  @override
  bool shouldRepaint(CouponArtPainter old) => old.t != t;
}
