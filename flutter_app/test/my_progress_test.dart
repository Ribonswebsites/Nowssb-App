// My progress (Ribon, Nov 23): the CliniQ layout on the progress page, not
// the profile. Real values only, empty states for a new account, the day
// strip / month switcher / hour ruler switch what is shown, sheets close
// on an outside tap, and nothing overflows at 360 or 390.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/progress/my_progress_kit.dart';
import 'package:nowssb/features/progress/progress_center.dart';
import 'package:nowssb/features/progress/progress_popup.dart';
import 'package:nowssb/features/progress/progress_sources.dart';
import 'package:nowssb/features/progress/today_progress_screen.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/test_fonts.dart';

Future<void> _mount(WidgetTester t, {double w = 390, double h = 2600}) async {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: ThemeData(fontFamily: 'DM Sans'),
    home: const Scaffold(backgroundColor: Colors.black, body: SingleChildScrollView(child: TodayProgressBody())),
  ));
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
}

Future<void> _settle(WidgetTester t) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    await loadDmSans();
    await loadMaterialIcons();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProgressCenter.instance.reset();
    DailyCheckIn.instance.debugReset();
    DailyCheckIn.debugClaim = null;
    EconomyMirror.instance.summary = const {};
    ProgressRoutes.goTab = (_, __) {};
    await DailyTasks.publish();
    PracticeProgress.instance.debugSetSessionsForTest({});
    ProgressSources.instance.sync();
  });

  Future<List<String>> practise(WidgetTester t) async {
    await t.runAsync(() => ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {}));
    final lib = ContentStore.instance.library;
    final now = DateTime.now();
    final s = <String, Map<String, dynamic>>{};
    final names = <String>[];
    void add(int daysAgo, int hour, int i, int secs) {
      final d = DateTime(now.year, now.month, now.day - daysAgo, hour, 10);
      final k = dayKey(d);
      s['${k}_${lib[i].word}'] = {'date': k, 'word': lib[i].word, 'completedAt': d.toIso8601String(), 'durationSec': secs};
      names.add(lib[i].word);
    }
    add(1, 9, 1, 300);
    add(0, 7, 0, 240);
    add(40, 8, 2, 120);
    PracticeProgress.instance.debugSetSessionsForTest(s);
    ProgressSources.instance.sync();
    return names;
  }

  testWidgets('new account: empty states and real zeros, nothing from the profile', (t) async {
    await t.runAsync(() => ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {}));
    await _mount(t);
    expect(find.byKey(const ValueKey('today-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-words-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-mind-rows')), findsOneWidget);
    expect(find.byKey(const ValueKey('mind-rhythm')), findsOneWidget);
    expect(find.byKey(const ValueKey('mind-week')), findsOneWidget);
    expect(find.byKey(const ValueKey('mind-strip')), findsOneWidget);
    expect(find.text('Your first word'), findsOneWidget);
    expect(find.textContaining('Practising since'), findsNothing);
    expect(find.text('Practitioner'), findsNothing);
    expect(find.text('0m'), findsOneWidget);
    expect(find.text('0 of 5 goals done'), findsOneWidget);
    // Nothing practised yet, so no earlier month to go back to.
    final prev = t.widget<GestureDetector>(find.byKey(const ValueKey('mp-month-prev')));
    expect(prev.onTap, isNull);
  });

  testWidgets('hero is the word practised last; days, months and hours switch', (t) async {
    final names = await practise(t);
    await _mount(t);
    final title = t.widget<Text>(find.byKey(const ValueKey('mp-hero-title')));
    expect(title.data, wordTitle(names[1]));
    expect(find.byKey(ValueKey('today-word-${ContentStore.instance.library[0].key}')), findsOneWidget);
    // Today's summary, then yesterday's.
    expect((t.widget<Text>(find.byKey(const ValueKey('today-day-summary')))).data, startsWith('Today \u00b7 1 word'));
    final now = DateTime.now();
    final y = DateTime(now.year, now.month, now.day - 1);
    if (y.month == now.month) {
      await t.tap(find.byKey(ValueKey('today-day-${dayKey(y)}')));
      await _settle(t);
      expect((t.widget<Text>(find.byKey(const ValueKey('today-day-summary')))).data, startsWith('Yesterday \u00b7 1 word'));
    }
    // Hour ruler: tap the first quarter → midnight, nothing played.
    final r = t.getTopLeft(find.byKey(const ValueKey('today-tick-scale')));
    await t.tapAt(r + const Offset(2, 30));
    await _settle(t);
    expect((t.widget<Text>(find.byKey(const ValueKey('today-hour-readout')))).data, '12 AM \u2013 1 AM');
    // Swap the hero to the next word.
    await t.tap(find.byKey(const ValueKey('mp-hero-swap')));
    await _settle(t);
    expect(t.widget<Text>(find.byKey(const ValueKey('mp-hero-title'))).data, isNot(wordTitle(names[1])));
    // Back a month and more: lands on the practised day.
    await t.tap(find.byKey(const ValueKey('mp-month-prev')));
    await _settle(t);
    expect(find.byKey(const ValueKey('mp-month-label')), findsOneWidget);
  });

  testWidgets('Details and progress sheets close on an outside tap and on back', (t) async {
    await practise(t);
    await _mount(t, h: 900);
    await t.tap(find.byKey(const ValueKey('today-details')));
    await _settle(t);
    expect(find.byKey(const ValueKey('mp-sheet')), findsOneWidget);
    expect(find.text('You finished it'), findsOneWidget);
    await t.tapAt(const Offset(195, 20));
    await _settle(t);
    expect(find.byKey(const ValueKey('mp-sheet')), findsNothing);
    await t.ensureVisible(find.byKey(const ValueKey('today-goals-info')));
    await t.tap(find.byKey(const ValueKey('today-goals-info')));
    await _settle(t);
    expect(find.byKey(const ValueKey('mp-sheet')), findsOneWidget);
    await t.binding.handlePopRoute();
    await _settle(t);
    expect(find.byKey(const ValueKey('mp-sheet')), findsNothing);
  });

  testWidgets('heart saves the hero word with the player\u2019s liked words', (t) async {
    final names = await practise(t);
    await _mount(t);
    await t.tap(find.byKey(const ValueKey('mp-hero-like')));
    await _settle(t);
    final p = await SharedPreferences.getInstance();
    expect(p.getStringList('nwsb_liked_words'), contains(names[1]));
  });

  for (final w in [360.0, 390.0]) {
    testWidgets('fits at $w wide (no overflow), check-in from the heading', (t) async {
      await practise(t);
      await _mount(t, w: w);
      expect(t.takeException(), isNull);
      await t.tap(find.byKey(const ValueKey('today-action-checkin')));
      await _settle(t);
      expect(find.text('1 of 5 goals done'), findsOneWidget);
      expect(find.byType(ProgressPanel), findsNothing);
    });
  }
}
