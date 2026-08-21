/// Every screen builds, and the switches actually switch.
///
/// A screen that throws on a phone-sized viewport is the failure that costs
/// the most to find by hand — you have to install a build to see it. These
/// are cheap and they cover the whole surface.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/cart.dart';
import 'package:nowssb/screens/connect.dart';
import 'package:nowssb/screens/fashion_plus.dart';
import 'package:nowssb/screens/healing.dart';
import 'package:nowssb/screens/library.dart';
import 'package:nowssb/screens/login.dart';
import 'package:nowssb/screens/player.dart';
import 'package:nowssb/screens/practice.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:nowssb/screens/routines.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/screens/store.dart';
import 'package:nowssb/screens/subscribe.dart';
import 'package:nowssb/screens/widgets_page.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.setMockInitialValues({});

  setUpAll(FakeVideoPlatform.new);
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump(const Duration(milliseconds: 50));
  }

  final screens = <String, Widget>{
    'Practice': const PracticeScreen(),
    'Library': const LibraryScreen(),
    'Store': const StoreScreen(),
    'Profile': const ProfileScreen(),
    'Sound Library': const SoundLibraryScreen(),
    'Fashion Plus': const FashionPlusScreen(),
    'Settings': const WidgetsPage(),
    'Login': const LoginScreen(),
    'Player': const PlayerScreen(),
    'Routines': const RoutinesScreen(),
    'Connect': const ConnectScreen(),
    'Cart': const CartScreen(kind: CartKind.cart),
    'Subscribe': const SubscribeScreen(),
    'Healing': const HealingScreen(),
  };

  screens.forEach((name, screen) {
    testWidgets('$name builds at phone size without overflowing',
        (tester) async {
      await pump(tester, screen);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the intro gate opens the page underneath it', (tester) async {
    await pump(tester, const SoundLibraryScreen());

    expect(find.text('OPEN LIBRARY'), findsOneWidget);

    await tester.tap(find.text('OPEN LIBRARY'));
    await tester.pump(const Duration(milliseconds: 60));

    expect(tester.takeException(), isNull);
    expect(find.text('OPEN LIBRARY'), findsNothing);
  });

  testWidgets('Fashion Plus really moves the setting', (tester) async {
    await Settings.instance.setFashionPlus(false);
    await pump(tester, const FashionPlusScreen());

    await tester.tap(find.text('ENTER FASHION PLUS'));
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('Motion is off'), findsOneWidget);
    await tester.tap(find.text('Motion is off'));
    await tester.pump(const Duration(milliseconds: 60));

    expect(Settings.instance.fashionPlus, isTrue,
        reason: 'the switch has to change the app, not just itself');
    expect(find.text('Motion is on'), findsOneWidget);

    await Settings.instance.setFashionPlus(false);
  });

  testWidgets('page film always takes a decoder (page backgrounds play)',
      (tester) async {
    // PageShell hard-codes autoplay:true so the film that IS the page always
    // moves — same as the website's .fp-page-vid. Fashion Plus still exists
    // for other motion, but it no longer freezes the page background itself.
    await Settings.instance.setFashionPlus(false);
    await pump(tester, const ProfileScreen());
    await tester.pump(const Duration(milliseconds: 60));

    expect(VideoPool.instance.liveCount, greaterThanOrEqualTo(1),
        reason: 'the page film is always playing, matching the website');
  });
}
