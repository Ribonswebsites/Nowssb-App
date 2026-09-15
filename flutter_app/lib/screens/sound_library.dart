/// Sound Library — YTM-style expanded full-page feed (not one wrapper card).
///
/// Tall looping banner video, category chips, Currently Playing, featured
/// main-result card, hits rail, vertical track rows, and Buy Request CTA.
/// Category mosaics / rails push [SoundCategoryScreen] with the same language.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/practice_progress.dart';
import '../data/store_catalog.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../widgets/intro_gate.dart';
import 'practice_player.dart';
import 'store.dart';
import 'word_detail.dart';

/// Collection banner file for each Atelier id — same table as part080 COLS.
const Map<String, String> _kColFiles = {
  'off50': 'sale',
  'elements': 'elements',
  'sacred': 'sacred',
  'identity': 'identity',
  'cosmos': 'cosmos',
  'nature': 'nature',
  'family': 'family',
  'elite': 'elite',
  'premium': 'premium',
  'mythical': 'mythical',
  'warriors': 'warriors',
  'ancient': 'ancient',
  'peace': 'peace',
  'white': 'white',
  'black': 'black',
};

const Color _kBg = Colors.black;
const Color _kCard = Color(0xFF212121);
const Color _kChip = Color(0xFF2A2A2A);
const Color _kMuted = Color(0xFFAAAAAA);
const Color _kSub = Color(0xFF8A8A8A);

String _colAsset(RmCategory c) {
  final file = _kColFiles[c.id] ?? c.id;
  return 'assets/store/collections/$file.webp';
}

int _hash(String s) {
  var h = 0;
  for (final cu in s.codeUnits) {
    h = (h * 31 + cu) & 0x7fffffff;
  }
  return h;
}

String _artForWord(String name, Map<String, RmCategory> byWord) {
  final key = name.toLowerCase();
  final hit = byWord[key];
  if (hit != null) return _colAsset(hit);
  const cs = kRmCategories;
  return _colAsset(cs[_hash(key) % cs.length]);
}

Map<String, RmCategory> _wordToCol() {
  final out = <String, RmCategory>{};
  for (final c in kRmCategories) {
    for (final w in c.words) {
      final k = w.word.toLowerCase();
      out.putIfAbsent(k, () => c);
    }
  }
  return out;
}

String _playsLabel(int n) {
  if (n <= 0) return '0 plays';
  if (n >= 1000000) {
    final v = n / 1000000;
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M plays';
  }
  if (n >= 1000) {
    final v = n / 1000;
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}K plays';
  }
  return '$n play${n == 1 ? '' : 's'}';
}

String _artistLine(Word w, Map<String, int> counts) {
  final artist = w.origin.isNotEmpty
      ? w.origin
      : (w.organ.isNotEmpty ? w.organ : 'NowssB');
  final plays = counts[w.word] ?? (_hash(w.word) % 9000 + 120);
  return '$artist • ${_playsLabel(plays)}';
}

/// Filter chips that stay on Sound Library (do not open Category page).
const _kFilterOnly = {'All', 'Sentences', 'My Words', 'Purchased'};

class SoundLibraryScreen extends StatefulWidget {
  const SoundLibraryScreen({super.key, this.embedded = false});

  /// True when opened as the player sheet — skip the intro gate.
  final bool embedded;

  @override
  State<SoundLibraryScreen> createState() => _SoundLibraryScreenState();
}

class _SoundLibraryScreenState extends State<SoundLibraryScreen> {
  String _chip = 'All';
  late final Map<String, RmCategory> _byWord = _wordToCol();

  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
    PracticeProgress.instance.addListener(_onContent);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    PracticeProgress.instance.removeListener(_onContent);
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  Map<String, int> _sessionCounts() {
    final out = <String, int>{};
    for (final s in PracticeProgress.instance.sessionsSnapshot) {
      final w = '${s['word'] ?? ''}'.trim();
      if (w.isEmpty) continue;
      out[w] = (out[w] ?? 0) + 1;
    }
    return out;
  }

  List<String> _chipList(List<Word> all) {
    final cats = <String>{};
    for (final w in all) {
      cats.addAll(w.categories);
    }
    final sorted = cats.toList()..sort();
    // YTM-style genre-ish chips first, then data categories.
    return [
      'All',
      'Trending',
      'Global',
      'Sentences',
      'My Words',
      ...sorted,
    ];
  }

