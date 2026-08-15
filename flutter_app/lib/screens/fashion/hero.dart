/// The Fashion home's hero — the deck, built from app/js/part083.js.
///
/// I HAD THE WRONG ONE. The hero has three looks (app/js/part082.js:118) and
/// this app was carrying the `full` one: the five photographs crossfading
/// edge to edge with a picture rail and a big rotating word. `heroStyle()`
/// at :137 says the shipped default is `plain` — "the set in glass, with the
/// greeting over it and the rail running through it" — and `full` is only
/// what someone gets if they went and chose it. So the top of the app looked
/// nothing like the top of the app.
///
/// The plain look is three things, and app/js/part083.js builds all of them:
///
///   1. A greeting ABOVE the card — see [HeroGreeting] in header.dart.
///   2. The card itself, in glass: a strip above the set carrying the store
///      and the search, the television, and a strip below it carrying
///      Explore, App Guide and Learn. Everything that is not the picture
///      comes OUT of the television and onto the glass around it — a screen
///      with an Explore button drawn on it is a screen with a button drawn
///      on it, and the two were fighting for the same 230px (:463).
///   3. A rail THROUGH it: the card is cell 0 of a deck, and six banners
///      follow it, one at a time, each sliding in from the right.
///
/// Every banner is the clip its own page opens with, so the rail is a window
/// onto the app rather than a set of adverts made for it (:34).
///
/// What it costs: one clip decodes at a time, because only the cell on
/// screen holds a lease. That is the same rule the web version states at
/// :22 and the same one [VideoPool] enforces here.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/tv_frame.dart';
import 'follow_steps.dart';

/// One banner on the rail — RAIL, app/js/part083.js:106.
///
/// `asset` is THE ADDRESS THE WEBSITE PLAYS, copied verbatim — a bundled
/// file for the two that are local on the web, and the Cloudinary URL for
/// the four that are not. Substituting a local look-alike for those four is
/// what made this rail play the wrong film in four of its six cells.
class _Rail {
  const _Rail(this.mark, this.hello, this.title, this.asset, this.dest);

  /// The block's own mark — the SVG path, from `I` at part083.js:50.
  final String mark;
  final String hello;
  final String title;
  final String asset;

  /// The tab this banner is a door to.
  final int dest;
}

const _rail = [
  // The subscription block's own gold clip.
  _Rail(
      NwsbMarks.crown,
      'The Full Library',
      'NowssB Subscription',
      'https://res.cloudinary.com/eenvubod/video/upload/v1784895544/'
          'grok_video_2026-07-24-17-46-41_vkxr4r.mp4',
      3),
  // The clip a word page opens with — NWSB_WORD_BANNER_VID.
  _Rail(
      NwsbMarks.word,
      'Where a word begins',
      'NowssB Word Store',
      'https://res.cloudinary.com/yvi3d7ov/video/upload/v1785512057/'
          'grok_video_2026-07-31-20-43-13_qh2qjg.mp4',
      3),
  // The clip every meaning's page opens with — MS_MEANING_VID.
  _Rail(
      NwsbMarks.meaning,
      'What a word truly means',
      'NowssB Meaning Store',
      'https://res.cloudinary.com/yvi3d7ov/video/upload/v1785511438/'
          'grok_video_2026-07-31-15-41-50_oxszei.mp4',
      3),
  _Rail(NwsbMarks.signature, 'The rarest word', 'The Signature',
      'assets/video/signature-banner.mp4', 3),
  // The eBooks banner clip — and NOT the little one spinning in the spill
  // disc, which is the mistake part083.js:130 records having made.
  _Rail(
      NwsbMarks.book,
      'Page by page',
      'NowssB eBooks',
      'https://res.cloudinary.com/eenvubod/video/upload/v1785406073/'
          'grok_video_2026-07-30-15-35-40_xwm1ei.mp4',
      2),
  _Rail(NwsbMarks.sound, 'Every word you own', 'Sound Library',
      'assets/video/sound-library-banner.mp4', 2),
];

class FashionHero extends StatefulWidget {
  const FashionHero({
    super.key,
    this.onExplore,
    this.onGuide,
    this.onSearch,
    this.onStore,
    this.onRail,
  });

  final VoidCallback? onExplore;
  final VoidCallback? onGuide;
  final VoidCallback? onSearch;
  final VoidCallback? onStore;

  /// Called with the banner's destination tab.
  final void Function(int dest)? onRail;

  @override
  State<FashionHero> createState() => _FashionHeroState();
}

class _FashionHeroState extends State<FashionHero> {
  final _deck = PageController();
  Timer? _t;
  int _i = 0;

  /// Whether the guide has taken the rail over — part084.js's `on()`, which
  /// is a class on the deck for exactly this reason: it is ONE rail, showing
  /// one of two sets of cells.
  bool _guide = false;

