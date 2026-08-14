/// The Fashion home — `#home`, the dark one.
///
/// The app has two homes and they are not skins of each other. The Normal
/// home is a pale neumorphic surface where every card is raised out of the
/// page by a shadow pair. This one is the opposite: a dark page with the film
/// running behind it and every block sitting on it as a pane of glass.
///
/// WHAT THIS PAGE IS, EXACTLY
///
/// `REG.fash.items` in app/js/part062.js:105-149 is the list of sections this
/// home is made of — thirty of them, in that order. This file is that list,
/// in that order, and nothing else: every section is a widget in
/// lib/screens/fashion/, each carrying the index.html line it was
/// transcribed from. Read the two side by side and they say the same thing.
///
/// Four entries are `defOff` — My Routines, Shabdapathy Foundations, Word
/// Search, Meaning Search. They are built like any other section and hidden
/// on a fresh install, which is what a fresh install shows. 26 of 30 are
/// visible. Reordering and hiding at runtime (the web's `hlApplyLayout`) is
/// not ported; [_defOff] is a constant, not a stored list.
///
/// The film behind it is the point. On the website that is `#fpBgVideo`, one
/// fixed element under every screen; here it is one [NwsbVideo] behind the
/// list, marked as a feature so it keeps its decoder while the banners
/// further down come and go.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../data/settings.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../shell/nav_shell.dart';
import '../theme/tokens.dart';
import 'fashion/header.dart';
import 'fashion/hero.dart';
import 'fashion/sections_bottom.dart';
import 'shared_sections.dart';
import 'fashion/sections_mid.dart';
import 'fashion/sections_top.dart';
import 'fashion_plus.dart';
import 'sound_library.dart';
import 'widgets_page.dart';
import 'word_detail.dart';

/// `REG.fash.items` — app/js/part062.js:107-148, key for key and in order.
///
/// Stated separately from the widgets so a test can hold the two against
/// each other: a section quietly dropped from the page is otherwise
/// invisible until someone scrolls the whole home on a device looking for
/// something they cannot name.
const kFashionSectionOrder = <String>[
  'greet',
  'herorow',
  'practice',
  'reader',
  'herovid',
  'streak',
  'tiles',
  'store',
  'trendwd',
  'custom',
  'fashplus',
  'rx',
  'connect',
  'trendvid',
  'storeban',
  'subvid',
  'edition',
  'routines',
  'offer',
  'cube',
  'shabda',
  'ebooks',
  'connectban',
  'healing',
  'genderpath',
  'promovid',
  'wsearch',
  'msearch',
  'shabvid',
  'footer',
];

/// The four `defOff` entries. Built, not placed.
const kFashionDefOff = <String>{'routines', 'shabda', 'wsearch', 'msearch'};

class HomeFashion extends StatefulWidget {
  const HomeFashion({super.key, this.name = 'Healer'});

  final String name;

  @override
  State<HomeFashion> createState() => _HomeFashionState();
}

class _HomeFashionState extends State<HomeFashion> {
  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    super.dispose();
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  void _go(int tab) => NavScope.goTo(context, tab);

