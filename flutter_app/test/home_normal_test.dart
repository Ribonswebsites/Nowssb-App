/// The Normal home, section for section.
///
/// The twin of test/home_fashion_test.dart, and for the same reason: what
/// goes wrong with a registry-ordered page is not a crash, it is a section
/// that silently stops being placed or a bar that stops going anywhere.
///
/// This page has one extra thing to check that the Fashion home does not.
/// Four of its registry rows have NO markup behind them on this home — the
/// website took them out and left the rows standing — and that is easy to
/// mistake for sections I forgot to build. The list of them is a constant,
/// and the page asserts against it, so the day one of them comes back the
/// note at the head of home_normal.dart has to come back with it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/glass_wrap.dart';
import 'package:nowssb/widgets/home_parts.dart';
import 'package:nowssb/widgets/neu_wrap.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    FakeVideoPlatform();
    // Deadlines own real Timers; this file runs on a fake clock. See
    // VideoPool.debugDeadlines.
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: NavScope(go: (_) {}, child: const HomeNormal()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  test('the registry is complete', () {
    expect(kNormalSectionOrder, hasLength(32));
    expect(kNormalSectionOrder.toSet(), hasLength(32),
        reason: 'two sections share a key');
    expect(kNormalSectionOrder.indexOf('dashboard'),
        kNormalSectionOrder.indexOf('search') + 1,
        reason: 'the supplied dashboard must sit directly below search');
    expect(kNormalSectionOrder.indexOf('essentials'),
        kNormalSectionOrder.indexOf('dashboard') + 1,
        reason: 'the supplied essentials must sit directly below the dashboard');

    for (final k in {...kNormalNoMarkup, ...kNormalDefOff}) {
      expect(kNormalSectionOrder, contains(k),
          reason: '$k is listed as absent but is not in the order');
    }

    // Three rows with no markup, two hidden by default — so a fresh install
    // shows twenty-five.
    //
    // It was twenty-three. `storeban` has left the no-markup set: this home
    // registers it (app/js/part062.js:82) and never had an element for it,
    // so the store banner is a real section here now rather than a bare clip
    // dropped above the store card.
    final shown = kNormalSectionOrder
        .where((k) => !kNormalNoMarkup.contains(k))
        .where((k) => !kNormalDefOff.contains(k))
        .length;
    expect(shown, 27);
  });

  testWidgets('the Normal home builds at phone size without overflowing',
      (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the whole page scrolls end to end', (tester) async {
    await pump(tester);

    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull, reason: 'threw on scroll $i');
    }
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, 600));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull, reason: 'threw scrolling back');
    }
  });

  testWidgets('every black bar on the Normal home goes somewhere',
      (tester) async {
    await pump(tester);

    final list = find.byType(Scrollable).first;
    var seen = 0;

    for (var i = 0; i < 40; i++) {
      for (final b in tester.widgetList<SecBanner>(find.byType(SecBanner))) {
        seen++;
        expect(b.onTap, isNotNull,
            reason: '"${b.title}" is a button that goes nowhere');
      }
      for (final c
          in tester.widgetList<NcbCarousel>(find.byType(NcbCarousel))) {
        seen++;
        expect(c.onTap, isNotNull, reason: 'a carousel bar that goes nowhere');
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
          reason: 'the decoder ceiling broke at scroll $i');
    }
  });

  testWidgets('a shared section wears each home\'s own language',
      (tester) async {
    // The nine shared sections are one set of widgets on two homes, and the
    // thing that would make that a mistake is if they came out looking the
    // same on both. They do not: the pane is a raised card here and a pane
    // of glass there, and this is what proves the scope is reaching them.
    await pump(tester);

    // Scrolled to, not assumed at the top: the streak card lost its head
    // (its own heading was saying the same thing underneath it) and the
    // streak banner moved down the page, so the first screen carries none.
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 40 && find.byType(WrapHead).evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 16));
    }

    final head = tester.widgetList<WrapHead>(find.byType(WrapHead));
    expect(head, isNotEmpty,
        reason: 'the Normal home should use the neumorphic head');
    expect(find.byType(SectionHead), findsNothing,
        reason: 'the glass head has no business on the pale home');
  });
}
