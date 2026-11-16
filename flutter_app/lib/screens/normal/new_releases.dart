/// New releases carousel on the Normal home: a black rounded card with
/// "New releases" / "See all" and a horizontal row of word tiles. Each
/// tile uses the practice player's cover art and a short real subtitle
/// (organ, else meaning, else benefit). Edge fades match the reference
/// mask: a left-to-right gradient that is transparent at the edges and
/// opaque between 15% and 85%.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/models.dart';
import '../practice_player.dart' show playerCoverArtFor;

/// Newest library words first. Brand-new published words are appended
/// to [ContentStore.library], so the end of that list is the latest.
List<Word> newReleaseWords(List<Word> library) {
  final usable = [
    for (final w in library)
      if (w.word.trim().isNotEmpty) w,
  ];
  return usable.reversed.toList();
}

/// A short real line for the tile: organ, else meaning, else benefit.
String newReleaseSubtitle(Word word) {
  for (final s in [word.organ, word.meaning, word.benefit]) {
    final t = s.trim();
    if (t.isNotEmpty) return t;
  }
  return '';
}

/// Queue passed to the practice player so the tapped word plays first,
/// then the rest of the New releases list in the same order.
List<Word> newReleaseQueue(List<Word> items, Word tapped) {
  final i = items.indexWhere((w) => w.key == tapped.key);
  if (i <= 0) return items.isEmpty ? [tapped] : items;
  return [...items.sublist(i), ...items.sublist(0, i)];
}

class NewReleasesCard extends StatelessWidget {
  const NewReleasesCard({
    super.key,
    required this.onWord,
    required this.onSeeAll,
    this.words,
  });

  /// Library to show (tests). Defaults to the live [ContentStore].
  final List<Word>? words;

  final void Function(Word word) onWord;
  final VoidCallback onSeeAll;

  static const _radius = 28.0;
  static const _tile = 78.0;
  static const _gap = 8.0;
  static const _tileRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ContentStore.instance,
      builder: (context, _) {
        final items = newReleaseWords(words ?? ContentStore.instance.library);
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          key: const ValueKey('new-releases'),
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
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'New releases',
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
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          key: const ValueKey('newrel-see-all'),
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
                        stops: [0.0, 0.15, 0.85, 1.0],
                      ).createShader(rect),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0) const SizedBox(width: _gap),
                              _Tile(
                                word: items[i],
                                index: i,
                                size: _tile,
                                radius: _tileRadius,
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
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.word,
    required this.index,
    required this.size,
    required this.radius,
    required this.onTap,
  });

  final Word word;
  final int index;
  final double size;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final art = playerCoverArtFor(word, index);
    final sub = newReleaseSubtitle(word);
    return GestureDetector(
      key: ValueKey('newrel-tile-${word.key}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Image.asset(
                  art,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF1A1A1A)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: size,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  word.word,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ),
            ),
            if (sub.isNotEmpty)
              SizedBox(
                width: size,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    sub,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
