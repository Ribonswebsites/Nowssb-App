import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/day_part.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/data/today_ritual.dart';
import 'package:nowssb/screens/fashion/header.dart';
import 'package:nowssb/screens/normal/sections_top.dart' show nmGreetHello, nmGreetSun, nmGreetMark, NmGreetSubline, nmGreetSublines;
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/template/editable.dart';
import 'package:nowssb/admin/template/slot_keys.dart';
import 'package:nowssb/admin/template/ui_overrides.dart';
import 'package:nowssb/screens/practice.dart' show nwsbSlot;
import 'package:nowssb/widgets/earth_day_film.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A wall-clock time in Nagpur (IST, fixed +05:30), as the app sees it:
/// a local DateTime. [istInstant] is the same moment as a UTC instant.
DateTime ist(int h, int m) => DateTime(2026, 10, 27, h, m);
DateTime istInstant(int h, int m) =>
    DateTime.utc(2026, 10, 27, h, m).subtract(const Duration(hours: 5, minutes: 30));

void main() {
  tearDown(() => DayClock.clock = null);

  group('dayPartFor (IST injected clocks)', () {
    const cases = {
      (1, 22): DayPart.night, // the bug: was "Good Morning"
      (4, 59): DayPart.night,
      (5, 0): DayPart.morning,
      (5, 59): DayPart.morning,
      (6, 0): DayPart.morning,
      (7, 0): DayPart.morning,
      (11, 59): DayPart.morning,
      (12, 0): DayPart.afternoon,
      (13, 0): DayPart.afternoon,
      (16, 59): DayPart.afternoon,
      (17, 0): DayPart.evening,
      (17, 59): DayPart.evening,
      (18, 0): DayPart.evening,
      (18, 30): DayPart.evening,
      (20, 59): DayPart.evening,
      (21, 0): DayPart.night,
      (22, 0): DayPart.night,
      (23, 30): DayPart.night,
    };
    cases.forEach((hm, want) {
      test('${hm.$1.toString().padLeft(2, '0')}:${hm.$2.toString().padLeft(2, '0')} → ${want.name}', () {
        final at = ist(hm.$1, hm.$2);
        expect(dayPartFor(at), want);
        // Every call site agrees.
        expect(nwsbSlot(at), want.slot);
        expect(EarthDayFilm.slot(at), want.slot);
        expect(nmGreetHello(at), want.greeting);
        expect(HeroGreeting.hello(at), 'Good ${want.label.toLowerCase()}');
        expect(nmGreetSun(at), want == DayPart.morning || want == DayPart.afternoon);
        DayClock.clock = () => at;
        expect(DayClock.part, want);
      });
    });

    test('01:22 IST greets Good Night with the moon, not the sun', () {
      expect(nmGreetHello(ist(1, 22)), 'Good Night');
      expect(nmGreetSun(ist(1, 22)), isFalse);
      expect(nmGreetMark(ist(1, 22)), Icons.nightlight_outlined);
    });

    test('UTC instants never leak: read in local time', () {
      final u = istInstant(1, 22); // 19:52 UTC the day before
      expect(u.isUtc, isTrue);
      expect(dayPartFor(u), dayPartFor(u.toLocal()));
      DayClock.clock = () => u;
      expect(DayClock.now().isUtc, isFalse);
      if (DateTime.now().timeZoneOffset == const Duration(hours: 5, minutes: 30)) {
        expect(dayPartFor(u), DayPart.night); // UTC hour 19 would say evening
        expect(nmGreetHello(u), 'Good Night');
      }
    });

    test('labels and order', () {
      expect(DayPart.night.next, DayPart.morning);
      expect(DayPart.morning.ritualTitle, 'Morning Ritual');
      expect(DayPart.night.ritualTitle, 'Night Restoration');
    });
  });

  group('DayClock live', () {
    testWidgets('crosses 11:59 → 12:00 and 20:59 → 21:00 live; one ref-counted timer', (tester) async {
      var t = DateTime(2026, 10, 27, 11, 59, 30);
      DayClock.clock = () => t;
      Widget probe(Key k) => DayPartBuilder(key: k, builder: (_, p, __) => Text(p.greeting, textDirection: TextDirection.ltr));
      await tester.pumpWidget(Column(children: [probe(const Key('a')), probe(const Key('b'))]));
      expect(find.text('Good Morning'), findsNWidgets(2));
      expect(DayClock.running, isTrue);

      t = DateTime(2026, 10, 27, 12);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Good Afternoon'), findsNWidgets(2));

      t = DateTime(2026, 10, 27, 20, 59, 59);
      DayClock.refresh();
      await tester.pump();
      expect(find.text('Good Evening'), findsNWidgets(2));
      t = DateTime(2026, 10, 27, 21);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Good Night'), findsNWidgets(2));

      await tester.pumpWidget(const SizedBox());
      expect(DayClock.running, isFalse);
    });

    testWidgets('refreshes on app resume', (tester) async {
      var t = DateTime(2026, 10, 27, 7);
      DayClock.clock = () => t;
      await tester.pumpWidget(DayPartBuilder(builder: (_, p, __) => Text(p.label, textDirection: TextDirection.ltr)));
      expect(find.text('Morning'), findsOneWidget);
      t = DateTime(2026, 10, 27, 23, 30); // phone slept; no timer has fired
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Night'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('TodayRitual', () {
    late List<Word> library;
    setUpAll(() {
      final raw = jsonDecode(File('assets/content/library.json').readAsStringSync()) as Map;
      library = (raw['items'] as List).map(Word.from).whereType<Word>().toList();
    });
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('uses the shipped library: words for the part plus "any"', () {
      final p = PracticeProgress.instance;
      for (final at in [ist(7, 0), ist(13, 0), ist(18, 30), ist(1, 22), ist(22, 0)]) {
        final r = TodayRitual.from(library: library, progress: p, now: at);
        final part = dayPartFor(at);
        expect(r.part, part);
        expect(r.title, part.ritualTitle);
        expect(r.words.every((w) => w.time == part.slot || w.time == 'any'), isTrue);
        expect(r.total, library.where((w) => w.time == part.slot || w.time == 'any').length);
        expect(r.done, p.completedTodayFor(r.words));
        expect(r.todaySessions, p.todaySessions);
        expect(r.totalSessions, p.totalSessions);
        expect(r.streak, p.streak);
        expect(r.fraction, inInclusiveRange(0, 1));
      }
      expect(TodayRitual.from(library: library, progress: p, now: ist(1, 22)).title, 'Night Restoration');
    });

    testWidgets('model: begin opens the current ritual; see progress; updates on the hour', (tester) async {
      var t = DateTime(2026, 10, 27, 11, 59, 50);
      DayClock.clock = () => t;
      List<Word>? begun;
      String? title;
      var progress = 0;
      final m = TodayRitualModel(
        onBegin: (w, s) {
          begun = w;
          title = s;
        },
        onSeeProgress: () => progress++,
      );
      var changes = 0;
      m.addListener(() => changes++);
      expect(m.value.title, 'Morning Ritual');
      m.begin();
      expect(title, 'Morning Ritual');
      expect(begun, m.value.words);
      m.seeProgress();
      expect(progress, 1);

      t = DateTime(2026, 10, 27, 12);
      await tester.pump(const Duration(seconds: 10));
      expect(changes, greaterThan(0));
      expect(m.value.title, 'Afternoon Session');
      m.begin();
      expect(title, 'Afternoon Session');
      m.dispose();
      expect(DayClock.running, isFalse);
    });
  });

  group('greeting subline', () {
    for (final (h, m, want) in [
      (7, 0, "Ready for today's healing practice?"),
      (13, 0, 'Time for a midday reset?'),
      (18, 30, 'Ready to slow down this evening?'),
      (1, 22, 'Ready to wind down tonight?'),
      (22, 0, 'Ready to wind down tonight?'),
    ]) {
      testWidgets('$h:$m → $want', (tester) async {
        await tester.pumpWidget(MaterialApp(home: NmGreetSubline(at: ist(h, m))));
        expect(find.text(want), findsOneWidget);
        expect(nmGreetSublines[dayPartFor(ist(h, m))], want);
      });
    }

    testWidgets("a user-edited subline is kept at night", (tester) async {
      final preview = EditorPreviewController();
      addTearDown(preview.dispose);
      final k = '${NmGreetSubline.slot}.${slotSlug("Ready for today's healing practice?")}';
      preview.draftOverrides[k] = const UiOverride(slot: NmGreetSubline.slot, type: SlotType.text, text: 'My own words');
      await tester.pumpWidget(MaterialApp(
        home: EditorPreviewScope(controller: preview, child: NmGreetSubline(at: ist(1, 22))),
      ));
      expect(find.text('My own words'), findsOneWidget);
      expect(find.text('Ready to wind down tonight?'), findsNothing);
    });
  });
}
