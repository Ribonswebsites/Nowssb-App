/// Store browsing extras — Pixelskits-style hero (with restored video banner),
/// frequency-style heal grid + Limited Time Free + Browse by Goal,
/// Recommended / Featured Playlist glass, and tall glass playlist carousel.
/// Shared by Word Atelier, Meaning Store, and Ebooks.
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import 'store_cards.dart';

// ─── #2 Pixelskits-style Store hero ──────────────────────────────────────────

class StorePixelsHero extends StatelessWidget {
  const StorePixelsHero({
    super.key,
    this.onBrowseAll,
    this.onViewCart,
    this.videoAsset,
    this.videoTitle = 'The Word Atelier',
  });

  final VoidCallback? onBrowseAll;
  final VoidCallback? onViewCart;
  /// When set, restores the pre-bcfffd1 looping store hero video above the
  /// elevated Pixelskits copy — never wipe the film for typography alone.
  final String? videoAsset;
  final String videoTitle;

  static const _cyan = Color(0xFF5CE1FF);
  static const _violet = Color(0xFFB388FF);
  static const _pink = Color(0xFFFF6BCB);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (videoAsset != null) ...[
            ClipRRect(
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
            const SizedBox(height: 16),
          ],
          // Eyebrow
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0x33FFFFFF), height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'A RIBONS ORIGINAL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                    color: _cyan.withValues(alpha: 0.92),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0x33FFFFFF), height: 1)),
            ],
          ),
          const SizedBox(height: 14),
          // Logo badge + title
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_cyan, _violet, _pink],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _violet.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icons/collection-icon.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFF0A0F1C),
                      child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NowssB',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'STORE · A RIBONS WEBSITE',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Color(0x66FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _StoreHeroHeadline(),
          const SizedBox(height: 12),
          const Text(
            'Own the words that heal — unlock vibrational origins, curated collections, and signature editions in one dark atelier.',
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              color: Color(0x8AFFFFFF),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  label: 'Browse All',
                  icon: Icons.grid_view_rounded,
                  filled: true,
                  onTap: onBrowseAll,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  label: 'View Cart',
                  icon: Icons.shopping_bag_outlined,
                  filled: false,
                  onTap: onViewCart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreHeroHeadline extends StatelessWidget {
  const _StoreHeroHeadline();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THE STORE',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.05,
            color: Colors.white,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF5CE1FF), Color(0xFFB388FF), Color(0xFFFF6BCB)],
          ).createShader(bounds),
          child: const Text(
            'FOR YOUR',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.05,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          'HEALING WORDS',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            height: 1.1,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.35
              ..color = const Color(0xFFB388FF),
          ),
        ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.label,
    required this.icon,
    required this.filled,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: filled ? const Color(0xFF060C18) : Colors.white),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: filled ? const Color(0xFF060C18) : Colors.white,
          ),
        ),
      ],
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: filled
              ? const LinearGradient(
                  colors: [Color(0xFF5CE1FF), Color(0xFFB388FF)],
                )
              : null,
          color: filled ? null : Colors.transparent,
          border: filled ? null : Border.all(color: const Color(0x55FFFFFF)),
        ),
        child: child,
      ),
    );
  }
}

// ─── #3 Two-column healing category grid ─────────────────────────────────────

class StoreHealCategory {
  const StoreHealCategory({
    required this.id,
    required this.title,
    required this.accentTitle,
    required this.stat,
    required this.icon,
    required this.border,
    required this.accent,
    required this.tint,
  });

  final String id;
  final String title;
  final String accentTitle;
  final String stat;
  final IconData icon;
  final Color border;
  final Color accent;
  final Color tint;
}

