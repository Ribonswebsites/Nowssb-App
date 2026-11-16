// The seven week-day tiles fit a 320dp screen at text x1.3 without overflowing.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

// Profile sets SF Pro Display and Roboto Mono. The test font (Ahem) draws
// every glyph as a full square, so load real faces where the box has them.
const _g = '/usr/share/fonts/truetype/sand-box/google';
const _faces = {
  '$_g/DM Sans/DMSans-VariableFont_opsz,wght.ttf': ['SF Pro Display', 'Roboto'],
  '$_g/Roboto Mono/RobotoMono-VariableFont_wght.ttf': ['Roboto Mono'],
};

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void _seedToday() {
  final key = _day(DateTime.now());
  PracticeProgress.instance.debugSetSessionsForTest({
    '${key}_SOMA': {
      'date': key,
      'word': 'SOMA',
      'completedAt': '${key}T12:00:00.000',
      'source': 'test',
    },
  });
}

void main() {
  final haveFonts = _faces.keys.every((f) => File(f).existsSync());
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    if (!haveFonts) return;
    for (final e in _faces.entries) {
      final b = ByteData.sublistView(File(e.key).readAsBytesSync());
      for (final f in e.value) {
        await (FontLoader(f)..addFont(Future.value(b))).load();
      }
    }
    await PracticeProgress.instance.start();
  });

  setUp(_seedToday);

  for (final (w, scale) in [(390.0, 1.0), (320.0, 1.3)]) {
    testWidgets('week tiles fit at ${w.toInt()} x$scale', (t) async {
      if (!haveFonts) return markTestSkipped('Profile fonts not installed');
      FakeVideoPlatform();
      VideoPool.debugDeadlines = false;
      t.view.physicalSize = Size(w * 3, 3600 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.exceptionAsString());
      await t.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
              size: Size(w, 3600), textScaler: TextScaler.linear(scale)),
          child: const ProfileScreen(),
        ),
      ));
      await t.pump(const Duration(milliseconds: 500));
      FlutterError.onError = prev;
      expect(
          find.byKey(const ValueKey('profile-week-tracker')), findsOneWidget);
      final tiles = find.byWidgetPredicate(
        (x) =>
            x.key is ValueKey<String> &&
            (x.key as ValueKey<String>).value.startsWith('profile-week-day-'),
      );
      expect(tiles, findsNWidgets(7));
      expect(errors.where((e) => e.contains('overflowed')), isEmpty);
      for (final e in tiles.evaluate()) {
        final r = t.getRect(find.byWidget(e.widget));
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(w));
        expect((r.width - r.height).abs(), lessThan(1.0),
            reason: 'day tiles stay square');
        final box = e.widget as AnimatedContainer;
        expect(box.decoration, isA<BoxDecoration>());
        expect((box.decoration as BoxDecoration).shape, BoxShape.rectangle);
        expect((box.decoration as BoxDecoration).borderRadius, isNotNull);
      }
      // Today's practiced day carries a gold check.
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 1));
    });
  }
}
