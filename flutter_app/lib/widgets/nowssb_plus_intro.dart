/// Full-bleed intro for NowssB Plus.
///
/// The poster fills the screen, edge to edge, and a glass pane at the foot
/// holds the short copy and the enter pill. The poster is shifted so the
/// vertical NOWSSB column sits fully above the pane. Enter opens the page
/// underneath, same as the old intro gate — it does not flip the motion
/// switch by itself.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'restyle_kit.dart';

class NowssbPlusIntro extends StatelessWidget {
  const NowssbPlusIntro({super.key, required this.child, this.onBack});

  /// What is underneath, revealed when Enter is pressed.
  final Widget child;

  final VoidCallback? onBack;

  static const art = 'assets/fashion/nowssb-plus-intro.webp';

  /// Pixel size of [art]. Used to place the NOWSSB column above the pane.
  static const artSize = Size(1080, 2340);

  /// Top and bottom of the vertical NOWSSB letter column, as a fraction of
  /// the poster height (measured on the asset: y=456–1841 of 2340).
  static const letterTop = 456 / 2340;
  static const letterBottom = 1841 / 2340;

  /// Gap, in logical pixels, between the bottom of the B and the pane.
  static const letterGap = 18.0;

  static const copy =
      'Turns on motion backgrounds on the Zen home tiles and pages. '
      'It uses more battery. Switch it off anytime in Settings.';

  void _open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => child));
  }

  @override
  Widget build(BuildContext context) {
    final minLetterTop = MediaQuery.paddingOf(context).top + 8;
    return Material(
      color: Colors.black,
      child: ClipRect(
        child: CustomMultiChildLayout(
          delegate: _IntroLayout(minLetterTop: minLetterTop),
          children: [
            LayoutId(
              id: _IntroSlot.backdrop,
              child: const ColoredBox(color: Colors.black),
            ),
            LayoutId(
              id: _IntroSlot.poster,
              child: Image.asset(
                art,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            LayoutId(
              id: _IntroSlot.shade,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x59000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0x99000000),
                        Color(0xF2000000),
                      ],
                      stops: [0, 0.14, 0.46, 0.72, 1],
                    ),
                  ),
                ),
              ),
            ),
            LayoutId(
              id: _IntroSlot.back,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  // heightFactor shrink-wraps; a plain Align would center it.
                  child: Align(
                    alignment: Alignment.centerLeft,
                    heightFactor: 1,
                    child: KitBackButton(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ),
            ),
            LayoutId(
              id: _IntroSlot.pane,
              child: SafeArea(
                top: false,
                child: GlassWrap(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHead(
                        eyebrow: 'NowssB Plus',
                        title: 'Motion on the Zen home',
                        mark: NwsbMarks.play,
                      ),
                      const Text(
                        copy,
                        style: TextStyle(
                          color: kKitMuted,
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      KitActionPill(
                        'Enter NowssB Plus',
                        onTap: () => _open(context),
                      ),
                    ],
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

enum _IntroSlot { backdrop, poster, shade, back, pane }

/// Places the poster so the NOWSSB column sits fully above the glass pane,
/// shrinking the shift if it would crop the N at the top.
class _IntroLayout extends MultiChildLayoutDelegate {
  _IntroLayout({required this.minLetterTop});

  final double minLetterTop;

  @override
  void performLayout(Size size) {
    if (hasChild(_IntroSlot.backdrop)) {
      layoutChild(_IntroSlot.backdrop, BoxConstraints.tight(size));
      positionChild(_IntroSlot.backdrop, Offset.zero);
    }
    if (hasChild(_IntroSlot.shade)) {
      layoutChild(_IntroSlot.shade, BoxConstraints.tight(size));
      positionChild(_IntroSlot.shade, Offset.zero);
    }
    if (hasChild(_IntroSlot.back)) {
      layoutChild(_IntroSlot.back, BoxConstraints.loose(size));
      positionChild(_IntroSlot.back, Offset.zero);
    }

    var paneTop = size.height;
    if (hasChild(_IntroSlot.pane)) {
      final pane = layoutChild(
        _IntroSlot.pane,
        BoxConstraints(maxWidth: size.width, maxHeight: size.height),
      );
      paneTop = size.height - pane.height;
      positionChild(_IntroSlot.pane, Offset(0, paneTop));
    }

    if (hasChild(_IntroSlot.poster)) {
      layoutChild(_IntroSlot.poster, BoxConstraints.tight(size));
      final scale = math.max(
        size.width / NowssbPlusIntro.artSize.width,
        size.height / NowssbPlusIntro.artSize.height,
      );
      final drawnH = NowssbPlusIntro.artSize.height * scale;
      // BoxFit.cover + Alignment.center: extra height is split top and bottom.
      final originY = (size.height - drawnH) / 2;
      final letterBottomY = originY + NowssbPlusIntro.letterBottom * drawnH;
      var dy = (paneTop - NowssbPlusIntro.letterGap) - letterBottomY;
      final letterTopY = originY + dy + NowssbPlusIntro.letterTop * drawnH;
      if (letterTopY < minLetterTop) {
        dy += minLetterTop - letterTopY;
      }
      positionChild(_IntroSlot.poster, Offset(0, dy));
    }
  }

  @override
  bool shouldRelayout(_IntroLayout old) => minLetterTop != old.minLetterTop;
}
