/// STILLWATER — the NowssB home design language (concept, not wired in).
///
/// Every section is a pool. Content rests on 2–3 depth planes like stones in
/// still water; one breath (5.5 s, in and out) drives all motion; a touch
/// drops a ripple that spreads and settles; a drag tilts the planes, which
/// spring back like water finding level.
///
/// Two waters, one grammar:
///  * Paper Pool  — the light neumorphic home: raised paper rim, pressed basin,
///    violet water light.
///  * Night Pool  — the dark glass Fashion home: ink water under a glass lid,
///    gold moon light.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens.dart';
import '../../admin/template/editable.dart';

/// One breath. In 2.75 s, out 2.75 s.
const kBreath = Duration(milliseconds: 5500);

/// The two waters.
enum Water { paper, night }

class StillPalette {
  const StillPalette._(this.water, this.rim, this.basinTop, this.basinBottom,
      this.light, this.lightSoft, this.ink, this.inkSoft);
  final Water water;
  final Color rim; // the surface the pool is cut into
  final Color basinTop;
  final Color basinBottom;
  final Color light; // the water's light (ripples, glows)
  final Color lightSoft;
  final Color ink;
  final Color inkSoft;

  static const paper = StillPalette._(
    Water.paper,
    NwsbColors.surface,
    Color(0xFFDCDFE8),
    Color(0xFFF7F8FB),
    Color(0xFF6C63D9),
    Color(0xFFB9B4F2),
    NwsbColors.ink,
    Color(0xFF5F6475),
  );
  static const night = StillPalette._(
    Water.night,
    NwsbColors.deep,
    Color(0xFF0B1426),
    Color(0xFF03060D),
    NwsbColors.gold,
    NwsbColors.goldLight,
    Color(0xFFF4F1EA),
    Color(0x99F4F1EA),
  );
  static StillPalette of(Water w) => w == Water.paper ? paper : night;
}

/// Renders/tests: freeze the breath at this phase (0–1).
class Stillwater {
  Stillwater._();
  @visibleForTesting
  static double? debugPhase;

  static bool still(BuildContext c) =>
      debugPhase == null &&
      ((MediaQuery.maybeDisableAnimationsOf(c) ?? false) ||
          WidgetsBinding.instance.runtimeType.toString().contains('Test'));

  /// 0 = empty lungs, 1 = full; eased like a real breath.
  static double lungs(double t) => .5 - .5 * math.cos(2 * math.pi * t);
}

/// Provides the shared breath to everything beneath it.
class Breath extends StatefulWidget {
  const Breath({super.key, required this.builder});
  final Widget Function(BuildContext context, double phase) builder;
  @override
  State<Breath> createState() => _BreathState();
}

class _BreathState extends State<Breath> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: kBreath);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Stillwater.debugPhase == null && !Stillwater.still(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (c, _) => widget.builder(c, Stillwater.debugPhase ?? (_c.isAnimating ? _c.value : .3)),
      );
}

// ─────────────────────────── touch: ripples ───────────────────────────

class _Ripple {
  _Ripple(this.at, this.born);
  final Offset at;
  final Duration born;
}

/// A surface that answers every touch with a ripple and a soft haptic.
/// [ambient] adds one slow ring per breath from [ambientAt] (fractional).
class RipplePool extends StatefulWidget {
  const RipplePool({
    super.key,
    required this.child,
    required this.palette,
    this.onTap,
    this.ambientAt,
    this.phase = 0,
    this.radius = 24,
    this.debugRipple,
  });
  final Widget child;
  final StillPalette palette;
  final VoidCallback? onTap;
  final Alignment? ambientAt;
  final double phase;
  final double radius;

  /// Renders only: draw one ripple at (fractional point, progress 0–1).
  final (Alignment, double)? debugRipple;
  @override
  State<RipplePool> createState() => _RipplePoolState();
}

