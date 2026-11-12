// Today's progress (Ribon, Nov 12): the Today button on both homes, every
// box in the Progress pop-up going somewhere real, live counts after an
// action, and the Today's progress page.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/coins/coins_screen.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/progress/progress_center.dart';
import 'package:nowssb/features/progress/progress_popup.dart';
import 'package:nowssb/features/progress/progress_sources.dart';
import 'package:nowssb/features/progress/quests_screen.dart';
import 'package:nowssb/features/progress/today_progress_screen.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:nowssb/screens/fashion/sections_top.dart';
import 'package:nowssb/screens/normal/sections_top.dart';
import 'package:nowssb/widgets/nwsb_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/test_fonts.dart';

final _tabs = <int>[];

Future<void> _mount(WidgetTester t, Widget home, {double h = 900}) async {
  t.view.physicalSize = Size(390, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(theme: ThemeData(fontFamily: 'DM Sans'), home: home));
  await t.pump();
}

Future<void> _openPanel(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('today-progress-button')));
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  expect(find.byType(ProgressPanel), findsOneWidget);
}

String _count(WidgetTester t, String key) => (t.widget(find.byKey(ValueKey(key))) as Text).data!;

Future<void> _settle(WidgetTester t) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
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
    await DailyTasks.publish();
    ProgressSources.instance.sync();
  });

  final home = Scaffold(body: Center(child: Builder(builder: (_) => const TodayProgressButton())));

  testWidgets('normal home greeting shows the Today button, not the old disc', (t) async {
    await _mount(t, const Scaffold(body: NmGreeting(name: 'Healer')));
    expect(find.byType(TodayProgressButton), findsOneWidget);
    expect(find.byType(ProgressIconButton), findsNothing);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('0/5 done'), findsOneWidget);
    await _openPanel(t);
    expect(find.text('0 of 5 today'), findsOneWidget);
  });

  testWidgets('Zen Begin Your Healing Path banner has the button on the right, clear of the speaker', (t) async {
    await _mount(t, const Scaffold(backgroundColor: Colors.black, body: FashGreeting()));
    final btn = find.byType(TodayProgressButton);
    expect(btn, findsOneWidget);
    final speaker = find.byType(NwsbIcon).first;
    final b = t.getRect(btn), s = t.getRect(speaker);
    expect(b.overlaps(s), isFalse);
    expect(b.left, greaterThan(s.right));
    expect(b.right, lessThanOrEqualTo(390 - 16));
    expect(t.takeException(), isNull);
    await _openPanel(t);
  });

  testWidgets('both greetings fit at 320 wide with the button', (t) async {
    t.view.physicalSize = const Size(320, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: const Scaffold(backgroundColor: Colors.black, body: Column(children: [NmGreeting(name: 'Healer'), FashGreeting()])),
    ));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.byType(TodayProgressButton), findsNWidgets(2));
  });

  testWidgets('Daily tasks box opens the tasks page', (t) async {
    await _mount(t, home);
    await _openPanel(t);
    await t.tap(find.byKey(const ValueKey('progress-tile-tasks')));
    await _settle(t);
    expect(find.byType(DailyTasksPage), findsOneWidget);
    expect(find.byType(ProgressPanel), findsNothing, reason: 'the pop-up closes first');
  });

  testWidgets("Today's practice box switches to the Practice tab", (t) async {
    await _mount(t, home);
    await _openPanel(t);
    await t.tap(find.byKey(const ValueKey('progress-tile-routine')));
    await _settle(t);
    expect(_tabs, [1]);
    expect(find.byType(ProgressPanel), findsNothing);
  });

  testWidgets('Daily coins box opens Coins', (t) async {
    await _mount(t, home);
    await _openPanel(t);
    await t.tap(find.byKey(const ValueKey('progress-tile-coins')));
    await _settle(t);
    expect(find.byType(CoinsScreen), findsOneWidget);
  });

  testWidgets('Quest box opens Quests', (t) async {
    await _mount(t, home);
    await _openPanel(t);
    await t.tap(find.byKey(const ValueKey('progress-tile-quest')));
    await _settle(t);
    expect(find.byType(QuestsScreen), findsOneWidget);
  });

  testWidgets('Daily check-in box checks in; the box, header and button update live', (t) async {
    await _mount(t, home);
    expect(find.text('0/5 done'), findsOneWidget);
    await _openPanel(t);
    expect(_count(t, 'progress-count-checkin'), '0/1');
    await t.tap(find.byKey(const ValueKey('progress-tile-checkin')));
    await _settle(t);
    expect(find.byType(ProgressPanel), findsOneWidget, reason: 'check-in happens in place');
    expect(_count(t, 'progress-count-checkin'), '1/1');
    expect(find.text('1 of 5 today'), findsOneWidget);
    expect(find.text('1/5 done'), findsOneWidget);
    expect(find.text('Checked in for today'), findsOneWidget);
    // Kept for the day: a fresh read still says checked in.
    DailyCheckIn.instance.debugReset();
    await t.runAsync(() => DailyCheckIn.instance.load());
    expect(DailyCheckIn.instance.doneToday, isTrue);
  });

  testWidgets('signed in, check-in also claims the login coins', (t) async {
    var claims = 0;
    DailyCheckIn.debugClaim = () async {
      claims++;
      EconomyMirror.instance.loginToday = true;
      return 5;
    };
    await _mount(t, home);
    await _openPanel(t);
    await t.tap(find.byKey(const ValueKey('progress-tile-checkin')));
    await _settle(t);
    expect(claims, 1);
    expect(_count(t, 'progress-count-checkin'), '1/1');
    expect(_count(t, 'progress-count-coins'), '1/2');
    expect(find.text('Checked in · +5 coins'), findsOneWidget);
  });

  testWidgets('counts follow the real stores: tasks, quest ledger, scratch', (t) async {
    await _mount(t, home);
    await _openPanel(t);
    expect(_count(t, 'progress-count-tasks'), '0/3');
    await t.runAsync(() => DailyTasks.setDone('word', true));
    await t.pump();
    expect(_count(t, 'progress-count-tasks'), '1/3');
    EconomyMirror.instance.summary = {
      'recentCoins': [
        {'delta': 25, 'reason': 'quest:practice5', 'at': DateTime.now().millisecondsSinceEpoch},
      ],
    };
    EconomyMirror.instance.scratchToday = true;
    ProgressSources.instance.sync();
    await t.pump();
    expect(_count(t, 'progress-count-quest'), '1/1');
    expect(_count(t, 'progress-count-coins'), '1/2');
    expect(find.text('1 of 5 today'), findsOneWidget);
  });

  test('a quest claimed yesterday does not count today', () {
    final y = DateTime.now().subtract(const Duration(days: 1, hours: 1)).millisecondsSinceEpoch;
    expect(questClaimedToday({'recentCoins': [{'reason': 'quest:x', 'at': y}]}), isFalse);
    expect(questClaimedToday({'recentCoins': [{'reason': 'daily-login', 'at': DateTime.now().millisecondsSinceEpoch}]}), isFalse);
  });

  test('first reading of a day is quiet; a later step into complete pops up', () {
    final c = ProgressCenter(clock: () => DateTime(2026, 11, 12, 10));
    c.sync(ProgressKind.checkin, 1, 1);
    expect(c.popup.value, isNull);
    c.sync(ProgressKind.tasks, 2, 3);
    c.sync(ProgressKind.tasks, 3, 3);
    expect(c.popup.value?.kind, ProgressKind.tasks);
  });

  testWidgets('View all opens Today\u2019s progress; every card and button works', (t) async {
    await _mount(t, home, h: 1400);
    await _openPanel(t);
    await t.tap(find.byKey(const ValueKey('progress-view-all')));
    await _settle(t);
    expect(find.byType(TodayProgressScreen), findsOneWidget);
    expect(find.text('0 of 5 goals done'), findsOneWidget);
    for (final k in ProgressKind.values) {
      expect(find.byKey(ValueKey('today-goal-${k.name}')), findsOneWidget);
    }
    // Check in from the page.
    await t.tap(find.byKey(const ValueKey('today-action-checkin')));
    await _settle(t);
    expect(_count(t, 'today-count-checkin'), '1/1');
    expect(find.text('1 of 5 goals done'), findsOneWidget);
    // Practice card → Practice tab.
    await t.tap(find.byKey(const ValueKey('today-goal-routine')));
    await _settle(t);
    expect(_tabs, [1]);
    // Tasks card → tasks page, tick one, back: count moved.
    await t.ensureVisible(find.byKey(const ValueKey('today-goal-tasks')));
    await t.tap(find.byKey(const ValueKey('today-goal-tasks')));
    await _settle(t);
    expect(find.byType(DailyTasksPage), findsOneWidget);
    await t.runAsync(() => DailyTasks.setDone('player', true));
    t.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(t);
    expect(_count(t, 'today-count-tasks'), '1/3');
    // Quest card → Quests.
    await t.ensureVisible(find.byKey(const ValueKey('today-goal-quest')));
    await t.tap(find.byKey(const ValueKey('today-goal-quest')));
    await _settle(t);
    expect(find.byType(QuestsScreen), findsOneWidget);
    t.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(t);
    // Coins card → Coins.
    await t.ensureVisible(find.byKey(const ValueKey('today-goal-coins')));
    await t.tap(find.byKey(const ValueKey('today-goal-coins')));
    await _settle(t);
    expect(find.byType(CoinsScreen), findsOneWidget);
  });

  testWidgets('Quests list real quests and only finished ones can be claimed', (t) async {
    await _mount(t, const Scaffold(backgroundColor: Colors.black, body: SingleChildScrollView(child: QuestsBody(signedIn: true, summary: {
      'quests': {
        'starter': [
          {'id': 'practice5', 'title': 'Practise 5 times', 'goal': 5, 'coins': 25, 'value': 5, 'claimed': false},
          {'id': 'listen1', 'title': 'Open the player', 'goal': 1, 'coins': 10, 'value': 1, 'claimed': true},
        ],
        'weekly': [
          {'id': 'w_minutes', 'title': 'Spend 60 minutes', 'goal': 60, 'coins': 40, 'value': 12, 'claimed': false},
        ],
      },
    }))), h: 1200);
    expect(find.text('Practise 5 times'), findsOneWidget);
    expect(find.text('12 of 60 · +40 coins'), findsOneWidget);
    expect(find.text('Claimed'), findsOneWidget);
    final ready = t.widget<TextButton>(find.descendant(of: find.byKey(const ValueKey('quest-claim-practice5')), matching: find.byType(TextButton)));
    expect(ready.onPressed, isNotNull);
    expect(find.byKey(const ValueKey('quest-claim-w_minutes')), findsNothing);
    expect(find.text('48 to go'), findsOneWidget);
  });
}
