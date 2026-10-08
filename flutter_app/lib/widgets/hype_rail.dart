/// District-style poster rail and the coupon ticket banner.
///
/// Layout only — NowssB posters, black / gold / white. No movie or card-brand art.
///
/// UI-3 upgrades [NowssbHypeRail]: big light-gray rank numerals behind portrait
/// posters, optional [SectionConfig] (`hypedRow`), admin black/gold placeholders.
/// Existing `const NowssbHypeRail()` call sites keep working.
library;

import 'package:flutter/material.dart';

import '../admin/layout/app_pages.dart';
import '../admin/template/editable.dart';
import '../shell/nwsb_links.dart';
import '../theme/tokens.dart';
import 'glass_wrap.dart';
import 'sections/section_config.dart';

/// Set from [ensureHypeRoutes] so this file does not import the screens.
typedef HypeOpener = void Function(BuildContext context, String id);

HypeOpener? openHypeCard;

class HypeCard {
  const HypeCard(this.id, this.asset, this.title, this.line);
  final String id;
  final String asset;
  final String title;
  final String line;
}

const kHypeCards = <HypeCard>[
  HypeCard('coupons', 'assets/gifts/coupon-hero.png', 'NowssB Coupons', 'Scratch today'),
  HypeCard('gifts', 'assets/gifts/gift-hero.png', 'NowssB Gifts', 'Daily spin'),
  HypeCard('earn', 'assets/banners/programs/earn.png', 'NowssB Earn', 'Coins on real sales'),
  HypeCard('rewards', 'assets/banners/programs/rewards.png', 'Rewards', 'Spend coins here'),
  HypeCard('signature', 'assets/hero-curve/banner-store.webp', 'Signature', 'The rarest words'),
  HypeCard('library', 'assets/hero-curve/banner-library.webp', 'Sound Library', 'Hear a word'),
];

/// Internal tile model — from [HypeCard] or [SectionMediaItem].
class _RailItem {
  const _RailItem({
    required this.id,
    required this.rank,
    required this.title,
    this.imageUrl,
    this.subtitle,
    this.hypeLine,
    this.ctaLabel,
    this.ctaLink,
    this.focalX = 0,
    this.focalY = 0,
    this.zoom = 1,
    this.fit = SectionMediaFit.cover,
    this.slot,
  });

  final String id;
  final int rank;
  final String title;
  final String? imageUrl;
  final String? subtitle;
  final String? hypeLine;
  final String? ctaLabel;
  final String? ctaLink;
  final double focalX;
  final double focalY;
  final double zoom;
  final SectionMediaFit fit;
  final String? slot;
}

String? _metaString(Map<String, dynamic> meta, List<String> keys) {
  for (final k in keys) {
    final v = meta[k];
    if (v == null) continue;
    final s = '$v'.trim();
    if (s.isNotEmpty) return s;
  }
  return null;
}

List<_RailItem> _itemsFor({
  SectionConfig? config,
  List<HypeCard>? cards,
}) {
  if (config != null && config.items.isNotEmpty) {
    final raw = config.items;
    final start = config.behavior.startIndex.clamp(0, raw.length - 1);
    var ordered = <SectionMediaItem>[
      ...raw.sublist(start),
      if (start > 0) ...raw.sublist(0, start),
    ];
    final cap = config.behavior.itemCount;
    if (cap != null && cap > 0 && cap < ordered.length) {
      ordered = ordered.sublist(0, cap);
    }
    return [
      for (var i = 0; i < ordered.length; i++)
        _RailItem(
          id: ordered[i].id,
          rank: ordered[i].rank ?? (i + 1),
          title: (ordered[i].title ?? '').trim().isEmpty ? 'Add title' : ordered[i].title!.trim(),
          imageUrl: ordered[i].imageUrl?.trim().isNotEmpty == true
              ? ordered[i].imageUrl!.trim()
              : null,
          subtitle: ordered[i].subtitle?.trim().isNotEmpty == true
              ? ordered[i].subtitle!.trim()
              : null,
          hypeLine: _metaString(ordered[i].meta, const ['hype', 'line', 'accent', 'hypeLine']),
          ctaLabel: ordered[i].ctaLabel,
          ctaLink: ordered[i].ctaLink,
          focalX: ordered[i].focalX,
          focalY: ordered[i].focalY,
          zoom: ordered[i].zoom,
          fit: ordered[i].fit,
          slot: 'hype_rail.${config.id}.${ordered[i].id}',
        ),
    ];
  }

  if (config != null && config.items.isEmpty) {
    // Admin-fillable placeholders while the section has no media yet.
    final n = (config.behavior.itemCount ?? 3).clamp(1, 8);
    return [
      for (var i = 0; i < n; i++)
        _RailItem(
          id: '_ph.$i',
          rank: i + 1,
          title: 'Add media',
          subtitle: 'Admin fillable',
          hypeLine: 'Tap to fill',
          slot: 'hype_rail.${config.id}.ph$i',
        ),
    ];
  }

  final source = cards ?? kHypeCards;
  return [
    for (var i = 0; i < source.length; i++)
      _RailItem(
        id: source[i].id,
        rank: i + 1,
        title: source[i].title,
        imageUrl: source[i].asset,
        hypeLine: source[i].line,
        ctaLink: source[i].id,
        slot: 'hype_rail.${source[i].id}',
      ),
  ];
}

