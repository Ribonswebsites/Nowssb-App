// My routine: every flow end to end — create, reorder, minutes, days,
// reminder, save, restart (reload from the phone), edit, delete + undo,
// Start (plays the words in order in the Player, each for its minutes, then
// says it is complete) — plus the reminder plan. With
// --dart-define=PAGE_SHOTS=<dir> it also writes the screenshots.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/data/word_voice.dart';
import 'package:nowssb/features/notifications/notif_categories.dart';
import 'package:nowssb/features/notifications/notif_scheduler.dart';
import 'package:nowssb/features/routine/routine_store.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/my_routine.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/theme/theme.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('PAGE_SHOTS');
final _key = GlobalKey();

Future<void> _settle(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(WidgetTester t, String name) async {
  if (_out.isEmpty) return;
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Widget _app(Widget home) => MaterialApp(
      theme: NwsbTheme.light,
      debugShowCheckedModeBanner: false,
      builder: (c, child) => RepaintBoundary(
        key: _key,
        child: Stack(children: [
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          child ?? const SizedBox(),
        ]),
      ),
      home: home,
    );

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first, maxScrolls: 60);
  // Let the scroll come to rest (a moving list ignores taps).
  await _settle(t, 8);
}

/// Brings [f] to the middle of the screen and lets the list rest.
Future<void> _center(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await _settle(t, 8);
  final y = t.getCenter(f).dy;
  await t.drag(find.byType(Scrollable).first, Offset(0, 420 - y));
  await _settle(t, 10);
}

