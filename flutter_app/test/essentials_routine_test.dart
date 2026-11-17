// Normal home "Your essentials" (Ribon, Nov 17): each step ticks itself from
// the real action, the next step opens, the line fills, it resets at local
// midnight and every account keeps its own routine. Shots at 390 wide with
// --dart-define=ESSENTIALS_SHOTS=<dir>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:nowssb/screens/normal/home_v4.dart' show V4Lottie;
import 'package:nowssb/screens/normal/neomorphic_essentials.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/word_detail.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:nowssb/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _shots = String.fromEnvironment('ESSENTIALS_SHOTS');
final _boundary = GlobalKey();

Future<void> _pumps(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _settle(WidgetTester t) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
  await _pumps(t, 10);
}

Future<void> _mount(WidgetTester t, {double width = 390, double scale = 1}) async {
  t.view.physicalSize = Size(width * 3, 1100 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: NwsbTheme.light.copyWith(textTheme: NwsbTheme.light.textTheme.apply(fontFamily: 'DM Sans')),
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: NavScope(
      go: (_) {},
      child: Scaffold(
        backgroundColor: NwsbColors.surface,
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: _boundary,
            child: const ColoredBox(
              color: NwsbColors.surface,
              child: Padding(
                padding: EdgeInsets.only(top: 24, bottom: 8),
                child: NmSuppliedEssentials(),
              ),
            ),
          ),
        ),
      ),
    ),
  ));
  await _settle(t);
}

