import '../../nowssb_ui/app_video_backdrop.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Calm living background: drifting glow orbs + up to 32 slow motes.
/// Code-drawn (no assets). Static frame when [animate] is false.
class AuraBackground extends StatefulWidget {
  const AuraBackground({super.key, required this.child, this.animate = true});
  final Widget child;
  final bool animate;
  @override
  State<AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<AuraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 30));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(AuraBackground old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NAppBackdrop(child: widget.child);
}

class _AuraPainter extends CustomPainter {
  _AuraPainter(this.a) : super(repaint: a);
  final Animation<double> a;
  static final _rnd = math.Random(7);
  static final _motes = List.generate(32, (_) => [_rnd.nextDouble(), _rnd.nextDouble(), _rnd.nextDouble()]);

  @override
  void paint(Canvas canvas, Size s) {
    final t = a.value * 2 * math.pi;
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF241A5C), Color(0xFF120B2E), Color(0xFF0A0720)],
        ).createShader(Offset.zero & s),
    );
    void orb(double x, double y, double r, Color c) {
      final o = Offset(x * s.width, y * s.height);
      canvas.drawCircle(o, r, Paint()..shader = RadialGradient(colors: [c, c.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: r)));
    }
    orb(0.2 + 0.05 * math.sin(t), 0.18 + 0.03 * math.cos(t), s.width * 0.6, const Color(0x558B7CF6));
    orb(0.85 + 0.04 * math.cos(t), 0.55 + 0.05 * math.sin(t), s.width * 0.55, const Color(0x40D86AE8));
    orb(0.4 + 0.06 * math.sin(t + 2), 0.92, s.width * 0.5, const Color(0x30E8C46A));
    final mote = Paint();
    for (final m in _motes) {
      final y = (m[1] - a.value * (0.3 + m[2] * 0.4)) % 1.0;
      final x = m[0] + 0.02 * math.sin(t * 2 + m[2] * 6);
      mote.color = Colors.white.withValues(alpha: 0.12 + 0.25 * m[2]);
      canvas.drawCircle(Offset(x * s.width, y * s.height), 0.8 + m[2] * 1.6, mote);
    }
  }

  @override
  bool shouldRepaint(_AuraPainter old) => false;
}