  List<Word> _chosen(List<Word> all) {
    if (_chip == 'All' ||
        _chip == 'Sentences' ||
        _chip == 'Trending' ||
        _chip == 'Global') {
      return all;
    }
    if (_chip == 'Purchased') return const [];
    if (_chip == 'My Words') return all;
    return all.where((w) => w.categories.contains(_chip)).toList();
  }

  void _playWord(Word w) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticePlayerScreen(
          words: [w],
          title: w.word,
        ),
      ),
    );
  }

  void _playAll(List<Word> list) {
    if (list.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticePlayerScreen(
          words: list,
          title: 'Sound Library',
        ),
      ),
    );
  }

  void _openWord(Word w) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordDetail(word: w)),
    );
  }

  void _goStore() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StoreScreen()),
    );
  }

  void _openCategory(String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SoundCategoryScreen(category: category),
      ),
    );
  }

  void _onChip(String c) {
    if (!_kFilterOnly.contains(c) &&
        c != 'Trending' &&
        c != 'Global' &&
        c != 'All') {
      // Real data categories → full Category page (same YTM language).
      _openCategory(c);
      return;
    }
    setState(() => _chip = c);
  }

  @override
  Widget build(BuildContext context) {
    final all = ContentStore.instance.library;
    final meanings = ContentStore.instance.meanings;
    final counts = _sessionCounts();
    final feed = _YtmSoundFeed(
      mode: _YtmFeedMode.library,
      title: 'SOUND LIBRARY',
      subtitle: 'Your words, sentences, and frequencies',
      chip: _chip,
      chips: _chipList(all),
      onChip: _onChip,
      words: _chosen(all),
      allWords: all,
      counts: counts,
      byWord: _byWord,
      onPlayWord: _playWord,
      onPlayAll: () => _playAll(_chosen(all)),
      onOpenWord: _openWord,
      onStore: _goStore,
      onOpenCategory: _openCategory,
      embedded: widget.embedded,
      onBack: () => Navigator.of(context).maybePop(),
      meaningsCount: meanings.length,
    );

    if (widget.embedded) {
      final bottom = Navigator.of(context).canPop() ? 0.0 : 96.0;
      return Material(
        color: _kBg,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: feed,
          ),
        ),
      );
    }

    return IntroGate(
      tag: 'Personal Collection',
      eyebrow: 'Shabdapathy · Sound Archive',
      title: 'Sound\nLibrary',
      body: 'Your saved sentences, subscription words, and purchased '
          'frequencies — all in one place.',
      stats: [
        '${all.length} words',
        '${meanings.length} meanings',
      ],
      art: 'assets/store/intro-words.webp',
      enterLabel: 'OPEN LIBRARY',
      child: feed,
    );
  }
}

/// Category surface — same expanded YTM structure as Sound Library.
class SoundCategoryScreen extends StatefulWidget {
  const SoundCategoryScreen({super.key, required this.category});

  final String category;

  @override
  State<SoundCategoryScreen> createState() => _SoundCategoryScreenState();
}

class _SoundCategoryScreenState extends State<SoundCategoryScreen> {
  late final Map<String, RmCategory> _byWord = _wordToCol();
  String _chip = '';

