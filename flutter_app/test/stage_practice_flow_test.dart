// America end to end without a phone: the shipped client_words.json reaches
// the library with the teacher's two real America stages (अमेरिका; Stage 1
// ळमेरिका), stages unlock 1 → 2, and the practice screen records (fake mic),
// scores on the real recordings and shows a pass, specific corrections, or a
// "not scored" message. The Ram Ram take (ळामन्ळाम) that was once filed as
// America's first stage is only a wrong-word fixture now.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/word_voice.dart';
import 'package:nowssb/features/stage_practice/stage_mic.dart';
import 'package:nowssb/features/stage_practice/stage_pack.dart';
import 'package:nowssb/features/stage_practice/stage_practice_screen.dart';
import 'package:nowssb/features/stage_practice/stage_progress.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';

class FakeMic implements StageMic {
  FakeMic(this.take, {this.permitted = true});
  Uint8List? take;
  bool permitted;
  int starts = 0;

  @override
  String? get lastPath => null;
  @override
  Future<bool> hasPermission() async => permitted;
  @override
  Future<void> start(String name, void Function(double dbfs) level) async {
    starts++;
    level(-20);
  }

  @override
  Future<Uint8List?> stop() async => take;
  @override
  Future<void> cancel() async {}
  @override
  void dispose() {}
}

