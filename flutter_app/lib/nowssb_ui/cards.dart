// Card family. Base = MeditationCard (spec reference): frosted violet panel,
// circular image, bold white title, small glass pill, page dots.
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:nowssb/theme/liquid_glass_theme.dart' show NwsbEffects;
import 'glass_core.dart';
import 'pills_chips.dart';
import 'circle_assets.dart';
import 'tokens.dart';

class CircleImage extends StatelessWidget {
  const CircleImage({super.key, this.image = NCircles.yogaDeck, this.size = 140, this.ring = NTokens.violet});
  final ImageProvider? image; final double size; final Color ring;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .5), width: 2),
          boxShadow: [BoxShadow(color: ring.withValues(alpha: .55), blurRadius: 28)],
          gradient: const LinearGradient(colors: [NTokens.violet, NTokens.pink]),
          image: image == null ? null : DecorationImage(image: image!, fit: BoxFit.cover)));
}

/// V1 Meditation card, matched to /workspace/specs/card-reference-exact.png.
/// Every size is a fraction of the card width W (measured on the reference):
/// radius .10W, side padding .06W, status row .07W, photo .64W with a thin
/// light ring, inner panel radius .07W / padding .065W, title .072W w800,
/// body .031W grey, Skip .034W, white Next pill .034W dark text, dots .016W,
/// home bar .30W. Outer glass: white 18%->9%, blur 26, 1px white 36% border.
class MeditationCard extends StatelessWidget {
  const MeditationCard({super.key, required this.title, this.subtitle, this.image,
    this.cta = 'Next', this.onCta, this.secondary = 'Skip', this.onSecondary, this.dots = 3, this.dotIndex = 0,
    this.blur = NTokens.cardBlur, this.statusBar = true, this.time = '9:41', this.onClose, this.onHeart, this.liked = false,
    this.homeBar = true});
  final String title; final String? subtitle, secondary; final ImageProvider? image;
  final String cta; final VoidCallback? onCta, onSecondary, onClose, onHeart; final int? dots; final int dotIndex;
  final double blur; final bool statusBar, liked, homeBar; final String time;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 300.0;
        final r = BorderRadius.circular(w * .10);
        final reduced = NwsbEffects.instance.reduced;
        Widget card = DecoratedBox(
          decoration: BoxDecoration(borderRadius: r, border: Border.all(color: NTokens.border),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [NTokens.glassTop, NTokens.glassBottom])),
          child: Padding(padding: EdgeInsets.fromLTRB(w * .06, w * .035, w * .06, w * .03), child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (statusBar) SizedBox(height: w * .06, child: Row(children: [
              Text(time, style: TextStyle(color: Colors.white, fontSize: w * .033, fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.signal_cellular_alt_rounded, color: Colors.white, size: w * .04),
              SizedBox(width: w * .012),
              Icon(Icons.wifi_rounded, color: Colors.white, size: w * .04),
              SizedBox(width: w * .012),
              Icon(Icons.battery_full_rounded, color: Colors.white, size: w * .045),
            ])),
            SizedBox(height: w * .02),
            Row(children: [
              GestureDetector(onTap: onClose, child: Container(width: w * .05, height: w * .05,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: Icon(Icons.close_rounded, size: w * .035, color: NTokens.ink))),
              const Spacer(),
              GestureDetector(onTap: onHeart, child: Icon(liked ? Icons.favorite_rounded : Icons.favorite_rounded,
                  color: Colors.white, size: w * .06)),
            ]),
            SizedBox(height: w * .03),
            Container(width: w * .64, height: w * .64,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: .55), width: 1.2),
                    color: Colors.white.withValues(alpha: .12),
                    image: image == null ? null : DecorationImage(image: image!, fit: BoxFit.cover))),
            SizedBox(height: w * .06),
            // Inner frosted panel (lighter, own radius)
            DecoratedBox(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(w * .07),
                  border: Border.all(color: Colors.white.withValues(alpha: .30)),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [NTokens.panelTop, NTokens.panelBottom])),
              child: Padding(padding: EdgeInsets.fromLTRB(w * .065, w * .075, w * .05, w * .04),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(title, style: TextStyle(color: Colors.white, fontSize: w * .072, height: 1.18, fontWeight: FontWeight.w800)),
                  if (subtitle != null) ...[SizedBox(height: w * .035),
                    Text(subtitle!, style: TextStyle(color: NTokens.bodyGrey, fontSize: w * .031, height: 1.45))],
                  SizedBox(height: w * .04),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(child: secondary == null ? const SizedBox.shrink() : GestureDetector(onTap: onSecondary,
                        child: Text(secondary!, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withValues(alpha: .8), fontSize: w * .034, fontWeight: FontWeight.w500)))),
                    SizedBox(width: w * .02),
                    ConstrainedBox(constraints: BoxConstraints(maxWidth: w * .45), child: GestureDetector(onTap: onCta, child: Container(
                      padding: EdgeInsets.symmetric(horizontal: w * .055, vertical: w * .03),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(w * .04),
                          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.white, Color(0xFFE4E1EC)]),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(cta, maxLines: 1,
                          style: TextStyle(color: NTokens.ink, fontSize: w * .034, fontWeight: FontWeight.w700)))))),
                  ]),
                  if (dots != null) ...[SizedBox(height: w * .035), Center(child: FittedBox(fit: BoxFit.scaleDown, child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < dots!; i++) Container(width: w * .016, height: w * .016,
                        margin: EdgeInsets.symmetric(horizontal: w * .008),
                        decoration: BoxDecoration(shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: i == dotIndex ? .95 : .4))),
                  ])))],
                ])),
            ),
            if (homeBar) ...[SizedBox(height: w * .045), Container(width: w * .30, height: w * .012,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(99)))],
          ])),
        );
        card = ClipRRect(borderRadius: r, child: reduced || blur <= 0 ? card
            : BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: card));
        // No drop shadow: on translucent glass it shows through as a dark inner band.
        return RepaintBoundary(child: card);
      });
}

