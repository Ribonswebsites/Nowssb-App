/// Rotating destination banners — Player, Library, Store, Reader.
///
/// Two swipeable cards, each the same language as the Lesmana hero: a
/// smaller centred figure, 16:9 stills orbiting behind, copy above and
/// below. Card one is the pointing figure; card two is the Egyptian
/// centre. The promo tablet keeps the blonde in front of the same ring.
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
  static const cleopatra = 'assets/hero-curve/cleopatra.webp';
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

  /// Extra stills so the ring is as full as the hero (7 slots).
  static const extras = <String>[
    'assets/hero-curve/stillness.webp',
    'assets/hero-curve/cosmos.webp',
    'assets/hero-curve/cities.webp',
  ];
}

class _EnterPageSpec {
  const _EnterPageSpec({
    required this.subject,
    required this.kicker,
    required this.title,
    required this.sub,
  });

  final String subject;
  final String kicker;
  final String title;
  final String sub;
}

const _pages = <_EnterPageSpec>[
  _EnterPageSpec(
    subject: EnterCurveAssets.pointer,
    kicker: 'Enter your path',
    title: 'Player · Library · Store · Reader',
    sub: 'One still, one destination — her hand shows the way.',
  ),
  _EnterPageSpec(
    subject: EnterCurveAssets.cleopatra,
    kicker: 'Sound that holds you',
    title: 'Frequencies, words, healing',
    sub: 'The same ring, a different centre. Swipe to step in.',
  ),
];

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
  double _para = 0;
  double _auto = 0;
  int _page = 0;
  Timer? _tick;
  ScrollPosition? _pos;
  late final PageController _pager;

  @override
  void initState() {
    super.initState();
    _pager = PageController();
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
    if (!_flutterTest) {
      _pos?.addListener(_onScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onScroll();
      });
    }
  }

  void _onScroll() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final y = box.localToGlobal(Offset.zero).dy;
    final para = ((180 - y) * 0.12).clamp(-72.0, 72.0);
    if ((para - _para).abs() < 0.4) return;
    setState(() => _para = para);
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pos?.removeListener(_onScroll);
    _pager.dispose();
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
          return SizedBox.expand(
            child: _orbit(
              w,
              h,
              compact: true,
              subject: EnterCurveAssets.subject,
            ),
          );
        },
      );
    }

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 560,
          child: PageView(
            controller: _pager,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              for (final spec in _pages) _pageBody(spec),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _pages.length; i++)
              Container(
                width: i == _page ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _page
                      ? Colors.white
                      : const Color(0x55FFFFFF),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      ],
    );

    if (widget.glass) {
      return GlassWrap(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: body,
      );
    }
    return body;
  }

  Widget _pageBody(_EnterPageSpec spec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            children: [
              const Text(
                'NowssB.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                spec.kicker,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFC4B5FD),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LayoutBuilder(
              builder: (context, c) => _orbit(
                c.maxWidth > 0 ? c.maxWidth : 320.0,
                c.maxHeight > 0 ? c.maxHeight : 360.0,
                compact: false,
                subject: spec.subject,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          child: Text(
            spec.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            spec.sub,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  /// 2D cylindrical orbit matching the hero: small 16:9 tiles, centred
  /// subject. Parallax is viewport-relative so this deep pane stays put.
  Widget _orbit(
    double width,
    double height, {
    required bool compact,
    required String subject,
  }) {
    final rot = _auto + _drag + _para * 0.004;
    final items = <(String, EnterCurveDest?)>[
      for (final d in EnterCurveAssets.destinations) (d.banner, d),
      if (!compact) for (final a in EnterCurveAssets.extras) (a, null),
    ];
    final n = items.length;
    final step = (math.pi * 2) / n;
    final cardW = compact ? 168.0 : 152.0;
    final cardH = compact ? 94.0 : 86.0;
    final radius = compact ? width * 0.34 : width * 0.38;
    final originX = width / 2;
    final originY = compact ? height * 0.42 : height * 0.42;
    final indices = List<int>.generate(n, (i) => i)
      ..sort((a, b) =>
          math.cos(rot + a * step).compareTo(math.cos(rot + b * step)));

    return GestureDetector(
      behavior:
          compact ? HitTestBehavior.translucent : HitTestBehavior.opaque,
      onHorizontalDragUpdate: compact
          ? (d) {
              setState(() => _drag += d.delta.dx * 0.01);
            }
          : null,
      child: ColoredBox(
        color: const Color(0xFF050505),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(0, compact ? 0 : _para),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (final i in indices)
                    _flatCard(
                      items[i].$1,
                      items[i].$2,
                      rot + i * step,
                      originX,
                      originY,
                      radius,
                      cardW,
                      cardH,
                    ),
                ],
              ),
            ),
            IgnorePointer(
              child: Transform.translate(
                offset: Offset(0, compact ? 0 : _para * 0.35),
                child: Align(
                  alignment: const Alignment(0.04, 0.95),
                  child: FractionallySizedBox(
                    heightFactor: compact ? 0.88 : 0.50,
                    child: Image.asset(
                      subject,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
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
    );
  }

  Widget _flatCard(
    String asset,
    EnterCurveDest? dest,
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
            child: dest == null
                ? _still(asset, cardW, cardH)
                : _banner(dest, width: cardW, height: cardH),
          ),
        ),
      ),
    );
  }

  Widget _still(String asset, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x66FFFFFF), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 14,
            offset: Offset(0, 8),
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
    );
  }

  Widget _banner(EnterCurveDest dest, {required double width, required double height}) {
    return GestureDetector(
      onTap: () => _open(dest.id),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
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
              top: 6,
              right: 6,
              child: _WhiteChip(
                mark: dest.mark,
                onTap: () => _open(dest.id),
              ),
            ),
            Positioned(
              right: 8,
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
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: NwsbIcon(mark, size: 11, color: Colors.black),
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
        padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
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
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 3),
            NwsbIcon(NwsbMarks.enterArrow, size: 9, viewBox: 12, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
