/// LA Art Box–style overlapping vertical cards.
///
/// Cream field, stacked left title, four coloured books on the right using
/// the four meditating portraits. Fashion wraps it in glass; Normal in neu.
library;

import 'package:flutter/material.dart';

import 'glass_wrap.dart';
import 'neumorphic.dart';
import '../theme/tokens.dart';

class StoriesFindYouBanner extends StatelessWidget {
  const StoriesFindYouBanner({
    super.key,
    this.neumorphic = false,
    this.onTap,
  });

  final bool neumorphic;
  final VoidCallback? onTap;

  static const _cream = Color(0xFFF6EDE4);
  static const _ink = Color(0xFF111111);

  static const _cards = <_StoryCard>[
    _StoryCard(
      color: Color(0xFFE07A32),
      image: 'assets/banners/stories/prana.png',
      kicker: 'PRANA',
      title: 'SOUND\nRITUAL',
    ),
    _StoryCard(
      color: Color(0xFFE8C12A),
      image: 'assets/banners/stories/pitta.png',
      kicker: 'PITTA',
      title: 'LIGHT\nBODY',
    ),
    _StoryCard(
      color: Color(0xFFC43A32),
      image: 'assets/banners/stories/soma.png',
      kicker: 'SOMA',
      title: 'WORD\nSCIENCE',
    ),
    _StoryCard(
      color: Color(0xFF5B8FB8),
      image: 'assets/banners/stories/aura.png',
      kicker: 'AURA',
      title: 'THE\nFUTURE',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final inner = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: _cream,
        padding: const EdgeInsets.fromLTRB(18, 22, 10, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SOUND\nTHAT\nFINDS YOU',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 28,
                      height: 0.92,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'There are no limitations to the\nfrequency at NowssB.',
                    style: TextStyle(
                      color: Color(0xFF3A3A3A),
                      fontSize: 10,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.arrow_forward, size: 18, color: _ink),
                ],
              ),
            ),
            const Expanded(flex: 14, child: _StoryStack()),
          ],
        ),
      ),
    );

    if (neumorphic) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: NeuCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(NwsbRadius.card),
            child: inner,
          ),
        ),
      );
    }
    return GlassWrap(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: inner,
      ),
    );
  }
}

class _StoryCard {
  const _StoryCard({
    required this.color,
    required this.image,
    required this.kicker,
    required this.title,
  });
  final Color color;
  final String image;
  final String kicker;
  final String title;
}

class _StoryStack extends StatelessWidget {
  const _StoryStack();

  @override
  Widget build(BuildContext context) {
    const cards = StoriesFindYouBanner._cards;
    return SizedBox(
      height: 268,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final cardW = (w * 0.42).clamp(72.0, 96.0);
          final step = (w - cardW) / 3.2;
          const heights = [198.0, 246.0, 232.0, 214.0];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < cards.length; i++)
                Positioned(
                  left: i * step,
                  bottom: i == 1 ? 4 : (i == 2 ? 10 : 18),
                  child: _Book(
                    spec: cards[i],
                    width: cardW,
                    height: heights[i],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Book extends StatelessWidget {
  const _Book({
    required this.spec,
    required this.width,
    required this.height,
  });
  final _StoryCard spec;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: spec.color,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(2, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.kicker,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spec.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Image.asset(
              spec.image,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
