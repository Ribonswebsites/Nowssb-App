// B004: the home subscription teaser shows Play's prices (buyer's currency),
// like the Subscription screen, never hard-coded USD.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nowssb/data/billing_config.dart';
import 'package:nowssb/data/play_subscriptions.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/shared_sections.dart';

import 'fake_video_platform.dart';

ProductDetails _p(String id, String price) =>
    ProductDetails(id: id, title: id, description: '', price: price, rawPrice: 0, currencyCode: 'INR');

void setPlayInr() => PlaySubscriptions.instance.debugSetProducts([
      _p(kResonanceMonthly, '₹249.00'),
      _p(playPlanFor('frequency', yearly: false)!.productId, '₹499.00'),
      _p(playPlanFor('frequencyX', yearly: false)!.productId, '₹999.00'),
    ]);

void main() {
  setUp(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  testWidgets('teaser tiers show Play prices, no hard-coded USD', (t) async {
    PlaySubscriptions.instance.debugSetProducts(const []);
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: SubscriptionSection()))));
    await t.pump();
    expect(find.textContaining(r'$'), findsNothing);
    expect(find.text('Price on Google Play'), findsNWidgets(3));

    setPlayInr();
    await t.pump();
    expect(find.text('₹249.00 / month'), findsOneWidget);
    expect(find.text('₹499.00 / month'), findsOneWidget);
    expect(find.text('₹999.00 / month'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(minutes: 1));
  });

  for (final (w, scale) in [(390.0, 1.0), (320.0, 1.3)]) {
    testWidgets('tier names show whole at ${w.toInt()} x$scale', (t) async {
      setPlayInr();
      t.view.physicalSize = Size(w, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(size: Size(w, 1400), textScaler: TextScaler.linear(scale)),
              child: const Scaffold(body: SingleChildScrollView(child: SubscriptionSection())))));
      await t.pump(const Duration(milliseconds: 900));
      expect(t.takeException(), isNull);
      for (final n in ['Free', 'Resonance', 'Frequency', 'Frequency X']) {
        final name = find.text(n).first;
        final price = find.textContaining('NowssB Edition').evaluate().isNotEmpty && n == 'Free'
            ? find.text('NowssB Edition').first
            : find.textContaining('/ month').first;
        // Same ancestors as the line under it: no sway that slides it out
        // of its own clip.
        int moves(Finder f) => find.ancestor(of: f, matching: find.byType(Transform)).evaluate().length;
        int clips(Finder f) => find.ancestor(of: f, matching: find.byType(ClipRect)).evaluate().length;
        expect(moves(name), moves(price), reason: n);
        expect(clips(name), clips(price), reason: n);
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 1));
    });
  }
}
