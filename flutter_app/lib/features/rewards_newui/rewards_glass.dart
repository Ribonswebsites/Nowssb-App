/// Page-local glass widgets for Rewards. Names mirror spec 14.2
/// (CoinChip, FilterChipRow, GiftTile, LockedCard, BreathingGlow...) so they
/// can be swapped for NowssB Bug Hunter's shared kit when it lands.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

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

/// Frosted card matching card-reference-exact.png: lavender-white tint ~18%,
/// 1px soft white border, r26, strong backdrop blur, soft shadow.
/// [inner] = the slightly more opaque nested panel.
class RGlassBox extends StatelessWidget {
  const RGlassBox({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.radius = RGlass.radius, this.tint, this.inner = false});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;
  final bool inner;
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: inner ? null : const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))]),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: inner ? 10 : RGlass.blur, sigmaY: inner ? 10 : RGlass.blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              color: Color.alphaBlend((tint ?? RGlass.tint).withValues(alpha: .25), RGlass.tint).withValues(alpha: inner ? RGlass.innerAlpha : RGlass.cardAlpha),
              border: Border.all(color: Colors.white.withValues(alpha: .38), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Small light-grey pill with dark text (reference "Next").
class RPill extends StatelessWidget {
  const RPill(this.label, {super.key, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: RGlass.pill,
        shape: const StadiumBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(label, style: const TextStyle(color: RGlass.pillText, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      );
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

/// Hero banner laid out like the reference card: round photo on top, a
/// nested frosted panel with bold title, muted body, "Skip" link left,
/// light "Next" pill right, and small page dots.
class RHeroCarousel extends StatefulWidget {
  const RHeroCarousel({super.key, required this.slides, this.onSkip});
  final List<(String, String)> slides;
  final VoidCallback? onSkip;
  @override
  State<RHeroCarousel> createState() => _RHeroCarouselState();
}

class _RHeroCarouselState extends State<RHeroCarousel> {
  final _pc = PageController();
  int _i = 0;
  static const _photos = ['lotus', 'lake', 'candle_incense', 'milky_way'];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    final n = (_i + 1) % widget.slides.length;
    _pc.animateToPage(n, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 330,
        child: PageView.builder(
          controller: _pc,
          itemCount: widget.slides.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (_, k) {
            final (t, s) = widget.slides[k];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: RGlassBox(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                child: Column(children: [
                  Container(
                    width: 132, height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: AssetImage('assets/images/circles/${_photos[k % _photos.length]}.webp'), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: RGlassBox(
                      inner: true,
                      radius: 22,
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, height: 1.15)),
                        const SizedBox(height: 4),
                        Text(s, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: RGlass.muted, fontSize: 12.5, height: 1.35)),
                        const Spacer(),
                        Row(children: [
                          GestureDetector(onTap: widget.onSkip, child: const Text('Skip', style: TextStyle(color: RGlass.muted, fontSize: 12))),
                          const Spacer(),
                          for (var d = 0; d < widget.slides.length; d++)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: d == _i ? 6 : 4, height: d == _i ? 6 : 4,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: d == _i ? .9 : .4)),
                            ),
                          const Spacer(),
                          RPill('Next', onTap: _next),
                        ]),
                      ]),
                    ),
                  ),
                ]),
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
        height: 36,
        child: ListView.separated(
          key: const Key('rewards.chips'),
          scrollDirection: Axis.horizontal,
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final o = options[i];
            final on = o == selected;
            return GestureDetector(
              onTap: () => onSelect(o),
              child: on
                  ? IgnorePointer(child: RPill(o, onTap: () {}))
                  : RGlassBox(
                      inner: true,
                      radius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(o, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
            );
          },
        ),
      );
}

class RGiftTile extends StatelessWidget {
  const RGiftTile({super.key, required this.item});
  final RewardItem item;
  @override
  Widget build(BuildContext context) {
    final color = switch (item.kind) { RewardKind.gift => const Color(0xFFFF9EDB), RewardKind.chest => RGlass.gold, RewardKind.coupon => RGlass.violet };
    final icon = switch (item.kind) {
      RewardKind.gift => Icons.card_giftcard_rounded,
      RewardKind.chest => Icons.inventory_2_rounded,
      RewardKind.coupon => Icons.confirmation_number_rounded
    };
    final till = item.validTill;
    final tile = RGlassBox(
      key: Key('rewards.tile.${item.id}'),
      padding: EdgeInsets.zero,
      tint: color,
      child: Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(radius: 26, backgroundColor: color.withValues(alpha: .3), child: Icon(icon, color: Colors.white, size: 28)),
              const SizedBox(height: 8),
              Text(item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              if (item.caption.isNotEmpty)
                Text(item.caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 11)),
              if (till != null)
                Text('Valid till ${till.day}/${till.month}/${till.year}', style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 11)),
            ]),
          ),
        ),
        Container(
          height: 26,
          width: double.infinity,
          alignment: Alignment.center,
          color: item.expired ? Colors.black38 : color.withValues(alpha: .6),
          child: Text(item.expired ? 'Expired' : 'Use now', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
    return item.expired
        ? Opacity(
            opacity: .5,
            child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[.33, .33, .33, 0, 0, .33, .33, .33, 0, 0, .33, .33, .33, 0, 0, 0, 0, 0, 1, 0]), child: tile))
        : tile;
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
          child: RGlassBox(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(body, textAlign: TextAlign.center, style: const TextStyle(color: RGlass.muted, fontSize: 13)),
              if (action != null) ...[const SizedBox(height: 16), RPill(action!, onTap: onAction)],
            ]),
          ),
        ),
      );
}
