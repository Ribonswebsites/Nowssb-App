/// Artist-style overlapping-portrait card row (MK-2).
///
/// Dark rounded cards with a circular portrait sitting on the top edge,
/// title / subtitle, optional meta stats, and a footer line. Reads
/// [SectionConfig] when provided; otherwise falls back to [kHypeCards].
library;

import 'package:flutter/material.dart';

import '../../admin/template/editable.dart';
import '../../shell/nwsb_links.dart';
import '../../theme/tokens.dart';
import '../hype_rail.dart';
import 'section_config.dart';

/// One NowssB-flavoured meta chip (icon + count).
class _MetaStat {
  const _MetaStat({required this.icon, required this.value});
  final IconData icon;
  final String value;
}

List<_MetaStat> _statsFromMeta(Map<String, dynamic> meta) {
  final raw = meta['stats'];
  if (raw is List) {
    final out = <_MetaStat>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final value = '${e['value'] ?? e['count'] ?? ''}'.trim();
      if (value.isEmpty) continue;
      out.add(_MetaStat(icon: _iconFrom(e['icon']), value: value));
    }
    return out;
  }

  final out = <_MetaStat>[];
  void add(String key, IconData icon) {
    final v = meta[key];
    if (v == null) return;
    final s = '$v'.trim();
    if (s.isEmpty) return;
    out.add(_MetaStat(icon: icon, value: s));
  }

  add('coins', Icons.monetization_on_outlined);
  add('spins', Icons.casino_outlined);
  add('scratches', Icons.confirmation_number_outlined);
  add('saves', Icons.bookmark_border);
  add('views', Icons.visibility_outlined);
  add('plays', Icons.play_circle_outline);
  add('rewards', Icons.star_outline);
  add('gifts', Icons.card_giftcard_outlined);
  return out;
}

IconData _iconFrom(Object? raw) {
  final s = '$raw'.toLowerCase().trim();
  return switch (s) {
    'coin' || 'coins' || 'money' => Icons.monetization_on_outlined,
    'spin' || 'spins' || 'casino' => Icons.casino_outlined,
    'scratch' || 'scratches' || 'ticket' || 'coupon' => Icons.confirmation_number_outlined,
    'save' || 'saves' || 'bookmark' => Icons.bookmark_border,
    'view' || 'views' || 'eye' => Icons.visibility_outlined,
    'play' || 'plays' || 'listen' => Icons.play_circle_outline,
    'reward' || 'rewards' || 'star' => Icons.star_outline,
    'gift' || 'gifts' => Icons.card_giftcard_outlined,
    'instagram' || 'ig' => Icons.camera_alt_outlined,
    'youtube' || 'yt' => Icons.play_arrow_rounded,
    'spotify' || 'music' => Icons.music_note_outlined,
    _ => Icons.circle_outlined,
  };
}

String? _footerFrom(SectionMediaItem item) {
  final footer = (item.meta['footer'] as String?)?.trim();
  if (footer != null && footer.isNotEmpty) return footer;
  final sub2 = (item.meta['subtitle2'] as String?)?.trim();
  if (sub2 != null && sub2.isNotEmpty) return sub2;
  return null;
}

bool _showBookmark(SectionMediaItem item) {
  final b = item.meta['bookmarked'];
  if (b == true) return true;
  if (b == false) return false;
  final badge = item.meta['badge'];
  if (badge == true) return true;
  if (badge is String && badge.trim().isNotEmpty) return true;
  final icon = (item.icon ?? '').toLowerCase();
  return icon == 'bookmark' || icon == 'save';
}

List<SectionMediaItem> _itemsFromConfig(SectionConfig? config) {
  final items = config?.items ?? const <SectionMediaItem>[];
  if (items.isNotEmpty) {
    final cap = config?.behavior.itemCount;
    return cap == null ? List<SectionMediaItem>.from(items) : items.take(cap).toList();
  }

  // Fallback: NowssB programme / feature cards from the hyped rail assets.
  final cap = config?.behavior.itemCount ?? kHypeCards.length;
  final cards = kHypeCards.take(cap).toList();
  return [
    for (var i = 0; i < cards.length; i++)
      SectionMediaItem(
        id: cards[i].id,
        imageUrl: cards[i].asset,
        title: cards[i].title,
        subtitle: cards[i].line,
        ctaLink: cards[i].id,
        icon: i.isEven ? 'bookmark' : null,
        meta: {
          if (i == 0) 'coins': '120',
          if (i == 0) 'spins': '3',
          if (i == 1) 'gifts': '1',
          if (i == 1) 'saves': '8',
          if (i == 2) 'coins': '45',
          if (i == 3) 'rewards': '6',
          if (i == 4) 'plays': '2.1k',
          if (i == 5) 'views': '9.4k',
          'footer': switch (cards[i].id) {
            'coupons' => 'Scratch · daily',
            'gifts' => 'Spin · today',
            'earn' => 'Sales · live',
            'rewards' => 'Spend · catalogue',
            'signature' => 'Rare words',
            'library' => 'Listen now',
            _ => cards[i].line,
          },
        },
      ),
  ];
}

/// Horizontal rail of artist-style cards (portrait overlapping a dark panel).
class ArtistCardsSection extends StatelessWidget {
  const ArtistCardsSection({
    super.key,
    this.config,
    this.onTap,
  });

  final SectionConfig? config;
  final ValueChanged<SectionMediaItem>? onTap;

