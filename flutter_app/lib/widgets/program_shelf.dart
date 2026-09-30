/// The shared pieces every program tab uses: a white-circle composing orb,
/// a glass line of text, and a sideways shelf of the program posters.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import 'app_thinking_loader.dart';
import 'glass_wrap.dart';

class ProgramPoster {
  const ProgramPoster(this.asset, this.title, this.line);
  final String asset;
  final String title;
  final String line;
}

const kProgramPosters = <ProgramPoster>[
  ProgramPoster('assets/banners/programs/earn.png', 'Earn', 'Cash on real sales'),
  ProgramPoster('assets/banners/programs/rewards.png', 'Rewards', 'Coins you spend here'),
  ProgramPoster('assets/banners/programs/gift.png', 'Gift', 'Send the item itself'),
  ProgramPoster('assets/banners/programs/bonus.png', 'Bonus', 'A target, paid once'),
  ProgramPoster('assets/banners/programs/partner.png', 'Partner', 'Perks, not cash'),
];

class WhiteCircleOrb extends StatelessWidget {
  const WhiteCircleOrb({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    final circle = size + 16;
    return Container(
      width: circle,
      height: circle,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: AppThinkingLoader(
        size: size,
        state: OrbState.composing,
        blackCircle: false,
      ),
    );
  }
}

class GlassLine extends StatelessWidget {
  const GlassLine({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          const WhiteCircleOrb(size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sideways snap shelf. Each card is a poster, not a copy of the last one.
class ProgramShelf extends StatelessWidget {
  const ProgramShelf({super.key, this.onTap, this.height = 168});

  final ValueChanged<ProgramPoster>? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kProgramPosters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final poster = kProgramPosters[i];
          return GestureDetector(
            onTap: onTap == null ? null : () => onTap!(poster),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      poster.asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111)),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xE6000000)],
                          stops: [0.45, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: GlassWrap(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text(
                          '${poster.title} · ${poster.line}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