const kStoreHealCategories = <StoreHealCategory>[
  StoreHealCategory(
    id: 'elements',
    title: 'Elements',
    accentTitle: 'Earth · Water · Fire',
    stat: '15 Words',
    icon: Icons.bolt_rounded,
    border: Color(0xFF4FC3F7),
    accent: Color(0xFF4FC3F7),
    tint: Color(0x224FC3F7),
  ),
  StoreHealCategory(
    id: 'sacred',
    title: 'Sacred',
    accentTitle: 'Divine Frequency',
    stat: '15 Words',
    icon: Icons.auto_awesome,
    border: Color(0xFFFFB74D),
    accent: Color(0xFFFFB74D),
    tint: Color(0x22FFB74D),
  ),
  StoreHealCategory(
    id: 'nature',
    title: 'Nature',
    accentTitle: 'Living Resonance',
    stat: '15 Words',
    icon: Icons.spa_outlined,
    border: Color(0xFF26A69A),
    accent: Color(0xFF4DB6AC),
    tint: Color(0x2226A69A),
  ),
  StoreHealCategory(
    id: 'warriors',
    title: 'Warriors',
    accentTitle: 'Strength Codes',
    stat: 'Elite Set',
    icon: Icons.shield_moon_outlined,
    border: Color(0xFF9E9E9E),
    accent: Color(0xFFBDBDBD),
    tint: Color(0x229E9E9E),
  ),
];

class StoreHealCategoryGrid extends StatelessWidget {
  const StoreHealCategoryGrid({super.key, required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HEAL BY CATEGORY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: NwsbColors.gold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Explore word & sound healing collections',
            style: TextStyle(fontSize: 12, color: Color(0x88FFFFFF)),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kStoreHealCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, i) {
              final c = kStoreHealCategories[i];
              return _HealCategoryCard(cat: c, onTap: () => onSelect(c.id));
            },
          ),
        ],
      ),
    );
  }
}

class _HealCategoryCard extends StatelessWidget {
  const _HealCategoryCard({required this.cat, required this.onTap});
  final StoreHealCategory cat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cat.border.withValues(alpha: 0.55), width: 1.2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0F1C),
              cat.tint,
              const Color(0xFF060C18),
            ],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _WaveformPainter(cat.accent))),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: cat.accent.withValues(alpha: 0.18),
                      border: Border.all(color: cat.accent.withValues(alpha: 0.4)),
                    ),
                    child: Icon(cat.icon, size: 16, color: cat.accent),
                  ),
                  const Spacer(),
                  Text(
                    cat.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cat.accentTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cat.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xCC060C18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: Text(
                          cat.stat,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xCC060C18),
                          border: Border.all(color: cat.border.withValues(alpha: 0.5)),
                        ),
                        child: Icon(Icons.arrow_forward_rounded, size: 15, color: cat.accent),
                      ),
                    ],
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

