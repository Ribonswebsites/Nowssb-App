// Restyle (Nov 12) before/after shots at 390 wide: top, middle, end.
// flutter test test/restyle_shots_test.dart --dart-define=RESTYLE_SHOTS=<dir> --dart-define=PAGES=practice,profile
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:nowssb/features/coins/coins_screen.dart';
import 'package:nowssb/features/circle/circle_screen.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/economy/economy_theme.dart';
import 'coins_screen_test.dart' as coins_fixture show summary;
import 'lucky_draw_test.dart' as draw_fixture show FakeRepo;
import 'package:nowssb/data/app_control.dart';
import 'package:nowssb/features/draw/lucky_draw_gate.dart';
import 'package:nowssb/features/economy/reward_fx.dart';
import 'package:nowssb/features/economy/reward_overlay.dart';
import 'package:nowssb/widgets/app_backdrop.dart';
import 'package:nowssb/features/draw/lucky_draw_screen.dart';
import 'package:nowssb/features/earn/earnings_screen.dart';
import 'package:nowssb/data/notifications.dart';
import 'package:nowssb/features/notifications/inbox_screen.dart';
import 'package:nowssb/features/notifications/notif_preferences_screen.dart';
import 'package:nowssb/features/notifications/notif_router.dart';
import 'package:nowssb/screens/notifications_sheet.dart';
import 'package:nowssb/features/programs/earn_program.dart';
import 'package:nowssb/features/programs/reference_program.dart';
import 'package:nowssb/features/social/connect_screen.dart';
import 'package:nowssb/screens/app_settings.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:nowssb/screens/library.dart';
import 'package:nowssb/screens/player_settings.dart';
import 'package:nowssb/screens/practice.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:nowssb/screens/quick_access.dart';
import 'package:nowssb/screens/saved_words.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/screens/store.dart';
import 'package:nowssb/screens/store/cart_pages.dart';
import 'package:nowssb/screens/store/ebooks_store.dart';
import 'package:nowssb/screens/subscription.dart';
import 'package:nowssb/screens/word_detail.dart';
import 'package:nowssb/widgets/home_menu_drawer.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('RESTYLE_SHOTS');

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 50));
}

final _key = GlobalKey();

const _rewardItems = <Map<String, dynamic>>[
  {'type': 'coins', 'label': '40 coins'},
  {'type': 'percentOff', 'label': '15% off coupon', 'rarity': 'rare'},
  {'type': 'giftbox', 'label': 'Silver gift box'},
];

Widget _overBackdrop(Widget child) => Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        const AppBackdrop(),
        const ColoredBox(color: Color(0xCC03060C)),
        child,
      ]),
    );

/// Loads the bell feed so the notifications sheet is not empty in shots.
class _LoadNotifs extends StatefulWidget {
  const _LoadNotifs({required this.child});
  final Widget child;
  @override
  State<_LoadNotifs> createState() => _LoadNotifsState();
}

