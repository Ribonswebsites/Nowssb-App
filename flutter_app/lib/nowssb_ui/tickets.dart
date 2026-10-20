// Approved designs only (/workspace/specs/approved-2-cards-coupons.png):
// NTicketCard (frosted coupon ticket with rarity pill) and NCardCarousel
// (horizontal rail of frosted meditation cards).
import 'package:flutter/material.dart';
import 'cards.dart';
import 'glass_core.dart';
import 'pills_chips.dart';
import 'tokens.dart';

/// Frosted coupon ticket: rarity-tinted glass, circular side notches, a
/// vertical dashed tear line, optional round image, rarity pill (+ NEW),
/// small [label], bold [title], optional [subtitle], CTA link, expired state.
class NTicketCard extends StatelessWidget {
  const NTicketCard({
    super.key, required this.title, this.label, this.subtitle, this.image,
    this.rarity = Rarity.rare, this.isNew = false, this.ctaLabel = 'View products', this.onTap, this.onCta,
    this.expired = false, this.expiredLabel = 'Expired',
  });
  final String title; final String? label, subtitle; final ImageProvider? image;
  final Rarity rarity; final bool isNew, expired; final String expiredLabel;
  /// CTA link text ('View products' by default). Pass null to hide the link.
  final String? ctaLabel;
  final VoidCallback? onTap, onCta;

  static const radius = 22.0, notch = 10.0;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    Widget card = ClipPath(clipper: const NotchClipper(radius: radius, notch: notch), child: NGlass(
      radius: radius, accent: rarity.color, tint: rarity.color, onTap: expired ? null : onTap,
      padding: const EdgeInsets.fromLTRB(20, 14, 18, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        if (image != null) ...[
          CircleImage(image: image, size: 64, ring: rarity.color),
          const SizedBox(width: 12),
        ],
        const SizedBox(width: 1, height: 64, child: DashedLine(vertical: true)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 6, runSpacing: 4, children: [RarityChip(rarity), if (isNew) const GlassBadge('NEW')]),
          const SizedBox(height: 6),
          if (label != null) Text(label!, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          if (subtitle != null) Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
          if (ctaLabel != null) GestureDetector(key: const Key('nticket-cta'), onTap: expired ? null : (onCta ?? onTap), child: Padding(padding: const EdgeInsets.only(top: 2),
              child: Text('$ctaLabel >', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: NTokens.mint, fontSize: 12, fontWeight: FontWeight.w700)))),
        ])),
      ]),
    ));
    if (expired) card = ExpiredOverlay(label: expiredLabel, child: card);
    return Semantics(label: '${rarity.name} coupon: $title${expired ? ', expired' : ''}',
        child: MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: scale.clamp(maxScaleFactor: 1.4)), child: card));
  }
}

/// One slide of [NCardCarousel].
class NCarouselItem {
  const NCarouselItem({required this.title, this.subtitle, this.image, this.cta = 'Next', this.secondary = 'Skip', this.onCta, this.onSecondary});
  final String title; final String? subtitle, secondary; final ImageProvider? image; final String cta;
  final VoidCallback? onCta, onSecondary;
}

/// Horizontal rail of frosted [MeditationCard]s (approved-2, top), with the
/// next card peeking in from the right. Height-bounded: cards scale to fit.
class NCardCarousel extends StatelessWidget {
  const NCardCarousel({super.key, required this.items, this.cardWidth = 250, this.height = 460, this.spacing = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16), this.statusBar = false, this.controller});
  final List<NCarouselItem> items; final double cardWidth, height, spacing; final EdgeInsets padding;
  final bool statusBar; final ScrollController? controller;
  @override
  Widget build(BuildContext context) => SizedBox(height: height, child: ListView.separated(
      controller: controller, scrollDirection: Axis.horizontal, padding: padding, itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(width: spacing),
      itemBuilder: (_, i) {
        final it = items[i];
        return SizedBox(width: cardWidth, child: MeditationCard(title: it.title, subtitle: it.subtitle, image: it.image,
            cta: it.cta, secondary: it.secondary, onCta: it.onCta, onSecondary: it.onSecondary,
            dots: items.length, dotIndex: i, statusBar: statusBar, homeBar: false));
      }));
}