class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var w = 0; w < 3; w++) {
      final path = Path();
      final yBase = size.height * (0.35 + w * 0.18);
      path.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 4) {
        final y = yBase + math.sin((x / size.width) * math.pi * 4 + w) * (6.0 + w * 2);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => oldDelegate.color != color;
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
            'See All',
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
  const StoreLimitedTimeFreeSection({super.key, this.onOpenWord});

  final void Function(String word, String root, String img, num price)? onOpenWord;

  static const _tracks = <(String, String, String)>[
    ('432 Hz', 'Relax Piano', 'assets/store/collections/peace.webp'),
    ('528 Hz', 'Calming Tones', 'assets/store/collections/sacred.webp'),
    ('639 Hz', 'Heart Open', 'assets/store/collections/nature.webp'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⏳ Limited Time Free',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2EC4B6), Color(0xFF0B1B3A)],
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
                                        const ColoredBox(color: Color(0xFF0A0F1C)),
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
  });

  final ValueChanged<String> onSelectCategory;
  final VoidCallback onSeeAll;
  final void Function(String word, String root, String img, num price)? onOpenWord;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoreHealCategoryGrid(onSelect: onSelectCategory),
        StoreLimitedTimeFreeSection(onOpenWord: onOpenWord),
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


// ─── Mid-rail compact glass banners (7 variants, between every 2 rows) ───────

class StoreMidRailBannerData {
  const StoreMidRailBannerData({
    required this.svgAsset,
    required this.images,
    required this.tileColors,
    required this.accent,
    required this.panelTint,
    this.iconTint = const Color(0xFF060C18),
  });

  final String svgAsset;
  final List<String> images;
  final List<Color> tileColors;
  final Color accent;
  final Color panelTint;
  final Color iconTint;
}

const kStoreMidRailBanners = <StoreMidRailBannerData>[
  StoreMidRailBannerData(
    svgAsset: 'assets/icons/icon_08.svg',
    images: [
      'assets/store/collections/warriors.webp',
      'assets/store/collections/elements.webp',
      'assets/store/collections/sacred.webp',
      'assets/store/collections/nature.webp',
    ],
    tileColors: [Color(0xFF1A237E), Color(0xFF004D40), Color(0xFF4A148C), Color(0xFFBF360C)],
    accent: Color(0xFF5CE1FF),
    panelTint: Color(0x332196F3),
  ),
  StoreMidRailBannerData(
    svgAsset: 'assets/icons/icon_12.svg',
    images: [
      'assets/store/collections/peace.webp',
      'assets/store/collections/cosmos.webp',
      'assets/store/collections/mythical.webp',
      'assets/store/collections/elite.webp',
    ],
    tileColors: [Color(0xFF00695C), Color(0xFF4527A0), Color(0xFFAD1457), Color(0xFF37474F)],
    accent: Color(0xFF26A69A),
    panelTint: Color(0x3326A69A),
  ),
  StoreMidRailBannerData(
    svgAsset: 'assets/icons/icon_15.svg',
    images: [
      'assets/store/collections/sale.webp',
      'assets/store/collections/family.webp',
      'assets/store/collections/identity.webp',
      'assets/store/collections/premium.webp',
    ],
    tileColors: [Color(0xFFE65100), Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF2E7D32)],
    accent: Color(0xFFFFB74D),
    panelTint: Color(0x33FFB74D),
  ),
  StoreMidRailBannerData(
    svgAsset: 'assets/icons/icon_19.svg',
    images: [
      'assets/store/collections/ancient.webp',
      'assets/store/collections/black.webp',
      'assets/store/collections/white.webp',
      'assets/store/collections/warriors.webp',
    ],
    tileColors: [Color(0xFF263238), Color(0xFF880E4F), Color(0xFF01579B), Color(0xFF33691E)],
    accent: Color(0xFFB388FF),
    panelTint: Color(0x33B388FF),
  ),
  StoreMidRailBannerData(
    svgAsset: 'assets/icons/icon_22.svg',
    images: [
      'assets/store/collections/elements.webp',
      'assets/store/collections/nature.webp',
      'assets/store/collections/peace.webp',
      'assets/store/collections/sacred.webp',
    ],
    tileColors: [Color(0xFF006064), Color(0xFFC62828), Color(0xFF283593), Color(0xFFF9A825)],
    accent: Color(0xFFFF6BCB),
    panelTint: Color(0x33FF6BCB),
    iconTint: Color(0xFF1A0530),
  ),
  StoreMidRailBannerData(
    svgAsset: 'assets/icons/icon_26.svg',
    images: [
      'assets/store/collections/cosmos.webp',
      'assets/store/collections/elite.webp',
      'assets/store/collections/mythical.webp',
      'assets/store/collections/premium.webp',
    ],
    tileColors: [Color(0xFF311B92), Color(0xFF004D40), Color(0xFFB71C1C), Color(0xFF0277BD)],
    accent: Color(0xFF7CFF6B),
    panelTint: Color(0x337CFF6B),
  ),
  StoreMidRailBannerData(
    svgAsset: 'assets/icons/icon_30.svg',
    images: [
      'assets/store/collections/family.webp',
      'assets/store/collections/identity.webp',
      'assets/store/collections/sale.webp',
      'assets/store/collections/ancient.webp',
    ],
    tileColors: [Color(0xFF4E342E), Color(0xFF1B5E20), Color(0xFF4A148C), Color(0xFF00695C)],
    accent: Color(0xFFE8D5A3),
    panelTint: Color(0x33E8D5A3),
  ),
];

/// Compact mid-rail strip: glass wrapper → black rounded bar → white-circle SVG
/// + 4 tinted store-image tiles. Keep height short.
class StoreMidRailBanner extends StatelessWidget {
  const StoreMidRailBanner({super.key, required this.data});

  final StoreMidRailBannerData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StoreGlassPanel(
        padding: const EdgeInsets.all(6),
        radius: 18,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xF2000000),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: data.accent.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: data.panelTint,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  data.svgAsset,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(data.iconTint, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 8),
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: data.tileColors[i % data.tileColors.length],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      data.images[i % data.images.length],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
