// Streak mark candidates (A voice stair, B letter श, C line diya) rendered in
// the real Normal-home "YOUR STREAK" card: stills at 0/1/4/7 days and frame
// sequences for GIFs. Writes to /workspace/team-plan/shots/streak2/raw.
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
import 'package:shared_preferences/shared_preferences.dart';

import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

const _out = '/workspace/team-plan/shots/streak2/raw';

Map<String, Map<String, dynamic>> _days(int n) {
  final now = DateTime.now();
  final out = <String, Map<String, dynamic>>{};
  for (var i = 0; i < n; i++) {
    final d = DateTime(now.year, now.month, now.day - i);
    final ymd =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    out['${ymd}_Om'] = {'date': ymd, 'word': 'Om', 'completedAt': d.toIso8601String(), 'durationSec': 300};
  }
  return out;
}

Widget _app(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Builder(
        builder: (c) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
          child: Scaffold(
            backgroundColor: const Color(0xFFEDEFF3),
            body: SingleChildScrollView(child: RepaintBoundary(key: const ValueKey('shot'), child: child)),
          ),
        ),
      ),
    );

Future<void> _shot(WidgetTester t, String name) async {
  final b = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
  await t.runAsync(() async {
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    final f = File('$_out/$name.png')..parent.createSync(recursive: true);
    f.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

final _opts = <String, (Widget Function(int, Size), int, int)>{
  // name: (builder, intro ms, loop ms)
  'a': ((s, z) => StreakVoiceStair(streak: s, size: z), 1100, 2400),
  'b': ((s, z) => StreakLetterSha(streak: s, size: z), 1900, 3200),
  'c': ((s, z) => StreakDiyaLine(streak: s, size: z), 1500, 2800),
};

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    if (!homeFontsReady) {
      for (final fam in ['DM Sans', 'Roboto']) {
        await (FontLoader(fam)
              ..addFont(Future.value(ByteData.sublistView(File('assets/fonts/NotoSans-PIE.ttf').readAsBytesSync()))))
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
      V4Streak.debugMark = null;
      StreakMarkFrame.debug = null;
    });
  });

  Future<void> sizeView(WidgetTester t) async {
    t.view.physicalSize = const Size(390 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  for (final e in _opts.entries) {
    testWidgets('option ${e.key} stills', (t) async {
      await sizeView(t);
      V4Streak.debugMark = e.value.$1;
      for (final d in [0, 1, 4, 7]) {
        PracticeProgress.instance.debugSetSessionsForTest(_days(d));
        StreakMarkFrame.debug = (1, .35);
        await t.pumpWidget(_app(KeyedSubtree(key: ValueKey('s$d'), child: V4Streak(onPractice: () {}, onOffers: () {}))));
        await precacheAll(t);
        await t.pump(const Duration(milliseconds: 50));
        await _shot(t, '${e.key}-d$d');
      }
      expect(t.takeException(), isNull);
    });

    for (final d in [0, 4]) {
      testWidgets('option ${e.key} frames at $d days', (t) async {
        await sizeView(t);
        V4Streak.debugMark = e.value.$1;
        PracticeProgress.instance.debugSetSessionsForTest(_days(d));
        final intro = e.value.$2, loop = e.value.$3;
        final total = intro + loop;
        const step = 50;
        var first = true;
        for (var ms = 0, i = 0; ms < total; ms += step, i++) {
          StreakMarkFrame.debug = ((ms / intro).clamp(0.0, 1.0), (ms % loop) / loop);
          await t.pumpWidget(_app(KeyedSubtree(key: ValueKey(ms), child: V4Streak(onPractice: () {}, onOffers: () {}))));
          if (first) {
            await precacheAll(t);
            first = false;
          }
          await t.pump(const Duration(milliseconds: 16));
          await _shot(t, '${e.key}-d$d-f${i.toString().padLeft(3, '0')}');
        }
        expect(t.takeException(), isNull);
      });
    }
  }
}
