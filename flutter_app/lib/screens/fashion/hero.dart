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
import '../../admin/template/editable.dart';
import '../../admin/layout/carousel_fx.dart';
import '../../admin/layout/layout_sections.dart' show CarouselAutoRotate;

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

/// One banner on the rail — RAIL, app/js/part083.js:106.
///
/// `asset` is THE ADDRESS THE WEBSITE PLAYS, copied verbatim — a bundled
/// file for the two that are local on the web, and the R2 URL for
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
  _Rail(NwsbMarks.crown, 'The Full Library', 'NowssB Subscription',
      'assets/video/subscription-b.mp4', 3),
  // The clip a word page opens with — NWSB_WORD_BANNER_VID.
  _Rail(NwsbMarks.word, 'Where a word begins', 'NowssB Word Store',
      'assets/video/hero-word-store.mp4', 3),
  // The clip every meaning's page opens with — MS_MEANING_VID.
  _Rail(NwsbMarks.meaning, 'What a word truly means', 'NowssB Meaning Store',
      'assets/video/hero-meaning-store.mp4', 3),
  _Rail(NwsbMarks.signature, 'The rarest word', 'The Signature',
      'assets/video/signature-banner.mp4', 3),
  // The eBooks banner clip — and NOT the little one spinning in the spill
  // disc, which is the mistake part083.js:130 records having made.
  _Rail(NwsbMarks.book, 'Page by page', 'NowssB eBooks',
      'assets/video/hero-ebooks.mp4', 2),
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
    this.onQuickAccess,
  });

  final VoidCallback? onExplore;
  final VoidCallback? onGuide;
  final VoidCallback? onSearch;
  final VoidCallback? onStore;
  final VoidCallback? onQuickAccess;

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
    if (_flutterTest) return;
    _t = Timer.periodic(_dwell, (_) {
      // `visible()` — :573. The rail stops when the home is not the screen
      // you are on and when the app is in the background. TickerMode is
      // both of those in Flutter.
      if (!mounted || !TickerMode.of(context)) return;
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
        final stacked = _footStacks(MediaQuery.textScalerOf(context), inner);
        final h = 12 + _topStripH + 10 + tv + 10 +
            (stacked ? _footStackedH : _footStripH) + 12 + (8 * 2) + 2;
        return SizedBox(
          height: h,
          child: CarouselAutoRotate(controller: _deck, count: _cells, child: PageView.builder(
            controller: _deck,
            itemCount: _cells,
            onPageChanged: (i) {
              // A finger on the rail means the same thing here as it does on an
              // arrow — part084.js:540.
              _held = DateTime.now().add(_hold);
              setState(() => _i = i);
            },
            itemBuilder: (context, i) => carouselFxItem(context, _deck, i, _cell(i, stacked)),
          )),
        );
      },
    );
  }

  Widget _cell(int i, bool footStacked) {
              if (i == 0) {
                return _HeroCard(
                  footStacked: footStacked,
                  onExplore: widget.onExplore,
                  onGuide: widget.onGuide,
                  onSearch: widget.onSearch,
                  onStore: widget.onStore,
                  onQuickAccess: widget.onQuickAccess,
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
  }
}

/// The two strips are not the same height and pretending they were is what
/// left slack under the set. The top one is the shop disc and the search
/// pill — both 44. The foot is the two bordered buttons, which come to about
/// 37, and the Learn disc at 34.
const double _topStripH = 44;
const double _footStripH = 42;
const double _footStackedH = _footStripH * 2 + 6;

/// B028: on one line the foot squeezes EXPLORE / APP GUIDE / LEARN until the
/// labels are tiny at 320dp x1.3. When one line can't hold every label at
/// 80% or more of full size, the foot takes two lines instead: the two
/// buttons, then Learn and its disc against the right edge.
bool _footStacks(TextScaler ts, double width) {
  double tw(String t, double size, double ls) => (TextPainter(
          text: TextSpan(text: t, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, letterSpacing: ls)),
          textDirection: TextDirection.ltr,
          textScaler: ts,
          maxLines: 1)
        ..layout())
      .width;
  // Each button: 9 + 9 padding and a 1px border each side.
  final explore = 0.8 * tw('EXPLORE', 9.5, 0.2) + 20;
  final guide = 0.8 * tw('APP GUIDE', 9.5, 0.2) + 20 + 4 + 12;
  final learn = tw('LEARN', 10.5, 0.4) + 8 + 34;
  const seps = 2 * 15.0;
  return explore + guide + learn + seps > width;
}

