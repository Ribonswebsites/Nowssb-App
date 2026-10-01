/// The four banner styles that belong on a page: the three-card earn row,
/// a split promo, a black glass row, and a sideways poster shelf.
library;

import 'package:flutter/material.dart';

import '../features/earn/earnings_screen.dart';
import '../features/vault/vault_screen.dart';
import 'black_glass_banner.dart';
import 'colored_split_promo_banner.dart';
import 'flip_portrait.dart';
import 'glass_wrap.dart';
import 'nwsb_icon.dart';
import 'program_shelf.dart';

class FourBanners extends StatelessWidget {
  const FourBanners({
    super.key,
    this.splitTitle = 'NowssB',
    this.splitCta = 'Open',
    this.blackTitle = 'NowssB',
    this.blackSub = 'Words, rewards, and what you have earned.',
  });

  final String splitTitle;
  final String splitCta;
  final String blackTitle;
  final String blackSub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TrioRail(),
        const SizedBox(height: 12),
        ColoredSplitPromoBanner(
          margin: EdgeInsets.zero,
          spec: SplitPromoSpec(
            title: splitTitle,
            cta: splitCta,
            leftColor: const Color(0xFF3D2914),
            rightColor: const Color(0xFFE4C56A),
            art: SplitPromoArts.blondeLotus,
          ),
        ),
        const SizedBox(height: 12),
        BlackGlassBanner(
          margin: EdgeInsets.zero,
          title: blackTitle,
          subtitle: blackSub,
          mark: NwsbMarks.rewards,
        ),
        const SizedBox(height: 12),
        const ProgramShelf(),
      ],
    );
  }
}

/// Equal-height flipping cards. They scroll sideways. Every card is the
/// same box, so the second one cannot come out shorter than the first.
class TrioRail extends StatelessWidget {
  const TrioRail({super.key});

  static const _h = 176.0;
  static const _w = 132.0;

  @override
  Widget build(BuildContext context) {
    final cards = <_Flip>[
      const _Flip('assets/banners/earn/hands-raise.png', 'assets/banners/earn/hands-dark.png'),
      _Flip(
        'assets/banners/earn/yoga-light.png',
        'assets/banners/earn/yoga-dark.png',
        label: 'NowssB Rewards',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const VaultScreen()),
        ),
      ),
      _Flip(
        'assets/banners/earn/man-light.png',
        'assets/banners/earn/man-dark.png',
        label: 'Your Earning',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EarningsScreen()),
        ),
      ),
      const _Flip('assets/banners/earn/sit-light.png', 'assets/banners/earn/sit-dark.png', label: 'Partner'),
    ];
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: _h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => SizedBox(width: _w, height: _h, child: cards[i]),
        ),
      ),
    );
  }
}

class _Flip extends StatelessWidget {
  const _Flip(this.front, this.back, {this.label, this.onTap});
  final String front;
  final String back;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF000000)),
            FlipPortrait(front: front, back: back, fit: BoxFit.contain),
            if (label != null)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xCC000000)],
                  ),
                ),
              ),
            if (label != null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  label!,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, height: 1.15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
