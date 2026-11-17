// Word detail must fit at 360 and 390 wide, at text scale 1.0 and 1.3.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/word_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

Word _vata({num price = 0}) => Word(
      key: 'vata',
      word: 'VATA',
      deva: '',
      translit: '',
      phonetic: 'vaa · ta',
      parts: const [
        WordPart(roman: 'vaa', deva: '', hold: 1.5, say: '', audio: ''),
        WordPart(roman: 'ta', deva: '', hold: 1.5, say: '', audio: ''),
      ],
      audioMale: '',
      audioFemale: '',
      organ: 'Nervous System',
      origin: 'Natural Origin',
      benefit: 'Balances nervous energy and reduces anxiety',
      meaning: 'Wind, movement — the force of motion',
      mouthPos: 'Long open A, let breath carry the word',
      resonance: 'Feel movement in the chest and throat',
      mistake: 'Do not clip the A — it must be long',
      tip: 'Say it with a slow exhale, like releasing wind',
      categories: const ['Mental Clarity', 'Lung & Breath'],
      gender: 'both',
      time: 'evening',
      price: price,
      img: '',
      stages: const [
        WordStage(title: 'Breath', text: 'Slow in', audio: 'https://media.example/vata-1.mp3'),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    await setUpHomeRender();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  for (final width in [360.0, 390.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('VATA fits at ${width.toInt()} x$scale', (t) async {
        t.view.physicalSize = Size(width, 2000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final errors = <String>[];
        final prev = FlutterError.onError;
        FlutterError.onError = (d) {
          errors.add(d.exceptionAsString());
          prev?.call(d);
        };
        await t.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 2000),
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: WordDetail(word: _vata()),
          ),
        ));
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
        FlutterError.onError = prev;
        expect(errors.where((e) => e.contains('overflowed')), isEmpty,
            reason: errors.where((e) => e.contains('overflowed')).join('\n'));
        expect(find.text('VATA'), findsWidgets);
        expect(find.text('Wind, movement — the force of motion'), findsOneWidget);
        expect(find.text('How to say it'), findsOneWidget);
        expect(find.text('Meaning and use'), findsOneWidget);
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 5));
      });
    }
  }
}
