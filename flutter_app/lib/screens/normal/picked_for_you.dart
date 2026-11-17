/// "Picked for you" on the Normal home: a second black card in the New
/// releases family, set lower on the page. It differs on purpose:
///   * one big landscape lead tile, then smaller landscape tiles;
///   * each tile is headed by its body area (organ), word underneath;
///   * a subtitle line naming today's body areas.
/// Same black container and edge fade. Its order is its own daily shuffle,
/// and its first tiles never repeat New releases' first tiles that day.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/models.dart';
import '../practice_player.dart' show playerCoverArtFor;
import 'new_releases.dart';

/// How many New releases tiles lead the row (and so must not lead here).
const kPickedAvoidLead = 3;

/// Words for the Picked for you row on [on] (default: today). Every
/// usable word once, in a daily order of its own; the words leading New
/// releases that day are moved to the back so the two rows open differently.
List<Word> pickedForYouWords(List<Word> library, {DateTime? on}) {
  final day = on ?? DateTime.now();
  final usable = [
    for (final w in library)
      if (w.word.trim().isNotEmpty) w,
  ];
  final shuffled = seededOrder(usable, homeDayNumber(day) * 104729 + 3);
  final lead = {
    for (final w in newReleaseWords(library, on: day).take(kPickedAvoidLead))
      w.key,
  };
  return [
    for (final w in shuffled)
      if (!lead.contains(w.key)) w,
    for (final w in shuffled)
      if (lead.contains(w.key)) w,
  ];
}

/// The body area a tile is headed by: organ, else meaning, else ''.
String pickedArea(Word w) {
  for (final s in [w.organ, w.meaning]) {
    final t = s.trim();
    if (t.isNotEmpty) return t;
  }
  return '';
}

/// "Brain, Liver · Digestion and more": the first two areas in the row.
String pickedSubtitle(List<Word> items) {
  final areas = <String>[];
  for (final w in items) {
    final a = pickedArea(w);
    if (a.isNotEmpty && !areas.contains(a)) areas.add(a);
    if (areas.length == 2) break;
  }
  if (areas.isEmpty) return 'By body area';
  return 'By body area · ${areas.join(', ')}';
}

class PickedForYouCard extends StatelessWidget {
  const PickedForYouCard({
    super.key,
    required this.onWord,
    required this.onSeeAll,
    this.words,
    this.today,
  });

  final List<Word>? words;
  final DateTime? today;
  final void Function(Word word) onWord;
  final VoidCallback onSeeAll;

  static const _radius = 28.0;
  static const _gap = 10.0;
  static const _leadW = 220.0;
  static const _leadH = 136.0;
  static const _tileW = 150.0;
  static const _tileH = 96.0;

  @override
  Widget build(BuildContext context) {
    return DailyRebuild(
      today: today,
      builder: (context, day) => ListenableBuilder(
        listenable: ContentStore.instance,
        builder: (context, _) {
          final items = pickedForYouWords(
            words ?? ContentStore.instance.library,
            on: day,
          );
          if (items.isEmpty) return const SizedBox.shrink();
          return Padding(
            key: const ValueKey('picked-for-you'),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24000000),
                    offset: Offset(7, 7),
                    blurRadius: 18,
                  ),
                  BoxShadow(
                    color: Color(0xFFFFFFFF),
                    offset: Offset(-7, -7),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(_radius),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Picked for you',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  pickedSubtitle(items),
                                  key: const ValueKey('picked-subtitle'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF9A9A9A),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            key: const ValueKey('picked-see-all'),
                            onTap: onSeeAll,
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 2,
                              ),
                              child: Text(
                                'See all',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFFB3B3B3),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0x00000000),
                            Color(0xFF000000),
                            Color(0xFF000000),
                            Color(0x00000000),
                          ],
                          stops: [0.0, 0.08, 0.85, 1.0],
                        ).createShader(rect),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          // Start past the left fade so the lead tile and its
                          // label read in full; later tiles still fade out.
                          padding: const EdgeInsets.only(left: 18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < items.length; i++) ...[
                                if (i > 0) const SizedBox(width: _gap),
                                _PickTile(
                                  word: items[i],
                                  index: i,
                                  width: i == 0 ? _leadW : _tileW,
                                  height: i == 0 ? _leadH : _tileH,
                                  lead: i == 0,
                                  onTap: () => onWord(items[i]),
                                ),
                              ],
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
        },
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.word,
    required this.index,
    required this.width,
    required this.height,
    required this.lead,
    required this.onTap,
  });

  final Word word;
  final int index;
  final double width;
  final double height;
  final bool lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final art = playerCoverArtFor(word, index);
    final area = pickedArea(word);
    return GestureDetector(
      key: ValueKey('picked-tile-${word.key}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: width,
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(lead ? 20 : 16),
                child: Image.asset(
                  art,
                  fit: BoxFit.cover,
                  // Landscape crop from the top: the word lines and the
                  // face both stay in frame.
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF1A1A1A)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (area.isNotEmpty)
              SizedBox(
                width: width,
                child: Text(
                  area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: lead ? 13 : 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ),
            SizedBox(
              width: width,
              child: Text(
                word.word,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9A9A9A),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
