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

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../media/nwsb_image.dart';
import '../theme/tokens.dart';
import 'nwsb_icon.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

enum HeadingMotion { roll, flip, slide, float, shimmer, marquee }

/// A continuously moving heading. The mode is intentionally varied so a long
/// home page feels alive without every heading moving in the same way.
class AnimatedHeading extends StatefulWidget {
  const AnimatedHeading(
    this.text, {
    super.key,
    required this.style,
    this.maxLines,
    this.overflow,
    this.mode,
  });

  final String text;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;
  final HeadingMotion? mode;

  @override
  State<AnimatedHeading> createState() => _AnimatedHeadingState();
}

class _AnimatedHeadingState extends State<AnimatedHeading>
    with SingleTickerProviderStateMixin {
  Timer? _motionTimer;
  double _phase = 0;
  late final AnimationController _marquee = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7600),
  );

  @override
  void initState() {
    super.initState();
    if (_flutterTest) return;
    _marquee.repeat();
    // A finite animation is deliberately retriggered by a timer rather than
    // driven by an always-on ticker. This keeps the home lively in production
    // while allowing widget tests and accessibility tooling to settle.
    _motionTimer = Timer.periodic(
      Duration(milliseconds: 3600 + (widget.text.length % 5) * 180),
      (_) {
        if (mounted) setState(() => _phase = _phase == 0 ? 1 : 0);
      },
    );
  }

  HeadingMotion get _motion =>
      widget.mode ??
      HeadingMotion
          .values[widget.text.codeUnitAt(0) % HeadingMotion.values.length];

  @override
  void dispose() {
    _motionTimer?.cancel();
    _marquee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final needsMarquee = painter.width > constraints.maxWidth;
        if (needsMarquee) {
          final gap = 36.0;
          final travel = painter.width + gap;
          return SizedBox(
            height: painter.height,
            width: constraints.maxWidth,
            child: AnimatedBuilder(
              animation: _marquee,
              builder: (_, __) {
                final offset = -(_marquee.value * travel);
                return ClipRect(
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        left: offset,
                        top: 0,
                        child: Row(
                          children: [
                            Text(widget.text,
                                maxLines: 1,
                                softWrap: false,
                                style: widget.style),
                            SizedBox(width: gap),
                            Text(widget.text,
                                maxLines: 1,
                                softWrap: false,
                                style: widget.style),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }
        return _animatedTransform(Text(widget.text,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
            style: widget.style));
      },
    );
  }

  Widget _animatedTransform(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1, end: _phase),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, value, child) {
        final t = value;
        switch (_motion) {
          case HeadingMotion.roll:
            return Transform.translate(offset: Offset(t * 3, 0), child: child);
          case HeadingMotion.flip:
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(t * 0.035),
              child: child,
            );
          case HeadingMotion.slide:
            return Transform.translate(
                offset: Offset(0, t * 2.5), child: child);
          case HeadingMotion.float:
            return Transform.translate(
                offset: Offset(t * 1.5, t * -2), child: child);
          case HeadingMotion.shimmer:
            return Opacity(opacity: 0.86 + ((value + 1) * 0.07), child: child);
          case HeadingMotion.marquee:
            return child!;
        }
      },
      child: child is Text
          ? child
          : Text(widget.text,
              maxLines: widget.maxLines,
              overflow: widget.overflow,
              style: widget.style),
    );
  }
}

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
                child: NwsbIcon(mark,
                    size: 19, viewBox: markViewBox, strokeWidth: 1.6),
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
                      child: AnimatedHeading(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, color: Color(0xCCFFFFFF)),
                        mode: HeadingMotion.marquee,
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
/// Rounded black bar matching CustomizeBlackBanner / request-customized
/// language (radius 20). Continuous marquee copy — never a sharp edge.
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x29FFFFFF)),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  GentleMarqueeText(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0x8CFFFFFF),
                      height: 1.35,
                    ),
                    duration: const Duration(milliseconds: 4200),
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
    if (_flutterTest) return;
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
                  size: 13,
                  viewBox: 12,
                  strokeWidth: 1.9,
                  color: NwsbColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass-wrapped Enter for Today's Practice / NowssB Player heroes.
/// Middle-right overlay: frosted pill around the label + arrow disc.
class GlassEnterPill extends StatelessWidget {
  const GlassEnterPill({super.key, this.label = 'Enter', this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            decoration: BoxDecoration(
              color: const Color(0x38FFFFFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x59FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
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
                    child: NwsbIcon(
                      NwsbMarks.enterArrow,
                      size: 13,
                      viewBox: 12,
                      strokeWidth: 1.9,
                      color: NwsbColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ensure video/image paints edge-to-edge inside the rounded clip.
              Positioned.fill(child: background),
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
                    AnimatedHeading(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15),
                      mode: HeadingMotion.roll,
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

/// True continuous marquee — text repeats so glyphs never clip mid-letter.
/// Apply only to subtitle slots under a heading (not titles / body / every
/// SecBanner title line). Customize banners keep subtitle motion.
class GentleMarqueeText extends StatefulWidget {
  const GentleMarqueeText(
    this.text, {
    super.key,
    required this.style,
    this.duration = const Duration(milliseconds: 9000),
    this.maxLines = 1,
  });

  final String text;
  final TextStyle style;
  final Duration duration;
  final int maxLines;

  @override
  State<GentleMarqueeText> createState() => _GentleMarqueeTextState();
}

class _GentleMarqueeTextState extends State<GentleMarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(GentleMarqueeText old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) {
      _c.duration = widget.duration;
      _syncTicker();
    }
  }

  void _syncTicker() {
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final ticking = TickerMode.of(context);
    if (disabled || !ticking) {
      if (_c.isAnimating) _c.stop();
      return;
    }
    if (!_c.isAnimating) _c.repeat(); // forward-only continuous scroll
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disabled || !TickerMode.of(context)) {
      return Text(
        widget.text,
        maxLines: widget.maxLines,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        // Always marquee with a repeated strip so short titles also move
        // continuously and long titles never clip mid-glyph.
        const gap = 48.0;
        final unit = painter.width + gap;
        final height = (painter.height * 1.35).clamp(16.0, 48.0);
        return SizedBox(
          height: height,
          width: constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : painter.width,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final offset = -(_c.value * unit);
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: offset,
                      top: (height - painter.height) / 2,
                      child: Row(
                        children: [
                          Text(widget.text,
                              maxLines: 1,
                              softWrap: false,
                              style: widget.style),
                          const SizedBox(width: gap),
                          Text(widget.text,
                              maxLines: 1,
                              softWrap: false,
                              style: widget.style),
                          const SizedBox(width: gap),
                          Text(widget.text,
                              maxLines: 1,
                              softWrap: false,
                              style: widget.style),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Thin moving black banner strip for section motion without layout redesign.
/// Sits above or below existing section content; copy slides gently.
class SectionMotionBanner extends StatelessWidget {
  const SectionMotionBanner({
    super.key,
    required this.title,
    this.sub,
    this.compact = true,
  });

  final String title;
  final String? sub;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: compact ? 10 : 14),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 11 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          if (sub != null && sub!.isNotEmpty) ...[
            const SizedBox(height: 2),
            GentleMarqueeText(
              sub!,
              style: TextStyle(
                color: const Color(0xB3FFFFFF),
                fontSize: compact ? 10 : 11,
              ),
              duration: const Duration(milliseconds: 4200),
            ),
          ],
        ],
      ),
    );
  }
}

