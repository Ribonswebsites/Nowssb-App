/// Zen Plus entry (Ribon 11-02): a white neumorphic card holding a brand-new
/// Flutter animation — a breathing lotus around a soft plus, with ripple
/// rings and three orbiting beads. No photo. Tapping blooms the lotus open,
/// then calls [onEnter].
///
/// [bgDim] is kept for call-site compatibility (the Zen home's dim setting)
/// and only deepens the lotus tint slightly, so the card previews it.
library;

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'surface.dart';

const _lav = Color(0xFF7B61D9);
const _peach = Color(0xFFE9A46B);

class NFashionPlusEntry extends StatefulWidget {
  const NFashionPlusEntry({super.key, required this.onEnter, this.bgDim});
  final VoidCallback onEnter;
  final double? bgDim;
  @override
  State<NFashionPlusEntry> createState() => _NFashionPlusEntryState();
}

class _NFashionPlusEntryState extends State<NFashionPlusEntry> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(milliseconds: 6000);
  bool _opening = false;

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  Future<void> _enter() async {
    if (_opening) return;
    setState(() => _opening = true);
    if (!_reduced) await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    widget.onEnter();
    if (!_reduced) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: NPress(label: 'Enter Zen Plus', onTap: _enter, child: Container(
        decoration: neu(r: 30), padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.fromLTRB(4, 4, 4, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Step into', style: nHello),
            Text('Zen Plus', style: nTitle),
            SizedBox(height: 4),
            Text('A calmer, deeper home for your practice. Tap anywhere to open it.', style: nSub),
          ])),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('zen-plus-well'),
            height: 236,
            decoration: neu(r: 22, pressed: true),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _opening ? 1 : 0), duration: _reduced ? Duration.zero : const Duration(milliseconds: 480), curve: Curves.easeOutCubic,
              builder: (_, open, __) => AnimatedBuilder(
                animation: loop,
                builder: (_, __) => CustomPaint(
                  key: const ValueKey('zen-plus-lotus'),
                  size: Size.infinite,
                  painter: ZenLotusPainter(t: loop.value, open: open, tint: (widget.bgDim ?? 0).clamp(0.0, 1.0)),
                ),
              ),
            ),
          ),
        ]),
      )));
}

/// Breathing lotus + plus, ripple rings and orbiting beads (t = 0..1 loop).
class ZenLotusPainter extends CustomPainter {
  ZenLotusPainter({required this.t, this.open = 0, this.tint = 0});
  final double t, open, tint;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r0 = math.min(s.width, s.height) * .5;
    final breathe = math.sin(t * math.pi * 2) * .5 + .5;
    // ripples
    for (var i = 0; i < 3; i++) {
      final k = (t + i / 3) % 1;
      canvas.drawCircle(c, r0 * (.35 + .6 * k), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _lav.withValues(alpha: .35 * (1 - k)));
    }
    // petals
    final petal = r0 * lerpDouble(.52, .62, breathe)! * (1 + .25 * open);
    final spread = lerpDouble(.18, .32, breathe)! + .3 * open;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + t * math.pi / 8;
      final tip = c + Offset(math.cos(a), math.sin(a)) * petal;
      final l = c + Offset(math.cos(a - spread), math.sin(a - spread)) * petal * .45;
      final r = c + Offset(math.cos(a + spread), math.sin(a + spread)) * petal * .45;
      final p = Path()
        ..moveTo(c.dx, c.dy)
        ..quadraticBezierTo(l.dx, l.dy, tip.dx, tip.dy)
        ..quadraticBezierTo(r.dx, r.dy, c.dx, c.dy);
      final col = Color.lerp(_lav, _peach, i.isEven ? .15 : .6)!;
      canvas.drawPath(p, Paint()..color = col.withValues(alpha: .20 + .12 * tint));
      canvas.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = col.withValues(alpha: .75));
    }
    // soft plus in the heart
    final arm = r0 * lerpDouble(.16, .2, breathe)!, th = r0 * .06;
    final plus = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: arm * 2, height: th * 2), Radius.circular(th));
    final plusV = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: th * 2, height: arm * 2), Radius.circular(th));
    canvas.drawCircle(c, arm * 1.25, Paint()..color = const Color(0xFFFFFFFF));
    final pp = Paint()..color = _lav;
    canvas.drawRRect(plus, pp);
    canvas.drawRRect(plusV, pp);
    // orbiting beads
    for (var i = 0; i < 3; i++) {
      final a = t * math.pi * 2 * (i.isEven ? 1 : -1) + i * 2.1;
      final rr = r0 * (.72 + .08 * i);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * rr, 3.5 + i.toDouble(), Paint()..color = i == 1 ? _peach : _lav);
    }
  }

  @override
  bool shouldRepaint(ZenLotusPainter o) => o.t != t || o.open != open || o.tint != tint;
}