class _LoadNotifsState extends State<_LoadNotifs> {
  @override
  void initState() {
    super.initState();
    NotifStore.instance.load();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

const _drawStatus = <String, dynamic>{
  'drawId': 'd-shot',
  'odds': {'text': 'About 1 in 150 entries wins', 'numerator': 1, 'denominator': 150},
  'closesAt': '2026-11-12T18:29:00Z',
  'resultsAt': '2026-11-12T18:30:00Z',
  'entered': false,
  'open': true,
  'result': null,
  'prizes': [
    {'id': 'g1', 'kind': 'gift', 'title': 'Headphone gift box', 'detail': 'Delivered to your address'},
    {'id': 'c1', 'kind': 'coupon', 'title': '20% off coupon', 'detail': 'Covers part of a price'},
  ],
};

const _drawWinners = <String, dynamic>{
  'winners': [
    {'displayName': 'Asha K.', 'prizeTitle': '20% off coupon', 'wonAt': '2026-11-10T18:30:00Z', 'review': {'text': 'Used it the same day.', 'stars': 5}},
    {'displayName': 'Ravi M.', 'prizeTitle': 'Headphone gift box', 'wonAt': '2026-11-08T18:30:00Z'},
  ],
};

Future<void> _shot(WidgetTester t, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _toFrac(WidgetTester t, double f) async {
  for (final e in find.byType(Scrollable).hitTestable().evaluate()) {
    final s = (e as StatefulElement).state as ScrollableState;
    if (s.axisDirection != AxisDirection.down) continue;
    final p = s.position;
    if (p.maxScrollExtent > 0) p.jumpTo(p.maxScrollExtent * f);
    break;
  }
  await _settle(t, 4);
}

Future<void> _toMid(WidgetTester t) async {
  for (final e in find.byType(Scrollable).hitTestable().evaluate()) {
    final s = (e as StatefulElement).state as ScrollableState;
    if (s.axisDirection != AxisDirection.down) continue;
    final p = s.position;
    if (p.maxScrollExtent > 0) p.jumpTo(p.maxScrollExtent / 2);
    break;
  }
  await _settle(t, 4);
}

Future<void> _toEnd(WidgetTester t) async {
  for (var pass = 0; pass < 3; pass++) {
    for (final e in find.byType(Scrollable).hitTestable().evaluate()) {
      final s = (e as StatefulElement).state as ScrollableState;
      if (s.axisDirection != AxisDirection.down) continue;
      final p = s.position;
      if (p.maxScrollExtent > 0) p.jumpTo(p.maxScrollExtent);
    }
    await _settle(t, 4);
  }
}

Map<String, Widget Function()> _pages() {
  final words = ContentStore.instance.library;
  return {
    'menu': () => Scaffold(body: HomeMenuDrawer(light: false, goTab: (_) {})),
    'settings': () => const AppSettingsScreen(),
    'player_settings': () => const PlayerSettingsScreen(),
    'notif_prefs': () => const NotifPreferencesScreen(),
    'store': () => const StoreScreen(),
    'cart': () => const CartPage(),
    'wishlist': () => const WishlistPage(),
    'subscription': () => const SubscriptionScreen(),
    if (words.isNotEmpty) 'word_detail': () => WordDetail(word: words.first),
    'coins': () => const CoinsScreen(),
    'draw': () => const LuckyDrawScreen(),
    // Lucky draw switched on, with the server shapes from lucky_draw_test.
    'draw_full': () {
      AppControl.instance.flags = const {kLuckyDrawFlag: true};
      return LuckyDrawScreen(repository: draw_fixture.FakeRepo(statusJson: _drawStatus));
    },
    'draw_winners': () {
      AppControl.instance.flags = const {kLuckyDrawFlag: true};
      return LuckyDrawWinnersScreen(repository: draw_fixture.FakeRepo(winnersJson: _drawWinners));
    },
    'profile': () => const ProfileScreen(),
    'recent_activity': () => const RecentActivityScreen(),
    'saved_words': () => const SavedWordsScreen(),
    'inbox_journal': () => const InboxScreen(),
    'latest_update': () => const LatestUpdatePage(),
    'notif_sheet': () => _overBackdrop(const _LoadNotifs(child: NotificationsSheet())),
    'quick_access': () => const QuickAccessScreen(),
    'connect': () => const ConnectScreen(),
    'practice': () => const PracticeScreen(),
    'library': () => const LibraryScreen(),
    if (words.isNotEmpty)
      'player': () => PracticePlayerScreen(words: words.take(8).toList(), title: 'Evening mix', showIntro: false),
    'sound_library': () => const SoundLibraryScreen(),
    'ebooks': () => const EbooksStoreScreen(),
    'earnings': () => const EarningsScreen(),
    'daily_tasks': () => const DailyTasksPage(),
    // Earn hub tabs, drawn as a signed-in member with an empty account so the
    // tab content (not the sign-in card) is on screen.
    'earn': () {
      EconomyMirror.instance.uid = 'shot';
      EconomyMirror.instance.summary = const {'shot': true};
      EconomyApi.debugHandler = (_, __) async => <String, dynamic>{};
      return const CircleScreen();
    },
    // The Coins page exactly as CoinsScreen lays it out, on the server
    // summary fixture from coins_screen_test.dart.
    'coins_full': () => EconomyPage(title: 'Coins', showBalance: false, child: CoinsBody(summary: coins_fixture.summary)),
    // Reward pop-ups over the app backdrop and the dialog barrier.
    'reward_won': () => _overBackdrop(const YouWonCard(title: 'Daily gift', items: [{'type': 'coins', 'label': '20 coins'}])),
    'reward_won_many': () => _overBackdrop(const YouWonCard(title: 'Gift box', rarity: 'epic', items: _rewardItems)),
    'reward_items': () => _overBackdrop(const Center(child: RewardItemsCard(title: 'Your rewards', items: _rewardItems))),
    'reward_box': () => _overBackdrop(const GiftBoxOpening(box: 'gold', title: 'Gold gift box', items: _rewardItems)),
    // Second open: the once-per-run welcome note is gone.
    'earn_hub': () => const CircleScreen(),
    for (final tab in ['overview', 'team', 'sales', 'targets', 'payouts', 'invite', 'academy', 'rules'])
      'earn_$tab': () {
        EconomyMirror.instance.uid = 'shot';
        EconomyMirror.instance.summary = const {'shot': true};
        EconomyApi.debugHandler = (_, __) async => <String, dynamic>{};
        return CircleScreen(initialTab: tab);
      },
  };
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1', 'guide_seen_lucky_draw': true});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    // Families the phone resolves to its system font (Roboto on Android).
    final dir = sdkMaterialFonts;
    if (dir != null) {
      for (final fam in ['SF Pro Display', 'SF Pro Text', 'SF Mono', 'Roboto Mono', 'monospace', 'Georgia']) {
        final l = FontLoader(fam);
        for (final f in Directory(dir).listSync().whereType<File>()) {
          final n = f.uri.pathSegments.last;
          if (n.startsWith('Roboto-') && n.endsWith('.ttf')) {
            l.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
          }
        }
        await l.load();
      }
    }
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (c) async => true);
  });

