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

  test('pricing section uses the four flip photos and keeps the 16:9 banner', () {
    final src = File('lib/screens/subscription.dart').readAsStringSync();
    expect(src, contains('aspectRatio: 16 / 9'));
    expect(src, contains("asset: 'assets/video/subscription-banner.mp4'"));
    expect(src, contains("asset: 'assets/video/subscription-join-nowssb.mp4'"));
    expect(src, contains("What's Included"));
    expect(src, contains('Choose your frequency'));
    expect(src, contains('Start your 30-day free trial'));
    expect(src, contains('Subscribe to \${plan.name}'));
    expect(src, contains('rotateY'));
    expect(src, contains('PageView.builder'));
    expect(src, contains('GlassWrap.fill'));
    expect(src, contains('GlassWrap.blurSigma'));
    expect(src, contains('Disclaimer & Confidentiality'));
    expect(src, contains('Terms & Conditions'));
    expect(src, contains('class SubscriptionTermsScreen'));
    expect(src, contains('top: 10'));
    expect(src, isNot(contains('Color(0x2EFFFFFF)')));
    expect(File('assets/subscription/tier-blazer-front.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-sun-back.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-bag-front.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-nile-back.png').existsSync(), isTrue);
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
    expect(find.text('Choose your frequency'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text("What's Included"), findsWidgets);
    expect(find.text('Start your 30-day free trial'), findsOneWidget);
    expect(find.text('Disclaimer & Confidentiality'), findsOneWidget);
    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Free'), findsWidgets);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('terms page lists the subscription conditions', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: SubscriptionTermsScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Plans and access'), findsOneWidget);
    expect(find.text('Free trial'), findsOneWidget);
    expect(find.text('Billing and renewal'), findsOneWidget);
    expect(find.text('Cancellation'), findsOneWidget);
  });
}
