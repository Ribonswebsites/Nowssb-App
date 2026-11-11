/// Sound Library glass layouts — three reusable presentations for the
/// sections that used to repeat one thumbnail-row / one card-rail layout.
///
///  * [GlassQuickGrid]      Spotify home: 2-column compact rows (square
///                          thumbnail + title), optional filter chips.
///  * [GlassNowPlayingGrid] Spotify widget: now-playing header (artwork,
///                          title, progress, round play/pause) over a 4-column
///                          grid of square tiles. Wired to [PlaybackSession].
///  * [GlassStationRow]     Spotify station cards: tinted glass plate, cut-out
///                          circular avatars, bold title, two-line subtitle.
///
/// All of them sit in [GlassSection] ([GlassWrap] — the HeroGlassRecipe
/// material) and use the [HomeText] sans styles. Only one BackdropFilter per
/// section: the cells inside are plain translucent fills so scrolling stays
/// smooth. Nothing here filters items away by default: every pick that goes
/// in is shown (the quick grid pages through them, the tile grid grows).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../admin/template/editable.dart';
import '../data/models.dart';
import '../data/playback_session.dart';
import 'glass_wrap.dart';
import 'hero_glass.dart';
import 'home_text.dart';

/// What the layouts need from the player: the live session, if any, and a
/// play / pause switch. [SessionPlayer] is the app's real [PlaybackSession];
/// tests hand in a fake.
abstract class SlPlayer implements Listenable {
  /// True while a session exists (playing or paused).
  bool get active;
  bool get playing;
  Word? get word;
  Future<void> toggle();
}

/// A [SlPlayer] that can also skip. The big Currently Playing hero needs
/// previous / next; the smaller layouts only ever toggle.
abstract class SlTransport implements SlPlayer {
  Future<void> next();
  Future<void> previous();
}

class SessionPlayer implements SlTransport {
  SessionPlayer([PlaybackSession? session])
      : _s = session ?? PlaybackSession.instance;
  final PlaybackSession _s;

  @override
  bool get active => _s.active;
  @override
  bool get playing => _s.playing;
  @override
  Word? get word => _s.word;
  @override
  Future<void> toggle() => _s.togglePlay();
  @override
  Future<void> next() => _s.next();
  @override
  Future<void> previous() => _s.previous();
  @override
  void addListener(VoidCallback listener) => _s.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => _s.removeListener(listener);
}

/// One playable item as the glass layouts show it.
class SlPick {
  const SlPick({required this.word, required this.art, this.subtitle = ''});
  final Word word;

  /// Asset path (or http url) of the picture.
  final String art;
  final String subtitle;
}

/// One station card: a category / collection that opens a page.
class SlStation {
  const SlStation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.avatars,
    required this.onTap,
    this.onLongPress,
    this.accent,
  });
  final String id;
  final String title;
  final String subtitle;
  final List<String> avatars;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color? accent;
}

/// Calm, meditation-only pictures with no text, used to give every glass tile
/// its own image. [tiles] are seated / standing figures on a colour plate or
/// in a quiet room (square tiles, whole figure in frame); [avatars] are
/// centred objects (lotus, candle, stones, bowls) that crop cleanly to a
/// circle. Red-haired and Cleopatra figures are deliberately not in here.
abstract final class SoundArtPool {
  static const List<String> tiles = [
    'assets/login/card-05.jpg',
    'assets/meditation/meditation-morning.webp',
    'assets/login/card-12.jpg',
    'assets/home/ref/ref-3.webp',
    'assets/login/card-17.jpg',
    'assets/meditation/meditation-evening.webp',
    'assets/login/card-08.jpg',
    'assets/home/hc/hc-b-breath.webp',
    'assets/login/card-14.jpg',
    'assets/home/ref/ref-1.webp',
    'assets/login/card-01.jpg',
    'assets/meditation/meditation-seated.webp',
    'assets/login/card-19.jpg',
    'assets/home/ref/ref-4.webp',
    'assets/login/card-06.jpg',
    'assets/home/ez/ez-med-lotus-white.webp',
    'assets/login/card-15.jpg',
    'assets/home/ref/ref-7.webp',
    'assets/login/card-10.jpg',
    'assets/home/hc/hc-c-word.webp',
    'assets/login/card-18.jpg',
    'assets/home/ref/ref-9.webp',
    'assets/login/card-07.jpg',
    'assets/home/hc/hc-d-breath.webp',
    'assets/login/card-11.jpg',
    'assets/login/card-16.jpg',
    'assets/home/ez/ez-med-beach.webp',
    'assets/home/hc/hc-f-heal.webp',
  ];

