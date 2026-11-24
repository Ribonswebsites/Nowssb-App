/// The Sound Library's "Recorded stages" card: every library word that ships
/// with the client's own stage recordings, with its progress and a way
/// straight into practice. Shows nothing when there are none.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/word_photos.dart';
import '../../widgets/restyle_kit.dart';
import 'stage_pack.dart';
import 'stage_practice_screen.dart';
import 'stage_progress.dart';

class StagedWordsCard extends StatefulWidget {
  const StagedWordsCard({super.key, required this.words, required this.onOpenWord});

  final List<Word> words;
  final ValueChanged<Word> onOpenWord;

  @override
  State<StagedWordsCard> createState() => _StagedWordsCardState();
}

class _StagedWordsCardState extends State<StagedWordsCard> {
  @override
  void initState() {
    super.initState();
    unawaited(StageProgressStore.instance.ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final staged = [
      for (final w in widget.words)
        if (StagePack.forWord(w) case final p?) (w, p)
    ];
    if (staged.isEmpty) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: StageProgressStore.instance,
      builder: (context, _) => KitPane(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        eyebrow: 'Recorded stages',
        title: 'Listen, speak, get scored',
        mark: NwsbMarks.stages,
        child: Column(children: [for (final (w, p) in staged) _row(context, w, p)]),
      ),
    );
  }

  Widget _row(BuildContext context, Word w, StagePack p) {
    final prog = StageProgressStore.instance;
    final passed = prog.passedCount(p.wordKey);
    final name = w.word.isEmpty ? w.word : '${w.word[0].toUpperCase()}${w.word.substring(1).toLowerCase()}';
    return InkWell(
      key: ValueKey('staged-word-${w.key}'),
      borderRadius: BorderRadius.circular(14),
      onTap: () => widget.onOpenWord(w),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: wordPhotoFor(w.word) != null
                      ? Image.asset(wordPhotoFor(w.word)!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => KitWordArt(word: w.word, deva: w.deva))
                      : KitWordArt(word: w.word, deva: w.deva))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('${p.stages.length} teacher-recorded stages · $passed passed',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kKitMuted, fontSize: 12.5)),
            ]),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            shape: const StadiumBorder(),
            child: InkWell(
              key: ValueKey('staged-practise-${w.key}'),
              customBorder: const StadiumBorder(),
              onTap: () => unawaited(openStagePractice(context, w)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.mic_rounded, size: 16, color: Color(0xFF0B0B10)),
                  SizedBox(width: 6),
                  Text('Practise',
                      style: TextStyle(color: Color(0xFF0B0B10), fontWeight: FontWeight.w800, fontSize: 13.5)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
