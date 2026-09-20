/// Rotating destination banners — Player, Library, Store, Reader.
///
/// Each still keeps its empty right side for a glass icon rail, a rule and
/// an Enter pill. The pointing figure sits in the bottom-right of the full
/// stage and aims at that pill. The same ring, smaller and with the blonde
/// in front, fills the promo tablet (no film behind her).
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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

  static const extras = <(String, String, String)>[
    ('ebook', 'eBook', NwsbMarks.ebook),
    ('healing', 'Healing', NwsbMarks.gender),
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
        setState(() => _auto += 0.01);
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

    const height = 236.0;
    final visual = ClipRRect(
      borderRadius: BorderRadius.circular(widget.glass ? 14 : 0),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, c) =>
              _coverStage(c.maxWidth > 0 ? c.maxWidth : 320.0, height),
        ),
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

  Widget _embedStage(double width, double height) {
    final rot = _auto + _drag + _scroll * 0.0016;
    const dests = EnterCurveAssets.destinations;
    final n = dests.length;
    final step = (math.pi * 2) / n;
    final radius = width * 0.32;
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
      child: ColoredBox(
        color: const Color(0xFF050505),
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final i in indices)
              _flatCard(
                dests[i],
                rot + i * step,
                width,
                height,
                radius,
                cardW,
                cardH,
                compact: true,
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
      ),
    );
  }

  Widget _coverStage(double width, double height) {
    final rot = _auto + _drag + _scroll * 0.0016;
    const dests = EnterCurveAssets.destinations;
    final n = dests.length;
    final step = (math.pi * 2) / n;
    final cardW = width * 0.92;
    final cardH = math.min(height * 0.90, cardW * 9 / 16);
    final radius = width * 0.24;
    final indices = List<int>.generate(n, (i) => i)
      ..sort((a, b) =>
          math.cos(rot + a * step).compareTo(math.cos(rot + b * step)));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) {
        setState(() => _drag += d.delta.dx * 0.01);
      },
      child: ColoredBox(
        color: const Color(0xFF050505),
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final i in indices)
              _flatCard(
                dests[i],
                rot + i * step,
                width,
                height,
                radius,
                cardW,
                cardH,
                compact: false,
              ),
            IgnorePointer(
              child: Align(
                alignment: const Alignment(1.06, 1.10),
                child: FractionallySizedBox(
                  heightFactor: 0.82,
                  widthFactor: 0.40,
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
          ],
        ),
      ),
    );
  }

  Widget _flatCard(
    EnterCurveDest dest,
    double angle,
    double width,
    double height,
    double radius,
    double cardW,
    double cardH, {
    required bool compact,
  }) {
    final depth = math.cos(angle);
    if (depth < (compact ? -0.12 : 0.22)) return const SizedBox.shrink();
    final scale = 0.62 + 0.38 * ((depth + 1) / 2);
    final opacity = 0.48 + 0.52 * ((depth + 0.12) / 1.12).clamp(0.0, 1.0);
    final x = width / 2 + math.sin(angle) * radius - cardW / 2;
    final y = compact
        ? height * 0.40 - cardH / 2 + (1 - depth) * 8
        : (height - cardH) / 2;
    return Positioned(
      left: x,
      top: y,
      width: cardW,
      height: cardH,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: _banner(dest, width: cardW, height: cardH, compact: compact),
        ),
      ),
    );
  }

  Widget _banner(
    EnterCurveDest dest, {
    required double width,
    required double height,
    required bool compact,
  }) {
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
              right: compact ? 6 : 10,
              top: compact ? 6 : 10,
              bottom: compact ? 6 : 10,
              child: _EnterRail(
                dest: dest,
                compact: compact,
                onOpen: _open,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnterRail extends StatelessWidget {
  const _EnterRail({
    required this.dest,
    required this.compact,
    required this.onOpen,
  });

  final EnterCurveDest dest;
  final bool compact;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final icons = <(String, String)>[
      for (final d in EnterCurveAssets.destinations) (d.id, d.mark),
      for (final e in EnterCurveAssets.extras) (e.$1, e.$3),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!compact)
          SizedBox(
            width: 52,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (final ic in icons)
                  _GlassChip(
                    mark: ic.$2,
                    size: 22,
                    onTap: () => onOpen(ic.$1),
                  ),
              ],
            ),
          )
        else
          _GlassChip(
            mark: dest.mark,
            size: 22,
            onTap: () => onOpen(dest.id),
          ),
        Container(
          width: 1,
          height: compact ? 22 : 36,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: const Color(0x66FFFFFF),
        ),
        _EnterPill(onTap: () => onOpen(dest.id)),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.mark,
    required this.size,
    required this.onTap,
  });

  final String mark;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x28FFFFFF),
              border: Border.all(color: const Color(0x66FFFFFF)),
            ),
            child: NwsbIcon(mark, size: size * 0.52),
          ),
        ),
      ),
    );
  }
}

class _EnterPill extends StatelessWidget {
  const _EnterPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0x28FFFFFF),
              border: Border.all(color: const Color(0x77FFFFFF)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 4),
                NwsbIcon(NwsbMarks.enterArrow, size: 10, viewBox: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
