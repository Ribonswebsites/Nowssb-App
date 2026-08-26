/// The Sound Library — every word you can hear, and the state of its audio.
///
/// The website's Sound Library is "your saved sentences, subscription words
/// and purchased frequencies, all in one place". The honest version of that
/// today is: every word in the library, with what recording it actually
/// carries. A word record has `audioMale`, `audioFemale`, and optionally a
/// recording per pronunciation part — and the app cannot play any of it yet.
///
/// So this screen shows what IS there rather than pretending. A word with a
/// recording says so; a word without says so too. That is more useful than a
/// row of play buttons that do nothing, and when audio lands the rows here
/// are already the right rows.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/intro_gate.dart';
import '../widgets/page_shell.dart';
import 'word_detail.dart';

class SoundLibraryScreen extends StatefulWidget {
  const SoundLibraryScreen({super.key});

  @override
  State<SoundLibraryScreen> createState() => _SoundLibraryScreenState();
}

class _SoundLibraryScreenState extends State<SoundLibraryScreen> {
  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  bool _hasAudio(Word w) =>
      w.audioMale.isNotEmpty ||
      w.audioFemale.isNotEmpty ||
      w.parts.any((p) => p.audio.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final all = ContentStore.instance.library;
    final withAudio = all.where(_hasAudio).toList();

    return IntroGate(
      tag: 'Personal Collection',
      eyebrow: 'Shabdapathy · Sound Archive',
      title: 'Sound\nLibrary',
      body: 'Your saved sentences, subscription words, and purchased '
          'frequencies — all in one place.',
      stats: [
        '${all.length} words',
        '${withAudio.length} with a recording',
      ],
      art: 'assets/store/intro-words.webp',
      enterLabel: 'OPEN LIBRARY',
      child: PageShell(
        eyebrow: 'Sound Archive',
        title: 'Sound Library',
        film: 'assets/video/sound-library-banner.mp4',
        onBack: () => Navigator.of(context).maybePop(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.list(children: [
              const _AudioNote(),
              const SizedBox(height: 20),
              if (all.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: Text('Nothing in the archive yet.',
                        style: TextStyle(color: Color(0x8CFFFFFF))),
                  ),
                )
              else
                for (final w in all)
                  WordRow(
                    word: w.word,
                    deva: w.deva,
                    sub: w.organ.isNotEmpty ? w.organ : w.meaning,
                    trailing: _AudioMark(has: _hasAudio(w)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => WordDetail(word: w)),
                    ),
                  ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _AudioMark extends StatelessWidget {
  const _AudioMark({required this.has});
  final bool has;

  @override
  Widget build(BuildContext context) {
    return Icon(
      has ? Icons.graphic_eq : Icons.volume_off_outlined,
      size: 17,
      color: has ? NwsbColors.goldLight : const Color(0x40FFFFFF),
    );
  }
}

class _AudioNote extends StatelessWidget {
  const _AudioNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: NwsbColors.goldLight),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Playback is not built yet. A word marked with a waveform has '
              'a recording in its record and will play as soon as it is — '
              'the rest carry only their written form.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0x99FFFFFF),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
