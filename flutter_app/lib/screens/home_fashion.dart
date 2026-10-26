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
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/layout/layout_sections.dart';
import '../data/content.dart';
import '../data/notifications.dart';
import '../data/settings.dart';
import '../shell/nav_shell.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/black_glass_banner.dart';
import '../widgets/four_banners.dart';
import '../widgets/meditation_flip_banner.dart';
import '../widgets/enter_curve_stage.dart';
import '../widgets/buddha_gyro_stage.dart';
import '../widgets/stories_find_you_banner.dart';
import '../widgets/earth_day_film.dart';
import '../widgets/promo_color_grid.dart';
import 'quotes_live.dart';
import 'player_settings.dart';
import 'fashion/drop_studio.dart';
import 'fashion/header.dart';
import 'fashion/hero_quick_row.dart';
import 'fashion/home_cards.dart';
import 'store/product_detail.dart' show openAtelierWord;
import '../features/progress/progress_center.dart';
import '../features/programs/rewards_program.dart';
import '../features/gifts/gifts_screen.dart';
import '../features/economy/coupon_screen.dart';
import '../features/progress/progress_popup.dart';
import 'store/daily_deals.dart';
import 'store/word_atelier.dart';
import 'store/store_cards.dart' show money;
import '../data/store_prices.dart';
import 'daily_tasks.dart';
import 'fashion/hero.dart';
import 'fashion/sections_bottom.dart';
import 'shared_sections.dart';
import 'normal/home_v4.dart' show kRewardsLottie, kCoinsLottie, kGiftLottie, kSpeakerLottie, kPlayLottie, kProgressLottie;
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
import '../widgets/program_shelf.dart';
import '../widgets/nwsb_icon.dart';
import 'app_settings.dart';
import '../features/earn/earn_home_sections.dart';
import '../widgets/sections/category_tiles_section.dart';
import '../widgets/sections/spotlight_section.dart';
import '../features/earn/earn_hub_screen.dart';
import '../features/programs/program_router.dart';
import '../shell/nwsb_links.dart';
import 'features_page.dart';
import '../widgets/home_keep_alive.dart';
import 'store/meaning_store.dart';

