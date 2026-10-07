/// Category tiles with 3D-style glowing icons + filter chips (MK-3).
///
/// Dark glassy tiles in an equal-width row (phone) and a horizontal pill chip
/// rail underneath. Items with `meta['kind'] == 'chip'` feed the chips;
/// everything else is a tile. Empty config falls back to NowssB defaults.
library;

import 'package:flutter/material.dart';

import '../../admin/template/editable.dart';
import '../../shell/nwsb_links.dart';
import '../../theme/tokens.dart';
import '../nwsb_icon.dart';
import 'section_config.dart';

// ─── Defaults ───────────────────────────────────────────────────────────────

const _kDefaultTiles = <SectionMediaItem>[
  SectionMediaItem(
    id: 'coupons',
    title: 'Coupons',
    subtitle: 'Scratch & save',
    imageUrl: 'assets/gifts/coupon-hero.png',
    icon: 'coupon',
    ctaLink: 'coupons',
    meta: {'glowColor': 0xFFE8A23A},
  ),
  SectionMediaItem(
    id: 'gifts',
    title: 'Gifts',
    subtitle: 'Daily spin',
    imageUrl: 'assets/gifts/gift-hero.png',
    icon: 'gift',
    ctaLink: 'gifts',
    meta: {'glowColor': 0xFFE07070},
  ),
  SectionMediaItem(
    id: 'store',
    title: 'Store',
    subtitle: 'Shop words',
    imageUrl: 'assets/store/nowssb-bag-headphones.webp',
    icon: 'bag',
    ctaLink: 'store',
    meta: {'glowColor': 0xFFC8A96E},
  ),
];

const _kDefaultChips = <SectionMediaItem>[
  SectionMediaItem(id: 'chip.popular', title: 'Popular', meta: {'kind': 'chip'}),
  SectionMediaItem(id: 'chip.new', title: 'New', meta: {'kind': 'chip'}),
  SectionMediaItem(id: 'chip.coupons', title: 'Coupons', meta: {'kind': 'chip'}),
  SectionMediaItem(
    id: 'chip.under499',
    title: 'Under ₹499',
    meta: {'kind': 'chip'},
  ),
];

bool _isChip(SectionMediaItem item) {
  final kind = item.meta['kind'];
  return kind == 'chip' || kind == 'filter';
}

List<SectionMediaItem> _tilesFrom(SectionConfig? config) {
  final items = config?.items ?? const <SectionMediaItem>[];
  final tiles = [
    for (final it in items)
      if (!_isChip(it)) it,
  ];
  if (tiles.isEmpty) {
    final cap = config?.behavior.itemCount ?? _kDefaultTiles.length;
    return _kDefaultTiles.take(cap).toList();
  }
  final cap = config?.behavior.itemCount;
  if (cap != null && cap > 0 && cap < tiles.length) {
    return tiles.take(cap).toList();
  }
  return tiles;
}

List<SectionMediaItem> _chipsFrom(SectionConfig? config) {
  final items = config?.items ?? const <SectionMediaItem>[];
  final chips = [
    for (final it in items)
      if (_isChip(it)) it,
  ];
  if (chips.isNotEmpty) return chips;
  // Optional second list on section meta via config — not on SectionConfig
  // today; fall back to NowssB-flavoured placeholders.
  return List<SectionMediaItem>.from(_kDefaultChips);
}

Color _glowOf(SectionMediaItem item, {Color fallback = NwsbColors.gold}) {
  final raw = item.meta['glowColor'] ?? item.meta['glow'];
  if (raw is int) return Color(raw);
  if (raw is String) {
    final s = raw.trim().toLowerCase();
    final named = switch (s) {
      'gold' || 'amber' => NwsbColors.gold,
      'goldlight' || 'lightgold' => NwsbColors.goldLight,
      'red' || 'rose' => const Color(0xFFE07070),
      'purple' || 'violet' => const Color(0xFFB48CFF),
      'white' => Colors.white,
      _ => null,
    };
    if (named != null) return named;
    final hex = s.startsWith('0x')
        ? int.tryParse(s)
        : (s.startsWith('#') ? int.tryParse(s.substring(1), radix: 16) : null);
    if (hex != null) {
      // Allow #RRGGBB → ARGB with full alpha.
      if (hex <= 0xFFFFFF) return Color(0xFF000000 | hex);
      return Color(hex);
    }
  }
  return fallback;
}