Future<void> _shot(WidgetTester t, String name) async {
  if (_shots.isEmpty) return;
  await _pumps(t, 8);
  await t.runAsync(() async {
    final b = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory(_shots).createSync(recursive: true);
    File('$_shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> _back(WidgetTester t) async {
  t.state<NavigatorState>(find.byType(Navigator).first).popUntil((r) => r.isFirst);
  await _settle(t);
}

Finder _in(String id, Finder f) =>
    find.descendant(of: find.byKey(ValueKey('essential-$id')), matching: f);

String _counter(WidgetTester t) {
  final texts = find.descendant(
      of: find.byKey(const ValueKey('essentials-counter')), matching: find.byType(Text));
  return (t.widget(texts.first) as Text).data!;
}

Future<T?> _run<T>(WidgetTester t, Future<T> Function() f) => t.runAsync<T>(f);

void main() {
  setUpAll(() async {
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    V4Lottie.debugProgress = .4;
    await loadDmSans();
    await loadMaterialIcons();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/url_launcher'), (c) async => true);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1', 'nwsb_player_guide_seen': true});
    DailyTasks.debugUid = 'ribon';
    DailyTasks.clock = DateTime.now;
    await DailyTasks.publish();
  });

  tearDown(() {
    DailyTasks.debugUid = null;
    DailyTasks.clock = DateTime.now;
  });

  testWidgets('real actions tick each step, unlock the next and fill the line', (t) async {
    final prev = FlutterError.onError;
    // The full player and word pages log asset misses / transient overflows
    // inside the test harness; this test is about the essentials section.
    FlutterError.onError = (d) {
      final s = d.toString();
      if (!s.contains('overflowed') && !s.contains('Unable to load asset') && !s.contains('HTTP')) prev!(d);
    };
    addTearDown(() => FlutterError.onError = prev);
    await _run(t, () async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
    });
    final lib = ContentStore.instance.library;
    expect(lib, isNotEmpty);

    await _mount(t);
    expect(_counter(t), '0 of 3 done');
    expect(_in('word', find.text('Step 1 of 3')), findsOneWidget, reason: 'first step is the open card');
    expect(find.text('543'), findsNothing);
    expect(find.text('Still open'), findsNothing);
    expect(_in('word', find.textContaining("Today's word · ")), findsOneWidget);
    expect(_in('player', find.byIcon(Icons.lock_outline_rounded)), findsOneWidget);
    expect(_in('read', find.byIcon(Icons.lock_outline_rounded)), findsOneWidget);
    expect(_in('player', find.text('To do')), findsOneWidget);
    await _shot(t, 'essentials-0-done');

    // 1 · a practice session for a word really finishes.
    await _run(t, () => PracticeProgress.instance.recordCompletedWord(lib.first));
    await _settle(t);
    expect(_counter(t), '1 of 3 done');
    expect(_in('word', find.text('Done')), findsOneWidget);
    expect(_in('word', find.byIcon(Icons.check_rounded)), findsWidgets);
    expect(_in('player', find.text('Step 2 of 3')), findsOneWidget, reason: 'player step unlocked and open');
    expect(_in('read', find.byIcon(Icons.lock_outline_rounded)), findsOneWidget);
    await _shot(t, 'essentials-1-done');

    // 2 · tapping the step opens the player; opening it ticks the step.
    await t.tap(find.byKey(const ValueKey('essential-player')));
    await _settle(t);
    expect(find.byType(PracticePlayerScreen), findsOneWidget);
    await _back(t);
    expect(_counter(t), '2 of 3 done');
    expect(_in('read', find.text('Step 3 of 3')), findsOneWidget);
    expect(_in('read', find.textContaining('The meaning of ')), findsOneWidget);
    await _shot(t, 'essentials-2-done');

    // 3 · tapping opens today's word page; its meaning on screen ticks it.
    await t.tap(find.byKey(const ValueKey('essential-read')));
    await _settle(t);
    expect(find.byType(WordDetail), findsOneWidget);
    await _back(t);
    expect(_counter(t), 'All 3 done');
    expect(find.textContaining('Step '), findsNothing);
    expect(find.text('Done'), findsNWidgets(3));
    expect(find.text('Your routine is done for today. It starts fresh tomorrow.'), findsOneWidget);
    await _shot(t, 'essentials-all-done');

    final done = await _run(t, () => DailyTasks.done());
    expect(done, {'word', 'player', 'read'});
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 6));
  });

  testWidgets('resets at local midnight, even with the home left open', (t) async {
    DailyTasks.clock = () => DateTime(2026, 11, 17, 23, 59, 57);
    await _run(t, () async {
      await DailyTasks.markEvent('word');
      await DailyTasks.markEvent('player');
    });
    await _mount(t);
    expect(_counter(t), '2 of 3 done');
    DailyTasks.clock = () => DateTime(2026, 11, 18, 0, 0, 5);
    await t.pump(const Duration(seconds: 5)); // the midnight timer fires
    await _settle(t);
    expect(_counter(t), '0 of 3 done');
    expect(_in('word', find.text('Step 1 of 3')), findsOneWidget);
    // Yesterday is still on record for that day.
    DailyTasks.clock = () => DateTime(2026, 11, 17, 22);
    expect(await _run(t, () => DailyTasks.done()), {'word', 'player'});
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('each account keeps its own routine on one phone', (t) async {
    await _run(t, () async {
      DailyTasks.debugUid = 'alice';
      await DailyTasks.markEvent('word');
      await DailyTasks.markEvent('read');
      DailyTasks.debugUid = 'bob';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('nwsb_task_template_bob', ['player\tOpen the player', 't1\tStretch for two minutes']);
      await DailyTasks.markEvent('word'); // not in Bob's routine
      DailyTasks.debugUid = 'alice';
      await DailyTasks.publish();
    });
    await _mount(t);
    expect(_counter(t), '2 of 3 done');
    expect(_in('read', find.text('Done')), findsOneWidget, reason: 'done out of order still counts');
    expect(_in('player', find.text('Step 2 of 3')), findsOneWidget);

    await _run(t, () async {
      DailyTasks.debugUid = 'bob';
      await DailyTasks.publish();
    });
    await _settle(t);
    expect(_counter(t), '0 of 2 done');
    expect(find.text('Stretch for two minutes'), findsOneWidget);
    expect(find.text('Sit with one word'), findsNothing);
    expect(await _run(t, () => DailyTasks.done()), isEmpty);

    await _run(t, () async {
      DailyTasks.debugUid = 'alice';
      await DailyTasks.publish();
    });
    await _settle(t);
    expect(_counter(t), '2 of 3 done');
    await t.pumpWidget(const SizedBox());
  });

  for (final width in [360.0, 390.0]) {
    testWidgets('no overflow at $width wide, text 1.3, every state', (t) async {
      for (final ids in [<String>[], ['word'], ['word', 'player'], ['word', 'player', 'read'], ['read']]) {
        await _run(t, () async {
          final prefs = await SharedPreferences.getInstance();
          for (final k in prefs.getKeys().where((k) => k.startsWith('nwsb_task_done_')).toList()) {
            await prefs.remove(k);
          }
          for (final id in ids) {
            await DailyTasks.markEvent(id);
          }
          await DailyTasks.publish();
        });
        for (final scale in [1.0, 1.3]) {
          await _mount(t, width: width, scale: scale);
          expect(t.takeException(), isNull, reason: '$ids at $width × $scale');
        }
      }
      await t.pumpWidget(const SizedBox());
    });
  }
}