  /// `held` — part084.js:196. The auto-advance stands down for a while
  /// whenever a finger touches it. "The point of pressing forward is to go
  /// at your own speed, and a card that then slid away under you would be
  /// the rail arguing."
  DateTime _held = DateTime.fromMillisecondsSinceEpoch(0);

  /// MIN_DWELL — the web hands over when the clip ENDS, with a floor under
  /// it. Nothing here knows when a clip ends yet, so the floor is the whole
  /// interval. ROTATE (part084.js:196) is the same 7s, which is why the
  /// guide can share this timer rather than starting a second one.
  static const _dwell = Duration(seconds: 7);
  static const _hold = Duration(seconds: 14);

  /// How many cells the deck has. Cell 0 is the hero either way — the card
  /// with the set in it, or the same card with the title on its screen.
  int get _cells => (_guide ? kFstSteps.length : _rail.length) + 1;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(_dwell, (_) {
      // `visible()` — :573. The rail stops when the home is not the screen
      // you are on and when the app is in the background. TickerMode is
      // both of those in Flutter.
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      if (!_deck.hasClients) return;
      if (DateTime.now().isBefore(_held)) return;
      _i = (_i + 1) % _cells;
      _deck.animateToPage(
        _i,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _deck.dispose();
    super.dispose();
  }

  /// `fstToggle` — part084.js. Tapping the disc does not jump to step one:
  /// it changes the television's own screen first, and THAT is the guide's
  /// first card. So both directions land on cell 0.
  void _toggleGuide() {
    setState(() {
      _guide = !_guide;
      _i = 0;
      _held = DateTime.now().add(_hold);
    });
    if (_deck.hasClients) _deck.jumpToPage(0);
  }

  /// `fstStep` — :361. Clamped rather than wrapping: the arrows are a way
  /// through the steps, and the timer is what wraps.
  void _step(int d) {
    final next = _i + d;
    if (next < 0 || next >= _cells) return;
    _held = DateTime.now().add(_hold);
    _deck.animateToPage(
      next,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // A PageView needs a bounded height, and the height it needs is the one
    // its tallest cell works out to — NOT a number picked by eye. It was 430
    // and the card comes to about 366 at phone width, so every cell was
    // carrying sixty-odd pixels of dead glass under it.
    //
    // The card is two strips and a television, and the television's height
    // follows from the width, so the whole thing is arithmetic:
    return LayoutBuilder(
      builder: (context, c) {
        // GlassWrap's margin, then its padding, then its border.
        final inner = c.maxWidth - (16 * 2) - (12 * 2) - 2;
        final tv = inner / DeviceFrame.tvLandscape.aspect;
        // padding, strip, gap, set, gap, strip, padding, the pane's own
        // vertical margin, and its 1px border top and bottom — which was
        // taken off the width and forgotten on the height.
        final h =
            12 + _topStripH + 10 + tv + 10 + _footStripH + 12 + (8 * 2) + 2;
        return SizedBox(
          height: h,
          child: PageView.builder(
            controller: _deck,
            itemCount: _cells,
            onPageChanged: (i) {
              // A finger on the rail means the same thing here as it does on an
              // arrow — part084.js:540.
              _held = DateTime.now().add(_hold);
              setState(() => _i = i);
            },
            itemBuilder: (context, i) {
              if (i == 0) {
                return _HeroCard(
                  onExplore: widget.onExplore,
                  onGuide: widget.onGuide,
                  onSearch: widget.onSearch,
                  onStore: widget.onStore,
                  // Only the cell on screen decodes. Off-cell clips are stills,
                  // which is what "no src at all until its turn" buys on the web.
                  live: _i == 0,
                  // The guide's own first card IS the hero — the set stays, and
                  // its screen carries the title instead of the wordmark and
                  // the word.
                  guide: _guide,
                  onLearn: _toggleGuide,
                  onStep: _step,
                );
              }
              if (_guide) {
                return FstCard(
                  step: kFstSteps[i - 1],
                  index: i,
                  onClose: _toggleGuide,
                  onStep: _step,
                  onGo: widget.onRail,
                );
              }
              final r = _rail[i - 1];
              return _RailCard(
                rail: r,
                live: _i == i,
                onTap: () => widget.onRail?.call(r.dest),
              );
            },
          ),
        );
      },
    );
  }
}

/// The two strips are not the same height and pretending they were is what
/// left slack under the set. The top one is the shop disc and the search
/// pill — both 44. The foot is the two bordered buttons, which come to about
/// 37, and the Learn disc at 34.
const double _topStripH = 50;
const double _footStripH = 42;

/// Cell 0 — `.hs-hero-cell`. The strip, the set, the strip.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.live,
    this.guide = false,
    this.onExplore,
    this.onGuide,
    this.onSearch,
    this.onStore,
    this.onLearn,
    this.onStep,
  });

