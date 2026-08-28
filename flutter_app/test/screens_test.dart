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
import 'package:nowssb/screens/fashion_plus.dart';
import 'package:nowssb/screens/library.dart';
import 'package:nowssb/screens/practice.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/screens/store.dart';
import 'package:nowssb/screens/widgets_page.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Settings persist through SharedPreferences, which has no platform in a
  // test — getInstance() never completes and the whole file hangs rather
  // than failing. An in-memory store is the sanctioned stand-in.
  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    FakeVideoPlatform();
    // Deadlines own real Timers; this file runs on a fake clock. See
    // VideoPool.debugDeadlines.
    VideoPool.debugDeadlines = false;
  });
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

    // The intro is in front: its Enter button is showing and the page's own
    // title row is not reachable yet.
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

  testWidgets('motion off means a page never asks for a decoder',
      (tester) async {
    // The whole point of the switch. With it off the background is a still,
    // and a still costs nothing at all — the pool is never even asked.
    await Settings.instance.setFashionPlus(false);
    await pump(tester, const ProfileScreen());
    await tester.pump(const Duration(milliseconds: 60));

    expect(VideoPool.instance.liveCount, 0,
        reason: 'a still background must not hold a decoder');
  });

  testWidgets('Flutter Store exposes the WebView Store departments', (tester) async {
    await pump(tester, const StoreScreen());

    expect(find.text('Word Atelier'), findsOneWidget);
    expect(find.text('Meaning Store'), findsOneWidget);
    expect(find.text('Signature Store'), findsOneWidget);
    expect(find.text('Shabdapathy · Library'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Flutter Store department intros build with foreground artwork', (tester) async {
    for (final screen in <Widget>[
      const WordAtelierScreen(),
      const MeaningStoreScreen(),
      const SignatureStoreScreen(),
      const EbooksStoreScreen(),
    ]) {
      await pump(tester, screen);
      expect(tester.takeException(), isNull);
    }
  });
}
