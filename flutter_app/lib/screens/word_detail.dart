/// One word, in full.
///
/// This is the screen the content model was built for. A NowssB word is not
/// an English word — it is a sound, written in Devanagari, which has letters
/// English does not have. There is no roman spelling of ऋ a reader can simply
/// read out. So the word arrives in four parts at once and this screen shows
/// all four:
///
///   deva      आरोग्य        the word as it is actually written
///   word      AAROGYA       a roman spelling to hold on to
///   parts[]   आ · रो · ग्य   the pronunciation boxes, three to five of them
///   audio     a recording    the only thing that ever settles an argument
///
/// Each box carries its own Devanagari, its own roman spelling, how long to
/// hold it, and one plain sentence on how to make the sound. That is what a
/// reader who has never seen Devanagari actually needs: something to look at,
/// something to read, and something to hear.
library;

import '../shell/tablet.dart';
import 'dart:async';

import '../data/word_voice.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../admin/template/editable.dart';
import '../data/entitlements.dart';
import '../data/models.dart';
import '../data/word_private.dart';
import '../features/stage_practice/stage_pack.dart';
import '../features/stage_practice/stage_progress.dart';
import '../media/nwsb_video.dart';
import '../widgets/content_lock.dart';
import '../widgets/restyle_kit.dart';
import 'daily_tasks.dart' show DailyTasks;
import 'practice_player.dart' show playerCoverArtFor;

class WordDetail extends StatefulWidget {
  const WordDetail({super.key, required this.word});

  final Word word;

  @override
  State<WordDetail> createState() => _WordDetailState();
}

class _WordDetailState extends State<WordDetail> {
  late Word _word;

  @override
  void initState() {
    super.initState();
    _word = widget.word;
    Entitlements.instance.addListener(_onEntitlements);
    _loadPaid();
  }

