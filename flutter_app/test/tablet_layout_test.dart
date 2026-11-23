// Tablet layout: the frame's sidebar / rail / right panel, and the helpers
// that keep pictures and pop-ups sensible on a wide screen. Phones get none
// of it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/splash.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/shell/tablet_frame.dart';
import 'package:nowssb/shell/tablet_home.dart';
import 'fake_video_platform.dart';

Future<void> _settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<GlobalKey<NavigatorState>> _app(WidgetTester t, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  SplashGate.done.value = true;
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(MaterialApp(
    navigatorKey: nav,
    navigatorObservers: [TabletShellGate.observer],
    builder: (c, child) => TabletFrame(navigatorKey: nav, child: child!),
    home: const NavShell(),
  ));
  await _settle(t, 15);
  final agree = find.text('I Agree · Continue');
  if (agree.evaluate().isNotEmpty) {
    await t.tap(agree.first, warnIfMissed: false);
    await _settle(t, 10);
  }
  for (var i = 0; i < 3 && nav.currentState!.canPop(); i++) {
    nav.currentState!.pop();
    await _settle(t, 4);
  }
  return nav;
}

/// Layout noise from pages rendered without network art: collect it and put
/// the handler back when the test ends.
void _quiet() {
  final prev = FlutterError.onError;
  FlutterError.onError = (_) {};
  addTearDown(() => FlutterError.onError = prev);
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(minutes: 5));
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (c) async => '/tmp/pp');
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    await ContentStore.instance.start();
  });

  test('breakpoints', () {
    expect(tabletWidthFor(390), TabletWidth.phone);
    expect(tabletWidthFor(599), TabletWidth.phone);
    expect(tabletWidthFor(600), TabletWidth.rail);
    expect(tabletWidthFor(839), TabletWidth.rail);
    expect(tabletWidthFor(840), TabletWidth.wide);
  });

  testWidgets('phone: no sidebar, the bottom nav as before', (t) async {
    _quiet();
    await _app(t, const Size(390, 844));
    expect(find.byType(TabletSidebar), findsNothing);
    expect(find.byType(TabletRail), findsNothing);
    expect(find.byKey(const ValueKey('nav-glass')), findsOneWidget);
    await _end(t);
  });

  testWidgets('1280 wide: sidebar, no bottom nav, right panel on Home and Library only', (t) async {
    _quiet();
    final nav = await _app(t, const Size(1280, 800));
    expect(find.byType(TabletSidebar), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-glass')), findsNothing);
    expect(find.byKey(const ValueKey('nav-glass-bar')), findsNothing);
    expect(find.byKey(const ValueKey('home-mode-pill')), findsNothing);
    expect(find.byType(TabletRightPanel), findsOneWidget);
    expect(find.byKey(const ValueKey('tablet-now-playing')), findsOneWidget);
    expect(find.text('Top words'), findsOneWidget);
    // The home is the reference's column: header, hero, playlists, trending.
    expect(find.byType(TabletHome), findsOneWidget);
    expect(find.byKey(const ValueKey('tablet-home-hero')), findsOneWidget);
    expect(find.text('Playlist'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Hi!'), findsOneWidget);
    expect(find.byKey(const ValueKey('tablet-mini-player')), findsOneWidget);

    // Store: no right panel, the centre keeps a reading width.
    await t.tap(find.byKey(const ValueKey('tablet-side-store')));
    await _settle(t, 8);
    expect(TabletShellGate.tab.value, 3);
    expect(find.byType(TabletRightPanel), findsNothing);
    final centre = t.getSize(find.byKey(const ValueKey('tablet-centre')));
    expect(centre.width, lessThanOrEqualTo(TabletBp.page + 0.5));

    await t.tap(find.byKey(const ValueKey('tablet-side-library')));
    await _settle(t, 8);
    expect(find.byType(TabletRightPanel), findsOneWidget);

    // A pushed page keeps the sidebar.
    await t.tap(find.byKey(const ValueKey('tablet-side-settings')));
    await _settle(t, 10);
    expect(nav.currentState!.canPop(), isTrue);
    expect(find.byType(TabletSidebar), findsOneWidget);
    expect(find.byType(TabletRightPanel), findsNothing);
    await _end(t);
  });

  testWidgets('800 wide portrait: nav rail', (t) async {
    _quiet();
    await _app(t, const Size(800, 1280));
    expect(find.byType(TabletRail), findsOneWidget);
    expect(find.byType(TabletSidebar), findsNothing);
    expect(find.byKey(const ValueKey('nav-glass')), findsNothing);
    await t.tap(find.byKey(const ValueKey('tablet-side-practice')));
    await _settle(t, 8);
    expect(TabletShellGate.tab.value, 1);
    await _end(t);
  });

  Widget box(double w, Widget child) => MediaQuery(
        data: MediaQueryData(size: Size(w, 900)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(alignment: Alignment.topLeft, child: SizedBox(width: w, child: child)),
        ),
      );

  testWidgets('TabletAspectRatio: plain AspectRatio on a phone, capped on a tablet', (t) async {
    const k = ValueKey('pic');
    await t.pumpWidget(box(390, const TabletAspectRatio(aspectRatio: 3 / 4, child: SizedBox(key: k))));
    expect(find.byType(AspectRatio), findsOneWidget);
    expect(t.getSize(find.byKey(k)), const Size(390, 520));
    await t.pumpWidget(box(740, const TabletAspectRatio(aspectRatio: 3 / 4, child: SizedBox(key: k))));
    expect(t.getSize(find.byKey(k)), const Size(740, 560));
    await t.pumpWidget(box(740, const TabletAspectRatio(aspectRatio: 16 / 9, child: SizedBox(key: k))));
    expect(t.getSize(find.byKey(k)).height, closeTo(740 * 9 / 16, 0.01));
  });

  testWidgets('TabletSheet: as is on a phone, capped width on a tablet', (t) async {
    const k = ValueKey('sheet');
    await t.pumpWidget(box(390, const SizedBox(height: 600, child: TabletSheet(child: SizedBox.expand(key: k)))));
    expect(t.getSize(find.byKey(k)).width, 390);
    await t.pumpWidget(box(900, const SizedBox(height: 600, child: TabletSheet(child: SizedBox.expand(key: k)))));
    expect(t.getSize(find.byKey(k)), const Size(TabletBp.sheet, 600));
  });
}
