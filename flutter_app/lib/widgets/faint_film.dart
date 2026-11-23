/// The one background film for the whole app, mounted once under the
/// navigator so it does not restart when a page opens.
library;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';

/// While a store word page is open, the app's one background film is
/// hidden and does not play. Released when the page is popped. This does
/// not change Still / Moving ([Settings.fashionPlus]).
class FaintFilmPause {
  FaintFilmPause._();
  static final ValueNotifier<int> _holds = ValueNotifier(0);
  static Listenable get listenable => _holds;
  static bool get paused => _holds.value > 0;
  static void hold() => _holds.value++;
  static void release() {
    if (_holds.value > 0) _holds.value--;
  }

  @visibleForTesting
  static void debugReset() => _holds.value = 0;
}

class FaintFilm extends StatelessWidget {
  const FaintFilm({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FaintFilmPause.listenable,
      builder: (context, _) {
        if (FaintFilmPause.paused) {
          return const ColoredBox(color: NwsbColors.deep);
        }
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
                      asset: 'assets/video/subscription-bg.mp4',
                      priority: ClipPriority.feature,
                      autoplay: true,
                      loop: true,
                      obeyMotion: true,
                      slot: 'faint_film.FaintFilm',
                    ),
            ),
          ],
        );
      },
    );
  }
}
