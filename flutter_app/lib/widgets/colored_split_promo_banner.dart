/// YouTube Music–style split promotional banner.
///
/// Left: dark panel with title + outlined CTA pill.
/// Right: solid COLOURED panel with a studio graphic (black-bg PNG).
/// Sharp vertical split, rounded card. Not the Sound Library Meaning card.
library;

import 'package:flutter/material.dart';

/// Bundled right-side studio shots — commit as-is, never recompress.
abstract final class SplitPromoArts {
  static const blondeBlazer = 'assets/banners/promo/split-blonde-blazer.png';
  static const whiteRobot = 'assets/banners/promo/split-white-robot.png';
  static const egyptianGold = 'assets/banners/promo/split-egyptian-gold.png';
  static const redHairBlazer = 'assets/banners/promo/split-red-hair-blazer.png';
  static const robotLookback = 'assets/banners/promo/split-robot-lookback.png';
  static const meaningsDevice = 'assets/meanings/meanings-device.png';
  static const ebooksProduct = 'assets/ebooks/ebooks-headphones.jpg';
  static const robotLotus = 'assets/banners/promo/split-robot-lotus.png';
  static const blondeLotus = 'assets/banners/promo/split-blonde-lotus.png';
  static const egyptianLotus = 'assets/banners/promo/split-egyptian-lotus.png';
  static const redLotus = 'assets/banners/promo/split-red-lotus.png';
  static const pose01 = 'assets/banners/promo/pose-01.png';
  static const pose02 = 'assets/banners/promo/pose-02.png';
  static const pose03 = 'assets/banners/promo/pose-03.png';
  static const pose04 = 'assets/banners/promo/pose-04.png';
  static const pose05 = 'assets/banners/promo/pose-05.png';
  static const pose06 = 'assets/banners/promo/pose-06.png';
  static const pose07 = 'assets/banners/promo/pose-07.png';
  static const pose08 = 'assets/banners/promo/pose-08.png';
  static const pose09 = 'assets/banners/promo/pose-09.png';
  static const pose10 = 'assets/banners/promo/pose-10.png';

  static const all = <String>[
    blondeBlazer,
    whiteRobot,
    egyptianGold,
    redHairBlazer,
    robotLookback,
    robotLotus,
    blondeLotus,
    egyptianLotus,
    redLotus,
  ];
}

/// Per-surface presets: distinct right-panel colours, rotating clean studio arts.
/// CTAs must open a useful destination for THAT surface — never "Explore Word
/// Store" when already on Word Atelier / wrong destination for the page.
enum SplitPromoSurface {
  soundLibrary,
  morningRitual,
  meaningStore,
  wordAtelier,
  signatureStore,
  fashionHome,
  ebooksStore,
  normalHome,
  profile,
  progress,
  coach,
  library,
  sentenceBuilder,
  requestWords,
  storeHome,
  selectLevel,
  readerHub,
}

class SplitPromoSpec {
  const SplitPromoSpec({
    required this.title,
    required this.cta,
    required this.leftColor,
    required this.rightColor,
    required this.art,
    this.onTap,
  });

  final String title;
  final String cta;
  final Color leftColor;
  final Color rightColor;
  final String art;
  final VoidCallback? onTap;