  static const List<String> avatars = [
    'assets/meditation/meditation-lotus.webp',
    'assets/home/hour-ananda.webp',
    'assets/meditation/meditation-candle.webp',
    'assets/home/hour-chandra.webp',
    'assets/meditation/meditation-stone-stack.webp',
    'assets/home/hour-kapha.webp',
    'assets/meditation/meditation-singing-bowl.webp',
    'assets/home/hour-surya.webp',
    'assets/meditation/meditation-stones-wave.webp',
    'assets/home/hour-shakti.webp',
    'assets/meditation/meditation-bowls-pair.webp',
    'assets/home/hour-soma.webp',
    'assets/meditation/meditation-cairn.webp',
    'assets/home/hour-ojas.webp',
    'assets/home/ez/ez-med-candle.webp',
    'assets/home/hour-prana.webp',
    'assets/home/hc/rs-candle.webp',
    'assets/home/hour-vata.webp',
    'assets/home/ref/ref-6.webp',
    'assets/home/hour-pitta.webp',
    'assets/home/hc/hc-e-word.webp',
    'assets/home/hour-aarogya.webp',
    'assets/home/hour-tejas.webp',
  ];
}

/// Hands each seed (a word, a category…) its own picture, once per page.
class SoundArtLedger {
  final Map<String, String> _bySeed = {};
  final Set<String> _used = {};

  static int _hash(String s) {
    var h = 0;
    for (final cu in s.codeUnits) {
      h = (h * 31 + cu) & 0x7fffffff;
    }
    return h;
  }

  /// The picture for [seed]. [preferred] (the word's own admin-set art) wins
  /// when it is still unused. [avatar] draws from the circle-safe pool.
  String pick(String seed, {String preferred = '', bool avatar = false}) {
    final known = _bySeed[seed];
    if (known != null) return known;
    String? chosen;
    if (preferred.isNotEmpty && !_used.contains(preferred)) {
      chosen = preferred;
    } else {
      final pool = avatar ? SoundArtPool.avatars : SoundArtPool.tiles;
      final start = (_hash(seed) * 40503) % pool.length;
      for (var k = 0; k < pool.length; k++) {
        final c = pool[(start + k) % pool.length];
        if (!_used.contains(c)) {
          chosen = c;
          break;
        }
      }
      chosen ??= pool[(_hash(seed) * 40503) % pool.length];
    }
    _used.add(chosen);
    _bySeed[seed] = chosen;
    return chosen;
  }
}

/// A picture from an asset path or an http url, covering its box.
class SlImage extends StatelessWidget {
  const SlImage(this.src,
      {super.key, this.word, this.alignment = const Alignment(0, -0.75)});
  final String src;
  final String? word;

