/// Page-local glass widgets for Rewards. Names mirror spec 14.2
/// (CoinChip, FilterChipRow, GiftTile, LockedCard, BreathingGlow...) so they
/// can be swapped for NowssB Bug Hunter's shared kit when it lands.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'lotus_coin.dart';
import 'rewards_data.dart';

abstract final class RGlass {
  static const bgTop = Color(0xFF2A1F5C);
  static const bgBottom = Color(0xFF120D2B);
  static const violet = Color(0xFFB79CFF);
  static const gold = Color(0xFFFFD27A);
}

/// Frosted glass panel (stand-in for GlassWrapper).
class RGlassBox extends StatelessWidget {
  const RGlassBox({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.radius = 20, this.tint});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (tint ?? Colors.white).withValues(alpha: .10),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
            ),
            child: child,
          ),
        ),
      );
}

/// Procedural floating orbs + slow breathing glow (spec 16). Respects
/// reduced motion.
class RAuraBackground extends StatefulWidget {
  const RAuraBackground({super.key});
  @override
  State<RAuraBackground> createState() => _RAuraBackgroundState();
}

class _RAuraBackgroundState extends State<RAuraBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 12));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _AuraPainter(_c.value))),
      );
}

class _AuraPainter extends CustomPainter {
  _AuraPainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [RGlass.bgTop, RGlass.bgBottom]).createShader(r));
    const orbs = [(.2, .15, 90.0, Color(0x66B79CFF)), (.85, .35, 120.0, Color(0x447FD3FF)), (.3, .75, 140.0, Color(0x44FF9EDB))];
    for (var i = 0; i < orbs.length; i++) {
      final (x, y, rad, c) = orbs[i];
      final a = 2 * math.pi * (t + i / 3);
      final o = Offset(size.width * x + 14 * math.cos(a), size.height * y + 18 * math.sin(a));
      final breathe = rad * (1 + .08 * math.sin(a * 2));
      canvas.drawCircle(
          o, breathe, Paint()..shader = RadialGradient(colors: [c, c.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: breathe)));
    }
  }

  @override
  bool shouldRepaint(_AuraPainter old) => old.t != t;
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
              const Icon(Icons.spa_rounded, color: RGlass.gold, size: 18),
              const SizedBox(width: 6),
              CountUpText(coins, key: const Key('rewards.coins'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

class RHeroCarousel extends StatefulWidget {
  const RHeroCarousel({super.key, required this.slides});
  final List<(String, String)> slides;
  @override
  State<RHeroCarousel> createState() => _RHeroCarouselState();
}

class _RHeroCarouselState extends State<RHeroCarousel> {
  int _i = 0;
  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
          height: 140,
          child: PageView(
            onPageChanged: (i) => setState(() => _i = i),
            children: [
              for (final (t, s) in widget.slides)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: RGlassBox(
                    tint: RGlass.violet,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
                          const SizedBox(height: 6),
                          Text(s, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .8))),
                        ]),
                      ),
                      const LotusCoin(size: 96),
                    ]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var k = 0; k < widget.slides.length; k++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: k == _i ? 22 : 8,
              height: 4,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: k == _i ? .9 : .3), borderRadius: BorderRadius.circular(2)),
            ),
        ]),
      ]);
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
        tint: RGlass.gold,
        child: Row(children: [
          const Text('24 hour deal', style: TextStyle(color: RGlass.gold, fontWeight: FontWeight.w700)),
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
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('rewards.filter.$o'),
                label: Text(o),
                selected: o == selected,
                onSelected: (_) => onSelect(o),
                labelStyle: TextStyle(color: o == selected ? RGlass.bgBottom : Colors.white),
                selectedColor: RGlass.violet,
                backgroundColor: Colors.white.withValues(alpha: .08),
                side: BorderSide(color: Colors.white.withValues(alpha: .3)),
                showCheckmark: false,
              ),
            ),
        ]),
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
              Icon(icon, color: RGlass.violet, size: 44),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(body, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .75))),
              if (action != null) ...[
                const SizedBox(height: 14),
                FilledButton(
                    onPressed: onAction, style: FilledButton.styleFrom(backgroundColor: RGlass.violet, foregroundColor: RGlass.bgBottom), child: Text(action!)),
              ],
            ]),
          ),
        ),
      );
}
