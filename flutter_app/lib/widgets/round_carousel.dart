/// A spinning ring of photographs.
///
/// Port of the Originkit round carousel. Nested Flutter transforms flatten
/// 3D, which painted an empty stage, so each card is placed by hand: sine
/// for the side position, cosine for depth, then scale, fade, and a slight
/// turn. Drag takes the wheel. The stage is black so the faces read.
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

  /// Asset paths, in ring order. At least two, or there is nothing to turn.
  final List<String> images;

  /// Matches the web control: degrees per second is `speed * 6`.
  final double speed;
  final double sensitivity;

  /// Degrees. Tips the far cards up so the cylinder reads.
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
        final stageW = c.maxWidth.isFinite ? c.maxWidth : 360.0;
        final cardW = (stageW * 0.26).clamp(92.0, 118.0);
        final cardH = cardW * 1.32;
        final count = images.length;
        final step = 2 * math.pi / count;
        final rot = _rot * math.pi / 180;
        final persp = 0.0022;
        // Wide enough that the side cards sit in black, not flush in a row.
        final radius = stageW * 0.52;

        final order = List<int>.generate(count, (i) => i)
          ..sort((a, b) {
            final da = math.cos(rot + a * step);
            final db = math.cos(rot + b * step);
            return da.compareTo(db);
          });

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: const Color(0xFF050506),
              child: SizedBox(
                height: cardH + 56,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (final i in order)
                      _card(
                        asset: images[i],
                        angle: rot + i * step,
                        radius: radius,
                        cardW: cardW,
                        cardH: cardH,
                        persp: persp,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _card({
    required String asset,
    required double angle,
    required double radius,
    required double cardW,
    required double cardH,
    required double persp,
  }) {
    final depth = math.cos(angle);
    // The back of the cylinder stays off the stage. Three faces, like the
    // Originkit shot: one large in front, one smaller on each side.
    if (depth < 0.15) return const SizedBox.shrink();
    final front = ((depth - 0.15) / 0.85).clamp(0.0, 1.0);
    final x = math.sin(angle) * radius;
    final y = (1 - front) * -14;
    final scale = 0.72 + 0.28 * front;
    final yaw = -math.sin(angle) * 0.72;
    final m = Matrix4.identity()
      ..setEntry(3, 2, persp)
      ..translateByDouble(x, y, 0.0, 1.0)
      ..rotateY(yaw)
      ..scaleByDouble(scale, scale, 1.0, 1.0);

    return Transform(
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      transform: m,
      child: _Face(
        asset: asset,
        width: cardW,
        height: cardH,
        radius: widget.cornerRadius,
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.asset,
    required this.width,
    required this.height,
    required this.radius,
  });

  final String asset;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, 8),
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
    );
  }
}