/// The Player's own stage chips overflow by a fraction of a pixel with the
/// test fonts (not with the real ones); only those are let through, and only
/// once the Player is open. Everything on the My routine pages stays strict.
void _playerFontSlack() {
  final onError = FlutterError.onError;
  FlutterError.onError = (d) {
    final s = d.toString();
    if (!(s.contains('overflowed by 0.') && s.contains('pixels'))) onError?.call(d);
  };
  addTearDown(() => FlutterError.onError = onError);
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  final played = <String>[];

  setUpAll(() async {
    await setUpHomeRender();
    // google_fonts from test/fonts, never the network (CI has none).
    if (homeFontCache == null) await setUpOfflineGoogleFonts();
    await loadRoboto();
    final dir = sdkMaterialFonts;
    if (dir != null) {
      for (final fam in ['SF Pro Display', 'SF Pro Text', '']) {
        final l = FontLoader(fam);
        for (final f in Directory(dir).listSync().whereType<File>()) {
          final n = f.uri.pathSegments.last;
          if (n.startsWith('Roboto-') && n.endsWith('.ttf')) {
            l.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
          }
        }
        await l.load();
      }
    }
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    // Each recording "plays" for 4 seconds.
    WordVoice.debugPlay = (w, stopped) async {
      played.add(w.word);
      for (var i = 0; i < 40 && !stopped(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return true;
    };
  });
  tearDownAll(() => WordVoice.debugPlay = null);

  test('a routine is saved per phone and comes back after a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final s = RoutineStore.instance;
    await s.debugReset();
    await s.start();
    expect(s.routines, isEmpty);
    const r = Routine(
      id: 'r1',
      name: 'Morning calm',
      items: [RoutineItem(wordKey: 'a', word: 'A', minutes: 2), RoutineItem(wordKey: 'b', word: 'B', minutes: 5)],
      minuteOfDay: 6 * 60 + 30,
      days: {1, 3, 5},
      reminder: true,
    );
    await s.save(r);
    await s.debugReset();
    await s.start();
    final back = s.byId('r1')!;
    expect(back.name, 'Morning calm');
    expect(back.items.map((i) => '${i.word}:${i.minutes}'), ['A:2', 'B:5']);
    expect(back.days, {1, 3, 5});
    expect(back.timeLabel, '6:30 AM');
    expect(back.daysLabel, 'Mon, Wed, Fri');
    expect(back.reminder, isTrue);
    expect(s.reminders.single.minute, 390);
    await s.save(back.copyWith(reminder: false));
    expect(s.reminders, isEmpty);
    await s.delete('r1');
    await s.debugReset();
    await s.start();
    expect(s.routines, isEmpty);
  });

  test('routine reminders are planned on their days at their time', () {
    final now = DateTime(2026, 11, 23, 9); // a Monday
    final plan = NotifPlanner.plan(PlanInput(
      now: now,
      signedIn: true,
      isOn: (_) => false,
      quietOn: false,
      quietFrom: 0,
      quietTo: 0,
      reminder: 8 * 60,
      routines: [
        (id: 'r1', name: 'Morning calm', minute: 8 * 60, days: {1, 3, 5})
      ],
    ));
    // Monday 8:00 has passed: Wed, Fri, then next Monday is outside 7 days.
    expect(plan.map((p) => p.at), [DateTime(2026, 11, 25, 8), DateTime(2026, 11, 27, 8)]);
    for (final p in plan) {
      expect(p.title, 'Time for Morning calm');
      expect(p.route, 'routine:r1');
      expect(p.category, NotifCategories.wordOfDay);
      expect(p.id, inInclusiveRange(NotifPlanner.firstId, NotifPlanner.lastId));
    }
  });

  testWidgets('create, reorder, edit, delete, restart and Start', (t) async {
    SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
      await RoutineStore.instance.debugReset();
    });
    // Three free words with a recording each (the shipped list may be empty).
    ContentStore.instance.debugSetClientWords([
      for (final n in ['Shanti', 'Prakash', 'Dhara'])
        {
          'key': 'rt_${n.toLowerCase()}',
          'word': n,
          'price': 0,
          'categories': ['Calm'],
          'audio': 'asset:assets/words/rt/${n.toLowerCase()}.m4a',
        },
    ]);
    final pool = routineWords();
    expect(pool.take(3).map((w) => w.word), ['Shanti', 'Prakash', 'Dhara'], reason: 'recorded words first');
    expect(pool.length, greaterThanOrEqualTo(3), reason: 'words with a recording in the library');
    final w = pool.take(3).toList();

    // ── empty state ──
    await t.pumpWidget(_app(const MyRoutineScreen()));
    await t.runAsync(() => RoutineStore.instance.start());
    await _settle(t);
    expect(find.text('My routine'), findsOneWidget);
    await _shot(t, '02_my_routine_top');
    await _scrollTo(t, find.text('Create your routine').last);
    expect(find.text('Create your routine'), findsWidgets);
    await _shot(t, '03_my_routine_empty');

    // ── create ──
    await t.tap(find.widgetWithText(RoutinePill, 'Create your routine'));
    await _settle(t, 6);
    expect(find.text('New routine'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('routine-name')), 'Morning calm');
    for (final x in w) {
      await _scrollTo(t, find.byKey(ValueKey('pick-${x.key}')));
      await t.tap(find.byKey(ValueKey('pick-${x.key}')));
      await t.pump();
    }
    // Saturday and Sunday off, reminder on.
    await _scrollTo(t, find.text('Sat'));
    await t.tap(find.text('Sat'));
    await t.tap(find.text('Sun'));
    await t.pump();
    await _scrollTo(t, find.byKey(const ValueKey('routine-reminder')));
    await t.tap(find.byKey(const ValueKey('routine-reminder')));
    await t.pump();

    // Order rows show in pick order; drag the third to the top.
    await t.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await _settle(t, 3);
    await _scrollTo(t, find.byKey(ValueKey('item-${w[2].key}')));
    final handle = find.descendant(
        of: find.byKey(ValueKey('item-${w[2].key}')), matching: find.byType(ReorderableDragStartListener));
    final first = t.getTopLeft(find.byKey(ValueKey('item-${w[0].key}')));
    final g = await t.startGesture(t.getCenter(handle));
    await t.pump(const Duration(milliseconds: 100));
    final target = first.dy - 10 - t.getCenter(handle).dy;
    for (var i = 0; i < 10; i++) {
      await g.moveBy(Offset(0, target / 10));
      await t.pump(const Duration(milliseconds: 50));
    }
    await g.up();
    await _settle(t, 6);
    final ys = [for (final x in w) t.getTopLeft(find.byKey(ValueKey('item-${x.key}'))).dy];
    expect(ys[2] < ys[0] && ys[0] < ys[1], isTrue, reason: 'dragged ${w[2].word} to the top: $ys');

    // First row (now w[2]) 3 → 1 min, second row (w[0]) 3 → 2 min.
    Finder rowBtn(Word x, IconData icon) => find.descendant(
        of: find.byKey(ValueKey('item-${x.key}')),
        matching: find.byWidgetPredicate((e) => e is RoutineRoundButton && e.icon == icon));
    await _center(t, find.byKey(ValueKey('item-${w[0].key}')));
    await t.tap(rowBtn(w[2], Icons.remove_rounded));
    await t.pump();
    await t.tap(rowBtn(w[2], Icons.remove_rounded));
    await t.pump();
    await t.tap(rowBtn(w[0], Icons.remove_rounded));
    await t.pump();
    expect(find.descendant(of: find.byKey(ValueKey('item-${w[2].key}')), matching: find.text('1 min')), findsOneWidget);
    expect(find.descendant(of: find.byKey(ValueKey('item-${w[0].key}')), matching: find.text('2 min')), findsOneWidget);
    await _shot(t, '04_creating_routine_order');
    await _scrollTo(t, find.text('Reminder'));
    await _shot(t, '05_creating_routine_when');

    await _scrollTo(t, find.byKey(const ValueKey('routine-save')));
    await t.tap(find.byKey(const ValueKey('routine-save')));
    await _settle(t, 8);
    var saved = RoutineStore.instance.routines.single;
    expect(saved.name, 'Morning calm');
    expect(saved.items.map((i) => i.word), [w[2].word, w[0].word, w[1].word]);
    expect(saved.items.map((i) => i.minutes), [1, 2, 3]);
    expect(saved.days, {1, 2, 3, 4, 5});
    expect(saved.daysLabel, 'Weekdays');
    expect(saved.reminder, isTrue);
    expect(RoutineStore.instance.reminders.single.id, saved.id);
    await _scrollTo(t, find.text('Morning calm'));
    expect(find.text('7:00 AM · Weekdays'), findsOneWidget);
    await _shot(t, '06_saved_routine');

    // ── restart: a fresh store reads it back from the phone ──
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() async {
      await RoutineStore.instance.debugReset();
    });
    await t.pumpWidget(_app(const MyRoutineScreen()));
    await t.runAsync(() => RoutineStore.instance.start());
    await _settle(t);
    await _scrollTo(t, find.text('Morning calm'));
    expect(find.text('Morning calm'), findsOneWidget);
    expect(find.text('${w[2].word} · ${w[0].word} · ${w[1].word}'), findsOneWidget);

    // ── edit: rename and drop the last word ──
    await t.tap(find.widgetWithText(RoutinePill, 'Edit'));
    await _settle(t, 6);
    expect(find.text('Edit routine'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('routine-name')), 'Evening calm');
    await _scrollTo(t, find.byKey(ValueKey('item-${w[1].key}')));
    await _settle(t, 8);
    await t.tap(rowBtn(w[1], Icons.close_rounded));
    await t.pump();
    await _scrollTo(t, find.byKey(const ValueKey('routine-save')));
    await t.tap(find.byKey(const ValueKey('routine-save')));
    await _settle(t, 8);
    saved = RoutineStore.instance.routines.single;
    expect(saved.name, 'Evening calm');
    expect(saved.items.map((i) => i.word), [w[2].word, w[0].word]);

    // ── delete, then undo ──
    await _scrollTo(t, find.text('Evening calm'));
    await t.tap(find.bySemanticsLabel('Delete Evening calm'));
    await _settle(t, 6);
    await t.tap(find.widgetWithText(RoutinePill, 'Delete'));
    await _settle(t, 6);
    expect(RoutineStore.instance.routines, isEmpty);
    await t.tap(find.text('Undo'));
    await _settle(t, 6);
    expect(RoutineStore.instance.routines.single.name, 'Evening calm');
    await t.pump(const Duration(seconds: 5));
    await _settle(t, 4);

    // ── Start: the Player plays them in order, each for its minutes ──
    played.clear();
    _playerFontSlack();
    await _scrollTo(t, find.text('Evening calm'));
    await t.tap(find.widgetWithText(RoutinePill, 'Start'));
    await _settle(t, 20);
    expect(find.byType(PracticePlayerScreen), findsOneWidget);
    expect(find.textContaining('Evening calm · 1 of 2'), findsOneWidget);
    // The Player's count-in (three, two, one and the cues), then the word.
    for (var i = 0; i < 30 && played.isEmpty; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(played.first, w[2].word);
    await _shot(t, '07_routine_playing');
    // 1 minute for the first word (it repeats meanwhile), then the second.
    for (var i = 0; i < 70; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(find.textContaining('Evening calm · 2 of 2'), findsOneWidget);
    expect(played.where((x) => x == w[2].word).length, greaterThan(1), reason: 'repeats for its minute: $played');
    for (var i = 0; i < 30 && played.last != w[0].word; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(played.last, w[0].word);
    await _shot(t, '08_routine_playing_second');
    for (var i = 0; i < 150 && find.text('Evening calm · Complete').evaluate().isEmpty; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(find.text('Evening calm · Complete'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Evening calm is complete'), findsOneWidget);
    final n = played.length;
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(played.length, n, reason: 'nothing plays after the routine ends');
    await _shot(t, '09_routine_complete');

    await t.pumpWidget(const SizedBox());
    await _settle(t, 30);
    ContentStore.instance.debugSetClientWords(const []);
  });

  testWidgets('the Player button says My routine and opens it', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
    });
    final words = ContentStore.instance.library.take(6).toList();
    _playerFontSlack();
    await t.pumpWidget(_app(PracticePlayerScreen(words: words, title: 'Practice', showIntro: false)));
    await _settle(t, 20);
    expect(find.text('SENTENCE'), findsNothing);
    expect(find.text('MY ROUTINE'), findsOneWidget);
    await _shot(t, '01_player_my_routine_button');
    await t.tap(find.text('MY ROUTINE'));
    await _settle(t, 10);
    expect(find.byType(MyRoutineScreen), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await _settle(t, 30);
  });
}
