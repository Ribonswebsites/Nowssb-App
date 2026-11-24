// Ribon (Nov 24): the Devanagari written on each recording, with the akshara
// being voiced lit up in step with the teacher's recording — in the Player
// (a pill over the replay pill, only while playing) and in the Practice pop-up.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/word_voice.dart';
import 'package:nowssb/features/stage_practice/akshara_karaoke.dart';
import 'package:nowssb/features/stage_practice/stage_pack.dart';
import 'package:nowssb/features/stage_practice/stage_progress.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/offline_google_fonts.dart';

List<dynamic> _clientItems() =>
    (jsonDecode(File('assets/content/client_words.json').readAsStringSync()) as Map)['items'] as List;
Word _lib(String key) => ContentStore.instance.library.firstWhere((w) => w.key == key);

Future<void> _open(WidgetTester t, Word w) async {
  await t.pumpWidget(MaterialApp(
    home: NavScope(
      go: (_) {},
      child: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: TextButton(
              key: const ValueKey('home-open-player'),
              onPressed: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
                  builder: (_) => PracticePlayerScreen(words: [w], title: 'Test', showIntro: false))),
              child: const Text('Home'),
            ),
          ),
        ),
      ),
    ),
  ));
  await t.tap(find.byKey(const ValueKey('home-open-player')));
  for (var i = 0; i < 10; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 100));
  }
  // Pick Stage 1: plays its recording.
  WordVoice.instance.stop();
  await t.tap(find.byKey(const ValueKey('player-stages-chip')).first, warnIfMissed: false);
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
  await t.tap(find.byKey(const ValueKey('stages-row-1')));
}

int? _lit(WidgetTester t) {
  for (var i = 0; i < 8; i++) {
    if (find.byKey(ValueKey('akshara-on-$i')).evaluate().isNotEmpty) return i;
  }
  return null;
}

void main() {
  test('aksharas: ळमेरिका and ळामन्ळाम split as written', () {
    expect(devaAksharas('ळमेरिका'), ['ळ', 'मे', 'रि', 'का']);
    expect(devaAksharas('ळामन्ळाम'), ['ळा', 'म', 'न्ळा', 'म']);
    expect(devaAksharas(''), isEmpty);
  });

  test('every stage with Devanagari has one timing per akshara, in order, inside the recording', () {
    var n = 0;
    for (final raw in _clientItems()) {
      final pack = StagePack.fromRaw(raw as Map<String, dynamic>);
      if (pack == null) continue;
      for (final st in pack.stages) {
        final deva = st.deva.isNotEmpty ? st.deva : pack.deva;
        if (deva.isEmpty) {
          expect(st.akshara, isEmpty);
          continue;
        }
        n++;
        expect(st.akshara.length, devaAksharas(deva).length, reason: '${pack.wordKey} ${st.number}');
        for (var i = 0; i < st.akshara.length; i++) {
          expect(st.akshara[i][1], greaterThan(st.akshara[i][0]));
          if (i > 0) expect(st.akshara[i][0], closeTo(st.akshara[i - 1][1], 1e-6));
        }
        expect(st.akshara.last[1], lessThanOrEqualTo(st.seconds + 0.05));
        expect(hasKaraoke(st, pack.deva), isTrue);
      }
    }
    expect(n, 5, reason: 'America 1-2, Ram Ram 1-3');
  });

  test('the music versions start the voice 2.5 s in', () {
    expect(voiceOffsetFor('assets/words/america/america_stage1_music.m4a'), 2.5);
    expect(voiceOffsetFor('assets/words/america/america_stage1_music3.m4a'), 2.5);
    expect(voiceOffsetFor('assets/words/america/america_stage1_clean.m4a'), 0);
  });

  group('in the Player', () {
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
      StageProgressStore.debugAccount = 'karaoke';
      StageProgressStore.instance.debugReset();
      ContentStore.instance.debugSetClientWords(_clientItems());
      Entitlements.instance.debugSet(uid: 'karaoke', tier: 'resonance', until: DateTime.now().add(const Duration(days: 30)));
    });
    tearDown(() {
      VideoPool.instance.debugDropAll();
      WordVoice.debugPlay = null;
    });

    for (final key in ['ramram', 'america']) {
      testWidgets('$key: the pill shows only while playing and lights every akshara in step', (t) async {
        // A recording "plays" like the real one: its position moves 50 ms at a time.
        var lengthMs = 0;
        WordVoice.debugPlay = (w, stopped) async {
          for (var ms = 0; ms <= lengthMs && !stopped(); ms += 50) {
            WordVoice.instance.position.value = Duration(milliseconds: ms);
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
          return true;
        };
        final pack = StagePack.forWord(_lib(key))!;
        final st = pack.stages.first;
        lengthMs = (st.musicSeconds * 1000).round();
        t.view.physicalSize = const Size(412 * 2, 915 * 2);
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        await _open(t, _lib(key));
        final seen = <int>[];
        var checked = 0;
        for (var i = 0; i < 400; i++) {
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
          await t.pump(const Duration(milliseconds: 50));
          final pos = WordVoice.instance.position.value;
          if (pos == null) {
            if (seen.isNotEmpty) break;
            continue;
          }
          expect(find.byKey(const ValueKey('player-karaoke-pill')), findsOneWidget, reason: 'shown while playing');
          final want = aksharaAt(st.akshara, pos.inMilliseconds / 1000, WordVoice.instance.currentAsset);
          final got = _lit(t);
          expect(got ?? -1, want, reason: 'at ${pos.inMilliseconds} ms');
          checked++;
          if (got != null && (seen.isEmpty || seen.last != got)) seen.add(got);
        }
        expect(WordVoice.instance.currentAsset, st.music);
        expect(seen, [0, 1, 2, 3], reason: 'the highlight moves across every akshara in order');
        expect(checked, greaterThan(100));
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.byKey(const ValueKey('player-karaoke-pill')), findsNothing, reason: 'hidden when it stops');
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 2));
      });
    }

    testWidgets('Washington (no Devanagari written): no pill', (t) async {
      WordVoice.debugPlay = (w, stopped) async {
        for (var ms = 0; ms <= 3000 && !stopped(); ms += 50) {
          WordVoice.instance.position.value = Duration(milliseconds: ms);
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        return true;
      };
      t.view.physicalSize = const Size(412 * 2, 915 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await _open(t, _lib('washington'));
      for (var i = 0; i < 400 && WordVoice.instance.position.value == null; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(WordVoice.instance.position.value, isNotNull);
      expect(find.byKey(const ValueKey('player-karaoke-pill')), findsNothing);
      WordVoice.instance.stop();
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 4));
    });
  });
}
