/// Flip glass brand showcase — filmstrip ↔ 3×3 grid (Flutter FLIP, no GSAP).
///
/// Fills the parent card footprint (same size as sibling H-scroll pages).
/// Filmstrip: near-square tiles with peeking neighbors (animos-style).
/// Grid: equal square 3×3. No demo labels / captions.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Brand stills — committed under assets/flip_brand (no recompression).
const kFlipBrandAssets = <String>[
  'assets/flip_brand/img1.jpg',
  'assets/flip_brand/img2.jpg',
  'assets/flip_brand/img3.jpg',
  'assets/flip_brand/img4.jpg',
  'assets/flip_brand/img5.jpg',
  'assets/flip_brand/img6.jpg',
  'assets/flip_brand/img7.jpg',
  'assets/flip_brand/img8.jpg',
  'assets/flip_brand/img9.jpg',
];

class FlipBrandShowcase extends StatefulWidget {
  const FlipBrandShowcase({
    super.key,
    this.active = true,
    this.onCycleComplete,
  });

  /// When true and sufficiently on-screen, the filmstrip↔grid loop runs.
  final bool active;

  /// Fired after one full cycle (row → grid → row), before the next loop.
  final VoidCallback? onCycleComplete;

  @override
  State<FlipBrandShowcase> createState() => _FlipBrandShowcaseState();
}

enum _FlipMode { row, grid }

