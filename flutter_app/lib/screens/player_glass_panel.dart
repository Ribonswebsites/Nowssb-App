/// The main player's glass panel, built on Ribon's reference layout:
/// a large rounded pane whose top edge dips in a soft curve, a cover-art
/// carousel (the words before and after peek in at the edges), the title,
/// a thin seek line, prev / rounded-square play / next, and a glass bar at
/// the pane's foot with repeat, favourite and shuffle.
///
/// Only the structure is taken from the reference. Colours are NowssB's own
/// (deep navy, white) and every surface is the kit glass (GlassWrap fill,
/// hairline and blur). Nothing here draws circles, rings, orbs or particles.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/app_haptics.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/glass_wrap.dart';

typedef PlayerCoverFor = String Function(Word word, int index);

/// Runs a tap: one light buzz, then the action. Haptics are for taps only;
/// swipes and page changes never buzz.
void playerTap(VoidCallback action) {
  AppHaptics.selection();
  action();
}

/// The pane's outline: a rounded rectangle whose top edge rises gently
/// towards the middle, like the reference's curved top.
class PlayerWaveBorder extends ShapeBorder {
  const PlayerWaveBorder({this.radius = 28, this.wave = 14});
  final double radius;

  /// How far the corners sit below the crest of the top edge.
  final double wave;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  Path _path(Rect r) {
    final rad = radius;
    final top = r.top + wave;
    return Path()
      ..moveTo(r.left, top + rad)
      ..quadraticBezierTo(r.left, top, r.left + rad, top)
      ..cubicTo(
        r.left + r.width * .30,
        top,
        r.left + r.width * .32,
        r.top,
        r.center.dx,
        r.top,
      )
      ..cubicTo(
        r.right - r.width * .32,
        r.top,
        r.right - r.width * .30,
        top,
        r.right - rad,
        top,
      )
      ..quadraticBezierTo(r.right, top, r.right, top + rad)
      ..lineTo(r.right, r.bottom - rad)
      ..quadraticBezierTo(r.right, r.bottom, r.right - rad, r.bottom)
      ..lineTo(r.left + rad, r.bottom)
      ..quadraticBezierTo(r.left, r.bottom, r.left, r.bottom - rad)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      _path(rect.deflate(.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = GlassWrap.line,
    );
  }

  @override
  ShapeBorder scale(double t) =>
      PlayerWaveBorder(radius: radius * t, wave: wave * t);
}

/// The big frosted pane everything on the player sits in.
class PlayerWavePanel extends StatelessWidget {
  const PlayerWavePanel({super.key, required this.child, this.wave = 14});
  final Widget child;
  final double wave;

  @override
  Widget build(BuildContext context) {
    final shape = PlayerWaveBorder(wave: wave);
    return DecoratedBox(
      key: const ValueKey('player-glass-panel'),
      decoration: ShapeDecoration(
        shape: shape,
        shadows: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 40, offset: Offset(0, 18)),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: GlassWrap.blurSigma,
            sigmaY: GlassWrap.blurSigma,
          ),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x1FFFFFFF), Color(0x0DFFFFFF)],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: wave),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontal carousel of the queue's covers. The current word's card is
/// full size; its neighbours peek in at the edges, slightly shorter.
/// A swipe that settles on another card plays that word.
class PlayerCoverCarousel extends StatefulWidget {
  const PlayerCoverCarousel({
    super.key,
    required this.words,
    required this.index,
    required this.coverFor,
    required this.width,
    required this.card,
    required this.onSelect,
    this.overlay,
  });

  final List<Word> words;
  final int index;
  final PlayerCoverFor coverFor;
  final double width;

  /// Side of the current card.
  final double card;
  final ValueChanged<int> onSelect;

  /// Drawn over the current card only (chips, syllables, ritual caption).
  final Widget? overlay;

  @override
  State<PlayerCoverCarousel> createState() => _PlayerCoverCarouselState();
}

