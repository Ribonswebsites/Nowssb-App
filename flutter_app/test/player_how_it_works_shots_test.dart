// 390-wide shots of the player with the How it works info button, and
// of the pop-up opened from that button.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'support/offline_google_fonts.dart';

const _out = '/workspace/team-plan/shots/playerinfo';

Future<void> _writePng(ui.Image img, String name) async {
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory(_out)..createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _write(WidgetTester t, Finder f, String name) async {
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(f);
    final img = await b.toImage(pixelRatio: 2);
    await _writePng(img, name);
  });
}

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

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
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
  tearDown(() {
    HowItWorksCard.debugFrame = null;
  });

  testWidgets('player with info button, and the sheet opened from it', (
    t,
  ) async {
    const w = 390.0, h = 844.0;
    t.view.physicalSize = const Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);

    late final List<Word> words;
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
      await Settings.instance.load();
      final lib = ContentStore.instance.library;
      words = lib.isNotEmpty ? lib.take(8).toList() : [_fallbackWord()];
    });

    HowItWorksCard.debugFrame = (clip) =>
        AssetImage(clip.replaceAll('.mp4', '-poster.webp'));

    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.toString().contains('overflowed')) prev!(d);
    };
    addTearDown(() => FlutterError.onError = prev);

    const key = ValueKey('playerinfo-shot');
    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(w, h),
          devicePixelRatio: 2,
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'DM Sans'),
            home: PracticePlayerScreen(
              words: words,
              title: 'Evening mix',
              showIntro: false,
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 200));
    expect(
      find.byKey(const ValueKey('player-how-it-works-btn')),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    await _write(t, find.byKey(key), 'player');

    await t.tap(find.byKey(const ValueKey('player-how-it-works-btn')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 200));
    expect(find.byType(HowItWorksCard), findsOneWidget);
    await _write(t, find.byKey(key), 'player-sheet');

    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 200));
  });
}
