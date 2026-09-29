/// Neon concentric rings + heartbeat waveform, driven by audio amplitude.
///
/// `siri_orb` 0.0.3 supplies the reactive orb (`SiriORB` + `OrbController`).
/// The package does not draw expanding rings or a horizontal frequency line,
/// so those are a painter. A tap fires an extra outward pulse on top of the
/// ambient one (AnimationController, since the orb only exposes `onTap`).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:siri_orb/basic_orb.dart';
import 'package:siri_orb/siri_orb.dart';

import '../theme/liquid_glass_theme.dart';

/// Shared level for the player, profile halo and any listening orb.
class ListeningMeter extends ChangeNotifier {
  ListeningMeter._();
  static final ListeningMeter instance = ListeningMeter._();

  double amplitude = 0.08;
  bool speaking = false;

  void setSpeaking(bool on, {double volume = 1}) {
    speaking = on;
    if (!on) {
      amplitude = 0.08;
    } else {
      amplitude = (0.25 + volume * 0.35).clamp(0.0, 1.0);
    }
    notifyListeners();
  }

  /// Live level from playback (0–1). Ignored when reduced effects are on
  /// except for a quiet idle so the rings still breathe a little.
  void push(double value) {
    final next = value.clamp(0.0, 1.0);
    if ((next - amplitude).abs() < 0.02 && speaking) return;
    amplitude = next;
    notifyListeners();
  }

  void pulse() {
    amplitude = 1;
    notifyListeners();
  }
}

class ListeningRings extends StatefulWidget {
  const ListeningRings({
    super.key,
    this.playing = false,
    this.showOrb = true,
    this.orbRadius = 46,
  });

  final bool playing;
  final bool showOrb;
  final double orbRadius;

  @override
  State<ListeningRings> createState() => _ListeningRingsState();
}

class _ListeningRingsState extends State<ListeningRings>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _tap;
  late final OrbController _orb;
  double _level = 0.08;

  @override
  void initState() {
    super.initState();
    _orb = OrbController(initialAmplitude: 0.08);
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _tap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(ListeningRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    _drive();
  }

  void _drive() {
    final meter = ListeningMeter.instance;
    final reduced = NwsbEffects.instance.reduced;
    final t = _ambient.value;
    final active = widget.playing || meter.speaking;
    final base = active
        ? (0.22 + meter.amplitude * 0.55) *
            (0.65 + 0.35 * math.sin(t * math.pi * 2))
        : 0.06 + 0.05 * math.sin(t * math.pi * 2);
    final burst = _tap.isAnimating ? (1 - _tap.value) : 0.0;
    final next = reduced ? base * 0.45 : (base + burst * 0.85).clamp(0.0, 1.0);
    _level = next;
    _orb.amplitude = next;
  }

  void _onTap() {
    ListeningMeter.instance.pulse();
    _tap.forward(from: 0);
  }

  @override
  void dispose() {
    _ambient.dispose();
    _tap.dispose();
    _orb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _ambient,
          _tap,
          ListeningMeter.instance,
          NwsbEffects.instance,
        ]),
        builder: (context, _) {
          _drive();
          final reduced = NwsbEffects.instance.reduced;
          return RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _RingWavePainter(
                    t: _ambient.value,
                    tap: _tap.value,
                    tapping: _tap.isAnimating,
                    amplitude: _level,
                    reduced: reduced,
                  ),
                ),
                if (widget.showOrb && !reduced)
                  Center(
                    child: SiriORB(
                      controller: _orb,
                      radius: widget.orbRadius,
                      onTap: _onTap,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RingWavePainter extends CustomPainter {
  _RingWavePainter({
    required this.t,
    required this.tap,
    required this.tapping,
    required this.amplitude,
    required this.reduced,
  });

  final double t;
  final double tap;
  final bool tapping;
  final double amplitude;
  final bool reduced;

  static const _colors = <Color>[
    Color(0xFF3D7CFF),
    Color(0xFF7A4DFF),
    Color(0xFFFF4FD8),
    Color(0xFF49E7FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * 0.48;
    final rings = reduced ? 3 : 6;
    for (var i = 0; i < rings; i++) {
      final shift = (t + i / rings) % 1.0;
      final r = maxR * (0.18 + shift * 0.82) * (0.86 + amplitude * 0.28);
      final fade = (1 - shift) * (0.35 + amplitude * 0.65);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 + amplitude * 1.6
        ..color = _colors[i % _colors.length].withValues(alpha: fade.clamp(0.05, 0.9));
      if (!reduced) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      }
      canvas.drawCircle(center, r, paint);
    }
    if (tapping) {
      final r = maxR * (0.2 + tap * 0.95);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFFEAF4FF).withValues(alpha: (1 - tap) * 0.9);
      canvas.drawCircle(center, r, paint);
    }
    _wave(canvas, size, center);
  }

  void _wave(Canvas canvas, Size size, Offset center) {
    final path = Path();
    final mid = center.dy;
    final amp = 6 + amplitude * (reduced ? 16 : 34);
    path.moveTo(0, mid);
    for (double x = 0; x <= size.width; x += 2) {
      final u = x / size.width;
      final heart = math.pow(math.sin(u * math.pi), 8).toDouble();
      final y = mid -
          math.sin((u * 4 + t) * math.pi * 2) * amp * 0.35 -
          heart * amp * math.sin((u * 18 + t * 6) * math.pi);
      path.lineTo(x, y);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.55 + amplitude * 0.4);
    if (!reduced) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RingWavePainter old) =>
      old.t != t ||
      old.tap != tap ||
      old.amplitude != amplitude ||
      old.reduced != reduced ||
      old.tapping != tapping;
}
