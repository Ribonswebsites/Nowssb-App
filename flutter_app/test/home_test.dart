/// The home page, checked for the two things a widget test is good at.
///
/// It does NOT scroll. Scrolling is covered by video_pool_test.dart, which
/// walks thirty clips past a viewport and asserts the ceiling at every step —
/// and it can do that because it runs in real async. A widget test runs on a
/// fake clock, and the pool's teardown awaits the platform actually releasing
/// a player; those two do not mix, and trying made the suite take four
/// minutes to say nothing.
///
/// What is worth checking here is what the unit tests cannot see:
///
///   · the page lays out at a real phone size without overflowing — this is
///     how the three overflows in the first draft of this screen were found;
///   · every clip on it goes through NwsbVideo, so every clip is under the
///     pool rather than holding a decoder of its own.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/nwsb_video.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FakeVideoPlatform();
    // Deadlines own real Timers; this file runs on a fake clock. See
    // VideoPool.debugDeadlines.
    VideoPool.debugDeadlines = false;
  });

  // The pool is a singleton, so each test starts from an empty one — and the
  // zero timer it uses to coalesce its passes has to be cancelled, or the
  // test framework rightly complains that a timer outlived the widget tree.
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeNormal()));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('the home lays out on a phone without overflowing',
      (tester) async {
    await pumpHome(tester);

    // A RenderFlex overflow is reported as a test exception, so getting here
    // with none means the page fits. Said explicitly so the intent survives
    // someone reading this later.
    expect(tester.takeException(), isNull);

    // The clips on the first screen are real, and each took a lease — which
    // is the only way a clip gets a decoder in this app.
    expect(find.byType(NwsbVideo), findsWidgets);
    expect(VideoPool.instance.leaseCount, greaterThan(0));

    debugPrint('home: ${tester.widgetList(find.byType(NwsbVideo)).length} '
        'clips built, ${VideoPool.instance.leaseCount} leases');
  });

  testWidgets('every clip on the home is a bundled asset under the pool',
      (tester) async {
    await pumpHome(tester);

    // The rule the port depends on: nothing constructs a VideoPlayer itself,
    // and nothing streams. A clip that did either would hold a decoder the
    // pool has never heard of — exactly the hole the website had.
    final clips = tester.widgetList<NwsbVideo>(find.byType(NwsbVideo));
    expect(clips, isNotEmpty);
    for (final v in clips) {
      expect(v.asset, startsWith('assets/video/'));
      expect(v.asset, endsWith('.mp4'));
    }
  });
}
