/// The view a swipe up on the player opens.
///
/// Phones copy the right-hand player phone of Ribon's reference one-to-one,
/// measured on a 390 x 844 canvas: a band at the top, a big rounded panel
/// from y 99, the grab handle, a large cover card (279 x 313) with a wavy
/// top and bottom edge and the words before and after peeking in at the
/// panel's edges, the title and subtitle centred, a thin seek bar with the
/// times under it, previous / play / next, and a tab-shaped bar at the
/// bottom with repeat, heart and shuffle.
///
/// Landscape tablets copy the reference tablet: an "Up next" list on the
/// left (the Trending list) and the now-playing card on the right (cover,
/// title, waveform seek, repeat / prev / play / next / shuffle).
///
/// Only the material is NowssB's: the deep navy page, the HeroGlassRecipe
/// glass for the panel, a darker glass plate for the bar and the card, and
/// white where the reference uses purple.
///
/// The view owns no player state. Every value comes from the player and
/// every tap goes back to it.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/app_haptics.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/glass_wrap.dart';

typedef PlayerUpCover = String Function(Word word, int index);

/// The darker glass the reference's dark-purple parts become.
const _plate = Color(0xA6050810);
const _muted = Color(0x8CFFFFFF);

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
    required this.durationSec,
    this.startedAt,
    this.secondsFor,
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

  /// Length of the current word and when its run began (for the seek bar).
  final double durationSec;
  final DateTime? startedAt;

  /// Length of any word in the queue (the Up next times on tablets).
  final double Function(Word word)? secondsFor;

  final VoidCallback onClose;
  final VoidCallback onTogglePlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// A swipe on the carousel (or a tap on an Up next row) picked word [index].
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

  /// True while a pull down past the top of Up next is moving the view.
  var _listPulled = false;

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

  /// Haptics on taps only.
  void _tap(VoidCallback action) {
    AppHaptics.selection();
    action();
  }

  Word get _word => widget.words[widget.index.clamp(0, widget.words.length - 1)];

  String get _title {
    final t = _word.word.trim();
    return t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
  }

  String _subFor(Word w) {
    // The word's line, like the reference's artist line: what it works on.
    final organ = w.organ.trim();
    if (organ.isNotEmpty) {
      final o = organ.toLowerCase();
      return '${o[0].toUpperCase()}${o.substring(1)}';
    }
    final deva = w.deva.trim();
    if (deva.isNotEmpty) return deva;
    final mix = widget.mixTitle.trim();
    return mix.isEmpty ? 'NowssB' : mix;
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.coverFor(_word, widget.index);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (d) => widget.onDragUpdate(d.delta.dy),
      onVerticalDragEnd: (d) => widget.onDragEnd(d.primaryVelocity ?? 0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: NwsbColors.deep),
          // The current cover, blurred, under deep navy: the page colour.
          Opacity(
            opacity: .5,
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
                colors: [Color(0x80060C18), Color(0xBF060C18), Color(0xE6040810)],
                stops: [0, .5, 1],
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 700 && box.maxWidth > box.maxHeight;
              return wide ? _wide(context, box) : _phone(context, box);
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── Phone ─────────────────────────────

  Widget _phone(BuildContext context, BoxConstraints box) {
    final pad = MediaQuery.paddingOf(context);
    final W = box.maxWidth;
    final H = box.maxHeight;
    // The reference measured on a 390 x 844 canvas. y() maps its heights,
    // u scales sizes so nothing outgrows its slot.
    final v = math.max(.5, (H - pad.top - pad.bottom) / 844);
    final u = math.min(W / 390, v);
    double y(double d) => pad.top + d * v;

    const side = 8.0;
    final sheetTop = y(99);
    final sheetW = W - side * 2;
    double sy(double d) => y(d) - sheetTop; // sheet-local y
    final cx = sheetW / 2;

    final cardW = 279 * u;
    final cardH = 313 * u;
    final barTop = sy(762);
    final barH = H - y(762);

    return Stack(
      children: [
        // The band above the panel: close, what is playing, queue.
        Positioned(
          left: 16,
          right: 16,
          top: y(52) - 21,
          height: 42,
          child: Row(
            children: [
              _GlassSquare(
                key: const ValueKey('player-up-close'),
                icon: Icons.keyboard_arrow_down_rounded,
                label: 'Close',
                onTap: () => _tap(widget.onClose),
              ),
              Expanded(child: _nowPlayingLabel()),
              _GlassSquare(
                key: const ValueKey('player-up-queue'),
                icon: Icons.queue_music_rounded,
                label: 'Queue',
                onTap: () => _tap(widget.onQueue),
              ),
            ],
          ),
        ),
        // The panel.
        Positioned(
          left: side,
          right: side,
          top: sheetTop,
          bottom: 0,
          child: ClipPath(
            clipper: const _SheetClip(),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: GlassWrap.blurSigma,
                sigmaY: GlassWrap.blurSigma,
              ),
              child: CustomPaint(
                painter: const _SheetPaint(),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Grab handle (tap or drag down to close).
                    Positioned(
                      left: cx - 60,
                      top: sy(115) - 11,
                      width: 120,
                      height: 22,
                      child: GestureDetector(
                        key: const ValueKey('player-up-handle'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _tap(widget.onClose),
                        child: Center(
                          child: Container(
                            width: 33 * u,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0x59FFFFFF),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Cover carousel, neighbours peeking at the panel edges.
                    Positioned(
                      left: -side,
                      width: W,
                      top: sy(161) + (313 * v - cardH) / 2,
                      height: cardH,
                      child: _carousel(
                        width: W,
                        cardW: cardW,
                        cardH: cardH,
                        gap: 3 * u,
                        neighbourScale: .84,
                        wave: true,
                      ),
                    ),
                    // Title and subtitle.
                    Positioned(
                      left: 24,
                      right: 24,
                      top: sy(522) - 16 * u,
                      height: 32 * u,
                      child: _titleText(22 * u),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      top: sy(557) - 11 * u,
                      height: 22 * u,
                      child: _subText(15 * u),
                    ),
                    // Seek bar and times.
                    Positioned(
                      left: cx - cardW / 2,
                      width: cardW,
                      top: sy(608) - 4 * u,
                      height: 44 * u,
                      child: _UpSeek(
                        key: ValueKey('player-up-seek-${widget.index}'),
                        playing: widget.playing,
                        durationSec: widget.durationSec,
                        startedAt: widget.startedAt,
                        wave: false,
                        scale: u,
                      ),
                    ),
                    // Previous / play / next.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: sy(688) - 40 * u,
                      height: 80 * u,
                      child: _transport(
                        play: 70 * u,
                        icon: 28 * u,
                        spread: 80 * u,
                      ),
                    ),
                    // The tab-shaped bar.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: barTop,
                      height: barH,
                      child: _phoneBar(u, pad.bottom),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _nowPlayingLabel() {
    final mix = widget.mixTitle.trim().isEmpty ? 'NowssB' : widget.mixTitle.trim();
    return Column(
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
              mix,
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
    );
  }

  Widget _phoneBar(double u, double bottomPad) {
    return ClipPath(
      clipper: const _TabClip(),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: CustomPaint(
          painter: const _TabPaint(),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: LayoutBuilder(
              builder: (context, b) {
                // Icons at 26%, 51% and 77% across, 60% down the bar.
                final w = b.maxWidth;
                final iy = (b.maxHeight) * .56;
                Widget at(double fx, Widget child) => Positioned(
                      left: w * fx - 26,
                      top: iy - 26,
                      width: 52,
                      height: 52,
                      child: child,
                    );
                return Stack(
                  children: [
                    at(.26, _repeatBtn(23 * u)),
                    at(.505, _likeBtn(25 * u)),
                    at(.77, _shuffleBtn(23 * u)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── Tablet ─────────────────────────────

  Widget _wide(BuildContext context, BoxConstraints box) {
    final pad = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.only(top: pad.top, bottom: pad.bottom),
      child: Column(
        children: [
          // Handle and the band: close, what is playing, queue.
          GestureDetector(
            key: const ValueKey('player-up-handle'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tap(widget.onClose),
            child: SizedBox(
              height: 22,
              width: 120,
              child: Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0x66FFFFFF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  _GlassSquare(
                    key: const ValueKey('player-up-close'),
                    icon: Icons.keyboard_arrow_down_rounded,
                    label: 'Close',
                    onTap: () => _tap(widget.onClose),
                  ),
                  Expanded(child: _nowPlayingLabel()),
                  _GlassSquare(
                    key: const ValueKey('player-up-queue'),
                    icon: Icons.queue_music_rounded,
                    label: 'Queue',
                    onTap: () => _tap(widget.onQueue),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, b) {
                const m = 24.0;
                final availH = b.maxHeight - m * 1.5;
                // The reference card is 117 x 155 (h = 1.32 w).
                final cw = math.min(math.min(460.0, availH / 1.32), b.maxWidth * .44);
                final ch = cw * 1.32;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(m, m / 2, m, m),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _upNextPane()),
                      const SizedBox(width: m),
                      SizedBox(width: cw, height: ch, child: _nowCard(cw, ch)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// The reference tablet's Trending list, as Up next.
  Widget _upNextPane() {
    final words = widget.words;
    return GlassWrap(
      margin: EdgeInsets.zero,
      radius: 26,
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Up next',
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                    ),
                  ),
                ),
                GestureDetector(
                  key: const ValueKey('player-up-see-all'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _tap(widget.onQueue),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'See more',
                      style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            // Pulling down past the top of the list moves the view down, so
            // a swipe down closes it here too.
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is OverscrollNotification &&
                    n.dragDetails != null &&
                    n.overscroll < 0) {
                  _listPulled = true;
                  widget.onDragUpdate(-n.overscroll);
                } else if (n is ScrollUpdateNotification &&
                    _listPulled &&
                    n.dragDetails != null) {
                  widget.onDragUpdate(-(n.scrollDelta ?? 0));
                } else if (n is ScrollEndNotification && _listPulled) {
                  _listPulled = false;
                  widget.onDragEnd(n.dragDetails?.primaryVelocity ?? 0);
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                physics: const ClampingScrollPhysics(),
                itemCount: words.length,
                itemBuilder: (context, i) => _upNextRow(i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _upNextRow(int i) {
    final w = widget.words[i];
    final current = i == widget.index;
    final t = w.word.trim();
    final title = t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
    final secs = i == widget.index ? widget.durationSec : widget.secondsFor?.call(w);
    return GestureDetector(
      key: ValueKey('player-up-row-$i'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _tap(current ? widget.onTogglePlay : () => widget.onSelect(i)),
      child: Container(
        height: 64,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: current ? const Color(0x1AFFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                (i + 1).toString().padLeft(2, '0'),
                style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44,
                height: 44,
                child: _Cover(path: widget.coverFor(w, i)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subFor(w),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (secs != null)
              Text(
                _clock(secs),
                style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            const SizedBox(width: 14),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                current && widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 18,
                color: NwsbColors.deep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The reference tablet's now-playing card, measured on its 117 x 155.
  Widget _nowCard(double w, double h) {
    final inset = w * .077;
    final imgH = h * .38;
    final r = BorderRadius.circular(w * .075);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [
          BoxShadow(color: Color(0x73000000), blurRadius: 40, offset: Offset(0, 18)),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _plate,
              borderRadius: r,
              border: Border.all(color: GlassWrap.line),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: inset,
                  right: inset,
                  top: inset,
                  height: imgH,
                  child: _carousel(
                    width: w - inset * 2,
                    cardW: w - inset * 2,
                    cardH: imgH,
                    gap: 0,
                    neighbourScale: 1,
                    wave: false,
                    radius: w * .055,
                  ),
                ),
                // Heart in a white badge on the cover.
                Positioned(
                  right: inset + 8,
                  top: inset + 8,
                  child: _likeBadge(),
                ),
                Positioned(
                  left: inset,
                  right: inset,
                  top: h * .505 - w * .04,
                  height: w * .08,
                  child: _titleText(w * .058),
                ),
                Positioned(
                  left: inset,
                  right: inset,
                  top: h * .567 - w * .028,
                  height: w * .056,
                  child: _subText(w * .036),
                ),
                Positioned(
                  left: inset,
                  right: inset,
                  top: h * .69 - h * .05,
                  height: h * .1,
                  child: _UpSeek(
                    key: ValueKey('player-up-seek-${widget.index}'),
                    playing: widget.playing,
                    durationSec: widget.durationSec,
                    startedAt: widget.startedAt,
                    wave: true,
                    scale: w / 420,
                    seed: _word.word,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: h * .855 - w * .1,
                  height: w * .2,
                  child: LayoutBuilder(
                    builder: (context, b) {
                      final play = w * .16;
                      Widget at(double fx, double size, Widget child) => Positioned(
                            left: b.maxWidth * fx - size / 2,
                            top: (b.maxHeight - size) / 2,
                            width: size,
                            height: size,
                            child: child,
                          );
                      final hit = math.max(48.0, w * .12);
                      return Stack(
                        children: [
                          at(.11, hit, _repeatBtn(w * .055)),
                          at(.33, hit, _prevBtn(w * .07)),
                          at(.5, play, _playBtn(play)),
                          at(.67, hit, _nextBtn(w * .07)),
                          at(.89, hit, _shuffleBtn(w * .055)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── Shared parts ─────────────────────────────

  Widget _carousel({
    required double width,
    required double cardW,
    required double cardH,
    required double gap,
    required double neighbourScale,
    required bool wave,
    double? radius,
  }) {
    final fraction = ((cardW + gap) / width).clamp(.2, 1.0);
    final pages = _controllerFor(fraction);
    return SizedBox(
      height: cardH,
      width: width,
      child: PageView.builder(
        key: const ValueKey('player-up-carousel'),
        controller: pages,
        itemCount: widget.words.length,
        padEnds: true,
        onPageChanged: (i) {
          if (_syncing || i == widget.index) return;
          // A swipe that settles on a word plays it. No buzz: haptics are
          // for taps only.
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
              return Transform.scale(
                scale: 1 - d * (1 - neighbourScale),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: i == widget.index ? () => _tap(widget.onTogglePlay) : null,
              child: Center(
                child: _CoverCard(
                  key: ValueKey('player-up-cover-$i'),
                  path: widget.coverFor(w, i),
                  width: cardW,
                  height: cardH,
                  wave: wave,
                  radius: radius ?? cardW * .075,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titleText(double size) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _title,
            key: const ValueKey('player-up-title'),
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: size,
              fontWeight: FontWeight.w700,
              letterSpacing: -.2,
              height: 1.2,
            ),
          ),
        ),
      );

  Widget _subText(double size) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _subFor(_word),
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: size,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ),
      );

  Widget _transport({required double play, required double icon, required double spread}) {
    return LayoutBuilder(
      builder: (context, b) {
        final cx = b.maxWidth / 2;
        final cy = b.maxHeight / 2;
        const hit = 52.0;
        return Stack(
          children: [
            Positioned(
              left: cx - spread - hit / 2,
              top: cy - hit / 2,
              width: hit,
              height: hit,
              child: _prevBtn(icon),
            ),
            Positioned(
              left: cx - play / 2,
              top: cy - play / 2,
              width: play,
              height: play,
              child: _playBtn(play),
            ),
            Positioned(
              left: cx + spread - hit / 2,
              top: cy - hit / 2,
              width: hit,
              height: hit,
              child: _nextBtn(icon),
            ),
          ],
        );
      },
    );
  }

  Widget _prevBtn(double size) => _IconTap(
        key: const ValueKey('player-up-prev'),
        icon: Icons.skip_previous_rounded,
        size: size,
        label: 'Previous',
        onTap: () => _tap(widget.onPrevious),
      );

  Widget _nextBtn(double size) => _IconTap(
        key: const ValueKey('player-up-next'),
        icon: Icons.skip_next_rounded,
        size: size,
        label: 'Next',
        onTap: () => _tap(widget.onNext),
      );

  /// The white play / pause key: a rounded square with soft corners.
  Widget _playBtn(double size) => Semantics(
        button: true,
        label: widget.playing ? 'Pause' : 'Play',
        child: GestureDetector(
          key: const ValueKey('player-up-play'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _tap(widget.onTogglePlay),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * .34),
              boxShadow: const [
                BoxShadow(color: Color(0x33FFFFFF), blurRadius: 24, spreadRadius: -4),
              ],
            ),
            child: Icon(
              widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: NwsbColors.deep,
              size: size * .46,
            ),
          ),
        ),
      );

  Widget _repeatBtn(double size) => _IconTap(
        key: const ValueKey('player-up-repeat'),
        icon: Icons.repeat_rounded,
        size: size,
        on: widget.repeat,
        label: widget.repeat ? 'Repeat on' : 'Repeat off',
        onTap: () => _tap(widget.onRepeat),
      );

  Widget _shuffleBtn(double size) => _IconTap(
        key: const ValueKey('player-up-shuffle'),
        icon: Icons.shuffle_rounded,
        size: size,
        on: widget.shuffle,
        label: widget.shuffle ? 'Shuffle on' : 'Shuffle off',
        onTap: () => _tap(widget.onShuffle),
      );

  Widget _likeBtn(double size) => _IconTap(
        key: const ValueKey('player-up-like'),
        icon: widget.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: size,
        on: widget.liked,
        label: widget.liked ? 'Remove from favourites' : 'Add to favourites',
        onTap: () => _tap(widget.onLike),
      );

  /// Heart in a white circle badge (the tablet card).
  Widget _likeBadge() => Semantics(
        button: true,
        toggled: widget.liked,
        label: widget.liked ? 'Remove from favourites' : 'Add to favourites',
        child: GestureDetector(
          key: const ValueKey('player-up-like'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _tap(widget.onLike),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Icon(
              widget.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 21,
              color: NwsbColors.deep,
            ),
          ),
        ),
      );
}

String _clock(double secs) {
  final s = secs.isFinite ? secs.round().clamp(0, 5999) : 0;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// The seek: a thin bar with the times under it (phone) or a waveform with
/// the times either side (tablet card). Runs from the player's own start
/// time and length, like the player's bar.
class _UpSeek extends StatefulWidget {
  const _UpSeek({
    super.key,
    required this.playing,
    required this.durationSec,
    required this.startedAt,
    required this.wave,
    required this.scale,
    this.seed = '',
  });
  final bool playing;
  final double durationSec;
  final DateTime? startedAt;
  final bool wave;
  final double scale;
  final String seed;

  @override
  State<_UpSeek> createState() => _UpSeekState();
}

class _UpSeekState extends State<_UpSeek> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  Duration get _len => Duration(
        milliseconds: (widget.durationSec * 1000).round().clamp(400, 120000),
      );

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _len);
    final began = widget.startedAt;
    if (widget.playing && began != null && widget.durationSec > 0) {
      final secs = DateTime.now().difference(began).inMilliseconds / 1000;
      _c.value = (secs / widget.durationSec).clamp(0.0, 1.0);
    }
    if (widget.playing) _c.forward();
  }

  @override
  void didUpdateWidget(covariant _UpSeek oldWidget) {
    super.didUpdateWidget(oldWidget);
    _c.duration = _len;
    if (widget.playing && !oldWidget.playing) {
      _c.forward(from: 0);
    } else if (!widget.playing && oldWidget.playing) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.scale;
    final timeStyle = TextStyle(
      color: _muted,
      fontSize: 13 * u,
      fontWeight: FontWeight.w500,
      fontFeatures: const [ui.FontFeature.tabularFigures()],
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value.clamp(0.0, 1.0);
        final total = widget.durationSec;
        final now = Text(_clock(t * total), style: timeStyle);
        final end = Text(_clock(total), style: timeStyle);
        if (widget.wave) {
          return Row(
            children: [
              now,
              SizedBox(width: 14 * u),
              Expanded(
                child: CustomPaint(
                  painter: _WavePaint(t: t, seed: widget.seed),
                  child: const SizedBox.expand(),
                ),
              ),
              SizedBox(width: 14 * u),
              end,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 7 * u,
              child: LayoutBuilder(
                builder: (context, b) => Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0x2EFFFFFF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: b.maxWidth * t,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12 * u),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [now, end],
            ),
          ],
        );
      },
    );
  }
}

class _WavePaint extends CustomPainter {
  _WavePaint({required this.t, required this.seed});
  final double t;
  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 34;
    final step = size.width / n;
    final bw = math.max(1.5, step * .45);
    final rnd = math.Random(seed.hashCode);
    final on = Paint()..color = Colors.white;
    final off = Paint()..color = const Color(0x40FFFFFF);
    for (var i = 0; i < n; i++) {
      final shape = .35 + .65 * math.sin(math.pi * (i + .5) / n);
      final h = size.height * (.25 + .75 * rnd.nextDouble()) * shape;
      final x = i * step + (step - bw) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - h) / 2, bw, h),
        Radius.circular(bw / 2),
      );
      canvas.drawRRect(rect, (i + .5) / n <= t ? on : off);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePaint old) => old.t != t || old.seed != seed;
}

/// The panel: rounded top corners (37 on the 390 canvas), straight down.
class _SheetClip extends CustomClipper<Path> {
  const _SheetClip();
  static Path shape(Size s) => Path()
    ..addRRect(RRect.fromRectAndCorners(
      Offset.zero & s,
      topLeft: const Radius.circular(36),
      topRight: const Radius.circular(36),
    ));
  @override
  Path getClip(Size size) => shape(size);
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SheetPaint extends CustomPainter {
  const _SheetPaint();
  @override
  void paint(Canvas canvas, Size size) {
    final p = _SheetClip.shape(size);
    canvas.drawPath(p, Paint()..color = GlassWrap.fill);
    // A soft lift at the top of the glass, like the reference's white.
    canvas.drawPath(
      p,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)],
        ).createShader(Offset.zero & Size(size.width, 220)),
    );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = GlassWrap.line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The bottom bar: narrower at the top with rounded shoulders, flaring out
/// to the panel's edges at the bottom (the reference's tab shape).
class _TabClip extends CustomClipper<Path> {
  const _TabClip();
  static Path shape(Size s) {
    final w = s.width;
    final h = s.height;
    // Top inset 21 / bottom inset 6 on the 374-wide panel.
    final top = w * .056;
    final bot = w * .016;
    const r = 24.0;
    return Path()
      ..moveTo(bot, h)
      ..cubicTo(top - 2, h * .55, top - 4, r * .4, top + r * .2, r * .45)
      ..quadraticBezierTo(top + r * .5, 0, top + r * 1.3, 0)
      ..lineTo(w - top - r * 1.3, 0)
      ..quadraticBezierTo(w - top - r * .5, 0, w - top - r * .2, r * .45)
      ..cubicTo(w - top + 4, r * .4, w - top + 2, h * .55, w - bot, h)
      ..close();
  }

  @override
  Path getClip(Size size) => shape(size);
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TabPaint extends CustomPainter {
  const _TabPaint();
  @override
  void paint(Canvas canvas, Size size) {
    final p = _TabClip.shape(size);
    canvas.drawPath(p, Paint()..color = _plate);
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = GlassWrap.line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        child: Center(
          child: Icon(icon, size: size, color: lit ? Colors.white : const Color(0xA6FFFFFF)),
        ),
      ),
    );
  }
}

/// A small glass button with rounded corners (the kit glass).
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

/// The cover card. Phones: the reference's wavy top and bottom edge.
class _CoverCard extends StatelessWidget {
  const _CoverCard({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    required this.wave,
    required this.radius,
  });
  final String path;
  final double width;
  final double height;
  final bool wave;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final clip = _CardClip(wave: wave, radius: radius);
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _CardShadow(clip),
        child: ClipPath(
          clipper: clip,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF0B0F1A)),
              _Cover(path: path),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardClip extends CustomClipper<Path> {
  const _CardClip({required this.wave, required this.radius});
  final bool wave;
  final double radius;

  Path shape(Size s) {
    final w = s.width;
    final h = s.height;
    final r = radius;
    if (!wave) {
      return Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(r)));
    }
    // Top: starts 3% down at the left, dips at 30%, rises to the top at
    // 75%. Bottom: rises 5% at 55%, back down at the right.
    final a = h * .03;
    return Path()
      ..moveTo(0, a + r)
      ..quadraticBezierTo(0, a, r, a)
      ..cubicTo(w * .3, a + h * .03, w * .5, h * .005, w * .78, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..cubicTo(w * .7, h, w * .6, h - h * .055, w * .42, h - h * .045)
      ..cubicTo(w * .25, h - h * .035, w * .12, h, r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..close();
  }

  @override
  Path getClip(Size size) => shape(size);
  @override
  bool shouldReclip(covariant _CardClip old) => old.wave != wave || old.radius != radius;
}

class _CardShadow extends CustomPainter {
  _CardShadow(this.clip);
  final _CardClip clip;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      clip.shape(size).shift(const Offset(0, 14)),
      Paint()
        ..color = const Color(0x80000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(covariant _CardShadow old) => false;
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
