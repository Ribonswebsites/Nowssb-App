// Today's progress in the CliniQ layout (Ribon, Nov 23): real stats, a day
// picker that switches the day shown, the tick ruler, Start session, the
// goal grid with working arrows, the Details sheet closing every way, no
// cut-off text at 360/390 and a tablet layout.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/app_haptics.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/progress/progress_center.dart';
import 'package:nowssb/features/progress/progress_sources.dart';
import 'package:nowssb/features/progress/progress_style.dart';
import 'package:nowssb/features/progress/today_progress_screen.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_fonts.dart';

final _tabs = <int>[];

Future<void> _mount(WidgetTester t, {double w = 390, double h = 2600}) async {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: ThemeData(fontFamily: 'DM Sans'),
    home: const Scaffold(backgroundColor: Colors.black, body: SingleChildScrollView(child: TodayProgressBody())),
  ));
  await t.pump();
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
  await t.pump(const Duration(milliseconds: 300));
}

String _text(WidgetTester t, String key) => (t.widget(find.byKey(ValueKey(key))) as Text).data!;

Map<String, Map<String, dynamic>> _sessions() {
  final now = DateTime.now();
  final today = dayKey(now), y = dayKey(DateTime(now.year, now.month, now.day - 1));
  return {
    '${today}_Prana': {'date': today, 'word': 'Prana', 'completedAt': DateTime(now.year, now.month, now.day, 0, 20).toIso8601String(), 'durationSec': 180},
    '${y}_Shanti': {'date': y, 'word': 'Shanti', 'completedAt': DateTime(now.year, now.month, now.day - 1, 9, 10).toIso8601String(), 'durationSec': 240},
    '${y}_Om': {'date': y, 'word': 'Om', 'completedAt': DateTime(now.year, now.month, now.day - 1, 9, 40).toIso8601String(), 'durationSec': 120},
  };
}

void main() {
  setUpAll(() async {
    await loadDmSans();
    await loadMaterialIcons();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProgressCenter.instance.reset();
    DailyCheckIn.instance.debugReset();
    DailyCheckIn.debugClaim = null;
    final m = EconomyMirror.instance;
    m.loginToday = false;
    m.scratchToday = false;
    m.summary = const {};
    _tabs.clear();
    ProgressRoutes.goTab = (_, i) => _tabs.add(i);
    PracticeProgress.instance.debugSetSessionsForTest({});
    await DailyTasks.publish();
    ProgressSources.instance.sync();
  });

  for (final w in [360.0, 390.0]) {
    testWidgets('new user at ${w.toInt()} wide: empty states, real zeros, nothing cut off', (t) async {
      await _mount(t, w: w);
      expect(t.takeException(), isNull);
      expect(find.byKey(const ValueKey('today-hero')), findsOneWidget);
      expect(find.text('Practitioner'), findsOneWidget);
      expect(find.text('0 of 5 goals done'), findsOneWidget);
      expect(find.byKey(const ValueKey('today-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('today-words-empty')), findsOneWidget);
      expect(_text(t, 'today-day-summary'), 'No practice');
      expect(find.text('0m'), findsOneWidget);
    });
  }

  testWidgets('real stats; the day strip switches the day; the ruler reads an hour', (t) async {
    PracticeProgress.instance.debugSetSessionsForTest(_sessions());
    await _mount(t);
    expect(t.takeException(), isNull);
    expect(find.byKey(const ValueKey('today-empty')), findsNothing);
    expect(find.text('9m'), findsOneWidget, reason: '3 + 4 + 2 minutes');
    expect(_text(t, 'today-day-title'), 'Today');
    expect(_text(t, 'today-day-summary'), '1 word · 3m');
    expect(find.text('Prana'), findsOneWidget);
    final now = DateTime.now();
    final y = DateTime(now.year, now.month, now.day - 1);
    await t.tap(find.byKey(ValueKey('today-day-${dayKey(y)}')));
    await t.pump(const Duration(milliseconds: 300));
    expect(_text(t, 'today-day-title'), 'Yesterday');
    expect(_text(t, 'today-day-summary'), '2 words · 6m');
    expect(find.text('Shanti · Om'), findsOneWidget);
    expect(_text(t, 'today-hour-readout'), contains('9 AM – 10 AM · 2 words, 6m'));
    // Tap the ruler at the very left: midnight hour, nothing yesterday.
    final r = t.getRect(find.byKey(const ValueKey('today-tick-scale')));
    await t.tapAt(Offset(r.left + 2, r.center.dy));
    await t.pump();
    expect(_text(t, 'today-hour-readout'), contains('12 AM – 1 AM · nothing played'));
  });

  testWidgets('goal grid arrows open their places; one card is lit', (t) async {
    await _mount(t);
    await t.tap(find.byKey(const ValueKey('today-arrow-routine')));
    await t.pump(const Duration(milliseconds: 300));
    expect(_tabs, [1]);
    await t.tap(find.byKey(const ValueKey('today-hero-practice')));
    await t.pump(const Duration(milliseconds: 300));
    expect(_tabs, [1, 1]);
  });

  testWidgets('Start session with no words yet goes to the Practice tab', (t) async {
    await _mount(t);
    await t.tap(find.byKey(const ValueKey('today-start-session')));
    await t.pump(const Duration(milliseconds: 300));
    expect(_tabs, [1]);
  });

  testWidgets('Details sheet closes on an outside tap, a swipe down and back', (t) async {
    await _mount(t, h: 900);
    Future<void> open() async {
      await t.tap(find.byKey(const ValueKey('today-details')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('today-details-sheet')), findsOneWidget);
    }

    await open();
    expect(find.text('Words finished'), findsOneWidget);
    await t.tapAt(const Offset(195, 20));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-details-sheet')), findsNothing);

    await open();
    await t.fling(find.byKey(const ValueKey('today-details-sheet')), const Offset(0, 500), 1500);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-details-sheet')), findsNothing);

    await open();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-details-sheet')), findsNothing);
  });

  testWidgets('tablet width: hero beside stats and a 4-across grid, no overflow', (t) async {
    PracticeProgress.instance.debugSetSessionsForTest(_sessions());
    await _mount(t, w: 1024, h: 2000);
    expect(t.takeException(), isNull);
    final hero = t.getRect(find.byKey(const ValueKey('today-hero')));
    final streak = t.getRect(find.byKey(const ValueKey('today-stat-streak')));
    expect(streak.left, greaterThan(hero.right));
    final a = t.getRect(find.byKey(const ValueKey('today-goal-tasks')));
    final b = t.getRect(find.byKey(const ValueKey('today-goal-quest')));
    expect(a.top, b.top, reason: 'all four in one row');
  });

  testWidgets('the ruler drag reads hours without haptics; taps do', (t) async {
    AppHaptics.debugReset();
    AppHaptics.debugEnabled(true);
    addTearDown(AppHaptics.debugReset);
    final calls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'HapticFeedback.vibrate') calls.add('${c.arguments}');
      return null;
    });
    await _mount(t);
    final r = t.getRect(find.byKey(const ValueKey('today-tick-scale')));
    await t.dragFrom(Offset(r.left + 10, r.center.dy), Offset(r.width * 0.6, 0));
    await t.pump();
    final afterDrag = calls.length;
    expect(_text(t, 'today-hour-readout'), isNot(contains('12 AM – 1 AM')), reason: 'the drag moved the handle');
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    await t.tapAt(Offset(r.left + 10, r.center.dy));
    await t.pump();
    expect(afterDrag, 0, reason: 'no haptics while dragging');
    expect(calls, isNotEmpty, reason: 'a tap clicks');
  });
}
