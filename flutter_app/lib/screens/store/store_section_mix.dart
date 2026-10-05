/// UI-6: varied section-type rows for the sub-store pages.
///
/// Each row is a [SectionConfig] with a stable id (`store.<page>.<slot>`) so
/// Chief of Staff's section editor can target it. There is no live
/// section-config loader yet, so these are the bundled defaults: empty or
/// NowssB-only media that the admin fills later (black/gold placeholders).
///
/// TODO(CS): when the section-config loader lands, resolve each id through
/// it first and fall back to these defaults.
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../shell/nwsb_links.dart';
import '../../widgets/sections/section_config.dart';
import '../../widgets/sections/section_registry.dart';
import 'store_cards.dart';

// ─── Shared rows ────────────────────────────────────────────────────────────

/// Title + section, so a varied row reads like the store's other rows.
class StoreMixRow extends StatelessWidget {
  const StoreMixRow({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          RmRowHeader(title: title),
          child,
        ],
      );
}

/// Builds [config] through the shared [SectionRegistry].
class StoreRegistrySection extends StatelessWidget {
  const StoreRegistrySection({super.key, required this.config});

  final SectionConfig config;

  @override
  Widget build(BuildContext context) {
    ensureSectionRegistry();
    return SectionRegistry.instance.build(context, config);
  }
}

// Configs are built once (static final / cached in State) so a rebuild on
// search typing never hands the widgets a new config (that would re-arm
// autoplay timers).

/// Section editor defaults for the type, re-keyed to [id], with [items].
SectionConfig _seed(String type, String id, List<SectionMediaItem> items) {
  ensureSectionRegistry();
  final base = SectionRegistry.instance.defaultConfigFor(type, id: id);
  return base.copyWith(
    items: items,
    // Store pages are ~340px wide: give the glassy card (200px + 14px glass
    // padding) and the coupon ticket a little more height so their text
    // never overflows.
    layout: switch (type) {
      SectionTypeId.glassyCarousel => base.layout.copyWith(height: 240),
      SectionTypeId.couponBanner => base.layout.copyWith(height: 264),
      _ => null,
    },
  );
}

/// Store-door glassy cards: titles and links only, media admin-filled.
List<SectionMediaItem> _storeDoors({required String skip}) => [
      if (skip != 'atelier')
        const SectionMediaItem(
          id: 'atelier',
          title: 'The Word Atelier',
          subtitle: 'Words described by sound',
          ctaLabel: 'Open',
          ctaLink: 'page:store.atelier',
        ),
      if (skip != 'meaning')
        const SectionMediaItem(
          id: 'meaning',
          title: 'The Meaning Store',
          subtitle: 'Meanings described by sound',
          ctaLabel: 'Open',
          ctaLink: 'page:store.meaning',
        ),
      const SectionMediaItem(
        id: 'signature',
        title: 'Signature Store',
        subtitle: 'The rarest words',
        ctaLabel: 'Open',
        ctaLink: 'page:store.signature',
      ),
      const SectionMediaItem(
        id: 'ebooks',
        title: 'eBooks',
        subtitle: 'Read the science',
        ctaLabel: 'Open',
        ctaLink: 'page:store.ebooks',
      ),
    ];

/// Programme chips under category tiles (each opens through [NwsbLinks.cta]).
List<SectionMediaItem> _programmeChips(String requestLabel) => [
      SectionMediaItem(
        id: 'chip.request',
        title: requestLabel,
        ctaLink: 'request',
        meta: const {'kind': 'chip'},
      ),
      const SectionMediaItem(
          id: 'chip.coupons', title: 'Coupons', ctaLink: 'coupons', meta: {'kind': 'chip'}),
      const SectionMediaItem(
          id: 'chip.gifts', title: 'Gifts', ctaLink: 'gifts', meta: {'kind': 'chip'}),
      const SectionMediaItem(
          id: 'chip.rewards', title: 'Rewards', ctaLink: 'rewards', meta: {'kind': 'chip'}),
    ];

