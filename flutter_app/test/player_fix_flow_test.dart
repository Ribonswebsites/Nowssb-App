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
import 'package:nowssb/data/word_voice.dart';
import 'package:nowssb/features/stage_practice/stage_progress.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/select_level.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';

List<dynamic> _clientItems() =>
    (jsonDecode(File('assets/content/client_words.json').readAsStringSync()) as Map)['items'] as List;
Word _lib(String key) => ContentStore.instance.library.firstWhere((w) => w.key == key);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
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
}
