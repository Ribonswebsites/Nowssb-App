/// FilmDial — the Fashion Plus background-film visibility dial.
/// 270° arc, draggable gold knob, live percent (Anton), orbiting sparks.
/// value 0..1 (Builder default FilmDial.defaultValue = 0.45). onChanged fires
/// live while dragging; onChangeEnd fires on release (save nwsb_fashplus_bg_dim).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'film_dial_kit.dart';

class FilmDial extends StatefulWidget {
  const FilmDial({super.key, required this.value, this.onChanged, this.onChangeEnd, this.size = 250, this.debugPhase});
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double size;
  /// Freezes the spark orbit for shot tests.
  final double? debugPhase;

  static const defaultValue = 0.45;
  static const _start = math.pi * .75, _sweep = math.pi * 1.5;

  @override
  State<FilmDial> createState() => _FilmDialState();
}

class _FilmDialState extends State<FilmDial> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  late double _v = widget.value.clamp(0.0, 1.0);
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    if (widget.debugPhase == null) _spin.repeat();
  }

  @override
  void didUpdateWidget(FilmDial o) {
    super.didUpdateWidget(o);
    if (!_dragging && o.value != widget.value) _v = widget.value.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _set(double v) {
    v = v.clamp(0.0, 1.0);
    if ((v * 20).round() != (_v * 20).round()) HapticFeedback.selectionClick();
    setState(() => _v = v);
    widget.onChanged?.call(v);
  }

  void _at(Offset p, Size s) {
    final c = s.center(Offset.zero);
    var a = math.atan2(p.dy - c.dy, p.dx - c.dx) - FilmDial._start;
    while (a < 0) {
      a += math.pi * 2;
    }
    const sw = FilmDial._sweep;
    if (a > sw) a = a > sw + (math.pi * 2 - sw) / 2 ? 0 : sw;
    _set(a / sw);
  }

  void _end() {
    _dragging = false;
    widget.onChangeEnd?.call(_v);
  }

  void _step(double d) {
    _set(_v + d);
    widget.onChangeEnd?.call(_v);
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_v * 100).round();
    return Semantics(
      slider: true,
      value: '$pct%',
      label: 'Film visibility',
      increasedValue: '${math.min(100, pct + 10)}%',
      decreasedValue: '${math.max(0, pct - 10)}%',
      onIncrease: () => _step(.1),
      onDecrease: () => _step(-.1),
      child: Center(
        child: SizedBox.square(
          dimension: widget.size,
          child: LayoutBuilder(builder: (context, c) {
            final s = Size(c.maxWidth, c.maxHeight);
            return GestureDetector(
              onPanDown: (d) {
                _dragging = true;
                _at(d.localPosition, s);
              },
              onPanUpdate: (d) => _at(d.localPosition, s),
              onPanEnd: (_) => _end(),
              onPanCancel: _end,
              child: AnimatedBuilder(
                animation: _spin,
                builder: (context, _) => CustomPaint(
                  painter: _DialPainter(_v, widget.debugPhase ?? _spin.value),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('$pct', textScaler: TextScaler.noScaling, style: doorDisplay(64, ls: 0)),
                      Text('PERCENT FILM',
                          textScaler: TextScaler.noScaling, style: doorBody(10, color: doorGoldSoft, w: FontWeight.w800, ls: 2)),
                      const SizedBox(height: 6),
                      Container(
                        color: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        child: Text(pct < 25 ? 'Barely there' : pct < 70 ? 'Soft glow' : 'Full film',
                            textScaler: TextScaler.noScaling, style: doorBody(12, w: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.v, this.t);
  final double v, t;
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final r = s.width / 2 - 18;
    const st = FilmDial._start, sw = FilmDial._sweep;
    c.drawCircle(o, r + 14, Paint()..color = const Color(0xCC0A0614));
    c.drawCircle(o, r + 14, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = doorGold.withValues(alpha: .4));
    // ticks
    for (var i = 0; i <= 30; i++) {
      final a = st + sw * i / 30;
      final on = i / 30 <= v;
      final len = i % 5 == 0 ? 12.0 : 6.0;
      c.drawLine(o + Offset(math.cos(a), math.sin(a)) * (r - 16),
          o + Offset(math.cos(a), math.sin(a)) * (r - 16 - len),
          Paint()..strokeWidth = 2..color = on ? doorGoldSoft : Colors.white24);
    }
    final rect = Rect.fromCircle(center: o, radius: r);
    c.drawArc(rect, st, sw, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round..color = Colors.white12);
    c.drawArc(rect, st, sw * v, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(colors: [doorViolet, doorGold, doorGoldSoft]).createShader(rect));
    // orbiting sparks
    for (var k = 0; k < 3; k++) {
      final a = t * math.pi * 2 * (k.isEven ? 1 : -1) + k * 2.1;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * (r + 14), 3, Paint()..color = doorGoldSoft);
    }
    final ka = st + sw * v;
    final kp = o + Offset(math.cos(ka), math.sin(ka)) * r;
    c.drawCircle(kp, 17, Paint()..color = Colors.black54..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    c.drawCircle(kp, 15, Paint()..shader = const RadialGradient(colors: [doorGoldSoft, doorGold]).createShader(Rect.fromCircle(center: kp, radius: 15)));
    c.drawCircle(kp, 5, Paint()..color = doorInk);
  }

  @override
  bool shouldRepaint(_DialPainter o) => o.v != v || o.t != t;
}

