/// The Fashion home, section for section.
///
/// This page is thirty registered sections in a fixed order, and the thing
/// that goes wrong with it is not a crash — it is a section that silently
/// stops being placed, or a black bar that stops going anywhere. Neither
/// shows up in `flutter analyze` and neither shows up on the first screen of
/// the app. Both show up here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/parts.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences has no platform in a test — getInstance() never
  // completes and the file hangs rather than failing.
  SharedPreferences.setMockInitialValues({});

  setUpAll(FakeVideoPlatform.new);
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  /// The home, under a NavScope so every section has somewhere to send you.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: NavScope(go: (_) {}, child: const HomeFashion()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  test('the registry is complete', () {
    // REG.fash.items has thirty entries and four of them are defOff, so a
    // fresh install shows twenty-six.
    expect(kFashionSectionOrder, hasLength(30));
    expect(kFashionDefOff, hasLength(4));
    expect(kFashionSectionOrder.toSet(), hasLength(30),
        reason: 'two sections share a key');
    for (final k in kFashionDefOff) {
      expect(kFashionSectionOrder, contains(k),
          reason: '$k is hidden but is not in the order');
    }
    expect(
      kFashionSectionOrder.where((k) => !kFashionDefOff.contains(k)).length,
      26,
    );
  });

  testWidgets('the Fashion home builds at phone size without overflowing',
      (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('it builds the same with motion off', (tester) async {
    // Fashion Plus gates the moving backgrounds. With it off the page is
    // the same page — a section that only lays out when its clip has a
    // decoder is a section that is broken on a cold start too.
    await Settings.instance.setFashionPlus(false);
    await pump(tester);
    expect(tester.takeException(), isNull);
    await Settings.instance.setFashionPlus(true);
  });

  testWidgets('the whole page scrolls end to end', (tester) async {
    await pump(tester);

    // Straight past the footer. ListView.builder only ever builds what is
    // near the viewport, so nothing below the fold is covered by simply
    // pumping the page — every section has to be dragged into view to know
    // it lays out at all.
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull, reason: 'threw on scroll $i');
    }

    // And back to the top, which unmounts everything on the way.
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, 600));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull, reason: 'threw scrolling back');
    }
  });

  testWidgets('every black bar on the Fashion home goes somewhere',
      (tester) async {
    await pump(tester);

    final list = find.byType(Scrollable).first;
    var seen = 0;

    // Checked as the page scrolls rather than once at the top: the bars
    // below the fold have not been built yet at rest, so a single sweep of
    // the tree would only ever inspect the first two or three of them.
    for (var i = 0; i < 40; i++) {
      for (final b in tester.widgetList<SecBanner>(find.byType(SecBanner))) {
        seen++;
        expect(b.onTap, isNotNull,
            reason: '"${b.title}" is a button that goes nowhere');
      }
      for (final c
          in tester.widgetList<NcbCarousel>(find.byType(NcbCarousel))) {
        seen++;
        expect(c.onTap, isNotNull,
            reason: 'a carousel bar that goes nowhere');
      }
      await tester.drag(list, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(seen, greaterThan(0), reason: 'no bars were ever built');
  });

  testWidgets('the pool ceiling holds while the page scrolls', (tester) async {
    await pump(tester);

    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 16));
      expect(VideoPool.instance.liveCount, lessThanOrEqualTo(VideoPool.maxLive),
          reason: 'the decoder ceiling broke at scroll $i — this page is the '
              'whole reason the pool exists');
    }
  });
}