/// V2 Shelf product card (Flipkart shelf -> glass): image tile, name, bottom benefit pill.
class ShelfCard extends StatelessWidget {
  const ShelfCard({super.key, required this.name, required this.benefit, this.image, this.onTap, this.width = 132, this.accent = NTokens.violet});
  final String name, benefit; final ImageProvider? image; final VoidCallback? onTap; final double width; final Color accent;
  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: NGlass(radius: 22, accent: accent, onTap: onTap,
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        AspectRatio(aspectRatio: 1, child: Center(child: CircleImage(image: image, size: width * .62, ring: accent))),
        const SizedBox(height: 6),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(colors: [accent.withValues(alpha: .85), NTokens.indigoBtn])),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(benefit, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)))),
      ])));
}

/// Notch clipper: circular cutouts on left/right edges at vertical [at] (0..1).
class NotchClipper extends CustomClipper<Path> {
  const NotchClipper({this.radius = 22, this.notch = 11, this.at = .5});
  final double radius, notch, at;
  @override
  Path getClip(Size s) {
    final y = s.height * at;
    final base = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(radius)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, y), radius: notch))
      ..addOval(Rect.fromCircle(center: Offset(s.width, y), radius: notch));
    return Path.combine(PathOperation.difference, base, holes);
  }
  @override
  bool shouldReclip(covariant NotchClipper o) => o.at != at || o.notch != notch;
}

class DashedLine extends StatelessWidget {
  const DashedLine({super.key, this.vertical = false});
  final bool vertical;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final len = vertical ? c.maxHeight : c.maxWidth; final n = (len / 9).floor();
        final dash = SizedBox(width: vertical ? 1 : 5, height: vertical ? 5 : 1, child: const ColoredBox(color: Colors.white54));
        return vertical ? Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.filled(n, dash))
            : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.filled(n, dash));
      });
}

/// V3 Coin Terminal ticket: gradient body, side notches at tear line, dashed divider, logo pill.
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.headline, required this.pillLabel, this.top,
    this.accent = NTokens.epic, this.onTap, this.width = 220, this.height = 250});
  final String headline, pillLabel; final Widget? top; final Color accent; final VoidCallback? onTap;
  final double width, height;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: SizedBox(width: width, height: height,
      child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: NTokens.glow(accent, .8)),
        child: ClipPath(clipper: const NotchClipper(at: .68), child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color.alphaBlend(accent.withValues(alpha: .55), NTokens.glassLiteTop), NTokens.bgMid.withValues(alpha: .85)]),
              border: Border.all(color: NTokens.border)),
          child: Column(children: [
            Expanded(flex: 68, child: Padding(padding: const EdgeInsets.all(14), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (top != null) Expanded(child: Center(child: top!)) else const Spacer(),
              Text(headline, maxLines: 2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ]))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SizedBox(height: 1, child: DashedLine())),
            Expanded(flex: 32, child: Center(child: GlassPill(label: pillLabel, style: PillStyle.white, dense: true, onTap: onTap))),
          ]))))));
}