  static SplitPromoSpec forSurface(
    SplitPromoSurface surface, {
    VoidCallback? onTap,
  }) {
    switch (surface) {
      case SplitPromoSurface.soundLibrary:
        return SplitPromoSpec(
          title: 'Practice your\ntones today.',
          cta: 'Begin Practice',
          leftColor: const Color(0xFF1A3A3C),
          rightColor: const Color(0xFF2EC4B6),
          art: SplitPromoArts.blondeLotus,
          onTap: onTap,
        );
      case SplitPromoSurface.morningRitual:
        return SplitPromoSpec(
          title: 'Expand your\nSound Library.',
          cta: 'Open Sound Library',
          leftColor: const Color(0xFF2A1B4D),
          rightColor: const Color(0xFF7C4DFF),
          art: SplitPromoArts.robotLotus,
          onTap: onTap,
        );
      case SplitPromoSurface.meaningStore:
        return SplitPromoSpec(
          title: 'Signature rarities\nawait you.',
          cta: 'View Signatures',
          // Teal + amber — not purple-on-purple empty.
          leftColor: const Color(0xFF0E2F2C),
          rightColor: const Color(0xFFE8A838),
          art: SplitPromoArts.meaningsDevice,
          onTap: onTap,
        );
      case SplitPromoSurface.wordAtelier:
        return SplitPromoSpec(
          title: 'Meanings unlock\neach word.',
          cta: 'Browse meanings',
          leftColor: const Color(0xFF4A2418),
          rightColor: const Color(0xFFE07A3D),
          art: SplitPromoArts.redLotus,
          onTap: onTap,
        );
      case SplitPromoSurface.signatureStore:
        return SplitPromoSpec(
          title: 'Request a word\nof your own.',
          cta: 'Request a word',
          leftColor: const Color(0xFF3D2914),
          rightColor: const Color(0xFFD4A017),
          art: SplitPromoArts.whiteRobot,
          onTap: onTap,
        );
      case SplitPromoSurface.fashionHome:
        // Black-bg lookback cutout ON pink panel (not black) — no busy plate in PNG.
        return SplitPromoSpec(
          title: 'Start today\'s\npractice now.',
          cta: 'Begin Practice',
          leftColor: const Color(0xFF4A1838),
          rightColor: const Color(0xFFE85D9A),
          art: SplitPromoArts.robotLookback,
          onTap: onTap,
        );
      case SplitPromoSurface.ebooksStore:
        return SplitPromoSpec(
          title: 'Dig into the\nSound Library.',
          cta: 'Open Sound Library',
          leftColor: const Color(0xFF143028),
          rightColor: const Color(0xFF2D6A4F),
          art: SplitPromoArts.ebooksProduct,
          onTap: onTap,
        );
      case SplitPromoSurface.normalHome:
        // ESSENTIALS / Normal home — never self-referential Word Store CTA.
        return SplitPromoSpec(
          title: 'Open today\'s\nSound Library.',
          cta: 'Open Sound Library',
          leftColor: const Color(0xFF1A3348),
          rightColor: const Color(0xFF2E86C1),
          art: SplitPromoArts.redHairBlazer,
          onTap: onTap,
        );
      case SplitPromoSurface.profile:
        return SplitPromoSpec(
          title: 'Start today\'s\npractice now.',
          cta: 'Begin Practice',
          leftColor: const Color(0xFF1A2A3C),
          rightColor: const Color(0xFF3D8BDB),
          art: SplitPromoArts.blondeBlazer,
          onTap: onTap,
        );
      case SplitPromoSurface.progress:
        return SplitPromoSpec(
          title: 'Keep your\nstreak alive.',
          cta: 'Begin Practice',
          leftColor: const Color(0xFF2A1838),
          rightColor: const Color(0xFF9B59B6),
          art: SplitPromoArts.whiteRobot,
          onTap: onTap,
        );
      case SplitPromoSurface.coach:
        return SplitPromoSpec(
          title: 'Dig into the\nSound Library.',
          cta: 'Open Sound Library',
          leftColor: const Color(0xFF183028),
          rightColor: const Color(0xFF27AE60),
          art: SplitPromoArts.egyptianGold,
          onTap: onTap,
        );
      case SplitPromoSurface.library:
        return SplitPromoSpec(
          title: 'Start today\'s\npractice now.',
          cta: 'Begin Practice',
          leftColor: const Color(0xFF1A2838),
          rightColor: const Color(0xFF5DADE2),
          art: SplitPromoArts.blondeLotus,
          onTap: onTap,
        );
      case SplitPromoSurface.sentenceBuilder:
        return SplitPromoSpec(
          title: 'Expand your\nSound Library.',
          cta: 'Open Sound Library',
          leftColor: const Color(0xFF2C1A3A),
          rightColor: const Color(0xFFAF7AC5),
          art: SplitPromoArts.robotLotus,
          onTap: onTap,
        );
      case SplitPromoSurface.requestWords:
        return SplitPromoSpec(
          title: 'Practice your\ntones today.',
          cta: 'Begin Practice',
          leftColor: const Color(0xFF3A2010),
          rightColor: const Color(0xFFE67E22),
          art: SplitPromoArts.redHairBlazer,
          onTap: onTap,
        );
      case SplitPromoSurface.storeHome:
        // Store hub mid-scroll — never self-referential Word Store CTA.
        return SplitPromoSpec(
          title: 'Open today\'s\nSound Library.',
          cta: 'Open Sound Library',
          leftColor: const Color(0xFF0F2A2E),
          rightColor: const Color(0xFF16A085),
          art: SplitPromoArts.egyptianLotus,
          onTap: onTap,
        );
      case SplitPromoSurface.selectLevel:
        return SplitPromoSpec(
          title: 'Keep your\nstreak alive.',
          cta: 'Begin Practice',
          leftColor: const Color(0xFF1A1830),
          rightColor: const Color(0xFF5B2C6F),
          art: SplitPromoArts.blondeBlazer,
          onTap: onTap,
        );
      case SplitPromoSurface.readerHub:
        return SplitPromoSpec(
          title: 'Browse deeper\nin Ebooks.',
          cta: 'Open Ebooks',
          leftColor: const Color(0xFF14241C),
          rightColor: const Color(0xFF1ABC9C),
          art: SplitPromoArts.redLotus,
          onTap: onTap,
        );
    }
  }
}

