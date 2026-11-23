/// A swipeable stack of practice cards, taken from the home's
/// `PRACTICES · MORNING` Depth stack (`_DepthCard` in calm_hero.dart) and
/// restyled in NowssB dark glass. The photos are the caller's (word photos
/// on the Store word page, never the home's ritual portraits). Swipe or
/// tap cycles the stack; Begin is a separate control.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../data/app_haptics.dart';

/// One sheet in [WordPracticeStack].
class WordStackEntry {
  const WordStackEntry({
    required this.word,
    required this.photo,
    required this.title,
    required this.onBegin,
    this.progress = '',
  });

  /// Small-caps kicker on the sheet and the name in the glass bar.
  final String word;

  /// Asset path or `http` URL. Word photographs, not a person from the
  /// home ritual card.
  final String photo;

  /// The large serif title on the front sheet.
  final String title;

  /// Short line under the word, e.g. "0 of 3 done".
  final String progress;

  final VoidCallback onBegin;
}

class WordPracticeStack extends StatefulWidget {
  const WordPracticeStack({
    super.key,
    required this.eyebrow,
    required this.entries,
    this.height = 400,
  });

  /// e.g. "PRACTICES · NATURE"
  final String eyebrow;
  final List<WordStackEntry> entries;
  final double height;

  @override
  State<WordPracticeStack> createState() => _WordPracticeStackState();
}

class _WordPracticeStackState extends State<WordPracticeStack>
    with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(mass: 1, stiffness: 260, damping: 24);
  late final AnimationController _pos = AnimationController.unbounded(vsync: this)
    ..addListener(() => setState(() {}));
  double _drag = 0, _start = 0;

  List<WordStackEntry> get _items => widget.entries;
  int get front => _items.isEmpty ? 0 : _pos.value.round() % _items.length;

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _settle(double target, double velocity) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _pos.value = target;
      return;
    }
    _pos.animateWith(SpringSimulation(_spring, _pos.value, target, velocity));
  }

  void _cycle() {
    if (_items.length < 2) return;
    AppHaptics.selection();
    _pos.stop();
    _start = _pos.value.roundToDouble();
    _settle(_start + 1, 0);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();
    final n = items.length;
    final raw = _pos.value;
    final p = (raw - raw.round()).abs() < .02 ? raw.roundToDouble() : raw;
    double depth(int i) => (i - p) % n;
    final order = [for (var i = 0; i < n; i++) i]..sort((a, b) => depth(b).compareTo(depth(a)));
    return Semantics(
      label: '${widget.eyebrow}. ${items[front].word}. ${front + 1} of $n',
      child: SizedBox(
        height: widget.height,
        child: GestureDetector(
          key: const ValueKey('word-practice-stack'),
          behavior: HitTestBehavior.opaque,
          onTap: _cycle,
          onVerticalDragStart: n < 2
              ? null
              : (_) {
                  _pos.stop();
                  _drag = 0;
                  _start = _pos.value.roundToDouble();
                },
          onVerticalDragUpdate: n < 2
              ? null
              : (u) {
                  _drag += u.delta.dy;
                  _pos.value = _start + (-_drag / 140).clamp(-1.0, 1.0);
                },
          onVerticalDragEnd: n < 2
              ? null
              : (e) {
                  final v = e.primaryVelocity ?? 0;
                  final d = (_drag < -24 || v < -250) ? 1 : (_drag > 24 || v > 250) ? -1 : 0;
                  _pos.animateWith(SpringSimulation(_spring, _pos.value, _start + d, -v / 140));
                },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xCC12141C),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0x33FFFFFF), width: .6),
                ),
                child: Stack(fit: StackFit.expand, children: [
                  Positioned(
                    left: 22,
                    top: 20,
                    right: 20,
                    child: Text(
                      widget.eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 50,
                    bottom: 16,
                    child: LayoutBuilder(builder: (context, c) {
                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        alignment: Alignment.bottomCenter,
                        children: [for (final i in order) _sheet(c, i, depth(i))],
                      );
                    }),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheet(BoxConstraints c, int wi, double dd) {
    final item = _items[wi];
    final n = _items.length;
    final leaving = dd > n - 1 ? dd - n : 0.0;
    final d = leaving < 0 ? 0.0 : dd;
    final isFront = wi == front;
    final h = c.maxHeight - 8;
    final m = Matrix4.identity()
      ..setEntry(3, 2, .001)
      ..translateByDouble(0, -d * 44.0 + leaving * 160, 0, 1)
      ..scaleByDouble(1 - d * .06, 1 - d * .06, 1, 1);
    final tint = _tints[wi % _tints.length];
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: h,
      child: Opacity(
        opacity: (1 + leaving).clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: m,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(fit: StackFit.expand, children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [tint.$1, tint.$2],
                  ),
                ),
              ),
              Opacity(opacity: .88, child: _photo(item.photo)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66000000), Color(0x00000000), Color(0xF2000000)],
                    stops: [0, .38, 1],
                  ),
                ),
              ),
              if (!isFront) ColoredBox(color: Colors.black.withValues(alpha: .18 * d)),
              Positioned(
                left: 16,
                top: isFront ? 14 : 8,
                right: 14,
                child: Row(children: [
                  Expanded(
                    child: Text(
                      item.word.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isFront ? Colors.white : const Color(0xB3FFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (isFront) ...[
                    Text(
                      '${wi + 1}/$n',
                      key: const ValueKey('word-stack-count'),
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (n > 1) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.swipe_vertical_rounded, size: 14, color: Color(0xCCFFFFFF)),
                    ],
                  ],
                ]),
              ),
              if (isFront)
                Positioned(
                  left: 16,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.title,
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: 'CormorantGaramond',
                            color: Colors.white,
                            fontSize: 30,
                            height: 1,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                            decoration: BoxDecoration(
                              color: const Color(0x24FFFFFF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0x38FFFFFF), width: .6),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.word.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: .4,
                                      ),
                                    ),
                                    if (item.progress.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        item.progress,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Flexible(child: _BeginPill(onTap: item.onBegin)),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _photo(String src) {
    if (src.startsWith('http')) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return Image.asset(
      src,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

/// Dark, non-gold tints so stacked sheet edges stay distinct.
const _tints = <(Color, Color)>[
  (Color(0xFF1A1E2A), Color(0xFF0B0D14)),
  (Color(0xFF1C1824), Color(0xFF0C0A10)),
  (Color(0xFF121A1C), Color(0xFF080A0C)),
  (Color(0xFF18161E), Color(0xFF0A090E)),
  (Color(0xFF142018), Color(0xFF080C0A)),
];

class _BeginPill extends StatelessWidget {
  const _BeginPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Begin',
        excludeSemantics: true,
        child: GestureDetector(
          key: const ValueKey('word-stack-begin'),
          onTap: () {
            AppHaptics.selection();
            onTap();
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F3),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.play_arrow_rounded, color: Color(0xFF16141C), size: 22),
              SizedBox(width: 4),
              Text(
                'Begin',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF16141C),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .1,
                ),
              ),
            ]),
          ),
        ),
      );
}