/// V4 Coupon list row: image left, label + bold offer + "View products >", New badge, side notches.
class CouponListCard extends StatelessWidget {
  const CouponListCard({super.key, required this.label, required this.offer, this.image, this.isNew = false,
    this.rarity = Rarity.rare, this.onTap, this.expired = false});
  final String label, offer; final ImageProvider? image; final bool isNew, expired; final Rarity rarity; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    Widget card = ClipPath(clipper: const NotchClipper(radius: 22, notch: 10), child: NGlass(
        radius: 22, accent: rarity.color, onTap: onTap, padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(children: [
          CircleImage(image: image, size: 64, ring: rarity.color),
          const SizedBox(width: 12),
          const SizedBox(height: 64, child: DashedLine(vertical: true)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [RarityChip(rarity), if (isNew) ...[const SizedBox(width: 6), const GlassBadge('NEW')]]),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
            Text(offer, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const Text('View products >', style: TextStyle(color: NTokens.mint, fontSize: 12, fontWeight: FontWeight.w700)),
          ])),
        ])));
    if (expired) card = ExpiredOverlay(child: card);
    return card;
  }
}

class ExpiredOverlay extends StatelessWidget {
  const ExpiredOverlay({super.key, required this.child, this.label = 'Expired'});
  final Widget child; final String label;
  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, children: [
        Opacity(opacity: .45, child: ColorFiltered(colorFilter: const ColorFilter.matrix(<double>[
          .33, .33, .33, 0, 0, .33, .33, .33, 0, 0, .33, .33, .33, 0, 0, 0, 0, 0, 1, 0]), child: child)),
        GlassPill(label: label, style: PillStyle.outlined, dense: true),
      ]);
}

/// V5 Gift tile (pink/violet/amber), big circle gift icon, "Won for", valid-till footer.
class GiftTile extends StatelessWidget {
  const GiftTile({super.key, required this.color, required this.wonFor, required this.validTill, this.expired = false, this.onTap});
  final Color color; final String wonFor, validTill; final bool expired; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final t = NGlass(radius: NTokens.rCard, accent: color, tint: color, onTap: onTap, padding: EdgeInsets.zero,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.fromLTRB(14, 18, 14, 10), child: Container(width: 76, height: 76,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .18),
                  border: Border.all(color: Colors.white54), boxShadow: [BoxShadow(color: color.withValues(alpha: .6), blurRadius: 24)]),
              child: const Icon(Icons.redeem_rounded, color: Colors.white, size: 40))),
          Text('Won for $wonFor', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
              color: color.withValues(alpha: .45),
              child: Text('Valid till $validTill', textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
        ]));
    return expired ? ExpiredOverlay(child: t) : t;
  }
}

/// V6 Deal of the Day, with locked "Coming Tomorrow" state.
class DealCard extends StatelessWidget {
  const DealCard({super.key, required this.title, required this.benefit, this.image, this.locked = false, this.unlockIn});
  final String title, benefit; final ImageProvider? image; final bool locked; final Duration? unlockIn;
  @override
  Widget build(BuildContext context) => SizedBox(width: 160, child: NGlass(radius: 22, accent: locked ? NTokens.common : NTokens.coral,
      padding: const EdgeInsets.all(10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 110, child: Center(child: locked
            ? Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .12), border: Border.all(color: Colors.white38)),
                child: const Icon(Icons.lock_rounded, color: NTokens.gold, size: 36))
            : CircleImage(image: image, size: 100, ring: NTokens.coral))),
        Text(locked ? 'Coming Tomorrow' : title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (locked && unlockIn != null) CountdownPill(remaining: unlockIn!)
        else GlassPill(label: benefit, style: PillStyle.solid, dense: true, accent: NTokens.coral),
      ])));
}

/// V7 3D tilted tag tile (Earn / Burn / Exchange, 100% CoinBack).
class TiltTag extends StatelessWidget {
  const TiltTag({super.key, required this.label, this.sub, this.color = NTokens.pink, this.angle = -.12});
  final String label; final String? sub; final Color color; final double angle;
  @override
  Widget build(BuildContext context) => Transform(alignment: Alignment.center,
      transform: Matrix4.identity()..setEntry(3, 2, .0015)..rotateY(angle * 1.6)..rotateZ(angle),
      child: NGlass(radius: 18, accent: color, tint: color, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white70)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            if (sub != null) Text(sub!, style: const TextStyle(color: NTokens.textLo, fontSize: 11)),
          ])));
}