  const only = String.fromEnvironment('PAGES');
  for (final w in [390.0]) {
    for (final skin in ['dark']) {
      testWidgets('page shots ${w.toInt()} $skin', (t) async {
        t.view.physicalSize = Size(w, const int.fromEnvironment('RESTYLE_H', defaultValue: 844).toDouble());
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.runAsync(() async {
          await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
          await Settings.instance.load();
          await Settings.instance.setFashionHome(skin == 'dark');
        });
        final prev = FlutterError.onError;
        final errs = <String>[];
        var page = '';
        FlutterError.onError = (d) => errs.add('$page: ${d.exceptionAsString().split('\n').first}');
        addTearDown(() => FlutterError.onError = prev);
        // The first page shot registers the google_fonts faces; without a
        // throwaway first shot the first real page renders in the test font.
        final pages = _pages().entries.toList();
        final warm = MapEntry('_warmup', pages.firstWhere((e) => e.key == 'settings').value);
        for (final e in [warm, ...pages]) {
          if (e.key != '_warmup' && only.isNotEmpty && !only.split(',').contains(e.key)) continue;
          page = e.key;
          try {
            await t.pumpWidget(MaterialApp(
                theme: NwsbTheme.light,
                debugShowCheckedModeBanner: false,
                // Same backdrop the app paints behind every route (main.dart).
                builder: (c, child) => RepaintBoundary(
                    key: _key,
                    child: Stack(children: [
                      const Positioned.fill(child: ColoredBox(color: Colors.black)),
                      const Positioned.fill(child: FaintFilm()),
                      child ?? const SizedBox(),
                    ])),
                home: e.value()));
            await _settle(t, 15);
            await t.runAsync(() => Future.delayed(const Duration(milliseconds: 600)));
            await _settle(t, 6);
            // Gift boxes shake three times before they open.
            if (e.key.startsWith('reward_')) await _settle(t, 45);
            final tag = '${w.toInt()}_${skin}_${e.key}';
            await _shot(t, '${e.key}_1top');
            const steps = int.fromEnvironment('RESTYLE_STEPS');
            if (steps > 1) {
              for (var k = 1; k < steps; k++) {
                await _toFrac(t, k / steps);
                await _shot(t, '${e.key}_2mid$k');
              }
            }
            await _toMid(t);
            await _shot(t, '${e.key}_2mid');
            await _toEnd(t);
            await _shot(t, '${e.key}_3end');
            tag.length;
          } catch (x) {
            errs.add('$page: threw $x'.split('\n').first);
          }
          await t.pumpWidget(const SizedBox());
          await _settle(t, 30);
          // Flush leftover cache-manager (or similar) timers so the test
          // does not hang after a page that starts one.
          await t.pump(const Duration(seconds: 11));
        }
        for (final f in Directory(_out).listSync()) {
          if (f.path.contains('/_warmup_')) f.deleteSync();
        }
        File('$_out/errors_${w.toInt()}_$skin.txt').writeAsStringSync(errs.toSet().join('\n'));
      }, skip: _out.isEmpty);
    }
  }
}
