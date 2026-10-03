/// The shared pieces every program tab uses: a white-circle composing orb,
/// a glass line of text, and a sideways shelf of the program posters.
library;

import 'package:flutter/material.dart';

import '../features/programs/program_router.dart';
import '../shell/nav_shell.dart';

import 'glass_wrap.dart';
import 'nwsb_icon.dart';
import '../admin/template/editable.dart';

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
  ProgramPoster('assets/banners/programs/rewards-live.png', 'Rewards', 'The white suit'),
  ProgramPoster('assets/banners/earn/hands-raise.png', 'Practice', 'Hands up'),
];

/// White circle with the section's own SVG. Never the composing animation.
class WhiteCircleOrb extends StatelessWidget {
  const WhiteCircleOrb({super.key, this.size = 18, this.mark = NwsbMarks.word});
  final double size;
  final String mark;

  @override
  Widget build(BuildContext context) {
    final circle = size + 16;
    return Container(
      width: circle,
      height: circle,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: NwsbIcon(mark, size: size, color: const Color(0xFF111111), strokeWidth: 1.7),
    );
  }
}

class GlassLine extends StatelessWidget {
  const GlassLine({super.key, required this.text, this.mark = NwsbMarks.word});
  final String text;
  final String mark;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          WhiteCircleOrb(size: 18, mark: mark),
          const SizedBox(width: 10),
          Expanded(
            child: EditableLabel('program_shelf.GlassLine',
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
  const ProgramShelf({super.key, this.onTap, this.height = 168, this.current});

  /// Override; by default each poster opens its own programme.
  final ValueChanged<ProgramPoster>? onTap;
  final double height;

  /// On a programme page, that programme's posters are left out.
  final Programme? current;

  static void openPoster(BuildContext context, ProgramPoster p) {
    if (p.title == 'Practice') {
      NavScope.goTo(context, 1);
      return;
    }
    final prog = Programmes.forPoster(p.title);
    if (prog == null) return;
    Programmes.open(context, prog, tab: p.title == 'Bonus' ? 'targets' : (p.line == 'The white suit' ? 'season' : null));
  }

  @override
  Widget build(BuildContext context) {
    final posters = [
      for (final p in kProgramPosters)
        if (current == null || Programmes.forPoster(p.title) != current) p,
    ];
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: posters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final poster = posters[i];
          return GestureDetector(
            onTap: () => onTap != null ? onTap!(poster) : openPoster(context, poster),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 220,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    EditableImage.asset(
                      poster.asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111)),
                      slot: 'program_shelf.ProgramShelf',
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
