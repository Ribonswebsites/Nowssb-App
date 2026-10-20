/// 10-level changer for Word Detail. Each level maps to the word's stage of
/// the same index; levels with no stage yet say so plainly.
library;

import 'package:flutter/material.dart';

import '../data/models.dart';

class WordLevelChanger extends StatefulWidget {
  const WordLevelChanger({super.key, required this.word, required this.open, this.levels = 10});

  final Word word;
  final bool open;
  final int levels;

  @override
  State<WordLevelChanger> createState() => _WordLevelChangerState();
}

class _WordLevelChangerState extends State<WordLevelChanger> {
  int _level = 1;

  void _set(int n) => setState(() => _level = n.clamp(1, widget.levels));

  @override
  Widget build(BuildContext context) {
    final stages = widget.word.stages;
    final stage = _level <= stages.length ? stages[_level - 1] : null;
    final String body;
    if (stage == null) {
      body = 'Level $_level isn\'t available for this word yet.';
    } else if (!widget.open && _level > 1) {
      body = 'Unlock this word to practise level $_level.';
    } else {
      body = stage.text.isEmpty ? stage.title : stage.text;
    }
    return Container(
      key: const Key('wordLevelChanger'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x44FFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Semantics(
            button: true,
            label: 'Previous level',
            child: IconButton(
              key: const Key('wordLevelPrev'),
              onPressed: _level > 1 ? () => _set(_level - 1) : null,
              icon: const Icon(Icons.chevron_left, color: Colors.white),
            ),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              label: 'Level $_level of ${widget.levels}',
              child: ExcludeSemantics(
                child: Text('Level $_level of ${widget.levels}',
                    key: const Key('wordLevelLabel'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Next level',
            child: IconButton(
              key: const Key('wordLevelNext'),
              onPressed: _level < widget.levels ? () => _set(_level + 1) : null,
              icon: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.levels,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final n = i + 1;
              final sel = n == _level;
              return Semantics(
                button: true,
                selected: sel,
                label: 'Level $n',
                child: GestureDetector(
                  key: Key('wordLevel$n'),
                  onTap: () => _set(n),
                  child: Container(
                    width: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel ? Colors.white : const Color(0x22FFFFFF),
                    ),
                    child: Text('$n',
                        style: TextStyle(
                            color: sel ? Colors.black : Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (stage != null)
          Text(stage.title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(body, key: const Key('wordLevelBody'),
            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, height: 1.4)),
      ]),
    );
  }
}
