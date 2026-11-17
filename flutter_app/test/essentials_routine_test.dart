// Normal home "Your essentials" (Ribon, Nov 17): the top card is a colourful
// auto-rotating carousel, one card per step; the timeline under it stays
// plain. Each step ticks from the real action, it resets at local midnight
// and every account keeps its own routine. Shots at 390 wide with
// --dart-define=ESSENTIALS_SHOTS=<dir>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/app_haptics.dart';
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
  await t
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
  await _pumps(t, 10);
}

Future<void> _mount(WidgetTester t,
    {double width = 390, double scale = 1}) async {
  t.view.physicalSize = Size(width * 3, 1400 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: NwsbTheme.light.copyWith(
        textTheme: NwsbTheme.light.textTheme.apply(fontFamily: 'DM Sans')),
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
    final b =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory(_shots).createSync(recursive: true);
    File('$_shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> _back(WidgetTester t) async {
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .popUntil((r) => r.isFirst);
  await _settle(t);
}

Finder _card(String id) => find.byKey(ValueKey('essential-$id'));
Finder _row(String id) => find.byKey(ValueKey('essential-row-$id'));
Finder _inCard(String id, Finder f) =>
    find.descendant(of: _card(id), matching: f);
Finder _inRow(String id, Finder f) =>
    find.descendant(of: _row(id), matching: f);

int _page() => NmSuppliedEssentials.carousel.currentState!.index;

String _counter(WidgetTester t) {
  final texts = find.descendant(
      of: find.byKey(const ValueKey('essentials-counter')),
      matching: find.byType(Text));
  return (t.widget(texts.first) as Text).data!;
}

Future<T?> _run<T>(WidgetTester t, Future<T> Function() f) => t.runAsync<T>(f);

List<String> _haptics(WidgetTester t) {
  final calls = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (c) async {
      if (c.method == 'HapticFeedback.vibrate') {
        calls.add('${c.arguments}');
      }
      return null;
    },
  );
  return calls;
}

void main() {
  setUpAll(() async {
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    V4Lottie.debugProgress = .4;
    await loadDmSans();
    await loadMaterialIcons();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (c) async => true);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(
        {'nwsb_terms_hub': '1', 'nwsb_player_guide_seen': true});
    DailyTasks.debugUid = 'ribon';
    DailyTasks.clock = DateTime.now;
    NmSuppliedEssentials.autoAdvance = false;
    await DailyTasks.publish();
  });

  tearDown(() {
    DailyTasks.debugUid = null;
    DailyTasks.clock = DateTime.now;
    NmSuppliedEssentials.autoAdvance = false;
  });

  testWidgets(
      'real actions tick each step, and the top card starts on the first open one',
      (t) async {
    final prev = FlutterError.onError;
    // The full player and word pages log asset misses / transient overflows
    // inside the test harness; this test is about the essentials section.
    FlutterError.onError = (d) {
      final s = d.toString();
      if (!s.contains('overflowed') &&
          !s.contains('Unable to load asset') &&
          !s.contains('HTTP')) {
        prev!(d);
      }
    };
    addTearDown(() => FlutterError.onError = prev);
    await _run(t, () async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
    });
    final lib = ContentStore.instance.library;
    expect(lib, isNotEmpty);

    await _mount(t);
    expect(_counter(t), '0 of 3 done');
    expect(_page(), 0, reason: 'carousel starts on the first open step');
    expect(_inCard('word', find.text('Step 1 of 3')), findsOneWidget);
    expect(_inCard('word', find.textContaining("Today's word · ")),
        findsOneWidget);
    expect(_inCard('word', find.text('To do')), findsOneWidget);
    expect(find.text('543'), findsNothing);
    expect(find.text('Still open'), findsNothing);
    expect(_inRow('player', find.byIcon(Icons.lock_outline_rounded)),
        findsOneWidget);
    expect(_inRow('read', find.byIcon(Icons.lock_outline_rounded)),
        findsOneWidget);
    expect(_inRow('player', find.text('To do')), findsOneWidget);
    await _shot(t, 'essentials-0-done');

    // 1 · a practice session for a word really finishes.
    await _run(
        t, () => PracticeProgress.instance.recordCompletedWord(lib.first));
    await _settle(t);
    expect(_counter(t), '1 of 3 done');
    expect(_inRow('word', find.text('Done')), findsOneWidget);
    expect(_inRow('word', find.byIcon(Icons.check_rounded)), findsWidgets);
    expect(_page(), 1, reason: 'carousel moves to the next open step');
    expect(_inCard('player', find.text('Step 2 of 3')), findsOneWidget);
    expect(_inRow('read', find.byIcon(Icons.lock_outline_rounded)),
        findsOneWidget);
    await _shot(t, 'essentials-1-done');

    // 2 · tapping the step opens the player; opening it ticks the step.
    await t.tap(find.byKey(const ValueKey('essential-player')));
    await _settle(t);
    expect(find.byType(PracticePlayerScreen), findsOneWidget);
    await _back(t);
    expect(_counter(t), '2 of 3 done');
    expect(_page(), 2);
    expect(_inCard('read', find.text('Step 3 of 3')), findsOneWidget);
    expect(_inCard('read', find.textContaining('The meaning of ')),
        findsOneWidget);
    await _shot(t, 'essentials-2-done');

    // 3 · tapping opens today's word page; its meaning on screen ticks it.
    await t.tap(find.byKey(const ValueKey('essential-read')));
    await _settle(t);
    expect(find.byType(WordDetail), findsOneWidget);
    await _back(t);
    expect(_counter(t), 'All 3 done');
    expect(_inRow('word', find.text('Done')), findsOneWidget);
    expect(_inRow('player', find.text('Done')), findsOneWidget);
    expect(_inRow('read', find.text('Done')), findsOneWidget);
    expect(
        find.text('Your routine is done for today. It starts fresh tomorrow.'),
        findsOneWidget);
    await _shot(t, 'essentials-all-done');

    final done = await _run(t, () => DailyTasks.done());
    expect(done, {'word', 'player', 'read'});
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 6));
  });

  testWidgets('each top card can be shown, with its own colour and info',
      (t) async {
    await _run(t, () async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
    });
    await _mount(t);
    const ids = ['word', 'player', 'read'];
    const steps = ['Step 1 of 3', 'Step 2 of 3', 'Step 3 of 3'];
    for (var i = 0; i < ids.length; i++) {
      NmSuppliedEssentials.carousel.currentState!.jumpTo(i);
      await _settle(t);
      expect(_page(), i);
      expect(_inCard(ids[i], find.text(steps[i])), findsOneWidget);
      expect(_inCard(ids[i], find.text('To do')), findsOneWidget);
      await _shot(t, 'essentials2-card-${ids[i]}');
    }
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('resets at local midnight, even with the home left open',
      (t) async {
    DailyTasks.clock = () => DateTime(2026, 11, 17, 23, 59, 57);
    await _run(t, () async {
      await DailyTasks.markEvent('word');
      await DailyTasks.markEvent('player');
    });
    await _mount(t);
    expect(_counter(t), '2 of 3 done');
    expect(_page(), 2, reason: 'starts on the last open step');
    DailyTasks.clock = () => DateTime(2026, 11, 18, 0, 0, 5);
    await t.pump(const Duration(seconds: 5)); // the midnight timer fires
    await _settle(t);
    expect(_counter(t), '0 of 3 done');
    expect(_page(), 0);
    expect(_inCard('word', find.text('Step 1 of 3')), findsOneWidget);
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
      await prefs.setStringList('nwsb_task_template_bob',
          ['player\tOpen the player', 't1\tStretch for two minutes']);
      await DailyTasks.markEvent('word'); // not in Bob's routine
      DailyTasks.debugUid = 'alice';
      await DailyTasks.publish();
    });
    await _mount(t);
    expect(_counter(t), '2 of 3 done');
    expect(_inRow('read', find.text('Done')), findsOneWidget,
        reason: 'done out of order still counts');
    expect(_page(), 1, reason: 'Alice starts on the open player step');
    expect(_inCard('player', find.text('Step 2 of 3')), findsOneWidget);

    await _run(t, () async {
      DailyTasks.debugUid = 'bob';
      await DailyTasks.publish();
    });
    await _settle(t);
    expect(_counter(t), '0 of 2 done');
    expect(_page(), 0);
    expect(find.text('Stretch for two minutes'), findsWidgets);
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

  testWidgets(
      'top cards auto-advance, pause when held, stay put in Still, and stay quiet',
      (t) async {
    await _run(t, () async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
      await Settings.instance.setFashionPlus(true);
    });
    AppHaptics.debugReset();
    await AppHaptics.preload();
    AppHaptics.debugEnabled(true);
    addTearDown(() {
      AppHaptics.debugEnabled(null);
      AppHaptics.debugReset();
    });
    NmSuppliedEssentials.autoAdvance = true;
    final h = _haptics(t);
    await _mount(t);
    expect(_page(), 0);

    await t.pump(NmSuppliedEssentials.every);
    await t.pump(NmSuppliedEssentials.glide + const Duration(milliseconds: 50));
    expect(_page(), 1, reason: 'auto-advances to the next card');
    expect(h, isEmpty, reason: 'auto-advance must not fire haptics');

    await t.pump(NmSuppliedEssentials.every);
    await t.pump(NmSuppliedEssentials.glide + const Duration(milliseconds: 50));
    expect(_page(), 2);

    final gesture = await t.startGesture(t.getCenter(find.byType(PageView)));
    // A small vertical move so lifting is not a tap on the card.
    await gesture.moveBy(const Offset(0, 40));
    await t.pump();
    await t.pump(NmSuppliedEssentials.every);
    await t.pump(NmSuppliedEssentials.glide + const Duration(milliseconds: 50));
    expect(_page(), 2, reason: 'stays put while a finger is on it');
    expect(h, isEmpty);
    await gesture.up();
    await t.pump();

    await _run(t, () => Settings.instance.setFashionPlus(false));
    await t.pump();
    // After release, a resume timer would otherwise restart motion; Still
    // must keep the carousel on this card.
    await t.pump(NmSuppliedEssentials.every);
    await t.pump(NmSuppliedEssentials.glide + const Duration(milliseconds: 50));
    expect(_page(), 2, reason: 'Still mode stops auto-rotation');
    expect(h, isEmpty);

    // A real swipe still moves the page and buzzes.
    await t.drag(find.byType(PageView), const Offset(280, 0));
    await t.pump();
    await t.pump(NmSuppliedEssentials.glide + const Duration(milliseconds: 50));
    expect(_page(), 1);
    expect(h, isNotEmpty, reason: 'a real user swipe fires a haptic');
    await t.pumpWidget(const SizedBox());
  });

  for (final width in [360.0, 390.0]) {
    testWidgets('no overflow at $width wide, text 1.3, every state', (t) async {
      for (final ids in [
        <String>[],
        ['word'],
        ['word', 'player'],
        ['word', 'player', 'read'],
        ['read']
      ]) {
        await _run(t, () async {
          final prefs = await SharedPreferences.getInstance();
          for (final k in prefs
              .getKeys()
              .where((k) => k.startsWith('nwsb_task_done_'))
              .toList()) {
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
          // Every carousel card, in this state, must also fit.
          final n = DailyTasks.items.value.length;
          for (var i = 0; i < n; i++) {
            NmSuppliedEssentials.carousel.currentState!.jumpTo(i);
            await t.pump();
            expect(t.takeException(), isNull,
                reason: '$ids card $i at $width × $scale');
          }
        }
      }
      await t.pumpWidget(const SizedBox());
    });
  }
}
