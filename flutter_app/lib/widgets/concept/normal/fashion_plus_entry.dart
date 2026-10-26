/// Fashion Plus entry — "Plus aperture": a white neumorphic frame holding a
/// dark portal. The real Fashion Plus still (assets/fashion/fp-intro.webp,
/// cropped to the model and her neon plus, left of the printed FASHION
/// letters, so no printed text shows) is seen only through a giant
/// plus-shaped window. The window breathes, a neon line traces its outline
/// with a running spark, and violet rings echo out in the dark corners.
/// Tapping anywhere opens the plus until the still fills the portal, then
/// calls [onEnter].
///
/// [bgDim] (0..1, optional) = how much the Fashion background is dimmed
/// (Builder: FashionBgDim). It darkens the still the same way, so the card
/// previews the user's own setting. null = no dim.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'surface.dart';

/// Derived from fp-intro.webp (tools: rembg matte + crop): the printed
/// FASHION letter block behind the model is replaced by the dark backdrop,
/// so no printed text or letter slab can show.
const kNFashionPlusStill = 'assets/home/fp-entry.webp';
const _neon = Color(0xFFB45CFF);

class NFashionPlusEntry extends StatefulWidget {
  const NFashionPlusEntry({super.key, required this.onEnter, this.bgDim});
  final VoidCallback onEnter;
  final double? bgDim;
  @override
  State<NFashionPlusEntry> createState() => _NFashionPlusEntryState();
}

class _NFashionPlusEntryState extends State<NFashionPlusEntry> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(milliseconds: 4200);
  bool _opening = false;

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  Future<void> _enter() async {
    if (_opening) return;
    setState(() => _opening = true);
    // Reduced motion: open instantly and enter now, with no animation.
    if (!_reduced) await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    widget.onEnter();
    if (!_reduced) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: NPress(label: 'Enter Fashion Plus', onTap: _enter, child: Container(
        decoration: neu(r: 30), padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.fromLTRB(4, 4, 4, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Step into', style: nHello),
            Text('Fashion Plus', style: nTitle),
            SizedBox(height: 4),
            Text('The dark, cinematic home. Tap anywhere to open it.', style: nSub),
          ])),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(22), child: SizedBox(height: 236, child: LayoutBuilder(builder: (c, k) {
            final w = k.maxWidth;
            const h = 236.0;
            return TweenAnimationBuilder<double>(
              tween: Tween(end: _opening ? 1 : 0), duration: _reduced ? Duration.zero : const Duration(milliseconds: 480), curve: Curves.easeInCubic,
              builder: (_, open, __) => AnimatedBuilder(animation: loop, builder: (_, __) {
                final t = loop.value;
                final breathe = math.sin(t * math.pi * 2) * .5 + .5;
                final arm = lerpDouble(lerpDouble(.27, .31, breathe)!, .9, open)! * h; // half-thickness
                final plus = _plusPath(Size(w, h), arm);
                final rim = _innerOutline(Size(w, h), arm);
                final dim = (widget.bgDim ?? 0).clamp(0.0, 1.0);
                return Stack(fit: StackFit.expand, children: [
                  const ColoredBox(color: Color(0xFF0B0812)),
                  CustomPaint(painter: _Rings(t: t)),
                  ClipPath(clipper: _PathClip(plus), child: Stack(fit: StackFit.expand, children: [
                    _Still(w: w, h: h),
                    if (dim > 0) ColoredBox(color: Colors.black.withValues(alpha: dim)),
                  ])),
                  CustomPaint(painter: _Neon(path: rim, t: t, fade: 1 - open)),
                ]);
              }));
          }))),
        ]),
      )));
}

/// A plus centred in the portal; arms run to the edges.
Path _plusPath(Size s, double a) {
  final c = s.center(Offset.zero);
  final ax = math.min(a, s.width / 2), ay = math.min(a, s.height / 2);
  return Path.combine(PathOperation.union,
      Path()..addRect(Rect.fromLTRB(0, c.dy - ay, s.width, c.dy + ay)),
      Path()..addRect(Rect.fromLTRB(c.dx - ax, 0, c.dx + ax, s.height)));
}

/// The plus outline *inside* the portal only: four L-shaped inner corners
/// (the arm ends lie on the portal edge and are not drawn), so the neon
/// line and its spark never run along the portal border.
Path _innerOutline(Size s, double a) {
  final c = s.center(Offset.zero);
  final ax = math.min(a, s.width / 2), ay = math.min(a, s.height / 2);
  final l = c.dx - ax, r = c.dx + ax, t = c.dy - ay, b = c.dy + ay;
  final p = Path();
  if (l > 0 && t > 0) p..moveTo(l, 0)..lineTo(l, t)..lineTo(0, t);
  if (r < s.width && t > 0) p..moveTo(r, 0)..lineTo(r, t)..lineTo(s.width, t);
  if (r < s.width && b < s.height) p..moveTo(s.width, b)..lineTo(r, b)..lineTo(r, s.height);
  if (l > 0 && b < s.height) p..moveTo(0, b)..lineTo(l, b)..lineTo(l, s.height);
  return p;
}

class _PathClip extends CustomClipper<Path> {
  _PathClip(this.p);
  final Path p;
  @override
  Path getClip(Size size) => p;
  @override
  bool shouldReclip(_PathClip o) => o.p != p;
}

/// The still, cropped to the model and the neon plus (x 0–.7 of the
/// 941×1672 frame); the face sits inside the plus's horizontal arm.
class _Still extends StatelessWidget {
  const _Still({required this.w, required this.h});
  final double w, h;
  static const _fy = .465, _span = .7;
  @override
  Widget build(BuildContext context) {
    // the portal's width shows x 0..[_span] of the frame
    final iw = w / _span, ih = iw * 1672 / 941;
    return ClipRect(child: Stack(clipBehavior: Clip.hardEdge, children: [
      Positioned(left: 0, top: h / 2 - ih * _fy, width: iw, height: ih,
          child: Image.asset(kNFashionPlusStill, fit: BoxFit.fill, errorBuilder: (_, __, ___) => const SizedBox())),
    ]));
  }
}

/// Violet rings rippling out from the centre in the dark corners.
class _Rings extends CustomPainter {
  _Rings({required this.t});
  final double t;
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final maxR = s.longestSide * .75;
    for (var i = 0; i < 6; i++) {
      final f = (i / 6 + t) % 1;
      c.drawCircle(o, maxR * f, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6
        ..color = _neon.withValues(alpha: .45 * (1 - f)));
    }
  }
  @override
  bool shouldRepaint(_Rings o) => o.t != t;
}

/// Neon outline of the plus window with a spark running along it.
class _Neon extends CustomPainter {
  _Neon({required this.path, required this.t, required this.fade});
  final Path path;
  final double t, fade;
  @override
  void paint(Canvas c, Size s) {
    if (fade <= 0) return;
    c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = _neon.withValues(alpha: .35 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFE3C4FF).withValues(alpha: fade));
    for (final m in path.computeMetrics()) {
      final p = m.getTangentForOffset(m.length * (.08 + .84 * t))?.position;
      if (p == null) continue;
      c.drawCircle(p, 9, Paint()..color = _neon.withValues(alpha: .6 * fade)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      c.drawCircle(p, 3, Paint()..color = Colors.white.withValues(alpha: fade));
    }
  }
  @override
  bool shouldRepaint(_Neon o) => o.t != t || o.path != path || o.fade != fade;
}