class _FlipBrandShowcaseState extends State<FlipBrandShowcase>
    with SingleTickerProviderStateMixin {
  static const _gap = 10.0;
  static const _tileRadius = 14.0;
  static const _stageRadius = 16.0;
  static const _holdMs = 1500;
  static const _flipMs = 850;
  static const _n = 9;

  /// Filmstrip tile ≈ 72% of stage width → one hero + peeking neighbors.
  static const _stripFrac = 0.72;

  final _stageKey = GlobalKey();
  final _tileKeys = List<GlobalKey>.generate(_n, (_) => GlobalKey());
  final _stripCtrl = ScrollController();

  late final AnimationController _flip;

  _FlipMode _mode = _FlipMode.row;
  bool _animating = false;
  bool _looping = false;
  bool _visible = false;
  /// Grid entrance FLIP runs once per mount; later grid reveals snap settled.
  bool _gridEntrancePlayed = false;
  List<Offset>? _deltas;
  List<Size>? _fromSizes;
  List<Size>? _toSizes;
  Timer? _probe;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _flipMs),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _probeVisibility();
      _precacheBrandStills();
    });
    _probe = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _probeVisibility();
    });
  }

  void _precacheBrandStills() {
    if (!mounted) return;
    for (final path in kFlipBrandAssets) {
      unawaited(precacheImage(AssetImage(path), context));
    }
  }

  @override
  void didUpdateWidget(covariant FlipBrandShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _probeVisibility());
    }
    if (!widget.active) {
      _looping = false;
    }
  }

  @override
  void dispose() {
    _looping = false;
    _probe?.cancel();
    _flip.dispose();
    _stripCtrl.dispose();
    super.dispose();
  }

  void _probeVisibility() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final rb = box.localToGlobal(Offset.zero) & box.size;
    final screen = MediaQuery.sizeOf(context);
    final view = Offset.zero & screen;
    final overlap = rb.intersect(view);
    final frac = overlap.isEmpty
        ? 0.0
        : (overlap.width * overlap.height) / (rb.width * rb.height);
    final now = frac >= 0.4;
    if (now != _visible) {
      _visible = now;
    }
    if (now && widget.active) {
      _ensureLoop();
    } else {
      _looping = false;
    }
  }

  void _ensureLoop() {
    // After the grid has settled, never restart filmstrip→grid.
    if (_gridEntrancePlayed) return;
    if (_looping || !widget.active || !_visible) return;
    _looping = true;
    unawaited(_runLoop());
  }

  Future<void> _runLoop() async {
    // One-shot: filmstrip → grid, then settled grid persists.
    // Do NOT flip back to row or replay the grid entrance.
    try {
      await _playFilmstrip();
      if (!mounted || !_looping || !widget.active || !_visible) return;
      await _flipTo(_FlipMode.grid);
      if (!mounted) return;
      _gridEntrancePlayed = true;
      await Future<void>.delayed(const Duration(milliseconds: _holdMs));
      if (!mounted) return;
      widget.onCycleComplete?.call();
    } finally {
      _looping = false;
    }
  }

  Future<void> _playFilmstrip() async {
    if (_mode != _FlipMode.row) {
      setState(() => _mode = _FlipMode.row);
      await SchedulerBinding.instance.endOfFrame;
    }
    if (!_stripCtrl.hasClients) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    if (!_stripCtrl.hasClients) return;
    _stripCtrl.jumpTo(0);
    final max = _stripCtrl.position.maxScrollExtent;
    if (max < 8) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return;
    }
    final ms = (2400 + (max / 90) * 1000).clamp(2400, 6000).round();
    try {
      await _stripCtrl.animateTo(
        max,
        duration: Duration(milliseconds: ms),
        curve: Curves.linear,
      );
    } catch (_) {}
  }

  List<Rect> _captureRects() {
    final stageBox =
        _stageKey.currentContext?.findRenderObject() as RenderBox?;
    if (stageBox == null || !stageBox.hasSize) {
      return List<Rect>.filled(_n, Rect.zero);
    }
    final origin = stageBox.localToGlobal(Offset.zero);
    return [
      for (final k in _tileKeys)
        () {
          final b = k.currentContext?.findRenderObject() as RenderBox?;
          if (b == null || !b.hasSize) return Rect.zero;
          final g = b.localToGlobal(Offset.zero);
          return (g - origin) & b.size;
        }(),
    ];
  }

  Future<void> _flipTo(_FlipMode next) async {
    if (_animating || _mode == next) return;

    // After the first grid reveal, later returns to grid snap settled —
    // do not replay the entrance FLIP intro.
    if (next == _FlipMode.grid && _gridEntrancePlayed) {
      _animating = true;
      setState(() {
        _mode = next;
        _deltas = null;
        _fromSizes = null;
        _toSizes = null;
      });
      _clearFlipLeftovers();
      _animating = false;
      return;
    }

    _animating = true;
    final first = _captureRects();

    setState(() {
      _mode = next;
      _deltas = null;
      _fromSizes = null;
      _toSizes = null;
    });

    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) {
      _animating = false;
      return;
    }

    final last = _captureRects();
    _fromSizes = [for (final r in first) r.size];
    _toSizes = [for (final r in last) r.size];
    _deltas = [
      for (var i = 0; i < _n; i++) first[i].topLeft - last[i].topLeft,
    ];

    _flip.value = 0;
    setState(() {});
    try {
      await _flip.animateTo(1, curve: Curves.easeInOutCubic);
    } catch (_) {}
    if (!mounted) {
      _animating = false;
      return;
    }
    if (next == _FlipMode.grid) {
      _gridEntrancePlayed = true;
    }
    _clearFlipLeftovers();
    if (next == _FlipMode.row && _stripCtrl.hasClients) {
      _stripCtrl.jumpTo(0);
    }
    _animating = false;
  }

  void _clearFlipLeftovers() {
    _deltas = null;
    _fromSizes = null;
    _toSizes = null;
    _flip.value = 0;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Expand to the parent H-scroll card footprint (same as sibling pages).
    return SizedBox.expand(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_stageRadius),
        child: ColoredBox(
          color: const Color(0xFF0A0A0E),
          child: KeyedSubtree(
            key: _stageKey,
            child: _mode == _FlipMode.row ? _row() : _grid(),
          ),
        ),
      ),
    );
  }

  Widget _tile(int i) {
    final t = _flip.value;
    final delta =
        (_deltas != null && i < _deltas!.length) ? _deltas![i] : Offset.zero;
    final ox = delta.dx * (1 - t);
    final oy = delta.dy * (1 - t);

    double scaleX = 1;
    double scaleY = 1;
    if (_fromSizes != null &&
        _toSizes != null &&
        _toSizes![i].width > 0.5 &&
        _toSizes![i].height > 0.5) {
      final sx = _fromSizes![i].width / _toSizes![i].width;
      final sy = _fromSizes![i].height / _toSizes![i].height;
      scaleX = sx + (1 - sx) * t;
      scaleY = sy + (1 - sy) * t;
    }

    return KeyedSubtree(
      key: _tileKeys[i],
      child: Transform(
        transform: Matrix4.identity()
          ..translateByDouble(ox, oy, 0, 1)
          ..scaleByDouble(scaleX, scaleY, 1, 1),
        alignment: Alignment.topLeft,
        filterQuality: FilterQuality.low,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_tileRadius),
          child: ColoredBox(
            color: const Color(0xFF111111),
            child: Image(
              image: AssetImage(kFlipBrandAssets[i]),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) {
                  return child;
                }
                return const ColoredBox(color: Color(0xFF111111));
              },
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF111111)),
            ),
          ),
        ),
      ),
    );
  }

  /// Filmstrip: square / near-square tiles, vertically centered, neighbors peek.
  Widget _row() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        if (w <= 0 || h <= 0) return const SizedBox.shrink();

        // Square tiles — never tall strips. Cap by height so they fit with pad.
        final side = math.min(h * 0.92, w * _stripFrac);
        final padV = math.max(0.0, (h - side) / 2);

        return Padding(
          padding: EdgeInsets.symmetric(vertical: padV),
          child: ListView.separated(
            controller: _stripCtrl,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            itemCount: _n,
            separatorBuilder: (_, __) => const SizedBox(width: _gap),
            itemBuilder: (_, i) => SizedBox(
              width: side,
              height: side,
              child: _tile(i),
            ),
          ),
        );
      },
    );
  }

  /// 3×3 equal squares with even gaps — fills the stage, not tall columns.
  Widget _grid() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        if (w <= 0 || h <= 0) return const SizedBox.shrink();

        // Largest square that fits a 3×3 with gaps + outer pad.
        const outerPad = 8.0;
        final usableW = w - outerPad * 2;
        final usableH = h - outerPad * 2;
        final cell = (math.min(usableW, usableH) - _gap * 2) / 3;
        final gridSide = cell * 3 + _gap * 2;

        return Center(
          child: SizedBox(
            width: gridSide,
            height: gridSide,
            child: Column(
              children: [
                for (var r = 0; r < 3; r++) ...[
                  if (r > 0) const SizedBox(height: _gap),
                  SizedBox(
                    height: cell,
                    child: Row(
                      children: [
                        for (var col = 0; col < 3; col++) ...[
                          if (col > 0) const SizedBox(width: _gap),
                          SizedBox(
                            width: cell,
                            height: cell,
                            child: _tile(r * 3 + col),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
