/// BD-8: visual proof for the Nykaa dark store home and the raised centre
/// nav button, plus an overflow pass at 320px / text scale 1.3.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/kit/kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/store.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

void main() {
  // These cover the legacy Store screens; the rebuilt ones have store_newui_test.
  setUpAll(() => NewUi.setDebugOverride('store', false));
  tearDownAll(NewUi.resetForTest);

  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.createTempSync('bd8').path);
    await _loadFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  void Function() restore = () {};
  Future<List<String>> pump(
      WidgetTester tester, Widget home, Size size, double scale) async {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final errors = <String>[];
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.library == 'rendering library' ||
          d.exceptionAsString().contains('overflowed')) {
        final m = RegExp(r'lib/[\w/]+\.dart:\d+:\d+').firstMatch(d.toString());
        errors
            .add('${d.exceptionAsString().split('\n').first} @ ${m?.group(0)}');
      }
    };
    restore = () => FlutterError.onError = prev;
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
      builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(
              textScaler: TextScaler.linear(scale), disableAnimations: true),
          child: child!),
      home: home,
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 200));
    }
    // Decode the poster images for real so the golden shows them.
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pump(const Duration(milliseconds: 200));
    return errors;
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 300,
        scrollable: find
            .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down)
            .first);
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('BD-8 store home golden 390x844', (tester) async {
    await pump(tester, const StoreScreen(), const Size(390, 844), 1.0);
    expect(find.text('Spotlight Picks'), findsOneWidget);
    expect(find.text('Shop Now'), findsWidgets);
    expect(find.byKey(const ValueKey('store-tab-Plans')), findsOneWidget);
    // Frame the tabs + Spotlight heading + first banner.
    restore();
    await expectLater(
        find.byType(StoreScreen), matchesGoldenFile('goldens/bd8-store.png'));
  });

  testWidgets('BD-8 nav shell golden 390x844 (raised centre)', (tester) async {
    await pump(tester, const NavShell(), const Size(390, 844), 1.0);
    expect(find.byKey(const ValueKey('nav-raised-centre')), findsOneWidget);
    restore();
    await expectLater(
        find.byType(NavShell), matchesGoldenFile('goldens/bd8-nav.png'));
  },
      // flutter_cache_manager leaves a 10s cleanup timer behind in NavShell;
      // run with BD8_NAV_GOLDEN=1 to regenerate the nav PNG.
      skip: !Platform.environment.containsKey('BD8_NAV_GOLDEN'));

  testWidgets('BD-8 store home: no overflow at 320x568, scale 1.3',
      (tester) async {
    final errors =
        await pump(tester, const StoreScreen(), const Size(320, 568), 1.3);
    final st = tester.state<ScrollableState>(find
        .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down)
        .first);
    for (var g = 0; g < 100; g++) {
      final p = st.position;
      if (p.pixels >= p.maxScrollExtent - 1) break;
      p.jumpTo((p.pixels + 300).clamp(0, p.maxScrollExtent));
      await tester.pump(const Duration(milliseconds: 50));
    }
    restore();
    expect(errors, isEmpty);
  });

  testWidgets('BD-8 nav: no overflow at 320x568, scale 1.3', (tester) async {
    final errors =
        await pump(tester, const NavShell(), const Size(320, 568), 1.3);
    expect(find.byKey(const ValueKey('nav-raised-centre')), findsOneWidget);
    restore();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
    // Only the nav bar itself is in scope (home_normal belongs to UD-2).
    expect(errors.where((e) => e.contains('nav_shell')), isEmpty);
  });
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/box/flutter';
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final roboto = FontLoader('Roboto');
  final icons = FontLoader('MaterialIcons');
  for (final f in dir.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') &&
        n.endsWith('.ttf') &&
        !n.contains('Italic')) {
      roboto.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
    if (n.startsWith('MaterialIcons')) {
      icons.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
  }
  await roboto.load();
  await icons.load();
}
