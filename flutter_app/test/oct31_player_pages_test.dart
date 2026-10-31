// The two pages the Player opens (Select frequency, Sentence builder) must
// lay out without a RenderFlex overflow on a narrow phone and with large text.
// (320 with large text still overflows inside the shared promo banner —
// colored_split_promo_banner.dart, left as a known item.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/select_level.dart';
import 'package:nowssb/screens/sentence_builder.dart';

import 'fake_video_platform.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  for (final c in <(String, Widget Function())>[
    ('Select frequency', () => const SelectLevelScreen()),
    ('Sentence builder', () => const SentenceBuilderScreen()),
  ]) {
    for (final (w, sc) in [(320.0, 1.0), (390.0, 1.3)]) {
      testWidgets('${c.$1} lays out at $w@$sc without overflow', (t) async {
        t.view.physicalSize = Size(w * 2, 844 * 2);
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        await t.runAsync(() async {
          await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
          await Settings.instance.load();
        });
        final errors = <String>[];
        final prev = FlutterError.onError;
        FlutterError.onError = (d) {
          final s = d.toString();
          if (s.contains('overflowed')) errors.add(s.split('\n').where((l) => l.contains('overflowed') || l.contains('lib/')).take(3).join(' '));
        };
        await t.pumpWidget(MediaQuery(
          data: MediaQueryData(size: Size(w, 844), textScaler: TextScaler.linear(sc)),
          child: MaterialApp(home: c.$2()),
        ));
        for (var i = 0; i < 8; i++) {
          await t.pump(const Duration(milliseconds: 150));
        }
        FlutterError.onError = prev;
        expect(errors, isEmpty);
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 2));
      });
    }
  }
}
