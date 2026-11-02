// Three section styles copied from Ribon's 11-02 references
// (ref1 fanned cards, ref2 cut-out + gold circles, ref3 cut-out + floating
// tiles), with meditation photos only (Pexels, see assets/CREDITS.md).
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'r27/live.dart';

enum RefStyle { fanned, circles, tiles }

const _black = Color(0xFFF0F2F7); // Ribon 11-02: normal home is white neumorphism
const _ink = Color(0xFF1A1A2E);
const _dir = 'assets/home/ref/';

Widget _photo(String n, {Alignment a = Alignment.topCenter, BoxFit fit = BoxFit.cover}) => Image.asset('$_dir$n.webp',
    fit: fit, alignment: a, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE6E9F0)));

class RefSection extends StatelessWidget {
  const RefSection({
    super.key,
    required this.style,
    required this.tag,
    required this.lead,
    required this.accentLine,
    required this.accent,
    required this.body,
    required this.cta,
    required this.onTap,
    required this.photos,
    this.cutout,
  });
  final RefStyle style;
  final String tag, lead, accentLine, body, cta;
  final Color accent;
  final VoidCallback onTap;

  /// Background / card photos (first is the main one).
  final List<String> photos;

  /// Transparent cut-out figure breaking out of the art.
  final String? cutout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: DecoratedBox(
      decoration: BoxDecoration(color: _black, borderRadius: BorderRadius.circular(28), boxShadow: const [
        BoxShadow(color: Color(0x24000000), offset: Offset(10, 10), blurRadius: 26),
        BoxShadow(color: Color(0xFAFFFFFF), offset: Offset(-7, -7), blurRadius: 20),
      ]),
      child: ClipRRect(borderRadius: BorderRadius.circular(28), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AspectRatio(aspectRatio: style == RefStyle.fanned ? 1.0 : .92, child: LayoutBuilder(builder: (c, b) => _art(b.biggest))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tag.toUpperCase(),
                style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, letterSpacing: 2.4, color: accent, fontWeight: FontWeight.w600, height: 1.35)),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: '$lead ', style: const TextStyle(color: _ink)),
                TextSpan(text: accentLine, style: TextStyle(color: accent)),
              ]),
              style: const TextStyle(fontFamily: 'Anton', fontSize: 34, height: 1.05, letterSpacing: .4),
            ),
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(fontFamily: 'DM Sans', fontSize: 16, height: 1.45, color: Color(0xFF4A4E5C))),
            const SizedBox(height: 18),
            _Pill(label: cta, color: accent, onTap: onTap),
          ]),
        ),
      ])),
    ));
  }

  Widget _art(Size s) {
    final w = s.width, h = s.height;
    switch (style) {
      case RefStyle.fanned:
        final cw = w * .58, ch = h * .78;
        Widget card(String p, double angle, double dx, {bool front = false}) => Positioned(
              left: w / 2 - cw / 2 + dx, top: h * .1, width: cw, height: ch,
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFFFFF), width: front ? 3 : 2),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 10))],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(13), child: _photo(p)),
                ),
              ),
            );
        return Stack(clipBehavior: Clip.none, children: [
          card(photos[1 % photos.length], -.14, -w * .36),
          card(photos[2 % photos.length], .14, w * .36),
          card(photos[0], 0, 0, front: true),
          if (cutout != null)
            Positioned(left: w * .08, right: w * .08, top: -h * .02, bottom: h * .02, child: _photo(cutout!, a: Alignment.bottomCenter, fit: BoxFit.contain)),
        ]);
      case RefStyle.circles:
        Widget ring(String p, double d, double l, double t) => Positioned(
              left: l, top: t, width: d, height: d,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFFFFFF), width: 4),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(4, 6))]),
                child: ClipOval(child: _photo(p, a: Alignment.center)),
              ),
            );
        return Stack(fit: StackFit.expand, children: [
          _photo(photos[0], a: Alignment.center),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              stops: [0, .55, 1], colors: [Color(0x00F0F2F7), Color(0x00F0F2F7), _black]))),
          ring(photos[1 % photos.length], w * .32, w * .64, h * .52),
          ring(photos[2 % photos.length], w * .22, w * .52, h * .74),
          if (cutout != null) Positioned(left: -w * .04, width: w * .62, top: h * .3, bottom: 0, child: _photo(cutout!, a: Alignment.bottomLeft, fit: BoxFit.contain)),
        ]);
      case RefStyle.tiles:
        Widget tile(String p, double l, double t, double tw, double angle) => Positioned(
              left: l, top: t, width: tw, height: tw * .68,
              child: Transform.rotate(angle: angle, child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 8))]),
                child: ClipRRect(borderRadius: BorderRadius.circular(7), child: _photo(p, a: Alignment.center)),
              )),
            );
        return Stack(fit: StackFit.expand, clipBehavior: Clip.hardEdge, children: [
          _photo(photos[0], a: Alignment.center),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              stops: [.55, 1], colors: [Color(0x00F0F2F7), _black]))),
          tile(photos[1 % photos.length], w * .03, h * .64, w * .34, -math.pi / 40),
          tile(photos[2 % photos.length], w * .6, h * .66, w * .36, math.pi / 36),
          if (cutout != null) Positioned(left: w * .06, right: w * .1, top: h * .02, bottom: h * .02, child: _photo(cutout!, a: Alignment.bottomCenter, fit: BoxFit.contain)),
        ]);
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final dark = color.computeLuminance() > .4;
    final fg = dark ? const Color(0xFF111111) : Colors.white;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x24000000), offset: Offset(5, 5), blurRadius: 12), BoxShadow(color: Color(0xFAFFFFFF), offset: Offset(-4, -4), blurRadius: 10)]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(label, style: TextStyle(fontFamily: 'DM Sans', fontSize: 16, fontWeight: FontWeight.w700, color: fg))),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded, size: 18, color: fg),
          ]),
        ),
      ),
    );
  }
}

