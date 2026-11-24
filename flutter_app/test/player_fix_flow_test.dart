// Ribon's phone test of 0defdb7 (Nov 24): every recorded stage open, every
// stage tap plays its edited recording (switching back and forth, after the
// track ends), the artwork stays with a small 1 / 2 / 3 badge (no black box),
// the down chevron closes the Player, and the old swipe-up "Now playing"
// screen is gone.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/playback_session.dart';
import 'package:nowssb/features/routine/routine_store.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/screens/my_routine.dart';
import 'package:nowssb/data/word_voice.dart';
import 'package:nowssb/features/stage_practice/stage_progress.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/select_level.dart';
import 'package:nowssb/screens/player_settings.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/offline_google_fonts.dart';

List<dynamic> _clientItems() =>
    (jsonDecode(File('assets/content/client_words.json').readAsStringSync()) as Map)['items'] as List;
Word _lib(String key) => ContentStore.instance.library.firstWhere((w) => w.key == key);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await setUpOfflineGoogleFonts();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StageProgressStore.debugAccount = 'player-fix';
    StageProgressStore.instance.debugReset();
    ContentStore.instance.debugSetClientWords(_clientItems());
    WordVoice.debugPlayed.clear();
    // A recording "plays" for 600 ms, or until stopped / replaced.
    WordVoice.debugPlay = (w, stopped) async {
      for (var i = 0; i < 30 && !stopped(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      return true;
    };
    Entitlements.instance.debugSet(uid: 'player-fix', tier: 'resonance', until: DateTime.now().add(const Duration(days: 30)));
  });
  tearDown(() {
    VideoPool.instance.debugDropAll();
    WordVoice.debugPlay = null;
  });

  Future<void> run(WidgetTester t, int frames) async {
    for (var i = 0; i < frames; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> openPlayer(WidgetTester t, List<Word> words) async {
    t.view.physicalSize = const Size(412 * 2, 915 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: NavScope(
        go: (_) {},
        child: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: TextButton(
                key: const ValueKey('home-open-player'),
                onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
                    builder: (_) => PracticePlayerScreen(words: words, title: 'Evening Practice', showIntro: false))),
                child: const Text('Home'),
              ),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.byKey(const ValueKey('home-open-player')));
    await run(t, 10);
  }

  Future<void> pickStage(WidgetTester t, int n) async {
    await t.tap(find.byKey(const ValueKey('player-stages-chip')).first, warnIfMissed: false);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    expect(find.byType(SelectLevelScreen), findsOneWidget);
    await t.tap(find.byKey(ValueKey('stages-row-$n')));
    await run(t, 4);
    expect(find.byType(SelectLevelScreen), findsNothing);
  }

  testWidgets('every stage tap plays its edited recording, back and forth and after it ends', (t) async {
    await openPlayer(t, [_lib('america'), _lib('ramram'), _lib('washington')]);
    await run(t, 10); // the first run ends by itself
    WordVoice.debugPlayed.clear();
    for (final n in [2, 1, 2, 2, 1]) {
      await pickStage(t, n);
      expect(WordVoice.debugPlayed.last, 'assets/words/america/america_stage${n}_music.m4a');
      // The artwork stays: no black caption box over it, just the small badge.
      expect(find.textContaining('Stage $n ·'), findsNothing);
      final badge = t.widget<Container>(find.byKey(ValueKey('player-stage-badge-$n')));
      expect((badge.decoration as BoxDecoration).color, const Color(0xFFF4F4F5));
      expect(find.byKey(const ValueKey('player-stage-badge-3')), findsOneWidget, reason: 'Coming soon number');
      await run(t, 10); // let it end before the next tap
    }
    expect(WordVoice.debugPlayed.length, 5, reason: 'five taps, five plays');
    // Next → Ram Ram plays its own Stage 1; Prev → back to America.
    WordVoice.debugPlayed.clear();
    await t.tap(find.byIcon(Icons.skip_next_rounded).first);
    await run(t, 4);
    expect(WordVoice.debugPlayed.last, 'assets/words/ramram/ramram_stage1_music.m4a');
    await pickStage(t, 3);
    expect(WordVoice.debugPlayed.last, 'assets/words/ramram/ramram_stage3_music.m4a');
    await run(t, 10);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('the down chevron closes the Player to the mini player', (t) async {
    await openPlayer(t, [_lib('america')]);
    expect(find.byType(PracticePlayerScreen), findsOneWidget);
    await t.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
    await run(t, 8);
    expect(find.byType(PracticePlayerScreen), findsNothing);
    expect(find.text('Home'), findsOneWidget);
    expect(PlaybackSession.instance.minimized, isTrue);
    await PlaybackSession.instance.dismiss();
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('a swipe up on the Player opens no second "Now playing" screen', (t) async {
    await openPlayer(t, [_lib('america'), _lib('ramram')]);
    await t.fling(find.byType(PracticePlayerScreen), const Offset(0, -500), 2500);
    await run(t, 8);
    expect(find.text('Evening Practice'), findsNothing);
    expect(File('lib/screens/player_up_view.dart').existsSync(), isFalse);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('Music: Drone, Warm pad, Singing bowl or Voice only, remembered and played', (t) async {
    await openPlayer(t, [_lib('america')]);
    await run(t, 10);
    for (final (opt, file) in [
      ('pad', 'america_stage1_music2.m4a'),
      ('bowl', 'america_stage1_music3.m4a'),
      ('voice', 'america_stage1_clean.m4a'),
      ('drone', 'america_stage1_music.m4a'),
    ]) {
      await t.tap(find.byKey(const ValueKey('player-music-btn')));
      await run(t, 5);
      await t.tap(find.byKey(ValueKey('music-opt-$opt')));
      await run(t, 5);
      expect(WordVoice.debugPlayed.last, 'assets/words/america/$file', reason: opt);
      await run(t, 8);
    }
    expect(Settings.instance.stageBed, 'drone');
    expect(Settings.instance.stageMusic, isTrue);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('My routine Start opens the main Player on the recorded words', (t) async {
    ContentStore.recordedWordsOnly = true;
    ContentStore.instance.debugRecompute();
    addTearDown(() {
      ContentStore.recordedWordsOnly = false;
      ContentStore.instance.debugRecompute();
    });
    expect(ContentStore.instance.library.map((w) => w.key).toSet(), {'america', 'ramram', 'washington'});
    t.view.physicalSize = const Size(412 * 2, 915 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
        home: NavScope(
            go: (_) {},
            child: Builder(
                builder: (ctx) => Scaffold(
                    body: TextButton(
                        key: const ValueKey('routine-start'),
                        onPressed: () => startRoutine(ctx, const Routine(id: 'evening', name: 'Evening Practice', items: [RoutineItem(wordKey: 'ananda', word: 'Ananda', minutes: 5)])),
                        child: const Text('Start')))))));
    await t.tap(find.byKey(const ValueKey('routine-start')));
    await run(t, 10);
    final p = t.widget<PracticePlayerScreen>(find.byType(PracticePlayerScreen));
    expect(p.words.map((w) => w.key), ['america', 'ramram', 'washington']);
    expect(find.text('NOW PLAYING'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('tap-through: every Player button does its job', (t) async {
    final went = <int>[];
    t.view.physicalSize = const Size(412 * 2, 915 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final words = [_lib('america'), _lib('ramram'), _lib('washington')];
    await t.pumpWidget(NavScope(
      go: went.add,
      child: MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              key: const ValueKey('home-open-player'),
              onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
                  builder: (_) => PracticePlayerScreen(words: words, title: 'Evening Practice', showIntro: false))),
              child: const Text('Home'),
            ),
          ),
        ),
      ),
    ));
    await t.tap(find.byKey(const ValueKey('home-open-player')));
    await run(t, 12);
    // Heart: saves and un-saves.
    expect(find.byIcon(Icons.favorite_border_rounded), findsWidgets);
    await t.tap(find.byIcon(Icons.favorite_border_rounded).last);
    await run(t, 3);
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    await t.tap(find.byIcon(Icons.favorite_rounded).last);
    await run(t, 3);
    // Shuffle and repeat switch.
    Color? iconColor(IconData i) => t.widget<Icon>(find.byIcon(i).first).color;
    final sh0 = iconColor(Icons.shuffle_rounded);
    await t.tap(find.byIcon(Icons.shuffle_rounded).first);
    await run(t, 3);
    expect(iconColor(Icons.shuffle_rounded), isNot(sh0));
    await t.tap(find.byIcon(Icons.shuffle_rounded).first);
    await run(t, 3);
    final rp0 = iconColor(Icons.repeat_rounded);
    await t.tap(find.byIcon(Icons.repeat_rounded).first);
    await run(t, 3);
    expect(iconColor(Icons.repeat_rounded), isNot(rp0));
    await t.tap(find.byIcon(Icons.repeat_rounded).first);
    await run(t, 3);
    // Next / Prev play their word's stage 1.
    WordVoice.debugPlayed.clear();
    await t.tap(find.byIcon(Icons.skip_next_rounded).first);
    await run(t, 4);
    expect(WordVoice.debugPlayed.last, contains('ramram_stage1'));
    await t.tap(find.byIcon(Icons.skip_previous_rounded).first);
    await run(t, 4);
    expect(WordVoice.debugPlayed.last, contains('america_stage1'));
    // Play / pause.
    await run(t, 10);
    final before = WordVoice.debugPlayed.length;
    await t.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await run(t, 3);
    expect(WordVoice.debugPlayed.length, before + 1);
    await t.tap(find.byIcon(Icons.pause_rounded).first);
    await run(t, 3);
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
    // Replay on the artwork restarts even mid-play.
    await t.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await run(t, 2);
    final mid = WordVoice.debugPlayed.length;
    await t.tap(find.byIcon(Icons.replay_rounded).first);
    await run(t, 3);
    expect(WordVoice.debugPlayed.length, mid + 1);
    await run(t, 10);
    // Grid icon: player tools.
    await t.tap(find.byIcon(Icons.dashboard_customize_outlined).first);
    await run(t, 4);
    expect(find.byType(PracticePlayerScreen), findsOneWidget);
    await t.tapAt(const Offset(10, 10));
    await run(t, 4);
    // Settings and help on the artwork.
    await t.tap(find.byIcon(Icons.settings_rounded).first);
    await run(t, 6);
    expect(find.byType(PlayerSettingsScreen), findsOneWidget);
    Navigator.of(t.element(find.byType(PlayerSettingsScreen))).pop();
    await run(t, 6);
    await t.tap(find.byIcon(Icons.help_outline_rounded).first);
    await run(t, 6);
    expect(find.byType(BottomSheet), findsOneWidget, reason: 'word info');
    Navigator.of(t.element(find.byType(BottomSheet))).pop();
    await run(t, 6);
    // Header info: how it works.
    await t.tap(find.byKey(const ValueKey('player-how-it-works-btn')));
    await run(t, 6);
    expect(find.byType(PracticePlayerScreen), findsOneWidget);
    final nav = Navigator.of(t.element(find.byType(PracticePlayerScreen)));
    if (nav.canPop()) {
      // Close whatever How it works opened.
      await t.binding.handlePopRoute();
      await run(t, 6);
    }
    expect(find.byType(PracticePlayerScreen), findsOneWidget);
    // Up next: plays the next word.
    final pv = find.byType(PageView).last;
    await t.drag(pv, const Offset(-400, 0));
    await run(t, 6);
    WordVoice.debugPlayed.clear();
    await t.tap(find.byIcon(Icons.play_arrow_rounded).last);
    await run(t, 4);
    expect(WordVoice.debugPlayed, isNotEmpty, reason: 'Up next plays');
    expect(WordVoice.debugPlayed.last, contains('ramram_stage1'));
    // MY ROUTINE opens the routine page; back returns to the Player.
    await t.drag(find.byType(PageView).last, const Offset(400, 0));
    await run(t, 6);
    await t.tap(find.text('MY ROUTINE').first);
    await run(t, 8);
    expect(find.byType(MyRoutineScreen), findsOneWidget);
    Navigator.of(t.element(find.byType(MyRoutineScreen))).pop();
    await run(t, 6);
    // STORE: the Player drops to the mini player and the Store tab opens.
    await t.tap(find.text('STORE').first);
    await run(t, 8);
    expect(went, contains(3));
    expect(find.byType(PracticePlayerScreen), findsNothing);
    // Android back from a fresh Player: closes it too.
    await t.tap(find.byKey(const ValueKey('home-open-player')));
    await run(t, 10);
    await t.binding.handlePopRoute();
    await run(t, 8);
    expect(find.byType(PracticePlayerScreen), findsNothing);
    await PlaybackSession.instance.dismiss();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  });
}
