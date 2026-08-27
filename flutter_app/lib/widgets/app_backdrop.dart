/// The one background rule shared by NowssB's primary Flutter pages.
///
/// Fashion Plus on: the saved Fashion Plus film plays everywhere.
/// Fashion Plus off: the saved still is shown everywhere, or black if none
/// has been selected. This deliberately does not use each page's old local
/// poster, so changing the setting changes the whole app consistently.
library;

import 'package:flutter/material.dart';

import '../data/settings.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Settings.instance,
      builder: (_, __) {
        final settings = Settings.instance;
        if (settings.fashionPlus) {
          return NwsbVideo(
            asset: settings.fashionVideoAsset,
            priority: ClipPriority.feature,
            autoplay: true,
          );
        }
        final image = settings.fashionImageAsset;
        if (image != null) {
          return Image.asset(
            image,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: NwsbColors.deep),
          );
        }
        return const ColoredBox(color: NwsbColors.deep);
      },
    );
  }
}
