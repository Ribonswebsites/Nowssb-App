/// The pieces both homes repeat.
///
/// These are not Fashion furniture, which is why they do not live under
/// `screens/fashion/`. `.spill`, `.nmh-sec-banner` and `.ncb-carousel` are
/// BLACK components in the stylesheet, and they are black on both homes —
/// the pale page puts a raised shadow under them and the dark page does not,
/// but the bar itself is the same bar. What differs between the homes is the
/// WRAPPER around a section, not the parts inside it.
///
/// The website builds each of them by hand every time it needs one. Written
/// once here so a change lands everywhere:
///
///   Spill      `.spill` — a round mark and, beside it, a pill carrying a
///              small icon, a hairline rule and one line of text. It sits
///              ABOVE a section and names it.
///   SecBanner  `.nmh-sec-banner` — the black bar that closes a section:
///              round icon, vertical rule, title over sub, arrow.
///   EnterPill  `.tp-enter` / `.reader-sec-cta` — the small white chip with
///              "Enter" and an arrow in a disc.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../media/nwsb_image.dart';
import '../theme/tokens.dart';
import 'nwsb_icon.dart';

/// The mark-and-pill that introduces a section.
class Spill extends StatelessWidget {
  const Spill({
    super.key,
    required this.label,
    required this.mark,
    this.markViewBox = 22,
    this.pillArt,
    this.onTap,
  });

  final String label;

  /// The SVG path in the round mark — one of [NwsbMarks].
  final String mark;

  /// The box that path was drawn in. The spill marks are 22, not 24.
  final double markViewBox;

  /// The picture in the pill's little disc, as index.html names it. Where a
  /// spill has no picture the mark is repeated, which is what the Reader's
  /// and eBooks' markup does.
  final String? pillArt;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              // `.spill-circle` — flat black with a hairline, 40px, and the
              // mark at 19.
              child: Center(
                child: NwsbIcon(mark, size: 19, viewBox: markViewBox,
                    strokeWidth: 1.6),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0x1AE8D5A3),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x3DE8D5A3)),
                      ),
                      child: pillArt == null
                          ? Center(
                              child: NwsbIcon(mark,
                                  size: 13,
                                  viewBox: markViewBox,
                                  color: NwsbColors.goldLight),
                            )
                          : NwsbImage(
                              url: pillArt!,
                              fallback: Center(
                                child: NwsbIcon(mark,
                                    size: 13,
                                    viewBox: markViewBox,
                                    color: NwsbColors.goldLight),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                        width: 1, height: 18, color: const Color(0x2EFFFFFF)),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.nmh-sec-banner` — the black bar under a section.
///
/// Square on the Fashion home, like everything else on it, and without the
/// neumorphic shadow: that white half-shadow is light-home furniture and on
/// dark glass it reads as a halo. Same lesson the website learned.
class SecBanner extends StatelessWidget {
  const SecBanner({
    super.key,
    required this.title,
    required this.sub,
    required this.mark,
    this.markViewBox = 24,
    this.art,
    this.onTap,
  });

  final String title;
  final String sub;

  /// The SVG path in the round tile — one of [NwsbMarks].
  final String mark;
  final double markViewBox;

  /// Some bars carry a picture in the tile instead of a path, and where
  /// index.html names one this is that URL.
  final String? art;

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
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Color(0xFF14141C),
                shape: BoxShape.circle,
              ),
              child: art == null
                  ? Center(
                      child: NwsbIcon(mark,
                          size: 19,
                          viewBox: markViewBox,
                          color: NwsbColors.goldLight),
                    )
                  : NwsbImage(
                      url: art!,
                      fallback: Center(
                        child: NwsbIcon(mark,
                            size: 19,
                            viewBox: markViewBox,
                            color: NwsbColors.goldLight),
                      ),
                    ),
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
            const NwsbIcon(NwsbMarks.arrow, size: 18, color: Color(0xE6FFFFFF)),
          ],
        ),
      ),
    );
  }
}

/// `.ncb-carousel` — a [SecBanner] whose contents change.
///
/// One bar, one row of dots, and a slide every 3200ms — app/js/part049.js:228.
/// It closes Connect, Subscription and the Store, and on a bar with a single
/// slide it is simply that bar with no dots, which is how the markup uses it
/// in two of those three places.
class NcbCarousel extends StatefulWidget {
  const NcbCarousel({super.key, required this.slides, this.onTap});

  /// (mark, name, sub) — the three things a slide carries.
  final List<(String, String, String)> slides;
  final VoidCallback? onTap;

  @override
  State<NcbCarousel> createState() => _NcbCarouselState();
}

class _NcbCarouselState extends State<NcbCarousel> {
  Timer? _t;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    if (widget.slides.length > 1) {
      _t = Timer.periodic(const Duration(milliseconds: 3200), (_) {
        // `if (document.hidden) return` — a bar nobody is looking at does
        // not need to be rebuilt every three seconds.
        if (!mounted || !TickerMode.valuesOf(context).enabled) return;
        setState(() => _i = (_i + 1) % widget.slides.length);
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (mark, name, sub) = widget.slides[_i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: SecBanner(
            key: ValueKey(_i),
            title: name,
            sub: sub,
            mark: mark,
            onTap: widget.onTap,
          ),
        ),
        if (widget.slides.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.slides.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: i == _i ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _i
                          ? NwsbColors.goldLight
                          : const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The white "Enter →" chip.
class EnterPill extends StatelessWidget {
  const EnterPill({super.key, this.label = 'Enter', this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: NwsbIcon(NwsbMarks.enterArrow,
                  size: 13, viewBox: 12, strokeWidth: 1.9,
                  color: NwsbColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card whose background is a picture with words over it — the shape
/// `.home-card` takes on this home. The scrim is what keeps white type
/// legible over any frame of any picture.
class PhotoCard extends StatelessWidget {
  const PhotoCard({
    super.key,
    required this.background,
    required this.label,
    required this.title,
    required this.sub,
    this.aspect = 16 / 9,
    this.onTap,
  });

  final Widget background;
  final String label;
  final String title;
  final String sub;
  final double aspect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: aspect,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              background,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x8C000000), Color(0xF2000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: NwsbColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xB3FFFFFF),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: EnterPill(onTap: onTap),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.fash-banner-cta` — the dark chip that sits ON a clip.
///
/// The mark is the cart on every one of them: `.nmh-cta-go` carries the same
/// trolley whether the chip says Subscribe Today or Shop Now, because both
/// end at the same till.
class ScreenCta extends StatelessWidget {
  const ScreenCta({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xB3000000),
          border: Border.all(color: const Color(0x2EFFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x2EFFFFFF)),
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 13, color: Color(0xEBFFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}
