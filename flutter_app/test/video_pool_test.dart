/// The pool's ceiling is the whole promise of the port, so it is tested
/// rather than asserted in a comment.
///
/// These run against the real [VideoPool] and real [VideoPlayerController]s,
/// with a fake platform underneath standing in for ExoPlayer. So what is
/// being counted is not the pool's opinion of itself — it is how many players
/// were actually asked for and given back, which is the number that decides
/// whether a phone survives the app.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVideoPlatform platform;

  /// Let the pool's coalesced rebalance run all the way through.
  Future<void> pumpPool() async {
    for (var i = 0; i < 24; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUpAll(() => platform = FakeVideoPlatform());

  setUp(() async {
    VideoPool.instance.unhold();
    await VideoPool.instance.debugReset();
    platform.reset();
  });

  tearDown(() async {
    VideoPool.instance.unhold();
    await VideoPool.instance.debugReset();
  });

  test('a hundred mounted clips keep their decoders and play state',
      () async {
    for (var i = 0; i < 100; i++) {
      VideoPool.instance.lease('assets/video/clip-$i.mp4');
    }
    await pumpPool();

    expect(VideoPool.instance.leaseCount, 100);
    expect(VideoPool.instance.liveCount, 100);
    expect(platform.created, hasLength(100),
        reason: 'a mounted eligible clip stays active even when its widget is below the fold');
  });

  test('a hundred clips on screen at once remain active together', () async {
    final leases = [
      for (var i = 0; i < 100; i++)
        VideoPool.instance.lease('assets/video/clip-$i.mp4'),
    ];
    for (var i = 0; i < leases.length; i++) {
      leases[i].reportDistance(i.toDouble());
    }
    await pumpPool();

    expect(VideoPool.instance.liveCount, 100);
    expect(platform.alive, 100,
        reason: 'all mounted clips remain playing instead of being capped by viewport ranking');
  });

  test('every on-screen clip plays when there is room under the ceiling', () async {
    final leases = [
      for (var i = 0; i < 8; i++)
        VideoPool.instance.lease('assets/video/home-$i.mp4'),
    ];
    for (final l in leases) {
      l.reportDistance(20);
    }
    await pumpPool();

    expect(VideoPool.instance.liveCount, 8,
        reason: 'a home of eight films must all move, not sit on posters');
    expect(platform.alive, 8);
  });

  test('the decoders go to the clips nearest the middle of the screen',
      () async {
    // Fill the pool past capacity so ranking actually evicts the furthest.
    final far = VideoPool.instance.lease('assets/video/far.mp4');
    final near = VideoPool.instance.lease('assets/video/near.mp4');
    for (var i = 0; i < VideoPool.maxLive; i++) {
      VideoPool.instance.lease('assets/video/other-$i.mp4')
          .reportDistance(500);
    }
    far.reportDistance(4000);
    near.reportDistance(10);
    await pumpPool();

    expect(VideoPool.instance.debugLive, contains(near));
    expect(VideoPool.instance.debugLive, isNot(contains(far)));
    expect(near.controller, isNotNull);
    expect(far.controller, isNull);
  });

  test('a feature clip outranks decoration however far away it is', () async {
    final tv = VideoPool.instance.lease('assets/video/tv-screen.mp4',
        priority: ClipPriority.feature);
    for (var i = 0; i < VideoPool.maxLive + 4; i++) {
      VideoPool.instance.lease('assets/video/banner-$i.mp4').reportDistance(5);
    }
    tv.reportDistance(900);
    await pumpPool();

    expect(VideoPool.instance.debugLive, contains(tv));
    expect(platform.alive, VideoPool.maxLive);
  });

  test('scrolling past a clip does not stop its loop', () async {
    final a = VideoPool.instance.lease('assets/video/a.mp4');
    a.reportDistance(0);
    await pumpPool();
    expect(platform.alive, 1);

    a.reportDistance(double.infinity);
    await pumpPool();

    expect(VideoPool.instance.liveCount, 1);
    expect(platform.alive, 1,
        reason: 'scrolling must not stop a mounted eligible clip');
    expect(a.controller, isNotNull);
  });

  test('scrolling a long page never exceeds the ceiling at any point',
      () async {
    final leases = [
      for (var i = 0; i < 30; i++)
        VideoPool.instance.lease('assets/video/row-$i.mp4'),
    ];

    var peak = 0;
    for (var scroll = 0; scroll < 30; scroll++) {
      for (var i = 0; i < leases.length; i++) {
        final d = (i - scroll).abs() * 400.0;
        leases[i].reportDistance(d > 900 ? double.infinity : d);
      }
      await pumpPool();
      if (platform.alive > peak) peak = platform.alive;
      expect(platform.alive, lessThanOrEqualTo(VideoPool.maxLive),
          reason: 'exceeded the ceiling at scroll step $scroll');
    }

    expect(peak, 30, reason: 'all mounted clips remain live throughout scrolling');
    expect(platform.created.length, 30,
        reason: 'clips are not repeatedly disposed and recreated while scrolling');
  });

  test('disposing a lease releases its player even while it holds one',
      () async {
    final a = VideoPool.instance.lease('assets/video/a.mp4');
    a.reportDistance(0);
    await pumpPool();
    expect(platform.alive, 1);

    a.dispose();
    await pumpPool();

    expect(VideoPool.instance.leaseCount, 0);
    expect(platform.alive, 0);
  });

  test('backgrounding the app hands every decoder back', () async {
    for (var i = 0; i < VideoPool.maxLive; i++) {
      VideoPool.instance.lease('assets/video/$i.mp4').reportDistance(10);
    }
    await pumpPool();
    expect(platform.alive, VideoPool.maxLive);

    VideoPool.instance.releaseAll();
    await pumpPool();

    expect(VideoPool.instance.liveCount, 0);
    expect(platform.alive, 0,
        reason: 'Android reclaims decoders from a background app; a '
            'controller still holding one comes back to a dead surface');
  });

  test('nothing decodes while the pool is held', () async {
    VideoPool.instance.hold();
    for (var i = 0; i < VideoPool.maxLive; i++) {
      VideoPool.instance.lease('assets/video/$i.mp4').reportDistance(10);
    }
    await pumpPool();

    expect(VideoPool.instance.liveCount, 0);
    expect(platform.created, isEmpty,
        reason: 'a held pool must not ask the phone for anything');

    VideoPool.instance.unhold();
    await pumpPool();

    expect(platform.alive, VideoPool.maxLive,
        reason: 'and everything on screen takes its slot the moment the '
            'splash ends');
  });

  test('coming back to the foreground takes them again', () async {
    for (var i = 0; i < VideoPool.maxLive; i++) {
      VideoPool.instance.lease('assets/video/$i.mp4').reportDistance(10);
    }
    await pumpPool();
    VideoPool.instance.releaseAll();
    await pumpPool();
    expect(platform.alive, 0);

    VideoPool.instance.resume();
    await pumpPool();

    expect(platform.alive, VideoPool.maxLive);
  });
}
