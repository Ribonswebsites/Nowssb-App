/// A real-looking coupon ticket: notched sides, a dashed perforation that
/// splits off a stub, a slow foil sheen, and a reveal (pop + settle) the
/// first time it appears. Pure Flutter paint — no external assets.
library;

import 'package:flutter/material.dart';

class TicketClipper extends CustomClipper<Path> {
  const TicketClipper({this.stubFraction = 0.72, this.notch = 11});
  final double stubFraction;
  final double notch;

  @override
  Path getClip(Size s) {
    final x = s.width * stubFraction;
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(16)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, 0), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(x, s.height), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(0, s.height / 2), radius: notch * .7))
      ..addOval(Rect.fromCircle(center: Offset(s.width, s.height / 2), radius: notch * .7));
    return Path.combine(PathOperation.difference, body, holes);
  }

  @override
  bool shouldReclip(TicketClipper old) => old.stubFraction != stubFraction || old.notch != notch;
}

class _PerforationPainter extends CustomPainter {
  _PerforationPainter(this.stubFraction, this.color);
  final double stubFraction;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final x = s.width * stubFraction;
    final p = Paint()..color = color..strokeWidth = 1.4..strokeCap = StrokeCap.round;
    for (double y = 16; y < s.height - 14; y += 8) {
      c.drawLine(Offset(x, y), Offset(x, y + 3.5), p);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter o) => o.stubFraction != stubFraction || o.color != color;
}

/// [body] goes left of the perforation, [stub] right of it.
class CouponTicket extends StatefulWidget {
  const CouponTicket({
    super.key,
    required this.body,
    required this.stub,
    this.height = 168,
    this.stubFraction = 0.72,
    this.reveal = true,
  });
  final Widget body;
  final Widget stub;
  final double height;
  final double stubFraction;
  final bool reveal;

  @override
  State<CouponTicket> createState() => _CouponTicketState();
}

class _CouponTicketState extends State<CouponTicket> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 720), value: widget.reveal ? 0 : 1);
  late final AnimationController _foil =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void initState() {
    super.initState();
    if (widget.reveal) _in.forward();
    // One slow sheen pass after the reveal; no endless loop (calm, test-safe).
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _foil.forward();
    });
  }

  @override
  void dispose() {
    _in.dispose();
    _foil.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFE4C56A);
    final ticket = ClipPath(
      clipper: TicketClipper(stubFraction: widget.stubFraction),
      child: Container(
        height: widget.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1408), Colors.black, Color(0xFF14100A)]),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _PerforationPainter(widget.stubFraction, const Color(0x80E4C56A)))),
          Row(children: [
            Expanded(
              flex: (widget.stubFraction * 100).round(),
              child: Padding(padding: const EdgeInsets.fromLTRB(18, 14, 14, 14), child: widget.body),
            ),
            Expanded(
              flex: ((1 - widget.stubFraction) * 100).round(),
              child: Padding(padding: const EdgeInsets.all(10), child: Center(child: widget.stub)),
            ),
          ]),
          // Foil sheen: one diagonal band of light sweeping across.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _foil,
                builder: (_, __) {
                  final t = Curves.easeInOut.transform(_foil.value);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.6 + 3.2 * t, -1),
                        end: Alignment(-0.9 + 3.2 * t, 1),
                        colors: const [Color(0x00FFFFFF), Color(0x2EFFF1C4), Color(0x00FFFFFF)],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
    return AnimatedBuilder(
      animation: _in,
      builder: (_, child) {
        final v = Curves.elasticOut.transform(_in.value.clamp(0.0, 1.0));
        final o = Curves.easeOut.transform(_in.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: o,
          child: Transform.scale(scale: 0.86 + 0.14 * v, child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x33E4C56A), blurRadius: 22, spreadRadius: -6)],
          border: Border.all(color: gold.withValues(alpha: 0)),
        ),
        child: ticket,
      ),
    );
  }
}