class _RipplePoolState extends State<RipplePool> with SingleTickerProviderStateMixin {
  final _ripples = <_Ripple>[];
  late final Ticker _ticker = createTicker(_tick);
  Duration _now = Duration.zero;
  static const _life = Duration(milliseconds: 2200);

  void _tick(Duration d) {
    _now = d;
    _ripples.removeWhere((r) => d - r.born > _life);
    if (_ripples.isEmpty) _ticker.stop();
    setState(() {});
  }

  void _drop(Offset p) {
    HapticFeedback.selectionClick();
    if (Stillwater.still(context)) return;
    if (!_ticker.isActive) {
      _now = Duration.zero;
      _ticker.start();
    }
    _ripples.add(_Ripple(p, _now));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final size = box.biggest;
        final rings = <(Offset, double)>[
          for (final r in _ripples)
            (r.at, ((_now - r.born).inMilliseconds / _life.inMilliseconds).clamp(0.0, 1.0)),
          if (widget.debugRipple != null)
            (widget.debugRipple!.$1.alongSize(size), widget.debugRipple!.$2),
        ];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _drop(d.localPosition),
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: CustomPaint(
              foregroundPainter: _RipplePainter(
                rings: rings,
                ambient: widget.ambientAt?.alongSize(size),
                phase: widget.phase,
                color: widget.palette.light,
              ),
              child: widget.child,
            ),
          ),
        );
      });
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.rings, this.ambient, required this.phase, required this.color});
  final List<(Offset, double)> rings;
  final Offset? ambient;
  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final reach = size.longestSide * .75;
    void ring(Offset c, double t, double strength) {
      // Three wavefronts, each fainter, like a pebble's rings.
      for (var k = 0; k < 3; k++) {
        final tk = t - k * .12;
        if (tk <= 0) continue;
        final e = Curves.easeOutCubic.transform(tk.clamp(0.0, 1.0));
        final a = (1 - tk).clamp(0.0, 1.0) * strength * (1 - k * .3);
        canvas.drawCircle(
          c,
          8 + e * reach,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 - k * .4
            ..color = color.withValues(alpha: .55 * a),
        );
      }
    }

    if (ambient != null) ring(ambient!, phase, .45);
    for (final r in rings) {
      ring(r.$1, r.$2, 1);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => true;
}

// ─────────────────────────── drag: depth tilt ───────────────────────────

/// The current tilt (-1..1 on each axis) for [Plane]s beneath.
class _TiltScope extends InheritedWidget {
  const _TiltScope({required this.tilt, required super.child});
  final Offset tilt;
  @override
  bool updateShouldNotify(_TiltScope old) => old.tilt != tilt;
}

/// Drag to tilt the planes; let go and they spring back to level.
class DepthTilt extends StatefulWidget {
  const DepthTilt({super.key, required this.child, this.rotate = 0, this.debugTilt});
  final Widget child;

  /// Max 3D rotation of the whole stage, radians. 0 = parallax only.
  final double rotate;
  final Offset? debugTilt;
  @override
  State<DepthTilt> createState() => _DepthTiltState();
}

class _DepthTiltState extends State<DepthTilt> with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  late final AnimationController _spring = AnimationController.unbounded(vsync: this)
    ..addListener(() => setState(() => _tilt = _from * _spring.value));
  Offset _from = Offset.zero;

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.debugTilt ?? _tilt;
    return LayoutBuilder(builder: (context, box) {
      return GestureDetector(
        onPanStart: (_) => _spring.stop(),
        onPanUpdate: (d) => setState(() {
          _tilt = Offset(
            (_tilt.dx + d.delta.dx / (box.maxWidth / 2)).clamp(-1.0, 1.0),
            (_tilt.dy + d.delta.dy / 160).clamp(-1.0, 1.0),
          );
        }),
        onPanEnd: (_) {
          HapticFeedback.lightImpact();
          _from = _tilt;
          _spring.value = 1;
          _spring.animateWith(SpringSimulation(
            const SpringDescription(mass: 1, stiffness: 120, damping: 11),
            1,
            0,
            0,
          ));
        },
        child: _TiltScope(
          tilt: t,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0012)
              ..rotateX(-t.dy * widget.rotate)
              ..rotateY(t.dx * widget.rotate),
            child: widget.child,
          ),
        ),
      );
    });
  }
}

