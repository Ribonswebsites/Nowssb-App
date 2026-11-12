// How it works pop-up: reel motion, copy, destinations, and no Zen Plus
// card on the normal home.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/app_settings.dart';
import 'package:nowssb/screens/normal/header_actions_sheet.dart';
import 'package:nowssb/widgets/app_destinations.dart';
import 'package:nowssb/widgets/how_it_works_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

Widget _app(Widget child, {double scale = 1, bool reduced = false}) =>
    MaterialApp(
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Builder(
        builder: (c) => MediaQuery(
          data: MediaQuery.of(c).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced,
          ),
          child: Scaffold(
            backgroundColor: const Color(0xFFEDEFF3),
            body: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );

Future<void> _size(WidgetTester t, double w, {double h = 900}) async {
  t.view.physicalSize = Size(w * 3, h * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

bool _isFallbackStyle(TextStyle? s) {
  if (s == null) return false;
  if (s.debugLabel?.contains('fallback style') == true) return true;
  return s.decoration == TextDecoration.underline &&
      s.decorationStyle == TextDecorationStyle.double &&
      s.decorationColor == const Color(0xFFFFFF00);
}

void expectCleanTypography(WidgetTester t) {
  void walk(InlineSpan span, String where) {
    if (span is TextSpan) {
      expect(_isFallbackStyle(span.style), isFalse,
          reason: 'yellow fallback underline on "$where" / "${span.text}"');
      for (final c in span.children ?? const <InlineSpan>[]) {
        walk(c, where);
      }
    }
  }

  for (final e in find.byType(RichText).evaluate()) {
    walk((e.widget as RichText).text, 'RichText');
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await setUpHomeRender();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  testWidgets('five steps, no Fashion or wellness copy', (t) async {
    await _size(t, 390);
    await t.pumpWidget(
        _app(const HowItWorksCard(autoRotate: false), reduced: true));
    await t.pump();
    expect(find.byKey(const ValueKey('how-it-works-reel')), findsOneWidget);
    expect(find.text('A NowssB word'), findsOneWidget);
    expect(find.text("See today's word"), findsOneWidget);
    expect(find.textContaining('Devanagari'), findsOneWidget);
    expect(find.text('HOW IT WORKS'), findsOneWidget);
    expect(find.text('01 / 05'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      expect(find.byKey(ValueKey('how-thumb-$i')), findsOneWidget);
    }
    expectCleanTypography(t);
    for (final banned in [
      'Zen Plus',
      'ZEN PLUS',
      'Fashion',
      'Enter now',
      'Enter Zen Plus',
      'MESH PULSE',
      'NODES LIVE',
      'Golden Breath',
      'Drop Studio',
      'EAR',
      'NECK',
      'JAW',
    ]) {
      expect(find.text(banned), findsNothing, reason: banned);
    }
  });

  testWidgets('thumbs jump to each step', (t) async {
    await _size(t, 390);
    await t.pumpWidget(
        _app(const HowItWorksCard(autoRotate: false), reduced: true));
    await t.pump();
    const titles = [
      'A NowssB word',
      'Parts and hold times',
      'Hear it',
      'Say it and get a score',
      'Streak and level',
    ];
    const ctas = [
      "See today's word",
      'Open the word page',
      'Open the player',
      'Open the player',
      "Today's progress",
    ];
    for (var i = 0; i < 5; i++) {
      await t.tap(find.byKey(ValueKey('how-thumb-$i')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 700));
      expect(find.text(titles[i]), findsOneWidget, reason: titles[i]);
      expect(find.text(ctas[i]), findsOneWidget, reason: ctas[i]);
      expect(find.text('0${i + 1} / 05'), findsOneWidget);
    }
  });

  testWidgets(
      'reel moves every 5 s, holds under a finger, resumes 5 s after it lifts',
      (t) async {
    await _size(t, 390);
    await t.pumpWidget(_app(const HowItWorksCard()));
    expect(find.text('01 / 05'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
    expect(find.text('01 / 05'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 1100));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('02 / 05'), findsOneWidget);
    final g = await t.startGesture(
        t.getCenter(find.byKey(const ValueKey('how-it-works-well'))));
    await t.pump(const Duration(seconds: 8));
    expect(find.text('02 / 05'), findsOneWidget);
    await g.up();
    await t.pump(const Duration(milliseconds: 1));
    await t.pump(const Duration(seconds: 4));
    expect(find.text('02 / 05'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 1100));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('03 / 05'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('how-thumb-0')));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.text('01 / 05'), findsOneWidget);
  });

  testWidgets('reduced motion holds still', (t) async {
    await _size(t, 390);
    await t.pumpWidget(_app(const HowItWorksCard(), reduced: true));
    expect(find.text('01 / 05'), findsOneWidget);
    await t.pump(const Duration(seconds: 8));
    expect(find.text('01 / 05'), findsOneWidget);
  });

  testWidgets('CTA reports the current step', (t) async {
    HowItWorksStep? hit;
    await _size(t, 390);
    await t.pumpWidget(_app(
      HowItWorksCard(autoRotate: false, onCta: (s) => hit = s),
      reduced: true,
    ));
    await t.tap(find.byKey(const ValueKey('how-it-works-cta')));
    await t.pump();
    expect(hit?.cta, "See today's word");
    await t.tap(find.byKey(const ValueKey('how-thumb-4')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 700));
    await t.tap(find.byKey(const ValueKey('how-it-works-cta')));
    await t.pump();
    expect(hit?.cta, "Today's progress");
  });

  for (final (w, s) in const [
    (320.0, 1.0),
    (360.0, 1.0),
    (390.0, 1.0),
    (412.0, 1.0),
    (320.0, 1.3)
  ]) {
    testWidgets('no overflow at $w@$s', (t) async {
      await _size(t, w);
      await t.pumpWidget(_app(const HowItWorksCard(autoRotate: false),
          scale: s, reduced: true));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
    });
  }

  test('menu and settings search can open How it works', () {
    final d = menuDestinations.where((e) => e.id == 'howitworks').single;
    expect(d.title, 'How it works');
    expect(d.action, same(showHowItWorks));
    expect(d.page, isNull);
  });

  testWidgets('showHowItWorks opens the pop-up and close dismisses it',
      (t) async {
    await _size(t, 390, h: 844);
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Scaffold(
        body: Builder(
          builder: (c) => TextButton(
            onPressed: () => showHowItWorks(c),
            child: const Text('Open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('Open'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(HowItWorksCard), findsOneWidget);
    expect(find.text('A NowssB word'), findsOneWidget);
    expectCleanTypography(t);
    await t.tap(find.byKey(const ValueKey('how-it-works-close')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(HowItWorksCard), findsNothing);
  });

  testWidgets('Settings Home row is the switch between homes', (t) async {
    await Settings.instance.setFashionHome(false);
    await _size(t, 390, h: 2000);
    await t.pumpWidget(const MediaQuery(
      data: MediaQueryData(size: Size(390, 2000), disableAnimations: true),
      child: MaterialApp(home: AppSettingsScreen()),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    final useZen = find.text('Tap to use the Zen home');
    await t.ensureVisible(useZen);
    await t.tap(useZen);
    await t.pump();
    expect(Settings.instance.fashionHome, isTrue);
    expect(find.text('Tap to use the Normal home'), findsOneWidget);
    await t.tap(find.text('Tap to use the Normal home'));
    await t.pump();
    expect(Settings.instance.fashionHome, isFalse);
  });

  testWidgets('header actions sheet has no Zen home shortcut', (t) async {
    await _size(t, 390, h: 844);
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: HeaderActionsSheet(
        glassMode: false,
        onGlassToggle: () {},
        onNotifications: () {},
      ),
    ));
    await t.pump();
    expect(find.text('Zen home'), findsNothing);
    expect(find.text('Zen'), findsNothing);
    expect(find.text('Notifications'), findsWidgets);
  });
}