Uint8List _silence() {
  const n = 16000 * 2;
  final b = ByteData(44 + n * 2);
  void s(int o, String v) {
    for (var i = 0; i < 4; i++) {
      b.setUint8(o + i, v.codeUnitAt(i));
    }
  }

  s(0, 'RIFF');
  b.setUint32(4, 36 + n * 2, Endian.little);
  s(8, 'WAVE');
  s(12, 'fmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, 16000, Endian.little);
  b.setUint32(28, 32000, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  s(36, 'data');
  b.setUint32(40, n * 2, Endian.little);
  return b.buffer.asUint8List();
}

List<dynamic> _clientItems() =>
    (jsonDecode(File('assets/content/client_words.json').readAsStringSync()) as Map)['items'] as List;

Uint8List _ref(int n) => File('assets/words/america/america_stage${n}_ref.wav').readAsBytesSync();

/// The teacher's Ram Ram (ळामन्ळाम) take: a different word, never America.
Uint8List _ramRam() => File('test/fixtures/shabda/clean_stage1.wav').readAsBytesSync();

Future<void> _attempt(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('stage-mic')));
  for (var i = 0; i < 40 && find.text('Recording').evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 20));
  }
  expect(find.text('Recording'), findsOneWidget);
  await t.tap(find.byKey(const ValueKey('stage-mic')));
  for (var i = 0; i < 300; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 20));
    if (find.text('Recording').evaluate().isEmpty && find.text('Scoring').evaluate().isEmpty) break;
  }
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  tearDown(VideoPool.instance.debugDropAll);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StageProgressStore.debugAccount = 'test';
    StageProgressStore.instance.debugReset();
    ContentStore.instance.debugSetClientWords(_clientItems());
  });

  test('America is in the library with its 2 real stages, all assets bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/words/america/'));
    expect(pubspec, contains('- assets/content/'));
    final w = ContentStore.instance.library.firstWhere((w) => w.key == 'america');
    expect(w.word, 'AMERICA');
    expect(w.deva, 'अमेरिका');
    expect(w.stages, hasLength(2));
    expect(w.price, 99);
    expect(WordVoice.hasVoice(w), isTrue);
    expect(WordVoice.isRemote(w), isFalse);
    expect(File(WordVoice.assetPath(w)).existsSync(), isTrue);
    final pack = StagePack.forWord(w)!;
    expect(pack.deva, 'अमेरिका');
    expect(pack.stages.map((s) => s.number), [1, 2]);
    expect(pack.stages.first.deva, 'ळमेरिका');
    expect(pack.passMark, 70);
    for (final s in pack.stages) {
      for (final f in [s.audio, s.music, s.reference]) {
        expect(File(f).existsSync(), isTrue, reason: f);
      }
    }
    expect(File('assets/words/america/america_stage3_ref.wav').existsSync(), isFalse);
    expect(pack.musicCredit, contains('CC0'));
  });

  test('stages unlock in order and keep the best score', () async {
    final p = StageProgressStore.instance;
    await p.ensureLoaded();
    expect(p.isUnlocked('america', 1), isTrue);
    expect(p.isUnlocked('america', 2), isFalse);
    expect(await p.addAttempt('america', 1, score: 55, passed: false), isFalse);
    expect(p.isUnlocked('america', 2), isFalse);
    expect(await p.addAttempt('america', 1, score: 82, passed: true), isTrue);
    expect(await p.addAttempt('america', 1, score: 60, passed: false), isFalse);
    expect(p.record('america', 1).best, 82);
    expect(p.record('america', 1).attempts, 3);
    expect(p.isUnlocked('america', 2), isTrue);
    expect(p.currentStage('america', 2), 2);
    // Survives a reload.
    p.debugReset();
    await p.ensureLoaded();
    expect(p.record('america', 1).passed, isTrue);
  });

  Widget app(StagePack pack, StageMic mic, {int? stage}) => MaterialApp(
        home: StagePracticeScreen(pack: pack, mic: mic, initialStage: stage),
      );

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(412 * 2, 2400 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
  }

  testWidgets('saying stage 1 like the recording passes and opens stage 2', (t) async {
    tall(t);
    final pack = StagePack.forKey('america')!;
    await t.pumpWidget(app(pack, FakeMic(_ref(1)), stage: 1));
    await t.pump();
    await _attempt(t);
    expect(find.textContaining('Passed'), findsWidgets);
    expect(find.text('What you got right'), findsOneWidget);
    expect(find.text('Go to Stage 2'), findsOneWidget);
    expect(StageProgressStore.instance.record('america', 1).passed, isTrue);
    expect(StageProgressStore.instance.isUnlocked('america', 2), isTrue);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('saying a different word (Ram Ram) fails with specific corrections', (t) async {
    tall(t);
    final pack = StagePack.forKey('america')!;
    await t.pumpWidget(app(pack, FakeMic(_ramRam()), stage: 1));
    await t.pump();
    await _attempt(t);
    expect(find.text('What to fix'), findsOneWidget);
    expect(find.text('Go to Stage 2'), findsNothing);
    final score = int.parse((t.widget<Text>(find.byKey(const ValueKey('stage-score')))).data!);
    expect(score, lessThan(50));
    expect(find.textContaining(RegExp('beginning|middle|ending')), findsWidgets);
    expect(StageProgressStore.instance.record('america', 1).passed, isFalse);
    expect(StageProgressStore.instance.record('america', 1).attempts, 1);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('silence gets a message, not a score, and is not counted', (t) async {
    tall(t);
    final pack = StagePack.forKey('america')!;
    await t.pumpWidget(app(pack, FakeMic(_silence()), stage: 1));
    await t.pump();
    await _attempt(t);
    expect(find.text('Not scored'), findsOneWidget);
    expect(find.byKey(const ValueKey('stage-score')), findsNothing);
    expect(StageProgressStore.instance.record('america', 1).attempts, 0);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('a refused microphone says how to allow it', (t) async {
    tall(t);
    final pack = StagePack.forKey('america')!;
    final mic = FakeMic(_ref(1), permitted: false);
    await t.pumpWidget(app(pack, mic, stage: 1));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('stage-mic')));
    await t.pump();
    expect(find.textContaining('Permissions → Microphone'), findsOneWidget);
    expect(mic.starts, 0);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('locked stages cannot be picked', (t) async {
    tall(t);
    final pack = StagePack.forKey('america')!;
    await t.pumpWidget(app(pack, FakeMic(_ref(1))));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('stage-chip-2')));
    await t.pump();
    expect(find.text('Pass Stage 1 to open Stage 2.'), findsOneWidget);
    expect(find.text('Stage 1 of 2'), findsOneWidget);
    expect(find.text('ळमेरिका'), findsWidgets);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}
