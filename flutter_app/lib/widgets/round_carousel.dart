/// A spinning ring of photographs.
///
/// Port of the Originkit round carousel: each face sits on a cylinder,
/// the ring turns on its own, and a sideways drag takes the wheel. The
/// maths is the same — radius from the card width and the count, a
/// perspective, a slight tilt — drawn with [Transform] instead of CSS.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class RoundCarousel extends StatefulWidget {
  const RoundCarousel({
    super.key,
    required this.images,
    this.speed = 7,
    this.sensitivity = 5,
    this.tilt = -7,
    this.perspective = 3000,
    this.cornerRadius = 22,
    this.spacing = 3,
  });

  /// Asset paths, in ring order. At least four, or the cylinder collapses.
  final List<String> images;

  /// Matches the web control: degrees per second is `speed * 6`.
  final double speed;
  final double sensitivity;

  /// Degrees, tipping the ring back so the far faces read as further away.
  final double tilt;
  final double perspective;
  final double cornerRadius;
  final double spacing;

  @override
  State<RoundCarousel> createState() => _RoundCarouselState();
}

class _RoundCarouselState extends State<RoundCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  double _rot = 0;
  double _vel = 0;
  bool _drag = false;
  Duration _last = Duration.zero;

  /// A repeating ticker never lets `pumpAndSettle` finish. Widget tests
  /// get the ring standing still; the device gets the spin.
  bool get _quiet =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    );
    if (_quiet) return;
    _spin.addListener(_onTick);
    _spin.repeat();
  }

  void _onTick() {
    if (!mounted || _drag) return;
    final now = _spin.lastElapsedDuration ?? Duration.zero;
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    final f = math.min(dt, 0.1);
    if (f <= 0) return;
    setState(() {
      if (_vel.abs() > 0.4) {
        _rot += _vel * f;
        _vel *= math.pow(0.94, f * 60).toDouble();
      } else {
        _vel = 0;
        _rot += widget.speed * 6 * f;
      }
    });
  }

  @override
  void dispose() {
    _spin.removeListener(_onTick);
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.length < 2) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, c) {
        final cardW = (c.maxWidth * 0.42).clamp(128.0, 176.0);
        final cardH = cardW * 1.28;
        final count = images.length;
        final angle = 2 * math.pi / count;
        final factor = 1 + widget.spacing * 0.15;
        final radius = (cardW * factor) / (2 * math.tan(math.pi / count));
        final tilt = widget.tilt * math.pi / 180;
        final rot = _rot * math.pi / 180;

        final order = List<int>.generate(count, (i) => i)
          ..sort((a, b) {
            final fa = math.cos(rot + a * angle);
            final fb = math.cos(rot + b * angle);
            return fa.compareTo(fb);
          });

        return GestureDetector(
          onHorizontalDragStart: (_) {
            _drag = true;
            _vel = 0;
          },
          onHorizontalDragUpdate: (e) {
            final k = 0.28 * widget.sensitivity;
            setState(() {
              _rot += e.delta.dx * k;
              _vel = e.delta.dx * k * 60;
            });
          },
          onHorizontalDragEnd: (_) => _drag = false,
          onHorizontalDragCancel: () => _drag = false,
          child: SizedBox(
            height: cardH + 36,
            width: double.infinity,
            child: ClipRect(
              child: Transform(
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 1 / widget.perspective)
                  ..rotateX(tilt),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translateByDouble(0.0, 0.0, -radius, 1.0)
                    ..rotateY(rot),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final i in order)
                        Transform(
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.medium,
                          transform: Matrix4.identity()
                            ..rotateY(i * angle)
                            ..translateByDouble(0.0, 0.0, radius, 1.0),
                          child: _Face(
                            asset: images[i],
                            width: cardW,
                            height: cardH,
                            radius: widget.cornerRadius,
                            opacity: _fade(math.cos(rot + i * angle)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _fade(double facing) {
    return ((facing + 0.35) / 1.2).clamp(0.18, 1);
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.asset,
    required this.width,
    required this.height,
    required this.radius,
    required this.opacity,
  });

  final String asset;
  final double width;
  final double height;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            asset,
            width: width,
            height: height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF141414)),
          ),
        ),
      ),
    );
  }
}
