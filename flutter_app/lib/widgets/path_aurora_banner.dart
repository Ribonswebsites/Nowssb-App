/// "Calm that pays you back": the animated banner that sits above the
/// Programmes glass panel on the Zen home. Everything is painted in code
/// (no photographs): an aurora ribbon, a breathing core, coins and links
/// orbiting it, and slow rising particles, on black.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/programs/program_router.dart';

const _kTeal = Color(0xFF19D3B0);
const _kEmerald = Color(0xFF5CE08A);
const _kGold = Color(0xFFF2C777);
const _kInk = Color(0xFF040708);

class PathAuroraBanner extends StatefulWidget {
  const PathAuroraBanner({super.key, this.onOpen});

  /// Tests / screenshots only: freeze the animation at this point (0..1).
  static double? debugT;

  /// Overrides the default tap (opens the Earn programme).
  final VoidCallback? onOpen;

  @override
  State<PathAuroraBanner> createState() => _PathAuroraBannerState();
}

class _PathAuroraBannerState extends State<PathAuroraBanner> with SingleTickerProviderStateMixin {
  // One loop is 24 s; every motion inside uses a whole number of cycles per
  // loop, so it never jumps when it wraps.
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still || PathAuroraBanner.debugT != null) {
      _c.stop();
      _c.value = PathAuroraBanner.debugT ?? .32;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _open() {
    HapticFeedback.selectionClick();
    if (widget.onOpen != null) {
      widget.onOpen!();
    } else {
      Programmes.open(context, Programme.earn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Calm that pays you back. Start earning.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _kInk,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0x2EFFFFFF)),
          ),
          child: SizedBox(
            height: 208,
            child: Stack(fit: StackFit.expand, children: [
              ExcludeSemantics(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (_, __) => CustomPaint(painter: _AuroraPainter(_c.value)),
                  ),
                ),
              ),
              // Keeps the words readable over the ribbon.
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xE6040708), Color(0xB3040708), Color(0x00040708)],
                      stops: [0, .5, .85],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 16, 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: .62,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: _kGold,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Color(0xAAF2C777), blurRadius: 8)],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('NOWSSB EARN',
                              style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.8)),
                        ]),
                        const SizedBox(height: 10),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Calm that\npays you back',
                              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.08, letterSpacing: -.6)),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _open,
                          child: Semantics(
                            button: true,
                            label: 'Start earning',
                            excludeSemantics: true,
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.only(left: 18, right: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [BoxShadow(color: Color(0x4D19D3B0), blurRadius: 18, spreadRadius: -2)],
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Start earning',
                                        style: TextStyle(color: Color(0xFF0B0F0E), fontSize: 14, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(color: Color(0xFF0B0F0E), shape: BoxShape.circle),
                                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Spec {
  const _Spec(this.x, this.y, this.rise, this.size, this.phase, this.tone);
  final double x, y, size, phase;
  final int rise, tone;
}

final List<_Spec> _specks = () {
  final r = math.Random(108);
  return [
    for (var i = 0; i < 46; i++)
      _Spec(r.nextDouble(), r.nextDouble(), 1 + r.nextInt(2), .7 + r.nextDouble() * 1.5, r.nextDouble(), r.nextInt(3)),
  ];
}();

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t);
  final double t;

  static const _tau = math.pi * 2;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    // Soft floor glow so the black has depth.
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = ui.Gradient.radial(Offset(w * .74, h * .5), w * .7, const [Color(0xFF0A1F1C), Color(0xFF040708)], const [0, 1]),
    );

    _ribbon(canvas, s, base: .60, amp: .13, freq: 1.0, k: 1, thick: .30, a: _kTeal, b: _kEmerald, alpha: .95, phase: 0);
    _ribbon(canvas, s, base: .45, amp: .10, freq: 1.6, k: -2, thick: .22, a: _kEmerald, b: _kTeal, alpha: .5, phase: .3);
    _ribbon(canvas, s, base: .70, amp: .08, freq: 2.2, k: 3, thick: .16, a: _kGold, b: _kGold, alpha: .2, phase: .6);

    final c = Offset(w * .745, h * .5);
    _core(canvas, c, w);
    _orbit(canvas, c, w, h);
    _specksLayer(canvas, s);
  }

  void _ribbon(Canvas canvas, Size s,
      {required double base, required double amp, required double freq, required int k, required double thick, required Color a, required Color b, required double alpha, required double phase}) {
    final w = s.width, h = s.height;
    const n = 90;
    double yAt(double x, double off) {
      final u = x / w;
      return h * (base + off) +
          h * amp * math.sin(_tau * (u * freq + k * t + phase)) +
          h * amp * .45 * math.sin(_tau * (u * freq * 2.3 - k * t * 2 + phase * 2));
    }

    final top = <Offset>[], bot = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final x = w * i / n;
      final u = i / n;
      // The ribbon thins to nothing at the left edge so the words stay clear.
      final fade = math.min(1.0, math.max(0.0, (u - .12) / .35));
      final th = h * thick * (.55 + .45 * math.sin(_tau * (u * 1.3 + t * 2 + phase))) * fade;
      final y = yAt(x, 0);
      top.add(Offset(x, y - th / 2));
      bot.add(Offset(x, y + th / 2));
    }
    final path = Path()..moveTo(top.first.dx, top.first.dy);
    for (final p in top.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in bot.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    final shift = (t * 2) % 1;
    final shader = ui.Gradient.linear(
      Offset(0, 0),
      Offset(w, 0),
      [a.withValues(alpha: 0), a.withValues(alpha: alpha), b.withValues(alpha: alpha), a.withValues(alpha: alpha * .8), b.withValues(alpha: 0)],
      [0, .25 + .08 * math.sin(_tau * shift), .55, .8, 1],
    );
    // Wide soft glow, then a tighter body, then a bright thread on the crest.
    canvas.drawPath(path, Paint()..shader = shader..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)..blendMode = BlendMode.plus);
    canvas.drawPath(path, Paint()..shader = shader..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)..blendMode = BlendMode.plus);
    // Hanging rays under the crest, like an aurora curtain.
    if (alpha > .4) {
      const rays = 120;
      for (var i = 4; i < rays; i++) {
        final u = i / rays;
        final idx = (u * n).round().clamp(0, n);
        final from = bot[idx];
        final lenK = .5 + .3 * math.sin(_tau * (u * 2.6 + t * 3 + phase)) + .2 * math.sin(_tau * (u * 9 - t * 6));
        final len = h * .30 * lenK * math.min(1.0, math.max(0.0, (u - .2) / .3));
        for (var j = 0; j < 5; j++) {
          final y0 = from.dy + len * j / 5, y1 = from.dy + len * (j + 1) / 5;
          canvas.drawLine(
            Offset(from.dx, y0),
            Offset(from.dx, y1),
            Paint()
              ..strokeWidth = 1.0
              ..color = b.withValues(alpha: alpha * .4 * (1 - j / 5) * (1 - j / 5))
              ..blendMode = BlendMode.plus,
          );
        }
      }
    }
    final crest = Path()..moveTo(top.first.dx, top.first.dy);
    for (final p in top.skip(1)) {
      crest.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      crest,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .8)
        ..shader = ui.Gradient.linear(Offset.zero, Offset(w, 0), [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .26), Colors.white.withValues(alpha: .04)], [.15, .6, 1])
        ..blendMode = BlendMode.plus,
    );
  }

  void _core(Canvas canvas, Offset c, double w) {
    // Four breaths per loop (6 s each).
    final breath = .5 + .5 * math.sin(_tau * (t * 4) - math.pi / 2);
    final r = w * (.085 + .012 * breath);
    canvas.drawCircle(
      c,
      r * 3.2,
      Paint()..shader = ui.Gradient.radial(c, r * 3.2, [_kGold.withValues(alpha: .30 + .12 * breath), _kTeal.withValues(alpha: .10), Colors.transparent], const [0, .45, 1]),
    );
    // Ripples drifting outward, one every 3 s.
    for (var i = 0; i < 2; i++) {
      final p = ((t * 8) + i / 2) % 1;
      canvas.drawCircle(
        c,
        r * (1.1 + p * 2.4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: .20 * (1 - p)),
      );
    }
    canvas.drawCircle(
      c,
      r,
      Paint()..shader = ui.Gradient.radial(c.translate(-r * .25, -r * .3), r * 1.2, const [Color(0xFFFFF6DA), Color(0xFFF2C777), Color(0xFFB07A22)], const [0, .55, 1]),
    );
    canvas.drawCircle(
      c,
      r * .62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66FFFFFF),
    );
    // A small closed lotus in the middle of the core: eight petals.
    final petal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x990B0F0E);
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(_tau * i / 8 + t * _tau * .0);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -r * .30), width: r * .30, height: r * .56), petal);
      canvas.restore();
    }
  }

  void _orbit(Canvas canvas, Offset c, double w, double h) {
    final rx = w * .215, ry = h * .34, tilt = -.22;
    final cs = math.cos(tilt), sn = math.sin(tilt);
    Offset onEllipse(double ang) {
      final x = rx * math.cos(ang), y = ry * math.sin(ang);
      return c + Offset(x * cs - y * sn, x * sn + y * cs);
    }

    // The path they travel.
    final guide = Path();
    for (var i = 0; i <= 90; i++) {
      final p = onEllipse(_tau * i / 90);
      i == 0 ? guide.moveTo(p.dx, p.dy) : guide.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      guide,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = const Color(0x1FFFFFFF),
    );

    // Five travellers: coin, link, coin, link, coin. Two orbits per loop.
    const kinds = [true, false, true, false, true];
    final items = <(double, int)>[];
    for (var i = 0; i < 5; i++) {
      final ang = _tau * (t * 2 + i / 5);
      items.add((ang, i));
    }
    // Far side first, so near ones overlap them.
    items.sort((p, q) => math.sin(p.$1).compareTo(math.sin(q.$1)));
    for (final it in items) {
      final ang = it.$1, i = it.$2;
      final z = math.sin(ang); // -1 far .. 1 near
      final depth = .78 + .22 * z;
      final pos = onEllipse(ang);
      final op = (.55 + .45 * (z * .5 + .5)).clamp(0.0, 1.0);
      if (kinds[i]) {
        _coin(canvas, pos, 12.5 * depth, op, spin: _tau * (t * 6 + i * .37));
      } else {
        _link(canvas, pos, 13 * depth, op, rot: ang + math.pi / 2 + tilt);
      }
    }
  }

  void _coin(Canvas canvas, Offset p, double r, double op, {required double spin}) {
    canvas.drawCircle(p, r * 2.1, Paint()..color = _kGold.withValues(alpha: .20 * op)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    // Turning on its edge: squash horizontally, never fully flat.
    final sx = .28 + .72 * math.cos(spin).abs();
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.scale(sx, 1);
    final rect = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..shader = ui.Gradient.radial(Offset(-r * .3, -r * .35), r * 1.5, [const Color(0xFFFFF1C2).withValues(alpha: op), const Color(0xFFE2A93B).withValues(alpha: op), const Color(0xFF8A5E1A).withValues(alpha: op)], const [0, .55, 1]),
    );
    canvas.drawCircle(
      Offset.zero,
      r * .72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF6B4510).withValues(alpha: .6 * op),
    );
    // A tiny lotus bud stamped on the face.
    final bud = Paint()..color = const Color(0xFF6B4510).withValues(alpha: .65 * op);
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -r * .02), width: r * .32, height: r * .62), bud);
    canvas.drawOval(Rect.fromCenter(center: Offset(-r * .24, r * .06), width: r * .26, height: r * .46), bud);
    canvas.drawOval(Rect.fromCenter(center: Offset(r * .24, r * .06), width: r * .26, height: r * .46), bud);
    canvas.drawArc(rect.deflate(.5), -2.6, 1.1, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.white.withValues(alpha: .6 * op));
    canvas.restore();
  }

  void _link(Canvas canvas, Offset p, double r, double op, {required double rot}) {
    canvas.drawCircle(p, r * 2, Paint()..color = _kTeal.withValues(alpha: .20 * op)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(rot);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(Offset(-r, -r), Offset(r, r), [const Color(0xFFD6FFF4).withValues(alpha: op), _kTeal.withValues(alpha: op)]);
    // Two interlocked pill-shaped rings.
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-r * .42, 0), width: r * 1.35, height: r * .8), Radius.circular(r * .4)), stroke);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(r * .42, 0), width: r * 1.35, height: r * .8), Radius.circular(r * .4)), stroke);
    canvas.restore();
  }

  void _specksLayer(Canvas canvas, Size s) {
    for (final sp in _specks) {
      final y = ((sp.y - t * sp.rise) % 1 + 1) % 1;
      final x = sp.x + .012 * math.sin(_tau * (t * 2 + sp.phase));
      final tw = .5 + .5 * math.sin(_tau * (t * (3 + sp.rise * 2) + sp.phase));
      // Edges of the loop fade out so nothing pops.
      final edge = math.min(1.0, math.min(y, 1 - y) * 6);
      final col = switch (sp.tone) { 0 => Colors.white, 1 => _kGold, _ => _kTeal };
      canvas.drawCircle(
        Offset(x * s.width, y * s.height),
        sp.size,
        Paint()..color = col.withValues(alpha: (.15 + .65 * tw) * edge),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}