// ─── Word Atelier ───────────────────────────────────────────────────────────

/// Word Atelier mix: couponBanner → hypedRow (existing) → categoryTiles →
/// glassyCarousel.
abstract final class AtelierMix {
  static const couponsId = 'store.atelier.coupons';
  static const tilesId = 'store.atelier.tiles';
  static const glassyId = 'store.atelier.glassy';

  /// Empty items → MK-1 falls back to our live wide coupons.
  static final SectionConfig coupons =
      _seed(SectionTypeId.couponBanner, couponsId, const []);

  static final SectionConfig tiles = _seed(SectionTypeId.categoryTiles, tilesId, [
        const SectionMediaItem(
          id: 'meaning',
          title: 'Meanings',
          subtitle: 'Meaning Store',
          icon: 'meaning',
          ctaLink: 'meaning',
          meta: {'glowColor': 0xFFE8A23A},
        ),
        const SectionMediaItem(
          id: 'signature',
          title: 'Signature',
          subtitle: 'Rarest words',
          icon: 'signature',
          ctaLink: 'signature',
          meta: {'glowColor': 0xFFC8A96E},
        ),
        const SectionMediaItem(
          id: 'ebooks',
          title: 'eBooks',
          subtitle: 'The science',
          icon: 'ebook',
          ctaLink: 'ebook',
          meta: {'glowColor': 0xFFE07070},
        ),
        ..._programmeChips('Request a word'),
      ]);

  /// Featured collections: category names; media admin-filled.
  static final SectionConfig glassy = _seed(SectionTypeId.glassyCarousel, glassyId, [
        for (final c in kRmCategories.take(5))
          SectionMediaItem(id: c.id, title: c.label, subtitle: c.sub),
      ]);
}

// ─── Meaning Store ──────────────────────────────────────────────────────────

/// Meaning Store mix: artistCards → categoryTiles → hypedRow (existing) →
/// glassyCarousel.
abstract final class MeaningMix {
  static const artistsId = 'store.meaning.artists';
  static const tilesId = 'store.meaning.tiles';
  static const glassyId = 'store.meaning.glassy';

  /// Featured meanings as artist cards (id = meaning key).
  static SectionConfig artists(List<MsMeaning> meanings, String Function(MsMeaning) art) =>
      _seed(SectionTypeId.artistCards, artistsId, [
        for (final m in meanings.take(6))
          SectionMediaItem(
            id: m.key,
            imageUrl: art(m),
            title: m.word,
            subtitle: m.root,
            meta: {'footer': m.category},
          ),
      ]);

  /// Tiles filter the meaning rows (id = category); chips open programmes.
  static final SectionConfig tiles = _seed(SectionTypeId.categoryTiles, tilesId, [
        const SectionMediaItem(
          id: 'Elements',
          title: 'Elements',
          subtitle: 'Earth · Water · Fire',
          icon: 'meaning',
          meta: {'glowColor': 0xFFE8A23A},
        ),
        const SectionMediaItem(
          id: 'Emotions',
          title: 'Emotions',
          subtitle: 'Feel the root',
          icon: 'flame',
          meta: {'glowColor': 0xFFE07070},
        ),
        const SectionMediaItem(
          id: 'Cosmos',
          title: 'Cosmos',
          subtitle: 'Sun · Moon · Stars',
          icon: 'star',
          meta: {'glowColor': 0xFFC8A96E},
        ),
        ..._programmeChips('Request a meaning'),
      ]);

  static final SectionConfig glassy =
      _seed(SectionTypeId.glassyCarousel, glassyId, _storeDoors(skip: 'meaning'));
}

/// Opens a tile/chip link when the page does not handle it itself.
void storeMixOpenLink(BuildContext context, SectionMediaItem item) {
  final link = (item.ctaLink ?? '').trim();
  if (link.isNotEmpty) NwsbLinks.cta(context, link);
}
