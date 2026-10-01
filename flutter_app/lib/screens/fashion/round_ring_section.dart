/// Fashion home — passive earning.
///
/// Five program posters sit on a black cylinder, the way a round carousel
/// does: one card forward, one on each side, the rest behind and hidden.
/// Drag turns it. There is no face chooser.
library;

import 'package:flutter/material.dart';

import '../../widgets/glass_wrap.dart';
import '../../widgets/program_shelf.dart';
import '../../widgets/round_carousel.dart';

class RoundRingSection extends StatelessWidget {
  const RoundRingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PASSIVE EARNING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: Color(0xFFE4C56A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'It keeps turning',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.1,
              color: Color(0xFFF4F4F5),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Earn, rewards, gifts, bonus, partner. Drag the ring.',
            style: TextStyle(fontSize: 12, color: Color(0xB3F4F4F5)),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: const Color(0xFF000000),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: RoundCarousel(
                  images: [for (final p in kProgramPosters) p.asset],
                  speed: 2.4,
                  tilt: -8,
                  spacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
