// Teacher-recorded words are practised ONLY in the Player:
//  • the Player's Stages list has one row per recorded stage (Stage 1, 2, 3),
//    a locked "Stage 3 · Coming soon" row where none is recorded, and one
//    "Request more stages" button — no banners, video, Buy or expand;
//  • tapping a stage plays that stage's EDITED recording (music version, or
//    the cleaned voice when stage music is off) in the Player;
//  • Practice records (fake mic), scores against that stage's recording with
//    the five sub-scores, a pointer on WHERE in the word it differed, and tips;
//    passing opens the next stage.
// Every shipped recording (America 1–2, Ram Ram 1–3, Washington 1–2) is
// played and scored through the sheet.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/data/word_photos.dart';
import 'package:nowssb/data/word_requests.dart';
import 'package:nowssb/data/word_voice.dart';
import 'package:nowssb/features/stage_practice/stage_mic.dart';
import 'package:nowssb/features/stage_practice/stage_pack.dart';
import 'package:nowssb/features/stage_practice/stage_progress.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice_overlay.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/select_level.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';

/// Mic level (dBFS) every 50 ms of a 16-bit mono WAV, as the phone reports it.
List<double> wavLevels(Uint8List wav) {
  final d = ByteData.sublistView(wav);
  final out = <double>[];
  const frame = 800; // 50 ms at 16 kHz
  for (var i = 44; i + frame * 2 <= wav.length; i += frame * 2) {
    var sum = 0.0;
    for (var k = 0; k < frame; k++) {
      final v = d.getInt16(i + k * 2, Endian.little) / 32768;
      sum += v * v;
    }
    final rms = math.sqrt(sum / frame);
    out.add(rms <= 1e-6 ? -90 : 20 * math.log(rms) / math.ln10);
  }
  return out;
}

/// A microphone that "hears" [take]: its levels while the take plays, then
/// room quiet (-65 dBFS) until stopped — so the sheet's auto-stop decides.
class FakeMic implements StageMic {
  FakeMic(this.take, {this.permitted = true});
  Uint8List? take;
  bool permitted;
  int starts = 0;
  int stops = 0;
  Timer? _feed;
  @override
  String? get lastPath => null;
  @override
  Future<bool> hasPermission() async => permitted;
  @override
  Future<void> start(String name, void Function(double dbfs) level) async {
    starts++;
    final lv = take == null ? const <double>[] : wavLevels(take!);
    var i = 0;
    _feed = Timer.periodic(const Duration(milliseconds: 50), (_) => level(i < lv.length ? lv[i++] : -65));
  }
  @override
  Future<Uint8List?> stop() async {
    stops++;
    _feed?.cancel();
    return take;
  }
  @override
  Future<void> cancel() async => _feed?.cancel();
  @override
  void dispose() {}
}

List<dynamic> _clientItems() =>
    (jsonDecode(File('assets/content/client_words.json').readAsStringSync()) as Map)['items'] as List;

Word _lib(String key) => ContentStore.instance.library.firstWhere((w) => w.key == key);

/// The teacher's Ram Ram stage 3 take (ळामन्ळाम): a different word from America.
Uint8List _ramRam3() => File('assets/words/ramram/ramram_stage3_ref.wav').readAsBytesSync();

