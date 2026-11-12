// Get Started (Zen home): every card opens a real page, the stepper shows
// real completion, and it is kept. Shots at 390 wide with
// --dart-define=GS_SHOTS=<dir>.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:nowssb/screens/normal/get_started_progress.dart';
import 'package:nowssb/screens/normal/horizontal_routine_cards.dart';
import 'package:nowssb/screens/player_guide.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/saved_words.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/screens/word_detail.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'fake_video_platform.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _shots = String.fromEnvironment('GS_SHOTS');

Future<void> _pumps(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

final _boundary = GlobalKey();
final _tabs = <int>[];

Future<void> _pumpSection(WidgetTester t) async {
  t.view.physicalSize = const Size(390 * 3, 900 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.runAsync(() async {
    await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
    await Settings.instance.load();
  });
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DM Sans'),
    home: NavScope(
      go: _tabs.add,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: _boundary,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1B2430), Color(0xFF0A0C10), Color(0xFF231A12)]),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const NmHorizontalRoutineCards(fashion: true),
            ),
          ),
        ),
      ),
    ),
  ));
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await _pumps(t, 6);
}

Future<void> _shot(WidgetTester t, String name) async {
  if (_shots.isEmpty) return;
  await t.pump(const Duration(milliseconds: 50));
  await t.runAsync(() async {
    final b = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 3);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory(_shots).createSync(recursive: true);
    File('$_shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> _show(WidgetTester t, String id) async {
  final i = GetStartedProgress.steps.indexOf(id);
  await t.tap(find.byKey(ValueKey('routine-step-$i')));
  await _pumps(t, 8);
}

Future<void> _tapCta(WidgetTester t, String id) async {
  await _show(t, id);
  await t.tap(find.byKey(ValueKey('getstarted-cta-$id')));
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await _pumps(t, 12);
}

Future<void> _back(WidgetTester t) async {
  final nav = t.state<NavigatorState>(find.byType(Navigator).first);
  nav.popUntil((r) => r.isFirst);
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await _pumps(t, 8);
}

bool _dotDone(String id) =>
    find.byKey(ValueKey('routine-step-${GetStartedProgress.steps.indexOf(id)}-done')).evaluate().isNotEmpty;

void main() {
  setUpAll(() async {
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    NmHorizontalRoutineCards.autoAdvance = false;
    await loadDmSans();
    await loadMaterialIcons();
    await loadTestFont('Noto Sans Devanagari', [
      '/usr/share/fonts/truetype/sand-box/google/Noto Sans Devanagari/NotoSansDevanagari-VariableFont_wdth,wght.ttf',
    ]);
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1', kPlayerGuideSeenKey: true});
    GetStartedProgress.instance.debugReset();
    _tabs.clear();
  });

  testWidgets('seven real steps, none of the old copy', (t) async {
    await _pumpSection(t);
    expect(t.takeException(), isNull);
    expect(find.text('Get Started'), findsOneWidget);
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(ValueKey('routine-step-$i')), findsOneWidget);
    }
    for (final bad in ['Positive Self-Talk & Power', 'Life Coaching', 'Story', 'What Your Body Knows', 'A Softer Inner Voice']) {
      expect(find.textContaining(bad), findsNothing);
    }
    expect(find.byType(Image), findsNothing, reason: 'word-only art, no posters or bag badges');
    expect(find.text('0 of 7 done'), findsOneWidget);
    for (final id in GetStartedProgress.steps) {
      await _show(t, id);
      expect(t.takeException(), isNull);
      await _shot(t, 'card-${GetStartedProgress.steps.indexOf(id) + 1}-$id');
    }
  });

  testWidgets('every CTA opens its page and the dots follow what was done', (t) async {
    final prev = FlutterError.onError;
    // Full pages (player, Sound Library) log transient overflows/asset misses
    // in the test harness; this test is about where each card goes.
    FlutterError.onError = (d) {
      final s = d.toString();
      if (!s.contains('overflowed') && !s.contains('Unable to load asset') && !s.contains('HTTP')) prev!(d);
    };
    addTearDown(() => FlutterError.onError = prev);
    await _pumpSection(t);
    final word = ContentStore.instance.library;
    expect(word, isNotEmpty);

    await _tapCta(t, 'word');
    expect(find.byType(WordDetail), findsOneWidget);
    await _back(t);
    expect(_dotDone('word'), isTrue);

    await _tapCta(t, 'practise');
    expect(find.byType(PracticePlayerScreen), findsOneWidget);
    await _back(t);
    expect(_dotDone('practise'), isFalse, reason: 'opening the player is not a finished session');
    await t.runAsync(() => PracticeProgress.instance.recordCompletedWord(word.first));
    await _pumps(t, 4);
    expect(_dotDone('practise'), isTrue);

    await _tapCta(t, 'guide');
    expect(find.byType(PlayerGuideScreen), findsOneWidget);
    await _back(t);
    expect(_dotDone('guide'), isTrue);

    await _tapCta(t, 'sounds');
    expect(find.byType(SoundLibraryScreen), findsOneWidget);
    await _back(t);
    expect(_dotDone('sounds'), isTrue);

    await _tapCta(t, 'save');
    expect(find.byType(SavedWordsScreen), findsOneWidget);
    expect(_dotDone('save'), isFalse);
    await t.runAsync(() async {
      final p = await SharedPreferences.getInstance();
      await p.setStringList('nwsb_liked_words', [word.first.word]);
    });
    await _back(t);
    expect(_dotDone('save'), isTrue);

    await _tapCta(t, 'tasks');
    expect(find.byType(DailyTasksPage), findsOneWidget);
    expect(_dotDone('tasks'), isFalse);
    await t.runAsync(() => DailyTasks.setDone('word', true));
    await _back(t);
    expect(_dotDone('tasks'), isTrue);

    await _tapCta(t, 'connect');
    expect(_tabs, [0], reason: 'Connect is tab 0');
    expect(_dotDone('connect'), isTrue);
    expect(find.text('7 of 7 done'), findsOneWidget);

    // Kept on the phone.
    final kept = await t.runAsync(() async =>
        (await SharedPreferences.getInstance()).getStringList(GetStartedProgress.prefsKey));
    expect(kept!.toSet(), GetStartedProgress.steps.toSet());
    await t.runAsync(() => PracticeProgress.instance.clearAll());
  });

  testWidgets('stepper with some steps done (shot) and stored steps reload', (t) async {
    SharedPreferences.setMockInitialValues({
      'nwsb_terms_hub': '1',
      GetStartedProgress.prefsKey: ['word', 'guide', 'sounds'],
    });
    await _pumpSection(t);
    await _pumps(t, 4);
    expect(_dotDone('word'), isTrue);
    expect(_dotDone('guide'), isTrue);
    expect(_dotDone('sounds'), isTrue);
    expect(_dotDone('practise'), isFalse);
    expect(find.text('3 of 7 done'), findsOneWidget);
    await _show(t, 'guide');
    expect(find.byKey(const ValueKey('getstarted-done-guide')), findsOneWidget);
    await _shot(t, 'stepper-3-done');
  });

  testWidgets('auto-advance: 5 s per card, holds on touch, resumes 5 s later', (t) async {
    NmHorizontalRoutineCards.autoAdvance = true;
    addTearDown(() => NmHorizontalRoutineCards.autoAdvance = false);
    await _pumpSection(t);
    final row = find.byKey(const ValueKey('getstarted-row'));
    double offset() => t.state<ScrollableState>(find.descendant(of: row, matching: find.byType(Scrollable))).position.pixels;
    expect(offset(), 0);
    await t.pump(const Duration(seconds: 5));
    await t.pump(const Duration(milliseconds: 650));
    final one = offset();
    expect(one, greaterThan(0));
    final g = await t.startGesture(t.getCenter(row));
    await t.pump(const Duration(seconds: 6));
    expect(offset(), one, reason: 'held while touched');
    await g.up();
    await t.pump(const Duration(seconds: 5));
    expect(offset(), one, reason: 'still holding right after the finger lifts');
    await t.pump(const Duration(seconds: 5));
    await t.pump(const Duration(milliseconds: 650));
    expect(offset(), greaterThan(one));
  });
}
