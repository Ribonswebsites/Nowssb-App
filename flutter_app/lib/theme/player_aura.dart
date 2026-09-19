/// Shared look for the player intro, AURA clock, and Music Player Settings.
///
/// Website `player-settings.html` is charcoal `#202731` with a dark swirl —
/// not the gold Now Playing box film. That gold clip stays on the player
/// stage only (`kPlayerBoxFilm`).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';

/// Gold liquid inside the Now Playing box. Do not put this on intro/setup.
const kPlayerBoxFilm = 'assets/video/grok-video-use-this.mp4';

/// Charcoal AURA film — same image the website/WebView uses behind the
/// clock and the Music Player Settings page.
const kPlayerAuraFilm = 'assets/video/player-aura-bg.mp4';

/// Intros + leftover player rooms share the AURA film.
const kPlayerSharedFilm = kPlayerAuraFilm;

const kPlayerAuraBg = Color(0xFF202731);
const kPlayerAuraFg = Color(0xFFF2F2EF);
const kPlayerAuraMuted = Color(0xFFB3BDCA);

TextStyle playerAuraText({
  double size = 12,
  FontWeight weight = FontWeight.w400,
  double letterSpacing = 0,
  double height = 1.2,
  Color? color,
}) {
  return GoogleFonts.outfit(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
    color: color ?? kPlayerAuraFg,
  );
}

/// Full-bleed charcoal AURA film with a light wash so type stays readable.
class PlayerAuraBackdrop extends StatelessWidget {
  const PlayerAuraBackdrop({super.key, this.child, this.opacity = .88});

  final Widget? child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: kPlayerAuraBg),
        Opacity(
          opacity: opacity,
          child: const NwsbVideo(
            asset: kPlayerAuraFilm,
            fit: BoxFit.cover,
            priority: ClipPriority.decoration,
            autoplay: true,
            loop: true,
            showPoster: true,
          ),
        ),
        const ColoredBox(color: Color(0x73202731)),
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
            color: kPlayerAuraBg,
            size: 28,
          ),
        ),
      ),
    );
  }
}
