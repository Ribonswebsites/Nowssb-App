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
import 'package:video_player/video_player.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/settings.dart';
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
  VideoPlayerController? _audio;
  String? _playingWord;

  Future<void> _playWord(Word word) async {
    WordPart? part;
    for (final candidate in word.parts) {
      if (candidate.audio.isNotEmpty) {
        part = candidate;
        break;
      }
    }
    final url = part?.audio.isNotEmpty == true
        ? part!.audio
        : (word.audioMale.isNotEmpty ? word.audioMale : word.audioFemale);
    if (url.isEmpty) return;
    if (_playingWord == word.word) {
      await _audio?.pause();
      if (mounted) setState(() => _playingWord = null);
      return;
    }
    await _audio?.dispose();
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      await controller.setVolume(Settings.instance.volume);
      await controller.setPlaybackSpeed(Settings.instance.speed);
      await controller.play();
      controller.addListener(() {
        if (!mounted) return;
        final value = controller.value;
        if (!value.isPlaying && value.position >= value.duration && value.duration > Duration.zero) {
          setState(() { if (_playingWord == word.word) _playingWord = null; });
        }
      });
      _audio = controller;
      if (mounted) setState(() => _playingWord = word.word);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _playingWord = null);
    }
  }
  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    _audio?.dispose();
    super.dispose();
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
                    trailing: _AudioMark(has: _hasAudio(w), playing: _playingWord == w.word, onTap: () => _playWord(w)),
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
  const _AudioMark({required this.has, required this.playing, required this.onTap});
  final bool has;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: has ? (playing ? 'Pause recording' : 'Play recording') : 'No recording',
      onPressed: has ? onTap : null,
      icon: Icon(playing ? Icons.pause_circle_outline : (has ? Icons.play_circle_outline : Icons.volume_off_outlined), size: 21, color: has ? NwsbColors.goldLight : const Color(0x40FFFFFF)),
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
              'Tap the waveform on any recorded word to play it. Your AURA '
              'speed and volume preferences are used for playback; unrecorded '
              'words remain available for reading and detail.',
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
