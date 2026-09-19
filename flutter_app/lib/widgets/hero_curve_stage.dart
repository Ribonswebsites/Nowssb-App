/// Lesmana-style 3D curve: the subject stays, campaign stills orbit behind.
///
/// Drag to turn the ring. Scroll parallax on the parent list. Auto-spins
/// when the ticker is live. Same widget on Normal (below search) and
/// Fashion (below the greeting, in glass).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass_wrap.dart';

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
  const HeroCurveStage({
    super.key,
    this.compact = false,
    this.glass = false,
  });

  /// Normal home: inset rounded stage.
  final bool compact;

  /// Fashion home: glass pane under the greeting.
  final bool glass;

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
    final height = widget.glass ? 580.0 : 540.0;
    final visual = ClipRRect(
      borderRadius: BorderRadius.circular(widget.glass ? 14 : 0),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: _stage(height),
      ),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        visual,
        const _CurveCopy(),
      ],
    );

    if (widget.glass) {
      return GlassWrap(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        child: body,
      );
    }
    if (widget.compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ColoredBox(color: const Color(0xFF050505), child: body),
        ),
      );
    }
    return ColoredBox(color: const Color(0xFF050505), child: body);
  }

  Widget _stage(double height) {
    final rot = _auto + _drag + _scroll * 0.0016;
    final n = HeroCurveAssets.cards.length;
    final step = (math.pi * 2) / n;
    final radius = height * 0.40;
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
                    alignment: const Alignment(0.04, 0.92),
                    child: FractionallySizedBox(
                      heightFactor: 0.72,
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
              const Positioned(
                left: 18,
                top: 16,
                child: Text(
                  'NowssB.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String asset, double angle, double radius,
      {VoidCallback? onTap}) {
    final depth = math.cos(angle);
    if (depth < -0.22) return const SizedBox.shrink();
    final scale = 0.72 + 0.28 * ((depth + 1) / 2);
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
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 152,
              height: 86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Sound that finds you',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFC4B5FD),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pronunciation & sound healing, wherever you are',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );
  }
}
