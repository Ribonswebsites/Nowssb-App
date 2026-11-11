/// The four banner styles that belong on a page: the three-card earn row,
/// a split promo, a black glass row, and a sideways poster shelf.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/draw/lucky_draw_gate.dart';
import '../features/draw/lucky_draw_screen.dart';
import '../features/programs/program_router.dart';
import '../theme/white_neu.dart';
import '../screens/subscription.dart';
import 'black_glass_banner.dart';
import 'colored_split_promo_banner.dart';
import 'nwsb_icon.dart';
import 'glass_wrap.dart';
import 'earn_now_section.dart';

class FourBanners extends StatelessWidget {
  const FourBanners({
    super.key,
    this.splitTitle = 'NowssB',
    this.splitCta = 'Open',
    this.blackTitle = 'NowssB',
    this.blackSub = 'Words, rewards, and what you have earned.',
    this.current,
  });

  /// The programme page this sits on: its own rail tile and shelf poster
  /// are left out (a page never links to itself).
  final Programme? current;

  final String splitTitle;
  final String splitCta;
  final String blackTitle;
  final String blackSub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrioRail(current: current),
        const SizedBox(height: 12),
        ColoredSplitPromoBanner(
          margin: EdgeInsets.zero,
          spec: SplitPromoSpec(
            title: splitTitle,
            cta: splitCta,
            leftColor: const Color(0xFF3D2914),
            rightColor: const Color(0xFFE4C56A),
            art: SplitPromoArts.blondeLotus,
            // The split promo opens the next programme (never this page).
            onTap: () => Programmes.open(context, _next(current)),
          ),
        ),
        const SizedBox(height: 12),
        BlackGlassBanner(
          margin: EdgeInsets.zero,
          title: blackTitle,
          subtitle: blackSub,
          mark: NwsbMarks.rewards,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen())),
        ),
      ],
    );
  }
}

Programme _next(Programme? p) => switch (p) {
      Programme.earnings => Programme.reference,
      Programme.earn => Programme.reference,
      _ => Programme.earnings,
    };

/// The Earn-page banner. The left photograph is full height. The cards on
/// the right are shorter, tinted, and they keep sliding. Same row on every
/// page that used to invent its own trio.
class TrioRail extends StatefulWidget {
  const TrioRail({super.key, this.current});

  /// Leave this programme's own tiles out (on its own page).
  final Programme? current;

  @override
  State<TrioRail> createState() => _TrioRailState();
}

class _RailFace {
  const _RailFace(this.image, this.programme);
  final String image;
  final Programme programme;
  void open(BuildContext context) => Programmes.open(context, programme);
}

class _TrioRailState extends State<TrioRail> {
  static const _all = <_RailFace>[
    _RailFace('assets/banners/promo/rail-well.webp', Programme.earnings),
    _RailFace('assets/banners/promo/rail-stones.webp', Programme.earn),
    _RailFace('assets/banners/promo/rail-folio.webp', Programme.reference),
  ];

  late final List<_RailFace> _faces = [
    for (final f in _all)
      if (f.programme != widget.current) f,
  ];

  @override
  Widget build(BuildContext context) {
    if (!onNormal(context)) return const _ProgrammeBanners();
    return _ProgrammeDeck(faces: _faces);
  }
}

