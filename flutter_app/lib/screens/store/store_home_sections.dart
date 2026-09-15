/// Store browsing extras — hero video banner (Ribons Original copy removed),
/// Limited Time Free + Browse by Goal, Recommended / Featured Playlist glass,
/// tall glass playlist carousel, and mid-rail collection strips.
/// Shared by Word Atelier, Meaning Store, and Ebooks.
library;

import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 170,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              NwsbVideo(
                asset: videoAsset!,
                priority: ClipPriority.feature,
              ),
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
  });

  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price) onOpenWord;

  static const _cards = <_RecCardData>[
    _RecCardData(
      badge: 'Free',
      badgeColor: Color(0xFF7CFF6B),
      title: 'Warrior',
      sub: 'Strength · Old French',
      word: 'warrior',
      root: 'Old French',
      img: kRmWordImg,
      price: 0,
      art: 'assets/store/collections/warriors.webp',
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
      art: 'assets/store/collections/sacred.webp',
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
      art: 'assets/store/collections/cosmos.webp',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              itemCount: _cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final c = _cards[i];
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
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0A0F1C)),
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
  });

  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price) onOpenWord;

  static const _rows = <_BundleRow>[
    _BundleRow('Earth', 'Elements · Proto-Germanic', 'earth', 'Proto-Germanic', 'assets/store/collections/elements.webp'),
    _BundleRow('Dragon', 'Mythical · Greek', 'dragon', 'Greek', 'assets/store/collections/mythical.webp'),
    _BundleRow('Peace', 'Peace Edition', 'peace', 'Latin', 'assets/store/collections/peace.webp'),
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
                  onTap: () => onOpenWord('warrior', 'Old French', kRmWordImg, 49),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/store/collections/warriors.webp',
                          width: 78,
                          height: 78,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(width: 78, height: 78, child: ColoredBox(color: Color(0xFF0A0F1C))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warriors Edition',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'A curated set of strength & courage words for daily healing practice.',
                              style: TextStyle(fontSize: 11, height: 1.4, color: Color(0x88FFFFFF)),
                            ),
                            SizedBox(height: 8),
                            _ItemCountPill(label: '12 WORDS'),
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
              errorBuilder: (_, __, ___) =>
                  const SizedBox(width: 42, height: 42, child: ColoredBox(color: Color(0xFF0A0F1C))),
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
                  style: const TextStyle(fontSize: 11, color: Color(0x77FFFFFF)),
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
          const Icon(Icons.menu_book_outlined, size: 12, color: NwsbColors.goldLight),
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
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'View all',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0x88FFFFFF),
            ),
          ),
        ),
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
    this.radius = 22,
    this.width,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: const Color(0x99101526),
            border: Border.all(color: const Color(0x33FFFFFF)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xAA182038), Color(0x77101526)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── #3b Limited Time Free + Browse by Goal (frequency package) ──────────────

class StoreLimitedTimeFreeSection extends StatelessWidget {
  const StoreLimitedTimeFreeSection({super.key, this.onOpenWord, this.onRequestWords});

  final void Function(String word, String root, String img, num price)? onOpenWord;
  final VoidCallback? onRequestWords;