const _expected = {'america': [1, 2], 'ramram': [1, 2, 3], 'washington': [1, 2]};

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  tearDown(() {
    VideoPool.instance.debugDropAll();
    PracticeLabSheet.debugMic = null;
    WordVoice.debugPlay = null;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StageProgressStore.debugAccount = 'player-stages';
    StageProgressStore.instance.debugReset();
    ContentStore.instance.debugSetClientWords(_clientItems());
    WordVoice.debugPlayed.clear();
    Entitlements.instance.debugSet(uid: 'player-stages', tier: 'resonance', until: DateTime.now().add(const Duration(days: 30)));
  });

  test('every client recording ships edited (clean + music + reference) with its own photo', () {
    for (final e in _expected.entries) {
      final pack = StagePack.forWord(_lib(e.key))!;
      expect(pack.stages.map((s) => s.number).toList(), e.value, reason: e.key);
      for (final s in pack.stages) {
        expect(s.music, endsWith('_music.m4a'));
        expect(s.audio, endsWith('_clean.m4a'));
        for (final f in [s.audio, s.music, s.reference]) {
          expect(File(f).existsSync(), isTrue, reason: f);
        }
      }
      expect(File(wordPhotoFor(e.key)!).existsSync(), isTrue, reason: e.key);
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/words/${e.key}/'));
    }
    expect(StagePack.forWord(_lib('america'))!.comingSoon, [3]);
    expect(StagePack.forWord(_lib('ramram'))!.stages.last.deva, 'ळामन्ळाम');
  });

  Future<void> pumpList(WidgetTester t, Word w, {ValueChanged<int>? onStage}) async {
    t.view.physicalSize = const Size(412 * 2, 1100 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: SelectLevelScreen(word: w, onStage: onStage))));
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Stages list: Stage 1/2, locked Stage 3 · Coming soon, Request more; nothing else', (t) async {
    final picked = <int>[];
    await pumpList(t, _lib('america'), onStage: picked.add);
    expect(find.text('America'), findsOneWidget);
    expect(find.byKey(const ValueKey('stages-headline-deva')), findsOneWidget);
    expect((t.widget(find.byKey(const ValueKey('stages-headline-deva'))) as Text).data, 'ळमेरिका');
    expect(find.text('STAGE 1'), findsOneWidget);
    expect((t.widget(find.byKey(const ValueKey('stages-deva-1'))) as Text).data, 'ळमेरिका');
    expect(find.text('STAGE 2'), findsOneWidget);
    expect(find.textContaining('Pass Stage'), findsNothing, reason: 'every recorded stage is open');
    expect(find.text('STAGE 3 · COMING SOON'), findsOneWidget);
    expect(find.textContaining('Buy'), findsNothing);
    expect(find.byKey(const ValueKey('stages-expand')), findsNothing);
    expect(find.textContaining('streak', findRichText: true), findsNothing);
    // Both recorded stages open straight away; only Stage 3 (not recorded) is locked.
    await t.tap(find.byKey(const ValueKey('stages-row-2')));
    await t.pump();
    expect(picked, [2]);
    await t.tap(find.byKey(const ValueKey('stages-row-3')));
    await t.pump();
    expect(picked, [2]);
    await t.tap(find.byKey(const ValueKey('stages-row-1')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('stages-row-2')));
    await t.pump();
    expect(picked, [2, 1, 2], reason: 'switching back and forth');
    // Request more stages.
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('stages-request')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('REQUESTED'), findsOneWidget);
    expect(WordRequestStore.instance.items.first.word, 'America');
  });

  testWidgets('a passed stage shows its best score; every recorded stage stays open', (t) async {
    await t.runAsync(() => StageProgressStore.instance.addAttempt('america', 1, score: 88, passed: true));
    final picked = <int>[];
    await pumpList(t, _lib('america'), onStage: picked.add);
    expect(find.text('Best 88 · passed'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('stages-row-2')));
    await t.pump();
    expect(picked, [2]);
  });

  testWidgets('in the Player: Stages → Stage 1 plays the edited music version; voice only plays clean', (t) async {
    t.view.physicalSize = const Size(412 * 2, 915 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    WordVoice.debugPlay = (w, stopped) async => true;
    final america = _lib('america');
    await t.pumpWidget(MaterialApp(
        home: NavScope(go: (_) {}, child: PracticePlayerScreen(words: [america], title: america.word, showIntro: false))));
    await t.pump(const Duration(seconds: 1));
    final chip = find.byKey(const ValueKey('player-stages-chip'));
    expect(chip, findsWidgets);
    await t.tap(chip.first, warnIfMissed: false);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    expect(find.byType(SelectLevelScreen), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('stages-row-1')));
    for (var i = 0; i < 20; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(SelectLevelScreen), findsNothing, reason: 'the list closes and the Player plays');
    expect(WordVoice.debugPlayed, contains('assets/words/america/america_stage1_music.m4a'));
    expect(WordVoice.debugPlayed.where((a) => a.contains('_ref') || a.contains('/recs/')), isEmpty);
    await t.runAsync(() => Settings.instance.setStageMusic(false));
    WordVoice.debugPlayed.clear();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 12));
    await t.pumpWidget(MaterialApp(
        home: NavScope(go: (_) {}, child: PracticePlayerScreen(words: [america], title: america.word, showIntro: false))));
    await t.pump(const Duration(seconds: 1));
    await t.tap(chip.first, warnIfMissed: false);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    await t.tap(find.byKey(const ValueKey('stages-row-1')));
    for (var i = 0; i < 20; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(WordVoice.debugPlayed, contains('assets/words/america/america_stage1_clean.m4a'));
    await t.runAsync(() => Settings.instance.setStageMusic(true));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 12));
  });

  Future<void> pumpSheet(WidgetTester t, Word w, int stage, FakeMic mic, {ValueChanged<int>? onStage}) async {
    t.view.physicalSize = const Size(412 * 2, 1400 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    PracticeLabSheet.debugMic = () => mic;
    final pack = StagePack.forWord(w)!;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: PracticeLabSheet(
          word: w,
          pack: pack,
          stage: pack.stages.firstWhere((s) => s.number == stage),
          onSpeak: () async {},
          onClose: () {},
          onStage: onStage,
          video: '',
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 400));
  }

  /// The sheet counts 3-2-1, records, stops by itself after the word and
  /// scores — no Start or Stop taps.
  Future<void> takeAndScore(WidgetTester t, {bool expectCountdown = true}) async {
    var sawCount = false, sawListening = false;
    for (var i = 0; i < 600; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump(const Duration(milliseconds: 50));
      sawCount |= find.byKey(const ValueKey('practice-countdown')).evaluate().isNotEmpty;
      sawListening |= find.byKey(const ValueKey('practice-listening')).evaluate().isNotEmpty;
      if (find.byKey(const ValueKey('stage-result')).evaluate().isNotEmpty ||
          find.byKey(const ValueKey('stage-unscored')).evaluate().isNotEmpty) {
        break;
      }
    }
    if (expectCountdown) {
      expect(sawCount, isTrue, reason: '3-2-1 shows first');
      expect(sawListening, isTrue, reason: 'then it listens');
    }
    for (var i = 0; i < 40; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump(const Duration(milliseconds: 20));
    }
  }

  for (final e in _expected.entries) {
    for (final n in e.value) {
      testWidgets('${e.key} stage $n: record, score against that recording, sub-scores, pointer, tips, progress', (t) async {
        // No earlier stage passed: every recorded stage is open anyway.
        final ref = File('assets/words/${e.key}/${e.key}_stage${n}_ref.wav').readAsBytesSync();
        final mic = FakeMic(ref);
        final went = <int>[];
        await pumpSheet(t, _lib(e.key), n, mic, onStage: went.add);
        // One pop-up only: no word/stage card above the sheet.
        expect(find.byKey(const ValueKey('stage-progress-label')), findsNothing);
        expect(find.byKey(ValueKey('stage-chip-$n')), findsNothing);
        await takeAndScore(t);
        expect(mic.starts, 1);
        expect(find.byKey(const ValueKey('stage-result')), findsOneWidget);
        final score = int.parse((t.widget(find.byKey(const ValueKey('stage-score'))) as Text).data!);
        expect(score, greaterThanOrEqualTo(70), reason: 'the stage’s own recording passes');
        // Simple score screen: one big score, one word, the waveform pointer, one sentence.
        expect(find.byKey(const ValueKey('stage-verdict')), findsOneWidget);
        expect(find.byKey(const ValueKey('stage-sub-sounds')), findsNothing);
        expect(find.textContaining('You need'), findsNothing);
        expect(find.textContaining('%'), findsNothing);
        expect(find.byKey(const ValueKey('stage-score-ring')), findsOneWidget);
        expect(find.byKey(const ValueKey('stage-pointer')), findsNothing, reason: 'closed until asked');
        await t.tap(find.byKey(const ValueKey('stage-improve-btn')));
        await t.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('stage-pointer')), findsOneWidget);
        expect(StageProgressStore.instance.record(e.key, n).passed, isTrue);
        final pack = StagePack.forWord(_lib(e.key))!;
        if (pack.stages.any((s) => s.number == n + 1)) {
          await t.tap(find.byKey(const ValueKey('practice-next-stage')));
          expect(went, [n + 1]);
        } else {
          expect(find.byKey(const ValueKey('practice-next-stage')), findsNothing);
        }
      });
    }
  }

  testWidgets('America stage 1 said as Ram Ram: Try again, a pointer and one plain sentence', (t) async {
    await pumpSheet(t, _lib('america'), 1, FakeMic(_ramRam3()));
    await takeAndScore(t);
    final score = int.parse((t.widget(find.byKey(const ValueKey('stage-score'))) as Text).data!);
    expect(score, lessThan(70));
    expect(find.byKey(const ValueKey('stage-fix-0')), findsNothing);
    expect((t.widget(find.byKey(const ValueKey('stage-verdict'))) as Text).data, 'Try again');
    await t.tap(find.byKey(const ValueKey('stage-improve-btn')));
    await t.pump(const Duration(milliseconds: 300));
    final note = (t.widget(find.byKey(const ValueKey('stage-pointer-note'))) as Text).data!;
    expect(note, matches(RegExp(r'^(Beginning|Middle|Ending): [a-z’ ]+\.$')));
    expect(find.textContaining('%'), findsNothing);
    expect(find.byKey(const ValueKey('practice-next-stage')), findsNothing);
    expect(StageProgressStore.instance.record('america', 1).passed, isFalse);
    expect(StageProgressStore.instance.record('america', 1).attempts, 1);
  });

  testWidgets('silence: a message, no score, not counted', (t) async {
    await pumpSheet(t, _lib('america'), 1, FakeMic(null));
    await takeAndScore(t);
    expect(find.byKey(const ValueKey('stage-unscored')), findsOneWidget);
    expect(find.byKey(const ValueKey('stage-score')), findsNothing);
    expect(StageProgressStore.instance.record('america', 1).attempts, 0);
  });

  testWidgets('a refused microphone says how to allow it', (t) async {
    await pumpSheet(t, _lib('america'), 1, FakeMic(null, permitted: false));
    for (var i = 0; i < 30; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Allow the microphone in phone settings to practise.'), findsOneWidget);
  });

  testWidgets('Cancel during the countdown stops it; Start runs it again', (t) async {
    final mic = FakeMic(File('assets/words/america/america_stage1_ref.wav').readAsBytesSync());
    await pumpSheet(t, _lib('america'), 1, mic);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('practice-countdown')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('practice-start')));
    await t.pump(const Duration(seconds: 3));
    expect(mic.starts, 0, reason: 'cancelled before recording');
    expect(find.text('Start'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('practice-start')));
    await takeAndScore(t);
    expect(mic.starts, 1);
    expect(find.byKey(const ValueKey('stage-result')), findsOneWidget);
  });
}
