import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  test(
    'subscription banner is 16:9 film, page background stays the join clip',
    () {
      final src = File('lib/screens/subscription.dart').readAsStringSync();
      expect(src, contains('aspectRatio: 16 / 9'));
      expect(src, contains("asset: 'assets/video/subscription-banner.mp4'"));
      expect(
        src,
        contains("poster: 'assets/video/subscription-banner-poster.webp'"),
      );
      expect(
        src,
        contains("asset: 'assets/video/subscription-join-nowssb.mp4'"),
      );
      expect(src, isNot(contains('bannerSlides')));
      expect(src, isNot(contains('_blackBanner')));
      expect(src, isNot(contains('_rotatingBanner')));
      expect(src, isNot(contains('_bottomOffer')));
      expect(src, isNot(contains('JOIN NOWSSB')));
      expect(src, isNot(contains('EVERY WORD · EVERY FREQUENCY')));
      expect(src.contains('aspectRatio: 16 / 9'), isTrue);
      expect(File('assets/video/subscription-banner.mp4').existsSync(), isTrue);
      expect(
        File('assets/video/subscription-banner-poster.webp').existsSync(),
        isTrue,
      );
      expect(
        File('assets/video/subscription-join-nowssb.mp4').existsSync(),
        isTrue,
      );
    },
  );

  testWidgets(
    'subscription page builds the 16:9 banner without black overlays',
    (tester) async {
      tester.view.physicalSize = const Size(412 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: SubscriptionScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('JOIN NOWSSB'), findsNothing);
      expect(find.text('EVERY WORD · EVERY FREQUENCY'), findsNothing);
      expect(find.text('Choose your frequency'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.byType(AspectRatio), findsWidgets);
      final ratios = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
      expect(ratios.any((w) => (w.aspectRatio - 16 / 9).abs() < 0.01), isTrue);
    },
  );
}
