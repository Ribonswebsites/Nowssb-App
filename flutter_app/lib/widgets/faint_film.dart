/// The one background film for the whole app, mounted once under the
/// navigator so it does not restart when a page opens.
library;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';

class FaintFilm extends StatelessWidget {
  const FaintFilm({super.key});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: NwsbColors.deep),
        Opacity(
          opacity: kBgVideoOpacity.clamp(0.08, 0.20),
          child: reduce
              ? const AppBackdrop()
              : const NwsbVideo(
                  asset: 'assets/video/player-bg-loop.mp4',
                  priority: ClipPriority.feature,
                  autoplay: true,
                  loop: true,
                  slot: 'faint_film.FaintFilm',
                ),
        ),
      ],
    );
  }
}
