/// Shared look for the player intro, AURA setup, and leftover intro pages.
///
/// One film — the same clip as the Now Playing box — so those rooms cannot
/// drift onto the old store-headphones still or a flat colour plate.
library;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';

const kPlayerSharedFilm = 'assets/video/grok-video-use-this.mp4';

/// Full-bleed player film with the AURA charcoal wash on top.
class PlayerAuraBackdrop extends StatelessWidget {
  const PlayerAuraBackdrop({super.key, this.child, this.opacity = .42});

  final Widget? child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF202731)),
        Opacity(
          opacity: opacity,
          child: const NwsbVideo(
            asset: kPlayerSharedFilm,
            fit: BoxFit.cover,
            priority: ClipPriority.decoration,
            autoplay: true,
            loop: true,
            showPoster: true,
          ),
        ),
        const ColoredBox(color: Color(0xA3202731)),
        if (child != null) child!,
      ],
    );
  }
}

/// White circular back control from `player-settings.html`.
class PlayerAuraBackButton extends StatelessWidget {
  const PlayerAuraBackButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF202731),
            size: 28,
          ),
        ),
      ),
    );
  }
}