  final bool live;

  /// True when the guide has the rail. The set stays and keeps playing —
  /// what changes is what is ON its screen and what is in the strip under
  /// it.
  final bool guide;

  final VoidCallback? onExplore;
  final VoidCallback? onGuide;
  final VoidCallback? onSearch;
  final VoidCallback? onStore;

  /// The white disc, and the way back out of the guide.
  final VoidCallback? onLearn;
  final void Function(int delta)? onStep;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.hs-top` — the store on the left, the search on the right.
          //
          // The two strips are given EXACT heights because the deck's height
          // is computed from them. An estimate there is an overflow here.
          SizedBox(
            height: _topStripH,
            child: Row(
              // Same two groups: the shop keeps left and shrinks if it must,
              // the search sits in the right-hand corner at its own size.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _ShopChip(onTap: onStore)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Sep(),
                    _SearchPill(onTap: onSearch),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TvFrame(
            asset: 'assets/video/hero-bg.mp4',
            frame: DeviceFrame.tvLandscape,
            autoplay: live,
            onTap: onExplore,
            // `.hero-content` IS the screen — index.html:1705. The wordmark,
            // the tagline, the strapline and the big word sit ON it; only
            // the search button and the two buttons are moved off it onto
            // the glass around it.
            //
            // With the guide on, the screen carries the title card instead:
            // "the wordmark goes blonde, Follow the steps comes up under it,
            // and the tagline, the word, the picture rail and the two
            // buttons go" (part084.js:398). The thing you tapped is the
            // thing that answers.
            overlay: guide ? const FstTitle() : _Screen(live: live),
          ),
          const SizedBox(height: 10),
          // `.hs-foot` — Explore and App Guide on the left, then Learn and
          // its disc hard against the right corner.
          SizedBox(
            height: _footStripH,
            // `footNav` — part084.js:394. "Explore and App Guide stand down
            // for as long as it is up, and come back the moment the guide
            // closes." The strip is the title card's own row, and it is the
            // only cell whose row is not on the card itself.
            child: guide
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: FstNav(
                      index: 0,
                      onClose: onLearn ?? () {},
                      onStep: onStep ?? (_) {},
                    ),
                  )
                : Row(
                    // TWO GROUPS, pushed apart. The buttons keep to the left and
                    // Learn with its disc sits in the corner, which is where the
                    // markup puts them.
                    //
                    // Every child used to be a bare Flexible, and Flexible
                    // defaults to flex: 1 — so the buttons, Learn AND the Spacer
                    // were all taking a share of the free width. The buttons
                    // stretched into boxes far wider than their labels and the
                    // Spacer only ever got a quarter of the gap it was there to
                    // hold, which is why Learn floated in the middle instead of
                    // reaching the edge. flex: 0 does not fix it either: that is
                    // the same as not being flexible at all, so the labels could
                    // no longer shrink and the strip overflowed by 77.
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shrinks if it has to; its labels ellipsise before the row
                      // ever overflows.
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: _FootButton(
                                  label: 'EXPLORE', onTap: onExplore),
                            ),
                            const _Sep(),
                            Flexible(
                              child: _FootButton(
                                label: 'APP GUIDE',
                                trailing: Icons.chevron_right,
                                onTap: onGuide,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Natural width, hard against the right edge.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _Sep(),
                          const Text(
                            'LEARN',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: Color(0xE6FFFFFF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // THE DISC. This is what "Learn" is for, and until now
                          // it opened the App Guide page — the same place the
                          // button two inches to its left already went, so the
                          // word beside it was describing nothing of its own.
                          //
                          // It runs the guide: fifteen black cards through the
                          // rail this card is cell 0 of. See follow_steps.dart.
                          Semantics(
                            button: true,
                            // part084.js:509, verbatim.
                            label: 'How this app works — follow the steps',
                            child: GestureDetector(
                              onTap: onLearn,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: NwsbIcon(NwsbMarks.arrow,
                                      size: 15, color: NwsbColors.ink),
                                ),
                              ),
                            ),
                          ),
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

/// Cells 1-6 — `.hs-ban`. The block's own heading, then its clip on the
/// landscape tablet.
class _RailCard extends StatelessWidget {
  const _RailCard({required this.rail, required this.live, this.onTap});
  final _Rail rail;
  final bool live;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x2EFFFFFF)),
                ),
                child: Center(child: NwsbIcon(rail.mark, size: 21)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rail.hello,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0x99FFFFFF),
                        height: 1.2,
                      ),
                    ),
                    Text(
                      rail.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TvFrame(
            asset: rail.asset,
            frame: DeviceFrame.tabletLandscape,
            autoplay: live,
            priority: live ? ClipPriority.feature : ClipPriority.decoration,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

/// `.hs-sep` — the same hairline the app header uses between its marks.
class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 7),
        color: const Color(0x24FFFFFF),
      );
}

/// `.hs-shop` — a white disc with a bag, then TODAY'S over Words & meanings.
class _ShopChip extends StatelessWidget {
  const _ShopChip({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: NwsbIcon(NwsbMarks.bag, size: 20, color: NwsbColors.ink),
            ),
          ),
          const SizedBox(width: 10),
          // Full size. Shrinking this was mine, not asked for — the strip
          // is tall enough to hold it, and if the width ever runs out it is
          // the one line that ellipsises, not the whole block that scales.
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "TODAY'S",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: NwsbColors.goldLight,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Words & meanings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

/// `.hs-searchpill` — the one control on this card that is a live invitation
/// rather than a label, so it says what it is and wears a ring.
class _SearchPill extends StatelessWidget {
  const _SearchPill({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SEARCH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: NwsbColors.ink,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF14141C),
                shape: BoxShape.circle,
              ),
              // `.hero-search-btn` carries assets/icons/search.webp, which
              // is in the repository — the one mark on this card that is a
              // picture rather than a path.
              padding: const EdgeInsets.all(9),
              child: Image.asset(
                'assets/icons/search.webp',
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.search, size: 19, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.hero-btns > *` — Explore and App Guide, bordered rather than filled.
class _FootButton extends StatelessWidget {
  const _FootButton({required this.label, this.trailing, this.onTap});
  final String label;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x0FFFFFFF),
          border: Border.all(color: const Color(0x2EFFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: Colors.white,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing, size: 12, color: const Color(0x99FFFFFF)),
            ],
          ],
        ),
      ),
    );
  }
}

