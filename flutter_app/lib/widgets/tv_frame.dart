/// The televisions — the real device bezels out of assets/frames/.
///
/// These are the renders the website uses, and the way they work is worth
/// stating because it is not obvious: THE FRAME IS A TRANSPARENT-APERTURE
/// PICTURE DRAWN ON TOP OF THE CONTENT, not a border around it. The hole in
/// the middle is transparent, so the clip is simply inset behind it by the
/// exact percentages the bezel's own artwork occupies.
///
/// Percentages, never pixels — the aperture then lands correctly at any size
/// with no second set of numbers to keep in step. Each set below is lifted
/// verbatim from the padding on `.nwsb-inframe.dev-*` in nowssb-nm.css, so
/// when a bezel is re-cut on the web there is one place here to match.
///
/// This replaces a hand-drawn white rounded rectangle. The frames were in
/// the repository the whole time.
library;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';

/// A bezel: its picture, the aperture inset as fractions of the box, and the
/// shape of the render so the frame is never squashed.
class DeviceFrame {
  const DeviceFrame(this.image, this.aspect,
      {required this.top,
      required this.right,
      required this.bottom,
      required this.left,
      this.verticalIsHeight = false});

  /// True when this frame's aperture is placed by ABSOLUTE OFFSETS rather
  /// than by padding — `top`/`bottom` percentages on a positioned box
  /// resolve against the containing block's HEIGHT, where padding resolves
  /// against its width. `.hhr-tab` is the one frame built that way, because
  /// a `<video>` is a replaced element and `width: auto` on one takes its
  /// intrinsic size and drops the `right` offset (nowssb-nm.css:14651).
  final bool verticalIsHeight;

  final String image;

  /// The render's own shape. A bezel drawn at the wrong ratio stops lining
  /// up with its aperture, which is what "the television looks broken"
  /// always turns out to be.
  final double aspect;

  final double top, right, bottom, left;

  /// EVERY side is a fraction of the WIDTH.
  ///
  /// That is not a simplification, it is what the stylesheet means: CSS
  /// percentage padding resolves against the containing block's width on
  /// all four sides, top and bottom included. nowssb-nm.css:11542 says so
  /// in as many words, and :11553 records the bug that proved it — a
  /// version that read the vertical numbers as fractions of the height
  /// came up 14px short at the foot and spilled 4px over the head, which
  /// is the black band that appeared under the screen.
  ///
  /// This code had the same bug. Height was being used for top and bottom,
  /// so every television's aperture sat a little too low and a little too
  /// short of its bezel.
  EdgeInsets insets(Size box) => EdgeInsets.only(
        top: (verticalIsHeight ? box.height : box.width) * top,
        bottom: (verticalIsHeight ? box.height : box.width) * bottom,
        left: box.width * left,
        right: box.width * right,
      );

  /// `.dev-tab-l` — padding: 4.854% 3.510% 3.734%. Trimmed render 1339x875.
  static const tabletLandscape = DeviceFrame(
    'assets/frames/tab-landscape.webp',
    1339 / 875,
    top: 0.04854,
    right: 0.03510,
    bottom: 0.03734,
    left: 0.03510,
  );

  /// `.hhr-tab` — nowssb-nm.css:14641. The wide white frame the
  /// Customize · Features · Earn strip sits in. Its aperture is placed by
  /// offsets, not padding: left 1.823%, top 5.994%, width 96.208%, height
  /// 87.381% — so right and bottom are what is left over.
  static const wordActs = DeviceFrame(
    'assets/frames/word-acts-tab.webp',
    1371 / 317,
    top: 0.05994,
    right: 0.01969,
    bottom: 0.06625,
    left: 0.01823,
    verticalIsHeight: true,
  );

  /// `.dev-tabc-l` — padding: 1.752% 1.523% 4.570% 1.447%. Render 1313x807.
  static const tabletCurveLandscape = DeviceFrame(
    'assets/frames/tab2-landscape.webp',
    1313 / 807,
    top: 0.01752,
    right: 0.01523,
    bottom: 0.04570,
    left: 0.01447,
  );

  /// `.dev-tabs-l` — padding: 2.766% 1.988% 5.877% 2.161%. Render 1157x863.
  static const tabletSlimLandscape = DeviceFrame(
    'assets/frames/tab3-landscape.webp',
    1157 / 863,
    top: 0.02766,
    right: 0.01988,
    bottom: 0.05877,
    left: 0.02161,
  );

  /// `.dev-tabc-p` — padding: 3.859% 2.426% 5.402%. Render 907x1307.
  static const tabletPortrait = DeviceFrame(
    'assets/frames/tab2-portrait.webp',
    907 / 1307,
    top: 0.03859,
    right: 0.02426,
    bottom: 0.05402,
    left: 0.02426,
  );

  /// `.dev-tabs-p` — padding: 5.195% 3.424% 4.014% 3.306%. Render 847x1299.
  static const tabletSlim = DeviceFrame(
    'assets/frames/tab3-portrait.webp',
    847 / 1299,
    top: 0.05195,
    right: 0.03424,
    bottom: 0.04014,
    left: 0.03306,
  );

  /// The kiosk — a portrait display on a stand with the wordmark printed on
  /// its top bezel. Trimmed render 815x1511; the aperture is 773x1379, which
  /// is 0.5606 — 9:16 to within a pixel, so a 720x1280 clip fills it exactly
  /// with nothing cropped and no bars.
  ///
  /// Measured off the render rather than typed by eye: the white bezel's
  /// bounding box gives the frame, and walking in from each edge along the
  /// centre lines gives the screen.
  static const kioskPortrait = DeviceFrame(
    'assets/frames/tv-kiosk-portrait.webp',
    815 / 1511,
    top: 0.03804,
    right: 0.02454,
    bottom: 0.12270,
    left: 0.02699,
  );

