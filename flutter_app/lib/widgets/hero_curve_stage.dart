/// Lesmana-style 3D curve: the subject stays, campaign stills orbit behind.
///
/// Drag to turn the ring. Scroll parallax on the parent list. Auto-spins
/// when the ticker is live. Same widget on Normal (below search) and
/// Fashion (top of the hero).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

class HeroCurveAssets {
  static const subject = 'assets/hero-curve/subject.webp';
  static const cards = <String>[
    'assets/hero-curve/stillness.webp',
    'assets/hero-curve/countries.webp',
    'assets/hero-curve/cosmos.webp',
    'assets/hero-curve/cities.webp',
    'assets/hero-curve/currencies.webp',
    'assets/hero-curve/body.webp',
    'assets/hero-curve/listen.webp',
  ];
}

class HeroCurveStage extends StatefulWidget {
  const HeroCurveStage({super.key, this.compact = false});

  /// Normal home: inset rounded stage. Fashion: full-bleed.
  final bool compact;

  @override
  State<HeroCurveStage> createState() => _HeroCurveStageState();
}

class _HeroCurveStageState extends State<HeroCurveStage> {
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

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final height = compact ? 460.0 : 520.0;
    final stage = SizedBox(
      height: height,
      width: double.infinity,
      child: _stage(height),
    );
    if (!compact) return stage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: stage,
      ),
    );
  }

  Widget _stage(double height) {
    final rot = _auto + _drag + _scroll * 0.0016;
    final n = HeroCurveAssets.cards.length;
    final step = (math.pi * 2) / n;
    final radius = height * 0.42;
    final indices = List<int>.generate(n, (i) => i)
      ..sort((a, b) => math.cos(rot + a * step).compareTo(math.cos(rot + b * step)));

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
                        _card(
                          HeroCurveAssets.cards[i],
                          rot + i * step,
                          radius,
                          onTap: () => setState(() {
                            _drag += -((rot + i * step) % (math.pi * 2));
                            if (_drag.abs() > math.pi) {
                              _drag -= _drag.sign * math.pi * 2;
                            }
                          }),
                        ),
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                child: Transform.translate(
                  offset: Offset(0, _scroll * -0.06),
                  child: Align(
                    alignment: const Alignment(0.08, 1.06),
                    child: FractionallySizedBox(
                      heightFactor: 0.92,
                      child: Image.asset(
                        HeroCurveAssets.subject,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x99000000),
                      ],
                      stops: [0, 0.22, 0.62, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Transform.translate(
                  offset: Offset(0, _scroll * -0.04),
                  child: const _CurveCopy(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String asset, double angle, double radius, {VoidCallback? onTap}) {
    final depth = math.cos(angle);
    if (depth < -0.22) return const SizedBox.shrink();
    final scale = 0.72 + 0.28 * ((depth + 1) / 2);
    final opacity = 0.38 + 0.62 * ((depth + 0.22) / 1.22).clamp(0.0, 1.0);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateY(angle)
        ..translateByDouble(0.0, -18.0, radius, 1.0),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 132,
              height: 176,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x66FFFFFF), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF111111)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurveCopy extends StatelessWidget {
  const _CurveCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NOWSSB',
          style: TextStyle(
            color: NwsbColors.goldLight,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3.4,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Word Science',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 0.95,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Natural origin of sound',
          style: TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
