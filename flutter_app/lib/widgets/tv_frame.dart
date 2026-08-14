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
      required this.left});

  final String image;

  /// The render's own shape. A bezel drawn at the wrong ratio stops lining
  /// up with its aperture, which is what "the television looks broken"
  /// always turns out to be.
  final double aspect;

  final double top, right, bottom, left;

  EdgeInsets insets(Size box) => EdgeInsets.only(
        top: box.height * top,
        bottom: box.height * bottom,
        left: box.width * left,
        right: box.width * right,
      );

  /// `.dev-tab-l` — padding: 4.854% 3.510% 3.734%
  static const tabletLandscape = DeviceFrame(
    'assets/frames/tab-landscape.webp',
    1452 / 831,
    top: 0.04854, right: 0.03510, bottom: 0.03734, left: 0.03510,
  );

  /// `.dev-tabc-p` — padding: 3.859% 2.426% 5.402%
  static const tabletPortrait = DeviceFrame(
    'assets/frames/tab2-portrait.webp',
    768 / 1168,
    top: 0.03859, right: 0.02426, bottom: 0.05402, left: 0.02426,
  );

  /// `.dev-tabs-p` — padding: 5.195% 3.424% 4.014% 3.306%
  static const tabletSlim = DeviceFrame(
    'assets/frames/tab3-portrait.webp',
    768 / 1168,
    top: 0.05195, right: 0.03424, bottom: 0.04014, left: 0.03306,
  );

  /// `.dev-tv-p` — padding: 3.4% 3.2% 8.4%
  static const tvPortrait = DeviceFrame(
    'assets/frames/tv-portrait.webp',
    900 / 1400,
    top: 0.034, right: 0.032, bottom: 0.084, left: 0.032,
  );

  /// `.dev-laptop` — padding: 3.049% 12.058% 16.701% 11.920%
  static const laptop = DeviceFrame(
    'assets/frames/laptop.webp',
    1600 / 1000,
    top: 0.03049, right: 0.12058, bottom: 0.16701, left: 0.11920,
  );
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
                  child: ColoredBox(
                    color: Colors.black,
                    child: NwsbVideo(
                      asset: asset,
                      priority: priority,
                      autoplay: autoplay,
                    ),
                  ),
                ),
                // The bezel, over the top. IgnorePointer because it is
                // decoration and must never eat a tap meant for the card.
                IgnorePointer(
                  child: Image.asset(
                    frame.image,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