void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => w));

/// The three styles applied to home sections, each with a working button.
class RefHomeSections extends StatelessWidget {
  const RefHomeSections({super.key});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        RefSection(
          key: const ValueKey('ref-offers'),
          style: RefStyle.circles,
          tag: 'Offers & earning · Coupons · Gifts',
          lead: 'SIT STILL.',
          accentLine: 'EARN MORE.',
          accent: const Color(0xFF8A5A0B),
          body: 'Every quiet minute adds up. Scratch today\'s coupon and unlock offers on words.',
          cta: 'See offers',
          photos: const ['ref-1', 'ref-6', 'ref-3'],
          onTap: () => _push(context, const R27CouponsLivePage()),
        ),
        RefSection(
          key: const ValueKey('ref-earn'),
          style: RefStyle.fanned,
          tag: 'NowssB Earn · Daily practice',
          lead: 'BREATHE IN.',
          accentLine: 'EARN COINS.',
          accent: const Color(0xFF6A3FC4),
          body: 'Finish a practice, keep your streak and invite a friend to earn NowssB coins.',
          cta: 'Start earning',
          photos: const ['ref-5', 'ref-2', 'ref-9'],
          onTap: () => _push(context, const R27EarnLivePage()),
        ),
        RefSection(
          key: const ValueKey('ref-rewards'),
          style: RefStyle.tiles,
          tag: 'NowssB Rewards · Vault',
          lead: 'SHOW UP.',
          accentLine: 'GET REWARDED.',
          accent: const Color(0xFFC0291B),
          body: 'Claim today\'s reward and open your vault of words, sounds and gifts.',
          cta: 'Claim rewards',
          photos: const ['ref-4', 'ref-7', 'ref-8'],
          onTap: () => _push(context, const R27RewardsLivePage()),
        ),
      ]);
}
