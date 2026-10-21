/// Every primary page uses Home's film (normal-glass-background.mp4).
library;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, this.base = NwsbColors.deep});

  /// Colour under the film before its first frame (Home passes its pale one).
  final Color base;

  /// Home's film. Every page that uses AppBackdrop plays this same asset,
  /// so swapping it here changes the background everywhere at once, and the
  /// pool hands every page the same clip rather than a decoder each.
  static const asset = 'assets/video/normal-glass-background.mp4';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        const IgnorePointer(
          child: NwsbVideo(
            asset: asset,
            fit: BoxFit.cover,
            priority: ClipPriority.feature,
            autoplay: true,
            loop: true,
            showPoster: true,
            slot: 'app_backdrop.AppBackdrop',
          ),
        ),
      ],
    );
  }
}