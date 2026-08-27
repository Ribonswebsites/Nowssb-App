/// A real audible native practice session.
///
/// The player uses the device text-to-speech engine to voice each current
/// practice word. Completion is persisted only after speech finishes, so the
/// dashboard reflects completed playback rather than a static placeholder.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/models.dart';
import '../data/practice_progress.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';

class PracticePlayerScreen extends StatefulWidget {
  const PracticePlayerScreen({super.key, required this.words, required this.title});

  final List<Word> words;
  final String title;

  @override
  State<PracticePlayerScreen> createState() => _PracticePlayerScreenState();
}

class _PracticePlayerScreenState extends State<PracticePlayerScreen> {
  final FlutterTts _tts = FlutterTts();
  var _index = 0;
  var _playing = false;
  var _completed = false;
  String? _error;

  Word get _word => widget.words[_index];

  @override
  void initState() {
    super.initState();
    unawaited(PracticeProgress.instance.start());
    unawaited(_prepareAndPlay());
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    super.dispose();
  }

  Future<void> _prepareAndPlay() async {
    if (_playing || widget.words.isEmpty) return;
    setState(() {
      _playing = true;
      _completed = false;
      _error = null;
    });
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.34);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.stop();
      await _tts.speak(_word.word);
      await PracticeProgress.instance.recordCompletedWord(_word);
      if (mounted) setState(() => _completed = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Your device could not start voice playback. Check that text-to-speech is enabled.');
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _next() async {
    if (_index >= widget.words.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index += 1);
    await _prepareAndPlay();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(
        backgroundColor: NwsbColors.deep,
        appBar: AppBar(backgroundColor: NwsbColors.deep, foregroundColor: Colors.white),
        body: const Center(child: Text('Choose words for your routine before starting a session.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
      );
    }

    final progress = '${_index + 1} of ${widget.words.length}';
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      appBar: AppBar(
        backgroundColor: NwsbColors.deep,
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackdrop()),
          SafeArea(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(progress.toUpperCase(), style: const TextStyle(color: NwsbColors.goldLight, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
                child: Column(
                  children: [
                    Icon(_playing ? Icons.volume_up_rounded : Icons.play_circle_fill_rounded, size: 54, color: NwsbColors.goldLight),
                    const SizedBox(height: 22),
                    Text(_word.word, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    Text(_word.phonetic.isEmpty ? 'Listen, then repeat at your own pace.' : _word.phonetic, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 15)),
                    const SizedBox(height: 18),
                    Text(_playing ? 'Playing now…' : _completed ? 'Completed and added to your progress.' : 'Ready to play.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0x8CFFFFFF), height: 1.5)),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFB4B4), height: 1.4)),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _playing ? null : _prepareAndPlay,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Play again'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0x66FFFFFF)), padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _playing ? null : _next,
                icon: Icon(_index >= widget.words.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded),
                label: Text(_index >= widget.words.length - 1 ? 'Finish session' : 'Next word'),
                style: ElevatedButton.styleFrom(backgroundColor: NwsbColors.goldLight, foregroundColor: NwsbColors.deep, padding: const EdgeInsets.symmetric(vertical: 17)),
              ),
            ],
          ),
            ),
          ),
        ],
      ),
    );
  }
}

class PracticeProgressScreen extends StatelessWidget {
  const PracticeProgressScreen({super.key, required this.words});

  final List<Word> words;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PracticeProgress.instance,
      builder: (context, _) {
        final progress = PracticeProgress.instance;
        final completed = progress.completedTodayFor(words);
        final goal = words.isEmpty ? 0 : (completed / words.length * 100).round().clamp(0, 100);
        return Scaffold(
          backgroundColor: NwsbColors.deep,
          appBar: AppBar(backgroundColor: NwsbColors.deep, foregroundColor: Colors.white, title: const Text('Your progress')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('LIVE PRACTICE DATA', style: TextStyle(color: NwsbColors.goldLight, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                Text(progress.totalSessions == 0 ? 'Your first completed playback will appear here.' : 'Your progress is built from completed sessions on this device.', style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 17, height: 1.45)),
                const SizedBox(height: 26),
                _ProgressStat(value: '${progress.todaySessions}', label: 'Sessions today'),
                _ProgressStat(value: '${progress.totalSessions}', label: 'Total sessions'),
                _ProgressStat(value: '${progress.streak}', label: 'Day streak'),
                _ProgressStat(value: words.isEmpty ? '—' : '$goal%', label: words.isEmpty ? 'Today’s goal' : '$completed of ${words.length} words today'),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x24FFFFFF))),
        child: Row(children: [Text(value, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 26, fontWeight: FontWeight.w800)), const SizedBox(width: 16), Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)))]),
      );
}