String? _markBody(String? icon) {
  final s = (icon ?? '').trim().toLowerCase();
  if (s.isEmpty) return null;
  return switch (s) {
    'coupon' || 'coupons' || 'ticket' || 'scratch' => NwsbMarks.coupon,
    'gift' || 'gifts' || 'spin' => NwsbMarks.gift,
    'bag' || 'store' || 'shop' => NwsbMarks.bag,
    'word' || 'words' => NwsbMarks.word,
    'meaning' || 'meanings' => NwsbMarks.meaning,
    'book' || 'ebook' || 'ebooks' => NwsbMarks.ebook,
    'sound' || 'listen' || 'library' => NwsbMarks.sound,
    'signature' => NwsbMarks.signature,
    'crown' || 'premium' => NwsbMarks.crown,
    'earn' || 'coin' || 'coins' => NwsbMarks.earn,
    'rewards' || 'star' => NwsbMarks.rewards,
    'flame' || 'streak' => NwsbMarks.flame,
    'hourglass' || 'free' => NwsbMarks.hourglass,
    'play' => NwsbMarks.play,
    'house' || 'home' => NwsbMarks.house,
    'user' || 'account' => NwsbMarks.user,
    'bell' => NwsbMarks.bell,
    _ => null,
  };
}

IconData _materialFallback(String? icon) {
  final s = (icon ?? '').trim().toLowerCase();
  return switch (s) {
    'coupon' || 'coupons' || 'ticket' => Icons.confirmation_number_outlined,
    'gift' || 'gifts' => Icons.card_giftcard_outlined,
    'bag' || 'store' || 'shop' => Icons.shopping_bag_outlined,
    'movie' || 'movies' => Icons.movie_outlined,
    'dining' || 'food' => Icons.restaurant_outlined,
    'event' || 'events' => Icons.mic_none_outlined,
    _ => Icons.apps_outlined,
  };
}

// ─── Section ────────────────────────────────────────────────────────────────

/// Category tiles row + filter chips for [SectionTypeId.categoryTiles].
class CategoryTilesSection extends StatefulWidget {
  const CategoryTilesSection({
    super.key,
    this.config,
    this.onTileTap,
    this.onChipSelected,
  });

  final SectionConfig? config;
  final ValueChanged<SectionMediaItem>? onTileTap;
  final ValueChanged<SectionMediaItem>? onChipSelected;

  @override
  State<CategoryTilesSection> createState() => _CategoryTilesSectionState();
}

class _CategoryTilesSectionState extends State<CategoryTilesSection> {
  int _chipIndex = 0;

  double get _cardHeight => widget.config?.layout.cardHeight ?? 120;
  double get _spacing => widget.config?.layout.spacing ?? 10;
  double get _radius => widget.config?.layout.radius ?? 18;
  double? get _cardWidth => widget.config?.layout.cardWidth;

  Color get _accent {
    final raw = widget.config?.style.accent;
    if (raw != null) return Color(raw);
    return NwsbColors.gold;
  }

  void _handleTileTap(SectionMediaItem item) {
    if (widget.onTileTap != null) {
      widget.onTileTap!(item);
      return;
    }
    final link = (item.ctaLink ?? '').trim();
    if (link.isEmpty) return;
    NwsbLinks.cta(context, link);
  }

