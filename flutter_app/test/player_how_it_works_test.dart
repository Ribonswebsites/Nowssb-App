// The player's top-bar info button opens How it works; the Word info row stays.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/widgets/how_it_works_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

Word _fallbackWord() => const Word(
  key: 'om',
  word: 'Om',
  deva: 'ॐ',
  translit: 'om',
  phonetic: 'om',
  parts: [],
  audioMale: '',
  audioFemale: '',
  organ: '',
  origin: 'Sanskrit',
  benefit: '',
  meaning: '',
  mouthPos: '',
  resonance: '',
  mistake: '',
  tip: '',
  categories: [],
  gender: 'both',
  time: 'any',
  price: 0,
  img: '',
);

Future<void> _pumps(WidgetTester t, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<List<Word>> _words() async {
  await ContentStore.instance.start().timeout(
    const Duration(seconds: 5),
    onTimeout: () {},
  );
  await Settings.instance.load();
  final lib = ContentStore.instance.library;
  if (lib.isNotEmpty) return lib.take(8).toList();
  return [_fallbackWord()];
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (c) async => 1,
    );
    m.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (c) async => true,
    );
  });

  testWidgets('top-bar info button opens How it works', (t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    late final List<Word> words;
    await t.runAsync(() async => words = await _words());
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('overflowed')) prev!(d);
    };
    addTearDown(() => FlutterError.onError = prev);

    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: PracticePlayerScreen(
          words: words,
          title: 'Test',
          showIntro: false,
        ),
      ),
    );
    await _pumps(t, 12);

    expect(find.text('NOW PLAYING'), findsOneWidget);
    final btn = find.byKey(const ValueKey('player-how-it-works-btn'));
    expect(btn, findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('How it works'), findsOneWidget);
    expect(find.byType(HowItWorksCard), findsNothing);

    await t.tap(btn);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(HowItWorksCard), findsOneWidget);
    expect(find.text('HOW IT WORKS'), findsOneWidget);
    expect(find.text('A NowssB word'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('how-it-works-close')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(HowItWorksCard), findsNothing);

    await t.pumpWidget(const SizedBox());
    await _pumps(t, 20);
  });

  testWidgets('Word info sheet still has the How it works row', (t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    late final List<Word> words;
    await t.runAsync(() async => words = await _words());
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('overflowed')) prev!(d);
    };
    addTearDown(() => FlutterError.onError = prev);

    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: PracticePlayerScreen(
          words: words,
          title: 'Test',
          showIntro: false,
        ),
      ),
    );
    await _pumps(t, 12);

    expect(find.bySemanticsLabel('Word info'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Word info'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('player-how-it-works')), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Five steps'), findsOneWidget);

    await t.pumpWidget(const SizedBox());
    await _pumps(t, 20);
  });
}
