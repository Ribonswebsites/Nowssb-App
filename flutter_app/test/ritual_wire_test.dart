/// Ritual card v4 wired to TodayRitualModel + DayClock.
/// Shots: flutter test test/ritual_wire_test.dart --dart-define=RITUAL_OUT=<dir>
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/day_part.dart';
import 'package:nowssb/screens/normal/calm_v3.dart';
import 'package:nowssb/widgets/concept/ritual_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/home_render.dart';

const _out = String.fromEnvironment('RITUAL_OUT');

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (ctx) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              backgroundColor: const Color(0xFFF0F2F7),
              body: ListView(padding: const EdgeInsets.only(top: 18), children: [child]),
            ),
          )),
    );

RitualCard _card(DayPart part, int done,
        {VoidCallback? b, VoidCallback? sp, VoidCallback? rp}) =>
    RitualCard(
      time: ritualTimeOf(part), title: part.ritualTitle, debugPhase: .5,
      completed: done, total: 8, sessionCount: 23, streak: 4,
      onBegin: b ?? () {}, onSeeProgress: sp ?? () {}, onReplay: rp);

Future<void> _size(WidgetTester t, double w, {double h = 900}) async {
  t.view.physicalSize = Size(w * 2, h * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
}

void _noEllipsis(WidgetTester t) {
  for (final e in find.byType(Text).evaluate()) {
    expect((e.widget as Text).overflow, isNot(TextOverflow.ellipsis));
  }
}

/// B022: each title word stays on one line (no letter-by-letter breaks).
void _wordsWhole(WidgetTester t, double scale) {
  final words = find.descendant(of: find.byKey(const ValueKey('ritual-title')), matching: find.byType(Text));
  expect(words, findsWidgets);
  for (final e in words.evaluate()) {
    final rp = t.renderObject<RenderParagraph>(find.byWidget(e.widget));
    expect(rp.size.height, lessThan(26 * scale * 1.1 * 1.5), reason: (e.widget as Text).data);
  }
}

void main() {
  setUpAll(setUpHomeRender);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => DayClock.clock = null);

  testWidgets('hooks: Begin, See progress', (t) async {
    await _size(t, 390);
    var b = 0, sp = 0, rp = 0;
    await t.pumpWidget(_host(_card(DayPart.morning, 3, b: () => b++, sp: () => sp++, rp: () => rp++)));
    await t.tap(find.text('Begin'));
    await t.tap(find.text('See progress'));
    await t.pump(const Duration(milliseconds: 500));
    expect((b, sp, rp), (1, 1, 0));
  });

  testWidgets('hooks: 8/8 Play again → onReplay, falls back to onBegin', (t) async {
    await _size(t, 390);
    var b = 0, rp = 0;
    await t.pumpWidget(_host(_card(DayPart.evening, 8, b: () => b++, rp: () => rp++)));
    expect(find.text('Begin'), findsNothing);
    await t.tap(find.text('Play again'));
    await t.pump(const Duration(milliseconds: 500));
    expect((b, rp), (0, 1));
    await t.pumpWidget(_host(_card(DayPart.evening, 8, b: () => b++)));
    await t.tap(find.text('Play again'));
    await t.pump(const Duration(milliseconds: 500));
    expect(b, 1);
    // 'Ritual complete' is a status, not a button.
    await t.tap(find.text('Ritual complete'));
    await t.pump(const Duration(milliseconds: 500));
    expect((b, rp), (1, 1));
  });

  testWidgets('8/8 lights all 8 beads; 4/8 lights 4', (t) async {
    await _size(t, 390);
    for (final d in [8, 4, 0]) {
      await t.pumpWidget(_host(_card(DayPart.night, d)));
      await t.pump();
      expect(ritualDebugLitBeads, d, reason: '$d/8');
    }
  });

  testWidgets('session line reads "N sessions so far"', (t) async {
    await _size(t, 390);
    await t.pumpWidget(_host(_card(DayPart.evening, 4)));
    expect(find.text('23 sessions so far'), findsOneWidget);
  });

  testWidgets('states: 0/8, 4/8, 8/8', (t) async {
    await _size(t, 390);
    for (final (d, primary, second) in [(0, 'Begin', 'See progress'), (4, 'Begin', 'See progress'), (8, 'Play again', 'Ritual complete')]) {
      await t.pumpWidget(_host(_card(DayPart.afternoon, d)));
      await t.pump();
      expect(find.text(primary), findsOneWidget, reason: '$d/8');
      expect(find.text(second), findsOneWidget, reason: '$d/8');
    }
  });

  testWidgets('home card at 01:00 is night, with the real ritual title; wired to the model', (t) async {
    await _size(t, 390);
    var t0 = DateTime(2026, 10, 27, 1, 0);
    DayClock.clock = () => t0;
    var begun = 0, prog = 0;
    await t.pumpWidget(_host(CalmToday(onStart: (_, __) => begun++, onProgress: () => prog++)));
    await t.pump();
    var card = t.widget<RitualCard>(find.byType(RitualCard));
    expect(card.time, RitualTime.night);
    expect(card.title, 'Night Restoration');
    expect(find.byKey(const ValueKey('cv3-today')), findsOneWidget); // one card, old one gone
    await t.tap(find.text('Begin'));
    await t.tap(find.text('See progress'));
    await t.pump(const Duration(milliseconds: 500));
    expect((begun, prog), (1, 1));
    // hourly tick: 04:59 → 05:00 flips to morning live
    t0 = DateTime(2026, 10, 27, 4, 59, 59);
    DayClock.refresh();
    await t.pump();
    t0 = DateTime(2026, 10, 27, 5);
    await t.pump(const Duration(seconds: 2));
    card = t.widget<RitualCard>(find.byType(RitualCard));
    expect(card.time, RitualTime.morning);
    // resume after sleep → night
    t0 = DateTime(2026, 10, 27, 22);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(t.widget<RitualCard>(find.byType(RitualCard)).time, RitualTime.night);
    await t.pumpWidget(const SizedBox());
  });

  for (final (w, s) in [(320.0, 1.0), (360.0, 1.0), (390.0, 1.0), (412.0, 1.0), (320.0, 1.3)]) {
    testWidgets('no overflow, no ellipsis, whole words @ $w x$s', (t) async {
      if (!homeFontsReady) return; // test font glyphs are far wider than DM Sans
      await _size(t, w);
      for (final part in DayPart.values) {
        for (final d in [0, 4, 8]) {
          await t.pumpWidget(_host(_card(part, d), scale: s));
          await t.pump();
          expect(t.takeException(), isNull, reason: '${part.name} $d/8');
          _noEllipsis(t);
          _wordsWhole(t, s);
        }
      }
    });
  }

  if (_out.isNotEmpty) {
    for (final (name, part, d) in [
      ('morning', DayPart.morning, 3),
      ('night', DayPart.night, 2),
      ('mid', DayPart.evening, 4),
      ('8of8', DayPart.afternoon, 8),
    ]) {
      for (final (w, s, tag) in [(390.0, 1.0, '390'), (320.0, 1.3, '320-1_3x')]) {
        testWidgets('shot $name $tag', (t) async {
          await _size(t, w, h: 640);
          final key = GlobalKey();
          await t.pumpWidget(RepaintBoundary(key: key, child: _host(_card(part, d), scale: s)));
          await precacheAll(t);
          await t.pump(const Duration(milliseconds: 800));
          expect(t.takeException(), isNull);
          _wordsWhole(t, s);
          await t.runAsync(() async {
            final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final img = await ro.toImage(pixelRatio: 2);
            final bd = await img.toByteData(format: ui.ImageByteFormat.png);
            File('$_out/ritual-wire-$name-$tag.png').writeAsBytesSync(bd!.buffer.asUint8List());
          });
        });
      }
    }
  }
}