  @override
  void didUpdateWidget(covariant WordDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word.key != widget.word.key) {
      _word = widget.word;
      _loadPaid();
    }
  }

  @override
  void dispose() {
    Entitlements.instance.removeListener(_onEntitlements);
    super.dispose();
  }

  void _onEntitlements() => _loadPaid();

  Future<void> _loadPaid() async {
    final open = Entitlements.instance.canOpenWord(widget.word);
    if (!open) {
      if (mounted) setState(() => _word = widget.word);
      return;
    }
    // Your essentials · "Read one meaning": this word's meaning is on screen.
    unawaited(DailyTasks.markEvent('read'));
    final next = await WordPrivateStore.instance.resolve(widget.word);
    if (!mounted) return;
    setState(() => _word = next);
  }

  @override
  Widget build(BuildContext context) {
    // Paid words: recordings, videos and meaning come from wordsPrivate via
    // /api/content/word once entitled — never assume public docs still carry them.
    return ListenableBuilder(
      listenable: Entitlements.instance,
      builder: (context, _) =>
          _page(context, Entitlements.instance.canOpenWord(widget.word)),
    );
  }

  Widget _page(BuildContext context, bool open) {
    final word = _word;
    final facts = <Widget>[
      if (open && word.meaning.isNotEmpty)
        _Fact(label: 'MEANING', value: word.meaning, icon: Icons.translate),
      if (word.benefit.isNotEmpty)
        _Fact(
            label: 'WHAT IT DOES',
            value: word.benefit,
            icon: Icons.favorite_border),
      if (word.organ.isNotEmpty)
        _Fact(
            label: 'WHERE IT WORKS',
            value: word.organ,
            icon: Icons.my_location),
      if (word.mouthPos.isNotEmpty)
        _Fact(
            label: 'YOUR MOUTH',
            value: word.mouthPos,
            icon: Icons.record_voice_over_outlined),
      if (word.resonance.isNotEmpty)
        _Fact(
            label: 'WHERE YOU FEEL IT',
            value: word.resonance,
            icon: Icons.graphic_eq),
      if (word.mistake.isNotEmpty)
        _Fact(
            label: 'THE COMMON MISTAKE',
            value: word.mistake,
            icon: Icons.error_outline,
            warn: true),
      if (word.tip.isNotEmpty)
        _Fact(label: 'A TIP', value: word.tip, icon: Icons.lightbulb_outline),
      if (word.notes.isNotEmpty)
        _Fact(
            label: 'NOTES',
            value: word.notes,
            icon: Icons.sticky_note_2_outlined),
    ];
    final sub = [
      if (word.deva.isNotEmpty) word.word,
      if (word.phonetic.isNotEmpty) word.phonetic,
    ].where((e) => e.trim().isNotEmpty).join('  ·  ');
    return KitPage(
      eyebrow: word.origin.isNotEmpty ? word.origin : 'Word',
      title: word.word,
      children: [
        KitHero(
          art: _WordPoster(word: word),
          eyebrow: word.origin.isNotEmpty ? word.origin : 'Word',
          title: word.deva.isNotEmpty ? word.deva : word.word,
          subline: sub.isEmpty ? null : sub,
          cornerLabel: open ? null : 'Locked',
        ),
        // No download: recordings stay inside the Player.
        if (!open) _LockedCard(word: word),
        if (open && word.video.startsWith('http'))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _WordVideo(url: word.video),
          ),
        if (word.description.isNotEmpty)
          KitPane(
            eyebrow: 'About this word',
            title: word.word,
            mark: NwsbMarks.word,
            child: Text(word.description,
                style: const TextStyle(
                    color: Color(0xE6FFFFFF), fontSize: 15, height: 1.5)),
          ),
        if (word.parts.isNotEmpty)
          KitPane(
            eyebrow: 'How to say it',
            title: 'Sound parts',
            mark: NwsbMarks.sound,
            child: _Parts(parts: word.parts),
          ),
        if (facts.isNotEmpty)
          KitPane(
            eyebrow: 'The word',
            title: 'Meaning and use',
            mark: NwsbMarks.meaning,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: facts),
          ),
        // Teacher-recorded stages are practised only in the Player.
        if (StagePack.forWord(word) == null && word.stages.isNotEmpty)
          KitPane(
            eyebrow: 'Practice',
            title: 'Stages',
            mark: NwsbMarks.stages,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < word.stages.length; i++)
                  _Stage(
                      n: i + 1, stage: word.stages[i], word: word, open: open),
              ],
            ),
          ),
        if (word.images.any((u) => u.startsWith('http')))
          KitPane(
            eyebrow: 'Gallery',
            title: 'Images',
            mark: NwsbMarks.feed,
            child: _Images(urls: [
              for (final u in word.images)
                if (u.startsWith('http')) u
            ]),
          ),
        if (word.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _Chips(word.categories),
          ),
      ],
    );
  }
}

class _WordPoster extends StatelessWidget {
  const _WordPoster({required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    final path = playerCoverArtFor(word, 0);
    Widget err(BuildContext _, Object __, StackTrace? ___) =>
        KitWordArt(word: word.word, deva: word.deva);
    if (path.startsWith('http')) {
      return EditableImage.network(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        word: word.word,
        errorBuilder: err,
        slot: 'word_detail.Poster',
      );
    }
    return EditableImage.asset(
      path,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      word: word.word,
      errorBuilder: err,
      slot: 'word_detail.Poster',
    );
  }
}

class _Parts extends StatelessWidget {
  const _Parts({required this.parts});
  final List<WordPart> parts;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return SizedBox(
      height: 132 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: parts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final p = parts[i];
          return Container(
            width: 116,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xF0111114),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x33FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}',
                  style: kKitEyebrow,
                ),
                const Spacer(),
                if (p.deva.isNotEmpty)
                  Text(
                    p.deva,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                Text(
                  p.roman,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: p.deva.isEmpty ? 22 : 15,
                    fontWeight: FontWeight.w700,
                    color:
                        p.deva.isEmpty ? Colors.white : const Color(0xB3FFFFFF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'hold ${p.hold.toStringAsFixed(p.hold % 1 == 0 ? 0 : 1)}s',
                  style: const TextStyle(
                    fontSize: 10,
                    color: kKitMuted,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.icon,
    this.warn = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KitIconBadge(icon, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditableLabel(
                  'word_detail.Fact',
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: warn
                        ? const Color(0xCCFF8A80)
                        : const Color(0xB3FFFFFF),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
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

class _Chips extends StatelessWidget {
  const _Chips(this.items);
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x24FFFFFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x40FFFFFF)),
            ),
            child: Text(
              c,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

/// Shown instead of the paid parts (recordings, videos, meaning) of a word
/// this account hasn't unlocked. Tapping opens the same lock sheet as the
/// Practice Player: buy the word on Google Play or see the plans.
class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ok = await ensureWordOpen(context, word);
        if (ok && context.mounted) {
          // Entitlements listener also reloads; this covers the same frame.
          final st = context.findAncestorStateOfType<_WordDetailState>();
          st?._loadPaid();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xF0111114),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: const Row(children: [
            KitIconBadge(Icons.lock_outline, size: 46),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditableLabel('word_detail.LockedCard', 'Unlock this word',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    SizedBox(height: 4),
                    EditableLabel('word_detail.LockedCard',
                        'Recordings, video and meaning open when you own the word or have a plan.',
                        style: TextStyle(
                            color: kKitMuted, fontSize: 12.5, height: 1.4)),
                  ]),
            ),
            KitRoundButton(icon: Icons.arrow_forward_rounded),
          ]),
        ),
      ),
    );
  }
}

