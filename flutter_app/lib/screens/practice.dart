/// Practice — today's session.
///
/// The website picks the session from the hour: a morning ritual, an
/// afternoon session, an evening practice, a night restoration. Same three
/// windows here as `getTimeSlot` in app/js/part037.js, and the words are
/// filtered by the `time` field every word already carries — which is the
/// point of having ported the model rather than a list of names.
///
/// The player owns the glassmorphism Practice Lab entry point; keeping this
/// screen focused on session selection means the Lab opens over the player
/// with its live blur, word breakdown, and sound-ripple experience intact.
library;

import 'package:nowssb/data/day_part.dart';
import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../theme/player_aura.dart';
import '../widgets/page_shell.dart';
import '../widgets/colored_split_promo_banner.dart';
import '../widgets/restyle_kit.dart';
import 'sound_library.dart';
import 'practice_player.dart';
import 'word_detail.dart';
import '../data/word_art.dart';
import '../admin/template/editable.dart';
import '../admin/layout/layout_sections.dart';

/// 'morning' … 'night' for [at] (default: now, local). See [dayPartFor].
String nwsbSlot([DateTime? at]) => dayPartFor(at ?? DayClock.now()).slot;

const _slotTitle = {
  'morning': 'Morning Ritual',
  'afternoon': 'Afternoon Session',
  'evening': 'Evening Practice',
  'night': 'Night Restoration',
};

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
    WordArt.instance.addListener(_onContent);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    WordArt.instance.removeListener(_onContent);
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final slot = nwsbSlot();
    final all = ContentStore.instance.library;

    // The words for this hour, and everything else after them. A word marked
    // 'any' belongs to every session; the rest are shown as "also today" so
    // the page is never three rows long on a thin library.
    final now = all.where((w) => w.time == slot || w.time == 'any').toList();
    final rest = all.where((w) => !now.contains(w)).toList();
    final sessionWords = now.isEmpty ? rest : now;

    void openWord(Word w) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WordDetail(word: w)),
        );
    void openLibrary() => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SoundLibraryScreen()),
        );
    final ritual = SplitPromoSpec.forSurface(SplitPromoSurface.morningRitual);
    final hold = SplitPromoExtras.at(12);

    return PageShell(
      eyebrow: 'Today',
      title: _slotTitle[slot] ?? 'Practice',
      film: kPlayerSharedFilm,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverList.list(children: [
            if (all.isEmpty)
              const _Empty()
            // Server-driven order (Admin → UI Editor); bundled order by default.
            else ...layoutChildren(context, 'practice', [
              LSection('session', 'Session card', _SessionCard(
                words: sessionWords,
                slot: slot,
                onStart: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PracticePlayerScreen(
                      words: sessionWords,
                      title: _slotTitle[slot] ?? 'Practice',
                    ),
                  ),
                ),
              )),
              LSection('promo', 'Morning Ritual banner', KitBlackCard(
                key: const ValueKey('practice-library-card'),
                art: KitCutout(ritual.art),
                eyebrow: 'Sound Library',
                title: ritual.title.replaceAll('\n', ' '),
                line: ritual.cta,
                onTap: openLibrary,
              )),
              LSection('now', 'This session words', KitPane(
                key: const ValueKey('practice-session-pane'),
                eyebrow: 'Tap a word to open it',
                title: 'This session',
                mark: NwsbMarks.play24,
                trailing: GlassPill(
                  label: 'Play all',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PracticePlayerScreen(
                        words: sessionWords,
                        title: _slotTitle[slot] ?? 'Practice',
                      ),
                    ),
                  ),
                ),
                child: Column(children: [
                  for (var i = 0; i < now.length; i++)
                    _row(now[i], openWord, index: i, highlighted: i == 0),
                ]),
              )),
              if (rest.isNotEmpty)
                LSection('also', 'Also today words', KitPane(
                  key: const ValueKey('practice-also-pane'),
                  eyebrow: 'Every other word you have',
                  title: 'Also today',
                  mark: NwsbMarks.sound,
                  child: Column(children: [
                    for (var i = 0; i < rest.length; i++)
                      _row(rest[i], openWord, index: now.length + i),
                  ]),
                )),
              LSection('promo2', 'Sound Library banner', KitBlackCard(
                key: const ValueKey('practice-hold-card'),
                art: KitCutout(hold.art),
                eyebrow: 'Practice',
                title: hold.title.replaceAll('\n', ' '),
                line: hold.cta,
                onTap: openLibrary,
              )),
            ]),
          ]),
        ),
      ],
    );
  }

  Widget _row(Word w, ValueChanged<Word> open,
          {required int index, bool highlighted = false}) =>
      KitRow(
        leading: _PlayerCover(
          path: playerCoverArtFor(w, index),
          word: w.word,
        ),
        title: w.word,
        sub: w.organ.isNotEmpty ? w.organ : w.meaning,
        highlighted: highlighted,
        onTap: () => open(w),
      );
}

