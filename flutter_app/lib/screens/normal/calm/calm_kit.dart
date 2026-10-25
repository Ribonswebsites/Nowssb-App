/// Calm kit — the normal home's quiet, image-free building blocks.
///
/// Light grey page, soft neumorphic wrappers, small pastel rounded cards
/// grouped 3–5 at a time. Every tappable piece reports a string action id so
/// the home decides where it goes (and tests can assert it without routing).
library;

import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../widgets/nwsb_icon.dart';

typedef CalmAct = void Function(String action);

/// Pastel pairs: (card fill, ink).
class CalmTone {
  const CalmTone(this.fill, this.ink);
  final Color fill;
  final Color ink;

  static const sage = CalmTone(Color(0xFFDCEBDF), Color(0xFF2F5D45));
  static const lilac = CalmTone(Color(0xFFE5E0F6), Color(0xFF4B3F8C));
  static const peach = CalmTone(Color(0xFFF8E2D3), Color(0xFF8A4B26));
  static const sky = CalmTone(Color(0xFFDBEAF6), Color(0xFF285A85));
  static const sand = CalmTone(Color(0xFFF4EBD3), Color(0xFF7A5A12));
  static const rose = CalmTone(Color(0xFFF6DDE5), Color(0xFF8A2D4D));
  static const mint = CalmTone(Color(0xFFD7F0EC), Color(0xFF1F6B62));
  static const mist = CalmTone(Color(0xFFE6E9F0), Color(0xFF3C4258));

  /// A pale card from any brand colour (the colour itself becomes the ink).
  factory CalmTone.of(Color c) => CalmTone(
        Color.alphaBlend(c.withValues(alpha: 0.20), Colors.white),
        Color.lerp(c, Colors.black, 0.38)!,
      );
}

const calmInk = Color(0xFF2B2D3A);
const calmSoft = Color(0xFF6F7385);

double calmScale(BuildContext c) => MediaQuery.textScalerOf(c).scale(10) / 10;

BoxDecoration calmRaised([double r = 28]) => BoxDecoration(
      color: NwsbColors.surface,
      borderRadius: BorderRadius.circular(r),
      boxShadow: NwsbShadows.raisedSm,
    );

BoxDecoration calmInset([double r = 22]) => BoxDecoration(
      borderRadius: BorderRadius.circular(r),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFDDE0E8), Color(0xFFEDEFF4), Color(0xFFF9FAFC)],
      ),
      border: Border.all(color: const Color(0x14000000)),
    );

/// Section heading: small eyebrow, title, optional trailing link.
class CalmHead extends StatelessWidget {
  const CalmHead(this.title, {super.key, this.eyebrow, this.more, this.onMore});
  final String title;
  final String? eyebrow;
  final String? more;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (eyebrow != null)
                Text(eyebrow!.toUpperCase(),
                    style: const TextStyle(fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: calmSoft)),
              Text(title,
                  style: const TextStyle(fontSize: 19, height: 1.2, fontWeight: FontWeight.w700, color: calmInk)),
            ]),
          ),
          if (more != null)
            GestureDetector(
              onTap: onMore,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 2),
                child: Text(more!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5B5BD6))),
              ),
            ),
        ]),
      );
}

/// The rounded wrapper a group of small cards sits in.
class CalmWrap extends StatelessWidget {
  const CalmWrap({super.key, required this.child, this.tint, this.padding = const EdgeInsets.all(10)});
  final Widget child;
  final Color? tint;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: padding,
          decoration: tint == null
              ? calmRaised()
              : BoxDecoration(color: tint, borderRadius: BorderRadius.circular(28)),
          child: child,
        ),
      );
}

/// White disc holding a line mark.
class CalmDisc extends StatelessWidget {
  const CalmDisc(this.mark, {super.key, required this.color, this.size = 34});
  final String mark;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.78), shape: BoxShape.circle),
        child: NwsbIcon(mark, size: size * 0.5, color: color, strokeWidth: 1.8),
      );
}

/// Small pastel card: disc, title, optional sub. Fills its parent's width.
class CalmTile extends StatelessWidget {
  const CalmTile({
    super.key,
    required this.title,
    required this.tone,
    required this.onTap,
    this.mark,
    this.sub,
    this.badge,
    this.dense = false,
  });
  final String title;
  final String? sub;
  final String? mark;
  final String? badge;
  final CalmTone tone;
  final VoidCallback onTap;
  final bool dense;