/// V8 Stat panel (tier benefits / cashback details): big-number rows with dividers.
class StatPanel extends StatelessWidget {
  const StatPanel({super.key, required this.rows});
  final List<(IconData, String, String)> rows;
  @override
  Widget build(BuildContext context) => NGlass(radius: NTokens.rHero, blur: NTokens.blurLarge, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(color: Colors.white24, height: 1),
          Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rows[i].$2, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(rows[i].$3, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
            ])),
            Icon(rows[i].$1, color: NTokens.mint, size: 28),
          ])),
        ],
      ]));
}

/// V9 Tinted info box (Applies to / Stacks with coins / Expires in) and selectable radio row.
class InfoBox extends StatelessWidget {
  const InfoBox({super.key, required this.title, required this.value, this.color = NTokens.violet, this.selected, this.onTap, this.tag});
  final String title, value; final Color color; final bool? selected; final VoidCallback? onTap; final String? tag;
  @override
  Widget build(BuildContext context) => NGlass(radius: NTokens.rBox, accent: color, tint: color, onTap: onTap, elevation: .4,
      padding: const EdgeInsets.all(14), child: Row(children: [
        if (selected != null) Padding(padding: const EdgeInsets.only(right: 10),
            child: Icon(selected! ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.white)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        ])),
        if (tag != null) GlassBadge(tag!, color: NTokens.mint),
      ]));
}

/// Tinted shelf container: title + optional countdown + see-all + horizontal rail.
class ShelfContainer extends StatelessWidget {
  const ShelfContainer({super.key, required this.title, required this.children, this.countdown, this.onSeeAll, this.tint = NTokens.pink});
  final String title; final List<Widget> children; final Duration? countdown; final VoidCallback? onSeeAll; final Color tint;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
      child: NGlass(radius: 28, tint: tint, accent: tint, blur: NTokens.blurLarge, padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
            if (countdown != null) CountdownPill(remaining: countdown!),
            if (onSeeAll != null) IconButton(onPressed: onSeeAll, icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white)),
          ])),
          const SizedBox(height: 12),
          SizedBox(height: 210, child: ListView.separated(scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: children.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) => children[i])),
        ])));
}

/// 3D icon shortcut row (5 tiles, one highlighted).
class ShortcutTileRow extends StatelessWidget {
  const ShortcutTileRow({super.key, required this.items, this.highlighted = 0, this.onTap});
  final List<(IconData, String)> items; final int highlighted; final ValueChanged<int>? onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
        for (var i = 0; i < items.length; i++) Expanded(child: Padding(padding: const EdgeInsets.all(4), child: NGlass(
            radius: 18, elevation: i == highlighted ? 1.2 : .3, tint: i == highlighted ? NTokens.pink : null,
            onTap: onTap == null ? null : () => onTap!(i), padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: const RadialGradient(center: Alignment(-.4, -.5), colors: [Colors.white, NTokens.mint, Color(0xFF2BA897)]),
                  boxShadow: [BoxShadow(color: NTokens.mint.withValues(alpha: .5), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Icon(items[i].$1, size: 20, color: NTokens.bgBottom)),
              const SizedBox(height: 6),
              Text(items[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ])))),
      ]));
}

/// Shimmer placeholder in glass (loading state).
class GlassSkeleton extends StatefulWidget {
  const GlassSkeleton({super.key, this.height = 120, this.radius = NTokens.rCard});
  final double height, radius;
  @override
  State<GlassSkeleton> createState() => _GlassSkeletonState();
}
class _GlassSkeletonState extends State<GlassSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  @override
  void dispose() { _a.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _a, builder: (_, __) => Container(height: widget.height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(widget.radius), border: Border.all(color: NTokens.border),
          gradient: LinearGradient(begin: Alignment(-1 + 2 * _a.value - .6, 0), end: Alignment(-1 + 2 * _a.value + .6, 0),
              colors: const [Color(0x14FFFFFF), Color(0x33FFFFFF), Color(0x14FFFFFF)]))));
}

/// Empty / error / offline state card.
class GlassStateCard extends StatelessWidget {
  const GlassStateCard({super.key, required this.icon, required this.title, required this.message, this.action, this.onAction});
  final IconData icon; final String title, message; final String? action; final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => NGlass(radius: NTokens.rHero, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: NTokens.mint), const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: NTokens.textLo)),
        if (action != null) ...[const SizedBox(height: 16), GlassPill(label: action!, style: PillStyle.white, onTap: onAction)],
      ]));
}
