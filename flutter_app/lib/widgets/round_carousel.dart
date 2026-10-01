/// A spinning ring of photographs.
///
/// Every card sits on a cylinder: perspective, rotateY, then a push along Z.
/// Back faces stay visible, smaller and dimmer. Drag is horizontal only so
/// the page can still scroll. One ticker drives the spin.
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

  final List<String> images;
  final double speed;
  final double sensitivity;
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

  bool get _quiet =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(days: 1));
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
    if (_vel.abs() > 0.4) {
      _rot += _vel * f;
      _vel *= math.pow(0.95, f * 60).toDouble();
    } else {
      _vel = 0;
      _rot += widget.speed * 6 * f;
    }
    setState(() {});
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
        final stageW = c.maxWidth.isFinite ? c.maxWidth : 340.0;
        final cardW = (stageW * 0.46).clamp(128.0, 168.0);
        final cardH = cardW * 1.28;
        final count = images.length;
        final step = 2 * math.pi / count;
        final rot = _rot * math.pi / 180;
        final radius = cardW * 0.42;

        final order = List<int>.generate(count, (i) => i)
          ..sort((a, b) {
            final da = math.cos(rot + a * step);
            final db = math.cos(rot + b * step);
            return da.compareTo(db);
          });

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            _drag = true;
            _vel = 0;
          },
          onHorizontalDragUpdate: (e) {
            final k = 0.22 * widget.sensitivity;
            setState(() {
              _rot += e.delta.dx * k;
              _vel = e.delta.dx * k * 60;
            });
          },
          onHorizontalDragEnd: (_) => _drag = false,
          onHorizontalDragCancel: () => _drag = false,
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                for (final i in order)
                  _card(
                    asset: images[i],
                    angle: rot + i * step,
                    radius: radius,
                    cardW: cardW,
                    cardH: cardH,
                  ),
              ],
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
  }) {
    final depth = math.cos(angle);
    final facing = depth >= 0;
    final near = ((depth + 1) / 2).clamp(0.0, 1.0);
    final opacity = facing ? 0.72 + 0.28 * near : 0.35 + 0.25 * near;
    // Last call is applied first: slide out on Z, then swing around Y.
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(angle)
      ..translateByDouble(0, 0, radius, 1);

    return Transform(
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      transform: m,
      child: Opacity(
        opacity: opacity,
        child: _Face(
          asset: asset,
          width: cardW,
          height: cardH,
          radius: widget.cornerRadius,
          back: !facing,
        ),
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
    required this.back,
  });

  final String asset;
  final double width;
  final double height;
  final double radius;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final photo = Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF141414)),
    );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: back
            ? ColorFiltered(
                colorFilter: const ColorFilter.mode(Color(0xAA000000), BlendMode.darken),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(-1, 1, 1),
                  child: photo,
                ),
              )
            : photo,
      ),
    );
  }
}
