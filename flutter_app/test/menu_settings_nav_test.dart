// Hamburger menu + Settings: every card opens something, Android back
// returns, dialogs cancel cleanly, no exceptions. Firebase is not set up
// (NwsbFirebase.ready == false), so screens must cope without it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/app_settings.dart';
import 'package:nowssb/widgets/home_menu_drawer.dart';
import 'package:nowssb/widgets/routine_deck.dart';
import 'fake_video_platform.dart';

Future<void> _settle(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _reveal(WidgetTester t, Finder f) async {
  for (var i = 0; i < 20 && t.getCenter(f).dy > 900; i++) {
    await t.drag(find.byType(CustomScrollView).first, const Offset(0, -200));
    await t.pump(const Duration(milliseconds: 300));
  }
  for (var i = 0; i < 20 && t.getCenter(f).dy < 120; i++) {
    await t.drag(find.byType(CustomScrollView).first, const Offset(0, 200));
    await t.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (c) async => '/tmp/pp');
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (c) async => true);
    m.setMockMethodCallHandler(SystemChannels.platform, (c) async => null);
  });

  void sizeUp(WidgetTester t) {
    t.view.physicalSize = const Size(460, 1024);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  testWidgets('menu: opens, back closes it', (t) async {
    sizeUp(t);
    await t.pumpWidget(MaterialApp(home: Builder(builder: (c) => Scaffold(
      body: Center(child: TextButton(onPressed: () => showHomeMenuDrawer(c, goTab: (_) {}), child: const Text('open'))),
    ))));
    await t.tap(find.text('open'));
    await _settle(t);
    expect(find.byType(HomeMenuDrawer), findsOneWidget);
    await t.binding.handlePopRoute();
    await _settle(t);
    expect(find.byType(HomeMenuDrawer), findsNothing);
    expect(find.text('open'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('menu: Settings card opens Settings, back returns', (t) async {
    sizeUp(t);
    await t.pumpWidget(MaterialApp(home: Builder(builder: (c) => Scaffold(
      body: Center(child: TextButton(onPressed: () => showHomeMenuDrawer(c, goTab: (_) {}), child: const Text('open'))),
    ))));
    await t.tap(find.text('open'));
    await _settle(t);
    final cards = <WorkCard>[];
    for (var i = 0; i < 12; i++) {
      for (final d in t.widgetList<RoutineDeck>(find.byType(RoutineDeck))) {
        for (final c in d.cards) {
          if (!cards.any((x) => x.title == c.title)) cards.add(c);
        }
      }
      await t.drag(find.byType(ListView).first, const Offset(0, -300));
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(cards.map((c) => c.title), containsAll(['Settings', 'Notifications', 'Activity']));
    cards.firstWhere((c) => c.title == 'Settings').onTap();
    await _settle(t);
    expect(find.byType(AppSettingsScreen), findsOneWidget);
    await t.binding.handlePopRoute();
    await _settle(t);
    expect(find.text('open'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('settings: tabs, rows, dialogs and back all work', (t) async {
    sizeUp(t);
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(navigatorKey: nav, home: const Scaffold(body: Text('root'))));
    nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const AppSettingsScreen()));
    await _settle(t);
    expect(find.text('Settings'), findsWidgets);

    // Tabs switch the list.
    await t.tap(find.text('Account'));
    await _settle(t, 3);
    expect(find.text('Sign Out'), findsWidgets);
    expect(find.text('Privacy Policy'), findsWidgets);
    expect(find.text('Delete Account'), findsWidgets);
    expect(find.text('Terms of Service'), findsWidgets);

    // Sign out asks first; "Stay signed in" keeps you here.
    await _reveal(t, find.text('Sign Out').last);
    await t.tap(find.text('Sign Out').last);
    await _settle(t, 4);
    expect(find.text('Sign out?'), findsOneWidget);
    await t.tap(find.text('Stay signed in'));
    await _settle(t, 4);
    expect(find.text('Sign out?'), findsNothing);

    // Delete asks first; "Keep my account" cancels.
    await _reveal(t, find.text('Delete Account').last);
    await t.tap(find.text('Delete Account').last);
    await _settle(t, 4);
    expect(find.text('Delete your account?'), findsOneWidget);
    await t.tap(find.text('Keep my account'));
    await _settle(t, 4);
    expect(find.text('Delete your account?'), findsNothing);

    // Android back closes a dialog first, then the page.
    await _reveal(t, find.text('About NowssB').last);
    await t.tap(find.text('About NowssB').last);
    await _settle(t, 4);
    expect(find.text('Close'), findsOneWidget);
    await t.binding.handlePopRoute();
    await _settle(t, 4);
    expect(find.text('Close'), findsNothing);

    await _reveal(t, find.text('Look'));
    await t.tap(find.text('Look'));
    await _settle(t, 3);
    expect(find.text('Notifications'), findsWidgets);
    await _reveal(t, find.text('Phone'));
    await t.tap(find.text('Phone'));
    await _settle(t, 3);
    expect(find.text('Keep Screen Awake'), findsWidgets);

    await t.binding.handlePopRoute();
    await _settle(t);
    expect(find.text('root'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
