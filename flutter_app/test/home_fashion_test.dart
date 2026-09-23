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
import 'package:nowssb/widgets/home_parts.dart';
import 'package:nowssb/widgets/nwsb_icon.dart';
import 'package:nowssb/screens/fashion/follow_steps.dart';
import 'package:nowssb/screens/shared_sections.dart';
import 'package:nowssb/widgets/glass_wrap.dart';
import 'package:nowssb/widgets/tv_frame.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences has no platform in a test — getInstance() never
  // completes and the file hangs rather than failing.
  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    FakeVideoPlatform();
    // Deadlines own real Timers; this file runs on a fake clock. See
    // VideoPool.debugDeadlines.
    VideoPool.debugDeadlines = false;
  });
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
    // fresh install shows twenty-six — plus `mainops`, which is this app's
    // own: six doors on one panel, so the app can be used without knowing
    // where anything is.
    expect(kFashionSectionOrder, hasLength(37));
    expect(kFashionDefOff, hasLength(4));
    expect(kFashionSectionOrder.toSet(), hasLength(37),
        reason: 'two sections share a key');
    for (final k in kFashionDefOff) {
      expect(kFashionSectionOrder, contains(k),
          reason: '$k is hidden but is not in the order');
    }
    expect(
      kFashionSectionOrder.where((k) => !kFashionDefOff.contains(k)).length,
      33,
    );
    expect(
      kFashionSectionOrder.indexOf('storiesFind'),
      kFashionSectionOrder.indexOf('tiles') + 1,
    );
    expect(
      kFashionSectionOrder.indexOf('enterCurve'),
      kFashionSectionOrder.indexOf('editorialC') - 1,
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
        expect(c.onTap, isNotNull, reason: 'a carousel bar that goes nowhere');
      }
      await tester.drag(list, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(seen, greaterThan(0), reason: 'no bars were ever built');
  });

  testWidgets('the header and the hero wear the app\'s own marks',
      (tester) async {
    // The whole point of nwsb_icon.dart. Every mark in index.html is a
    // drawn path, and picking the Material glyph that looks nearest is what
    // made the top of this app read as a different app. If someone reaches
    // for Icons.* up here again, this fails.
    await pump(tester);

    final marks = tester.widgetList<NwsbIcon>(find.byType(NwsbIcon));
    expect(marks.length, greaterThanOrEqualTo(4),
        reason: 'the bell, the house, the menu and the greeting orb are all '
            "the app's own paths");

    for (final m in marks) {
      expect(m.body.trim(), startsWith('<'),
          reason: 'a mark must be SVG path data, not a name');
    }
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

  testWidgets('the four tiles are the four in the markup', (tester) async {
    await pump(tester);

    final list = find.byType(Scrollable).first;
    for (var i = 0;
        i < 30 && find.text('Tap to restyle').evaluate().isEmpty;
        i++) {
      await tester.drag(list, const Offset(0, -320));
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.text('Tap to restyle'), findsWidgets);

    // Photo banners are the first card; swipe to the Connect grid.
    await tester.drag(find.text('Tap to restyle').first, const Offset(-280, 0));
    await tester.pumpAndSettle();

    for (final t in [
      'Connect',
      'My Progress',
      'Word Science',
      'My Profile',
    ]) {
      expect(find.text(t), findsWidgets, reason: '$t is not on the home');
    }
    expect(find.text('The Store'), findsNothing,
        reason: 'The Store is not one of the four tiles');
  });

  testWidgets('the offer is one section: head, film, bar', (tester) async {
    await pump(tester);

    final list = find.byType(Scrollable).first;
    for (var i = 0;
        i < 60 && find.byType(EditionSection).evaluate().isEmpty;
        i++) {
      await tester.drag(list, const Offset(0, -320));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(EditionSection), findsOneWidget);
    // ONE of them, not two — this card and the promo were both showing the
    // subscription film a few inches apart.

    // The four subscription tiers are set ON the clip, so they read as part
    // of the picture and not as a separate card above it.
    final tv = tester.getRect(find.descendant(
      of: find.byType(EditionSection),
      matching: find.byType(TvFrame),
    ));
    for (final tier in ['Free', 'Resonance', 'Frequency', 'Frequency X']) {
      final tierRect = tester.getRect(find.text(tier).first);
      expect(tv.contains(tierRect.topLeft), isTrue,
          reason: '$tier belongs inside the TV screen');
    }

    // And the button is OUTSIDE the set, under it.
    final button = tester.getTopLeft(find.descendant(
      of: find.byType(EditionSection),
      matching: find.text('Upgrade Now'),
    ));
    expect(button.dy, greaterThanOrEqualTo(tv.bottom - 1),
        reason: 'the button belongs outside the set');

    // The old poster-promo content is gone from the screen.
    expect(
      find.descendant(
        of: find.byType(EditionSection),
        matching: find.text('Unlock your full healing potential'),
      ),
      findsNothing,
      reason: 'the TV contains the tier rows, not the old promo content',
    );

    // And the promo sits on a pane like every other section.
    expect(
      find.descendant(
        of: find.byType(EditionSection),
        matching: find.byType(GlassWrap),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the six doors are one compact panel', (tester) async {
    await pump(tester);

    final list = find.byType(Scrollable).first;
    for (var i = 0;
        i < 30 && find.byType(MainOptionsSection).evaluate().isEmpty;
        i++) {
      await tester.drag(list, const Offset(0, -320));
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(MainOptionsSection.options, hasLength(6));
    for (final (mark, _, label, tab) in MainOptionsSection.options) {
      expect(mark.trim(), startsWith('<'),
          reason: '$label must be a drawn path, not a glyph');
      expect(tab, inInclusiveRange(0, 4),
          reason: '$label points at a tab that does not exist');
    }

    // Every one of the five tabs is reachable from this panel — that is the
    // whole point of it.
    expect(MainOptionsSection.options.map((o) => o.$4).toSet(), hasLength(5));

    // Tall enough to tap. A 40pt row crushed the marks into the labels;
    // 72pt is a real door on both homes without turning the panel into a
    // page. The head and the bar under it stay the shared furniture.
    expect(MainOptionsSection.rowHeight, 72);
    expect(MainOptionsSection.rowHeight, greaterThanOrEqualTo(68));
    expect(MainOptionsSection.rowHeight, lessThanOrEqualTo(80));
    final panel = tester.getRect(find.byType(MainOptionsSection));
    expect(
        find.descendant(
          of: find.byType(MainOptionsSection),
          matching: find.byType(SecBanner),
        ),
        findsOneWidget);
    expect(MainOptionsSection.rowHeight * 2, greaterThan(120),
        reason: 'two rows must be tall enough to tap');
    expect(panel.height, lessThan(480),
        reason: 'the panel got tall — it is meant to read as one menu');
    expect(tester.takeException(), isNull);
  });

  // ── Follow the steps ────────────────────────────────────────────────
  // The guide is the one thing on this page that REPLACES the rail rather
  // than adding to it, so the failure it can have is a quiet one: the disc
  // does nothing, or it opens onto cards that overflow the deck's fixed
  // height. Neither is visible in analyze and neither crashes.

  testWidgets('the Learn disc runs the guide through the rail', (tester) async {
    await pump(tester);

    // Closed, the rail is the six banners and the strip says LEARN.
    expect(find.text('LEARN'), findsOneWidget);
    expect(find.text('Follow the steps'), findsNothing);

    final disc = find.bySemanticsLabel('How this app works — follow the steps');
    await tester.ensureVisible(disc);
    await tester.pump();
    await tester.tap(disc);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The set's own screen is the first card — not step one.
    expect(find.text('Follow the steps'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('${kFstSteps.length} steps'), findsOneWidget);

    // And the two buttons stand down while it is up.
    expect(find.text('EXPLORE'), findsNothing);
    expect(find.text('APP GUIDE'), findsNothing);
  });

  testWidgets('every step card fits the deck it runs through', (tester) async {
    await pump(tester);
    final disc = find.bySemanticsLabel('How this app works — follow the steps');
    await tester.ensureVisible(disc);
    await tester.pump();
    await tester.tap(disc);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Forward through all fifteen. A card taller than the cell overflows,
    // and an overflow in a test is an exception — which is the point: the
    // deck's height is computed from the hero card, and a step card has to
    // live inside it.
    for (var i = 1; i <= kFstSteps.length; i++) {
      await tester.tap(find.bySemanticsLabel('Next step').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 420));
      expect(find.text('Step $i of ${kFstSteps.length}'), findsOneWidget,
          reason: 'step $i did not arrive');
      expect(find.text(kFstSteps[i - 1].title), findsWidgets);
    }
  });

  testWidgets('the guide gives the rail back', (tester) async {
    await pump(tester);
    final disc = find.bySemanticsLabel('How this app works — follow the steps');
    await tester.ensureVisible(disc);
    await tester.pump();
    await tester.tap(disc);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Follow the steps'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close the steps').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));

    expect(find.text('Follow the steps'), findsNothing);
    expect(find.text('EXPLORE'), findsOneWidget);
    expect(find.text('LEARN'), findsOneWidget);
  });

  testWidgets('every step with a door has a real destination', (tester) async {
    // The web's steps call openSub(); here the door is a tab, and a tab that
    // is not one of the five is a button that goes nowhere.
    for (final s in kFstSteps) {
      expect(s.goLabel == null, s.goTab == null,
          reason: '"${s.title}" has half a door');
      if (s.goTab != null) {
        expect(s.goTab, inInclusiveRange(0, 4),
            reason: '"${s.title}" points at a tab that does not exist');
      }
    }
  });
}
