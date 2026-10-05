/// Thin type → default config + placeholder builder registry.
///
/// UI-1 (glassy carousel), UI-3 (hyped row), UI-6/7, and Maker (MK-1..3)
/// replace the stub builders. Do not rewrite this map when adding a widget —
/// call [SectionRegistry.register] or edit the entry's builder only.
library;

import 'package:flutter/widgets.dart';

import 'artist_cards_section.dart';
import 'category_tiles_section.dart';
import 'coupon_banner_section.dart';
import '../hype_rail.dart';
import 'glassy_carousel_section.dart';
import 'spotlight_section.dart';
import 'section_config.dart';

typedef SectionWidgetBuilder = Widget Function(BuildContext context, SectionConfig config);

/// One registered section type.
class SectionTypeEntry {
  const SectionTypeEntry({
    required this.type,
    required this.label,
    required this.defaultConfig,
    required this.builder,
  });

  final String type;
  final String label;

  /// Starter config (id is a placeholder; callers overwrite with the LSection id).
  final SectionConfig defaultConfig;
  final SectionWidgetBuilder builder;

  SectionTypeEntry copyWith({
    String? type,
    String? label,
    SectionConfig? defaultConfig,
    SectionWidgetBuilder? builder,
  }) =>
      SectionTypeEntry(
        type: type ?? this.type,
        label: label ?? this.label,
        defaultConfig: defaultConfig ?? this.defaultConfig,
        builder: builder ?? this.builder,
      );
}

Widget _placeholder(BuildContext context, SectionConfig config) => SizedBox(
      height: config.layout.height ?? 48,
      child: Center(
        child: Text(
          'section:${config.type}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Color(0x66FFFFFF)),
        ),
      ),
    );

SectionConfig _defaults(String type, {bool glass = false, double? height, double? cardWidth, double? cardHeight, double? spacing, double? radius}) =>
    SectionConfig(
      id: '_default.$type',
      type: type,
      style: SectionStyle(glass: glass),
      layout: SectionLayout(
        height: height,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        spacing: spacing,
        radius: radius,
      ),
    );

/// Global registry. Seeded with every known type and a labeled placeholder.
class SectionRegistry {
  SectionRegistry._();
  static final SectionRegistry instance = SectionRegistry._();

  final Map<String, SectionTypeEntry> _byType = {};

  Map<String, SectionTypeEntry> get entries => Map.unmodifiable(_byType);

  SectionTypeEntry? operator [](String type) => _byType[type];

  void register(SectionTypeEntry entry) => _byType[entry.type] = entry;

  /// Build a widget for [config], or a tiny placeholder if the type is unknown.
  Widget build(BuildContext context, SectionConfig config) {
    if (!config.enabled) return const SizedBox.shrink();
    final e = _byType[config.type];
    if (e == null) return _placeholder(context, config);
    return e.builder(context, config);
  }

  SectionConfig defaultConfigFor(String type, {required String id}) {
    final e = _byType[type];
    final base = e?.defaultConfig ?? _defaults(type);
    return base.copyWith(id: id, type: type);
  }
}

/// Seeds [SectionRegistry.instance] once. Safe to call repeatedly.
bool _seeded = false;

void ensureSectionRegistry() {
  if (_seeded) return;
  _seeded = true;
  final r = SectionRegistry.instance;
  void add(String type, String label, SectionConfig def, {SectionWidgetBuilder? builder}) {
    r.register(SectionTypeEntry(
      type: type,
      label: label,
      defaultConfig: def,
      builder: builder ?? _placeholder,
    ));
  }

  add(
    SectionTypeId.glassyCarousel,
    'Glassy carousel',
    _defaults(SectionTypeId.glassyCarousel, glass: true, height: 220, cardWidth: 160, cardHeight: 200, spacing: 12, radius: 20),
    builder: (context, config) => GlassyCarouselSection(config: config),
  );
  r.register(SectionTypeEntry(
    type: SectionTypeId.couponBanner,
    label: 'Coupon banner',
    defaultConfig: const SectionConfig(
      id: '_default.couponBanner',
      type: SectionTypeId.couponBanner,
      layout: SectionLayout(height: 248, radius: 18),
      behavior: SectionBehavior(autoplay: true, autoplayMs: 4000, loop: true),
      style: SectionStyle(glowColor: 0x66E8A23A, accent: 0xFFE8A23A),
    ),
    builder: (context, config) => CouponBannerSection(config: config),
  ));
  r.register(SectionTypeEntry(
    type: SectionTypeId.hypedRow,
    label: 'Hyped row',
    defaultConfig: const SectionConfig(
      id: '_default.hypedRow',
      type: SectionTypeId.hypedRow,
      layout: SectionLayout(height: 320, cardWidth: 146, cardHeight: 198, spacing: 12, radius: 18),
      style: SectionStyle(accent: 0xFFE8A23A),
    ),
    builder: (context, config) => NowssbHypeRail(config: config, title: ''),
  ));
  r.register(SectionTypeEntry(
    type: SectionTypeId.artistCards,
    label: 'Artist cards',
    defaultConfig: const SectionConfig(
      id: '_default.artistCards',
      type: SectionTypeId.artistCards,
      layout: SectionLayout(height: 220, cardWidth: 150, cardHeight: 190, spacing: 10, radius: 16),
      style: SectionStyle(accent: 0xFFC8A96E),
    ),
    builder: (context, config) => ArtistCardsSection(config: config),
  ));
  r.register(SectionTypeEntry(
    type: SectionTypeId.categoryTiles,
    label: 'Category tiles',
    defaultConfig: const SectionConfig(
      id: '_default.categoryTiles',
      type: SectionTypeId.categoryTiles,
      layout: SectionLayout(height: 160, cardWidth: 100, cardHeight: 120, spacing: 10, radius: 18),
      style: SectionStyle(accent: 0xFFC8A96E),
    ),
    builder: (context, config) => CategoryTilesSection(config: config),
  ));
  r.register(SectionTypeEntry(
    type: SectionTypeId.spotlight,
    label: 'Spotlight',
    defaultConfig: const SectionConfig(
      id: '_default.spotlight',
      type: SectionTypeId.spotlight,
      layout: SectionLayout(height: 320, cardHeight: 320, radius: 20),
      behavior: SectionBehavior(autoplay: true, autoplayMs: 4500, loop: true),
      style: SectionStyle(glass: true, accent: 0xFFC8A96E),
    ),
    builder: (context, config) => SpotlightSection(config: config),
  ));
  add(SectionTypeId.imageBanner, 'Image banner', _defaults(SectionTypeId.imageBanner, height: 220));
  add(SectionTypeId.videoBanner, 'Video banner', _defaults(SectionTypeId.videoBanner, height: 240));
  add(SectionTypeId.splitPromo, 'Split promo', _defaults(SectionTypeId.splitPromo, height: 170));
  add(SectionTypeId.cardRow, 'Card row',
      _defaults(SectionTypeId.cardRow, height: 190, cardWidth: 140, spacing: 10, radius: 14));
  add(SectionTypeId.textBlock, 'Text block', _defaults(SectionTypeId.textBlock));
  add(SectionTypeId.cta, 'Button', _defaults(SectionTypeId.cta));
}