/// The word's own video (added from Admin → Words / Word requests).
class _WordVideo extends StatelessWidget {
  const _WordVideo({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TabletAspectRatio(
          aspectRatio: 16 / 9,
          child: NwsbVideo(
              asset: url,
              fit: BoxFit.cover,
              showPoster: false,
              obeyMotion: false,
              slot: 'word_detail.WordVideo',
              id: 'video'),
        ),
      );
}

/// One stage of the practice, with its own recording or clip if it has one.
class _Stage extends StatefulWidget {
  const _Stage(
      {required this.n,
      required this.stage,
      required this.word,
      required this.open});
  final int n;
  final WordStage stage;
  final Word word;
  final bool open;

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  AudioPlayer? _player;
  bool _playing = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!widget.open && !_playing) {
      // Locked word: the lock sheet (buy / plans) instead of the recording.
      if (!await ensureWordOpen(context, widget.word) || !mounted) return;
    }
    final p = _player ??= AudioPlayer();
    if (_playing) {
      await p.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    try {
      setState(() => _playing = true);
      // just_audio keeps `playing` true after a clip ends, and play() on a
      // player that is still "playing" returns at once — so the second tap
      // replayed the clip with the button already back on "play" and no way
      // to stop it. Stop first so play() waits for this run again.
      await p.stop();
      await p.setUrl(widget.stage.audio);
      await p.play();
    } catch (_) {}
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.stage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Text('${widget.n}',
                style: const TextStyle(
                    color: Color(0xFF0B0B10),
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('STAGE ${widget.n}', style: kKitEyebrow),
              if (st.title.isNotEmpty)
                Text(st.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
            ]),
          ),
          if (st.audio.startsWith('http'))
            KitRoundButton(
              icon: _playing
                  ? Icons.stop_rounded
                  : (widget.open
                      ? Icons.play_arrow_rounded
                      : Icons.lock_outline),
              size: 46,
              onTap: _toggle,
              label: _playing ? 'Stop' : (widget.open ? 'Play' : 'Unlock'),
            ),
        ]),
        if (st.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(st.text,
              style: const TextStyle(
                  color: Color(0xD9FFFFFF), fontSize: 14, height: 1.45)),
        ],
        if (widget.open && st.video.startsWith('http')) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: TabletAspectRatio(
              aspectRatio: 16 / 9,
              child: NwsbVideo(
                  asset: st.video,
                  fit: BoxFit.cover,
                  showPoster: false,
                  obeyMotion: false,
                  slot: 'word_detail.Stage',
                  id: 'stage${widget.n}'),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Images extends StatelessWidget {
  const _Images({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: TabletAspectRatio(
              aspectRatio: 1,
              child: Image.network(urls[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0x14FFFFFF))),
            ),
          ),
        ),
      );
}
