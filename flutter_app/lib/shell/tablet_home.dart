/// The tablet home: the centre column of Ribon's reference, in NowssB glass.
///
///   Home ······························· bell · [ search ]
///   [ hero banner: headline, line, Explore Now pill · person ]
///   Playlist ································ See more
///   [ four square cards: cover, title, word count, play ]
///   Trending ································ See more
///   01  [art]  title / line ·········· parts  [play]  ⋮
///
/// Only the Normal home on a framed tablet (sidebar or rail) shows it. The
/// NowssB (zen) home keeps HomeFashion inside the frame, and a phone keeps
/// HomeNormal / HomeFashion exactly as they are.
library;

import 'package:flutter/material.dart';

import '../data/app_haptics.dart';
import '../data/content.dart';
import '../data/models.dart';
import '../screens/fashion/header.dart' show showDestinationSearchSheet;
import '../screens/notifications_sheet.dart';
import '../screens/practice_player.dart';
import '../screens/sound_library.dart';
import 'nav_shell.dart';
import 'tablet_frame.dart';

const _muted = Color(0x8CFFFFFF);
const _person = 'assets/banners/promo/split-egyptian-gold.png';

/// A playlist: one Sound Library category and its words.
class _Playlist {
  const _Playlist(this.name, this.words);
  final String name;
  final List<Word> words;
}

List<_Playlist> _playlists(List<Word> all) {
  final by = <String, List<Word>>{};
  for (final w in all) {
    for (final c in w.categories) {
      final k = c.trim();
      if (k.isEmpty) continue;
      (by[k] ??= <Word>[]).add(w);
    }
  }
  final out = [for (final e in by.entries) _Playlist(e.key, e.value)]
    ..sort((a, b) => b.words.length.compareTo(a.words.length));
  return out;
}

class TabletHome extends StatelessWidget {
  const TabletHome({super.key});

  void _push(BuildContext context, Widget page) {
    AppHaptics.selection();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _play(BuildContext context, List<Word> words, String title, {int start = 0}) {
    if (words.isEmpty) return;
    final list = start == 0 ? words : [...words.skip(start), ...words.take(start)];
    _push(context, PracticePlayerScreen(words: list, title: title, showIntro: false));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ContentStore.instance,
      builder: (context, _) {
        final all = ContentStore.instance.library;
        final lists = _playlists(all).take(4).toList();
        final trending = [...all.where((w) => w.price <= 0), ...all.where((w) => w.price > 0)].skip(3).take(5).toList();
        // Transparent: the home sits on the frame's glass panel, one surface
        // with the right column, like the reference.
        return Material(
          type: MaterialType.transparency,
          child: CustomScrollView(
            key: const ValueKey('tablet-home'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                sliver: SliverList.list(children: [
                  _Header(
                    onBell: () => showNotificationsSheet(context),
                    onSearch: () => showDestinationSearchSheet(context),
                  ),
                  const SizedBox(height: 18),
                  _Hero(onExplore: () {
                    AppHaptics.selection();
                    NavScope.goTo(context, 2);
                  }),
                  if (lists.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionHead('Playlist', onMore: () => _push(context, const SoundLibraryScreen())),
                    const SizedBox(height: 12),
                    _PlaylistRow(
                      lists: lists,
                      onOpen: (p) => _push(context, SoundCategoryScreen(category: p.name)),
                      onPlay: (p) => _play(context, p.words, p.name),
                    ),
                  ],
                  if (trending.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionHead('Trending', onMore: () => NavScope.goTo(context, 1)),
                    const SizedBox(height: 6),
                    for (var i = 0; i < trending.length; i++)
                      _TrendRow(
                        key: ValueKey('tablet-trend-${trending[i].key}'),
                        rank: i + 1,
                        word: trending[i],
                        art: playerCoverArtFor(trending[i], i + 3),
                        onPlay: () => _play(context, trending, 'Trending', start: i),
                      ),
                  ],
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBell, required this.onSearch});
  final VoidCallback onBell;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(
        child: Text('Home',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
      ),
      IconButton(
        key: const ValueKey('tablet-home-bell'),
        onPressed: onBell,
        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 6),
      GestureDetector(
        key: const ValueKey('tablet-home-search'),
        behavior: HitTestBehavior.opaque,
        onTap: onSearch,
        child: SizedBox(
          width: 220,
          child: TabletPane(
            radius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: const Row(children: [
              Icon(Icons.search_rounded, size: 18, color: _muted),
              SizedBox(width: 8),
              Expanded(
                child: Text('Search any word or page',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted, fontSize: 12.5)),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const ValueKey('tablet-home-hero'),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 216,
        child: Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B2440), Color(0xFF0E1426), Color(0xFF101A30)],
                ),
                border: Border.all(color: const Color(0x1AFFFFFF)),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 6,
            bottom: 0,
            child: Image.asset(_person, fit: BoxFit.contain, alignment: Alignment.bottomRight,
                errorBuilder: (_, __, ___) => const SizedBox()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 0, 16),
            child: FractionallySizedBox(
              widthFactor: 0.58,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('NOWSSB',
                      style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                  const SizedBox(height: 8),
                  const Text('Listen to healing\nwords all the time',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 25, height: 1.15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Sound Library collections and this hour\'s words, ready to play.',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    key: const ValueKey('tablet-home-explore'),
                    onTap: onExplore,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Explore Now',
                          style: TextStyle(color: Color(0xFF0B0B10), fontSize: 12.5, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead(this.title, {required this.onMore});
  final String title;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onMore,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('See more', style: TextStyle(color: _muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ),
      ]);
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({required this.lists, required this.onOpen, required this.onPlay});
  final List<_Playlist> lists;
  final ValueChanged<_Playlist> onOpen;
  final ValueChanged<_Playlist> onPlay;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (var i = 0; i < 4; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(
          child: i < lists.length
              ? _PlaylistCard(list: lists[i], index: i, onOpen: () => onOpen(lists[i]), onPlay: () => onPlay(lists[i]))
              : const SizedBox(),
        ),
      ],
    ]);
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.list, required this.index, required this.onOpen, required this.onPlay});
  final _Playlist list;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final n = list.words.length;
    return GestureDetector(
      key: ValueKey('tablet-playlist-${list.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(fit: StackFit.expand, children: [
            TabletArt(playerCoverArtFor(list.words.first, index)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x00000000), Color(0xCC05070D)],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 8,
              bottom: 9,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 1),
                    Text('$n ${n == 1 ? 'word' : 'words'}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11)),
                  ]),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppHaptics.selection();
                    onPlay();
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.play_arrow_rounded, size: 18, color: Color(0xFF0B0B10)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({super.key, required this.rank, required this.word, required this.art, required this.onPlay});
  final int rank;
  final Word word;
  final String art;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final line = [if (word.origin.trim().isNotEmpty) word.origin.trim(), if (word.organ.trim().isNotEmpty) word.organ.trim()]
        .join(' · ');
    final parts = word.parts.length;
    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Row(children: [
          SizedBox(
            width: 28,
            child: Text(rank.toString().padLeft(2, '0'),
                style: const TextStyle(color: _muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 42, height: 42, child: TabletArt(art)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(word.word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              if (line.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _muted, fontSize: 11.5)),
              ],
            ]),
          ),
          Expanded(
            flex: 2,
            child: Text(parts > 0 ? '$parts ${parts == 1 ? 'part' : 'parts'}' : '',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 14),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.more_vert_rounded, size: 18, color: _muted),
        ]),
      ),
    );
  }
}