Widget _footLayout(bool stacked, Row row) {
  if (!stacked) return row;
  final buttons = row.children.first;
  final learn = row.children.last as Row;
  return Column(
    key: const ValueKey('hero-foot-stacked'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: _footStripH, child: Row(children: [buttons])),
      const SizedBox(height: 6),
      SizedBox(
        height: _footStripH,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: learn.children.skip(1).toList(),
        ),
      ),
    ],
  );
}

/// Cell 0 — `.hs-hero-cell`. The strip, the set, the strip.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.live,
    this.footStacked = false,
    this.guide = false,
    this.onExplore,
    this.onGuide,
    this.onSearch,
    this.onStore,
    this.onQuickAccess,
    this.onLearn,
    this.onStep,
  });

  final bool live;
  /// The foot runs on two lines (B028): see [_footStacks].
  final bool footStacked;

  /// True when the guide has the rail. The set stays and keeps playing —
  /// what changes is what is ON its screen and what is in the strip under
  /// it.
  final bool guide;

  final VoidCallback? onExplore;
  final VoidCallback? onGuide;
  final VoidCallback? onSearch;
  final VoidCallback? onStore;
  final VoidCallback? onQuickAccess;

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
              // Shop left + search only. Quick access lives in HeroCurveStage.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _ShopChip(onTap: onStore)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Sep(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _SearchPill(onTap: onSearch),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TvFrame(
            asset: 'assets/tv/home-words-tv.mp4',
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
          // B028: a light dark wash under the label row so the white
          // EXPLORE / APP GUIDE / LEARN hold 4.5:1 on any backdrop, the
          // bright flat-grey fallback included, not only on the dark film.
          DecoratedBox(
            key: const ValueKey('hero-foot-scrim'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x47000000), Color(0x5C000000)],
              ),
            ),
            child: SizedBox(
            height: footStacked ? _footStackedH : _footStripH,
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
                : _footLayout(footStacked, Row(
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
                          const EditableLabel('hero.HeroCard',
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
                  )),
          )),
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
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: NwsbIcon(NwsbMarks.bag, size: 18, color: NwsbColors.ink),
            ),
          ),
          const SizedBox(width: 10),
          // Full size. Shrinking this was mine, not asked for — the strip
          // is tall enough to hold it, and if the width ever runs out it is
          // the one line that ellipsises, not the whole block that scales.
          // The strip has an exact height, so at large text the two lines
          // scale down together rather than spill onto the screen below
          // (B016).
          const Flexible(
            child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                EditableLabel('hero.ShopChip',
                  "TODAY'S",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: NwsbColors.goldLight,
                  ),
                ),
                SizedBox(height: 1),
                EditableLabel('hero.ShopChip',
                  'Words & meanings',
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
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

/// `.hs-searchpill` — the one control on this card that is a live invitation
/// rather than a label, so it says what it is and wears a ring.

/// Top-right Quick action control on the Fashion hero header.
class _QuickAccessChip extends StatelessWidget {
  const _QuickAccessChip({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0x44FFFFFF)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apps_rounded, size: 16, color: Colors.white),
            SizedBox(width: 6),
            EditableLabel('hero.QuickAccessChip',
              'Quick action',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EditableLabel('hero.SearchPill',
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
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF14141C),
                shape: BoxShape.circle,
              ),
              // `.hero-search-btn` carries assets/icons/search.webp, which
              // is in the repository — the one mark on this card that is a
              // picture rather than a path.
              padding: const EdgeInsets.all(8),
              child: EditableImage.asset(
                'assets/icons/search.webp',
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.search, size: 19, color: Colors.white),
                    slot: 'hero.SearchPill',
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
            // Scale the label to the room it has instead of cutting it to
            // "EXPLO…" at large text on a narrow screen (B016).
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: EditableLabel('hero.FootButton',
                label,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: Colors.white,
                ),
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
  // Minimal overlay on the left of the TV: a thick white NowssB and one
  // short line. Nothing else on the screen.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final u = c.maxWidth / 100;
        const shadow = [Shadow(color: Color(0xCC000000), blurRadius: 12)];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 5 * u, vertical: 4 * u),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NowssB',
                  style: TextStyle(
                    fontSize: 11 * u,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: -0.5,
                    shadows: shadow,
                  ),
                ),
                SizedBox(height: 1.5 * u),
                Text(
                  'Words & meanings',
                  style: TextStyle(
                    fontSize: 3.6 * u,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: shadow,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