  /// Biased to the top so a portrait picture never loses the head to the
  /// square crop (landscape and square pictures are unaffected).
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(color: Color(0xFF1A1A1E));
    if (src.isEmpty) return fallback;
    if (src.startsWith('http')) {
      return Image.network(src,
          fit: BoxFit.cover,
          alignment: alignment,
          errorBuilder: (_, __, ___) => fallback);
    }
    return EditableImage.asset(
      src,
      fit: BoxFit.cover,
      alignment: alignment,
      word: word,
      slot: 'sound_library.SlmFeed',
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// The glass pane every new layout sits in: [GlassWrap] with a [HomeText]
/// heading and subline, and an optional trailing pill.
class GlassSection extends StatelessWidget {
  const GlassSection({
    super.key,
    required this.title,
    this.subline,
    this.trailing,
    required this.child,
    this.slot = 'sound_library.SlmFeed',
  });

  final String title;
  final String? subline;
  final Widget? trailing;
  final Widget child;
  final String slot;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GlassWrap(
        margin: const EdgeInsets.fromLTRB(12, 14, 12, 6),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EditableLabel(
                        slot,
                        title,
                        style: HomeText.heading.copyWith(fontSize: 22),
                      ),
                      if (subline != null) ...[
                        const SizedBox(height: 3),
                        EditableLabel(slot, subline!, style: HomeText.subline),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// Glass pill used for "Play all" and the filter chips.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0x24FFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? Colors.white : const Color(0x40FFFFFF)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF111118) : Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── (A) Quick grid ──────────────────────────────────────────────────────────

class GlassQuickGrid extends StatefulWidget {
  const GlassQuickGrid({
    super.key,
    required this.picks,
    required this.onPlay,
    this.onOpen,
    this.chips = const [],
    this.matches,
    this.trailingFor,
    this.emptyLabel = 'Nothing here yet.',
    this.player,
  });

  final List<SlPick> picks;
  final ValueChanged<Word> onPlay;

  /// Long-press: open the word's page.
  final ValueChanged<Word>? onOpen;

  /// Optional filter chips (the first is the "show everything" one).
  final List<String> chips;
  final bool Function(String chip, SlPick pick)? matches;
  final Widget Function(SlPick pick)? trailingFor;
  final String emptyLabel;
  final SlPlayer? player;

  static const int rowsPerPage = 4;
  static const int perPage = rowsPerPage * 2;

  @override
  State<GlassQuickGrid> createState() => _GlassQuickGridState();
}

class _GlassQuickGridState extends State<GlassQuickGrid> {
  String _chip = '';
  int _page = 0;

  List<SlPick> get _shown {
    if (_chip.isEmpty || widget.matches == null) return widget.picks;
    return widget.picks.where((p) => widget.matches!(_chip, p)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final pages = <List<SlPick>>[];
    for (var i = 0; i < shown.length; i += GlassQuickGrid.perPage) {
      pages.add(shown.sublist(
          i,
          i + GlassQuickGrid.perPage > shown.length
              ? shown.length
              : i + GlassQuickGrid.perPage));
    }
    const rowH = 56.0;
    const gap = 8.0;
    const gridH = GlassQuickGrid.rowsPerPage * rowH +
        (GlassQuickGrid.rowsPerPage - 1) * gap;
    final player = widget.player ?? SessionPlayer();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in widget.chips) ...[
                    GlassPill(
                      key: ValueKey('sl-chip-$c'),
                      label: c,
                      selected: (_chip.isEmpty ? widget.chips.first : _chip) == c,
                      onTap: () => setState(() {
                        _chip = c == widget.chips.first ? '' : c;
                        _page = 0;
                      }),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        SizedBox(
          height: gridH,
          child: pages.isEmpty
              ? Center(
                  child: Text(widget.emptyLabel, style: HomeText.subline))
              : ListenableBuilder(
                  listenable: player,
                  builder: (context, _) {
                    final live = player.active ? player.word?.word : null;
                    return PageView.builder(
                      key: ValueKey('sl-quick-pages-$_chip'),
                      itemCount: pages.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, pi) {
                        final p = pages[pi];
                        return Column(
                          children: [
                            for (var r = 0;
                                r < GlassQuickGrid.rowsPerPage;
                                r++) ...[
                              if (r > 0) const SizedBox(height: gap),
                              SizedBox(
                                height: rowH,
                                child: Row(
                                  children: [
                                    for (var c = 0; c < 2; c++) ...[
                                      if (c > 0) const SizedBox(width: gap),
                                      Expanded(
                                        child: r * 2 + c < p.length
                                            ? _QuickCell(
                                                pick: p[r * 2 + c],
                                                playing: live ==
                                                    p[r * 2 + c].word.word,
                                                onPlay: widget.onPlay,
                                                onOpen: widget.onOpen,
                                                trailing: widget.trailingFor
                                                    ?.call(p[r * 2 + c]),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
        if (pages.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? Colors.white
                          : const Color(0x59FFFFFF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuickCell extends StatelessWidget {
  const _QuickCell({
    required this.pick,
    required this.playing,
    required this.onPlay,
    this.onOpen,
    this.trailing,
  });
  final SlPick pick;
  final bool playing;
  final ValueChanged<Word> onPlay;
  final ValueChanged<Word>? onOpen;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(14);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('sl-quick-${pick.word.word}'),
        borderRadius: r,
        onTap: () => onPlay(pick.word),
        onLongPress: onOpen == null ? null : () => onOpen!(pick.word),
        child: Ink(
          decoration: BoxDecoration(
            color: HeroGlassRecipe.fill,
            borderRadius: r,
            border: Border.all(
                color: playing ? const Color(0xB3FFFFFF) : HeroGlassRecipe.line),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(13)),
                child: SizedBox(
                  width: 54,
                  height: double.infinity,
                  child: SlImage(pick.art, word: pick.word.word),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pick.word.word,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              if (playing)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.graphic_eq_rounded,
                      color: Colors.white, size: 18),
                ),
              if (trailing != null) trailing!,
              if (trailing == null && !playing) const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── (B) Now playing + tile grid ─────────────────────────────────────────────

class GlassNowPlayingGrid extends StatelessWidget {
  const GlassNowPlayingGrid({
    super.key,
    required this.picks,
    required this.onPlay,
    required this.headerArt,
    this.onOpen,
    this.lastPlayed,
    this.player,
  });

  /// Every item — each one becomes a tile (4 per row, as many rows as needed).
  final List<SlPick> picks;

  /// Open / start this word in the player.
  final ValueChanged<Word> onPlay;
  final ValueChanged<Word>? onOpen;

  /// Picture for the header (not one of the tile pictures).
  final String Function(Word w) headerArt;

  /// What to show when nothing is playing. Falls back to the first pick.
  final Word? lastPlayed;
  final SlPlayer? player;

  @override
  Widget build(BuildContext context) {
    final s = player ?? SessionPlayer();
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final live = s.active ? s.word : null;
        final shown = live ?? lastPlayed ?? (picks.isEmpty ? null : picks.first.word);
        final label = live != null
            ? (s.playing ? 'NOW PLAYING' : 'PAUSED')
            : (lastPlayed != null ? 'LAST PLAYED' : 'SUGGESTED FOR YOU');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shown != null)
              _NowPlayingHeader(
                word: shown,
                art: headerArt(shown),
                label: label,
                player: s,
                live: live != null,
                onPlay: onPlay,
                onOpen: onOpen,
              ),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, c) {
              const cols = 4;
              const gap = 8.0;
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final p in picks)
                    _GridTile(
                      size: w,
                      pick: p,
                      playing: live?.word == p.word.word,
                      onPlay: onPlay,
                      onOpen: onOpen,
                    ),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}

class _NowPlayingHeader extends StatefulWidget {
  const _NowPlayingHeader({
    required this.word,
    required this.art,
    required this.label,
    required this.player,
    required this.live,
    required this.onPlay,
    this.onOpen,
  });
  final Word word;
  final String art;
  final String label;
  final SlPlayer player;
  final bool live;
  final ValueChanged<Word> onPlay;
  final ValueChanged<Word>? onOpen;

  @override
  State<_NowPlayingHeader> createState() => _NowPlayingHeaderState();
}

class _NowPlayingHeaderState extends State<_NowPlayingHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bar = AnimationController(
      vsync: this, duration: const Duration(seconds: 9));

  bool get _playing => widget.live && widget.player.playing;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _NowPlayingHeader old) {
    super.didUpdateWidget(old);
    if (old.word.word != widget.word.word) _bar.value = 0;
    _sync();
  }

  void _sync() {
    if (_playing) {
      if (!_bar.isAnimating) _bar.repeat();
    } else {
      _bar.stop();
      if (!widget.live) _bar.value = 0;
    }
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.live) {
      unawaited(widget.player.toggle());
    } else {
      widget.onPlay(widget.word);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.word;
    final sub = [
      if (w.origin.isNotEmpty) w.origin else if (w.organ.isNotEmpty) w.organ,
      if (w.meaning.isNotEmpty) w.meaning,
    ].join(' · ');
    final r = BorderRadius.circular(18);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: HeroGlassRecipe.fill,
        borderRadius: r,
        border: Border.all(color: HeroGlassRecipe.line),
      ),
      child: Row(
        children: [
          GestureDetector(
            key: const ValueKey('sl-np-open'),
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onPlay(w),
            onLongPress:
                widget.onOpen == null ? null : () => widget.onOpen!(w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                      width: 68,
                      height: 68,
                      child: SlImage(widget.art, word: w.word)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onPlay(w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    key: const ValueKey('sl-np-label'),
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 10.5,
                      letterSpacing: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    w.word,
                    key: const ValueKey('sl-np-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12.5,
                      ),
                    ),
                  const SizedBox(height: 9),
                  AnimatedBuilder(
                    animation: _bar,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        height: 4,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(color: Color(0x33FFFFFF)),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _bar.value.clamp(0.0, 1.0),
                              child: const ColoredBox(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: _playing ? 'Pause' : 'Play',
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('sl-np-toggle'),
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFF111118),
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.size,
    required this.pick,
    required this.playing,
    required this.onPlay,
    this.onOpen,
  });
  final double size;
  final SlPick pick;
  final bool playing;
  final ValueChanged<Word> onPlay;
  final ValueChanged<Word>? onOpen;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(14);
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('sl-tile-${pick.word.word}'),
          borderRadius: r,
          onTap: () => onPlay(pick.word),
          onLongPress: onOpen == null ? null : () => onOpen!(pick.word),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: r,
              border: Border.all(
                color: playing ? Colors.white : HeroGlassRecipe.line,
                width: playing ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(playing ? 12 : 13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SlImage(pick.art, word: pick.word.word),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(0, 0.15),
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                  ),
                  if (playing)
                    const Positioned(
                      top: 5,
                      right: 5,
                      child: Icon(Icons.graphic_eq_rounded,
                          color: Colors.white, size: 16),
                    ),
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 5,
                    child: Text(
                      pick.word.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── (C) Station row ─────────────────────────────────────────────────────────

class GlassStationRow extends StatelessWidget {
  const GlassStationRow({super.key, required this.stations});
  final List<SlStation> stations;

  static const double cardW = 158;
  static const double cardH = 206;

  static const List<Color> _accents = [
    Color(0xFF2DD4BF),
    Color(0xFF818CF8),
    Color(0xFFFBBF24),
    Color(0xFF38BDF8),
    Color(0xFFA78BFA),
    Color(0xFF34D399),
    Color(0xFFF0ABFC),
    Color(0xFF60A5FA),
  ];

  static Color accentFor(String id) =>
      _accents[SoundArtLedger._hash(id) % _accents.length];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: stations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _StationCard(station: stations[i]),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station});
  final SlStation station;

  @override
  Widget build(BuildContext context) {
    final accent = station.accent ?? GlassStationRow.accentFor(station.id);
    final r = BorderRadius.circular(22);
    const av = 54.0;
    return SizedBox(
      width: GlassStationRow.cardW,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('sl-station-${station.id}'),
          borderRadius: r,
          onTap: station.onTap,
          onLongPress: station.onLongPress,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              borderRadius: r,
              border: Border.all(color: const Color(0x33FFFFFF)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.42),
                  accent.withValues(alpha: 0.12),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: av,
                  child: Stack(
                    children: [
                      for (var i = 0; i < station.avatars.length && i < 3; i++)
                        Positioned(
                          left: i * 34.0,
                          child: Container(
                            width: av,
                            height: av,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xE6FFFFFF), width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x59000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3)),
                              ],
                            ),
                            child: ClipOval(
                                child: SlImage(station.avatars[i],
                                    alignment: Alignment.center)),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  station.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  station.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xDDFFFFFF),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