class ColoredSplitPromoBanner extends StatelessWidget {
  const ColoredSplitPromoBanner({
    super.key,
    required this.spec,
    this.height = 132,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  factory ColoredSplitPromoBanner.forSurface(
    SplitPromoSurface surface, {
    Key? key,
    VoidCallback? onTap,
    double height = 132,
    EdgeInsets margin = const EdgeInsets.only(bottom: 16),
  }) {
    return ColoredSplitPromoBanner(
      key: key,
      spec: SplitPromoSpec.forSurface(surface, onTap: onTap),
      height: height,
      margin: margin,
    );
  }

  final SplitPromoSpec spec;
  final double height;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(14);
    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: spec.onTap,
          borderRadius: r,
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              borderRadius: r,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: r,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left — dark text + outlined CTA pill
                  Expanded(
                    flex: 48,
                    child: ColoredBox(
                      color: spec.leftColor,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                spec.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color.lerp(
                                    Colors.white,
                                    spec.rightColor,
                                    0.35,
                                  )!,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.22,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: Color.lerp(
                                    Colors.white,
                                    spec.rightColor,
                                    0.45,
                                  )!,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                spec.cta,
                                style: TextStyle(
                                  color: Color.lerp(
                                    Colors.white,
                                    spec.rightColor,
                                    0.35,
                                  )!,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Right — solid colour + studio graphic
                  Expanded(
                    flex: 52,
                    child: ColoredBox(
                      color: spec.rightColor,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Soft lighter blob behind subject (YTM-like)
                          Align(
                            alignment: const Alignment(0.35, 0.2),
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
                            child: Image.asset(
                              spec.art,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Extra split banners. Same 132px chrome as the original practice banner.
/// Homes take 0–3, Sound Library 4–5, store sub-pages 6–13.
abstract final class SplitPromoExtras {
  static const _rows = <(String, String, int, int, String)>[
    (
      'Keep this hour\'s\nfrequency.',
      'Open Library',
      0xFF10243A,
      0xFF1ABC9C,
      SplitPromoArts.pose01,
    ),
    (
      'A word for\nthe body now.',
      'Begin Practice',
      0xFF3B1528,
      0xFFE07A32,
      SplitPromoArts.pose02,
    ),
    (
      'Sleep into\nthe next tone.',
      'Begin Practice',
      0xFF143028,
      0xFFD4A017,
      SplitPromoArts.pose03,
    ),
    (
      'Meanings that\nstay with you.',
      'Open Reader',
      0xFF2A1840,
      0xFFE07A5F,
      SplitPromoArts.pose04,
    ),
    (
      'Today\'s tones,\nready to play.',
      'Begin Practice',
      0xFF1A2744,
      0xFF5B8FB8,
      SplitPromoArts.pose05,
    ),
    (
      'Shop the word\nthat heals.',
      'Open Store',
      0xFF3A2410,
      0xFFC47B2B,
      SplitPromoArts.pose06,
    ),
    (
      'Build a library\nof your own.',
      'Browse words',
      0xFF1A2038,
      0xFF6C5CE7,
      SplitPromoArts.pose07,
    ),
    (
      'Unlock what\nthe word means.',
      'Open meanings',
      0xFF0E2F2C,
      0xFF2EC4B6,
      SplitPromoArts.pose08,
    ),
    (
      'A rare drop,\nonce only.',
      'View signatures',
      0xFF2C1810,
      0xFFC9A227,
      SplitPromoArts.pose09,
    ),
    (
      'Read the science\nbehind the sound.',
      'Open Ebooks',
      0xFF102820,
      0xFF27AE60,
      SplitPromoArts.pose10,
    ),
    (
      'Request a word\nmade for you.',
      'Request a word',
      0xFF2A1420,
      0xFFE85D9A,
      SplitPromoArts.pose01,
    ),
    (
      'Practice the\norgan it heals.',
      'Begin Practice',
      0xFF142033,
      0xFF3498DB,
      SplitPromoArts.pose02,
    ),
    (
      'Hold the tone\nuntil it lands.',
      'Begin Practice',
      0xFF241430,
      0xFF9B59B6,
      SplitPromoArts.pose03,
    ),
    (
      'A meaning for\nevery frequency.',
      'Open meanings',
      0xFF1A2830,
      0xFF16A085,
      SplitPromoArts.pose04,
    ),
    (
      'Sit with the\nsound awhile.',
      'Begin Practice',
      0xFF1A1428,
      0xFF8E44AD,
      SplitPromoArts.pose05,
    ),
    (
      'The word is\nthe practice.',
      'Open Library',
      0xFF10241C,
      0xFF1ABC9C,
      SplitPromoArts.pose06,
    ),
  ];

  static SplitPromoSpec at(int index, {VoidCallback? onTap}) {
    final row = _rows[index % _rows.length];
    return SplitPromoSpec(
      title: row.$1,
      cta: row.$2,
      leftColor: Color(row.$3),
      rightColor: Color(row.$4),
      art: row.$5,
      onTap: onTap,
    );
  }
}