  /// Titles never break mid-word: one-word titles shrink to fit, and small
  /// grid tiles cap the text scale a little so their words stay whole.
  Widget _title() {
    final style = TextStyle(fontSize: dense ? 13 : 14.5, height: 1.2, fontWeight: FontWeight.w700, color: tone.ink);
    if (!title.contains(' ')) {
      return FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(title, maxLines: 1, style: style));
    }
    if (!dense) return Text(title, style: style);
    return Builder(
      builder: (context) => Text(title,
          style: style, textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1)),
    );
  }

  @override
  Widget build(BuildContext context) => Material(
        color: tone.fill,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(dense ? 10 : 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                if (mark != null) CalmDisc(mark!, color: tone.ink, size: dense ? 28 : 34),
                const Spacer(),
                if (badge != null)
                  Flexible(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(99)),
                      child: Text(badge!,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tone.ink)),
                    ),
                  ),
              ]),
              SizedBox(height: dense ? 8 : 12),
              _title(),
              if (sub != null) ...[
                const SizedBox(height: 3),
                Text(sub!,
                    style: TextStyle(fontSize: 11.5, height: 1.25, color: tone.ink.withValues(alpha: 0.72))),
              ],
            ]),
          ),
        ),
      );
}

/// Grid of equal-width cards, [cols] per row, rows sized to their tallest.
class CalmGrid extends StatelessWidget {
  const CalmGrid({super.key, required this.children, this.cols = 2, this.gap = 8});
  final List<Widget> children;
  final int cols;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += cols) {
      final cells = <Widget>[];
      for (var j = 0; j < cols; j++) {
        if (j > 0) cells.add(SizedBox(width: gap));
        final k = i + j;
        cells.add(Expanded(child: k < children.length ? children[k] : const SizedBox()));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// Horizontal scroll row of fixed-width cards; height grows with text scale.
class CalmRail extends StatelessWidget {
  const CalmRail({super.key, required this.children, required this.height, this.width = 150, this.inWrap = false});
  final List<Widget> children;
  final double height;
  final double width;
  final bool inWrap;

  @override
  Widget build(BuildContext context) {
    final s = calmScale(context);
    final w = width * (s < 1 ? 1 : (1 + (s - 1) * 0.5));
    // The row is as tall as its tallest card, so labels wrap instead of
    // being cut; [height] is only the floor.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: inWrap ? 0 : 16, vertical: inWrap ? 0 : 6),
      clipBehavior: inWrap ? Clip.hardEdge : Clip.none,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              SizedBox(width: w, child: children[i]),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Soft pill button.
class CalmPill extends StatelessWidget {
  const CalmPill(this.label, {super.key, required this.onTap, this.color = calmInk, this.fill = Colors.white});
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) => Material(
        color: fill,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ),
        ),
      );
}

/// One wide soft card: disc, title, sub, pill. The whole card taps too.
class CalmBand extends StatelessWidget {
  const CalmBand({
    super.key,
    required this.title,
    required this.tone,
    required this.onTap,
    this.sub,
    this.cta,
    this.mark,
    this.eyebrow,
    this.trailing,
  });
  final String title;
  final String? sub;
  final String? cta;
  final String? mark;
  final String? eyebrow;
  final CalmTone tone;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          color: tone.fill,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (eyebrow != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(eyebrow!.toUpperCase(),
                            style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: tone.ink.withValues(alpha: 0.7))),
                      ),
                    Text(title,
                        style: TextStyle(fontSize: 17, height: 1.22, fontWeight: FontWeight.w700, color: tone.ink)),
                    if (sub != null) ...[
                      const SizedBox(height: 4),
                      Text(sub!,
                          style: TextStyle(fontSize: 12.5, height: 1.3, color: tone.ink.withValues(alpha: 0.75))),
                    ],
                    if (cta != null) ...[
                      const SizedBox(height: 12),
                      CalmPill(cta!, onTap: onTap, color: tone.ink),
                    ],
                  ]),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!]
                else if (mark != null) ...[const SizedBox(width: 12), CalmDisc(mark!, color: tone.ink, size: 56)],
              ]),
            ),
          ),
        ),
      );
}

/// Full-width list row inside a wrapper.
class CalmRow extends StatelessWidget {
  const CalmRow({super.key, required this.title, required this.onTap, this.sub, this.mark, this.tone = CalmTone.mist});
  final String title;
  final String? sub;
  final String? mark;
  final CalmTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(children: [
            if (mark != null)
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tone.fill, borderRadius: BorderRadius.circular(13)),
                child: NwsbIcon(mark!, size: 19, color: tone.ink, strokeWidth: 1.8),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: calmInk)),
                if (sub != null)
                  Text(sub!, style: const TextStyle(fontSize: 12, height: 1.25, color: calmSoft)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: calmSoft),
          ]),
        ),
      );
}
