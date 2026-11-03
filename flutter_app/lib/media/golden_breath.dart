/// Zen Plus tile clips (Ribon 11-03): Golden Breath (default), Sound Wave,
/// Release. Each is a that dips through black at the seam, muted, 720px.
/// NwsbVideo pauses it offscreen; under reduced motion only the poster shows.
library;

import 'package:flutter/material.dart';
import 'nwsb_video.dart';

const kGoldenBreathClip = 'assets/video/golden-breath-tile.mp4';
const kGoldenBreathPoster = 'assets/video/golden-breath-tile-poster.webp';
const kSoundWaveClip = 'assets/video/zen-soundwave-tile.mp4';
const kSoundWavePoster = 'assets/video/zen-soundwave-tile-poster.webp';
const kReleaseClip = 'assets/video/zen-release-tile.mp4';
const kReleasePoster = 'assets/video/zen-release-tile-poster.webp';

class GoldenBreathClip extends StatelessWidget {
  const GoldenBreathClip({super.key, this.alignment = const Alignment(.55, -.15), this.slot,
      this.asset = kGoldenBreathClip, this.poster = kGoldenBreathPoster});
  final Alignment alignment;
  final String asset, poster;
  final String? slot;
  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      return Image.asset(poster, fit: BoxFit.cover, alignment: alignment, gaplessPlayback: true);
    }
    return NwsbVideo(asset: asset, poster: poster, alignment: alignment, slot: slot);
  }
}
