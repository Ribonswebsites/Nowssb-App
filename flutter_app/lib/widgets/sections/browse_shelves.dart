/// Home shelves styled after a dark media app, with NowssB art only.
///
/// Three layouts:
///   * [TodayDeckSection] — icon row, a thin progress line, a large card
///     with a white pill and the next card peeking.
///   * [MadeForYouSection] — filter chips, white collage cards, a landscape row.
///   * [ProgramsForYouSection] — a wide episode card, an "Open in" row of
///     NowssB marks (no other apps), and program cards with round portraits.
///
/// Black, gold, white, and the app's own posters. No third-party brands.
library;

import 'package:flutter/material.dart';

import '../../admin/layout/app_pages.dart';
import '../../theme/tokens.dart';
import '../home_skin.dart';
import '../hype_rail.dart';
import '../nwsb_icon.dart';
import 'artist_cards_section.dart';
import 'coupon_banner_section.dart';
import 'glassy_carousel_section.dart';
import 'section_config.dart';

const _inkDark = Color(0xFF121418);
const _card = Color(0xFF16181E);
const _card2 = Color(0xFF243044);
const _line = Color(0x33FFFFFF);

void _open(BuildContext context, String route) {
  if (route.isEmpty) return;
  openRoute(context, route);
}

Color _ink(BuildContext context) =>
    HomeSkinScope.of(context) == HomeSkin.fashion ? Colors.white : _inkDark;

Color _dim(BuildContext context) => HomeSkinScope.of(context) == HomeSkin.fashion
    ? const Color(0xB3FFFFFF)
    : const Color(0xFF5E5E5E);

