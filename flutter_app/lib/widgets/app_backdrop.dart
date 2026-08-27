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
        final key = ValueKey(
          '${settings.backgroundTransition}-${settings.fashionPlus}-'
          '${settings.fashionVideoIndex}-${settings.fashionImageIndex}',
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: NwsbColors.deep),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              reverseDuration: const Duration(milliseconds: 150),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(key: key, child: _visual(settings)),
            ),
          ],
        );
      },
    );
  }

  Widget _visual(Settings settings) {
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
        errorBuilder: (_, __, ___) => const ColoredBox(color: NwsbColors.deep),
      );
    }
    return const ColoredBox(color: NwsbColors.deep);
  }
}
