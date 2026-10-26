// Home Trending 'See all': a text-only header link that opens the poster
// TrendingScreen, while the word taps and 'Open the library' keep working.
// No ellipsis or overflow at 320, 360, 390, 412 and 320@1.3.
// TRENDING_SHOTS=<dir> writes trending-link-{390,320-1.3x}.png and the page it opens.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/features/economy/money.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/poster/poster_pages.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart';
import 'package:nowssb/widgets/concept/normal/trending.dart';
import 'package:nowssb/widgets/concept/stillwater.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _shots = String.fromEnvironment('TRENDING_SHOTS');

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
}

class _Obs extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> r, Route<dynamic>? p) => pushed.add(r);
}

Finder _act(String l) => find.byWidgetPredicate((w) => w is NPress && w.label == l);

final _boundary = GlobalKey();

/// Same wiring as home_normal: words -> log, library -> log, See all -> TrendingScreen.
Future<_Obs> _pump(WidgetTester t, List<String> log, {double w = 390, double ts = 1}) async {
  t.view.physicalSize = Size(w * 2, 844 * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  final obs = _Obs();
  await t.pumpWidget(RepaintBoundary(key: _boundary, child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DM Sans'),
    navigatorObservers: [obs],
    builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(ts), disableAnimations: true), child: child!),
    home: Builder(builder: (c) => Scaffold(body: SingleChildScrollView(child: NTrending(
      words: const ['Om', 'Shanti', 'Prana'],
      onWord: (s) => log.add('word:$s'),
      onLibrary: () => log.add('library'),
      onSeeAll: () => posterPush(c, const TrendingScreen()),
    )))),
  )));
  await t.pump(const Duration(milliseconds: 300));
  obs.pushed.clear();
  return obs;
}

Future<void> _shot(WidgetTester t, String name) async {
  if (_shots.isEmpty) return;
  await t.runAsync(() async {
    final ro = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_shots/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await _font('NotoSansPIE', 'assets/fonts/NotoSans-PIE.ttf');
    await _font('Anton', 'assets/fonts/Anton-Regular.ttf');
    if (_shots.isNotEmpty) Directory(_shots).createSync(recursive: true);
  });
  setUp(() {
    Stillwater.debugPhase = .42;
    Entitlements.instance.debugSet(uid: 'u1');
    FxBook.instance.country = 'IN';
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    Stillwater.debugPhase = null;
    FxBook.instance.country = null;
  });

  testWidgets("'See all' pushes the poster TrendingScreen", (t) async {
    final log = <String>[];
    await t.runAsync(() => ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {}));
    final obs = await _pump(t, log);
    final link = find.byKey(const ValueKey('trending-see-all'));
    expect(find.descendant(of: link, matching: find.text('See all')), findsOneWidget);
    expect(find.descendant(of: link, matching: find.byType(Icon)), findsNothing);
    await _shot(t, 'trending-link-390');
    await t.tap(link);
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(obs.pushed, hasLength(1));
    expect(find.byType(TrendingScreen), findsOneWidget);
    expect(log, isEmpty);
    // the chart lists the real library words
    expect(ContentStore.instance.library, isNotEmpty);
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await t.pump(const Duration(milliseconds: 50));
    }
    await _shot(t, 'trending-link-opens-trendingscreen-390');
  });

  testWidgets('word taps and Open the library still work, and push nothing', (t) async {
    final log = <String>[];
    final obs = await _pump(t, log);
    await t.tap(_act('Open Om').first, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(_act('Open Shanti').first, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Open the library  →'));
    await t.pump(const Duration(milliseconds: 600));
    expect(log, ['word:Om', 'word:Shanti', 'library']);
    expect(obs.pushed, isEmpty);
  });

  testWidgets('no See all link without onSeeAll', (t) async {
    t.view.physicalSize = const Size(780, 1688);
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: NTrending(words: const ['Om'], onWord: (_) {}, onLibrary: () {}))));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('See all'), findsNothing);
  });

  for (final (w, ts) in [(320.0, 1.0), (360.0, 1.0), (390.0, 1.0), (412.0, 1.0), (320.0, 1.3)]) {
    testWidgets('See all fits at $w@$ts: one line, no ellipsis, no overflow', (t) async {
      if (!homeFontsReady) return markTestSkipped('needs the real fonts');
      await _pump(t, <String>[], w: w, ts: ts);
      expect(t.takeException(), isNull);
      final p = t.renderObject<RenderParagraph>(find.text('See all'));
      expect(p.didExceedMaxLines, isFalse);
      expect(p.size.width, greaterThanOrEqualTo(p.getMaxIntrinsicWidth(p.size.height) - .5));
      final title = t.renderObject<RenderParagraph>(find.text('Trending now'));
      expect(title.didExceedMaxLines, isFalse);
      if (w == 320 && ts == 1.3) await _shot(t, 'trending-link-320-1.3x');
    });
  }
}
