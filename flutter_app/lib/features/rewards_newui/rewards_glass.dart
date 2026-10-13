/// Page-local glass widgets for Rewards. Names mirror spec 14.2
/// (CoinChip, FilterChipRow, GiftTile, LockedCard, BreathingGlow...) so they
/// can be swapped for NowssB Bug Hunter's shared kit when it lands.
library;

import 'package:flutter/material.dart';

import '../../nowssb_ui/nowssb_ui.dart';
import '../../widgets/nwsb_coin_fly.dart';
import 'rewards_data.dart';

abstract final class RGlass {
  static const bgBottom = Color(0xFF0B0B12);
  static const violet = Color(0xFFB79CFF);
  static const gold = Color(0xFFFFD27A);
  // Reference card values.
  static const radius = 26.0;
  static const tint = Color(0xFFEDE8FF); // lavender-white
  static const cardAlpha = .18;
  static const innerAlpha = .28;
  static const blur = 24.0;
  static const pill = Color(0xFFEDEDF2);
  static const pillText = Color(0xFF1A1A22);
  static const muted = Color(0xFFC9C7D6);
}

/// Approved card glass = the kit's [NGlass] (same frosting as the approved
/// MeditationCard). [inner] = the nested, slightly more opaque panel.
class RGlassBox extends StatelessWidget {
  const RGlassBox(
      {super.key, required this.child, this.padding = const EdgeInsets.all(14), this.radius = NTokens.rCard, this.tint, this.inner = false, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;
  final bool inner;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) =>
      NGlass(radius: radius, padding: padding, elevation: inner ? .3 : 1, accent: tint ?? NTokens.violet, onTap: onTap, child: child);
}

/// Approved "Next" pill (kit white pill).
class RPill extends StatelessWidget {
  const RPill(this.label, {super.key, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GlassPill(label: label, style: PillStyle.white, dense: true, onTap: onTap);
}

class RCoinChip extends StatelessWidget {
  const RCoinChip({super.key, required this.coins, this.onTap});
  final int coins;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$coins coins, open coin history',
        child: GestureDetector(
          onTap: onTap,
          child: RGlassBox(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            radius: 30,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const NwsbCoinDisc(size: 18),
              const SizedBox(width: 6),
              Text('$coins', key: const Key('rewards.coins'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

/// Hero = the approved frosted MeditationCard carousel (neighbour peeks in).
class RHeroCarousel extends StatefulWidget {
  const RHeroCarousel({super.key, required this.slides, this.onSkip});
  final List<(String, String)> slides;
  final VoidCallback? onSkip;
  @override
  State<RHeroCarousel> createState() => _RHeroCarouselState();
}

class _RHeroCarouselState extends State<RHeroCarousel> {
  final _pc = PageController(viewportFraction: .86);
  int _i = 0;
  static const _photos = ['yoga_deck', 'sea_face', 'stones', 'lotus'];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 392,
        child: PageView.builder(
          controller: _pc,
          padEnds: false,
          itemCount: widget.slides.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, k) {
            final (t, s) = widget.slides[k];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Align(
                alignment: Alignment.topCenter,
                child: MeditationCard(
                  title: t,
                  subtitle: s,
                  image: NCircles.of(_photos[k % _photos.length]),
                  secondary: 'Skip',
                  dots: widget.slides.length,
                  dotIndex: _i,
                  cta: 'Next',
                  onCta: () => _pc.animateToPage((k + 1) % widget.slides.length, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic),
                ),
              ),
            );
          },
        ),
      );
}

class RShortcutTile extends StatelessWidget {
  const RShortcutTile({super.key, required this.icon, required this.label, this.onTap, this.dot = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dot;
  @override
  Widget build(BuildContext context) => Flexible(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(children: [
            Stack(clipBehavior: Clip.none, children: [
              RGlassBox(radius: 16, child: Icon(icon, color: RGlass.gold, size: 26)),
              if (dot) const Positioned(right: -2, top: -2, child: CircleAvatar(radius: 5, backgroundColor: Color(0xFFFF5C7A))),
            ]),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ]),
        ),
      );
}

class RDealStrip extends StatelessWidget {
  const RDealStrip({super.key, required this.title, this.endsAt, this.onTap});
  final String title;
  final DateTime? endsAt;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final left = endsAt?.difference(DateTime.now());
    final h = left == null || left.isNegative ? null : '${left.inHours}h ${left.inMinutes % 60}m left';
    return GestureDetector(
      onTap: onTap,
      child: RGlassBox(
        child: Row(children: [
          const Text('24 hour deal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
          if (h != null) Text(h, style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: 12)),
        ]),
      ),
    );
  }
}

class RTallCard extends StatelessWidget {
  const RTallCard({super.key, required this.title, required this.body, this.locked = false, this.onTap});
  final String title;
  final String body;
  final bool locked;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: locked ? null : onTap,
        child: RGlassBox(
          padding: const EdgeInsets.all(14),
          child: SizedBox.expand(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(locked ? Icons.lock_rounded : Icons.storefront_rounded, color: locked ? Colors.white54 : RGlass.gold),
              const Spacer(),
              Text(title, style: TextStyle(color: locked ? Colors.white60 : Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text(body, maxLines: 2, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 12)),
            ]),
          ),
        ),
      );
}

class RArrowBar extends StatelessWidget {
  const RArrowBar({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: RGlassBox(
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ]),
        ),
      );
}

class RFilterChips extends StatelessWidget {
  const RFilterChips({super.key, required this.options, required this.selected, required this.onSelect});
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: ListView.separated(
          key: const Key('rewards.chips'),
          scrollDirection: Axis.horizontal,
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final o = options[i];
            return Center(
              child: o == selected
                  ? GlassPill(label: o, style: PillStyle.white, dense: true, onTap: () => onSelect(o))
                  : NGlass(
                      radius: NTokens.rPill,
                      elevation: .3,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      onTap: () => onSelect(o),
                      child: Text(o, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
            );
          },
        ),
      );
}

/// My Rewards row = the approved frosted coupon ticket (CouponListCard)
/// with a rarity pill; expired rows use the kit's ExpiredOverlay.
class RGiftTile extends StatelessWidget {
  const RGiftTile({super.key, required this.item, this.onTap});
  final RewardItem item;
  final VoidCallback? onTap;
  static const _img = {RewardKind.coupon: 'singing_bowl', RewardKind.gift: 'lotus', RewardKind.chest: 'stones'};
  @override
  Widget build(BuildContext context) {
    final till = item.validTill;
    final label = [
      switch (item.kind) { RewardKind.gift => 'Gift', RewardKind.chest => 'Chest', RewardKind.coupon => 'Coupon' },
      if (item.caption.isNotEmpty) item.caption else if (till != null) 'Valid till ${till.day}/${till.month}/${till.year}',
    ].join(' \u00b7 ');
    return KeyedSubtree(
      key: Key('rewards.tile.${item.id}'),
      child: CouponListCard(
        label: label,
        offer: item.title,
        image: NCircles.of(_img[item.kind]!),
        rarity: switch (item.kind) { RewardKind.chest => Rarity.legendary, RewardKind.gift => Rarity.epic, RewardKind.coupon => Rarity.rare },
        isNew: !item.expired && till != null && till.difference(DateTime.now()).inDays > 30,
        expired: item.expired,
        onTap: item.expired ? null : onTap,
      ),
    );
  }
}

class RStateMessage extends StatelessWidget {
  const RStateMessage({super.key, required this.icon, required this.title, required this.body, this.action, this.onAction, this.compact = false});
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  final bool compact;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 32),
          child: GlassStateCard(icon: icon, title: title, message: body, action: action, onAction: onAction),
        ),
      );
}
