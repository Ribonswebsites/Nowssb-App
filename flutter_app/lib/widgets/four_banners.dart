/// The four banner styles that belong on a page: the three-card earn row,
/// a split promo, a black glass row, and a sideways poster shelf.
library;

import 'package:flutter/material.dart';

import '../admin/template/editable.dart';
import '../features/earn/earnings_screen.dart';
import '../features/vault/vault_screen.dart';
import 'black_glass_banner.dart';
import 'colored_split_promo_banner.dart';
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
        const _Trio(),
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
          mark: NwsbMarks.earn,
        ),
        const SizedBox(height: 12),
        const ProgramShelf(),
      ],
    );
  }
}

class _Trio extends StatelessWidget {
  const _Trio();

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: 168,
        child: Row(
          children: [
            const Expanded(flex: 5, child: _Still('assets/banners/earn/hands-raise.png')),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _Still(
                'assets/banners/earn/yoga-light.png',
                label: 'NowssB Rewards',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const VaultScreen()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _Still(
                'assets/banners/earn/man-light.png',
                label: 'Your Earning',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const EarningsScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Still extends StatelessWidget {
  const _Still(this.asset, {this.label, this.onTap});
  final String asset;
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
            EditableImage.asset(asset, fit: BoxFit.cover, slot: 'four_banners.Trio'),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
