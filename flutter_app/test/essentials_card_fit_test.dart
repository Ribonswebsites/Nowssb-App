// The rotating 'Your essentials' step card must fit its text on every day:
// the info line carries the word of the day ('The meaning of Aarogya'), so a
// fixed page height overflowed on some days (Nov 18 CI). This walks a fixed
// clock through a whole word-of-the-day cycle, plus a long admin word, at
// 360-412 wide and text scale 1.0 / 1.3, done and to-do.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/home_widget_sync.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:nowssb/screens/normal/neomorphic_essentials.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

String _cap(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

/// Same strings as NmSuppliedEssentials._info for the day's word.
String Function(String) _infoFor(String name) => (id) => switch (id) {
      'word' => name.isEmpty ? 'Any word you like' : "Today's word · $name",
      'player' => name.isEmpty ? 'Press play on any word' : 'Press play on $name',
      'read' => name.isEmpty ? "Open any word's meaning" : 'The meaning of $name',
      _ => 'Tick it off when it is done',
    };

List<DailyTaskView> _tasks(bool done) => [
      for (final t in DailyTasks.items.value)
        DailyTaskView(t.id, t.title, t.mark, done),
      DailyTaskView('t1', 'Ten slow breaths before the evening walk',
          'moon', done),
    ];

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  final raw = jsonDecode(File('assets/content/library.json').readAsStringSync());
  final library = [
    for (final e in (raw['items'] as List)) Word.from(e),
  ].whereType<Word>().toList();
  // A fixed clock over one full cycle of the word of the day.
  final start = DateTime(2026, 1, 1, 7, 30);
  final names = <String>{
    '',
    for (var d = 0; d < library.length + 1; d++)
      _cap(HomeWidgetSync.wordFor(start.add(Duration(days: d)), library)
              ?.word ??
          ''),
    'Swasthyavardhini', // a long admin-published word
  };

  for (final w in [360.0, 390.0, 412.0]) {
    for (final s in [1.0, 1.3]) {
      testWidgets('step card fits every day at ${w.toInt()} @ $s',
          (t) async {
        t.view.physicalSize = Size(w * 3, 1200 * 3);
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        expect(library, isNotEmpty);
        for (final name in names) {
          for (final done in [false, true]) {
            await t.pumpWidget(const SizedBox());
            await t.pumpWidget(MaterialApp(
              theme: NwsbTheme.light.copyWith(
                  textTheme: NwsbTheme.light.textTheme
                      .apply(fontFamily: 'DM Sans')),
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(s)),
                child: child!,
              ),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    EssentialsCarousel(
                      tasks: _tasks(done),
                      infoFor: _infoFor(name),
                      iconFor: (_) => Icons.task_alt_outlined,
                      onOpen: (_) {},
                    ),
                  ]),
                ),
              ),
            ));
            await t.pump(const Duration(milliseconds: 50));
            expect(t.takeException(), isNull,
                reason: '"$name" done=$done at ${w.toInt()} @ $s');
            // Swipe through every card so each one lays out.
            for (var i = 0; i < _tasks(done).length; i++) {
              await t.drag(find.byType(PageView), Offset(-w, 0));
              await t.pump(const Duration(milliseconds: 600));
              expect(t.takeException(), isNull,
                  reason: '"$name" card $i done=$done at ${w.toInt()} @ $s');
            }
          }
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 30));
      });
    }
  }
}
