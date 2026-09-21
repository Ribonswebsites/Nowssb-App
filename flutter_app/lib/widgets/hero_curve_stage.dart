/// Lesmana-style 3D curve: the subject stays, campaign stills orbit behind.
///
/// Drag to turn the ring. Scroll parallax on the parent list. Auto-spins
/// when the ticker is live. Same widget on Normal (below search) and
/// Fashion (below the greeting, in glass).
library;

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../screens/fashion/header.dart';
import 'app_thinking_loader.dart';
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

  /// Promo tablet on Fashion home — blonde cutout + campaign stills.
  static const tabSubject = 'assets/hero-curve/tab-subject.webp';
  static const tabCards = <String>[
    'assets/hero-curve/tab-window.webp',
    'assets/hero-curve/tab-desert.webp',
    'assets/hero-curve/tab-beach.webp',
    'assets/hero-curve/tab-stool.webp',
    'assets/hero-curve/tab-forest.webp',
    'assets/hero-curve/tab-rain.webp',
  ];
}

class HeroCurveStage extends StatefulWidget {
  const HeroCurveStage({
    super.key,
    this.compact = false,
    this.glass = false,
    this.embedded = false,
    this.subject,
    this.cards,
    this.onSearch,
    this.onQuickAccess,
  });

  /// Normal home: inset rounded stage.
  final bool compact;

  /// Fashion home: glass pane under the greeting.
  final bool glass;

  /// Inside a tablet aperture: transparent stage, no copy, smaller subject.
  final bool embedded;

  final String? subject;
  final List<String>? cards;

  /// Opens destination search (Hero header only).
  final VoidCallback? onSearch;

  /// Opens Quick access (Hero header only — not Frequency mid glass).
  final VoidCallback? onQuickAccess;

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
        // Same orbit path as before, only calmer and slower.
        setState(() => _auto += 0.0055);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final assets = <String>[
      widget.subject ?? HeroCurveAssets.subject,
      ...(widget.cards ?? HeroCurveAssets.cards),
    ];
    for (final asset in assets) {
      precacheImage(AssetImage(asset), context);
    }
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
    if (widget.embedded) {
      return LayoutBuilder(
        builder: (context, c) {
          final h = c.maxHeight > 0 ? c.maxHeight : 220.0;
          final w = c.maxWidth > 0 ? c.maxWidth : 320.0;
          return SizedBox.expand(child: _embedStage(w, h));
        },
      );
    }
    final height = widget.glass ? 560.0 : 600.0;
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
        if (widget.glass || widget.compact)
          _HeroChrome(
            onSearch: widget.onSearch,
            onQuickAccess: widget.onQuickAccess,
            // Fashion (glass) keeps search; Normal (compact) hero loses it.
            showSearch: widget.glass,
          ),
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

