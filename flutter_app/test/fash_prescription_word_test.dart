// The prescription's word pills must report the word's LIBRARY index, not
// its position among the three picks — or the wrong word opens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/day_part.dart';
import 'package:nowssb/screens/fashion/sections_mid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/media/video_pool.dart';

import 'fake_video_platform.dart';

void main() {
  testWidgets('each pill opens the word it shows', (t) async {
    SharedPreferences.setMockInitialValues({});
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await t.runAsync(() => ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {}));
    final all = ContentStore.instance.library;
    expect(all, isNotEmpty);
    final slot = dayPartFor(DateTime.now()).slot;
    final picks = all.where((w) => w.time == slot || w.time == 'any').take(3).toList();
    expect(picks, isNotEmpty);

    final got = <int>[];
    await t.pumpWidget(MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: FashPrescription(onWord: got.add)))));
    await t.pump();
    for (final w in picks) {
      await t.ensureVisible(find.text(w.word).first);
      await t.pump();
      await t.tap(find.text(w.word).first, warnIfMissed: false);
      await t.pump();
    }
    expect(got, hasLength(picks.length));
    for (var i = 0; i < picks.length; i++) {
      expect(all[got[i]].word, picks[i].word);
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(minutes: 1));
  });
}
