// Normal-home "YOUR STREAK" card with the written श letter: stills at 0 and
// 5 days, plus animation frames. Writes to /workspace/team-plan/shots/streak4/raw.
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/screens/normal/home_v4.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart' show NormalLoop;
import 'package:nowssb/widgets/concept/r27/streak_marks.dart';
import 'package:nowssb/widgets/concept/r27/streak_marks2.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

const _out = '/workspace/team-plan/shots/streak4/raw';

Map<String, Map<String, dynamic>> _days(int n) {
  final now = DateTime.now();
  final out = <String, Map<String, dynamic>>{};
  for (var i = 0; i < n; i++) {
    final d = DateTime(now.year, now.month, now.day - i);
    final ymd =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    out['${ymd}_Om'] = {
      'date': ymd,
      'word': 'Om',
      'completedAt': d.toIso8601String(),
      'durationSec': 300,
    };
  }
  return out;
}

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(fontFamily: 'DM Sans'),
  home: Builder(
    builder: (c) => MediaQuery(
      data: MediaQuery.of(c).copyWith(
        size: const Size(390, 900),
        textScaler: TextScaler.noScaling,
        disableAnimations: true,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFEDEFF3),
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 390,
            child: SingleChildScrollView(
              child: RepaintBoundary(
                key: const ValueKey('shot'),
                child: ColoredBox(color: const Color(0xFFEDEFF3), child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _shot(WidgetTester t, String name) async {
  final b = t.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot')),
  );
  await t.runAsync(() async {
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    final f = File('$_out/$name.png')..parent.createSync(recursive: true);
    f.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    if (!homeFontsReady) {
      for (final fam in ['DM Sans', 'Roboto']) {
        await (FontLoader(fam)..addFont(
              Future.value(
                ByteData.sublistView(
                  File('assets/fonts/NotoSans-PIE.ttf').readAsBytesSync(),
                ),
              ),
            ))
            .load();
      }
    }
    SharedPreferences.setMockInitialValues({});
    await PracticeProgress.instance.start();
  });

  setUp(() {
    V4Lottie.debugProgress = .35;
    NormalLoop.debugT = .35;
    addTearDown(() {
      V4Lottie.debugProgress = null;
      NormalLoop.debugT = null;
      StreakMarkFrame.debug = null;
      V4Streak.debugMark = null;
    });
  });

  Future<void> sizeView(WidgetTester t) async {
    t.view.physicalSize = const Size(390 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }


  final options = <String, (Widget Function(int, Size), Duration, Duration)>{
    'a-silk': ((s, z) => StreakSilkRibbons(streak: s, size: z), StreakSilkRibbons.intro, StreakSilkRibbons.period),
    'b-tower': ((s, z) => StreakGlassTower(streak: s, size: z), StreakGlassTower.intro, StreakGlassTower.period),
    'c-lotus': ((s, z) => StreakLotusLine(streak: s, size: z), StreakLotusLine.intro, StreakLotusLine.period),
  };
  const frames = bool.fromEnvironment('FRAMES', defaultValue: true);

  for (final e in options.entries) {
    for (final d in [0, 7]) {
      testWidgets('${e.key} at $d days', (t) async {
        await sizeView(t);
        PracticeProgress.instance.debugSetSessionsForTest(_days(d));
        V4Streak.debugMark = e.value.$1;
        StreakMarkFrame.debug = (1, .35);
        await t.pumpWidget(_app(KeyedSubtree(key: ValueKey('s$d'), child: V4Streak(onPractice: () {}, onOffers: () {}))));
        await precacheAll(t);
        await t.pump(const Duration(milliseconds: 50));
        await _shot(t, '${e.key}-${d}d');
        if (frames) {
          final introMs = e.value.$2.inMilliseconds, loopMs = e.value.$3.inMilliseconds;
          const step = 60;
          var i = 0;
          for (var ms = 0; ms < introMs + loopMs; ms += step, i++) {
            StreakMarkFrame.debug = ((ms / introMs).clamp(0.0, 1.0), ((ms - introMs).clamp(0, loopMs) % loopMs) / loopMs);
            if (ms < introMs) StreakMarkFrame.debug = ((ms / introMs).clamp(0.0, 1.0), 0);
            await t.pumpWidget(_app(KeyedSubtree(key: ValueKey(ms), child: V4Streak(onPractice: () {}, onOffers: () {}))));
            await t.pump(const Duration(milliseconds: 16));
            await _shot(t, '${e.key}-${d}d-f${i.toString().padLeft(3, '0')}');
          }
        }
        expect(t.takeException(), isNull);
      });
    }
  }
}