/// What is ON the television — index.html:1713-1750.
///
/// The wordmark at the top left, the tagline word under it, then at the foot
/// the strapline and the big word. Both words rotate: HERO_WORDS and
/// TAG_WORDS from app/js/part012.js:1372 and :1429, the word every 4s and
/// the tagline every 2.5s.
///
/// `.hero-cards` — the five-photograph strip — is NOT here. In the plain
/// look the rail replaces it (app/js/part083.js:20), and the five pictures
/// are remote anyway.
class _Screen extends StatefulWidget {
  const _Screen({required this.live});
  final bool live;

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  /// HERO_WORDS — app/js/part012.js:1372.
  static const _words = [
    'VIBRATION',
    'FREQUENCIES',
    'MIND',
    'NEURONS',
    'RESONANCE',
  ];

  /// TAG_WORDS — :1429.
  static const _tags = [
    'VIBRATION',
    'FREQUENCY',
    'RESONANCE',
    'AWAKENING',
    'SOUND BIRTH',
  ];

  Timer? _wt;
  Timer? _tt;
  int _w = 0;
  int _t = 0;

  @override
  void initState() {
    super.initState();
    _wt = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      setState(() => _w = (_w + 1) % _words.length);
    });
    _tt = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      setState(() => _t = (_t + 1) % _tags.length);
    });
  }

  @override
  void dispose() {
    _wt?.cancel();
    _tt?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // The screen is small and the type on it is sized against the
        // television, not against the phone — so everything scales off the
        // aperture's own width rather than carrying fixed points.
        final u = c.maxWidth / 100;
        // Placed, not stacked in a Flex. The aperture is a FIXED box and
        // a Column inside one overflows the moment the type is a line
        // taller than expected — which is exactly what `.hero-content`
        // avoids on the web by pinning its two groups to the top and the
        // bottom of the screen.
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 5 * u, vertical: 4 * u),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // `clamp(32px, 9vw, 52px)` — against the SCREEN, not
                    // the phone, because the screen is what it is on.
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 10 * u,
                          color: Colors.white,
                          height: 1.05,
                          shadows: const [
                            Shadow(color: Color(0xCC000000), blurRadius: 10),
                          ],
                        ),
                        children: const [
                          TextSpan(
                            text: 'Nowss',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: 'B',
                            style: TextStyle(fontWeight: FontWeight.w200),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.5 * u),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _tags[_t],
                        key: ValueKey(_t),
                        style: TextStyle(
                          fontSize: 2.9 * u,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Color(0xCC000000), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 3.3 * u,
                          color: const Color(0xE6FFFFFF),
                          shadows: const [
                            Shadow(color: Color(0xCC000000), blurRadius: 12),
                          ],
                        ),
                        children: const [
                          TextSpan(text: 'Natural Origin of '),
                          TextSpan(
                            text: 'Word Science',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.5 * u),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _words[_w],
                        key: ValueKey(_w),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 6.4 * u,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 3,
                          height: 1.05,
                          shadows: const [
                            Shadow(color: Color(0xCC000000), blurRadius: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
