/// The bug this file exists for.
///
/// The first APK looked right and played nothing: the readout said
/// "decoders 0/4" on a page full of clips. The cause was one line in the
/// wrong place — the post-frame measurement was registered inside build(),
/// and a post-frame callback fires ONCE. A ListView does not rebuild the
/// children that are merely scrolling past, and NwsbVideo only rebuilds when
/// the pool grants it a decoder. So a clip measured itself on its first
/// frame and never again, and a clip that missed on that single measurement
/// could never ask for another.
///
/// The unit tests could not see it — they drive reportDistance by hand — and
/// the widget test could not either, because it never scrolled. So the check
/// here is the one that matters and is deliberately not about distances at
/// all: PUMP FRAMES WITHOUT REBUILDING ANYTHING, AND SEE WHETHER THE CLIP IS
/// STILL TALKING TO THE POOL.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/nwsb_video.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:video_player/video_player.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(FakeVideoPlatform.new);
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('a clip keeps measuring itself on frames that do not rebuild it',
      (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: const [
            SizedBox(height: 300, child: NwsbVideo(asset: 'assets/video/a.mp4')),
            SizedBox(height: 1200),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 30));

    double dist() => VideoPool.instance.debugLeases.single.distance;

    expect(dist(), isNot(double.infinity),
        reason: 'the clip is on screen and should have said so');
    final before = dist();

    // Now SCROLL it — which moves the clip without rebuilding it, because a
    // ListView does not rebuild children that are merely travelling past.
    // If the measurement only ran from build(), the distance is frozen at
    // whatever the first frame said and the pool is blind from here on.
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 30));

    expect(dist(), isNot(before),
        reason: 'the clip was scrolled 260px and never noticed — the '
            'measurement is not running on frames of its own');
  });

  testWidgets('a clip on screen ends up with a decoder', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 300,
          child: NwsbVideo(asset: 'assets/video/a.mp4'),
        ),
      ),
    ));
    // Several frames, because granting one is a round trip to the platform.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }

    expect(VideoPool.instance.liveCount, greaterThan(0),
        reason: 'a clip filling the screen must get one of the four '
            'decoders — 0/4 here is the bug the first APK shipped with');
  });

  testWidgets('a clip that holds a decoder paints a player, not just a poster',
      (tester) async {
    // A granted clip must have the PLAYER in the tree. Holding a decoder and
    // showing only the poster underneath it is the failure that looks like
    // "the videos are not playing" while the readout says everything is
    // fine, and nothing else in the suite would notice it.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 200,
            child: NwsbVideo(asset: 'assets/video/hero-bg.mp4'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));

    // Whatever the platform has reported, a granted clip must be PAINTING a
    // player rather than only its poster.
    expect(VideoPool.instance.liveCount, greaterThan(0),
        reason: 'a clip on screen should hold a decoder');
    expect(find.byType(VideoPlayer), findsOneWidget,
        reason: 'the player must be in the tree, not just the poster');
  });
}
