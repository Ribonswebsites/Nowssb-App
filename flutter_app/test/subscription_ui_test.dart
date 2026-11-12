import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/features/programs/store_extras.dart';
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
    expect(src, contains("asset: 'assets/video/subscription-b.mp4'"));
    expect(src, contains("asset: 'assets/video/subscription-bg.mp4'"));
    expect(src, contains("What's Included"));
    expect(src, contains('Choose your frequency'));
    expect(src, contains('Start free trial'));
    expect(src, contains("'Subscribe'"));
    expect(src, contains('rotateY'));
    expect(src, contains('PageView.builder'));
    expect(src, contains('GlassWrap.fill'));
    expect(src, contains('GlassWrap.blurSigma'));
    expect(src, isNot(contains('Disclaimer & Confidentiality')));
    expect(src, isNot(contains('Price on Google Play')));
    expect(src, isNot(contains('not available in this build')));
    expect(src, isNot(contains('Payments are handled by Google Play')));
    expect(src, contains('Terms & Conditions'));
    expect(src, contains('class SubscriptionTermsScreen'));
    expect(src, contains('top: 10'));
    expect(src, isNot(contains('Color(0x2EFFFFFF)')));
    expect(File('assets/subscription/tier-blazer-front.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-sun-back.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-bag-front.png').existsSync(), isTrue);
    expect(File('assets/subscription/tier-nile-back.png').existsSync(), isTrue);
  });

  test('every plan front and back is a different picture, used nowhere else', () {
    final src = File('lib/screens/subscription.dart').readAsStringSync();
    final paths = RegExp(r"(?:front|back): '(assets/subscription/[^']+)'")
        .allMatches(src.substring(0, src.indexOf('class _Plan {')))
        .map((m) => m.group(1)!)
        .toList();
    expect(paths.length, 8, reason: '4 plans x front + back');
    expect(paths.toSet().length, 8, reason: 'no path reused');
    String digest(File f) => base64.encode(sha1.convert(f.readAsBytesSync()).bytes);
    final byHash = <String, String>{};
    for (final p in paths) {
      final h = digest(File(p));
      expect(byHash.containsKey(h), isFalse,
          reason: '$p has the same pixels as ${byHash[h]}');
      byHash[h] = p;
    }
    // Not a copy of any other bundled picture (the hero and other pages).
    for (final f in Directory('assets').listSync(recursive: true, followLinks: false)) {
      if (f is! File || f.path.contains('assets/subscription/')) continue;
      if (!RegExp(r'\.(png|jpe?g|webp)$').hasMatch(f.path)) continue;
      if (f.lengthSync() < 30000) continue;
      final other = byHash[digest(f)];
      expect(other, isNull, reason: '${f.path} duplicates $other');
    }
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
    expect(find.text('Start free trial'), findsOneWidget);
    expect(find.text('Disclaimer & Confidentiality'), findsNothing);
    expect(find.textContaining('not available in this build'), findsNothing);
    expect(find.textContaining('Price on Google Play'), findsNothing);
    expect(find.textContaining('Payments are handled by Google Play'), findsNothing);
    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Free'), findsWidgets);
    expect(find.byType(PageView), findsOneWidget);
  });

  test('subscription page source has no Copy link / Share referral block', () {
    final src = File('lib/screens/subscription.dart').readAsStringSync();
    for (final bad in const [
      'ShareItemButtons',
      'ShareChip',
      'Copy link',
      'Share NowssB',
      'SharePlus',
      'ios_share',
    ]) {
      expect(src, isNot(contains(bad)), reason: '$bad belongs in Profile only');
    }
    final manifest =
        File('lib/admin/template/slot_manifest.g.dart').readAsStringSync();
    expect(manifest, isNot(contains('SubscriptionScreen.share-nowssb')));
  });

  testWidgets('subscription page shows no Copy link or Share widget',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SubscriptionScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    // Scroll to the very bottom so the footer is built.
    await tester.scrollUntilVisible(
      find.text('Terms & Conditions'),
      500,
      scrollable: find
          .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down)
          .first,
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Copy link'), findsNothing);
    expect(find.textContaining('Share'), findsNothing);
    expect(find.textContaining('your link'), findsNothing);
    expect(find.byType(ShareItemButtons), findsNothing);
    expect(find.byType(ShareChip), findsNothing);
    expect(find.byIcon(Icons.link_rounded), findsNothing);
    expect(find.byIcon(Icons.ios_share_rounded), findsNothing);
    expect(find.text('Restore purchases'), findsOneWidget);
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
