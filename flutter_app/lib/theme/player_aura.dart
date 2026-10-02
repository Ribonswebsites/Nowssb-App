/// Shared look for the player intro, AURA clock, and Music Player Settings.
///
/// Website `player-settings.html` is charcoal `#202731` with a dark swirl —
/// not the Now Playing box films. Those clips stay on the player stage
/// only (`kPlayerBoxFilms`).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../admin/template/editable.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';

/// Primary player-box film. Intro and settings must not use this clip.
const kPlayerBoxFilm = 'assets/video/player-box-rings.mp4';

/// Same film for every word so the center box does not swap looks.
const kPlayerBoxWaveFilm = 'assets/video/player-box-rings.mp4';
const kPlayerBoxFilms = <String>[kPlayerBoxFilm];

/// Charcoal AURA film — leftover intro rooms.
const kPlayerAuraFilm = 'assets/video/player-aura-bg.mp4';

/// Full Now Playing page film. Settings + AURA clock use this, never the box clips.
const kPlayerPageFilm = 'assets/video/player-bg-loop.mp4';

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
  const PlayerAuraBackdrop({
    super.key,
    this.child,
    this.opacity = .88,
    this.film = kPlayerAuraFilm,
  });

  final Widget? child;
  final double opacity;
  final String film;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: kPlayerAuraBg),
        Opacity(
          opacity: opacity,
          child: NwsbVideo(
            asset: film,
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
  const PlayerAuraBackButton({super.key, required this.onTap, this.icon = Icons.chevron_left_rounded, this.iconSize = 28, this.tooltip});
  final VoidCallback onTap;

  /// Chevron by default; the walkthrough uses a close mark.
  final IconData icon;
  final double iconSize;
  final String? tooltip;

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
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: kPlayerAuraBg,
            size: iconSize,
            semanticLabel: tooltip,
          ),
        ),
      ),
    );
  }
}


/// The player family's page shell — Player settings, Saved words (Library)
/// and any other player sub-page: charcoal AURA page film, white round back,
/// the NowssB mark (or the page's own actions) on the right, and a light
/// spaced caps heading. One widget so sibling player pages always match.
class PlayerAuraPage extends StatelessWidget {
  const PlayerAuraPage({
    super.key,
    required this.slot,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.film = kPlayerPageFilm,
    this.titleSize = 29,
  });

  /// Template-editor slot for the heading and brand mark (`<file>.<Class>`).
  final String slot;
  final String title;

  /// Dynamic line under the heading (counts etc. — not a template slot).
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final String film;
  final double titleSize;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPlayerAuraBg,
      body: PlayerAuraBackdrop(
        film: film,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 12, 4),
                child: Row(
                  children: [
                    PlayerAuraBackButton(
                      onTap: onBack ?? () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    if (actions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: EditableLabel(slot,
                          'NowssB',
                          style: playerAuraText(
                            size: 12,
                            letterSpacing: 4,
                            weight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      ...actions,
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 18, 24, subtitle == null ? 12 : 4),
                child: EditableLabel(slot,
                  title,
                  style: playerAuraText(
                    size: titleSize,
                    weight: FontWeight.w300,
                    letterSpacing: 4.0,
                    height: 1.28,
                  ),
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text(
                    subtitle!,
                    style: playerAuraText(
                      size: 12,
                      letterSpacing: 2.2,
                      color: kPlayerAuraMuted,
                    ),
                  ),
                ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
