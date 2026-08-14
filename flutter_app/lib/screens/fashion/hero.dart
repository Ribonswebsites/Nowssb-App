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
import '../../widgets/tv_frame.dart';

/// One banner on the rail — RAIL, app/js/part083.js:106.
///
/// `asset` is the local stand-in where the web reads a Cloudinary URL. Four
/// of the six are already local files on the web too; the other two fall
/// back to the clip nearest in meaning until the download runs.
class _Rail {
  const _Rail(this.icon, this.hello, this.title, this.asset, this.dest);
  final IconData icon;
  final String hello;
  final String title;
  final String asset;

  /// The tab this banner is a door to.
  final int dest;
}

const _rail = [
  _Rail(Icons.workspace_premium_outlined, 'The Full Library',
      'NowssB Subscription', 'assets/video/subscription-a.mp4', 3),
  _Rail(Icons.shopping_bag_outlined, 'Where a word begins',
      'NowssB Word Store', 'assets/video/store-section.mp4', 3),
  _Rail(Icons.shopping_bag_outlined, 'What a word truly means',
      'NowssB Meaning Store', 'assets/video/store-banner.mp4', 3),
  _Rail(Icons.auto_awesome_outlined, 'The rarest word', 'The Signature',
      'assets/video/signature-banner.mp4', 3),
  _Rail(Icons.menu_book_outlined, 'Page by page', 'NowssB eBooks',
      'assets/video/word-acts.mp4', 2),
  _Rail(Icons.graphic_eq, 'Every word you own', 'Sound Library',
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

  /// MIN_DWELL — the web hands over when the clip ENDS, with a floor under
  /// it. Nothing here knows when a clip ends yet, so the floor is the whole
  /// interval.
  static const _dwell = Duration(seconds: 7);

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(_dwell, (_) {
      // `visible()` — :573. The rail stops when the home is not the screen
      // you are on and when the app is in the background. TickerMode is
      // both of those in Flutter.
      if (!mounted || !TickerMode.valuesOf(context).enabled) return;
      if (!_deck.hasClients) return;
      _i = (_i + 1) % (_rail.length + 1);
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // The deck is as tall as its tallest cell. Cell 0 is the card, and
      // the card is a television plus two strips.
      height: 430,
      child: PageView.builder(
        controller: _deck,
        itemCount: _rail.length + 1,
        onPageChanged: (i) => setState(() => _i = i),
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
  }
}

/// Cell 0 — `.hs-hero-cell`. The strip, the set, the strip.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.live,
    this.onExplore,
    this.onGuide,
    this.onSearch,
    this.onStore,
  });

  final bool live;
  final VoidCallback? onExplore;
  final VoidCallback? onGuide;
  final VoidCallback? onSearch;
  final VoidCallback? onStore;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // `.hs-top` — the store on the left, the search on the right.
          Row(
            children: [
              Flexible(child: _ShopChip(onTap: onStore)),
              const _Sep(),
              _SearchPill(onTap: onSearch),
            ],
          ),
          const SizedBox(height: 10),
          TvFrame(
            asset: 'assets/video/hero-bg.mp4',
            frame: DeviceFrame.tvLandscape,
            autoplay: live,
            onTap: onExplore,
            // `.hero-content` IS the screen — index.html:1705. The wordmark,
            // the tagline, the strapline and the big word sit ON it, and
            // only the search button and the two buttons are moved off it
            // onto the glass. This was empty, which is why the set read as
            // a television showing nothing.
            overlay: _Screen(live: live),
          ),
          const SizedBox(height: 10),
          // `.hs-foot` — Explore, App Guide, then the way into the guide.
          Row(
            children: [
              Flexible(child: _FootButton(label: 'EXPLORE', onTap: onExplore)),
              const _Sep(),
              Flexible(
                child: _FootButton(
                  label: 'APP GUIDE',
                  trailing: Icons.chevron_right,
                  onTap: onGuide,
                ),
              ),
              const _Sep(),
              const Flexible(
                child: Text(
                  'LEARN',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Color(0xE6FFFFFF),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onGuide,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward,
                      size: 19, color: NwsbColors.ink),
                ),
              ),
            ],
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
                child: Icon(rail.icon, size: 21, color: Colors.white),
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
        margin: const EdgeInsets.symmetric(horizontal: 10),
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
            child: const Icon(Icons.shopping_bag_outlined,
                size: 20, color: NwsbColors.ink),
          ),
          const SizedBox(width: 10),
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
        padding: const EdgeInsets.fromLTRB(16, 5, 5, 5),
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
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: NwsbColors.ink,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF14141C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, size: 19, color: Colors.white),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Icon(trailing, size: 15, color: const Color(0x99FFFFFF)),
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
                          fontSize: 13 * u,
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
                          fontSize: 3.4 * u,
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
                          fontSize: 3.9 * u,
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
                          fontSize: 9.5 * u,
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