  double get _cardWidth => config?.layout.cardWidth ?? 150;
  double get _cardHeight => config?.layout.cardHeight ?? 190;
  double get _spacing => config?.layout.spacing ?? 10;
  double get _radius => config?.layout.radius ?? 16;

  double get _portraitD => (_cardWidth * 0.5).clamp(64.0, 80.0);

  double get _rowHeight {
    final configured = config?.layout.height;
    if (configured != null) return configured;
    return _cardHeight + (_portraitD / 2) + 8;
  }

  Color get _cardColor {
    final raw = config?.style.glowColor;
    // Prefer a neutral dark charcoal; glowColor is for accents elsewhere.
    if (raw != null && (raw & 0xFF000000) != 0) {
      // Only use glow as card tint when it is very dark.
      final c = Color(raw);
      if (c.computeLuminance() < 0.08) return c;
    }
    return const Color(0xFF1A1A1A);
  }

  Color get _accent {
    final raw = config?.style.accent;
    if (raw != null) return Color(raw);
    return NwsbColors.gold;
  }

  void _handleTap(BuildContext context, SectionMediaItem item) {
    if (editModeOn(context)) return;
    if (onTap != null) {
      onTap!(item);
      return;
    }
    final link = (item.ctaLink ?? '').trim();
    if (link.isEmpty) return;
    final opener = openHypeCard;
    if (opener != null && kHypeCards.any((c) => c.id == link)) {
      opener(context, link);
      return;
    }
    NwsbLinks.cta(context, link);
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsFromConfig(config);
    if (items.isEmpty) return const SizedBox.shrink();

    final portraitD = _portraitD;
    final overhang = portraitD / 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: _rowHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: EdgeInsets.only(top: overhang * 0.15, right: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => SizedBox(width: _spacing),
          itemBuilder: (context, i) {
            final item = items[i];
            return _ArtistCard(
              item: item,
              sectionId: config?.id ?? 'artist_cards',
              cardWidth: _cardWidth,
              cardHeight: _cardHeight,
              radius: _radius,
              portraitD: portraitD,
              cardColor: _cardColor,
              accent: _accent,
              onTap: () => _handleTap(context, item),
            );
          },
        ),
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({
    required this.item,
    required this.sectionId,
    required this.cardWidth,
    required this.cardHeight,
    required this.radius,
    required this.portraitD,
    required this.cardColor,
    required this.accent,
    required this.onTap,
  });

  final SectionMediaItem item;
  final String sectionId;
  final double cardWidth;
  final double cardHeight;
  final double radius;
  final double portraitD;
  final Color cardColor;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slot = '$sectionId.${item.id}';
    final title = (item.title ?? '').trim().isEmpty ? 'NowssB' : item.title!.trim();
    final subtitle = (item.subtitle ?? '').trim();
    final footer = _footerFrom(item);
    final stats = _statsFromMeta(item.meta);
    final bookmark = _showBookmark(item);
    final overhang = portraitD / 2;
    final alignment = Alignment(item.focalX, item.focalY);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: cardWidth,
        height: cardHeight + overhang,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Dark card body — starts halfway down the portrait.
            Positioned(
              top: overhang,
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10, overhang + 8, 10, 10),
                  child: Column(
                    children: [
                      EditableLabel(
                        '$slot.title',
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        EditableLabel(
                          '$slot.subtitle',
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ],
                      if (stats.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _MetaRow(stats: stats, accent: accent),
                      ],
                      const Spacer(),
                      if (footer != null && footer.isNotEmpty) ...[
                        Divider(
                          height: 12,
                          thickness: 0.6,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        EditableLabel(
                          '$slot.footer',
                          footer,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Circular portrait overlapping the top edge.
            Positioned(
              top: 0,
              child: SizedBox(
                width: portraitD,
                height: portraitD,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: portraitD,
                      height: portraitD,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0C0C0C), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.22),
                            blurRadius: 10,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Transform.scale(
                          scale: item.zoom.clamp(1.0, 8.0),
                          child: _PortraitImage(
                            imageUrl: item.imageUrl,
                            slot: '$slot.portrait',
                            alignment: alignment,
                            fit: item.fit == SectionMediaFit.contain
                                ? BoxFit.contain
                                : BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    if (bookmark)
                      Positioned(
                        right: -2,
                        top: portraitD * 0.08,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF151515),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0x33FFFFFF)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.bookmark,
                            size: 12,
                            color: accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortraitImage extends StatelessWidget {
  const _PortraitImage({
    required this.imageUrl,
    required this.slot,
    required this.alignment,
    required this.fit,
  });

  final String? imageUrl;
  final String slot;
  final Alignment alignment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    if (url.isEmpty) {
      return const ColoredBox(color: Color(0xFF111111));
    }
    if (url.startsWith('http')) {
      return EditableImage.network(
        url,
        fit: fit,
        alignment: alignment,
        slot: slot,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111)),
      );
    }
    return EditableImage.asset(
      url,
      fit: fit,
      alignment: alignment,
      slot: slot,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111)),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.stats, required this.accent});

  final List<_MetaStat> stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final shown = stats.take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              color: Colors.white.withValues(alpha: 0.18),
            ),
          Icon(shown[i].icon, size: 11, color: accent.withValues(alpha: 0.9)),
          const SizedBox(width: 3),
          Text(
            shown[i].value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
