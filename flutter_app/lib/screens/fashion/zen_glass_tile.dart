/// Dark-home Zen Plus entry (Ribon 11-03): a glass tile with real depth —
/// backdrop blur, frosted layers, a refraction rim that light travels round.
/// Three variants; the 8s loop holds still under reduced motion.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum ZenGlassStyle { prism, strata, lens, breath }

const _gold = Color(0xFFC8A96E);
const _goldLight = Color(0xFFE8D5A3);
const _vio = Color(0xFFB9A6FF);

class ZenGlassTile extends StatefulWidget {
  const ZenGlassTile({super.key, required this.style, required this.on, this.onTap, this.debugT, this.media});
  final ZenGlassStyle style;
  final bool on;
  final VoidCallback? onTap;
  final double? debugT;

  /// [ZenGlassStyle.breath]: the moving picture behind the glass.
  final Widget? media;
  @override
  State<ZenGlassTile> createState() => _ZenGlassTileState();
}

class _ZenGlassTileState extends State<ZenGlassTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  bool _down = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || widget.debugT != null;
    if (still) {
      _c.stop();
      _c.value = widget.debugT ?? .3;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const r = 24.0;
    return Semantics(
      button: true,
      label: 'Enter Zen Plus',
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _down ? .975 : 1,
          duration: const Duration(milliseconds: 160),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final t = _c.value;
                return Stack(clipBehavior: Clip.none, children: [
                  if (widget.style == ZenGlassStyle.strata) ..._strata(t, r),
                  if (widget.media != null) _window(t, r) else ClipRRect(
                    borderRadius: BorderRadius.circular(r),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                      child: CustomPaint(
                        painter: _GlassPainter(t: t, style: widget.style, r: r),
                        child: Padding(padding: const EdgeInsets.fromLTRB(14, 16, 14, 16), child: _content(t)),
                      ),
                    ),
                  ),
                  Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _RimPainter(t: t, r: r)))),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Golden Breath: the clip is a clear window on the right; a frosted pane
  /// holds the words on the left, its edge catching the light.
  Widget _window(double t, double r) => ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFF0B0716))),
          Positioned.fill(child: Align(alignment: Alignment.centerRight, child: FractionallySizedBox(widthFactor: .62, heightFactor: 1,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (b) => const LinearGradient(colors: [Color(0x00000000), Color(0xFF000000)], stops: [0, .35]).createShader(b),
                child: widget.media!)))),
          Positioned.fill(child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: .56, heightFactor: 1,
            child: ClipRect(child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.white.withValues(alpha: .10), Colors.white.withValues(alpha: .04)]),
                border: Border(right: BorderSide(color: _goldLight.withValues(alpha: .25 + .2 * math.sin(t * math.pi * 2).abs()), width: 1)),
              ))))))),
          CustomPaint(
            painter: _GlassPainter(t: t, style: ZenGlassStyle.prism, r: r, body: false),
            // words stay on the frosted pane; Enter sits low in the window, under
            // the chin, so the particle stream above stays clear
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 56, child: Padding(padding: const EdgeInsets.fromLTRB(14, 20, 10, 20), child: _content(t, enter: false))),
              Expanded(flex: 44, child: Align(alignment: const Alignment(.85, .8), child: Padding(padding: const EdgeInsets.all(10), child: _enter(t)))),
            ]),
          ),
        ]),
      );

  List<Widget> _strata(double t, double r) => [
        for (var i = 2; i >= 1; i--)
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(math.sin(t * math.pi * 2 + i) * 3, -7.0 * i + math.cos(t * math.pi * 2 + i) * 2),
              child: Transform.scale(
                scale: 1 - .04 * i,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(r),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: DecoratedBox(decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(r),
                      color: Colors.white.withValues(alpha: .05 + .02 * (2 - i)),
                      border: Border.all(color: Colors.white.withValues(alpha: .14)),
                    )),
                  ),
                ),
              ),
            ),
          ),
      ];

  Widget _content(double t, {bool enter = true}) => Row(children: [
        SizedBox(width: 52, height: 52, child: CustomPaint(painter: _GemPainter(t: t, style: widget.style))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('EXPERIENCE', style: TextStyle(fontSize: 10.5, letterSpacing: 2.2, color: _goldLight, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('Zen Plus', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
          const SizedBox(height: 3),
          Text(widget.on ? 'On — the tiles, the practice card and every photo background are playing' : 'Off — pages keep their photographs',
              softWrap: true, style: const TextStyle(fontSize: 11.5, color: Color(0xB3FFFFFF), height: 1.35)),
        ])),
        if (enter) const SizedBox(width: 10),
        if (enter) _enter(t),
      ]);

  Widget _enter(double t) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: .32), Colors.white.withValues(alpha: .06)]),
          border: Border.all(color: Colors.white.withValues(alpha: .35), width: 1),
          boxShadow: [BoxShadow(color: _gold.withValues(alpha: .18 + .12 * math.sin(t * math.pi * 2).abs()), blurRadius: 18)],
        ),
        child: Transform.translate(
          offset: Offset(2.5 * math.sin(t * math.pi * 4).clamp(0, 1), 0),
          child: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
        ),
      );
}