/// Three programmes, three different cards, scrolled sideways.
/// Not one glass box, and none of the old photographs.
class _ProgrammeDeck extends StatelessWidget {
  const _ProgrammeDeck({required this.faces});
  final List<_RailFace> faces;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: faces.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _DeckCard(face: faces[i]),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.face});
  final _RailFace face;

  @override
  Widget build(BuildContext context) {
    final child = switch (face.programme) {
      Programme.reference => _folio(face),
      Programme.earnings => _well(face),
      Programme.earn => _ring(face),
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        face.open(context);
      },
      child: SizedBox(width: 246, child: child),
    );
  }

  static Widget _folio(_RailFace face) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE4DDD2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Row(children: [
            Image.asset(face.image, width: 78, height: 188, fit: BoxFit.cover),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('01  ·  LINKS', style: TextStyle(color: Color(0xFF8A8175), fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Text('Reference', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF1C1915), fontSize: 22, height: 1, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  const SizedBox(height: 6),
                  const Text('Your links', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFF6E675E), fontSize: 12.5, height: 1.25)),
                  const Spacer(),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: _OpenDot(ink: Color(0xFF1C1915), fill: Color(0xFFF3EDE4)),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );

  static Widget _well(_RailFace face) => DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xFF171412), borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                child: Text('02  ·  EARNED', style: TextStyle(color: Color(0xFFC4A574), fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
              ),
              ClipOval(child: Image.asset(face.image, width: 54, height: 54, fit: BoxFit.cover)),
            ]),
            const Spacer(),
            const Text('Earning', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 26, height: 1, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            const Text('What you have earned', maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFFB7A99A), fontSize: 12.5, height: 1.25)),
            const SizedBox(height: 12),
            const Row(children: [
              _Tick(on: true), SizedBox(width: 4),
              _Tick(on: true), SizedBox(width: 4),
              _Tick(on: true), SizedBox(width: 4),
              _Tick(on: false), SizedBox(width: 4),
              _Tick(on: false),
            ]),
          ]),
        ),
      );

  static Widget _ring(_RailFace face) => DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xFFF4E7D4), borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC4A574), width: 1.5),
              ),
              padding: const EdgeInsets.all(6),
              child: ClipOval(child: Image.asset(face.image, fit: BoxFit.cover)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('03  ·  TODAY', style: TextStyle(color: Color(0xFF8A6A3B), fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('Coins', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF2A2118), fontSize: 24, height: 1, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Earned today', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF6E5A40), fontSize: 12.5, height: 1.25)),
              ]),
            ),
          ]),
        ),
      );
}

class _OpenDot extends StatelessWidget {
  const _OpenDot({required this.ink, required this.fill});
  final Color ink;
  final Color fill;
  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Icon(Icons.arrow_forward_rounded, size: 16, color: ink),
      );
}

class _Tick extends StatelessWidget {
  const _Tick({required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 4,
        decoration: BoxDecoration(
          color: on ? const Color(0xFFE7C48A) : const Color(0xFF3A332C),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

/// The Zen home's Programmes block: the NowssB Earn row (the Store's own
/// carousel widget), then the programme cards inside ONE glass pane, the very same [GlassWrap] the
/// other Zen sections sit on, under the same kind of heading (round glass
/// badge, small grey eyebrow, bold title) as the Word Store.
class ProgrammesGlassSection extends StatelessWidget {
  const ProgrammesGlassSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EarnNowSection(),
        GlassWrap(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x2EFFFFFF)),
                  ),
                  child: const Center(child: NwsbIcon(NwsbMarks.compass, size: 21)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Your path',
                          key: ValueKey('prog-glass-eyebrow'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, color: Color(0x99FFFFFF), height: 1.2)),
                      Text('Programmes',
                          key: ValueKey('prog-glass-title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2, letterSpacing: -0.4)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const _GlassCards(),
            ],
          ),
        ),
      ],
    );
  }
}

/// The six programme cards of the glass pane. Each opens a page that exists.
class _GlassCards extends StatelessWidget {
  const _GlassCards();

