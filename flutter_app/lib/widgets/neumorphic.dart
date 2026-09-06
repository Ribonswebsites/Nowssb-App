/// The Normal home's surface language, as one widget.
///
/// Every card on that page is the same thing: the page's own colour, a
/// radius, and the two-shadow pair that makes it read as raised out of the
/// page rather than laid on top of it. Doing it once here is why the port
/// can stay honest to the CSS — there is one place to change when the CSS
/// changes, instead of forty.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../screens/normal/glassmorphism_theme.dart';

enum NwsbElevation { sm, md, xs }

class NeuCard extends StatelessWidget {
  const NeuCard({
    super.key,
    required this.child,
    this.radius = NwsbRadius.card,
    this.padding = const EdgeInsets.all(20),
    this.elevation = NwsbElevation.md,
    this.onTap,
    this.color,
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final NwsbElevation elevation;
  final VoidCallback? onTap;
  final Color? color;

  List<BoxShadow> get _shadow => switch (elevation) {
        NwsbElevation.md => NwsbShadows.raised,
        NwsbElevation.sm => NwsbShadows.raisedSm,
        NwsbElevation.xs => NwsbShadows.raisedXs,
      };

  @override
  Widget build(BuildContext context) {
    if (NormalGlassMode.of(context)) {
      final glass = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0x5CFFFFFF),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: const Color(0xF2FFFFFF), width: 1.5),
            ),
            child: child,
          ),
        ),
      );
      return onTap == null
          ? glass
          : GestureDetector(onTap: onTap, child: glass);
    }
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: _shadow,
      ),
      child: child,
    );
    if (onTap == null) return body;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}