/// `REG.fash.items` — app/js/part062.js:107-148, key for key and in order.
///
/// Stated separately from the widgets so a test can hold the two against
/// each other: a section quietly dropped from the page is otherwise
/// invisible until someone scrolls the whole home on a device looking for
/// something they cannot name.
const kFashionSectionOrder = <String>[
  'greet',
  'practice',
  'herorow',
  'routineCards',
  'coachCards',
  // Not on the website's registry. Six doors on one panel so the app can
  // be used without knowing where anything is — see MainOptionsSection.
  'mainops',
  'actionbar',
  // MK-6 home mix (ref 5): category tiles + spotlight, high on the page.
  'catTiles',
  'spotlight',
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
  'roundring',
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

/// Plain-words names for the UI Editor.
const kFashionSectionTitles = <String, String>{
  'greet': 'Greeting line',
  'herorow': 'Hero row & split banner',
  'roundring': 'NowssB Coupons',
  'practice': 'Practice card',
  'routineCards': 'Routine cards, Earth Day film & colour grid',
  'mainops': 'Main options',
  'actionbar': 'Support & coach bar',
  'catTiles': 'Category tiles & filters',
  'spotlight': 'In the spotlight',
  'reader': 'Reader & promo banner',
  'herovid': 'Streak & store videos',
  'streak': 'Streak',
  'tiles': 'Feature tiles',
  'storiesFind': 'Stories find you',
  'buddhaGyro': 'Buddha quotes stage',
  'store': "Today's offer",
  'trendwd': 'Trending words',
  'custom': 'Customize',
  'fashplus': 'Fashion Plus',
  'enterCurve': 'Enter curve',
  'rx': 'Word prescription',
  'trendvid': 'Shop now video',
  'storeban': 'Store banner, earn, rewards & gifts',
  'edition': 'Edition',
  'routines': 'Routines (off by default)',
  'offer': 'Offer',
  'cube': 'Quick access cube',
  'shabda': 'Shabdapathy foundations (off by default)',
  'ebooks': 'eBooks',
  'connectban': 'Connect banner',
  'healing': 'Healing path',
  'wsearch': 'Word search (off by default)',
  'msearch': 'Meaning search (off by default)',
  'shabvid': 'Shabdapathy video',
  'footer': 'Footer',
};

/// Sideways carousels wired to the Animation tab's transitions and
/// auto-rotate (carouselFxItem / CarouselAutoRotate inside them).
const kFashionCarousels = <String>{'tiles', 'healing'};

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
    Settings.instance.addListener(_onSettings);
    _loadProfile();
  }

  /// Profile completion (name, photo, banner, reminder) — same keys the
  /// Profile tab saves.
  double _profileDone = 0;
  int _profileLeft = 4;
  Future<void> _loadProfile() async {
    try {
      final p = await SharedPreferences.getInstance();
      bool has(String k) => (p.getString(k) ?? '').trim().isNotEmpty;
      final checks = [
        has('nowssb_name'),
        has('nwsb_local_photo') || has('nwsb_photo_path'),
        has('nwsb_local_banner') || has('nwsb_banner_path'),
        has('nowssb_reminder'),
      ];
      final done = checks.where((e) => e).length;
      if (!mounted) return;
      setState(() {
        _profileDone = done / checks.length;
        _profileLeft = checks.length - done;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    Settings.instance.removeListener(_onSettings);
    super.dispose();
  }

  // Rebuild Home only when what it shows changes (the library arriving,
  // or a home setting), not on every progress tick.
  Object? _lib;
  int _libLen = -1;
  void _onContent() {
    final lib = ContentStore.instance.library;
    if (identical(lib, _lib) && lib.length == _libLen) return;
    _lib = lib;
    _libLen = lib.length;
    if (mounted) setState(() {});
  }

  void _onSettings() {
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
        _push(const AboutNowssbScreen(science: true));
      case 'about':
        _push(const AboutNowssbScreen());
      case 'features':
        _push(const FeaturesPage());
      case 'widgets':
        _push(const WidgetsPage());
      case 'connect':
        NwsbLinks.connect(context);
      default:
        _go(2);
    }
  }

  void _footerLink(String key) {
    switch (key) {
      case 'about':
        _push(const AboutNowssbScreen());
      case 'word-science':
        _push(const AboutNowssbScreen(science: true));
      case 'sound-library':
        _push(const SoundLibraryScreen());
      case 'meaning-store':
        _push(const MeaningStoreScreen());
      case 'practice':
        _go(1);
      case 'profile':
        _go(4);
    }
  }

  /// Pool for the daily 8-card quick row; every entry opens a real page.
  List<QuickCard> _quickPool() => [
        QuickCard('rewards', 'Rewards', 'Your coins & perks', Icons.workspace_premium_rounded, () => _push(const RewardsProgramPage()), lottie: kRewardsLottie),
        QuickCard('earn', 'Earn', 'Coins for practice', Icons.savings_rounded, () => _push(const EarnHubScreen()), lottie: kCoinsLottie),
        QuickCard('gifts', 'Gifts', 'Send or redeem', Icons.card_giftcard_rounded, () => _push(const GiftsScreen()), lottie: kGiftLottie),
        QuickCard('coupons', 'Coupons', 'Deals for you', Icons.local_offer_rounded, () => _push(const CouponScreen())),
        QuickCard('store', 'Store', 'Deal of the Day', Icons.storefront_rounded, () => _go(3)),
        QuickCard('progress', 'Progress', 'Today at a glance', Icons.donut_large_rounded, () => ProgressPanel.open(context), lottie: kProgressLottie),
        QuickCard('practice', 'Practice', 'Start a session', Icons.play_circle_fill_rounded, () => _go(1), lottie: kPlayLottie),
        QuickCard('tasks', 'Daily tasks', 'Tick off today', Icons.checklist_rounded, () => _push(const DailyTasksPage())),
        QuickCard('sounds', 'Sound library', 'Every word sound', Icons.graphic_eq_rounded, () => _push(const SoundLibraryScreen()), lottie: kSpeakerLottie),
        QuickCard('meanings', 'Meanings', 'Signature words', Icons.auto_stories_rounded, () => _push(const MeaningStoreScreen())),
        QuickCard('features', 'Features', 'Everything in NowssB', Icons.grid_view_rounded, () => _push(const FeaturesPage())),
        QuickCard('atelier', 'Atelier', 'Word Atelier', Icons.spellcheck_rounded, () => _push(const WordAtelierScreen())),
        QuickCard('healing', 'Healing', 'Your healing path', Icons.spa_rounded, () => _push(const HealingPathScreen())),
      ];

  /// Today's Store words (real deals), priced in local currency; each
  /// opens that word in the store.
  List<StoreNowItem> _storeItems() => [
        for (final d in dailyDeals(count: 8))
          StoreNowItem(
            word: d.title,
            category: d.category,
            percent: realDealPercent(d.word),
            price: money(StorePrices.instance.priceFor('word:${d.word.toLowerCase()}')),
            onTap: () => openAtelierWord(context,
                word: d.word, root: d.root, img: kHomeStoreArt, price: StorePrices.instance.priceFor('word:${d.word.toLowerCase()}')),
          ),
      ];

  /// Currently Playing–style rail: coins, progress, profile, two tasks.
  Widget _progressRail() => ListenableBuilder(
        listenable: Listenable.merge([ProgressCenter.instance, DailyTasks.items]),
        builder: (context, _) {
          final pc = ProgressCenter.instance;
          final coins = pc.itemOf(ProgressKind.coins);
          final all = pc.items;
          final done = all.fold<int>(0, (a, e) => a + e.done);
          final total = all.fold<int>(0, (a, e) => a + e.total);
          final tasks = DailyTasks.items.value;
          final open = [...tasks.where((t) => !t.done), ...tasks.where((t) => t.done)].take(2).toList();
          final tasksDone = tasks.where((t) => t.done).length;
          const taskArt = ['assets/banners/earn/sit-dark.png', 'assets/banners/earn/hands-raise.png'];
          final pct = (_profileDone * 100).round();
          return NowProgressRail(items: [
            NowProgressItem(
              title: 'Next coins',
              sub: coins == null || coins.done < coins.total ? 'Collect your next daily coins' : 'All daily coins collected',
              caption: 'Coins',
              image: 'assets/rails/rewards-coins.png',
              value: coins?.value ?? 0,
              left: '${coins?.done ?? 0}/${coins?.total ?? 2} coins',
              right: '${((coins?.value ?? 0) * 100).round()}%',
              icon: Icons.toll_rounded,
              onTap: () => _push(const EarnHubScreen()),
            ),
            NowProgressItem(
              title: 'Your progress',
              sub: "Today's tasks, practice, coins and check-in",
              caption: 'Progress',
              image: 'assets/profile_source/img-progress.png',
              value: total == 0 ? 0 : done / total,
              left: '$done of $total today',
              right: '${total == 0 ? 0 : (done * 100 / total).round()}%',
              icon: Icons.donut_large_rounded,
              onTap: () => ProgressPanel.open(context),
            ),
            NowProgressItem(
              title: pct >= 100 ? 'Profile complete' : 'Profile not finished',
              sub: pct >= 100 ? 'Everything is set' : '$_profileLeft step${_profileLeft == 1 ? '' : 's'} left: name, photo, banner, reminder',
              caption: 'Profile',
              image: 'assets/profile_source/img-ring.png',
              value: _profileDone,
              left: '$pct% complete',
              right: '100%',
              icon: Icons.person_rounded,
              onTap: () => _go(4),
            ),
            for (var i = 0; i < open.length; i++)
              NowProgressItem(
                title: open[i].title,
                sub: open[i].done ? 'Done today' : 'Daily task · tick it off',
                caption: 'Task ${i + 1}',
                image: taskArt[i % taskArt.length],
                value: open[i].done ? 1 : 0,
                left: '$tasksDone of ${tasks.length} done',
                right: open[i].done ? 'Done' : 'To do',
                icon: open[i].done ? Icons.check_rounded : Icons.checklist_rounded,
                onTap: () => _push(const DailyTasksPage()),
              ),
          ]);
        },
      );

  /// Daily pool for the Today's Practice carousel; each opens a real page.
  List<PracticeBannerSpec> _practicePool() => [
        PracticeBannerSpec("Today's Practice", 'Begin your healing path', () => _go(1)),
        PracticeBannerSpec('Sit with one word', 'Five quiet minutes', () => _go(1)),
        PracticeBannerSpec('Your word ritual', 'Pick up where you left', () => _go(1)),
        PracticeBannerSpec('Listen, then repeat', 'Three, seven or twenty-one reps', () => _go(1)),
        PracticeBannerSpec('Morning practice', 'The card knows the hour', () => _go(1)),
        PracticeBannerSpec('Speak it back', 'Scored from 0 to 100', () => _go(1)),
        PracticeBannerSpec('Words for today', 'Queued and ready to play', () => _go(1)),
        PracticeBannerSpec('Breathe and repeat', 'Start a word session', () => _go(1)),
        PracticeBannerSpec('Close with a sentence', 'Healing words from your session', () => _go(1)),
      ];

  void _openQuickActions() {
    showHeaderActionsSheet(
      context,
      glassMode: false,
      onGlassToggle: () {},
      onNotifications: () => showNotificationsSheet(context),
      onFashionHome: () => Settings.instance.setFashionHome(false),
      onStore: () => _go(3),
      onPlayer: () => _go(1),
    );
  }

  /// The thirty, in `REG.fash.items` order. Keyed by the registry's own `k`
  /// so the two lists can be diffed by eye.
  /// Vertical air between stacked Fashion home sections (Ribon, Oct 27).
  static const double kFashSectionGap = 22;

  List<(String, Widget)> _sections() => [
        // Today's Practice rides inside the greeting so it always sits
        // directly under the heading (a saved layout can't split them).
        ('greet', FashGreeting(below: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FashPractice(
                banners: dailyPracticeBanners(_practicePool()),
                // Today's Practice opens the Practice tab (Ribon, Oct 24).
                onTap: () => _go(1),
              ),
              // NowssB Store sits directly under Today's Practice (Ribon, Oct 24).
              StoreNowCarousel(items: _storeItems(), onHeader: () => _push(const WordAtelierScreen())),
            ],
          ))),
        ('practice', const SizedBox.shrink()),
        (
          'herorow',
          FashHeroRow(
            onCustomize: () => _push(const WidgetsPage()),
            onFeatures: () => _push(const FeaturesPage()),
            onEarn: () => _push(const EarnHubScreen()),
          ),
        ),
        ('routineCards', Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: TrioRail(),
            ),
            const NmHorizontalRoutineCards(fashion: true),
            SizedBox(height: kFashSectionGap),
            const EarthDayFilm(),
            SizedBox(height: kFashSectionGap),
            PromoColorGrid(onOpen: _openGrid),
            SizedBox(height: kFashSectionGap),
            // Up next: coins, progress, profile, tasks — mid-page.
            _progressRail(),
          ],
        )),

        ('coachCards', const SizedBox.shrink()),
        ('mainops', Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MeditationFlipBanner(onTap: () => _go(1), leadingIcons: true, glassIcon: true),
            SizedBox(height: kFashSectionGap),
            FashTiles(onTile: _go, onOpen: _openEnter),
            SizedBox(height: kFashSectionGap),
            // Quick picks: colourful boxes, drifting — mid-page (Ribon, Oct 24).
            const HomeRowHeading('Quick picks', sub: 'Tap a colour to jump in'),
            HeroQuickRow(pool: [for (final c in _quickPool()) if (c.id != 'rewards' && c.id != 'tasks') c], squaresOnly: true, pinned: const {}),
            // 'Start today's practice now' — moved mid-page (Ribon, Oct 24).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ColoredSplitPromoBanner.forSurface(
                SplitPromoSurface.fashionHome,
                onTap: () => _go(1),
                margin: EdgeInsets.zero,
              ),
            ),
            SizedBox(height: kFashSectionGap),
            MainOptionsSection(onGo: _go, onAction: _openMainOption),
          ],
        )),
        (
          'actionbar',
          NmSuppliedActionBar(
            glassmorphism: true,
            onSupport: () => _go(4),
            onCoach: () => _push(const PersonalCoachScreen()),
          ),
        ),
        (
          'catTiles',
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: CategoryTilesSection(),
          ),
        ),
        (
          'spotlight',
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: SpotlightSection(),
          ),
        ),
        (
          'reader',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: ColoredSplitPromoBanner(
                  spec: SplitPromoExtras.at(1, onTap: () => _go(1)),
                  margin: EdgeInsets.zero,
                ),
              ),
              FashReader(onTap: () => _push(const ReaderHubScreen())),
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
        ('streak', Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: BlackGlassBanner(
                margin: EdgeInsets.zero,
                title: 'NowssB Rewards',
                subtitle: 'Your streak, quests and season.',
                mark: NwsbMarks.rewards,
                onTap: () => Programmes.open(context, Programme.rewards, tab: 'streaks'),
              ),
            ),
            FashStreak(onTap: () => _go(1)),
          ],
        )),
        ('tiles', const SizedBox.shrink()),
        // Removed on Ribon's order (Oct 23): Sound That Finds You.
        ('storiesFind', const SizedBox.shrink()),
        ('buddhaGyro', BuddhaGyroStage(
          onOpenQuotes: () => _push(const QuotesWeekScreen()),
        )),
        // Removed on Ribon's order (Oct 23): 'Build a library' banner.
        ('store', const SizedBox.shrink()),
        ('trendwd', FashTrending(onTap: () => _go(2))),
        // "Make this home yours" and "Today's offers" now live in Drop
        // Studio; this card is the one way in.
        ('custom', DropStudioEntry(onTap: () => _push(const DropStudioScreen()))),
        (
          'fashplus',
          FashPlusMini(onTap: () => _push(const FashionPlusScreen()))
        ),
        ('enterCurve', const SizedBox.shrink()),
        ('rx', FashPrescription(onTap: () => _go(1), onWord: _openWord)),
        ('trendvid', FashShopNow(onTap: () => _go(3))),
        ('storeban', Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StoreBannerSection(onTap: () => _go(3)),
            SizedBox(height: kFashSectionGap),
            const EarnUmbrellaSection(),
          ],
        )),
        ('subvid', const SizedBox.shrink()),
        (
          'edition',
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            EditionSection(onTap: () => _push(const SubscriptionScreen())),
            const SizedBox(height: 24),
            const PartnerHomeSection(),
            const SizedBox(height: 24),
            const ProgramTrioRail(),
          ])
        ),
        ('routines', RoutinesSection(onTap: () => _go(1), fashion: true)),
        ('offer', FashOffer(onTap: () => _go(3))),
        // NowssB Coupons: below NowssB Gifts, a contained glass block.
        ('roundring', const SizedBox.shrink()),
        ('cube', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          QuickAccessSection(
            onCart: () => NwsbLinks.cart(context),
            onWishlist: () => NwsbLinks.wishlist(context),
            onOrders: () => _go(4),
          ),
          const SizedBox(height: 24),
          const ReferenceHomeSection(),
        ])),
        ('shabda', FashShabdapathy(onTap: () => _go(2))),
        ('ebooks', EbooksSection(onTap: () => _push(const EbooksStoreScreen()))),
        ('connectban', ConnectBannerSection(onTap: () => NwsbLinks.connect(context))),
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
        ('promovid', const SizedBox.shrink()),
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

    const air = {
      'herorow',
      'reader',
      'storiesFind',
      'store',
      'storeban',
      'connectban',
      'edition',
      'trendwd',
    };
    // Server-driven order (Admin → UI Editor). The hero block is a section
    // of its own; empty rows stay as glue so the spacing is unchanged. With
    // no saved layout this is the bundled order, as is.
    final shown = layoutChildren(
      context,
      'home.fashion',
      [
        LSection(
          'hero',
          'Hero: greeting, curve & rail',
          // The greeting sits ABOVE the deck, not inside it —
          // app/js/part083.js:505 inserts it before the deck
          // in the home; it does not travel with the rail.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HeroGreeting(name: widget.name, onQuickAccess: _openQuickActions),
              HeroQuickRow(pool: _quickPool()),
              FashionHero(
                onExplore: () => _go(2),
                onGuide: () => _push(const FeaturesPage()),
                onSearch: () => showDestinationSearchSheet(
                  context,
                  onSelect: _openSearchDest,
                ),
                onStore: () => _go(3),
                onRail: _go,
              ),
            ],
          ),
          carousel: true,
        ),
        for (final (k, w) in built)
          if (k != 'healing' || Settings.instance.showHealing)
            if (w is SizedBox && w.width == 0 && w.height == 0)
              Padding(
                padding: EdgeInsets.zero,
                child: KeyedSubtree(key: ValueKey('fash-$k'), child: w),
              )
            else
              LSection(
                k,
                kFashionSectionTitles[k] ?? k,
                Padding(
                  padding: EdgeInsets.only(bottom: air.contains(k) ? 26 : kFashSectionGap),
                  child: KeyedSubtree(key: ValueKey('fash-$k'), child: w),
                ),
                carousel: kFashionCarousels.contains(k),
              ),
      ],
      hiddenByDefault: kFashionDefOff,
    );

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
                    onSettings: () => _push(const AppSettingsScreen()),
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
                  itemCount: shown.length,
                  itemBuilder: (context, i) => HomeKeepAlive(child: shown[i]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
