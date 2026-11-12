// 390-wide shots of the Normal-home "YOUR STREAK" card at 0 days, 4 days,
// and mid-animation frames of the candle flame.
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/screens/normal/home_v4.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart' show NormalLoop;
import 'package:shared_preferences/shared_preferences.dart';

import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

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
      data: MediaQuery.of(c)
          .copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
      child: Scaffold(
        backgroundColor: const Color(0xFFEDEFF3),
        body: SingleChildScrollView(
          child: RepaintBoundary(key: const ValueKey('shot'), child: child),
        ),
      ),
    ),
  ),
);

Future<void> _shot(WidgetTester t, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 50));
  final b = t.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('shot')),
  );
  await t.runAsync(() async {
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    final dir = Directory('/workspace/team-plan/shots/streak')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
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
    addTearDown(() => V4Lottie.debugProgress = null);
  });

  Future<void> sizeView(WidgetTester t) async {
    t.view.physicalSize = const Size(390 * 3, 1400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  testWidgets('streak card at 0 days', (t) async {
    await sizeView(t);
    PracticeProgress.instance.debugSetSessionsForTest({});
    NormalLoop.debugT = .35;
    addTearDown(() => NormalLoop.debugT = null);
    await t.pumpWidget(_app(V4Streak(onPractice: () {}, onOffers: () {})));
    await t.pump();
    await _shot(t, 'card-0');
    expect(find.text('YOUR STREAK'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('streak card at 4 days', (t) async {
    await sizeView(t);
    PracticeProgress.instance.debugSetSessionsForTest(_days(4));
    NormalLoop.debugT = .35;
    addTearDown(() => NormalLoop.debugT = null);
    await t.pumpWidget(_app(V4Streak(onPractice: () {}, onOffers: () {})));
    await t.pump();
    await _shot(t, 'card-4');
    expect(find.text('4'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('streak candle mid-animation frames at 4 days', (t) async {
    await sizeView(t);
    PracticeProgress.instance.debugSetSessionsForTest(_days(4));
    addTearDown(() => NormalLoop.debugT = null);
    const frames = <(double, String)>[
      (0, 'card-4-t00'),
      (.25, 'card-4-t25'),
      (.5, 'card-4-t50'),
      (.75, 'card-4-t75'),
    ];
    for (final (phase, name) in frames) {
      NormalLoop.debugT = phase;
      await t.pumpWidget(
        _app(
          KeyedSubtree(
            key: ValueKey(phase),
            child: V4Streak(onPractice: () {}, onOffers: () {}),
          ),
        ),
      );
      await t.pump();
      await _shot(t, name);
    }
    expect(t.takeException(), isNull);
  });
}