  /// `.dev-tv-p` — padding: 3.4% 3.2% 8.4%. Render 862x1450.
  static const tvPortrait = DeviceFrame(
    'assets/frames/tv-portrait.webp',
    862 / 1450,
    top: 0.034,
    right: 0.032,
    bottom: 0.084,
    left: 0.032,
  );

  /// `.dev-laptop` — padding: 3.049% 12.058% 16.701% 11.920%. Render
  /// 1443x915.
  static const laptop = DeviceFrame(
    'assets/frames/laptop.webp',
    1443 / 915,
    top: 0.03049,
    right: 0.12058,
    bottom: 0.16701,
    left: 0.11920,
  );

  /// `.dev-tv-l` — padding: 2.410% 1.791% 8.540% 1.928%, at the trimmed
  /// render's own 1452x831.
  ///
  /// [image] is empty because this bezel is not one picture: it is a top
  /// cap, a bottom cap and a side rail tiled between them. See [TvFrame],
  /// which draws the three when it sees an empty image, the same way
  /// `.dev-tv-l::after` and `::before` do. A television is 1.75:1 and the
  /// rail it holds is not, so one render stretched to the box would put
  /// visible bezel detail wherever the box disagreed with it.
  static const tvLandscape = DeviceFrame(
    '',
    1452 / 831,
    top: 0.02410,
    right: 0.01791,
    bottom: 0.08540,
    left: 0.01928,
  );

  /// The bottom cap's height as a fraction of the box's HEIGHT — 124/831.
  /// The side rails stop here, and a percentage measured from the bottom of
  /// a positioned box is the one number on this frame that is vertical.
  static const double tvLandscapeCapFraction = 124 / 831;
}

class TvFrame extends StatelessWidget {
  const TvFrame({
    super.key,
    required this.asset,
    this.frame = DeviceFrame.tabletLandscape,
    this.aspect,
    this.priority = ClipPriority.feature,
    this.autoplay = true,
    this.onTap,
    this.overlay,
  });

  /// The clip on the screen.
  final String asset;

  /// Which device it is shown in.
  final DeviceFrame frame;

  /// Overrides the frame's own shape. Rarely wanted — a bezel drawn at a
  /// ratio other than its own stops matching its aperture.
  final double? aspect;

  /// The television is the point of its section, so by default it claims a
  /// decoder ahead of any banner near it.
  final ClipPriority priority;

  final bool autoplay;
  final VoidCallback? onTap;

  /// What sits ON the screen, inside the aperture and over the clip — the
  /// Quick Access row, a caption, a call to action. Clipped to the aperture
  /// like everything else on the screen is.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: aspect ?? frame.aspect,
        child: LayoutBuilder(
          builder: (context, c) {
            final box = Size(c.maxWidth, c.maxHeight);
            return Stack(
              fit: StackFit.expand,
              children: [
                // The screen, behind the glass. Black under it because a
                // clip that has not opened yet should read as a dark screen
                // rather than as a hole in the device.
                Padding(
                  padding: frame.insets(box),
                  child: ClipRect(
                    child: ColoredBox(
                      color: Colors.black,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          NwsbVideo(
                            asset: asset,
                            priority: priority,
                            autoplay: autoplay,
                            showPoster: false,
                          ),
                          if (overlay != null) overlay!,
                        ],
                      ),
                    ),
                  ),
                ),
                // The bezel, over the top. IgnorePointer because it is
                // decoration and must never eat a tap meant for the card.
                IgnorePointer(child: _Bezel(frame: frame)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// tv-l-mid.webp's own width. The rail has to be scaled to the box, and
/// scaling means knowing what it is being scaled from.
const double _tvRailNaturalWidth = 1452;

/// The bezel picture — one render, or the television's three slices.
class _Bezel extends StatelessWidget {
  const _Bezel({required this.frame});
  final DeviceFrame frame;

  @override
  Widget build(BuildContext context) {
    if (frame.image.isNotEmpty) {
      return Image.asset(
        frame.image,
        fit: BoxFit.fill,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }

    // `.dev-tv-l` — the two caps at their own height, and the rail tiled
    // down the sides between the top of the box and the top of the bottom
    // cap. Tiling it the whole height is what once carried the rails past
    // the bottom bezel and boxed the stand in.
    return LayoutBuilder(
      builder: (context, c) {
        final railBottom = c.maxHeight * DeviceFrame.tvLandscapeCapFraction;
        return Stack(
          children: [
            // The side rails. `background: … top center / 100% 8px repeat-y`
            // — scaled to the FULL WIDTH of the box and tiled downwards.
            //
            // This was `Image.asset(fit: BoxFit.none, repeat: repeatY)`,
            // which draws the file at its natural size: the slice is 1452
            // wide and the television is about 600, so it was painted
            // 1452 wide and centred, putting the left rail off the left edge
            // and the right rail off the right one. The set has had no sides
            // at all.
            //
            // `scale` on the provider is what CSS's `100%` is: dividing the
            // natural width by the box width makes the image's LOGICAL width
            // exactly the box, and its height follows, so repeatY then tiles
            // the right shape.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: railBottom,
              child: Image.asset(
                'assets/frames/tv-l-mid.webp',
                scale: _tvRailNaturalWidth / c.maxWidth,
                fit: BoxFit.none,
                repeat: ImageRepeat.repeatY,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Image.asset(
                'assets/frames/tv-l-top.webp',
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Image.asset(
                'assets/frames/tv-l-bottom.webp',
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}