/// Frosted body: translucent fill, inner light pooling, moving caustic.
class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.t, required this.style, required this.r, this.body = true});
  final double t, r;
  final bool body;
  final ZenGlassStyle style;
  @override
  void paint(Canvas canvas, Size s) {
    final rr = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(r));
    final ph = t * math.pi * 2;
    if (body) {
      canvas.drawRRect(rr, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(s.width, s.height),
          [Colors.white.withValues(alpha: .20), Colors.white.withValues(alpha: .06), Colors.white.withValues(alpha: .10)], [0, .6, 1]));
      // a pool of coloured light drifting under the glass
      final g = Offset(s.width * (.3 + .25 * math.sin(ph)), s.height * (.5 + .3 * math.cos(ph)));
      canvas.drawCircle(g, s.height * 1.1, Paint()..shader = ui.Gradient.radial(g, s.height * 1.1,
          [_vio.withValues(alpha: .22), _vio.withValues(alpha: 0)]));
    }
    if (style == ZenGlassStyle.prism) {
      // diagonal spectral band — light split by the glass edge
      final x = (t * 1.6 - .3) * (s.width + s.height);
      canvas.save();
      canvas.clipRRect(rr);
      final band = Path()..moveTo(x, 0)..lineTo(x + 46, 0)..lineTo(x + 46 - s.height, s.height)..lineTo(x - s.height, s.height)..close();
      canvas.drawPath(band, Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.linear(Offset(x - s.height * .5, 0), Offset(x + 46 - s.height * .5, 0), [
          const Color(0x00FFFFFF), const Color(0x22FF9EC7), const Color(0x26FFE6A8), const Color(0x2296E6FF), const Color(0x00FFFFFF)],
          [0, .3, .5, .7, 1]));
      canvas.restore();
    }
    if (style == ZenGlassStyle.lens) {
      // a liquid lens drifting through the glass, brightening what it passes
      final lx = s.width * (.15 + .7 * (math.sin(ph) * .5 + .5));
      final c = Offset(lx, s.height * .5);
      canvas.save();
      canvas.clipRRect(rr);
      canvas.drawOval(Rect.fromCenter(center: c, width: s.height * 1.3, height: s.height * 1.1), Paint()..shader =
          ui.Gradient.radial(c, s.height * .65, [Colors.white.withValues(alpha: .12), Colors.white.withValues(alpha: .03), Colors.white.withValues(alpha: 0)], [0, .8, 1]));
      canvas.drawArc(Rect.fromCenter(center: c, width: s.height * 1.3, height: s.height * 1.1), math.pi * 1.1, math.pi * .6, false,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.white.withValues(alpha: .35));
      canvas.restore();
    }
    // top sheen
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, s.height * .45), Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height * .45),
        [Colors.white.withValues(alpha: .10), Colors.white.withValues(alpha: 0)]));
    canvas.restore();
  }
  @override
  bool shouldRepaint(_GlassPainter o) => o.t != t;
}