/// The word's own poster (the same cover the player shows), clipped by the
/// parent tile (128×128 / 16 on the hero, 52×52 / 8 on a row). Posters are
/// square; a taller picture keeps its top, where the word and face sit.
class _PlayerCover extends StatelessWidget {
  const _PlayerCover({super.key, required this.path, this.word});
  final String path;
  final String? word;

  @override
  Widget build(BuildContext context) {
    Widget err(BuildContext _, Object __, StackTrace? ___) =>
        const ColoredBox(color: Color(0xFF111111));
    if (path.startsWith('http')) {
      return EditableImage.network(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        word: word,
        errorBuilder: err,
        slot: 'practice.PlayerCover',
      );
    }
    return EditableImage.asset(
      path,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      word: word,
      errorBuilder: err,
      slot: 'practice.PlayerCover',
    );
  }
}

/// Today's session in the Currently Playing hero layout: the player's
/// cover for the selected word, the count, the line, the round white
/// Start button, and the first few words as pills. Tapping a pill
/// crossfades the cover to that word's player art.
class _SessionCard extends StatefulWidget {
  const _SessionCard({
    required this.words,
    required this.slot,
    required this.onStart,
  });
  final List<Word> words;
  final String slot;
  final VoidCallback onStart;

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  var _selected = 0;

  @override
  void didUpdateWidget(covariant _SessionCard old) {
    super.didUpdateWidget(old);
    if (widget.words.isEmpty) {
      _selected = 0;
    } else if (_selected >= widget.words.length) {
      _selected = widget.words.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    final count = words.length;
    final i = words.isEmpty ? 0 : _selected.clamp(0, words.length - 1);
    final lead = words.isEmpty ? null : words[i];
    final path = playerCoverArtFor(lead, i);
    return KitHero(
      key: const ValueKey('practice-hero'),
      art: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, if (current != null) current],
        ),
        child: _PlayerCover(
          key: ValueKey(path),
          path: path,
          word: lead?.word,
        ),
      ),
      cornerLabel: "Today's session",
      eyebrow: 'Ready to play',
      title: '$count ${count == 1 ? 'word' : 'words'}',
      subline: 'Say each one on the exhale, and hold the last sound.',
      buttonIcon: Icons.play_arrow_rounded,
      buttonLabel: 'Start Player',
      onButton: widget.onStart,
      footer: words.length < 2
          ? null
          : SizedBox(
              height: 34,
              child: ListView.separated(
                key: const ValueKey('practice-chips'),
                scrollDirection: Axis.horizontal,
                cacheExtent: 800,
                itemCount: words.length.clamp(0, 8),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Center(
                  child: GlassPill(
                    key: ValueKey('practice-chip-${words[i].word}'),
                    label: words[i].word,
                    selected: i == _selected,
                    onTap: () => setState(() => _selected = i),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 34, color: Color(0x66FFFFFF)),
          SizedBox(height: 14),
          EditableLabel('practice.Empty',
            'No words yet.',
            style: TextStyle(fontSize: 15, color: Color(0xB3FFFFFF)),
          ),
          SizedBox(height: 6),
          Text(
            'Your words are on their way.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12, color: Color(0x8CFFFFFF), height: 1.5),
          ),
        ],
      ),
    );
  }
}
