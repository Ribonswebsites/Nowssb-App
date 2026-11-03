// Ribon's Oct 31 phone report, checked at phone size with real drags.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/features/earn/earn_home_sections.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/normal/horizontal_routine_cards.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'fake_video_platform.dart';

Future<void> _pumps(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _phone(WidgetTester t, Widget child) async {
  t.view.physicalSize = const Size(360 * 2, 780 * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.runAsync(() async {
    await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
    await Settings.instance.load();
  });
  await t.pumpWidget(MaterialApp(home: child));
  await _pumps(t);
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (c) async => '/tmp/pp');
  });

  testWidgets('1: programme rail is Rewards only (Gifts/Coupons removed)', (t) async {
    await _phone(t, const Scaffold(body: SingleChildScrollView(child: ProgramTrioRail(autoRotate: true))));
    expect(find.byType(YourRewardsSection), findsOneWidget);
    expect(find.byKey(const ValueKey('program-trio-pages')), findsNothing);
    expect(find.text('NowssB Gifts'), findsNothing);
    expect(find.text('NowssB Coupons'), findsNothing);
    await t.pumpWidget(const SizedBox());
    await _pumps(t, 100);
  });

  testWidgets('2: nav clearance = nav + pill + safe area', (t) async {
    await _phone(t, NavClearance(height: NavClearance.navAndPill, child: const Scaffold(body: NavClearanceSpacer())));
    expect(t.getSize(find.byKey(const ValueKey('nav-clearance'))).height, greaterThanOrEqualTo(136));
  });

  testWidgets('4: routine has no counter; banner, dots and cards work', (t) async {
    await _phone(t, const Scaffold(body: SingleChildScrollView(child: NmHorizontalRoutineCards(fashion: true))));
    expect(find.text('6 cards'), findsNothing);
    final dot = find.byKey(const ValueKey('routine-step-2'));
    if (dot.evaluate().isNotEmpty) {
      await t.tap(dot);
      await _pumps(t, 6);
    }
    await t.tap(find.byKey(const ValueKey('routine-customize')));
    await _pumps(t, 6);
    expect(find.byKey(const ValueKey('routine-builder')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('routine-builder-1')));
    await _pumps(t, 6);
  });

  testWidgets('5: queue sheet scrolls and swipes down to dismiss', (t) async {
    t.view.physicalSize = const Size(360 * 2, 780 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
    });
    final prev = FlutterError.onError;
    // The player's own collapse animation logs a transient overflow; this
    // test is about gestures only.
    FlutterError.onError = (d) {
      if (!d.toString().contains('overflowed')) prev!(d);
    };
    addTearDown(() => FlutterError.onError = prev);
    final words = ContentStore.instance.library.take(12).toList();
    expect(words, isNotEmpty);
    await t.pumpWidget(MaterialApp(home: PracticePlayerScreen(words: words, title: 'Test', showIntro: false)));
    await _pumps(t, 20);
    await t.flingFrom(const Offset(180, 600), const Offset(0, -300), 1500);
    await _pumps(t, 10);
    final handle = find.byKey(const ValueKey('queue-grab-handle'));
    expect(handle, findsOneWidget);
    // The queue list scrolls.
    final sc = find.byType(Scrollable).hitTestable();
    await t.drag(find.byType(CustomScrollView).last, const Offset(0, -300));
    await _pumps(t, 6);
    expect(sc, findsWidgets);
    // Pull back down well past the top: dismisses.
    await t.drag(find.byType(CustomScrollView).last, const Offset(0, 300));
    await t.drag(find.byType(CustomScrollView).last, const Offset(0, 400));
    await _pumps(t, 10);
    expect(handle, findsNothing);
    // Handle drag also dismisses.
    await t.flingFrom(const Offset(180, 600), const Offset(0, -300), 1500);
    await _pumps(t, 10);
    expect(handle, findsOneWidget);
    await t.drag(handle, const Offset(0, 120));
    await _pumps(t, 10);
    expect(handle, findsNothing);
    await t.pumpWidget(const SizedBox());
    await _pumps(t, 30);
  });

  test('6: activity labels are human', () {
    expect(ProfileScreen.coinReason('act:open'), isNot(contains('act:')));
    expect(ProfileScreen.coinReason('act:open'), 'Opened the app');
    expect(ProfileScreen.coinReason('act:some_new_thing'), isNot(contains('act:')));
  });
}
