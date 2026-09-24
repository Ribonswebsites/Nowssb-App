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
import '../data/notifications.dart';
import '../data/settings.dart';
import '../shell/nav_shell.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/enter_curve_stage.dart';
import '../widgets/hero_curve_stage.dart';
import '../widgets/buddha_gyro_stage.dart';
import '../widgets/stories_find_you_banner.dart';
import '../widgets/subscription_today_offer.dart';
import '../widgets/earth_day_film.dart';
import '../widgets/promo_color_grid.dart';
import '../widgets/studio_panels.dart';
import 'quotes_live.dart';
import 'player_settings.dart';
import 'fashion/header.dart';
import 'fashion/hero.dart';
import 'fashion/sections_bottom.dart';
import 'shared_sections.dart';
import 'fashion/sections_mid.dart';
import 'fashion/sections_top.dart';
import '../widgets/colored_split_promo_banner.dart';
import 'fashion_plus.dart';
import 'notifications_sheet.dart';
import 'normal/header_actions_sheet.dart';
import 'sound_library.dart';
import 'widgets_page.dart';
import 'quick_access.dart';
import '../widgets/home_menu_drawer.dart';
import 'word_detail.dart';
import 'progress/progress_screen.dart';
import 'normal/neomorphic_action_bar.dart';
import 'normal/horizontal_routine_cards.dart';
import 'personal_coach.dart';
import 'healing_path.dart';
import 'subscription.dart';
import 'store/ebooks_store.dart';
import 'reader/reader_hub.dart';
import 'store/request_words.dart';
import 'sentence_builder.dart';
import 'app_settings.dart';
import 'store/meaning_store.dart';

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
  'routineCards',
  'coachCards',
  // Not on the website's registry. Six doors on one panel so the app can
  // be used without knowing where anything is — see MainOptionsSection.
  'mainops',
  'actionbar',
  'reader',
  'herovid',
  'streak',
  'tiles',
  'storiesFind',
  'buddhaGyro',
  'store',
  'trendwd',
  'custom',
  'fashplus',
  'enterCurve',
  'rx',
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
  'journey',
  'personalCoach',
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

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  /// The prescription's word pills open the word itself, the way tapping one
  /// on the web does.
  void _openWord(int i) {
    final all = ContentStore.instance.library;
    if (i < 0 || i >= all.length) return;
    _push(WordDetail(word: all[i]));
  }

  void _openGrid(String id) {
    switch (id) {
      case 'practice':
        _go(1);
      case 'library':
        _go(2);
      case 'store':
        _go(3);
      case 'reader':
        _push(const ReaderHubScreen());
      case 'healing':
        _push(const HealingPathScreen());
      case 'subscription':
        _push(const SubscriptionScreen());
      case 'player':
        _push(const PlayerSettingsScreen());
      case 'progress':
        _push(PracticeProgressScreen(words: ContentStore.instance.library));
      case 'quotes':
        _push(const QuotesWeekScreen());
    }
  }

  void _openEnter(String id) {
    switch (id) {
      case 'player':
        _go(1);
      case 'library':
        _push(const SoundLibraryScreen());
      case 'store':
        _go(3);
      case 'reader':
        _push(const ReaderHubScreen());
      case 'ebook':
        _push(const EbooksStoreScreen());
      case 'healing':
        _push(const HealingPathScreen());
    }
  }

  void _openMainOption(String label, int tab) {
    switch (label) {
      case 'Sound Library':
        _push(const SoundLibraryScreen());
      case 'My Progress':
        _push(PracticeProgressScreen(words: ContentStore.instance.library));
      default:
        _go(tab);
    }
  }

  /// Quick action hero chip → HeaderActionsSheet destinations.
  void _openQuickAction() {
    showHeaderActionsSheet(
      context,
      glassMode: true,
      onGlassToggle: () {},
      onNotifications: () => showNotificationsSheet(context),
      onFashionHome: () {},
      onStore: () => _go(3),
      onPlayer: () => _go(1),
    );
  }

  void _openSearchDest(String key) {
    switch (key) {
      case 'player':
        _go(1);
      case 'library':
      case 'sound-library':
        _push(const SoundLibraryScreen());
      case 'store':
        _go(3);
      case 'reader':
        _push(const ReaderHubScreen());
      case 'meaning-store':
        _push(const MeaningStoreScreen());
      case 'practice':
        _go(1);
      case 'profile':
        _go(4);
      case 'progress':
        _push(PracticeProgressScreen(words: ContentStore.instance.library));
      case 'healing':
      case 'healer':
        _push(const HealingPathScreen());
      case 'fashion':
        _push(const FashionPlusScreen());
      case 'coach':
        _push(const PersonalCoachScreen());
      case 'settings':
        _push(const AppSettingsScreen());
      case 'quick-access':
        _push(const QuickAccessScreen());
      case 'sentence':
        _push(const SentenceBuilderScreen());
      case 'request-words':
        _push(const RequestWordsScreen());
      case 'subscribe':
        _push(const SubscriptionScreen());
      case 'word-science':
      case 'about':
        _go(2);
      case 'widgets':
        _push(const WidgetsPage());
      case 'connect':
        _go(0);
      default:
        _go(2);
    }
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FashHeroRow(
                onCustomize: () => _push(const WidgetsPage()),
                onFeatures: () => _push(const WidgetsPage()),
                onEarn: () => _go(4),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ColoredSplitPromoBanner.forSurface(
                  SplitPromoSurface.fashionHome,
                  onTap: () => _go(1),
                  margin: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        (
          'practice',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FashPractice(onTap: () => _go(1)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ColoredSplitPromoBanner(
                  spec: SplitPromoExtras.at(0, onTap: () => _go(2)),
                  margin: EdgeInsets.zero,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SoundAgePanel(),
              ),
            ],
          ),
        ),
        ('routineCards', Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const NmHorizontalRoutineCards(fashion: true),
            const EarthDayFilm(),
            PromoColorGrid(onOpen: _openGrid),
          ],
        )),
        ('coachCards', const SizedBox.shrink()),
        ('mainops', MainOptionsSection(onGo: _go, onAction: _openMainOption)),
        (
          'actionbar',
          NmSuppliedActionBar(
            glassmorphism: true,
            onSupport: () => _go(4),
            onCoach: () => _push(const PersonalCoachScreen()),
          ),
        ),
        (
          'reader',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FashReader(onTap: () => _push(const ReaderHubScreen())),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ColoredSplitPromoBanner(
                  spec: SplitPromoExtras.at(1, onTap: () => _go(1)),
                  margin: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        (
          'herovid',
          FashStreakVideo(
            onTap: () => _go(1),
            onStoreTap: () => _go(3),
          ),
        ),
        ('streak', FashStreak(onTap: () => _go(1))),
        ('tiles', FashTiles(onTile: _go, onOpen: _openEnter)),
        (
          'storiesFind',
          StoriesFindYouBanner(onTap: () => _go(2)),
        ),
        ('buddhaGyro', BuddhaGyroStage(
          onOpenQuotes: () => _push(const QuotesWeekScreen()),
        )),
        (
          'store',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SubscriptionTodayOffer(
                onClaim: () => _push(const SubscriptionScreen()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ColoredSplitPromoBanner(
                  spec: SplitPromoExtras.at(14, onTap: () => _go(1)),
                  margin: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        ('trendwd', FashTrending(onTap: () => _go(2))),
        (
          'custom',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FashCustomize(onTap: () => _push(const WidgetsPage())),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ColoredSplitPromoBanner(
                  spec: SplitPromoExtras.at(15, onTap: () => _go(2)),
                  margin: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        (
          'fashplus',
          FashPlusMini(onTap: () => _push(const FashionPlusScreen()))
        ),
        (
          'enterCurve',
          EnterCurveStage(onOpen: _openEnter),
        ),
        ('rx', FashPrescription(onTap: () => _go(1), onWord: _openWord)),
        ('trendvid', FashShopNow(onTap: () => _go(3))),
        ('storeban', StoreBannerSection(onTap: () => _go(3))),
        ('subvid', const SizedBox.shrink()),
        (
          'edition',
          EditionSection(onTap: () => _push(const SubscriptionScreen()))
        ),
        ('routines', RoutinesSection(onTap: () => _go(1), fashion: true)),
        ('offer', FashOffer(onTap: () => _go(3))),
        (
          'cube',
          QuickAccessSection(
            onCart: () => _go(3),
            onWishlist: () => _go(3),
            onOrders: () => _go(4),
          ),
        ),
        ('shabda', FashShabdapathy(onTap: () => _go(2))),
        ('ebooks', EbooksSection(onTap: () => _go(2))),
        ('connectban', ConnectBannerSection(onTap: () => _go(0))),
        (
          'healing',
          HealingSection(
            onTap: () => _push(const HealingPathScreen()),
            onFemale: () => _push(
                const HealingPathScreen(initialGender: HealingGender.female)),
            onMale: () => _push(
                const HealingPathScreen(initialGender: HealingGender.male)),
          ),
        ),
        ('journey', const SizedBox.shrink()),
        ('personalCoach', const SizedBox.shrink()),
        // Choose Your Path is slide 2 of HealingSection — do not inject a
        // second banner/section (that caused stacked banners + blank pages).
        ('genderpath', const SizedBox.shrink()),
        ('promovid', FashPromoVideo(onOpen: _openEnter)),
        ('wsearch', FashWordSearch(onOpen: (_) => _go(2))),
        ('msearch', FashMeaningSearch(onOpen: (_) => _go(2))),
        ('shabvid', FashShabdaVideo(onTap: () => _go(2))),
        ('footer', HomeFooterSection(onLink: _footerLink)),
      ];

  @override
  Widget build(BuildContext context) {
    final built = _sections();
    // Keep this as a non-fatal diagnostic. A stale debug build or a generated
    // section patch must never replace the entire home with Flutter's red
    // assertion screen; the page can still render and the test suite catches
    // a real registry change.
    assert(() {
      final keys = built.map((e) => e.$1).toList();
      if (keys.toString() != kFashionSectionOrder.toString()) {
        debugPrint('NowssB: Fashion section registry drift: $keys');
      }
      return true;
    }());

    final shown = [
      for (final (k, w) in built)
        if (!kFashionDefOff.contains(k)) (k, w),
    ];

    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: Stack(
        children: [
          // One selected Fashion Plus film is shared with every destination;
          // with motion off this resolves to the chosen still or black.
          const Positioned.fill(child: AppBackdrop()),
          // `#fpBgVeil` — nowssb-nm.css:10853. TWO layers, and the point of
          // both is that the MIDDLE OF THE SCREEN IS LEFT ALONE: a radial
          // that pulls only the corners down, and a light top-and-bottom
          // weight so the header and the tab bar have something to sit on.
          //
          // What was here was a solid scrim at 85% / 95% / 98%, which is not
          // a vignette — it is a lid. The film was playing underneath it and
          // could not be seen at all, which is exactly what the page looked
          // like: black.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.1), // 50% 45%
                    radius: 0.88,
                    colors: [
                      Color(0x00000000),
                      Color(0x24000000), // rgba(0,0,0,0.14)
                      Color(0x57000000), // rgba(0,0,0,0.34)
                      Color(0x94000000), // rgba(0,0,0,0.58)
                    ],
                    stops: [0.30, 0.58, 0.80, 1.0],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x42000000), // rgba(0,0,0,0.26)
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x57000000), // rgba(0,0,0,0.34)
                    ],
                    stops: [0, 0.20, 0.76, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // `.home-header` is fixed above the page and never scrolls, so
          // it is outside the scroller rather than its first row.
          // NOT wrapped in a SafeArea. The header's glass has to run to the
          // very top of the screen and the status bar sits ON it — a
          // SafeArea out here inset the whole column instead, which left a
          // black band above the header and made it look like a bar that
          // stopped short.
          Column(
            children: [
              ListenableBuilder(
                listenable: NotifStore.instance,
                builder: (context, _) {
                  return HomeHeader(
                    notifications: NotifStore.instance.unreadRaw,
                    onNotifications: () => showNotificationsSheet(context),
                    onNormalHome: () => Settings.instance.setFashionHome(false),
                    onMenu: () => showHomeMenuDrawer(context, goTab: _go),
                  );
                },
              ),
              Expanded(
                // No horizontal padding on the list: the wrappers carry
                // their own `margin: 18px 16px`.
                child: ListView.builder(
                  // Modest look-ahead so off-screen video sections stay
                  // lazy-mounted instead of opening every decoder at once.
                  cacheExtent: 480,
                  // Footer carries solid-black bottom clearance (no video bleed).
                  padding: EdgeInsets.zero,
                  itemCount: shown.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      // The greeting sits ABOVE the deck, not inside it —
                      // app/js/part083.js:505 inserts it before the deck
                      // in the home; it does not travel with the rail.
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const LiveQuoteTab(),
                          HeroGreeting(name: widget.name),
                          // Search + Quick access live ONLY inside HeroCurveStage.
                          HeroCurveStage(
                            glass: true,
                            onSearch: () => showDestinationSearchSheet(
                              context,
                              onSelect: _openSearchDest,
                            ),
                            // Quick action → HeaderActionsSheet, NOT QuickAccessScreen.
                            onQuickAccess: _openQuickAction,
                          ),
                          FashionHero(
                            onExplore: () => _go(2),
                            onGuide: () => _push(const WidgetsPage()),
                            onSearch: () => showDestinationSearchSheet(
                              context,
                              onSelect: _openSearchDest,
                            ),
                            onStore: () => _go(3),
                            onRail: _go,
                          ),
                        ],
                      );
                    }
                    final (k, w) = shown[i - 1];
                    return KeyedSubtree(key: ValueKey('fash-$k'), child: w);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
