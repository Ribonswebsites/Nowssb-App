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

/// Frosted card from card-reference-exact.png: translucent light-lavender
/// panel, 1px bright white border, large radius, soft blur + drop shadow.
/// [inner] is the smaller, slightly less transparent inner panel (r20).
/// [tint] is ignored for the fill (kept for API); rarity shows as text only.
class CouponGlass extends StatelessWidget {
  const CouponGlass({
    super.key,
    required this.child,
    this.radius = 30,
    this.padding = const EdgeInsets.all(14),
    this.tint = Colors.white,
    this.lite = false,
    this.inner = false,
    this.clipper,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color tint;
  final bool lite, inner;
  final CustomClipper<Path>? clipper;

  static const fill = Color(0x2EEDE8FF); // light lavender/white ~18%
  static const innerFill = Color(0x45F3F0FF); // ~27%, less transparent
  static const border = Color(0x8CFFFFFF); // white 55%, 1px

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: inner ? innerFill : fill,
        borderRadius: r,
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (!lite && !inner) {
      box = BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: box);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: inner ? null : const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: RepaintBoundary(child: ClipRRect(borderRadius: r, child: box)),
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
