/// The view a swipe up on the player opens: the current word's cover in a
/// carousel (the words before and after peek in at the edges), the title,
/// the seek bar, prev / play / next, and a glass bar with repeat, favourite
/// and shuffle.
///
/// Layout only is taken from Ribon's reference. The colours are NowssB's
/// own (deep navy, white, the hero glass), the play button is a rounded
/// square, and nothing here draws circles, rings, orbs or particles.
///
/// The view owns no player state. Every value comes from the player and
/// every tap goes back to it, so it always shows the same queue, word,
/// favourite, repeat and shuffle as the player underneath.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/app_haptics.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/glass_wrap.dart';

typedef PlayerUpCover = String Function(Word word, int index);

class PlayerUpView extends StatefulWidget {
  const PlayerUpView({
    super.key,
    required this.words,
    required this.index,
    required this.mixTitle,
    required this.coverFor,
    required this.playing,
    required this.liked,
    required this.shuffle,
    required this.repeat,
    required this.seekBar,
    required this.onClose,
    required this.onTogglePlay,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
    required this.onLike,
    required this.onShuffle,
    required this.onRepeat,
    required this.onQueue,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final List<Word> words;
  final int index;
  final String mixTitle;
  final PlayerUpCover coverFor;
  final bool playing;
  final bool liked;
  final bool shuffle;
  final bool repeat;

  /// The player's own seek bar (elapsed and total time).
  final Widget seekBar;

  final VoidCallback onClose;
  final VoidCallback onTogglePlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// A swipe on the carousel settled on word [index].
  final ValueChanged<int> onSelect;
  final VoidCallback onLike;
  final VoidCallback onShuffle;
  final VoidCallback onRepeat;
  final VoidCallback onQueue;

  /// Vertical drag on the view (pixels, down is positive) so the player can
  /// move the view with the finger and settle it open or closed.
  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onDragEnd;

  @override
  State<PlayerUpView> createState() => _PlayerUpViewState();
}

class _PlayerUpViewState extends State<PlayerUpView> {
  PageController? _pages;
  double _fraction = 0;

  /// True while the carousel is moved by the player (next/prev/shuffle),
  /// so that move is not read as the reader picking a word.
  var _syncing = false;

  @override
  void didUpdateWidget(covariant PlayerUpView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pages = _pages;
    if (pages == null || !pages.hasClients) return;
    final shown = (pages.page ?? pages.initialPage.toDouble()).round();
    if (shown != widget.index) {
      _syncing = true;
      final far = (shown - widget.index).abs() > 1;
      final move = far
          ? Future<void>.sync(() => pages.jumpToPage(widget.index))
          : pages.animateToPage(
              widget.index,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            );
      move.whenComplete(() {
        if (mounted) _syncing = false;
      });
    }
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  PageController _controllerFor(double fraction) {
    if (_pages == null || (_fraction - fraction).abs() > .001) {
      final at = _pages != null && _pages!.hasClients
          ? (_pages!.page ?? widget.index.toDouble()).round()
          : widget.index;
      _pages?.dispose();
      _pages = PageController(initialPage: at, viewportFraction: fraction);
      _fraction = fraction;
    }
    return _pages!;
  }

  void _tap(VoidCallback action) {
    AppHaptics.selection();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    final word = words[widget.index.clamp(0, words.length - 1)];
    final cover = widget.coverFor(word, widget.index);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) => widget.onDragUpdate(d.delta.dy),
      onVerticalDragEnd: (d) => widget.onDragEnd(d.primaryVelocity ?? 0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: NwsbColors.deep),
          // The current cover, blurred, as the page colour; the deep navy
          // over it keeps NowssB's own palette in charge.
          Opacity(
            opacity: .42,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36),
              child: _Cover(path: cover, key: ValueKey('up-bg-$cover')),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99060C18), Color(0xCC060C18), Color(0xF2040810)],
                stops: [0, .55, 1],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final wide = box.maxWidth >= 700 && box.maxWidth > box.maxHeight;
                return Column(
                  children: [
                    _TopBar(
                      mixTitle: widget.mixTitle,
                      onClose: () => _tap(widget.onClose),
                      onQueue: () => _tap(widget.onQueue),
                    ),
                    Expanded(
                      child: wide ? _wide(context, word) : _tall(context, word),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Phones and portrait tablets: everything stacked and centred.
  Widget _tall(BuildContext context, Word word) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        // Controls take a fixed band; the cover gets the rest, never more
        // than 72% of the width (so neighbours peek in) or 440 on tablets.
        const controls = 66.0 + 46 + 92 + 82 + 24;
        final card = math.max(
          120.0,
          math.min(math.min(w * .72, 440.0), box.maxHeight - controls - 28),
        );
        final contentW = math.min(w - 48, 560.0);
        return Column(
          children: [
            const Spacer(flex: 2),
            _carousel(w, card),
            const Spacer(flex: 2),
            SizedBox(width: contentW, child: _titleBlock(word)),
            const SizedBox(height: 6),
            SizedBox(width: contentW, child: widget.seekBar),
            const SizedBox(height: 6),
            SizedBox(width: contentW, child: _transport(84)),
            const Spacer(flex: 1),
            SizedBox(width: contentW, child: _bottomBar()),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  /// Landscape tablets: the cover carousel on the left, the controls on the
  /// right, so nothing has to shrink to fit the short height.
  Widget _wide(BuildContext context, Word word) {
    return LayoutBuilder(
      builder: (context, box) {
        final leftW = box.maxWidth * .54;
        final card = math.max(
          160.0,
          math.min(box.maxHeight - 48, leftW * .68),
        );
        return Row(
          children: [
            // Clipped so the neighbours peek in without reaching the controls.
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 24),
              child: ClipRect(
                child: SizedBox(
                  width: leftW - 40,
                  child: Center(child: _carousel(leftW - 40, card)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 40, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _titleBlock(word),
                    const SizedBox(height: 14),
                    widget.seekBar,
                    const SizedBox(height: 10),
                    _transport(92),
                    const SizedBox(height: 22),
                    _bottomBar(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _carousel(double width, double card) {
    final fraction = ((card + 12) / width).clamp(.3, 1.0);
    final pages = _controllerFor(fraction);
    return SizedBox(
      height: card,
      width: width,
      child: PageView.builder(
        key: const ValueKey('player-up-carousel'),
        controller: pages,
        itemCount: widget.words.length,
        padEnds: true,
        onPageChanged: (i) {
          if (_syncing || i == widget.index) return;
          // A swipe that settles on a word plays it. No buzz here: haptics
          // are for taps only.
          widget.onSelect(i);
        },
        itemBuilder: (context, i) {
          final w = widget.words[i];
          return AnimatedBuilder(
            animation: pages,
            builder: (context, child) {
              var page = widget.index.toDouble();
              if (pages.hasClients && pages.position.haveDimensions) {
                page = pages.page ?? page;
              }
              final d = (page - i).abs().clamp(0.0, 1.0);
              return Opacity(
                opacity: 1 - d * .35,
                child: Transform.scale(scale: 1 - d * .1, child: child),
              );
            },
            child: GestureDetector(
              onTap: i == widget.index ? () => _tap(widget.onTogglePlay) : null,
              child: Center(
                child: _CoverCard(
                  key: ValueKey('player-up-cover-$i'),
                  path: widget.coverFor(w, i),
                  size: card,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titleBlock(Word word) {
    final t = word.word.trim();
    final title = t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
    final sub = [
      if (word.deva.trim().isNotEmpty) word.deva.trim(),
      widget.mixTitle.trim().isEmpty ? 'NowssB' : widget.mixTitle.trim(),
    ].join('  ·  ');
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            key: const ValueKey('player-up-title'),
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            sub,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _transport(double play) {
    return SizedBox(
      height: play + 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconTap(
            key: const ValueKey('player-up-prev'),
            icon: Icons.skip_previous_rounded,
            size: 40,
            label: 'Previous',
            onTap: () => _tap(widget.onPrevious),
          ),
          SizedBox(width: play * .42),
          Semantics(
            button: true,
            label: widget.playing ? 'Pause' : 'Play',
            child: GestureDetector(
              key: const ValueKey('player-up-play'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _tap(widget.onTogglePlay),
              child: Container(
                width: play,
                height: play,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(play * .3),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 10)),
                  ],
                ),
                child: Icon(
                  widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: NwsbColors.deep,
                  size: play * .5,
                ),
              ),
            ),
          ),
          SizedBox(width: play * .42),
          _IconTap(
            key: const ValueKey('player-up-next'),
            icon: Icons.skip_next_rounded,
            size: 40,
            label: 'Next',
            onTap: () => _tap(widget.onNext),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return GlassWrap(
      margin: EdgeInsets.zero,
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconTap(
            key: const ValueKey('player-up-repeat'),
            icon: Icons.repeat_rounded,
            size: 24,
            on: widget.repeat,
            label: widget.repeat ? 'Repeat on' : 'Repeat off',
            onTap: () => _tap(widget.onRepeat),
          ),
          _IconTap(
            key: const ValueKey('player-up-like'),
            icon: widget.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 26,
            on: widget.liked,
            label: widget.liked ? 'Remove from favourites' : 'Add to favourites',
            onTap: () => _tap(widget.onLike),
          ),
          _IconTap(
            key: const ValueKey('player-up-shuffle'),
            icon: Icons.shuffle_rounded,
            size: 24,
            on: widget.shuffle,
            label: widget.shuffle ? 'Shuffle on' : 'Shuffle off',
            onTap: () => _tap(widget.onShuffle),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.mixTitle, required this.onClose, required this.onQueue});
  final String mixTitle;
  final VoidCallback onClose;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The grab handle: tap or drag it down to close.
        GestureDetector(
          key: const ValueKey('player-up-handle'),
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: const SizedBox(
            height: 22,
            width: 120,
            child: Center(
              child: SizedBox(
                width: 42,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x66FFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                _GlassSquare(
                  key: const ValueKey('player-up-close'),
                  icon: Icons.keyboard_arrow_down_rounded,
                  label: 'Close',
                  onTap: onClose,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'NOW PLAYING',
                        maxLines: 1,
                        style: TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 10.5,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            mixTitle.trim().isEmpty ? 'NowssB' : mixTitle.trim(),
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _GlassSquare(
                  key: const ValueKey('player-up-queue'),
                  icon: Icons.queue_music_rounded,
                  label: 'Queue',
                  onTap: onQueue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A small glass button with rounded corners (the kit glass, not a circle).
class _GlassSquare extends StatelessWidget {
  const _GlassSquare({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: GlassWrap.blurSigma, sigmaY: GlassWrap.blurSigma),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: GlassWrap.fill,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: GlassWrap.line),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  const _IconTap({
    super.key,
    required this.icon,
    required this.size,
    required this.label,
    required this.onTap,
    this.on,
  });
  final IconData icon;
  final double size;
  final String label;
  final VoidCallback onTap;

  /// null: a plain control; true/false: a toggle that is on or off.
  final bool? on;

  @override
  Widget build(BuildContext context) {
    final lit = on ?? true;
    return Semantics(
      button: true,
      toggled: on,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: math.max(48, size + 16),
          height: math.max(48, size + 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: size, color: lit ? Colors.white : const Color(0x80FFFFFF)),
              if (on != null) ...[
                const SizedBox(height: 3),
                // A short bar under a toggle that is on (no dot, no circle).
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: on! ? 14 : 0,
                  height: 2.5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({super.key, required this.path, required this.size});
  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(size * .1);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [
          BoxShadow(color: Color(0x8C000000), blurRadius: 30, offset: Offset(0, 16)),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF0B0F1A)),
            _Cover(path: path),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: r,
                border: Border.all(color: const Color(0x1FFFFFFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext _, Object __, StackTrace? ___) =>
        const ColoredBox(color: Color(0xFF0B0F1A));
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: fallback);
    }
    return Image.asset(path, fit: BoxFit.cover, errorBuilder: fallback);
  }
}