  @override
  void initState() {
    super.initState();
    _chip = widget.category;
    ContentStore.instance.addListener(_onContent);
    PracticeProgress.instance.addListener(_onContent);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    PracticeProgress.instance.removeListener(_onContent);
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  Map<String, int> _sessionCounts() {
    final out = <String, int>{};
    for (final s in PracticeProgress.instance.sessionsSnapshot) {
      final w = '${s['word'] ?? ''}'.trim();
      if (w.isEmpty) continue;
      out[w] = (out[w] ?? 0) + 1;
    }
    return out;
  }

  List<String> _relatedChips(List<Word> all) {
    final cats = <String>{};
    for (final w in all) {
      cats.addAll(w.categories);
    }
    final sorted = cats.toList()..sort();
    return [widget.category, 'All', ...sorted.where((c) => c != widget.category)];
  }

  List<Word> _wordsFor(List<Word> all) {
    if (_chip == 'All') return all;
    return all.where((w) => w.categories.contains(_chip)).toList();
  }

  void _playWord(Word w) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticePlayerScreen(words: [w], title: w.word),
      ),
    );
  }

  void _playAll(List<Word> list) {
    if (list.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticePlayerScreen(
          words: list,
          title: widget.category,
        ),
      ),
    );
  }

  void _openWord(Word w) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordDetail(word: w)),
    );
  }

  void _goStore() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StoreScreen()),
    );
  }

  void _openCategory(String category) {
    if (category == widget.category) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SoundCategoryScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ContentStore.instance.library;
    final counts = _sessionCounts();
    final words = _wordsFor(all);
    final n = words.length;

    return Material(
      color: _kBg,
      child: _YtmSoundFeed(
        mode: _YtmFeedMode.category,
        title: widget.category.toUpperCase(),
        subtitle: n == 0
            ? 'Browse tones in this category'
            : '$n word${n == 1 ? '' : 's'} · NowssB audience',
        chip: _chip,
        chips: _relatedChips(all),
        onChip: (c) {
          if (c == 'All') {
            setState(() => _chip = 'All');
            return;
          }
          if (c != widget.category && !_kFilterOnly.contains(c)) {
            _openCategory(c);
            return;
          }
          setState(() => _chip = c);
        },
        words: words,
        allWords: all,
        counts: counts,
        byWord: _byWord,
        onPlayWord: _playWord,
        onPlayAll: () => _playAll(words),
        onOpenWord: _openWord,
        onStore: _goStore,
        onOpenCategory: _openCategory,
        embedded: false,
        onBack: () => Navigator.of(context).maybePop(),
        meaningsCount: ContentStore.instance.meanings.length,
      ),
    );
  }
}

enum _YtmFeedMode { library, category }

class _YtmSoundFeed extends StatelessWidget {
  const _YtmSoundFeed({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.chip,
    required this.chips,
    required this.onChip,
    required this.words,
    required this.allWords,
    required this.counts,
    required this.byWord,
    required this.onPlayWord,
    required this.onPlayAll,
    required this.onOpenWord,
    required this.onStore,
    required this.onOpenCategory,
    required this.embedded,
    required this.onBack,
    required this.meaningsCount,
  });

  final _YtmFeedMode mode;
  final String title;
  final String subtitle;
  final String chip;
  final List<String> chips;
  final ValueChanged<String> onChip;
  final List<Word> words;
  final List<Word> allWords;
  final Map<String, int> counts;
  final Map<String, RmCategory> byWord;
  final ValueChanged<Word> onPlayWord;
  final VoidCallback onPlayAll;
  final ValueChanged<Word> onOpenWord;
  final VoidCallback onStore;
  final ValueChanged<String> onOpenCategory;
  final bool embedded;
  final VoidCallback onBack;
  final int meaningsCount;

  String art(String name) => _artForWord(name, byWord);

  List<Word> get _pool => words.isNotEmpty ? words : allWords;

