/// Rotating destination banners — Player, Library, Store, Reader.
///
/// Same language as the Lesmana hero: the stills orbit behind the figure
/// with perspective and scroll parallax. Each still keeps its own icon in
/// a white circle (top-right) and Enter in a white pill on the empty right.
/// The pointing figure is a cutout — no studio box — bottom-right, aiming
/// at that pill. The promo tablet uses the same ring with the blonde in front.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass_wrap.dart';
import 'hero_curve_stage.dart';
import 'nwsb_icon.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

class EnterCurveDest {
  const EnterCurveDest({
    required this.id,
    required this.banner,
    required this.label,
    required this.mark,
  });

  final String id;
  final String banner;
  final String label;
  final String mark;
}

class EnterCurveAssets {
  static const pointer = 'assets/hero-curve/pointer.webp';
  static const subject = HeroCurveAssets.tabSubject;

  static const destinations = <EnterCurveDest>[
    EnterCurveDest(
      id: 'player',
      banner: 'assets/hero-curve/banner-player.webp',
      label: 'Player',
      mark: NwsbMarks.play24,
    ),
    EnterCurveDest(
      id: 'library',
      banner: 'assets/hero-curve/banner-library.webp',
      label: 'Sound Library',
      mark: NwsbMarks.sound,
    ),
    EnterCurveDest(
      id: 'store',
      banner: 'assets/hero-curve/banner-store.webp',
      label: 'Store',
      mark: NwsbMarks.bag,
    ),
    EnterCurveDest(
      id: 'reader',
      banner: 'assets/hero-curve/banner-reader.webp',
      label: 'Reader',
      mark: NwsbMarks.reader,
    ),
  ];
}

class EnterCurveStage extends StatefulWidget {
  const EnterCurveStage({
    super.key,
    this.embedded = false,
    this.glass = false,
    this.onOpen,
  });

  /// Inside the promo tablet: blonde in front, no pointer, no copy.
  final bool embedded;

  /// Fashion pane around the full stage.
  final bool glass;

  final void Function(String id)? onOpen;

  @override
  State<EnterCurveStage> createState() => _EnterCurveStageState();
}

class _EnterCurveStageState extends State<EnterCurveStage> {
  double _drag = 0;
  double _scroll = 0;
  double _auto = 0;
  Timer? _tick;
  ScrollPosition? _pos;

  @override
  void initState() {
    super.initState();
    if (!_flutterTest) {
      _tick = Timer.periodic(const Duration(milliseconds: 32), (_) {
        if (!mounted) return;
        setState(() => _auto += 0.012);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next == _pos) return;
    _pos?.removeListener(_onScroll);
    _pos = next;
    if (!_flutterTest) _pos?.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted || _pos == null) return;
    setState(() => _scroll = _pos!.pixels);
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pos?.removeListener(_onScroll);
    super.dispose();
  }

  void _open(String id) => widget.onOpen?.call(id);

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight > 0 ? c.maxHeight : 220.0;
          final w = c.maxWidth > 0 ? c.maxWidth : 320.0;
          return SizedBox.expand(child: _embedStage(w, h));
        },
      );
    }

    const height = 560.0;
    final visual = ClipRRect(
      borderRadius: BorderRadius.circular(widget.glass ? 14 : 0),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: _fullStage(height),
      ),
    );

    if (widget.glass) {
      return GlassWrap(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: visual,
      );
    }
    return visual;
  }

  /// 2D orbit inside the tablet — Matrix4 is flattened by the frame.
  Widget _embedStage(double width, double height) {
    final rot = _auto + _drag + _scroll * 0.0016;
    const dests = EnterCurveAssets.destinations;
    final n = dests.length;
    final step = (math.pi * 2) / n;
    final radius = width * 0.34;
    const cardW = 168.0;
    const cardH = 94.0;
    final indices = List<int>.generate(n, (i) => i)
      ..sort((a, b) =>
          math.cos(rot + a * step).compareTo(math.cos(rot + b * step)));

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) {
        setState(() => _drag += d.delta.dx * 0.01);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final i in indices)
            _flatCard(
              dests[i],
              rot + i * step,
              width / 2,
              height * 0.42,
              radius,
              cardW,
              cardH,
            ),
          IgnorePointer(
            child: Align(
              alignment: const Alignment(0.04, 1.0),
              child: FractionallySizedBox(
                heightFactor: 0.90,
                child: Image.asset(
                  EnterCurveAssets.subject,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Perspective ring + scroll parallax, matching the hero curve.
  Widget _fullStage(double height) {
    final rot = _auto + _drag + _scroll * 0.0016;
    const dests = EnterCurveAssets.destinations;
    final n = dests.length;
    final step = (math.pi * 2) / n;
    final radius = height * 0.38;
    final indices = List<int>.generate(n, (i) => i)
      ..sort((a, b) =>
          math.cos(rot + a * step).compareTo(math.cos(rot + b * step)));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) {
        setState(() => _drag += d.delta.dx * 0.008);
      },
      child: ColoredBox(
        color: const Color(0xFF050505),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, _scroll * -0.18),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.00115),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final i in indices)
                        _spinCard(dests[i], rot + i * step, radius),
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                child: Transform.translate(
                  offset: Offset(0, _scroll * -0.06),
                  child: Align(
                    alignment: const Alignment(1.12, 1.04),
                    child: FractionallySizedBox(
                      heightFactor: 0.88,
                      child: Image.asset(
                        EnterCurveAssets.pointer,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spinCard(EnterCurveDest dest, double angle, double radius) {
    final depth = math.cos(angle);
    if (depth < -0.22) return const SizedBox.shrink();
    final scale = 0.70 + 0.30 * ((depth + 1) / 2);
    final opacity = 0.38 + 0.62 * ((depth + 0.22) / 1.22).clamp(0.0, 1.0);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateY(angle)
        ..translateByDouble(0.0, -8.0, radius, 1.0),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: _banner(dest, width: 200, height: 112),
        ),
      ),
    );
  }

  Widget _flatCard(
    EnterCurveDest dest,
    double angle,
    double originX,
    double originY,
    double radius,
    double cardW,
    double cardH,
  ) {
    final depth = math.cos(angle);
    if (depth < -0.18) return const SizedBox.shrink();
    final scale = 0.58 + 0.42 * ((depth + 1) / 2);
    final opacity = 0.40 + 0.60 * ((depth + 0.18) / 1.18).clamp(0.0, 1.0);
    final x = originX + math.sin(angle) * radius - cardW / 2;
    final y = originY - cardH / 2 + (1 - depth) * 8;
    return Positioned(
      left: x,
      top: y,
      width: cardW,
      height: cardH,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..rotateY(math.sin(angle) * 0.62),
          child: Transform.scale(
            scale: scale,
            child: _banner(dest, width: cardW, height: cardH),
          ),
        ),
      ),
    );
  }

  Widget _banner(EnterCurveDest dest, {required double width, required double height}) {
    return GestureDetector(
      onTap: () => _open(dest.id),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x66FFFFFF), width: 1.1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              dest.banner,
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF111111)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _WhiteChip(
                mark: dest.mark,
                onTap: () => _open(dest.id),
              ),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _WhiteEnter(onTap: () => _open(dest.id)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteChip extends StatelessWidget {
  const _WhiteChip({required this.mark, required this.onTap});

  final String mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: NwsbIcon(mark, size: 13, color: Colors.black),
      ),
    );
  }
}

class _WhiteEnter extends StatelessWidget {
  const _WhiteEnter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 4),
            NwsbIcon(NwsbMarks.enterArrow, size: 10, viewBox: 12, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
