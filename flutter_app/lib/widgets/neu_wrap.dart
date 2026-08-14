/// The pane every Normal-home section sits on, and the head it opens with.
///
/// The Fashion home's twin of this is `glass_wrap.dart`. They are the same
/// idea in two different languages, and that is the whole difference between
/// the two homes: a section is a pane of GLASS over a film on one, and a
/// card RAISED out of the page on the other. Everything inside a section is
/// the same on both.
///
/// Lifted value for value from `#home-nm .nmh-sec-wrap` at nowssb-nm.css:9923
/// and `#home-nm .nmh-wrap-head` at :15005.
///
///     margin    16 vertical
///     padding   14
///     fill      #f0f2f7            ← the page's own colour
///     radius    22
///     shadow    7px 7px 16px rgba(0,0,0,0.14)
///               -5px -5px 12px rgba(255,255,255,0.97)
///     children  10 apart
///
/// The shadow is TWO shadows, never one: a dark one down-right and a white
/// one up-left. Drop either and the card stops reading as raised and starts
/// reading as a box drawn on the page, which is the one thing this whole
/// surface language is.
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class SecWrap extends StatelessWidget {
  const SecWrap({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
  });

  /// Spaced 10 apart, which is what `.nmh-sec-wrap > * + *` does.
  final List<Widget> children;
  final EdgeInsets padding;
  final EdgeInsets margin;

  static const radius = 22.0;

  /// `box-shadow: 7px 7px 16px rgba(0,0,0,0.14), -5px -5px 12px rgba(255,255,255,0.97)`
  static const shadow = <BoxShadow>[
    BoxShadow(color: Color(0x24000000), offset: Offset(7, 7), blurRadius: 16),
    BoxShadow(color: Color(0xF7FFFFFF), offset: Offset(-5, -5), blurRadius: 12),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        padding: padding,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: NwsbColors.surface,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// `.nmh-wrap-head` — a raised disc, then a light line over a heavy one.
///
/// The Fashion home's `SectionHead` is the same shape in the other language:
/// there the disc is white on glass, here it is the page's own colour raised
/// out of the page, with the gold mark that every disc on this home carries.
class WrapHead extends StatelessWidget {
  const WrapHead({
    super.key,
    required this.eyebrow,
    required this.title,
    this.icon,
    this.mark,
  });

  final String eyebrow;
  final String title;

  /// A Material stand-in, used until [mark] can point at the real artwork.
  final IconData? icon;

  /// The section's own mark, when it is a bundled picture.
  final Widget? mark;

  /// `color: #b39a5e` — a shade darker than the eyebrow gold, because this
  /// one sits on a pale surface rather than a dark one.
  static const markGold = Color(0xFFB39A5E);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // `margin: 2px 0 14px`, and `padding-right: 40px` to clear the cross.
      padding: const EdgeInsets.fromLTRB(0, 2, 40, 0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: NwsbColors.surface,
              shape: BoxShape.circle,
              boxShadow: NwsbShadows.raisedXs,
            ),
            child: mark ??
                Icon(icon ?? Icons.circle_outlined, size: 21, color: markGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                    color: Color(0x801A1A2E), // rgba(26,26,46,0.5)
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: NwsbColors.ink,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