/// Large portrait posters in a sideways row, with a big rank behind each one.
///
/// Standalone: `const NowssbHypeRail()` uses [kHypeCards].
/// Config-driven: pass [config] with `type: SectionTypeId.hypedRow`.
class NowssbHypeRail extends StatelessWidget {
  const NowssbHypeRail({
    super.key,
    this.title = 'Most Hyped on NowssB',
    this.config,
    this.cards,
  });

  final String title;

  /// When set, drives items + layout/behavior/style from [SectionConfig].
  final SectionConfig? config;

  /// Optional override of the default [kHypeCards] (ignored when [config] has items).
  final List<HypeCard>? cards;

  bool _reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  void _open(BuildContext context, _RailItem item) {
    final link = item.ctaLink?.trim() ?? '';
    if (link.isNotEmpty) {
      // Legacy hype ids (coupons, gifts, …) go through openHypeCard when wired.
      if (openHypeCard != null && !link.contains('/') && !link.contains(':') && !link.startsWith('http')) {
        openHypeCard!(context, link);
        return;
      }
      openRoute(context, link);
      return;
    }
    final label = item.ctaLabel?.trim() ?? '';
    if (label.isNotEmpty) {
      NwsbLinks.cta(context, label);
      return;
    }
    openHypeCard?.call(context, item.id);
  }

  @override
  Widget build(BuildContext context) {
    if (config != null && !config!.enabled) return const SizedBox.shrink();

    final layout = config?.layout ?? SectionLayout.empty;
    final style = config?.style ?? SectionStyle.empty;
    final accent = style.accent != null ? Color(style.accent!) : const Color(0xFFE8A23A);
    final items = _itemsFor(config: config, cards: cards);
    final reduce = _reduceMotion(context);

    final posterW = layout.cardWidth ?? 146;
    final posterH = layout.cardHeight ??
        (layout.aspect != null && layout.aspect! > 0 ? posterW / layout.aspect! : 198.0);
    final radius = layout.radius ?? 18;
    final spacing = layout.spacing ?? 12;
    final rankGutter = (posterW * 0.34).clamp(44.0, 58.0);
    final tileW = posterW + rankGutter;
    const textBlock = 72.0; // title + subtitle + hype
    final stackH = posterH + 16;
    final listH = layout.height ?? (stackH + textBlock);
    final pad = layout.padding ?? const EdgeInsets.only(bottom: 16);
    final showHeading = title.trim().isNotEmpty;

    Widget rail = SizedBox(
      height: listH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: reduce
            ? const ClampingScrollPhysics()
            : const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing),
        itemBuilder: (context, i) => _HypeTile(
          item: items[i],
          tileWidth: tileW,
          posterWidth: posterW,
          posterHeight: posterH,
          rankGutter: rankGutter,
          radius: radius,
          accent: accent,
          reduceMotion: reduce,
          onOpen: () => _open(context, items[i]),
        ),
      ),
    );

    if (layout.wrapperWidth != null || layout.wrapperHeight != null) {
      rail = SizedBox(
        width: layout.wrapperWidth,
        height: layout.wrapperHeight ?? listH,
        child: rail,
      );
    }

    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeading)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 12),
              child: Text(
                title,
                style: TextStyle(
                  color: StoreSurface.lightOf(context) ? const Color(0xFF16181E) : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          rail,
        ],
      ),
    );
  }
}

class _HypeTile extends StatelessWidget {
  const _HypeTile({
    required this.item,
    required this.tileWidth,
    required this.posterWidth,
    required this.posterHeight,
    required this.rankGutter,
    required this.radius,
    required this.accent,
    required this.reduceMotion,
    required this.onOpen,
  });

  final _RailItem item;
  final double tileWidth;
  final double posterWidth;
  final double posterHeight;
  final double rankGutter;
  final double radius;
  final Color accent;
  final bool reduceMotion;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final hasCta = (item.ctaLabel?.trim().isNotEmpty ?? false) ||
        (item.ctaLink?.trim().isNotEmpty ?? false) ||
        openHypeCard != null;
    final subtitle = item.subtitle?.trim();
    final hype = item.hypeLine?.trim();
    final align = Alignment(item.focalX, item.focalY);
    final fit = item.fit == SectionMediaFit.contain ? BoxFit.contain : BoxFit.cover;
    final rankSize = (posterHeight * 0.56).clamp(72.0, 128.0);

