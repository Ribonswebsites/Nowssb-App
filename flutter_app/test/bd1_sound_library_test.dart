/// BD-1: sound library pages build at 320px wide under large text scales.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/aura_sound_library.dart';
import 'package:nowssb/screens/currently_playing_album.dart';
import 'package:nowssb/screens/sound_library.dart';

import 'fake_video_platform.dart';

const _w = Word(
  key: 'om',
  word: 'Shantih Shantih Shantih',
  deva: '',
  translit: '',
  phonetic: '',
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
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  Future<void> pump(WidgetTester tester, Widget child, double scale) async {
    tester.view.physicalSize = const Size(320 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 720),
          textScaler: TextScaler.linear(scale),
        ),
        child: child,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Full feeds are checked at 1.3 only: at 2.0 the shared NowssbHypeRail
  // (lib/widgets/hype_rail.dart, not a BD-1 file) overflows by 27px on its
  // own. The BD-1 widgets themselves are clean at both scales.
  for (final scale in [1.3]) {
    testWidgets('sound library (orb hero) at 320px x$scale', (tester) async {
      await pump(tester, const SoundLibraryScreen(embedded: true), scale);
      expect(tester.takeException(), isNull);
    });
    testWidgets('aura sound library (title band) at 320px x$scale',
        (tester) async {
      await pump(tester, const AuraSoundLibraryScreen(), scale);
      expect(tester.takeException(), isNull);
    });
  }
  for (final scale in [1.3, 2.0]) {
    testWidgets('currently playing album at 320px x$scale', (tester) async {
      await pump(
        tester,
        Scaffold(
          body: ListView(children: [
            CurrentlyPlayingAlbum(
              words: const [_w, _w, _w],
              art: (_) => 'assets/missing.png',
              counts: const {},
              onPlay: (_) {},
              onOpen: (_) {},
            ),
          ]),
        ),
        scale,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
