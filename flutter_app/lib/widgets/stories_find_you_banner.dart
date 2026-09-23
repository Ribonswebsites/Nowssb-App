/// LA Art Box–style overlapping vertical cards.
///
/// Black field, stacked left title, four coloured books on the right using
/// the four meditating portraits. Fashion wraps it in glass; Normal in neu.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static const _black = Color(0xFF050505);
  static const _ink = Colors.white;

  static const _cards = <_StoryCard>[
    _StoryCard(
      color: Color(0xFFE07A32),
      image: 'assets/banners/stories/prana.png',
      kicker: 'PRANA',
      title: 'SOUND\nRITUAL',
      layout: _BookLayout.photoBottom,
    ),
    _StoryCard(
      color: Color(0xFFE8C12A),
      image: 'assets/banners/stories/pitta.png',
      kicker: 'PITTA',
      title: 'LIGHT\nBODY',
      layout: _BookLayout.photoTop,
    ),
    _StoryCard(
      color: Color(0xFFC43A32),
      image: 'assets/banners/stories/soma.png',
      kicker: 'SOMA',
      title: 'WORD\nSCIENCE',
      layout: _BookLayout.whiteInset,
    ),
    _StoryCard(
      color: Color(0xFF5B8FB8),
      image: 'assets/banners/stories/aura.png',
      kicker: 'AURA',
      title: 'THE\nFUTURE',
      layout: _BookLayout.photoBottom,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final inner = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRect(
          child: Container(
          color: _black,
          padding: const EdgeInsets.fromLTRB(16, 20, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SOUND\nTHAT\nFINDS YOU',
                      style: GoogleFonts.anton(
                        color: _ink,
                        fontSize: 31,
                        height: 0.88,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      'There are no limitations to the\nfrequency at NowssB.',
                      style: GoogleFonts.libreBaskerville(
                        color: Colors.white,
                        fontSize: 9,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const Expanded(flex: 15, child: _StoryStack()),
            ],
          ),
        ),
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

enum _BookLayout { photoBottom, photoTop, whiteInset }

class _StoryCard {
  const _StoryCard({
    required this.color,
    required this.image,
    required this.kicker,
    required this.title,
    required this.layout,
  });
  final Color color;
  final String image;
  final String kicker;
  final String title;
  final _BookLayout layout;
}

class _StoryStack extends StatelessWidget {
  const _StoryStack();

  @override
  Widget build(BuildContext context) {
    const cards = StoriesFindYouBanner._cards;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight.isFinite ? c.maxHeight : 300.0;
        final cardW = (w * 0.38).clamp(70.0, 98.0);
        final step = ((w - cardW) / 3.05).clamp(28.0, 62.0);
        final heights = [h * .76, h, h * .92, h * .83];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < cards.length; i++)
              Positioned(
                left: i * step,
                bottom: 0,
                child: _Book(
                  spec: cards[i],
                  width: cardW,
                  height: heights[i],
                ),
              ),
          ],
        );
      },
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
    final kicker = Text(
      spec.kicker,
      style: GoogleFonts.dmSans(
        color: Colors.white,
        fontSize: 7.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
    final title = Text(
      spec.title,
      style: GoogleFonts.anton(
        color: Colors.white,
        fontSize: 15,
        height: 0.92,
        letterSpacing: 0.2,
      ),
    );

    late final Widget body;
    switch (spec.layout) {
      case _BookLayout.photoBottom:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [kicker, const SizedBox(height: 4), title],
              ),
            ),
            Expanded(child: _photo()),
          ],
        );
      case _BookLayout.photoTop:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: height * 0.34, child: _photo()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [kicker, const SizedBox(height: 4), title],
                  ),
                ),
              ),
            ),
          ],
        );
      case _BookLayout.whiteInset:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [kicker, const SizedBox(height: 4), title],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 0, 7, 8),
                child: ColoredBox(
                  color: Colors.white,
                  child: _photo(alignment: Alignment.topCenter),
                ),
              ),
            ),
          ],
        );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: spec.color,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(2, 8),
          ),
        ],
      ),
      child: body,
    );
  }

  Widget _photo({Alignment alignment = const Alignment(0, -0.55)}) {
    return Image.asset(
      spec.image,
      fit: BoxFit.cover,
      alignment: alignment,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