    Widget poster = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: posterWidth,
        height: posterHeight,
        child: _PosterMedia(
          imageUrl: item.imageUrl,
          slot: item.slot ?? 'hype_rail.${item.id}',
          fit: fit,
          alignment: align,
          zoom: item.zoom,
        ),
      ),
    );

    final tile = SizedBox(
      width: tileWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: posterHeight + 8,
            width: tileWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Big light-gray rank tucked behind the poster (ref 2).
                Positioned(
                  left: -4,
                  bottom: -6,
                  child: IgnorePointer(
                    child: _RankNumeral(
                      rank: item.rank,
                      fontSize: rankSize,
                      reduceMotion: reduceMotion,
                    ),
                  ),
                ),
                Positioned(
                  left: rankGutter,
                  top: 0,
                  child: poster,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: rankGutter * 0.15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: StoreSurface.lightOf(context) ? const Color(0xFF16181E) : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                if (hasCta) ...[
                  const SizedBox(width: 6),
                  _FlameCta(onTap: onOpen),
                ],
              ],
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Padding(
              padding: EdgeInsets.only(left: rankGutter * 0.15),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9A9A9A),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (hype != null && hype.isNotEmpty) ...[
            const SizedBox(height: 3),
            Padding(
              padding: EdgeInsets.only(left: rankGutter * 0.15),
              child: Text(
                hype,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: tile,
    );
  }
}

/// Light-gray rank with a subtle top→bottom fade (reference look).
class _RankNumeral extends StatelessWidget {
  const _RankNumeral({
    required this.rank,
    required this.fontSize,
    required this.reduceMotion,
  });

  final int rank;
  final double fontSize;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: fontSize,
      height: 0.85,
      fontWeight: FontWeight.w900,
      letterSpacing: -2,
      color: const Color(0xFFB8B8B8),
    );
    final text = Text('$rank', style: style);
    if (reduceMotion) return text;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFD0D0D0),
          Color(0xFF8A8A8A),
        ],
      ).createShader(bounds),
      child: text,
    );
  }
}

class _FlameCta extends StatelessWidget {
  const _FlameCta({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: const Icon(Icons.local_fire_department, size: 16, color: Colors.white),
      ),
    );
  }
}

class _PosterMedia extends StatelessWidget {
  const _PosterMedia({
    required this.imageUrl,
    required this.slot,
    required this.fit,
    required this.alignment,
    required this.zoom,
  });

  final String? imageUrl;
  final String slot;
  final BoxFit fit;
  final Alignment alignment;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    Widget child;
    if (url == null || url.isEmpty) {
      child = const _BlackGoldPlaceholder();
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      child = EditableImage.network(
        url,
        slot: slot,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => const _BlackGoldPlaceholder(),
      );
    } else {
      child = EditableImage.asset(
        url,
        slot: slot,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => const _BlackGoldPlaceholder(),
      );
    }
    if (zoom > 1.01) {
      child = Transform.scale(scale: zoom, alignment: alignment, child: child);
    }
    return child;
  }
}

class _BlackGoldPlaceholder extends StatelessWidget {
  const _BlackGoldPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A0E), Color(0xFF16120A), Color(0xFF0A0A0E)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: NwsbColors.gold, size: 32),
            SizedBox(height: 6),
            Text(
              'Add media',
              style: TextStyle(
                color: NwsbColors.goldLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide ticket promo. Same layout as a weekend offer banner, NowssB colours.
class CouponTicketPromo extends StatelessWidget {
  const CouponTicketPromo({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFF071018)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('NOWSSB', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        SizedBox(width: 8),
                        Text('✦', style: TextStyle(color: NwsbColors.goldLight, fontSize: 14)),
                        SizedBox(width: 8),
                        Text('COUPONS', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2.4)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipPath(
                      clipper: _TicketClip(),
                      child: ColoredBox(
                        color: const Color(0xFF0C0C0C),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Text('NOWSSB COUPON', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 6),
                              const Text('LIMITED', style: TextStyle(color: Color(0xFFE23B3B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6)),
                              const Text(
                                '25% OFF',
                                style: TextStyle(color: Color(0xFFE8A23A), fontSize: 36, fontWeight: FontWeight.w900, height: 1.05),
                              ),
                              const Text(
                                'on a word or a meaning · not cash',
                                style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: onPressed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A23A),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Scratch now', style: TextStyle(color: Color(0xFF1A1206), fontWeight: FontWeight.w800, fontSize: 14)),
                            SizedBox(width: 6),
                            Icon(Icons.chevron_right, size: 18, color: Color(0xFF1A1206)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _TicketClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notch = 12.0;
    final mid = size.height / 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)));
    path.addOval(Rect.fromCircle(center: Offset(0, mid), radius: notch));
    path.addOval(Rect.fromCircle(center: Offset(size.width, mid), radius: notch));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Coupon page bar: home circle, title, subtitle, optional coins, avatar.
class CouponsPageHeader extends StatelessWidget {
  const CouponsPageHeader({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x33101828),
              border: Border.all(color: const Color(0x55FFFFFF)),
            ),
            child: const Icon(Icons.home_outlined, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NowssB Coupons',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Scratch · Tickets · Shop',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(Icons.expand_more, size: 16, color: Color(0xB3FFFFFF)),
                ],
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => openHypeCard?.call(context, 'profile'),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFFE8D5A3), width: 1.4),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}