  List<Word> get _currentlyPlaying {
    // Prefer words with session history; fall back to first of pool.
    final practiced = allWords
        .where((w) => (counts[w.word] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (counts[b.word] ?? 0).compareTo(counts[a.word] ?? 0));
    final base = practiced.isNotEmpty ? practiced : _pool;
    return base.take(8).toList();
  }

  Word? get _featured => _pool.isEmpty ? null : _pool.first;

  List<Word> get _hits {
    final cold = _pool.where((w) => counts[w.word] == null).toList();
    final use = cold.isNotEmpty ? cold : _pool;
    return use.take(10).toList();
  }

  List<Word> get _trending => _pool.take(12).toList();

  List<String> get _mosaicCats {
    final cats = <String>{};
    for (final w in allWords) {
      cats.addAll(w.categories);
    }
    final list = cats.toList()..sort();
    return list.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HeroBanner(
              title: title,
              subtitle: subtitle,
              topInset: top,
              embedded: embedded,
              onBack: onBack,
              showSubscribe: mode == _YtmFeedMode.category,
              onPlay: onPlayAll,
              onStore: onStore,
            ),
          ),
          SliverToBoxAdapter(child: _ChipRow(chips: chips, chip: chip, onChip: onChip)),
          if (_currentlyPlaying.isNotEmpty)
            ..._sectionSlivers(
              title: 'Currently Playing',
              child: _CurrentlyPlayingRail(
                words: _currentlyPlaying,
                art: art,
                onTap: onPlayWord,
              ),
            ),
          if (_featured != null)
            SliverToBoxAdapter(
              child: _FeaturedMainCard(
                word: _featured!,
                art: art(_featured!.word),
                meta: _artistLine(_featured!, counts),
                onPlay: () => onPlayWord(_featured!),
                onSave: onStore,
                onMore: () => onOpenWord(_featured!),
              ),
            ),
          if (_hits.isNotEmpty)
            ..._sectionSlivers(
              eyebrow: mode == _YtmFeedMode.library
                  ? 'THE BIGGEST & BEST TONES INTERNATIONALLY!'
                  : 'FEATURED IN THIS CATEGORY',
              title: mode == _YtmFeedMode.library
                  ? "Today's Global Hits"
                  : 'Listen to the new single',
              child: _HitsRail(
                words: _hits,
                art: art,
                counts: counts,
                onTap: onPlayWord,
              ),
            ),
          if (_trending.isNotEmpty)
            ..._sectionSlivers(
              title: mode == _YtmFeedMode.library
                  ? 'Trending songs for you'
                  : 'Top songs',
              trailing: _PlayAllPill(onTap: onPlayAll),
              child: _TrackList(
                words: _trending,
                art: art,
                counts: counts,
                onTap: onPlayWord,
                onMore: onOpenWord,
              ),
            ),
          SliverToBoxAdapter(
            child: _BuyRequestCta(onTap: onStore),
          ),
          if (mode == _YtmFeedMode.library && _mosaicCats.isNotEmpty)
            ..._sectionSlivers(
              title: 'Browse by category',
              child: _CategoryMosaicRail(
                cats: _mosaicCats,
                allWords: allWords,
                onTap: onOpenCategory,
              ),
            ),
          if (mode == _YtmFeedMode.category && _featured != null)
            ..._sectionSlivers(
              title: 'More like this',
              child: _HitsRail(
                words: _hits.skip(1).take(8).toList(),
                art: art,
                counts: counts,
                onTap: onPlayWord,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  List<Widget> _sectionSlivers({
    String? eyebrow,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          color: _kSub,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(child: child),
    ];
  }
}

// ─── Hero / banner ───────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.title,
    required this.subtitle,
    required this.topInset,
    required this.embedded,
    required this.onBack,
    required this.showSubscribe,
    required this.onPlay,
    required this.onStore,
  });

  final String title;
  final String subtitle;
  final double topInset;
  final bool embedded;
  final VoidCallback onBack;
  final bool showSubscribe;
  final VoidCallback onPlay;
  final VoidCallback onStore;