class _PlayerCoverCarouselState extends State<PlayerCoverCarousel> {
  PageController? _pages;
  double _fraction = 0;

  /// True while the player moves the carousel (next, prev, shuffle), so
  /// that move is not read as the reader picking a word.
  var _syncing = false;

  @override
  void didUpdateWidget(covariant PlayerCoverCarousel oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final fraction = ((card + 14) / widget.width).clamp(.3, 1.0);
    final pages = _controllerFor(fraction);
    return SizedBox(
      width: widget.width,
      height: card,
      child: PageView.builder(
        key: const ValueKey('player-cover-carousel'),
        controller: pages,
        itemCount: widget.words.length,
        padEnds: true,
        onPageChanged: (i) {
          if (_syncing || i == widget.index) return;
          // No buzz: haptics are for taps only.
          widget.onSelect(i);
        },
        itemBuilder: (context, i) {
          final w = widget.words[i];
          final current = i == widget.index;
          return AnimatedBuilder(
            animation: pages,
            builder: (context, child) {
              var page = widget.index.toDouble();
              if (pages.hasClients && pages.position.haveDimensions) {
                page = pages.page ?? page;
              }
              final d = (page - i).abs().clamp(0.0, 1.0);
              return Opacity(
                opacity: 1 - d * .3,
                child: Transform.scale(scale: 1 - d * .12, child: child),
              );
            },
            child: Center(
              child: PlayerCoverCard(
                key: ValueKey('player-cover-$i'),
                path: widget.coverFor(w, i),
                width: card,
                height: card,
                overlay: current ? widget.overlay : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlayerCoverCard extends StatelessWidget {
  const PlayerCoverCard({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    this.overlay,
  });
  final String path;
  final double width;
  final double height;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(24);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [
          BoxShadow(
              color: Color(0x8C000000), blurRadius: 26, offset: Offset(0, 14)),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF0B0F1A)),
            PlayerCoverImage(path: path),
            if (overlay != null) overlay!,
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: r,
                  border: Border.all(color: const Color(0x2EFFFFFF)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerCoverImage extends StatelessWidget {
  const PlayerCoverImage({super.key, required this.path});
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

/// Small frosted chip used on and around the cover (kit glass, white icon).
class PlayerGlassChip extends StatelessWidget {
  const PlayerGlassChip({
    super.key,
    required this.child,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.dark = true,
  });
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  /// Over a photo the chip needs a darker tint to stay readable.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final pane = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? const Color(0x99060C18) : GlassWrap.fill,
        borderRadius: r,
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      child: child,
    );
    // On the cover the chip is a dark frosted tint without a live blur:
    // a backdrop filter inside the carousel's moving cards smears the
    // photo past the card's rounded corners.
    if (dark) return pane;
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: GlassWrap.blurSigma,
          sigmaY: GlassWrap.blurSigma,
        ),
        child: pane,
      ),
    );
  }
}

/// A square glass button with a white icon (no circles).
class PlayerGlassSquare extends StatelessWidget {
  const PlayerGlassSquare({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 40,
    this.iconSize = 19,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => playerTap(onTap),
          child: SizedBox(
            width: size,
            height: size,
            child: PlayerGlassChip(
              dark: false,
              radius: 12,
              padding: EdgeInsets.zero,
              child: Center(
                  child: Icon(icon, color: Colors.white, size: iconSize)),
            ),
          ),
        ),
      );
}

/// The thin seek line: a filled part and no knob, elapsed time left and
/// total time right. [t] is 0..1.
class PlayerSeekLine extends StatelessWidget {
  const PlayerSeekLine({
    super.key,
    required this.t,
    required this.elapsed,
    required this.total,
  });
  final double t;
  final String elapsed;
  final String total;

  @override
  Widget build(BuildContext context) {
    const time = TextStyle(color: Color(0xB3FFFFFF), fontSize: 11, height: 1.1);
    return SizedBox(
      height: 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0x29FFFFFF)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: t.clamp(0.0, 1.0),
                    child: const ColoredBox(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(elapsed, key: const ValueKey('player-elapsed'), style: time),
              Text(total, key: const ValueKey('player-total'), style: time),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small previous / rounded-square play / small next.
class PlayerTransport extends StatelessWidget {
  const PlayerTransport({
    super.key,
    required this.playing,
    required this.onPrevious,
    required this.onPlay,
    required this.onNext,
    this.play = 56,
  });
  final bool playing;
  final VoidCallback onPrevious;
  final VoidCallback onPlay;
  final VoidCallback onNext;
  final double play;

  Widget _side(Key key, IconData icon, String label, VoidCallback onTap) =>
      Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          key: key,
          behavior: HitTestBehavior.opaque,
          onTap: () => playerTap(onTap),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: play + 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _side(const ValueKey('player-prev'), Icons.skip_previous_rounded,
              'Previous', onPrevious),
          SizedBox(width: play * .5),
          Semantics(
            button: true,
            label: playing ? 'Pause' : 'Play',
            child: GestureDetector(
              key: const ValueKey('player-play'),
              behavior: HitTestBehavior.opaque,
              onTap: () => playerTap(onPlay),
              child: Container(
                width: play,
                height: play,
                decoration: BoxDecoration(
                  color: const Color(0xF2FFFFFF),
                  borderRadius: BorderRadius.circular(play * 16 / 56),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 22,
                        offset: Offset(0, 10)),
                    BoxShadow(color: Color(0x33FFFFFF), blurRadius: 18),
                  ],
                ),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: NwsbColors.deep,
                  size: play * .54,
                ),
              ),
            ),
          ),
          SizedBox(width: play * .5),
          _side(const ValueKey('player-next'), Icons.skip_next_rounded, 'Next',
              onNext),
        ],
      ),
    );
  }
}

/// The dark glass bar at the foot of the pane: repeat, favourite, shuffle.
class PlayerGlassBar extends StatelessWidget {
  const PlayerGlassBar({
    super.key,
    required this.repeat,
    required this.liked,
    required this.shuffle,
    required this.onRepeat,
    required this.onLike,
    required this.onShuffle,
  });
  final bool repeat;
  final bool liked;
  final bool shuffle;
  final VoidCallback onRepeat;
  final VoidCallback onLike;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(24);
    return ClipRRect(
      key: const ValueKey('player-glass-bar'),
      borderRadius: r,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: GlassWrap.blurSigma,
          sigmaY: GlassWrap.blurSigma,
        ),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0x8C050912),
            borderRadius: r,
            border: Border.all(color: GlassWrap.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _BarIcon(
                key: const ValueKey('player-repeat'),
                icon: Icons.repeat_rounded,
                on: repeat,
                label: repeat ? 'Repeat on' : 'Repeat off',
                onTap: onRepeat,
              ),
              _BarIcon(
                key: const ValueKey('player-like'),
                icon: liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                on: liked,
                size: 25,
                label: liked ? 'Remove from favourites' : 'Add to favourites',
                onTap: onLike,
              ),
              _BarIcon(
                key: const ValueKey('player-shuffle'),
                icon: Icons.shuffle_rounded,
                on: shuffle,
                label: shuffle ? 'Shuffle on' : 'Shuffle off',
                onTap: onShuffle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    super.key,
    required this.icon,
    required this.on,
    required this.label,
    required this.onTap,
    this.size = 23,
  });
  final IconData icon;
  final bool on;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        toggled: on,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => playerTap(onTap),
          child: SizedBox(
            width: 64,
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: size,
                    color: on ? Colors.white : const Color(0x8CFFFFFF)),
                const SizedBox(height: 4),
                // A short bar under a control that is on (no dot, no circle).
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: on ? 14 : 0,
                  height: 2.5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
