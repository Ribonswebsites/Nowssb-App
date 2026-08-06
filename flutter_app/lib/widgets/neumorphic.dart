/// The Normal home's surface language, as one widget.
///
/// Every card on that page is the same thing: the page's own colour, a
/// radius, and the two-shadow pair that makes it read as raised out of the
/// page rather than laid on top of it. Doing it once here is why the port
/// can stay honest to the CSS — there is one place to change when the CSS
/// changes, instead of forty.
library;

import 'package:flutter/material.dart';
import '../theme/tokens.dart';

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

/// The black banner that closes most sections — .nmh-sec-banner.
/// Round icon, hairline rule, title and sub, arrow.
class NwsbBanner extends StatelessWidget {
  const NwsbBanner({
    super.key,
    required this.title,
    required this.sub,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String sub;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(NwsbRadius.bar),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF14141C),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: NwsbColors.goldLight),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 34, color: const Color(0x1FFFFFFF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0x8CFFFFFF),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward,
                size: 18, color: Color(0xE6FFFFFF)),
          ],
        ),
      ),
    );
  }
}