  @override
  Widget build(BuildContext context) {
    // Tall hero so the looping banner video is clearly visible.
    final height = topInset + (showSubscribe ? 340.0 : 300.0);
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: NwsbVideo(
              asset: 'assets/video/sound-library-banner.mp4',
              priority: ClipPriority.feature,
              fit: BoxFit.cover,
            ),
          ),
          // Light bottom gradient only — keep most of the video readable.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 0.78, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 12,
            top: topInset + 4,
            child: Row(
              children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 24),
                  )
                else if (embedded && Navigator.of(context).canPop())
                  const SizedBox(width: 8)
                else
                  const SizedBox(width: 12),
                const Spacer(),
                IconButton(
                  onPressed: onStore,
                  icon: const Icon(Icons.share_outlined,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.05,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showSubscribe) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onStore,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Subscribe',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _RoundIconBtn(
                        icon: Icons.podcasts_rounded,
                        onTap: onStore,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onPlay,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.black, size: 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x66FFFFFF)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Chips ───────────────────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.chips,
    required this.chip,
    required this.onChip,
  });

  final List<String> chips;
  final String chip;
  final ValueChanged<String> onChip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = chips[i];
          final on = c == chip;
          return GestureDetector(
            onTap: () => onChip(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: on ? Colors.white : _kChip,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                c,
                style: TextStyle(
                  color: on ? Colors.black : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Currently Playing ───────────────────────────────────────────────────────

class _CurrentlyPlayingRail extends StatelessWidget {
  const _CurrentlyPlayingRail({
    required this.words,
    required this.art,
    required this.onTap,
  });

  final List<Word> words;
  final String Function(String) art;
  final ValueChanged<Word> onTap;

  @override
  Widget build(BuildContext context) {
    const size = 128.0;
    return SizedBox(
      height: size + 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: words.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final w = words[i];
          return GestureDetector(
            onTap: () => onTap(w),
            child: SizedBox(
              width: size,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Image.asset(
                        art(w.word),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: _kCard),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    w.word,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    w.organ.isNotEmpty ? w.organ : 'Now playing',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _kMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Featured main-result card (image 2) ─────────────────────────────────────

class _FeaturedMainCard extends StatelessWidget {
  const _FeaturedMainCard({
    required this.word,
    required this.art,
    required this.meta,
    required this.onPlay,
    required this.onSave,
    required this.onMore,
  });

  final Word word;
  final String art;
  final String meta;
  final VoidCallback onPlay;
  final VoidCallback onSave;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Image.asset(
                      art,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF333333)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.word,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Word • $meta',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _kMuted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_vert, color: _kMuted, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onPlay,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.black, size: 22),
                          SizedBox(width: 4),
                          Text(
                            'Play',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onSave,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x88FFFFFF)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 20),
                          SizedBox(width: 4),
                          Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hits rail (Global Hits style) ───────────────────────────────────────────

class _HitsRail extends StatelessWidget {
  const _HitsRail({
    required this.words,
    required this.art,
    required this.counts,
    required this.onTap,
  });

  final List<Word> words;
  final String Function(String) art;
  final Map<String, int> counts;
  final ValueChanged<Word> onTap;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();
    const size = 148.0;
    return SizedBox(
      height: size + 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: words.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final w = words[i];
          return GestureDetector(
            onTap: () => onTap(w),
            child: SizedBox(
              width: size,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: Image.asset(
                            art(w.word),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const ColoredBox(color: _kCard),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xCCFFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.black, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    w.word,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _artistLine(w, counts),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _kMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Vertical track list ─────────────────────────────────────────────────────

class _TrackList extends StatelessWidget {
  const _TrackList({
    required this.words,
    required this.art,
    required this.counts,
    required this.onTap,
    required this.onMore,
  });

  final List<Word> words;
  final String Function(String) art;
  final Map<String, int> counts;
  final ValueChanged<Word> onTap;
  final ValueChanged<Word> onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          for (var i = 0; i < words.length; i++)
            _TrackRow(
              word: words[i],
              art: art(words[i].word),
              sub: _artistLine(words[i], counts),
              highlighted: i == 0,
              onTap: () => onTap(words[i]),
              onMore: () => onMore(words[i]),
            ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.word,
    required this.art,
    required this.sub,
    required this.highlighted,
    required this.onTap,
    required this.onMore,
  });

  final Word word;
  final String art;
  final String sub;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? const Color(0xFF1A1A1A) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Image.asset(
                    art,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: _kCard),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _kMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onMore,
                icon: const Icon(Icons.more_vert, color: _kMuted, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayAllPill extends StatelessWidget {
  const _PlayAllPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _kChip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Play all',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Buy Request CTA ─────────────────────────────────────────────────────────

class _BuyRequestCta extends StatelessWidget {
  const _BuyRequestCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag_outlined,
                    color: Colors.black, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buy Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Open the Store to request or purchase words',
                      style: TextStyle(color: _kMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Category mosaic rail → Category page ────────────────────────────────────

class _CategoryMosaicRail extends StatelessWidget {
  const _CategoryMosaicRail({
    required this.cats,
    required this.allWords,
    required this.onTap,
  });

  final List<String> cats;
  final List<Word> allWords;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const size = 140.0;
    return SizedBox(
      height: size + 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = cats[i];
          final ws = allWords.where((w) => w.categories.contains(c)).length;
          return GestureDetector(
            onTap: () => onTap(c),
            child: SizedBox(
              width: size,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: GridView.count(
                        crossAxisCount: 2,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (var q = 0; q < 4; q++)
                            Image.asset(
                              _colAsset(kRmCategories[
                                  (_hash(c) + q * 4) % kRmCategories.length]),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const ColoredBox(color: _kCard),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$ws word${ws == 1 ? '' : 's'}',
                    style: const TextStyle(color: _kMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
