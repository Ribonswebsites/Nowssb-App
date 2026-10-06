/// The animation library's building blocks: a spec per animation, the ink
/// it is drawn with (dark ink on light pages, light ink on dark ones) and
/// [AnimView], which plays any spec offline from a Ticker.
///
/// Painters draw in a 100 × 100 box (the canvas is scaled to the real
/// size) and get the time in seconds, so every one is a pure function of
/// (time, ink): cheap to thumbnail, easy to freeze for a screenshot.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

enum AnimCategory { orbs, loaders, backgrounds, particles, celebrations }

const kAnimCategoryNames = <AnimCategory, String>{
  AnimCategory.orbs: 'Orbs',
  AnimCategory.loaders: 'Loaders',
  AnimCategory.backgrounds: 'Backgrounds',
  AnimCategory.particles: 'Particles',
  AnimCategory.celebrations: 'Celebrate',
};

/// Draws one frame in a 100 × 100 box at [t] seconds.
typedef AnimPainter = void Function(Canvas c, double t, AnimInk k);

/// A widget-built animation (e.g. the thinking orbs package).
typedef AnimBuilder = Widget Function(BuildContext context, double size, AnimInk k);

class AnimSpec {
  const AnimSpec(this.id, this.name, this.category, {this.paint, this.build, this.clip = false})
      : assert((paint == null) != (build == null), 'one of paint or build');

  /// Stable id, saved in layouts — never rename.
  final String id;

  /// One or two words for the drawer.
  final String name;
  final AnimCategory category;
  final AnimPainter? paint;
  final AnimBuilder? build;

  /// Backgrounds fill their box; clip them to it.
  final bool clip;
}

/// How an animation is inked.
class AnimInk {
  const AnimInk({this.onLight = false, this.lite = false});

  /// Sits on a light background: draw with dark ink.
  final bool onLight;

  /// Thumbnail: fewer particles, same look.
  final bool lite;

  Color get fg => onLight ? const Color(0xFF1B2030) : const Color(0xFFFFFFFF);
  Color get gold => onLight ? const Color(0xFFB07D1A) : const Color(0xFFE8D5A3);
  Color get mint => onLight ? const Color(0xFF0E9F6E) : const Color(0xFF34D399);
  Color get violet => onLight ? const Color(0xFF5B3CC4) : const Color(0xFF9F7BFF);
  Color get pink => onLight ? const Color(0xFFD6336C) : const Color(0xFFFF5C9A);
  Color get sky => onLight ? const Color(0xFF1C7ED6) : const Color(0xFF4CC3FF);
  Color get orange => onLight ? const Color(0xFFE8590C) : const Color(0xFFFFA94D);

  /// The five accents, in order.
  List<Color> get palette => [gold, mint, violet, pink, sky, orange];

  /// [full] items, halved for thumbnails.
  int n(int full) => lite ? math.max(1, (full * 0.55).round()) : full;
}

// ── Small maths shared by the painters ──────────────────────────────────

const tau = math.pi * 2;

/// Stable pseudo-random 0..1 for item [i] (and a [salt] per property).
double rnd(int i, [int salt = 0]) {
  var x = (i * 73856093) ^ (salt * 19349663) ^ 0x5bd1e995;
  x = (x ^ (x >> 13)) * 1274126177;
  x = x ^ (x >> 16);
  return (x & 0xffffff) / 0xffffff;
}

/// 0..1 sawtooth with [period] seconds, offset by [phase] (0..1).
double saw(double t, double period, [double phase = 0]) => ((t / period) + phase) % 1.0;

/// −1..1 sine with [period] seconds.
double osc(double t, double period, [double phase = 0]) => math.sin((t / period + phase) * tau);

Paint fillOf(Color c) => Paint()..color = c;

Paint strokeOf(Color c, double w, {StrokeCap cap = StrokeCap.round}) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = cap
  ..strokeJoin = StrokeJoin.round;

