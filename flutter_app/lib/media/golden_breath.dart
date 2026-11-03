/// Zen Plus clip (Ribon 11-03): Golden Breath; the hero films reuse the widget. Each is a seamless loop that dips through black at the seam, muted, 720px.
/// NwsbVideo pauses it offscreen; under reduced motion only the poster shows.
library;

import 'package:flutter/material.dart';
import 'nwsb_video.dart';

const kGoldenBreathClip = 'assets/video/golden-breath-tile.mp4';
const kGoldenBreathPoster = 'assets/video/golden-breath-tile-poster.webp';

class GoldenBreathClip extends StatelessWidget {
  const GoldenBreathClip({super.key, this.alignment = const Alignment(.55, -.15), this.slot,
      this.asset = kGoldenBreathClip, this.poster = kGoldenBreathPoster});
  final Alignment alignment;
  final String asset, poster;
  final String? slot;

  /// Renders/tests only: paint this frame instead of the clip.
  static ImageProvider Function(String asset)? debugFrame;

  @override
  Widget build(BuildContext context) {
    final dbg = debugFrame;
    if (dbg != null) {
      return Image(image: dbg(asset), fit: BoxFit.cover, alignment: alignment, gaplessPlayback: true);
    }
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      return Image.asset(poster, fit: BoxFit.cover, alignment: alignment, gaplessPlayback: true);
    }
    return NwsbVideo(asset: asset, poster: poster, alignment: alignment, slot: slot);
  }
}