  void _push(Widget page) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => page),
      );

  /// The prescription's word pills open the word itself, the way tapping one
  /// on the web does.
  void _openWord(int i) {
    final all = ContentStore.instance.library;
    if (i < 0 || i >= all.length) return;
    _push(WordDetail(word: all[i]));
  }

  void _footerLink(String key) {
    switch (key) {
      case 'about':
      case 'word-science':
        _go(2);
      case 'sound-library':
        _push(const SoundLibraryScreen());
      case 'meaning-store':
        _go(3);
      case 'practice':
        _go(1);
      case 'profile':
        _go(4);
    }
  }

  /// The thirty, in `REG.fash.items` order. Keyed by the registry's own `k`
  /// so the two lists can be diffed by eye.
  List<(String, Widget)> _sections() => [
        ('greet', const FashGreeting()),
        (
          'herorow',
          FashHeroRow(
            onCustomize: () => _push(const WidgetsPage()),
            onFeatures: () => _push(const WidgetsPage()),
            onEarn: () => _go(4),
          )
        ),
        ('practice', FashPractice(onTap: () => _go(1))),
        ('reader', FashReader(onTap: () => _go(2))),
        ('herovid', FashStreakVideo(onTap: () => _go(1))),
        ('streak', FashStreak(onTap: () => _go(1))),
        ('tiles', FashTiles(onTile: _go)),
        ('store', FashStore(onTap: () => _go(3))),
        ('trendwd', FashTrending(onTap: () => _go(2))),
        ('custom', FashCustomize(onTap: () => _push(const WidgetsPage()))),
        (
          'fashplus',
          FashPlusMini(onTap: () => _push(const FashionPlusScreen()))
        ),
        (
          'rx',
          FashPrescription(onTap: () => _go(1), onWord: _openWord),
        ),
        ('connect', FashConnect(onTap: () => _go(0))),
        ('trendvid', FashShopNow(onTap: () => _go(3))),
        ('storeban', FashStoreBanner(onTap: () => _go(3))),
        ('subvid', SubscriptionSection(onTap: () => _go(3))),
        ('edition', EditionSection(onTap: () => _go(3))),
        ('routines', RoutinesSection(onTap: () => _go(1))),
        ('offer', FashOffer(onTap: () => _go(3))),
        (
          'cube',
          QuickAccessSection(
            onCart: () => _go(3),
            onWishlist: () => _go(3),
            onOrders: () => _go(4),
          )
        ),
        ('shabda', FashShabdapathy(onTap: () => _go(2))),
        ('ebooks', EbooksSection(onTap: () => _go(2))),
        ('connectban', ConnectBannerSection(onTap: () => _go(0))),
        ('healing', HealingSection(onTap: () => _go(2))),
        (
          'genderpath',
          GenderPathSection(
            onFemale: () => _go(2),
            onMale: () => _go(2),
            onTap: () => _go(2),
          )
        ),
        ('promovid', FashPromoVideo(onTap: () => _go(2))),
        ('wsearch', FashWordSearch(onOpen: (_) => _go(2))),
        ('msearch', FashMeaningSearch(onOpen: (_) => _go(2))),
        ('shabvid', FashShabdaVideo(onTap: () => _go(2))),
        ('footer', HomeFooterSection(onLink: _footerLink)),
      ];

  @override
  Widget build(BuildContext context) {
    final built = _sections();
    assert(
      built.map((e) => e.$1).toList().toString() ==
          kFashionSectionOrder.toString(),
      'the page and the registry have drifted apart',
    );

    final shown = [
      for (final (k, w) in built)
        if (!kFashionDefOff.contains(k)) w,
    ];

    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          // The page's own film, behind everything. Fixed in effect: it is
          // outside the scroller, so it does not move with the list.
          const Positioned.fill(
            child: NwsbVideo(
              asset: 'assets/video/fashion-plus-bg-6.mp4',
              priority: ClipPriority.feature,
            ),
          ),
          // A scrim, or nothing on top of it is readable. The film is busy
          // and bright in places and the whole page is white type.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD9060C18),
                    Color(0xF2060C18),
                    Color(0xFA060C18),
                  ],
                ),
              ),
            ),
          ),

          // `.home-header` is fixed above the page and never scrolls, so
          // it is outside the scroller rather than its first row.
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                HomeHeader(
                  onNormalHome: () => Settings.instance.setFashionHome(false),
                  onMenu: () => _push(const WidgetsPage()),
                ),
                Expanded(
                  // No horizontal padding on the list: the wrappers carry
                  // their own `margin: 18px 16px`.
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 108),
                    itemCount: shown.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        // The greeting sits ABOVE the deck, not inside it —
                        // app/js/part083.js:505 inserts it before the deck
                        // in the home; it does not travel with the rail.
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            HeroGreeting(name: widget.name),
                            FashionHero(
                              onExplore: () => _go(2),
                              onGuide: () => _push(const WidgetsPage()),
                              onSearch: () => _go(2),
                              onStore: () => _go(3),
                              onRail: _go,
                            ),
                          ],
                        );
                      }
                      return shown[i - 1];
                    },
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