Paint glowOf(Color c, double sigma) => Paint()
  ..color = c
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(0.1, sigma));

Color hue(double h, [double s = 0.75, double v = 1, double a = 1]) =>
    HSVColor.fromAHSV(a.clamp(0.0, 1.0), h % 360, s.clamp(0.0, 1.0), v.clamp(0.0, 1.0)).toColor();

Color fade(Color c, double a) => c.withValues(alpha: (c.a * a).clamp(0.0, 1.0));

const Offset kMid = Offset(50, 50);

Offset polar(double r, double angle, [Offset c = kMid]) => c + Offset(math.cos(angle) * r, math.sin(angle) * r);

/// A star / sparkle path with [points] tips.
Path starPath(Offset c, double outer, double inner, {int points = 5, double rot = -math.pi / 2}) {
  final p = Path();
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? outer : inner;
    final a = rot + i * math.pi / points;
    final o = polar(r, a, c);
    i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

/// A heart centred on [c], [s] wide.
Path heartPath(Offset c, double s) {
  final p = Path();
  final x = c.dx, y = c.dy, h = s / 2;
  p.moveTo(x, y + h * 0.9);
  p.cubicTo(x - h * 1.4, y - h * 0.1, x - h * 0.6, y - h * 1.2, x, y - h * 0.4);
  p.cubicTo(x + h * 0.6, y - h * 1.2, x + h * 1.4, y - h * 0.1, x, y + h * 0.9);
  return p..close();
}

// ── The player ──────────────────────────────────────────────────────────

/// Plays [spec] at [size]. Frames are capped at [fps] (thumbnails use 30)
/// and stop with the ticker (off screen, TickerMode off, app paused).
/// With [fixedT] it draws that one frame and does not tick.
class AnimView extends StatefulWidget {
  const AnimView({super.key, required this.spec, required this.size, this.ink = const AnimInk(), this.fps = 60, this.fixedT});
  final AnimSpec spec;
  final double size;
  final AnimInk ink;
  final double fps;
  final double? fixedT;

  @override
  State<AnimView> createState() => _AnimViewState();
}

class _AnimViewState extends State<AnimView> with SingleTickerProviderStateMixin {
  final _t = ValueNotifier<double>(0.35);
  Ticker? _ticker;
  Duration _last = Duration.zero;

  /// Each view starts at its own spot so a grid does not move in lockstep.
  late final double _offset = rnd(identityHashCode(this) & 0xffff) * 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AnimView old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final still = widget.fixedT != null ||
        widget.spec.paint == null ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (widget.fixedT != null) _t.value = widget.fixedT!;
    if (still) {
      _ticker?.dispose();
      _ticker = null;
      return;
    }
    _ticker ??= createTicker(_tick)..start();
  }

  void _tick(Duration e) {
    final gap = 1 / widget.fps;
    if ((e - _last).inMicroseconds < gap * 1e6 * 0.9) return;
    _last = e;
    _t.value = _offset + e.inMicroseconds / 1e6;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spec;
    if (s.build != null) return SizedBox.square(dimension: widget.size, child: s.build!(context, widget.size, widget.ink));
    final paint = CustomPaint(
      size: Size.square(widget.size),
      painter: _AnimPainter(s, _t, widget.ink),
      isComplex: true,
      willChange: widget.fixedT == null,
    );
    return RepaintBoundary(child: s.clip ? ClipRRect(borderRadius: BorderRadius.circular(widget.size * 0.06), child: paint) : paint);
  }
}

class _AnimPainter extends CustomPainter {
  _AnimPainter(this.spec, this.t, this.ink) : super(repaint: t);
  final AnimSpec spec;
  final ValueNotifier<double> t;
  final AnimInk ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    spec.paint!(canvas, t.value, ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnimPainter old) => old.spec != spec || old.ink.onLight != ink.onLight || old.ink.lite != ink.lite;
}
