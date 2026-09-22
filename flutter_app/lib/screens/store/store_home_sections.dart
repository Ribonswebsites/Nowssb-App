/// Store browsing extras — hero video banner (Ribons Original copy removed),
/// Limited Time Free + Browse by Goal, Recommended / Featured Playlist glass,
/// tall glass playlist carousel, and mid-rail collection strips.
/// Shared by Word Atelier, Meaning Store, and Ebooks.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../data/cart_bag.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/black_glass_banner.dart';
import '../../widgets/glass_wrap.dart';
import 'store_actions.dart';
import 'store_cards.dart';

// ─── #2 Store hero video (Ribons Original copy block removed) ────────────────

class StorePixelsHero extends StatelessWidget {
  const StorePixelsHero({
    super.key,
    this.onBrowseAll,
    this.onViewCart,
    this.videoAsset,
    this.videoTitle = 'The Word Atelier',
  });

  /// Kept for call-site compatibility; branding CTAs were removed.
  final VoidCallback? onBrowseAll;
  final VoidCallback? onViewCart;
  final String? videoAsset;
  final String videoTitle;

  @override
  Widget build(BuildContext context) {
    if (videoAsset == null || videoAsset!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: StoreGlassPanel(
        radius: 20,
        padding: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NwsbVideo(asset: videoAsset!, priority: ClipPriority.feature),
                if (videoTitle.trim().isNotEmpty) ...[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x22060C18), Color(0xE6060C18)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        videoTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─── Subscribe video banner (taller + pill right-centre) ─────────────────────

class StoreSubscribeBanner extends StatelessWidget {
  const StoreSubscribeBanner({
    super.key,
    this.videoAsset,
    this.pillIconUrl,
    this.pillIconAsset,
  });

  final String? videoAsset;
  final String? pillIconUrl;
  final String? pillIconAsset;

  @override
  Widget build(BuildContext context) {
    final asset = videoAsset ?? nwsbVideo(kMsSubscribeVidFile);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          // Taller than 16/5 so video/content is not clipped.
          aspectRatio: 16 / 7.2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NwsbVideo(
                asset: asset,
                priority: ClipPriority.decoration,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0x66060C18), Color(0x22060C18)],
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0.55, 0.0), // right-centre
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xEE060C18),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: const Color(0x33E8D5A3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: pillIconAsset != null
                            ? Image.asset(
                                pillIconAsset!,
                                width: 22,
                                height: 22,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox(width: 22, height: 22),
                              )
                            : Image.network(
                                pillIconUrl ?? kMsSubscribePillIcon,
                                width: 22,
                                height: 22,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox(width: 22, height: 22),
                              ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Subscribe Today',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: NwsbColors.goldLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── #4 Recommended + Featured Bundle ────────────────────────────────────────

class StoreRecommendedSection extends StatelessWidget {
  const StoreRecommendedSection({
    super.key,
    required this.onSeeAll,
    required this.onOpenWord,
    this.meanings = false,
  });

  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price)
  onOpenWord;
  final bool meanings;

  static const _wordCards = <_RecCardData>[
    _RecCardData(
      badge: 'Free',
      badgeColor: Color(0xFF7CFF6B),
      title: 'Warrior',
      sub: 'Strength · Old French',
      word: 'warrior',
      root: 'Old French',
      img: kRmWordImg,
      price: 0,
      art: kStoreProductArt,
    ),
    _RecCardData(
      badge: 'Sale',
      badgeColor: Color(0xFFFFB74D),
      title: 'Spirit',
      sub: 'Soul · Latin',
      word: 'spirit',
      root: 'Latin',
      img: kRmWordImg,
      price: 24.5,
      art: kStoreProductArt,
    ),
    _RecCardData(
      badge: 'New',
      badgeColor: Color(0xFF5CE1FF),
      title: 'Cosmos',
      sub: 'Infinity · Greek',
      word: 'cosmos',
      root: 'Greek',
      img: kRmWordImg,
      price: 49,
      art: kStoreProductArt,
    ),
  ];

  static const _meaningCards = <_RecCardData>[
    _RecCardData(
      badge: 'Free',
      badgeColor: Color(0xFF7CFF6B),
      title: 'Warrior',
      sub: 'Strength · Inner courage',
      word: 'warrior',
      root: 'Inner courage',
      img: kMsCardImg,
      price: 0,
      art: kMsMeaningProductArt,
    ),
    _RecCardData(
      badge: 'Sale',
      badgeColor: Color(0xFFFFB74D),
      title: 'Spirit',
      sub: 'Soul · Living essence',
      word: 'spirit',
      root: 'Living essence',
      img: kMsCardImg,
      price: 24.5,
      art: kMsMeaningProductArt,
    ),
    _RecCardData(
      badge: 'New',
      badgeColor: Color(0xFF5CE1FF),
      title: 'Cosmos',
      sub: 'Infinity · Beyond form',
      word: 'cosmos',
      root: 'Beyond form',
      img: kMsCardImg,
      price: 49,
      art: kMsMeaningIconAsset,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cards = meanings ? _meaningCards : _wordCards;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Recommended for You', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final c = cards[i];
                return _RecommendedCard(
                  data: c,
                  onTap: () => onOpenWord(c.word, c.root, c.img, c.price),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecCardData {
  const _RecCardData({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.sub,
    required this.word,
    required this.root,
    required this.img,
    required this.price,
    required this.art,
  });
  final String badge;
  final Color badgeColor;
  final String title;
  final String sub;
  final String word;
  final String root;
  final String img;
  final num price;
  final String art;
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.data, required this.onTap});
  final _RecCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              data.art,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF0A0F1C)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66060C18), Color(0xF2060C18)],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: data.badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF060C18),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.sub,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xCCFFFFFF),
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

class StoreFeaturedBundleSection extends StatelessWidget {
  const StoreFeaturedBundleSection({
    super.key,
    required this.onSeeAll,
    required this.onOpenWord,
    this.meanings = false,
  });

  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price)
  onOpenWord;
  final bool meanings;

  static const _rows = <_BundleRow>[
    _BundleRow(
      'Earth',
      'Elements · Proto-Germanic',
      'earth',
      'Proto-Germanic',
      kStoreProductArt,
    ),
    _BundleRow(
      'Dragon',
      'Mythical · Greek',
      'dragon',
      'Greek',
      kStoreProductArt,
    ),
    _BundleRow('Peace', 'Peace Edition', 'peace', 'Latin', kStoreProductArt),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Featured Bundle', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          StoreGlassPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () =>
                      onOpenWord('warrior', 'Old French', kRmWordImg, 49),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          kStoreProductArt,
                          width: 78,
                          height: 78,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 78,
                            height: 78,
                            child: ColoredBox(color: Color(0xFF0A0F1C)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Warriors Edition',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              meanings
                                  ? 'A curated set of strength & courage meanings for daily healing practice.'
                                  : 'A curated set of strength & courage words for daily healing practice.',
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: Color(0x88FFFFFF),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _ItemCountPill(
                                label: meanings ? '12 MEANINGS' : '12 WORDS'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final r in _rows) ...[
                  _BundleListRow(
                    row: r,
                    onTap: () => onOpenWord(r.word, r.root, kRmWordImg, 49),
                  ),
                  if (r != _rows.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BundleRow {
  const _BundleRow(this.title, this.sub, this.word, this.root, this.art);
  final String title;
  final String sub;
  final String word;
  final String root;
  final String art;
}

class _BundleListRow extends StatelessWidget {
  const _BundleListRow({required this.row, required this.onTap});
  final _BundleRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              row.art,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 42,
                height: 42,
                child: ColoredBox(color: Color(0xFF0A0F1C)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  row.sub,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x77FFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCountPill extends StatelessWidget {
  const _ItemCountPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 12,
            color: NwsbColors.goldLight,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xCCFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        StoreViewAllControl(onTap: onSeeAll),
      ],
    );
  }
}

// ─── Shared glass panel ──────────────────────────────────────────────────────

class StoreGlassPanel extends StatelessWidget {
  const StoreGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = kGlassRadius,
    this.width,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double? width;

  /// Exact Fashion-home [GlassWrap] blur / fill / border / shadow tokens.
  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [
          BoxShadow(
            color: Color(0x57000000),
            offset: Offset(0, 16),
            blurRadius: 40,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassWrap.blurSigma,
            sigmaY: GlassWrap.blurSigma,
          ),
          child: Container(
            width: width,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              color: GlassWrap.fill,
              border: Border.all(color: GlassWrap.line),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Wide looping store film in a glass frame — used between Atelier product rows.
class StoreGlassFilmBanner extends StatelessWidget {
  const StoreGlassFilmBanner({super.key, required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: StoreGlassPanel(
        radius: 22,
        padding: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: NwsbVideo(
              asset: asset,
              priority: ClipPriority.decoration,
              autoplay: true,
              loop: true,
              showPoster: true,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── #3b Limited Time Free + Browse by Goal (frequency package) ──────────────

class StoreLimitedTimeFreeSection extends StatelessWidget {
  const StoreLimitedTimeFreeSection({
    super.key,
    this.onOpenWord,
    this.onRequestWords,
    this.meanings = false,
  });

  final void Function(String word, String root, String img, num price)?
  onOpenWord;
  final VoidCallback? onRequestWords;
  final bool meanings;

  static const _tracks = <(String, String, String)>[
    ('432 Hz', 'Relax Piano', 'assets/store/collections/peace.webp'),
    ('528 Hz', 'Calming Tones', 'assets/store/collections/sacred.webp'),
    ('639 Hz', 'Heart Open', 'assets/store/collections/nature.webp'),
  ];

  static const _tealTop = Color(0xFF2EC4B6);
  static const _tealBot = Color(0xFF0B1B3A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading: SVG hourglass (NOT emoji) + title + Request Words CTA
          Row(
            children: [
              const NwsbIcon(
                NwsbMarks.hourglass,
                size: 20,
                color: NwsbColors.goldLight,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Limited Time Free',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (onRequestWords != null)
                GestureDetector(
                  onTap: onRequestWords,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x55E8D5A3)),
                      color: const Color(0x22E8D5A3),
                    ),
                    child: Text(
                      meanings ? 'Request Meanings' : 'Request Words',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: NwsbColors.goldLight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Optional Fashion-glass notif pill (SVG + bag art) — keeps frequencies card below
          StoreNotifBanner(
            heading: 'LIMITED TIME FREE',
            svgBody: NwsbMarks.hourglass,
            artAsset: meanings ? kMsMeaningProductArt : kStoreProductArt,
            accent: _tealTop,
            sub: meanings
                ? 'Free healing tracks — request a meaning if yours is missing.'
                : 'Free healing tracks — request a word if yours is missing.',
            pillLabel: 'FREE NOW',
          ),
          const SizedBox(height: 12),
          // Teal gradient glass frequencies card — DO NOT REMOVE
          StoreGlassPanel(
            padding: EdgeInsets.zero,
            radius: 22,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_tealTop, _tealBot],
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Listen to Healing Frequencies',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Calm your mind with a free track.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 0; i < _tracks.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: onOpenWord == null
                                ? null
                                : () => onOpenWord!(
                                    _tracks[i].$1,
                                    _tracks[i].$2,
                                    kRmWordImg,
                                    0,
                                  ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Image.asset(
                                      _tracks[i].$3,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const ColoredBox(
                                            color: Color(0xFF0A0F1C),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _tracks[i].$1,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _tracks[i].$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xAAFFFFFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoreBrowseByGoalSection extends StatelessWidget {
  const StoreBrowseByGoalSection({
    super.key,
    required this.onSeeAll,
    this.onSelect,
    this.meanings = false,
  });

  final VoidCallback onSeeAll;
  final ValueChanged<String>? onSelect;
  final bool meanings;

  static const _wordGoals = <(String, String, Color)>[
    ('Focus', kStoreProductArt, Color(0xFF5CE1FF)),
    ('Calm', kStoreProductArt, Color(0xFF4DB6AC)),
    ('Sacred', kStoreProductArt, Color(0xFFFFB74D)),
    ('Nature', kStoreProductArt, Color(0xFF81C784)),
    ('Cosmos', kStoreProductArt, Color(0xFFB388FF)),
  ];

  static const _meaningGoals = <(String, String, Color)>[
    ('Focus', kMsMeaningIconAsset, Color(0xFF5CE1FF)),
    ('Calm', kMsMeaningProductArt, Color(0xFF4DB6AC)),
    ('Sacred', kMsMeaningIconAsset, Color(0xFFFFB74D)),
    ('Nature', kMsMeaningProductArt, Color(0xFF81C784)),
    ('Cosmos', kMsMeaningIconAsset, Color(0xFFB388FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Browse by Goal', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: (meanings ? _meaningGoals : _wordGoals).length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final g = (meanings ? _meaningGoals : _wordGoals)[i];
                return GestureDetector(
                  onTap: onSelect == null
                      ? null
                      : () => onSelect!(g.$1.toLowerCase()),
                  child: SizedBox(
                    width: 86,
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: g.$3, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: g.$3.withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              g.$2,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const ColoredBox(color: Color(0xFF0A0F1C)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          g.$1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Image-3 package: frequency grid + Limited Time Free + Browse by Goal.
class StoreFrequencyPackage extends StatelessWidget {
  const StoreFrequencyPackage({
    super.key,
    required this.onSelectCategory,
    required this.onSeeAll,
    this.onOpenWord,
    this.onRequestWords,
    this.meanings = false,
  });

  final ValueChanged<String> onSelectCategory;
  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price)?
  onOpenWord;
  final VoidCallback? onRequestWords;
  final bool meanings;

  @override
  Widget build(BuildContext context) {
    // HEAL BY CATEGORY 2×2 grid removed — keep Limited Time Offer + Browse by Goal.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoreLimitedTimeFreeSection(
          onOpenWord: onOpenWord,
          onRequestWords: onRequestWords,
          meanings: meanings,
        ),
        StoreBrowseByGoalSection(
          onSeeAll: onSeeAll,
          onSelect: onSelectCategory,
          meanings: meanings,
        ),
      ],
    );
  }
}

// ─── #4b Featured Playlist glass (exact layout from ref) ─────────────────────

class StoreFeaturedPlaylistSection extends StatelessWidget {
  const StoreFeaturedPlaylistSection({
    super.key,
    required this.onSeeAll,
    required this.onOpenWord,
    this.meanings = false,
  });

  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price)
  onOpenWord;
  final bool meanings;

  static const _wordRows = <_BundleRow>[
    _BundleRow(
      'Deep Healing',
      'Emotional & Physical',
      'peace',
      'Latin',
      kStoreProductArt,
    ),
    _BundleRow(
      'Healing Frequency',
      'Healing Meditation',
      'spirit',
      'Latin',
      kStoreProductArt,
    ),
    _BundleRow(
      'Remove Negative',
      'Healing Reiki Music',
      'earth',
      'Proto-Germanic',
      kStoreProductArt,
    ),
  ];

  static const _meaningRows = <_BundleRow>[
    _BundleRow(
      'Deep Healing',
      'Emotional & Physical',
      'peace',
      'Calm meaning',
      kMsMeaningProductArt,
    ),
    _BundleRow(
      'Healing Frequency',
      'Healing Meditation',
      'spirit',
      'Soul meaning',
      kMsMeaningIconAsset,
    ),
    _BundleRow(
      'Remove Negative',
      'Healing Reiki Music',
      'earth',
      'Grounding meaning',
      kMsMeaningProductArt,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Featured Playlist', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          StoreGlassPanel(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => onOpenWord('balance', 'Inner', kRmWordImg, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          meanings ? kMsMeaningProductArt : kStoreProductArt,
                          width: 78,
                          height: 78,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 78,
                            height: 78,
                            child: ColoredBox(color: Color(0xFF0A0F1C)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inner Balance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'If you\'re looking for some chill tones to restore balance and deep focus…',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: Color(0x88FFFFFF),
                              ),
                            ),
                            SizedBox(height: 8),
                            _ItemCountPill(label: '4 SESSIONS'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final r in (meanings ? _meaningRows : _wordRows)) ...[
                  _BundleListRow(
                    row: r,
                    onTap: () => onOpenWord(r.word, r.root, kRmWordImg, 49),
                  ),
                  if (r != (meanings ? _meaningRows : _wordRows).last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── #5 Tall 3-card horizontal glass playlist carousel ───────────────────────

class StoreGlassPlaylistCarousel extends StatelessWidget {
  const StoreGlassPlaylistCarousel({
    super.key,
    required this.onSeeAll,
    required this.onOpenWord,
    this.meanings = false,
  });

  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price)
  onOpenWord;
  final bool meanings;

  static const _wordCards = <_GlassPlaylistCardData>[
    _GlassPlaylistCardData(
      title: 'Warriors Edition',
      desc: 'Strength & courage words for daily practice.',
      count: '12 WORDS',
      art: kStoreProductArt,
      rows: [
        ('Warrior', 'Old French'),
        ('Dragon', 'Greek'),
        ('Earth', 'Proto-Germanic'),
      ],
    ),
    _GlassPlaylistCardData(
      title: 'Sacred Frequency',
      desc: 'Divine codes and soft healing tones.',
      count: '8 SESSIONS',
      art: kStoreProductArt,
      rows: [('Spirit', 'Latin'), ('Peace', 'Latin'), ('Om', 'Sanskrit')],
    ),
    _GlassPlaylistCardData(
      title: 'Nature Resonance',
      desc: 'Living elements for calm and clarity.',
      count: '10 WORDS',
      art: kStoreProductArt,
      rows: [
        ('Water', 'Proto-Germanic'),
        ('Fire', 'Proto-Germanic'),
        ('Wind', 'Proto-Germanic'),
      ],
    ),
  ];

  static const _meaningCards = <_GlassPlaylistCardData>[
    _GlassPlaylistCardData(
      title: 'Warriors Edition',
      desc: 'Strength & courage meanings for daily practice.',
      count: '12 MEANINGS',
      art: kMsMeaningProductArt,
      rows: [
        ('Warrior', 'Inner courage'),
        ('Dragon', 'Transforming power'),
        ('Earth', 'Grounding presence'),
      ],
    ),
    _GlassPlaylistCardData(
      title: 'Sacred Frequency',
      desc: 'Divine codes and soft healing tones.',
      count: '8 MEANINGS',
      art: kMsMeaningIconAsset,
      rows: [
        ('Spirit', 'Living essence'),
        ('Peace', 'Still centre'),
        ('Om', 'Sacred resonance'),
      ],
    ),
    _GlassPlaylistCardData(
      title: 'Nature Resonance',
      desc: 'Living element meanings for calm and clarity.',
      count: '10 MEANINGS',
      art: kMsMeaningProductArt,
      rows: [
        ('Water', 'Flowing life'),
        ('Fire', 'Inner spark'),
        ('Wind', 'Clear breath'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Featured Collections', onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          SizedBox(
            height: 292,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: (meanings ? _meaningCards : _wordCards).length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final c = (meanings ? _meaningCards : _wordCards)[i];
                return StoreGlassPanel(
                  width: 268,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => onOpenWord(
                          c.rows.first.$1.toLowerCase(),
                          c.rows.first.$2,
                          kRmWordImg,
                          49,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                c.art,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: ColoredBox(color: Color(0xFF0A0F1C)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      height: 1.35,
                                      color: Color(0x88FFFFFF),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _ItemCountPill(label: c.count),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var r = 0; r < c.rows.length; r++) ...[
                        GestureDetector(
                          onTap: () => onOpenWord(
                            c.rows[r].$1.toLowerCase(),
                            c.rows[r].$2,
                            kRmWordImg,
                            49,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  c.art,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: ColoredBox(color: Color(0xFF0A0F1C)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.rows[r].$1,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      c.rows[r].$2,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0x77FFFFFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (r != c.rows.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPlaylistCardData {
  const _GlassPlaylistCardData({
    required this.title,
    required this.desc,
    required this.count,
    required this.art,
    required this.rows,
  });
  final String title;
  final String desc;
  final String count;
  final String art;
  final List<(String, String)> rows;
}

// ─── Mid-rail notification glass banners (6 variants, between every 2 rows) ──

class StoreMidRailBannerData {
  const StoreMidRailBannerData({
    required this.heading,
    required this.artAsset,
    required this.accent,
    this.svgBody,
    this.sub = '',
    this.pillLabel,
  });

  final String heading;
  final String artAsset;
  final Color accent;
  final String? svgBody;
  final String sub;
  final String? pillLabel;
}

/// Six black notification banners between product rows. Art is always the
/// NowssB bag-headphones product — never fashion heels / meditation stock.
const kStoreMidRailBanners = <StoreMidRailBannerData>[
  StoreMidRailBannerData(
    heading: 'COLLECTIONS',
    artAsset: kStoreProductArt,
    accent: Color(0xFF5CE1FF),
    svgBody: NwsbMarks.bag,
    sub: 'Sacred · Warrior · Elements',
    pillLabel: 'COLLECTIONS',
  ),
  StoreMidRailBannerData(
    heading: 'CURATED RAILS',
    artAsset: kStoreProductArt,
    accent: Color(0xFF26A69A),
    svgBody: NwsbMarks.flame,
    sub: 'Time & Cosmos picks',
    pillLabel: '50% OFF',
  ),
  StoreMidRailBannerData(
    heading: 'FEATURED DROP',
    artAsset: kStoreProductArt,
    accent: Color(0xFFFFB74D),
    svgBody: NwsbMarks.word,
    sub: 'Limited atelier editions',
    pillLabel: 'FEATURED',
  ),
  StoreMidRailBannerData(
    heading: 'WORD ATELIER',
    artAsset: kStoreProductArt,
    accent: Color(0xFFB388FF),
    svgBody: NwsbMarks.sound,
    sub: 'Real bag · real sound',
    pillLabel: 'ATELIER',
  ),
  StoreMidRailBannerData(
    heading: 'ELEMENTS',
    artAsset: kStoreProductArt,
    accent: Color(0xFFFF6BCB),
    svgBody: NwsbMarks.sound,
    sub: 'Earth · Water · Fire · Air',
    pillLabel: 'ELEMENTS',
  ),
  StoreMidRailBannerData(
    heading: 'ELITE WORDS',
    artAsset: kStoreProductArt,
    accent: Color(0xFF7CFF6B),
    svgBody: NwsbMarks.crown,
    sub: 'Rarest catalogue entries',
    pillLabel: 'ELITE',
  ),
];

/// Taller notification-style glass strip: heading above black pill with
/// LEFT text | separator | RIGHT small circular bag/word image + ripple.
class StoreMidRailBanner extends StatelessWidget {
  const StoreMidRailBanner({super.key, required this.data, this.onTap});

  final StoreMidRailBannerData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: StoreNotifBanner(
          heading: data.heading,
          svgBody: data.svgBody ?? NwsbMarks.bag,
          artAsset: data.artAsset,
          accent: data.accent,
          sub: data.sub,
          pillLabel: data.pillLabel ?? data.heading,
        ),
      ),
    );
  }
}

/// Inserts banner [index] (0..5) — safe no-op if out of range.
Widget? storeMidRailBannerAt(int index) {
  if (index < 0 || index >= kStoreMidRailBanners.length) return null;
  return StoreMidRailBanner(data: kStoreMidRailBanners[index]);
}

// ─── Shared notification glass banner (Limited / mid-rails / section pills) ─

class StoreNotifBanner extends StatelessWidget {
  const StoreNotifBanner({
    super.key,
    required this.heading,
    required this.svgBody,
    required this.artAsset,
    required this.accent,
    this.sub = '',
    this.trailing,
    this.pillLabel,
  });

  final String heading;
  final String svgBody;
  final String artAsset;
  final Color accent;
  final String sub;
  final Widget? trailing;

  /// Short label inside the black pill (defaults to [heading]).
  final String? pillLabel;

  @override
  Widget build(BuildContext context) {
    final left = (pillLabel ?? heading).trim();
    return StoreGlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  heading,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: accent,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(fontSize: 11, color: Color(0x88FFFFFF)),
            ),
          ],
          const SizedBox(height: 10),
          StoreBlackPill(
            label: left.isEmpty ? 'STORE' : left,
            artAsset: artAsset.isEmpty ? kStoreProductArt : artAsset,
            accent: accent,
            svgBody: svgBody,
          ),
        ],
      ),
    );
  }
}

// ─── View all → blur + 3D carousel glass panel ───────────────────────────────

class StoreViewAllItem {
  const StoreViewAllItem({
    required this.title,
    required this.sub,
    required this.art,
    required this.word,
    required this.root,
    required this.img,
    required this.price,
  });

  final String title;
  final String sub;
  final String art;
  final String word;
  final String root;
  final String img;
  final num price;
}

Future<void> showStoreViewAllPanel(
  BuildContext context, {
  required String title,
  required List<StoreViewAllItem> items,
  required void Function(String word, String root, String img, num price)
  onOpenWord,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, anim, secondary) {
      return _StoreViewAllOverlay(
        title: title,
        items: items,
        onOpenWord: onOpenWord,
      );
    },
    transitionBuilder: (ctx, anim, secondary, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

List<StoreViewAllItem> storeDefaultViewAllItems() {
  const cats = <(String, String, String)>[
    ('Sacred Divine', 'Consciousness', kStoreProductArt),
    ('Warrior', 'Strength', kStoreProductArt),
    ('Elements', 'Nature', kStoreProductArt),
    ('Time & Cosmos', 'Infinity', kStoreProductArt),
    ('Peace', 'Stillness', kStoreProductArt),
    ('Mythical', 'Ancient forces', kStoreProductArt),
  ];
  return [
    for (final c in cats)
      StoreViewAllItem(
        title: c.$1,
        sub: c.$2,
        art: c.$3,
        word: c.$1.split(' ').first.toLowerCase(),
        root: c.$2,
        img: kRmWordImg,
        price: 49,
      ),
  ];
}

class _StoreViewAllOverlay extends StatefulWidget {
  const _StoreViewAllOverlay({
    required this.title,
    required this.items,
    required this.onOpenWord,
  });

  final String title;
  final List<StoreViewAllItem> items;
  final void Function(String word, String root, String img, num price)
  onOpenWord;

  @override
  State<_StoreViewAllOverlay> createState() => _StoreViewAllOverlayState();
}

class _StoreViewAllOverlayState extends State<_StoreViewAllOverlay> {
  late final PageController _page;
  double _pageValue = 0;

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: 0.62);
    _page.addListener(() {
      setState(() => _pageValue = _page.page ?? 0);
    });
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  StoreViewAllItem get _current {
    if (widget.items.isEmpty) {
      return const StoreViewAllItem(
        title: 'Word',
        sub: 'Atelier',
        art: kStoreProductArt,
        word: 'word',
        root: 'NowssB',
        img: kRmWordImg,
        price: 49,
      );
    }
    final i = _pageValue.round().clamp(0, widget.items.length - 1);
    return widget.items[i];
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: const Color(0x66060C18)),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StoreGlassPanel(
                  radius: 26,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x22FFFFFF),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 220,
                        child: PageView.builder(
                          controller: _page,
                          itemCount: widget.items.length,
                          itemBuilder: (context, i) {
                            final delta = (i - _pageValue);
                            final abs = delta.abs().clamp(0.0, 1.5);
                            final scale = 1 - (abs * 0.12);
                            final rotY = delta * 0.55;
                            final item = widget.items[i];
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0014)
                                ..rotateY(rotY)
                                ..scaleByDouble(scale, scale, scale, 1.0),
                              child: Opacity(
                                opacity: (1 - abs * 0.35).clamp(0.45, 1.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    widget.onOpenWord(
                                      item.word,
                                      item.root,
                                      item.img,
                                      item.price,
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0x33FFFFFF),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x88000000),
                                          blurRadius: 18,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.asset(
                                          item.art,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const ColoredBox(
                                                color: Color(0xFF0A0F1C),
                                              ),
                                        ),
                                        const DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0x33060C18),
                                                Color(0xF2060C18),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.title,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  item.sub,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xAAFFFFFF),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _current.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _WhiteCircleAction(
                            label: 'Buy Now',
                            mark: NwsbMarks.bag,
                            wide: true,
                            onTap: () {
                              final c = _current;
                              storeBuyNow(
                                context,
                                wordBagItem(
                                  name: c.title,
                                  root: c.root,
                                  img: c.img,
                                  price: c.price,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _WhiteCircleAction(
                            mark: NwsbMarks.wishlist,
                            onTap: () {
                              CartBag.instance.addWishlist(
                                wordBagItem(
                                  name: _current.title,
                                  root: _current.root,
                                  img: _current.img,
                                  price: _current.price,
                                ),
                              );
                              _toast('Saved ${_current.title} to wishlist');
                            },
                          ),
                          const SizedBox(width: 10),
                          _WhiteCircleAction(
                            icon: Icons.thumb_up_alt_outlined,
                            onTap: () => _toast('Liked ${_current.title}'),
                          ),
                          const SizedBox(width: 10),
                          _WhiteCircleAction(
                            mark: NwsbMarks.cart,
                            onTap: () {
                              storeAddToCart(
                                context,
                                wordBagItem(
                                  name: _current.title,
                                  root: _current.root,
                                  img: _current.img,
                                  price: _current.price,
                                ),
                              );
                              _toast('Added ${_current.title} to cart');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCircleAction extends StatelessWidget {
  const _WhiteCircleAction({
    this.icon,
    this.mark,
    this.label,
    required this.onTap,
    this.wide = false,
  });

  final IconData? icon;
  final String? mark;
  final String? label;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final child = label != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mark != null) ...[
                NwsbIcon(mark!, size: 15, color: const Color(0xFF060C18)),
                const SizedBox(width: 6),
              ],
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF060C18),
                ),
              ),
            ],
          )
        : (mark != null
              ? NwsbIcon(mark!, size: 18, color: const Color(0xFF060C18))
              : Icon(icon, size: 20, color: const Color(0xFF060C18)));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: wide ? null : 46,
        padding: wide ? const EdgeInsets.symmetric(horizontal: 16) : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: wide ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: wide ? BorderRadius.circular(23) : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ─── Quick mosaic (Words / Request / Meanings + pills) ───────────────────────

/// Words tile + Request a word + Meanings + atelier pills row.
/// Used on Word Atelier (below first 50% OFF). Formerly on Store home.
class StoreQuickMosaic extends StatelessWidget {
  const StoreQuickMosaic({
    super.key,
    required this.onWords,
    required this.onMeanings,
    required this.onSignature,
    required this.onEbooks,
    required this.onRequest,
  });

  final VoidCallback onWords;
  final VoidCallback onMeanings;
  final VoidCallback onSignature;
  final VoidCallback onEbooks;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: HeavyGlassPanel(
                    margin: EdgeInsets.zero,
                    radius: 22,
                    padding: const EdgeInsets.all(5),
                    child: SizedBox.expand(
                      child: _MosaicTile(
                        title: 'Words',
                        sub: 'The Word Atelier',
                        mark: NwsbMarks.bag,
                        video: 'assets/video/store-orb-box.mp4',
                        onTap: onWords,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Expanded(
                        child: _MosaicBar(
                          title: 'Request a word',
                          sub: 'Ask for a sound',
                          mark: NwsbMarks.bell,
                          onTap: onRequest,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _MosaicBar(
                          title: 'Meanings',
                          sub: 'Decoded origins',
                          mark: NwsbMarks.bag,
                          onTap: onMeanings,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _MosaicPill(label: 'Atelier', mark: NwsbMarks.bag, onTap: onWords),
                _MosaicPill(label: 'Meanings', mark: NwsbMarks.bag, onTap: onMeanings),
                _MosaicPill(label: 'Signature', mark: NwsbMarks.wishlist, onTap: onSignature),
                _MosaicPill(label: 'Ebooks', mark: NwsbMarks.house, onTap: onEbooks),
                _MosaicPill(label: 'Request', mark: NwsbMarks.bell, onTap: onRequest),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MosaicTile extends StatelessWidget {
  const _MosaicTile({
    required this.title,
    required this.sub,
    required this.mark,
    required this.video,
    required this.onTap,
  });

  final String title;
  final String sub;
  final String mark;
  final String video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NwsbVideo(
              asset: video,
              priority: ClipPriority.feature,
              autoplay: true,
              loop: true,
              showPoster: true,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xE0000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NwsbIcon(mark, size: 22, color: const Color(0xFFE8D5A3)),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      color: Color(0xB8FFFFFF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MosaicBar extends StatelessWidget {
  const _MosaicBar({
    required this.title,
    required this.sub,
    required this.mark,
    required this.onTap,
  });

  final String title;
  final String sub;
  final String mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: HeavyGlassPanel(
        margin: EdgeInsets.zero,
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            NwsbIcon(mark, size: 18, color: const Color(0xFFE8D5A3)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MosaicPill extends StatelessWidget {
  const _MosaicPill({
    required this.label,
    required this.mark,
    required this.onTap,
  });

  final String label;
  final String mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xCC0C0C0E),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NwsbIcon(mark, size: 14, color: const Color(0xFFE8D5A3)),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
