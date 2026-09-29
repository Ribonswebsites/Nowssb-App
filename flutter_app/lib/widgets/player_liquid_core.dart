/// Moving center of the Now Playing box.
///
/// Replaces the static player-box film with `liquid_glass_animation` 0.0.1
/// (`LiquidGlass`: real-time sine wave, speed, blur, opacity) plus
/// [ListeningRings].
library;

import 'package:flutter/material.dart';
import 'package:liquid_glass_animation/liquid_glass_animation.dart' as wave;

import '../theme/liquid_glass_theme.dart';
import 'listening_visual.dart';

class PlayerLiquidCore extends StatelessWidget {
  const PlayerLiquidCore({super.key, required this.playing});

  final bool playing;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NwsbEffects.instance,
      builder: (context, _) {
        final reduced = NwsbEffects.instance.reduced;
        return LayoutBuilder(
          builder: (context, box) {
            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF05060A)),
                wave.LiquidGlass(
                  width: box.maxWidth,
                  height: box.maxHeight,
                  blur: reduced ? 6 : 16,
                  opacity: reduced ? 0.1 : 0.2,
                  speed: const Duration(seconds: 8),
                  waveAmplitude: reduced ? 8 : 16,
                  waveFrequency: 1.35,
                  showBubbles: !reduced,
                  bubbleCount: 5,
                  borderRadius: BorderRadius.zero,
                  tint: const Color(0xFF8EB4FF),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF10162A),
                      Color(0xFF1A1030),
                      Color(0xFF07080C),
                    ],
                  ),
                ),
                ListeningRings(
                  playing: playing,
                  showOrb: !reduced,
                  orbRadius: reduced ? 0 : 52,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
