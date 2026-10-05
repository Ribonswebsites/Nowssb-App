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

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/entitlements.dart';
import '../data/models.dart';
import '../data/word_private.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/content_lock.dart';
import '../admin/template/editable.dart';
import '../media/nwsb_video.dart';

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
      builder: (context, _) => _page(context, Entitlements.instance.canOpenWord(widget.word)),
    );
  }

  Widget _page(BuildContext context, bool open) {
    final word = _word;
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB3060C18), Color(0xFA060C18)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(title: word.word),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      _Headline(word: word),
                      const SizedBox(height: 26),
                      if (!open) ...[
                        _LockedCard(word: word),
                        const SizedBox(height: 22),
                      ],
                      if (open && word.video.startsWith('http')) ...[
                        _WordVideo(url: word.video),
                        const SizedBox(height: 22),
                      ],
                      if (word.description.isNotEmpty) ...[
                        const _SectionLabel('ABOUT THIS WORD'),
                        const SizedBox(height: 10),
                        Text(word.description, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 15, height: 1.5)),
                        const SizedBox(height: 24),
                      ],
                      if (word.parts.isNotEmpty) ...[
                        const _SectionLabel('HOW TO SAY IT'),
                        const SizedBox(height: 12),
                        _Parts(parts: word.parts),
                        const SizedBox(height: 26),
                      ],
                      if (open && word.meaning.isNotEmpty)
                        _Fact(
                          label: 'MEANING',
                          value: word.meaning,
                          icon: Icons.translate,
                        ),
                      if (word.benefit.isNotEmpty)
                        _Fact(
                          label: 'WHAT IT DOES',
                          value: word.benefit,
                          icon: Icons.favorite_border,
                        ),
                      if (word.organ.isNotEmpty)
                        _Fact(
                          label: 'WHERE IT WORKS',
                          value: word.organ,
                          icon: Icons.my_location,
                        ),
                      if (word.mouthPos.isNotEmpty)
                        _Fact(
                          label: 'YOUR MOUTH',
                          value: word.mouthPos,
                          icon: Icons.record_voice_over_outlined,
                        ),
                      if (word.resonance.isNotEmpty)
                        _Fact(
                          label: 'WHERE YOU FEEL IT',
                          value: word.resonance,
                          icon: Icons.graphic_eq,
                        ),
                      if (word.mistake.isNotEmpty)
                        _Fact(
                          label: 'THE COMMON MISTAKE',
                          value: word.mistake,
                          icon: Icons.error_outline,
                          warn: true,
                        ),
                      if (word.tip.isNotEmpty)
                        _Fact(
                          label: 'A TIP',
                          value: word.tip,
                          icon: Icons.lightbulb_outline,
                        ),
                      if (word.stages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const _SectionLabel('STAGES'),
                        const SizedBox(height: 12),
                        for (var i = 0; i < word.stages.length; i++) _Stage(n: i + 1, stage: word.stages[i], word: word, open: open),
                      ],
                      if (word.images.any((u) => u.startsWith('http'))) ...[
                        const SizedBox(height: 14),
                        _Images(urls: [for (final u in word.images) if (u.startsWith('http')) u]),
                      ],
                      if (word.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _Fact(label: 'NOTES', value: word.notes, icon: Icons.sticky_note_2_outlined),
                      ],
                      const SizedBox(height: 18),
                      if (word.categories.isNotEmpty) _Chips(word.categories),
                    ],
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.arrow_back, size: 20, color: NwsbColors.ink),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: EditableLabel('word_detail.TopBar',
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.word});
  final Word word;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word.origin,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
            color: NwsbColors.gold,
          ),
        ),
        const SizedBox(height: 14),
        // The Devanagari first and largest when it exists — it is the word.
        // The roman spelling under it is a reading aid, not the thing itself.
        if (word.deva.isNotEmpty)
          Text(
            word.deva,
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        Text(
          word.word,
          style: TextStyle(
            fontSize: word.deva.isEmpty ? 42 : 26,
            fontWeight: FontWeight.w800,
            color: word.deva.isEmpty ? Colors.white : NwsbColors.goldLight,
            height: 1.1,
            letterSpacing: word.deva.isEmpty ? -0.5 : 1,
          ),
        ),
        if (word.phonetic.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            word.phonetic,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0x99FFFFFF),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return EditableLabel('word_detail.SectionLabel',
      text,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w700,
        color: Color(0x8CFFFFFF),
      ),
    );
  }
}

/// The pronunciation boxes. Three to five, side by side and scrollable —
/// they are read left to right as one word, so they must not wrap into a
/// grid where the reading order stops being obvious.
class _Parts extends StatelessWidget {
  const _Parts({required this.parts});
  final List<WordPart> parts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
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
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: NwsbColors.gold,
                  ),
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
                    color: NwsbColors.goldLight,
                    letterSpacing: 0.5,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warn ? const Color(0x1AE0342B) : const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warn ? const Color(0x33E0342B) : const Color(0x14FFFFFF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 17,
              color: warn ? const Color(0xFFFF8A80) : NwsbColors.goldLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditableLabel('word_detail.Fact',
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    color: warn
                        ? const Color(0xCCFF8A80)
                        : const Color(0x8CFFFFFF),
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
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Text(
              c,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xCCFFFFFF),
                letterSpacing: 0.3,
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x1AE8C77E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x55E8C77E)),
        ),
        child: const Row(children: [
          Icon(Icons.lock_outline, color: Color(0xFFE8C77E), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EditableLabel('word_detail.LockedCard', 'Unlock this word',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              SizedBox(height: 4),
              EditableLabel('word_detail.LockedCard', 'Recordings, video and meaning open when you own the word or have a plan.',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12.5, height: 1.4)),
            ]),
          ),
          Icon(Icons.chevron_right, color: Color(0xFFE8C77E)),
        ]),
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
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: NwsbVideo(asset: url, fit: BoxFit.cover, showPoster: false, slot: 'word_detail.WordVideo', id: 'video'),
        ),
      );
}

/// One stage of the practice, with its own recording or clip if it has one.
class _Stage extends StatefulWidget {
  const _Stage({required this.n, required this.stage, required this.word, required this.open});
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
      await p.setUrl(widget.stage.audio);
      await p.play();
    } catch (_) {}
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.stage;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Color(0x33E8C77E), shape: BoxShape.circle),
            child: Text('${widget.n}', style: const TextStyle(color: Color(0xFFE8C77E), fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(st.title.isEmpty ? '' : st.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          if (st.audio.startsWith('http'))
            IconButton(
              onPressed: _toggle,
              icon: Icon(_playing ? Icons.stop_circle_outlined : (widget.open ? Icons.play_circle_outline : Icons.lock_outline), color: const Color(0xFFE8C77E)),
            ),
        ]),
        if (st.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(st.text, style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 14, height: 1.45)),
        ],
        if (widget.open && st.video.startsWith('http')) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: NwsbVideo(asset: st.video, fit: BoxFit.cover, showPoster: false, slot: 'word_detail.Stage', id: 'stage${widget.n}'),
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
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(urls[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0x14FFFFFF))),
            ),
          ),
        ),
      );
}
