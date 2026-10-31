// Phone-size shots of every pushed page (top and scrolled to the end), with
// real fonts, for the Oct 31 sweep. Only runs with
// --dart-define=PAGE_SHOTS=<out dir>. Light = Normal skin, dark = Fashion skin.
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
import 'package:nowssb/features/draw/lucky_draw_screen.dart';
import 'package:nowssb/features/earn/earn_hub_screen.dart';
import 'package:nowssb/features/earn/earnings_screen.dart';
import 'package:nowssb/features/economy/coupon_screen.dart';
import 'package:nowssb/features/economy/partner_screen.dart';
import 'package:nowssb/features/economy/reference_screen.dart';
import 'package:nowssb/features/gifts/gifts_screen.dart';
import 'package:nowssb/features/notifications/inbox_screen.dart';
import 'package:nowssb/features/notifications/notif_preferences_screen.dart';
import 'package:nowssb/features/programs/coupons_program.dart';
import 'package:nowssb/features/programs/earn_program.dart';
import 'package:nowssb/features/programs/gifts_program.dart';
import 'package:nowssb/features/programs/partner_program.dart';
import 'package:nowssb/features/programs/reference_program.dart';
import 'package:nowssb/features/programs/rewards_program.dart';
import 'package:nowssb/features/social/connect_screen.dart';
import 'package:nowssb/features/vault/vault_screen.dart';
import 'package:nowssb/screens/app_settings.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:nowssb/screens/features_page.dart';
import 'package:nowssb/screens/library.dart';
import 'package:nowssb/screens/player_settings.dart';
import 'package:nowssb/screens/practice.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:nowssb/screens/progress/progress_screen.dart';
import 'package:nowssb/screens/quick_access.dart';
import 'package:nowssb/screens/reader/reader_hub.dart';
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
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('PAGE_SHOTS');

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 50));
}

final _key = GlobalKey();

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
    'rewards': () => const RewardsProgramPage(),
    'vault': () => const VaultScreen(),
    'draw': () => const LuckyDrawScreen(),
    'coupons': () => const CouponScreen(),
    'coupons_program': () => const CouponsProgramPage(),
    'gifts': () => const GiftsScreen(),
    'gifts_program': () => const GiftsProgramPage(),
    'profile': () => const ProfileScreen(),
    'recent_activity': () => const RecentActivityScreen(),
    'saved_words': () => const SavedWordsScreen(),
    'inbox_journal': () => const InboxScreen(),
    'quick_access': () => const QuickAccessScreen(),
    'connect': () => const ConnectScreen(),
    'practice': () => const PracticeScreen(),
    'library': () => const LibraryScreen(),
    if (words.isNotEmpty)
      'player': () => PracticePlayerScreen(words: words.take(8).toList(), title: 'Evening mix', showIntro: false),
    'sound_library': () => const SoundLibraryScreen(),
    'ebooks': () => const EbooksStoreScreen(),
    'reader_hub': () => const ReaderHubScreen(),
    'earn_hub': () => const EarnHubScreen(),
    'earn_program': () => const EarnProgramPage(),
    'earnings': () => const EarningsScreen(),
    'partner': () => const PartnerScreen(),
    'partner_program': () => const PartnerProgramPage(),
    'reference': () => const ReferenceScreen(),
    'reference_program': () => const ReferenceProgramPage(),
    'progress': () => PracticeProgressScreen(words: words.take(12).toList()),
    'daily_tasks': () => const DailyTasksPage(),
    'features': () => const FeaturesPage(),
  };
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
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
  for (final w in [360.0, 320.0]) {
    for (final skin in ['light', 'dark']) {
      testWidgets('page shots ${w.toInt()} $skin', (t) async {
        t.view.physicalSize = Size(w, 780);
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
        for (final e in _pages().entries) {
          if (only.isNotEmpty && !only.split(',').contains(e.key)) continue;
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
            final tag = '${w.toInt()}_${skin}_${e.key}';
            await _shot(t, '${tag}_top');
            await _toEnd(t);
            await _shot(t, '${tag}_end');
          } catch (x) {
            errs.add('$page: threw $x'.split('\n').first);
          }
          await t.pumpWidget(const SizedBox());
          await _settle(t, 30);
        }
        File('$_out/errors_${w.toInt()}_$skin.txt').writeAsStringSync(errs.toSet().join('\n'));
      }, skip: _out.isEmpty);
    }
  }
}
