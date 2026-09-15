/// Sound Library — restored website SLM feed + YTM polish.
///
/// Keeps every prior section (intro, looping banner, filter chips, speed dial,
/// quick picks, Store video rail, Meaning promo, sentences, Atelier
/// collections, big cards, category mosaics with word lists, meanings rows)
/// and layers taller banner video, Currently Playing rail, Buy Request CTA,
/// and [SoundCategoryScreen] pages that list every word in a category.
/// Artwork is Word Atelier collection renders in `assets/store/collections/`.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/practice_progress.dart';
import '../data/store_catalog.dart';
import '../media/nwsb_image.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/black_glass_banner.dart';
import '../widgets/intro_gate.dart';
import '../widgets/tv_frame.dart';
import 'practice.dart';
import 'practice_player.dart';
import 'store.dart';
import 'store/meaning_store.dart';
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
  final cs = kRmCategories;
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
    return ['All', 'Sentences', 'My Words', 'Purchased', ...sorted];
  }

  List<Word> _chosen(List<Word> all) {
    if (_chip == 'All' || _chip == 'Sentences') return all;
    // Purchased / My Words: no purchase ledger yet — show all / none emptied.
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

  void _goMeanings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MeaningStoreScreen()),
    );
  }

  void _goPractice() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PracticeScreen()),
    );
  }

  void _openCategory(String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SoundCategoryScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = ContentStore.instance.library;
    final meanings = ContentStore.instance.meanings;
    final counts = _sessionCounts();
    final feed = _SlmFeed(
      chip: _chip,
      chips: _chipList(all),
      onChip: (c) => setState(() => _chip = c),
      words: _chosen(all),
      allWords: all,
      meanings: meanings,
      counts: counts,
      byWord: _byWord,
      onPlayWord: _playWord,
      onOpenWord: _openWord,
      onStore: _goStore,
      onMeanings: _goMeanings,
      onPractice: _goPractice,
      onOpenCategory: _openCategory,
      embedded: widget.embedded,
      onBack: () => Navigator.of(context).maybePop(),
    );

    if (widget.embedded) {
      // Bottom inset clears the floating nav pill when this is the Library
      // tab root; pushed sheets still get SafeArea bottom from the modal.
      final bottom = Navigator.of(context).canPop() ? 0.0 : 96.0;
      return Material(
        color: Colors.black,
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

class _SlmFeed extends StatelessWidget {
  const _SlmFeed({
    required this.chip,
    required this.chips,
    required this.onChip,
    required this.words,
    required this.allWords,
    required this.meanings,
    required this.counts,
    required this.byWord,
    required this.onPlayWord,
    required this.onOpenWord,
    required this.onStore,
    required this.onMeanings,
    required this.onPractice,
    required this.onOpenCategory,
    required this.embedded,
    required this.onBack,
  });

  final String chip;
  final List<String> chips;
  final ValueChanged<String> onChip;
  final List<Word> words;
  final List<Word> allWords;
  final List<Meaning> meanings;
  final Map<String, int> counts;
  final Map<String, RmCategory> byWord;
  final ValueChanged<Word> onPlayWord;
  final ValueChanged<Word> onOpenWord;
  final VoidCallback onStore;
  final VoidCallback onMeanings;
  final VoidCallback onPractice;
  final ValueChanged<String> onOpenCategory;
  final bool embedded;
  final VoidCallback onBack;

  String art(String name) => _artForWord(name, byWord);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width * 0.78;
    final mosaicW = MediaQuery.sizeOf(context).width * 0.42;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _SlmHead(
            chips: chips,
            chip: chip,
            onChip: onChip,
            onBack: onBack,
            embedded: embedded,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 48),
              children: [
                if (chip == 'Sentences') ...[
                  _sentencesSec(),
                  _storeVideos(wide),
                  _promo(),
                  _buyRequest(),
                  _meaningRows(),
                ] else if (words.isEmpty) ...[
                  _empty(),
                  _promo(),
                  _buyRequest(),
                ] else ...[
                  _currentlyPlaying(),
                  _speedDial(),
                  _section(
                    'Quick picks',
                    trailing: words.isEmpty
                        ? null
                        : _pill('Play all', () => onPlayWord(words.first)),
                    child: _rowPages(words.take(12).toList()),
                  ),
                  _storeVideos(wide),
                  _promo(),
                  _sentencesSec(),
                  _collections(context, wide),
                  _bigCards(wide),
                  _mosaics(mosaicW),
                  _buyRequest(),
                  _meaningRows(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  List<Word> get _playingRail {
    final practiced = allWords
        .where((w) => (counts[w.word] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (counts[b.word] ?? 0).compareTo(counts[a.word] ?? 0));
    final base = practiced.isNotEmpty ? practiced : words;
    return base.take(8).toList();
  }

  Widget _currentlyPlaying() {
    final list = _playingRail;
    if (list.isEmpty) return const SizedBox.shrink();
    return _section(
      'Currently Playing',
      child: _CurrentlyPlayingRail(
        words: list,
        art: art,
        onTap: onPlayWord,
      ),
    );
  }

  Widget _buyRequest() => _BuyRequestCta(onTap: onStore);

  Widget _empty() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        child: Column(
          children: [
            const Text(
              'Nothing in this filter yet.',
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
            ),
            const SizedBox(height: 14),
            _pill('Show everything', () => onChip('All')),
          ],
        ),
      );

  Widget _section(String title, {Widget? trailing, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: HeavyGlassPanel(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NestedDarkWrap(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
            NestedDarkWrap(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x66FFFFFF)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12.5),
        ),
      ),
    );
  }

  Widget _chev(VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
    );
  }

  Widget _speedDial() {
    if (words.isEmpty) return const SizedBox.shrink();
    final pages = <List<Word>>[];
    for (var i = 0; i < words.length && i < 27; i += 9) {
      pages.add(words.sublist(i, i + 9 > words.length ? words.length : i + 9));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: HeavyGlassPanel(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NestedDarkWrap(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/store/intro-store.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR PRACTICE',
                      style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Speed dial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          NestedDarkWrap(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
            height: 280,
            child: PageView.builder(
              itemCount: pages.length,
              controller: PageController(viewportFraction: 0.94),
              itemBuilder: (_, page) {
                final used = <String>{};
                final p = pages[page];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final w in p)
                        Builder(builder: (_) {
                          var src = art(w.word);
                          if (used.contains(src)) {
                            for (var k = 1; k <= kRmCategories.length; k++) {
                              final alt = _colAsset(
                                  kRmCategories[(_hash(w.word) + k) %
                                      kRmCategories.length]);
                              if (!used.contains(alt)) {
                                src = alt;
                                break;
                              }
                            }
                          }
                          used.add(src);
                          return GestureDetector(
                            onTap: () => onPlayWord(w),
                            child: FramedSlot(
                              frame: DeviceFrame.tab6Landscape,
                              overlay: Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                      8, 20, 8, 8),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Color(0xD9000000),
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    w.word,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              child: Image.asset(
                                src,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: Color(0xFF1A1A1A)),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _rowPages(List<Word> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    final pages = <List<Word>>[];
    for (var i = 0; i < list.length; i += 4) {
      pages.add(list.sublist(i, i + 4 > list.length ? list.length : i + 4));
    }
    return SizedBox(
      height: 4 * 64.0,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.94),
        itemCount: pages.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(left: 10, right: 4),
          child: Column(
            children: [
              for (final w in pages[i]) _trackRow(w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trackRow(Word w, {String? title, String? sub, VoidCallback? onTap}) {
    final label = title ?? w.word;
    final subtitle = sub ??
        [
          if (w.phonetic.isNotEmpty) w.phonetic,
          if (w.organ.isNotEmpty) w.organ,
          if (counts[w.word] != null)
            '${counts[w.word]} session${counts[w.word] == 1 ? '' : 's'}',
        ].join(' · ');
    return InkWell(
      onTap: onTap ?? () => onPlayWord(w),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: FramedSlot(
                frame: DeviceFrame.tab6Landscape,
                child: Image.asset(
                  art(w.word),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF1A1A1A)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF5F5F7),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0x80EBEBF5),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => onOpenWord(w),
              icon: const Icon(Icons.more_vert, color: Color(0x99FFFFFF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeVideos(double cardW) {
    final items = <_StoreVid>[
      _StoreVid(
        title: 'Sound Library',
        sub: 'Every word and sentence you own',
        asset: 'assets/video/sound-library-banner.mp4',
        onTap: onPractice,
      ),
      _StoreVid(
        title: 'The NowssB Store',
        sub: 'Two libraries. One destination.',
        asset: nwsbVideo(kMsMeaningVidFile),
        onTap: onStore,
      ),
      _StoreVid(
        title: 'NowssB Signature',
        sub: 'The rarest words and meanings',
        asset: 'assets/video/signature-banner.mp4',
        onTap: onStore,
      ),
      _StoreVid(
        title: 'Subscription',
        sub: 'Unlock the full word library',
        asset: 'assets/video/subscription-a.mp4',
        onTap: onStore,
      ),
      _StoreVid(
        title: 'Offers & bundles',
        sub: 'Coupons on words and meanings',
        asset: 'assets/video/coupon-a.mp4',
        onTap: onStore,
      ),
    ];
    return _section(
      'From the Store',
      trailing: _chev(onStore),
      child: SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final x = items[i];
            return SizedBox(
              width: cardW,
              child: GestureDetector(
                onTap: x.onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FramedSlot(
                      frame: DeviceFrame.tab4Landscape,
                      child: NwsbVideo(
                        asset: x.asset,
                        priority: ClipPriority.decoration,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      x.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      x.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0x94FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _promo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: HeavyGlassPanel(
        radius: 22,
        padding: const EdgeInsets.all(8),
        child: NestedDarkWrap(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          radius: 16,
          onTap: onMeanings,
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F4FA), Color(0xFFC5DCE8)],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  flex: 58,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Every word has an origin.\nFind out what yours means.',
                          style: TextStyle(
                            color: Color(0xFF06121A),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          meanings.isEmpty
                              ? 'The Meaning Store'
                              : '${meanings.length} meanings in the archive',
                          style: const TextStyle(
                            color: Color(0xAD06121A),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward,
                            color: Color(0xFF06121A), size: 26),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 42,
                  child: ColoredBox(
                    color: const Color(0xFF06121A),
                    child: FramedSlot(
                      frame: DeviceFrame.tab6Landscape,
                      child: Image.asset(
                        'assets/store/intro-meanings.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF06121A)),
                      ),
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

  Widget _sentencesSec() {
    return _section(
      'Your sentences',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0FFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Finish a practice session and the sentence you built is saved here.',
                style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 12),
              _pill('Start a session', onPractice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collections(BuildContext context, double cardW) {
    return _section(
      'Collections',
      trailing: _chev(onStore),
      child: SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: kRmCategories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final c = kRmCategories[i];
            return SizedBox(
              width: cardW,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _AtelierWordsScreen(category: c),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FramedSlot(
                      frame: DeviceFrame.tab4Landscape,
                      child: Image.asset(
                        _colAsset(c),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${c.words.length} words · ${c.sub}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0x94FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _bigCards(double cardW) {
    final cold = words.where((w) => counts[w.word] == null).toList();
    final use = (cold.isNotEmpty ? cold : words).take(6).toList();
    if (use.isEmpty) return const SizedBox.shrink();
    return _section(
      'Not practised yet',
      child: SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: use.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final w = use[i];
            final benefit =
                w.benefit.isNotEmpty ? w.benefit : (w.meaning.isNotEmpty ? w.meaning : '');
            return SizedBox(
              width: cardW,
              child: GestureDetector(
                onTap: () => onPlayWord(w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FramedSlot(
                      frame: DeviceFrame.tab4Landscape,
                      child: Image.asset(
                        art(w.word),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF1A1A1A)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      benefit.isEmpty ? w.word : '${w.word} — $benefit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [w.organ, w.origin].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0x94FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _mosaics(double cardW) {
    final cats = <String>{};
    for (final w in allWords) {
      cats.addAll(w.categories);
    }
    final list = cats.toList()..sort();
    if (list.isEmpty) return const SizedBox.shrink();
    return _section(
      'Browse by category',
      child: SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: list.length.clamp(0, 10),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final c = list[i];
            final ws = allWords.where((w) => w.categories.contains(c)).length;
            return SizedBox(
              width: cardW,
              child: GestureDetector(
                onTap: () => onOpenCategory(c),
                onLongPress: () => onChip(c),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FramedSlot(
                      frame: DeviceFrame.tab5Landscape,
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
                                  const ColoredBox(color: Color(0xFF1A1A1A)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$ws word${ws == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0x94FFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _meaningRows() {
    if (meanings.isEmpty) return const SizedBox.shrink();
    final list = meanings.take(12).toList();
    final pages = <List<Meaning>>[];
    for (var i = 0; i < list.length; i += 4) {
      pages.add(list.sublist(i, i + 4 > list.length ? list.length : i + 4));
    }
    return _section(
      'Meanings & origins',
      trailing: _chev(onMeanings),
      child: SizedBox(
        height: 4 * 64.0,
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.94),
          itemCount: pages.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(left: 10, right: 4),
            child: Column(
              children: [
                for (final m in pages[i])
                  InkWell(
                    onTap: onMeanings,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 76,
                            child: FramedSlot(
                              frame: DeviceFrame.tab6Landscape,
                              child: m.img.isNotEmpty
                                  ? NwsbImage(url: m.img)
                                  : Image.asset(
                                      art(m.name),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const ColoredBox(
                                              color: Color(0xFF1A1A1A)),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFF5F5F7),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.sub.isEmpty ? 'Meaning' : m.sub,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0x80EBEBF5),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.more_vert,
                              color: Color(0x99FFFFFF)),
                        ],
                      ),
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

class _StoreVid {
  const _StoreVid({
    required this.title,
    required this.sub,
    required this.asset,
    required this.onTap,
  });
  final String title;
  final String sub;
  final String asset;
  final VoidCallback onTap;
}

class _SlmHead extends StatelessWidget {
  const _SlmHead({
    required this.chips,
    required this.chip,
    required this.onChip,
    required this.onBack,
    required this.embedded,
  });

  final List<String> chips;
  final String chip;
  final ValueChanged<String> onChip;
  final VoidCallback onBack;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    // Taller hero so the looping banner video stays clearly visible (YTM polish).
    return SizedBox(
      height: top + 248,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: NwsbVideo(
              asset: 'assets/video/sound-library-banner.mp4',
              fit: BoxFit.cover,
              priority: ClipPriority.feature,
              autoplay: true,
              loop: true,
              showPoster: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.35, 0.78, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: top + 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sheet grabber only when this screen was pushed/modaled
                // (can pop). As the Library bottom-nav tab root it cannot —
                // showing a grabber + dead back chevron looked broken.
                if (embedded && Navigator.of(context).canPop())
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xB8FFFFFF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          onPressed: onBack,
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 28),
                        )
                      else
                        const SizedBox(width: 12),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: NwsbColors.goldLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Color(0xFF060C18), size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sound Library',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.notifications_none_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0x33FFFFFF),
                        child: Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: chips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = chips[i];
                      final on = c == chip;
                      return GestureDetector(
                        onTap: () => onChip(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: on ? Colors.white : const Color(0x22FFFFFF),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: on
                                  ? Colors.white
                                  : const Color(0x33FFFFFF),
                            ),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              color: on ? Colors.black : Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── YTM polish add-ons (layered on restored SLM feed) ───────────────────────

const Color _kYtmCard = Color(0xFF212121);
const Color _kYtmMuted = Color(0xFFAAAAAA);

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
        padding: const EdgeInsets.symmetric(horizontal: 6),
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
                            const ColoredBox(color: _kYtmCard),
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
                    style: const TextStyle(color: _kYtmMuted, fontSize: 11),
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

class _BuyRequestCta extends StatelessWidget {
  const _BuyRequestCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: _kYtmCard,
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
                      style: TextStyle(color: _kYtmMuted, fontSize: 12.5),
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



/// Atelier collection — full word list for a Store category (never wipe lists).
class _AtelierWordsScreen extends StatelessWidget {
  const _AtelierWordsScreen({required this.category});
  final RmCategory category;

  @override
  Widget build(BuildContext context) {
    final library = ContentStore.instance.library;
    final byName = <String, Word>{
      for (final w in library) w.word.toLowerCase(): w,
    };
    final entries = category.words;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: top + 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _colAsset(category),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF111111)),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 16,
                    top: top + 8,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 28),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${entries.length} words · ${category.sub}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xB8FFFFFF),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Word list',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final e = entries[i];
                final hit = byName[e.word.toLowerCase()];
                return ListTile(
                  onTap: () {
                    if (hit != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PracticePlayerScreen(
                            words: [hit],
                            title: hit.word,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StoreScreen()),
                      );
                    }
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Image.asset(
                        _colAsset(category),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: _kYtmCard),
                      ),
                    ),
                  ),
                  title: Text(
                    e.word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    e.root.isNotEmpty ? e.root : 'NowssB · Atelier',
                    style: const TextStyle(color: _kYtmMuted, fontSize: 12.5),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white54),
                );
              },
              childCount: entries.length,
            ),
          ),
          SliverToBoxAdapter(
            child: _BuyRequestCta(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StoreScreen()),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

/// Category page — full word list for the category (never wipe lists).
class SoundCategoryScreen extends StatefulWidget {
  const SoundCategoryScreen({super.key, required this.category});

  final String category;

  @override
  State<SoundCategoryScreen> createState() => _SoundCategoryScreenState();
}

class _SoundCategoryScreenState extends State<SoundCategoryScreen> {
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

  List<Word> _wordsFor(List<Word> all) =>
      all.where((w) => w.categories.contains(widget.category)).toList();

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

  String _art(String name) => _artForWord(name, _byWord);

  @override
  Widget build(BuildContext context) {
    final all = ContentStore.instance.library;
    final words = _wordsFor(all);
    final counts = _sessionCounts();
    final top = MediaQuery.paddingOf(context).top;
    final practiced = words
        .where((w) => (counts[w.word] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (counts[b.word] ?? 0).compareTo(counts[a.word] ?? 0));
    final playing = (practiced.isNotEmpty ? practiced : words).take(8).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: top + 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(
                    child: NwsbVideo(
                      asset: 'assets/video/sound-library-banner.mp4',
                      fit: BoxFit.cover,
                      priority: ClipPriority.feature,
                      autoplay: true,
                      loop: true,
                      showPoster: true,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 16,
                    top: top + 8,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 28),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                '${words.length} word${words.length == 1 ? '' : 's'} · full list',
                                style: const TextStyle(
                                  color: Color(0xB8FFFFFF),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (words.isNotEmpty)
                          TextButton(
                            onPressed: () => _playAll(words),
                            child: const Text('Play all',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (playing.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                      child: Text(
                        'Currently Playing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _CurrentlyPlayingRail(
                      words: playing,
                      art: _art,
                      onTap: _playWord,
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                'All words in ${widget.category}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (words.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No words in this category yet.',
                  style: TextStyle(color: Color(0x99FFFFFF)),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final w = words[i];
                  final plays = counts[w.word];
                  final sub = [
                    if (w.organ.isNotEmpty) w.organ,
                    if (plays != null) '$plays session${plays == 1 ? '' : 's'}',
                    if (w.origin.isNotEmpty) w.origin,
                  ].join(' · ');
                  return InkWell(
                    onTap: () => _playWord(w),
                    onLongPress: () => _openWord(w),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: Image.asset(
                                _art(w.word),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: _kYtmCard),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.word,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFF5F5F7),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sub.isEmpty ? 'NowssB' : sub,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0x80EBEBF5),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openWord(w),
                            icon: const Icon(Icons.more_vert,
                                color: Color(0x99FFFFFF)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: words.length,
              ),
            ),
          SliverToBoxAdapter(child: _BuyRequestCta(onTap: _goStore)),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}
