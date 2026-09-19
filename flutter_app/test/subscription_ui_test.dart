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

  test('pricing flip photos and join-clip backdrop are in the repo', () {
    final src = File('lib/screens/subscription.dart').readAsStringSync();
    expect(src, contains("asset: 'assets/video/subscription-join-nowssb.mp4'"));
    expect(src, contains('Simple plans, straight to your growth.'));
    expect(src, contains("What's Included"));
    expect(src, contains('tier-blazer-front.png'));
    expect(src, contains('tier-sun-back.png'));
    expect(src, contains('tier-bag-front.png'));
    expect(src, contains('tier-nile-back.png'));
    expect(src, contains('rotateY'));
    expect(File('assets/subscription/tier-blazer-front.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-blazer-back.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-sun-front.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-sun-back.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-bag-front.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-bag-back.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-nile-front.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-nile-back.png').existsSync(), isTrue);
    expect(File('assets/video/subscription-join-nowssb.mp4').existsSync(), isTrue);
  });

  testWidgets('subscription page shows the pricing carousel', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SubscriptionScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text('Simple plans, straight to your growth.'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text("What's Included"), findsWidgets);
    expect(find.text('Free'), findsWidgets);
  });
}