/// A depth plane: [depth] 0 = the water surface, 1 = nearest the eye.
/// Near planes move further with tilt and lift a little with each breath.
class Plane extends StatelessWidget {
  const Plane({super.key, required this.depth, required this.child, this.phase = 0, this.drift = 0});
  final double depth;
  final double phase;

  /// Horizontal breath drift in px (signed).
  final double drift;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final tilt = context.dependOnInheritedWidgetOfExactType<_TiltScope>()?.tilt ?? Offset.zero;
    final lungs = Stillwater.lungs(phase);
    return Transform.translate(
      offset: Offset(tilt.dx * 18 * depth + drift * (lungs - .5) * 2, tilt.dy * 10 * depth - lungs * 4 * depth),
      child: child,
    );
  }
}

// ─────────────────────────── surfaces ───────────────────────────

/// The rim: a raised paper card (light) or a glass lid over ink (dark).
class PoolRim extends StatelessWidget {
  const PoolRim({super.key, required this.palette, required this.child, this.pad = const EdgeInsets.all(18)});
  final StillPalette palette;
  final Widget child;
  final EdgeInsets pad;
  @override
  Widget build(BuildContext context) {
    final paper = palette.water == Water.paper;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      padding: pad,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: paper ? palette.rim : null,
        gradient: paper
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withValues(alpha: .10), Colors.white.withValues(alpha: .03)],
              ),
        border: paper ? null : Border.all(color: Colors.white.withValues(alpha: .14)),
        boxShadow: paper
            ? const [
                BoxShadow(color: Color(0x24000000), offset: Offset(7, 7), blurRadius: 18),
                BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-7, -7), blurRadius: 18),
              ]
            : const [BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 14))],
      ),
      child: child,
    );
  }
}

/// The basin: the pressed-in water every Stillwater section holds.
class Basin extends StatelessWidget {
  const Basin({super.key, required this.palette, required this.child, this.radius = 24, this.circle = false});
  final StillPalette palette;
  final Widget child;
  final double radius;
  final bool circle;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.basinTop, palette.basinBottom],
          ),
          border: palette.water == Water.night ? Border.all(color: palette.light.withValues(alpha: .18)) : null,
        ),
        child: child,
      );
}

/// One calm call to action, shaped for its water.
class StillGo extends StatelessWidget {
  const StillGo({super.key, required this.label, required this.onTap, required this.palette, this.quiet = false});
  final String label;
  final VoidCallback? onTap;
  final StillPalette palette;
  final bool quiet;
  @override
  Widget build(BuildContext context) {
    final paper = palette.water == Water.paper;
    final bg = quiet
        ? (paper ? Colors.white : Colors.white.withValues(alpha: .08))
        : (paper ? palette.ink : palette.light);
    final fg = quiet ? palette.ink : (paper ? Colors.white : const Color(0xFF14100A));
    return Material(
      color: bg,
      shape: StadiumBorder(
          side: !paper && quiet ? BorderSide(color: Colors.white.withValues(alpha: .22)) : BorderSide.none),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: EditableLabel('stillwater.StillGo', label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: fg, letterSpacing: .2)),
        ),
      ),
    );
  }
}

/// Small spaced capital label above a section.
class StillEyebrow extends StatelessWidget {
  const StillEyebrow(this.text, {super.key, required this.palette});
  final String text;
  final StillPalette palette;
  @override
  Widget build(BuildContext context) => EditableLabel('stillwater.StillEyebrow', text,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.2,
          color: palette.water == Water.paper ? palette.light : palette.lightSoft));
}