  static const _tracks = <(String, String, String, num)>[
    ('Warrior', 'Old French', 'assets/store/collections/warriors.webp', 0),
    ('Spirit', 'Latin', 'assets/store/collections/sacred.webp', 0),
    ('Peace', 'Old French', 'assets/store/collections/peace.webp', 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoreNotifBanner(
            heading: 'LIMITED TIME OFFER',
            svgBody: NwsbMarks.flame,
            artAsset: 'assets/store/nowssb-bag-headphones.webp',
            accent: const Color(0xFFFF8A3D),
            sub: 'Free atelier picks — request a word if yours is missing.',
            trailing: onRequestWords == null
                ? null
                : GestureDetector(
              onTap: onRequestWords,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x55E8D5A3)),
                  color: const Color(0x22E8D5A3),
                ),
                child: const Text(
                  'Request Words',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: NwsbColors.goldLight,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: RmWordCard.cardHeight + 4,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tracks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final t = _tracks[i];
                return RmWordCard(
                  name: t.$1,
                  root: t.$2,
                  imgUrl: kRmWordImg,
                  price: t.$4,
                  tint: storeCardTint(t.$1),
                  onTap: onOpenWord == null
                      ? null
                      : () => onOpenWord!(t.$1.toLowerCase(), t.$2, kRmWordImg, t.$4),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StoreBrowseByGoalSection extends StatelessWidget {
  const StoreBrowseByGoalSection({super.key, required this.onSeeAll, this.onSelect});

  final VoidCallback onSeeAll;
  final ValueChanged<String>? onSelect;

  static const _goals = <(String, String, Color)>[
    ('Focus', 'assets/store/collections/warriors.webp', Color(0xFF5CE1FF)),
    ('Calm', 'assets/store/collections/peace.webp', Color(0xFF4DB6AC)),
    ('Sacred', 'assets/store/collections/sacred.webp', Color(0xFFFFB74D)),
    ('Nature', 'assets/store/collections/nature.webp', Color(0xFF81C784)),
    ('Cosmos', 'assets/store/collections/cosmos.webp', Color(0xFFB388FF)),
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
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final g = _goals[i];
                return GestureDetector(
                  onTap: onSelect == null ? null : () => onSelect!(g.$1.toLowerCase()),
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
  });

  final ValueChanged<String> onSelectCategory;
  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price)? onOpenWord;
  final VoidCallback? onRequestWords;

  @override
  Widget build(BuildContext context) {
    // HEAL BY CATEGORY 2×2 grid removed — keep Limited Time Offer + Browse by Goal.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoreLimitedTimeFreeSection(onOpenWord: onOpenWord, onRequestWords: onRequestWords),
        StoreBrowseByGoalSection(onSeeAll: onSeeAll, onSelect: onSelectCategory),
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
  });

  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price) onOpenWord;

  static const _rows = <_BundleRow>[
    _BundleRow('Deep Healing', 'Emotional & Physical', 'peace', 'Latin', 'assets/store/collections/peace.webp'),
    _BundleRow('Healing Frequency', 'Healing Meditation', 'spirit', 'Latin', 'assets/store/collections/sacred.webp'),
    _BundleRow('Remove Negative', 'Healing Reiki Music', 'earth', 'Proto-Germanic', 'assets/store/collections/elements.webp'),
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
                          'assets/store/collections/peace.webp',
                          width: 78,
                          height: 78,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox(width: 78, height: 78, child: ColoredBox(color: Color(0xFF0A0F1C))),
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
                              style: TextStyle(fontSize: 11, height: 1.4, color: Color(0x88FFFFFF)),
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

// ─── #5 Tall 3-card horizontal glass playlist carousel ───────────────────────

class StoreGlassPlaylistCarousel extends StatelessWidget {
  const StoreGlassPlaylistCarousel({
    super.key,
    required this.onSeeAll,
    required this.onOpenWord,
  });

  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price) onOpenWord;

  static const _cards = <_GlassPlaylistCardData>[
    _GlassPlaylistCardData(
      title: 'Warriors Edition',
      desc: 'Strength & courage words for daily practice.',
      count: '12 WORDS',
      art: 'assets/store/collections/warriors.webp',
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
      art: 'assets/store/collections/sacred.webp',
      rows: [
        ('Spirit', 'Latin'),
        ('Peace', 'Latin'),
        ('Om', 'Sanskrit'),
      ],
    ),
    _GlassPlaylistCardData(
      title: 'Nature Resonance',
      desc: 'Living elements for calm and clarity.',
      count: '10 WORDS',
      art: 'assets/store/collections/nature.webp',
      rows: [
        ('Water', 'Proto-Germanic'),
        ('Fire', 'Proto-Germanic'),
        ('Wind', 'Proto-Germanic'),
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
              itemCount: _cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final c = _cards[i];
                return StoreGlassPanel(
                  width: 268,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => onOpenWord(c.rows.first.$1.toLowerCase(), c.rows.first.$2, kRmWordImg, 49),
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
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox(width: 70, height: 70, child: ColoredBox(color: Color(0xFF0A0F1C))),
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
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(width: 40, height: 40, child: ColoredBox(color: Color(0xFF0A0F1C))),
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
                                      style: const TextStyle(fontSize: 11, color: Color(0x77FFFFFF)),
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


// ─── Mid-rail notification glass banners (7 variants, between every 2 rows) ──

class StoreMidRailBannerData {
  const StoreMidRailBannerData({
    required this.heading,
    required this.artAsset,
    required this.accent,
    this.svgBody,
    this.sub = '',
  });

  final String heading;
  final String artAsset;
  final Color accent;
  final String? svgBody;
  final String sub;
}

const kStoreMidRailBanners = <StoreMidRailBannerData>[
  StoreMidRailBannerData(
    heading: 'COLLECTIONS',
    artAsset: 'assets/store/collections/warriors.webp',
    accent: Color(0xFF5CE1FF),
    svgBody: NwsbMarks.bag,
    sub: 'Sacred · Warrior · Elements',
  ),
  StoreMidRailBannerData(
    heading: 'CURATED RAILS',
    artAsset: 'assets/store/collections/cosmos.webp',
    accent: Color(0xFF26A69A),
    svgBody: NwsbMarks.flame,
    sub: 'Time & Cosmos picks',
  ),
  StoreMidRailBannerData(
    heading: 'FEATURED DROP',
    artAsset: 'assets/store/collections/sale.webp',
    accent: Color(0xFFFFB74D),
    svgBody: NwsbMarks.word,
    sub: 'Limited atelier editions',
  ),
  StoreMidRailBannerData(
    heading: 'WORD ATELIER',
    artAsset: 'assets/store/nowssb-bag-headphones.webp',
    accent: Color(0xFFB388FF),
    svgBody: NwsbMarks.sound,
    sub: 'Real bag · real sound',
  ),
  StoreMidRailBannerData(
    heading: 'ELEMENTS',
    artAsset: 'assets/store/collections/elements.webp',
    accent: Color(0xFFFF6BCB),
    svgBody: NwsbMarks.sound,
    sub: 'Earth · Water · Fire · Air',
  ),
  StoreMidRailBannerData(
    heading: 'ELITE WORDS',
    artAsset: 'assets/store/collections/elite.webp',
    accent: Color(0xFF7CFF6B),
    svgBody: NwsbMarks.crown,
    sub: 'Rarest catalogue entries',
  ),
  StoreMidRailBannerData(
    heading: 'SALE RAIL',
    artAsset: 'assets/store/collections/sale.webp',
    accent: Color(0xFFE8D5A3),
    svgBody: NwsbMarks.flame,
    sub: 'Half-price vibrational words',
  ),
];

/// Taller notification-style glass strip: heading above black pill with
/// SVG circle → separator → real collection/bag art.
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
        ),
      ),
    );
  }
}

/// Inserts banner [index] (0..6) — safe no-op if out of range.
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
  });

  final String heading;
  final String svgBody;
  final String artAsset;
  final Color accent;
  final String sub;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.16),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                  ),
                  alignment: Alignment.center,
                  child: NwsbIcon(svgBody, size: 18, color: accent),
                ),
                Container(
                  width: 1,
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: const Color(0x33FFFFFF),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 44,
                        child: Image.asset(
                          artAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: accent.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                    ),
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
  required void Function(String word, String root, String img, num price) onOpenWord,
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
    ('Sacred Divine', 'Consciousness', 'assets/store/collections/sacred.webp'),
    ('Warrior', 'Strength', 'assets/store/collections/warriors.webp'),
    ('Elements', 'Nature', 'assets/store/collections/elements.webp'),
    ('Time & Cosmos', 'Infinity', 'assets/store/collections/cosmos.webp'),
    ('Peace', 'Stillness', 'assets/store/collections/peace.webp'),
    ('Mythical', 'Ancient forces', 'assets/store/collections/mythical.webp'),
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
  final void Function(String word, String root, String img, num price) onOpenWord;

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
        art: 'assets/store/nowssb-bag-headphones.webp',
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
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
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
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
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
                                    widget.onOpenWord(item.word, item.root, item.img, item.price);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0x33FFFFFF)),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0x88000000), blurRadius: 18, offset: Offset(0, 8)),
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
                                              const ColoredBox(color: Color(0xFF0A0F1C)),
                                        ),
                                        const DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [Color(0x33060C18), Color(0xF2060C18)],
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
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
                            wide: true,
                            onTap: () {
                              final c = _current;
                              Navigator.of(context).pop();
                              widget.onOpenWord(c.word, c.root, c.img, c.price);
                            },
                          ),
                          const SizedBox(width: 10),
                          _WhiteCircleAction(
                            icon: Icons.favorite_border,
                            onTap: () => _toast('Saved ${_current.title} to wishlist'),
                          ),
                          const SizedBox(width: 10),
                          _WhiteCircleAction(
                            icon: Icons.thumb_up_alt_outlined,
                            onTap: () => _toast('Liked ${_current.title}'),
                          ),
                          const SizedBox(width: 10),
                          _WhiteCircleAction(
                            icon: Icons.shopping_bag_outlined,
                            onTap: () => _toast('Added ${_current.title} to cart'),
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
    this.label,
    required this.onTap,
    this.wide = false,
  });

  final IconData? icon;
  final String? label;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
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
            BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: label != null
            ? Text(
                label!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF060C18),
                ),
              )
            : Icon(icon, size: 20, color: const Color(0xFF060C18)),
      ),
    );
  }
}