class _Head extends StatelessWidget {
  const _Head(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _ink(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

Widget _asset(String url, {double? w, double? h, BoxFit fit = BoxFit.cover}) {
  return Image.asset(
    url,
    width: w,
    height: h,
    fit: fit,
    errorBuilder: (_, __, ___) => ColoredBox(
      color: const Color(0xFF1B2437),
      child: SizedBox(width: w, height: h),
    ),
  );
}

// ─── Shared home configs (real posters, not empty "Add media" slots) ────────

/// Glassy row both homes share. One object so a rebuild does not re-seed it.
const kHomeGlassy = SectionConfig(
  id: 'home.glassy',
  type: SectionTypeId.glassyCarousel,
  layout: SectionLayout(height: 248, cardWidth: 168, cardHeight: 200, spacing: 12, radius: 20),
  style: SectionStyle(glass: true, accent: 0xFFC8A96E),
  items: [
    SectionMediaItem(
      id: 'library',
      imageUrl: 'assets/hero-curve/banner-library.webp',
      title: 'Sound Library',
      subtitle: 'Hear a word',
      ctaLabel: 'Open',
      ctaLink: 'page:sound.library',
    ),
    SectionMediaItem(
      id: 'signature',
      imageUrl: 'assets/hero-curve/banner-store.webp',
      title: 'Signature',
      subtitle: 'The rarest words',
      ctaLabel: 'Open',
      ctaLink: 'page:store.signature',
    ),
    SectionMediaItem(
      id: 'coupons',
      imageUrl: 'assets/gifts/coupon-hero.png',
      title: 'Coupons',
      subtitle: 'Scratch today',
      ctaLabel: 'Open',
      ctaLink: 'page:coupons.program',
    ),
    SectionMediaItem(
      id: 'earn',
      imageUrl: 'assets/banners/programs/earn.png',
      title: 'Earn',
      subtitle: 'Coins on real sales',
      ctaLabel: 'Open',
      ctaLink: 'page:earn',
    ),
  ],
);

/// Ticket banner. Taller than the bare default so the offer line does not clip.
const kHomeCoupons = SectionConfig(
  id: 'home.coupons',
  type: SectionTypeId.couponBanner,
  layout: SectionLayout(height: 264, radius: 18),
  behavior: SectionBehavior(autoplay: true, autoplayMs: 4000, loop: true),
  style: SectionStyle(glowColor: 0x66E8A23A, accent: 0xFFE8A23A),
);
const kHomeArtists = SectionConfig(
  id: 'home.artists',
  type: SectionTypeId.artistCards,
  layout: SectionLayout(cardWidth: 156, cardHeight: 188, spacing: 12, radius: 16),
  style: SectionStyle(accent: 0xFFC8A96E),
  items: [
    SectionMediaItem(
      id: 'library',
      imageUrl: 'assets/hero-curve/banner-library.webp',
      title: 'Sounds',
      subtitle: 'Hear it once',
      ctaLink: 'library',
      meta: {'footer': 'Sound Library', 'plays': 'Listen'},
    ),
    SectionMediaItem(
      id: 'coupons',
      imageUrl: 'assets/gifts/coupon-hero.png',
      title: 'Coupons',
      subtitle: 'Scratch today',
      ctaLink: 'coupons',
      meta: {'footer': 'Daily', 'rewards': 'Open'},
    ),
    SectionMediaItem(
      id: 'signature',
      imageUrl: 'assets/hero-curve/banner-store.webp',
      title: 'Signature',
      subtitle: 'Rarest words',
      ctaLink: 'signature',
      meta: {'footer': 'The store', 'plays': 'Shop'},
    ),
    SectionMediaItem(
      id: 'earn',
      imageUrl: 'assets/banners/programs/earn.png',
      title: 'Earn',
      subtitle: 'Real sales',
      ctaLink: 'earn',
      meta: {'footer': 'Catalogue', 'rewards': 'Coins'},
    ),
    SectionMediaItem(
      id: 'rewards',
      imageUrl: 'assets/banners/programs/rewards.png',
      title: 'Rewards',
      subtitle: 'Spend coins',
      ctaLink: 'rewards',
      meta: {'footer': 'Not cash', 'plays': 'Open'},
    ),
  ],
);

// ─── 1. Today deck ──────────────────────────────────────────────────────────

class _IconDoor {
  const _IconDoor(this.label, this.mark, this.route);
  final String label;
  final String mark;
  final String route;
}

const _doors = <_IconDoor>[
  _IconDoor('Sounds', NwsbMarks.sound, 'page:sound.library'),
  _IconDoor('Breath', NwsbMarks.stages, 'page:practice'),
  _IconDoor('Words', NwsbMarks.word, 'page:library'),
  _IconDoor('Story', NwsbMarks.reader, 'page:reader'),
  _IconDoor('Still', NwsbMarks.hourglass, 'page:healing'),
];

class _TodayCard {
  const _TodayCard(this.kicker, this.title, this.cta, this.asset, this.route);
  final String kicker;
  final String title;
  final String cta;
  final String asset;
  final String route;
}

const _todayCards = <_TodayCard>[
  _TodayCard('Practice · 3 min', 'Breathe the word', 'Start today\'s practice', 'assets/banners/promo/pose-01.png', 'page:practice'),
  _TodayCard('Sound · 4 min', 'Hear it once', 'Open the sound library', 'assets/hero-curve/banner-library.webp', 'page:sound.library'),
  _TodayCard('Story · 6 min', 'Read the meaning', 'Open the reader', 'assets/banners/programs/rewards.png', 'page:reader'),
];

/// Icon row, progress line, and a peeking practice card.
class TodayDeckSection extends StatefulWidget {
  const TodayDeckSection({super.key, this.config});

  /// Accepted so the admin registry can build it. Content is NowssB's own.
  final SectionConfig? config;

  @override
  State<TodayDeckSection> createState() => _TodayDeckSectionState();
}

class _TodayDeckSectionState extends State<TodayDeckSection> {
  late final PageController _page = PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = _ink(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          for (final d in _doors)
            Expanded(
              child: GestureDetector(
                onTap: () => _open(context, d.route),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(children: [
                    NwsbIcon(d.mark, size: 26, color: ink, strokeWidth: 1.6),
                    const SizedBox(height: 8),
                    Text(
                      d.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 22),
        _Head(
          'Today',
          trailing: NwsbIcon(NwsbMarks.bell, size: 20, color: _dim(context), strokeWidth: 1.6),
        ),
        Row(children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _dim(context), width: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          Text('Get started', style: TextStyle(color: _dim(context), fontSize: 13)),
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: HomeSkinScope.of(context) == HomeSkin.fashion ? _line : const Color(0x33000000),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _dim(context), width: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          Text('Still', style: TextStyle(color: _dim(context), fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 332,
          child: PageView.builder(
            controller: _page,
            padEnds: false,
            itemCount: _todayCards.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _TodayFace(card: _todayCards[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayFace extends StatelessWidget {
  const _TodayFace({required this.card});
  final _TodayCard card;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context, card.route),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_card2, _card],
          ),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _asset(card.asset, w: 120, h: 120),
            ),
            const SizedBox(height: 18),
            Text(
              card.kicker,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              card.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.15),
            ),
            const Spacer(),
            DecoratedBox(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  card.cta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _inkDark, fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── 2. Made for you ────────────────────────────────────────────────────────

class _Collage {
  const _Collage(this.tag, this.kicker, this.title, this.route, this.shots);
  final String tag;
  final String kicker;
  final String title;
  final String route;
  final List<String> shots;
}

class _Land {
  const _Land(this.tag, this.title, this.line, this.asset, this.route);
  final String tag;
  final String title;
  final String line;
  final String asset;
  final String route;
}

const _collages = <_Collage>[
  _Collage('words', 'Your', 'Word mix', 'page:library', [
    'assets/hero-curve/banner-store.webp',
    'assets/banners/promo/pose-02.png',
    'assets/gifts/coupon-hero.png',
    'assets/banners/programs/rewards.png',
  ]),
  _Collage('sounds', 'Your', 'Sound mix', 'page:sound.library', [
    'assets/hero-curve/banner-library.webp',
    'assets/banners/promo/pose-03.png',
    'assets/banners/programs/earn.png',
    'assets/banners/promo/pose-04.png',
  ]),
  _Collage('store', 'Your', 'Store mix', 'tab:3', [
    'assets/store/nowssb-bag-headphones.webp',
    'assets/gifts/gift-hero.png',
    'assets/hero-curve/banner-store.webp',
    'assets/banners/promo/pose-05.png',
  ]),
];

const _lands = <_Land>[
  _Land('practice', 'Today\'s practice', 'Three minutes', 'assets/banners/promo/pose-01.png', 'page:practice'),
  _Land('sounds', 'Sound library', 'Hear a word', 'assets/hero-curve/banner-library.webp', 'page:sound.library'),
  _Land('words', 'Signature words', 'The rare set', 'assets/hero-curve/banner-store.webp', 'page:store.signature'),
  _Land('store', 'NowssB store', 'Shop the words', 'assets/store/nowssb-bag-headphones.webp', 'tab:3'),
];

const _filters = <(String, String)>[
  ('All', ''),
  ('Practice', 'practice'),
  ('Sounds', 'sounds'),
  ('Words', 'words'),
  ('Store', 'store'),
];

/// Chips, white collage cards, and a landscape "New" row.
class MadeForYouSection extends StatefulWidget {
  const MadeForYouSection({super.key, this.config});
  final SectionConfig? config;

  @override
  State<MadeForYouSection> createState() => _MadeForYouSectionState();
}

class _MadeForYouSectionState extends State<MadeForYouSection> {
  var _chip = 0;

  @override
  Widget build(BuildContext context) {
    final tag = _filters[_chip].$2;
    final mixes = [for (final c in _collages) if (tag.isEmpty || c.tag == tag) c];
    final lands = [for (final c in _lands) if (tag.isEmpty || c.tag == tag) c];
    final shownMix = mixes.isEmpty ? _collages : mixes;
    final shownLand = lands.isEmpty ? _lands : lands;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final on = i == _chip;
              return GestureDetector(
                onTap: () => setState(() => _chip = i),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: on ? NwsbColors.gold : const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: on ? NwsbColors.gold : const Color(0x33FFFFFF)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: Text(
                        _filters[i].$1,
                        style: TextStyle(
                          color: on ? _inkDark : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        const _Head('Made for you'),
        SizedBox(
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shownMix.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _CollageCard(mix: shownMix[i]),
          ),
        ),
        const SizedBox(height: 22),
        _Head(
          'New',
          trailing: GestureDetector(
            onTap: () => _open(context, 'tab:3'),
            child: Text('View all', style: TextStyle(color: _dim(context), fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shownLand.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _LandCard(item: shownLand[i]),
          ),
        ),
      ],
    );
  }
}

class _CollageCard extends StatelessWidget {
  const _CollageCard({required this.mix});
  final _Collage mix;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context, mix.route),
      child: SizedBox(
        width: 236,
        height: 198,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(children: [
              Positioned(right: -28, top: 28, child: _shot(mix.shots[0], -0.42, 108, 78)),
              if (mix.shots.length > 1) Positioned(right: 18, bottom: -16, child: _shot(mix.shots[1], 0.28, 96, 70)),
              if (mix.shots.length > 2) Positioned(right: 46, top: 8, child: _shot(mix.shots[2], 0.18, 72, 54)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mix.kicker, style: const TextStyle(color: _inkDark, fontSize: 18, fontWeight: FontWeight.w800, height: 1.05)),
                  Text(mix.title, style: const TextStyle(color: NwsbColors.gold, fontSize: 18, fontWeight: FontWeight.w800, height: 1.05)),
                  const Spacer(),
                  Row(children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: NwsbColors.gold, width: 2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('NowssB', style: TextStyle(color: _inkDark, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _shot(String asset, double angle, double w, double h) {
    return Transform.rotate(
      angle: angle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _asset(asset, w: w, h: h),
      ),
    );
  }
}

class _LandCard extends StatelessWidget {
  const _LandCard({required this.item});
  final _Land item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context, item.route),
      child: SizedBox(
        width: 240,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            _asset(item.asset),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text(item.line, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── 3. Programs ────────────────────────────────────────────────────────────

class _Episode {
  const _Episode(this.kicker, this.title, this.line, this.asset, this.route);
  final String kicker;
  final String title;
  final String line;
  final String asset;
  final String route;
}

class _Program {
  const _Program(this.kicker, this.title, this.line, this.asset, this.route, this.faces);
  final String kicker;
  final String title;
  final String line;
  final String asset;
  final String route;
  final List<String> faces;
}

const _episodes = <_Episode>[
  _Episode('Practice · 8 min', 'Why a word lands', 'With the sound, not a dictionary', 'assets/banners/promo/pose-06.png', 'page:practice'),
  _Episode('Sound · 5 min', 'Hear it before you read', 'One word, one voice', 'assets/hero-curve/banner-library.webp', 'page:sound.library'),
  _Episode('Reader · 12 min', 'The daily line', 'Read it once, slowly', 'assets/banners/programs/rewards.png', 'page:reader'),
];

const _programs = <_Program>[
  _Program('Program · 7 days', 'Daily practice', 'NowssB\n4 doors', 'assets/banners/promo/pose-02.png', 'page:practice', [
    'assets/banners/promo/pose-01.png',
    'assets/banners/promo/pose-03.png',
    'assets/banners/promo/pose-05.png',
  ]),
  _Program('Program · 7 days', 'Sound week', 'NowssB\n3 doors', 'assets/hero-curve/banner-library.webp', 'page:sound.library', [
    'assets/banners/promo/pose-04.png',
    'assets/banners/promo/pose-06.png',
    'assets/banners/promo/pose-07.png',
  ]),
  _Program('Program · 5 days', 'Signature words', 'NowssB\nThe store', 'assets/hero-curve/banner-store.webp', 'page:store.signature', [
    'assets/banners/promo/pose-02.png',
    'assets/gifts/coupon-hero.png',
    'assets/banners/programs/earn.png',
  ]),
];

const _openIn = <(String, String)>[
  (NwsbMarks.play24, 'page:practice'),
  (NwsbMarks.sound, 'page:sound.library'),
  (NwsbMarks.book, 'page:reader'),
];

/// Episode card, Open-in marks, and program cards with overlapping portraits.
class ProgramsForYouSection extends StatefulWidget {
  const ProgramsForYouSection({super.key, this.config});
  final SectionConfig? config;

  @override
  State<ProgramsForYouSection> createState() => _ProgramsForYouSectionState();
}

class _ProgramsForYouSectionState extends State<ProgramsForYouSection> {
  late final PageController _page = PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 248,
          child: PageView.builder(
            controller: _page,
            padEnds: false,
            itemCount: _episodes.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _EpisodeFace(item: _episodes[i]),
            ),
          ),
        ),
        const SizedBox(height: 14),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x22FFFFFF)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const Text('Open in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              for (var i = 0; i < _openIn.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _open(context, _openIn[i].$2),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: NwsbIcon(_openIn[i].$1, size: 20, color: _inkDark, strokeWidth: 1.7),
                  ),
                ),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 22),
        const _Head('Programs for you'),
        SizedBox(
          height: 292,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _programs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _ProgramCard(item: _programs[i]),
          ),
        ),
      ],
    );
  }
}

class _EpisodeFace extends StatelessWidget {
  const _EpisodeFace({required this.item});
  final _Episode item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context, item.route),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(height: 112, width: double.infinity, child: _asset(item.asset)),
            ),
            const SizedBox(height: 10),
            Text(item.kicker, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
            const SizedBox(height: 4),
            Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, height: 1.15)),
            const Spacer(),
            Text(item.line, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.item});
  final _Program item;

  @override
  Widget build(BuildContext context) {
    final lines = item.line.split('\n');
    return GestureDetector(
      onTap: () => _open(context, item.route),
      child: SizedBox(
        width: 250,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x22FFFFFF)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(height: 132, width: double.infinity, child: _asset(item.asset)),
              ),
              const SizedBox(height: 10),
              Text(item.kicker, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
              const SizedBox(height: 4),
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              const Spacer(),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(lines.first, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    if (lines.length > 1)
                      Text(lines[1], maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                  ]),
                ),
                SizedBox(
                  width: 64,
                  height: 28,
                  child: Stack(children: [
                    for (var i = 0; i < item.faces.length && i < 3; i++)
                      Positioned(
                        left: i * 16,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _card, width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _asset(item.faces[i]),
                        ),
                      ),
                  ]),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The shelves that were in the admin catalog but not on either home.
/// One of each. Category tiles and spotlight already sit above these.
abstract final class HomeShelves {
  static const pad = EdgeInsets.fromLTRB(16, 8, 16, 4);

  static const today = Padding(padding: pad, child: TodayDeckSection());

  static const glassy = Padding(
    padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
    child: GlassyCarouselSection(config: kHomeGlassy),
  );

  static const coupons = Padding(
    padding: pad,
    child: CouponBannerSection(config: kHomeCoupons),
  );

  static const hyped = Padding(
    padding: pad,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xF0121216),
        borderRadius: BorderRadius.all(Radius.circular(22)),
        border: Border.fromBorderSide(BorderSide(color: Color(0x33C8A96E))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 14, 4, 4),
        child: NowssbHypeRail(),
      ),
    ),
  );

  static const artists = Padding(
    padding: pad,
    child: ArtistCardsSection(config: kHomeArtists),
  );

  static const made = Padding(padding: pad, child: MadeForYouSection());

  static const programs = Padding(padding: pad, child: ProgramsForYouSection());
}
