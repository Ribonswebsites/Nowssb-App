/// Practice — today's session.
///
/// The website picks the session from the hour: a morning ritual, an
/// afternoon session, an evening practice, a night restoration. Same three
/// windows here as `getTimeSlot` in app/js/part037.js, and the words are
/// filtered by the `time` field every word already carries — which is the
/// point of having ported the model rather than a list of names.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/page_shell.dart';
import 'practice_player.dart';
import 'word_detail.dart';

String nwsbSlot([DateTime? at]) {
  final h = (at ?? DateTime.now()).hour;
  if (h < 12) return 'morning';
  if (h < 17) return 'afternoon';
  if (h < 21) return 'evening';
  return 'night';
}

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
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
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

    return PageShell(
      eyebrow: 'Today',
      title: _slotTitle[slot] ?? 'Practice',
      film: 'assets/video/player-liquid-splash.mp4',
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(children: [
            if (all.isEmpty)
              const _Empty()
            else ...[
              _SessionCard(
                count: sessionWords.length,
                slot: slot,
                onStart: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PracticePlayerScreen(
                      words: sessionWords,
                      title: _slotTitle[slot] ?? 'Practice',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const DarkHead(
                eyebrow: 'Tap a word to open it',
                title: 'This session',
                icon: Icons.play_circle_outline,
              ),
              const SizedBox(height: 14),
              for (final w in now) _row(context, w),
              if (rest.isNotEmpty) ...[
                const SizedBox(height: 22),
                const DarkHead(
                  eyebrow: 'Every other word you have',
                  title: 'Also today',
                  icon: Icons.library_music_outlined,
                ),
                const SizedBox(height: 14),
                for (final w in rest) _row(context, w),
              ],
            ],
          ]),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, Word w) => WordRow(
        word: w.word,
        deva: w.deva,
        sub: w.organ.isNotEmpty ? w.organ : w.meaning,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WordDetail(word: w)),
        ),
      );
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.count,
    required this.slot,
    required this.onStart,
  });
  final int count;
  final String slot;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: NwsbColors.goldLight,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count == 1 ? 'word' : 'words',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0x8CFFFFFF),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Aligned to your $slot — say each one on the exhale, and hold '
                  'the last sound.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xCCFFFFFF),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 19),
                  label: const Text('Start Player'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NwsbColors.goldLight,
                    foregroundColor: NwsbColors.deep,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
          Text(
            'No words yet.',
            style: TextStyle(fontSize: 15, color: Color(0xB3FFFFFF)),
          ),
          SizedBox(height: 6),
          Text(
            'The library loads from the studio. What ships with the app '
            'should be here already — if this is empty, the bundled copy '
            'did not read.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12, color: Color(0x66FFFFFF), height: 1.5),
          ),
        ],
      ),
    );
  }
}
