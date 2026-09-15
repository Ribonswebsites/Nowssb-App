/// Store browsing extras — Pixelskits-style hero, healing category grid,
/// Recommended rail + Featured Bundle. Used by the Word Atelier (Store
/// product rails) only.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../theme/tokens.dart';
import 'store_cards.dart';

// ─── #2 Pixelskits-style Store hero ──────────────────────────────────────────

class StorePixelsHero extends StatelessWidget {
  const StorePixelsHero({
    super.key,
    this.onBrowseAll,
    this.onViewCart,
  });

  final VoidCallback? onBrowseAll;
  final VoidCallback? onViewCart;

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
          // Big multi-line headline
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
          // Twin pills
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
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101526),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
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