/// Refraction rim: hairline edge with a bright highlight travelling round.
class _RimPainter extends CustomPainter {
  _RimPainter({required this.t, required this.r});
  final double t, r;
  @override
  void paint(Canvas canvas, Size s) {
    final rr = RRect.fromRectAndRadius((Offset.zero & s).deflate(.5), Radius.circular(r));
    canvas.drawRRect(rr, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.white.withValues(alpha: .16));
    final a = t * math.pi * 2;
    canvas.drawRRect(rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = SweepGradient(transform: GradientRotation(a), colors: [
        Colors.white.withValues(alpha: 0), _goldLight.withValues(alpha: .9), Colors.white.withValues(alpha: .7),
        Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0), _vio.withValues(alpha: .6), Colors.white.withValues(alpha: 0)],
        stops: const [0, .06, .1, .2, .55, .62, .72]).createShader(Offset.zero & s));
  }
  @override
  bool shouldRepaint(_RimPainter o) => o.t != t;
}

/// The icon: a faceted glass gem / layered crystal / liquid drop with
/// an inner glow that breathes.
class _GemPainter extends CustomPainter {
  _GemPainter({required this.t, required this.style});
  final double t;
  final ZenGlassStyle style;
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final b = math.sin(t * math.pi * 2) * .5 + .5;
    final R = s.width * .46;
    canvas.drawCircle(c, R * 1.25, Paint()..color = _gold.withValues(alpha: .18 + .14 * b)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(c, R, Paint()..shader = ui.Gradient.linear(c - Offset(R, R), c + Offset(R, R),
        [Colors.white.withValues(alpha: .40), Colors.white.withValues(alpha: .06)]));
    canvas.drawCircle(c, R, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.white.withValues(alpha: .45));
    final rot = t * math.pi * 2 / 3;
    switch (style) {
      case ZenGlassStyle.prism:
        for (var i = 0; i < 3; i++) {
          final p = Path();
          for (var j = 0; j < 3; j++) {
            final a = rot + i * math.pi * 2 / 9 + j * math.pi * 2 / 3;
            final o = c + Offset(math.cos(a), math.sin(a)) * R * (.55 + .06 * b);
            j == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
          }
          p.close();
          canvas.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = [_goldLight, Colors.white, _vio][i].withValues(alpha: .8));
        }
      case ZenGlassStyle.strata:
        for (var i = 0; i < 3; i++) {
          final y = c.dy + (i - 1) * R * .32 + math.sin(t * math.pi * 2 + i) * 1.5;
          final w = R * (1.1 - .18 * (i - 1).abs());
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, y), width: w, height: R * .2), Radius.circular(R)),
              Paint()..color = [_goldLight, Colors.white, _vio][i].withValues(alpha: .75));
        }
      case ZenGlassStyle.lens:
      case ZenGlassStyle.breath:
        final d = Path()
          ..moveTo(c.dx, c.dy - R * .62)
          ..cubicTo(c.dx + R * .5, c.dy - R * .1, c.dx + R * .45, c.dy + R * .5, c.dx, c.dy + R * .52)
          ..cubicTo(c.dx - R * .45, c.dy + R * .5, c.dx - R * .5, c.dy - R * .1, c.dx, c.dy - R * .62);
        canvas.drawPath(d, Paint()..shader = ui.Gradient.radial(c + Offset(-R * .15, R * .05), R * .7,
            [Colors.white, _goldLight.withValues(alpha: .8), _vio.withValues(alpha: .5)], [0, .5, 1]));
        canvas.drawCircle(c + Offset(-R * .14, R * .05 - 3 * b), R * .09, Paint()..color = Colors.white);
    }
  }
  @override
  bool shouldRepaint(_GemPainter o) => o.t != t;
}
