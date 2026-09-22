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
  static const robotLotus = 'assets/banners/promo/split-robot-lotus.png';
  static const blondeLotus = 'assets/banners/promo/split-blonde-lotus.png';
  static const egyptianLotus = 'assets/banners/promo/split-egyptian-lotus.png';
  static const redLotus = 'assets/banners/promo/split-red-lotus.png';

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
          leftColor: const Color(0xFF3A1848),
          rightColor: const Color(0xFFC44DFF),
          art: SplitPromoArts.egyptianLotus,
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
          art: SplitPromoArts.robotLookback,
          onTap: onTap,
        );
      case SplitPromoSurface.fashionHome:
        return SplitPromoSpec(
          title: 'Start today\'s\npractice now.',
          cta: 'Begin Practice',
          leftColor: const Color(0xFF4A1838),
          rightColor: const Color(0xFFE85D9A),
          art: SplitPromoArts.whiteRobot,
          onTap: onTap,
        );
      case SplitPromoSurface.ebooksStore:
        return SplitPromoSpec(
          title: 'Dig into the\nSound Library.',
          cta: 'Open Sound Library',
          leftColor: const Color(0xFF143028),
          rightColor: const Color(0xFF2D6A4F),
          art: SplitPromoArts.egyptianGold,
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