  void _handleChipTap(int index, SectionMediaItem item) {
    setState(() => _chipIndex = index);
    if (widget.onChipSelected != null) {
      widget.onChipSelected!(item);
      return;
    }
    final link = (item.ctaLink ?? '').trim();
    if (link.isNotEmpty) NwsbLinks.cta(context, link);
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _tilesFrom(widget.config);
    final chips = _chipsFrom(widget.config);
    if (tiles.isEmpty && chips.isEmpty) return const SizedBox.shrink();

    final sectionId = widget.config?.id ?? 'category_tiles';
    final configuredH = widget.config?.layout.height;
    final tileRowH = configuredH ?? (_cardHeight + 8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tiles.isNotEmpty)
            SizedBox(
              height: tileRowH,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final n = tiles.length;
                  final maxW = constraints.maxWidth;
                  final wantEqual = n <= 3;
                  final fixed = _cardWidth;
                  final needScroll = !wantEqual &&
                      fixed != null &&
                      (fixed * n + _spacing * (n - 1)) > maxW + 0.5;

                  if (needScroll) {
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: n,
                      separatorBuilder: (_, __) => SizedBox(width: _spacing),
                      itemBuilder: (context, i) => _CategoryTile(
                        item: tiles[i],
                        sectionId: sectionId,
                        width: fixed,
                        height: _cardHeight,
                        radius: _radius,
                        accent: _accent,
                        onTap: () => _handleTileTap(tiles[i]),
                      ),
                    );
                  }

                  return Row(
                    children: [
                      for (var i = 0; i < n; i++) ...[
                        if (i > 0) SizedBox(width: _spacing),
                        Expanded(
                          child: _CategoryTile(
                            item: tiles[i],
                            sectionId: sectionId,
                            width: double.infinity,
                            height: _cardHeight,
                            radius: _radius,
                            accent: _accent,
                            onTap: () => _handleTileTap(tiles[i]),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          if (chips.isNotEmpty) ...[
            SizedBox(height: tiles.isEmpty ? 0 : 14),
            SectionFilterChips(
              items: chips,
              sectionId: sectionId,
              selectedIndex: _chipIndex.clamp(0, chips.length - 1),
              accent: _accent,
              onSelected: (i, item) => _handleChipTap(i, item),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tile ───────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.item,
    required this.sectionId,
    required this.width,
    required this.height,
    required this.radius,
    required this.accent,
    required this.onTap,
  });

  final SectionMediaItem item;
  final String sectionId;
  final double width;
  final double height;
  final double radius;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slot = '$sectionId.${item.id}';
    final title =
        (item.title ?? '').trim().isEmpty ? 'NowssB' : item.title!.trim();
    final subtitle = (item.subtitle ?? '').trim();
    final glow = _glowOf(item, fallback: accent);
    final iconSize = (height * 0.38).clamp(36.0, 56.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xCC141414),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0x28FFFFFF), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                // Soft top sheen for a glass-ish feel (NowssB dark, not blue).
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: height * 0.45,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: _GlowingIcon(
                            item: item,
                            slot: '$slot.icon',
                            size: iconSize,
                            glow: glow,
                            accent: accent,
                          ),
                        ),
                      ),
                      EditableLabel(
                        '$slot.title',
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        EditableLabel(
                          '$slot.subtitle',
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            height: 1.15,
                          ),
                        ),
                      ],
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

class _GlowingIcon extends StatelessWidget {
  const _GlowingIcon({
    required this.item,
    required this.slot,
    required this.size,
    required this.glow,
    required this.accent,
  });

  final SectionMediaItem item;
  final String slot;
  final double size;
  final Color glow;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final glowBox = size * 1.75;
    return SizedBox(
      width: glowBox,
      height: glowBox,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft colored bloom behind the icon → "3D" depth on dark glass.
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glow.withValues(alpha: 0.55),
                  glow.withValues(alpha: 0.18),
                  glow.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
            child: SizedBox(width: glowBox, height: glowBox),
          ),
          SizedBox(
            width: size,
            height: size,
            child: _IconFace(
              item: item,
              slot: slot,
              size: size,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconFace extends StatelessWidget {
  const _IconFace({
    required this.item,
    required this.slot,
    required this.size,
    required this.color,
  });

  final SectionMediaItem item;
  final String slot;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = (item.imageUrl ?? '').trim();
    if (url.isNotEmpty) {
      final child = url.startsWith('http')
          ? EditableImage.network(
              url,
              fit: BoxFit.contain,
              slot: slot,
              errorBuilder: (_, __, ___) => _markOrMaterial(),
            )
          : EditableImage.asset(
              url,
              fit: BoxFit.contain,
              slot: slot,
              errorBuilder: (_, __, ___) => _markOrMaterial(),
            );
      return Transform.scale(
        scale: item.zoom.clamp(1.0, 8.0),
        child: child,
      );
    }
    return _markOrMaterial();
  }

  Widget _markOrMaterial() {
    final mark = _markBody(item.icon);
    if (mark != null) {
      return NwsbIcon(mark, size: size * 0.85, color: color, strokeWidth: 1.5);
    }
    return Icon(
      _materialFallback(item.icon),
      size: size * 0.8,
      color: color,
    );
  }
}

// ─── Filter chips ───────────────────────────────────────────────────────────

/// Horizontal dark pill chips with thin white/gold border.
///
/// Selected chip gets a brighter fill and gold border. When
/// `meta['dropdown'] == true`, a small chevron is shown after the label.
class SectionFilterChips extends StatelessWidget {
  const SectionFilterChips({
    super.key,
    required this.items,
    required this.sectionId,
    required this.selectedIndex,
    required this.onSelected,
    this.accent = NwsbColors.gold,
  });

  final List<SectionMediaItem> items;
  final String sectionId;
  final int selectedIndex;
  final void Function(int index, SectionMediaItem item) onSelected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final selected = i == selectedIndex;
          final label =
              (item.title ?? item.ctaLabel ?? '').trim().isEmpty
                  ? 'Filter'
                  : (item.title ?? item.ctaLabel)!.trim();
          final dropdown = item.meta['dropdown'] == true;
          final slot = '$sectionId.chip.${item.id}';

          return GestureDetector(
            onTap: () => onSelected(i, item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(14, 7, dropdown ? 10 : 14, 7),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFF141414),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: selected
                      ? accent.withValues(alpha: 0.85)
                      : const Color(0x33FFFFFF),
                  width: 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EditableLabel(
                    slot,
                    label,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  if (dropdown) ...[
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: selected
                          ? accent
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