  /// 2D orbit inside a tablet. Matrix4 perspective is flattened by the
  /// video texture / save-layer, so the blonde and stills never painted.
  /// sin/cos placement composites the same way the Shabdapathy copy does.
  Widget _embedStage(double width, double height) {
    final rot = _auto + _drag + _scroll * 0.0016;
    final cards = widget.cards ?? HeroCurveAssets.tabCards;
    final subject = widget.subject ?? HeroCurveAssets.tabSubject;
    final n = cards.length;
    final step = (math.pi * 2) / n;
    final radius = width * 0.34;
    const cardW = 132.0;
    const cardH = 74.0;
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
            _embedCard(
              cards[i],
              rot + i * step,
              width,
              height,
              radius,
              cardW,
              cardH,
            ),
          IgnorePointer(
            child: Align(
              alignment: const Alignment(0.04, 1.0),
              child: FractionallySizedBox(
                heightFactor: 0.88,
                child: Stack(
                  fit: StackFit.passthrough,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        widthFactor: 0.46,
                        heightFactor: 0.82,
                        child: const SizedBox.expand(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(0, 0.1),
                                radius: 0.85,
                                colors: [
                                  Color(0xFF050505),
                                  Color(0xF2050505),
                                  Color(0x00050505),
                                ],
                                stops: [0.0, 0.62, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        1, 0, 0, 0, 0,
                        0, 1, 0, 0, 0,
                        0, 0, 1, 0, 0,
                        0, 0, 0, 2.2, 0,
                      ]),
                      child: Image.asset(
                        subject,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _embedCard(
    String asset,
    double angle,
    double width,
    double height,
    double radius,
    double cardW,
    double cardH,
  ) {
    final depth = math.cos(angle);
    if (depth < -0.12) return const SizedBox.shrink();
    final scale = 0.62 + 0.38 * ((depth + 1) / 2);
    final opacity = 0.45 + 0.55 * ((depth + 0.12) / 1.12).clamp(0.0, 1.0);
    final x = width / 2 + math.sin(angle) * radius - cardW / 2;
    final y = height * 0.42 - cardH / 2 + (1 - depth) * 10;
    return Positioned(
      left: x,
      top: y,
      width: cardW,
      height: cardH,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _drag += -angle;
          if (_drag.abs() > math.pi) _drag -= _drag.sign * math.pi * 2;
        }),
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x3DFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x99FFFFFF), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x88000000),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
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
      ),
    );
  }

  Widget _stage(double height) {
    final rot = _auto + _drag + _scroll * 0.0016;
    final cards = widget.cards ?? HeroCurveAssets.cards;
    final subject = widget.subject ?? HeroCurveAssets.subject;
    final n = cards.length;
    final step = (math.pi * 2) / n;
    // Keep the original orbit path, but tighten the radius to remove gaps.
    final radius = height * 0.31;
    final indices = List<int>.generate(n, (i) => i)
      ..sort((a, b) =>
          math.cos(rot + a * step).compareTo(math.cos(rot + b * step)));
    const rows = [-118.0, 0.0, 118.0];

    final stage = GestureDetector(
      behavior: widget.embedded
          ? HitTestBehavior.translucent
          : HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) {
        setState(() => _drag += d.delta.dx * 0.008);
      },
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
                    for (var r = 0; r < 3; r++)
                      for (final i in indices)
                        _card(
                          cards[i],
                          rot + i * step + r * (step / 3),
                          radius,
                          y: rows[r],
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
            // Subject LAST + opaque silhouette under cutout so orbit cards
            // never show through semi-transparent clothing (yuva webp).
            IgnorePointer(
              child: Transform.translate(
                offset: Offset(0, _scroll * -0.06),
                child: Align(
                  alignment: widget.embedded
                      ? const Alignment(0.02, 0.95)
                      : const Alignment(0.04, 0.92),
                  child: FractionallySizedBox(
                    heightFactor: widget.embedded ? 0.78 : 0.72,
                    child: Stack(
                      fit: StackFit.passthrough,
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Opaque body mask so orbit never reads through clothes.
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            widthFactor: 0.42,
                            heightFactor: 0.78,
                            child: const SizedBox.expand(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment(0, 0.15),
                                    radius: 0.85,
                                    colors: [
                                      Color(0xFF050505),
                                      Color(0xF2050505),
                                      Color(0x00050505),
                                    ],
                                    stops: [0.0, 0.62, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            1, 0, 0, 0, 0,
                            0, 1, 0, 0, 0,
                            0, 0, 1, 0, 0,
                            0, 0, 0, 2.2, 0,
                          ]),
                          child: Image.asset(
                            subject,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            filterQuality: FilterQuality.high,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.embedded) return stage;
    return ColoredBox(color: const Color(0xFF050505), child: stage);
  }

  Widget _card(String asset, double angle, double radius,
      {VoidCallback? onTap, double y = -8}) {
    final depth = math.cos(angle);
    if (depth < -0.22) return const SizedBox.shrink();
    final scale = 0.72 + 0.28 * ((depth + 1) / 2);
    final opacity = 0.38 + 0.62 * ((depth + 0.22) / 1.22).clamp(0.0, 1.0);
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateY(angle)
        ..translateByDouble(0.0, y, radius, 1.0),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: widget.embedded ? 150 : 152,
              height: widget.embedded ? 84 : 86,
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


/// Top of hero black/glass card: NowssB LEFT + Quick action RIGHT.
/// Search below only when [showSearch] (Fashion). Normal omits search.
class _HeroChrome extends StatelessWidget {
  const _HeroChrome({
    this.onSearch,
    this.onQuickAccess,
    this.showSearch = true,
  });
  final VoidCallback? onSearch;
  final VoidCallback? onQuickAccess;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Flexible(
                child: Text(
                  'NowssB.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onQuickAccess,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0x44FFFFFF)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppThinkingLoader(
                        size: 28,
                        state: OrbState.solving,
                        circlePad: 6,
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.apps_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Quick action',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 10),
            FashionGreetingSearch(
              compact: true,
              onOpen: onSearch,
            ),
          ],
        ],
      ),
    );
  }
}