  @override
  Widget build(BuildContext context) {
    Widget gap() => const SizedBox(height: 10);
    return Column(children: [
      _ProgBanner(
        art: 'assets/banners/promo/prog-letter.webp',
        kicker: 'Programme',
        title: 'Reference',
        line: 'Your links',
        glass: true,
        onOpen: (c) => Programmes.open(c, Programme.reference),
      ),
      gap(),
      _ProgBanner(
        art: 'assets/banners/promo/prog-sill.webp',
        kicker: 'Programme',
        title: 'Earning',
        line: 'What you have earned',
        glass: true,
        onOpen: (c) => Programmes.open(c, Programme.earnings),
      ),
      gap(),
      _ProgBanner(
        art: 'assets/banners/promo/prog-bowl.webp',
        kicker: 'Programme',
        title: 'Coins',
        line: 'Earned today',
        glass: true,
        onOpen: openCoinsPage,
      ),
      gap(),
      _ProgBanner(
        art: 'assets/banners/promo/rail-stones.webp',
        kicker: 'Programme',
        title: 'Bonuses',
        line: 'Targets and rewards',
        glass: true,
        onOpen: (c) => Programmes.open(c, Programme.earn, tab: 'targets'),
      ),
      gap(),
      _ProgBanner(
        art: 'assets/banners/promo/quiet-room.webp',
        kicker: 'Membership',
        title: 'Zen Plus',
        line: 'The full library',
        glass: true,
        onOpen: (c) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen())),
      ),
      // Only while the draw is switched on, so it never opens "coming soon".
      LuckyDrawGate(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _ProgBanner(
            art: 'assets/banners/promo/rail-well.webp',
            kicker: 'Daily',
            title: 'Lucky draw',
            line: 'Free to enter today',
            glass: true,
            onOpen: (c) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const LuckyDrawScreen())),
          ),
        ),
      ),
    ]);
  }
}

/// One programme, one banner. Same shape as the store card (picture, label,
/// big title, round button). On the Zen home they sit inside one glass panel
/// ([glass]); elsewhere each stands on its own.
class _ProgrammeBanners extends StatelessWidget {
  const _ProgrammeBanners();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProgBanner(
          art: 'assets/banners/promo/prog-letter.webp',
          kicker: 'Programme',
          title: 'Reference',
          line: 'Your links',
          programme: Programme.reference,
        ),
        const SizedBox(height: 10),
        _ProgBanner(
          art: 'assets/banners/promo/prog-sill.webp',
          kicker: 'Programme',
          title: 'Earning',
          line: 'What you have earned',
          programme: Programme.earnings,
        ),
        const SizedBox(height: 10),
        _ProgBanner(
          art: 'assets/banners/promo/prog-bowl.webp',
          kicker: 'Programme',
          title: 'Coins',
          line: 'Earned today',
          programme: Programme.earn,
        ),
      ],
    );
  }
}

class _ProgBanner extends StatelessWidget {
  const _ProgBanner({
    required this.art,
    required this.kicker,
    required this.title,
    required this.line,
    this.programme,
    this.onOpen,
    this.glass = false,
  });

  final bool glass;
  final void Function(BuildContext)? onOpen;
  final String art;
  final String kicker;
  final String title;
  final String line;
  final Programme? programme;

  @override
  Widget build(BuildContext context) {
    final img = glass ? 96.0 : 116.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        if (onOpen != null) {
          onOpen!(context);
        } else {
          Programmes.open(context, programme!);
        }
      },
      child: Container(
        height: glass ? 116 : 136,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // In the glass panel the cards go see-through dark so the frost
          // shows around them; on their own they stay near-black.
          color: glass ? Colors.black : const Color(0xF0111114),
          borderRadius: BorderRadius.circular(glass ? 20 : 22),
          border: Border.all(color: glass ? const Color(0x1FFFFFFF) : const Color(0x33FFFFFF)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(glass ? 16 : 14),
            child: Image.asset(art, width: img, height: img, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => ColoredBox(color: const Color(0xFF161616), child: SizedBox(width: img, height: img))),
          ),
          SizedBox(width: glass ? 12 : 14),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(kicker.toUpperCase(), maxLines: 1,
                    style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              // Long names shrink instead of being cut.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(title.toUpperCase(), maxLines: 1,
                    style: TextStyle(color: Colors.white, fontSize: glass ? 24 : 26, fontWeight: FontWeight.w900, letterSpacing: .4)),
              ),
              const SizedBox(height: 4),
              Text(line, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.25)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 22),
          ),
        ]),
      ),
    );
  }
}
