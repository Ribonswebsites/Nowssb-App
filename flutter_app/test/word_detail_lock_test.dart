// Word Detail opens a paid word's recordings, video and meaning only with
// the same entitlement the Practice Player checks (REPORT P0 #2).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/word_detail.dart';

import 'fake_video_platform.dart';

Word _w({required num price}) => Word(
      key: 'om',
      word: 'Om',
      deva: '',
      translit: '',
      phonetic: '',
      parts: const [],
      audioMale: '',
      audioFemale: '',
      organ: '',
      origin: 'Sanskrit',
      benefit: '',
      meaning: 'The first sound',
      mouthPos: '',
      resonance: '',
      mistake: '',
      tip: '',
      categories: const [],
      gender: 'both',
      time: 'any',
      price: price,
      img: '',
      stages: const [WordStage(title: 'Breath', text: 'Slow in', audio: 'https://media.example/om-1.mp3')],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('a paid word is locked for a free account', (t) async {
    await t.pumpWidget(MaterialApp(home: WordDetail(word: _w(price: 99))));
    await t.pump();
    expect(find.text('Unlock this word'), findsOneWidget);
    expect(find.text('The first sound'), findsNothing, reason: 'meaning stays hidden');
    expect(find.byIcon(Icons.play_circle_outline), findsNothing, reason: 'no free play button');
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('a free word opens fully', (t) async {
    await t.pumpWidget(MaterialApp(home: WordDetail(word: _w(price: 0))));
    await t.pump();
    expect(find.text('Unlock this word'), findsNothing);
    expect(find.text('The first sound'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}
