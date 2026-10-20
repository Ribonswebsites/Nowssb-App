import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/coupons/coupon_pages.dart';
import 'package:nowssb/features/economy/coupon_tickets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget Function(BuildContext) b) => MaterialApp(home: Scaffold(body: Builder(builder: (c) => Center(child: b(c)))));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('How It Works: Next through 4 slides, Got it closes', (t) async {
    await t.pumpWidget(_host((c) => ElevatedButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const CouponHowItWorks())), child: const Text('open'))));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      expect(find.text('Next'), findsOneWidget);
      await t.tap(find.byKey(const Key('hiw_next')));
      await t.pumpAndSettle();
    }
    expect(find.text('Got it'), findsOneWidget);
    await t.tap(find.byKey(const Key('hiw_next')));
    await t.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Terms page lists rules without a rupee sign', (t) async {
    await t.pumpWidget(const MaterialApp(home: CouponTermsPage()));
    expect(find.text('ONE PER ORDER'), findsOneWidget);
    expect(find.textContaining('₹'), findsNothing);
  });

  testWidgets('Coupon Detail shows code, terms button opens Terms', (t) async {
    final d = kWideCoupons.first;
    await t.pumpWidget(_host((c) => ElevatedButton(onPressed: () => showCouponDetail(c, d), child: const Text('open'))));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text(d.copy), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('detail_terms')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('detail_terms')));
    await t.pumpAndSettle();
    expect(find.byType(CouponTermsPage), findsOneWidget);
  });

  testWidgets('Apply sheet: pick a coupon, close with X', (t) async {
    await t.pumpWidget(_host((c) => ElevatedButton(onPressed: () => showApplyCoupon(c), child: const Text('open'))));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('apply_${kWideCoupons[1].code}')));
    await t.pump();
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    await t.tap(find.byKey(const Key('sheet_close')));
    await t.pumpAndSettle();
    expect(find.text('Apply a coupon'), findsNothing);
  });

  testWidgets('Button guide: Next through steps to Done; Skip ends it', (t) async {
    await t.pumpWidget(_host((c) => ElevatedButton(onPressed: () => showCouponButtonGuide(c), child: const Text('open'))));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);
    await t.tap(find.byKey(const Key('guide_next')));
    await t.pumpAndSettle();
    expect(find.text('2 / 5'), findsOneWidget);
    await t.tap(find.byKey(const Key('guide_skip')));
    await t.pumpAndSettle();
    expect(find.text('2 / 5'), findsNothing);
  });

  testWidgets('First use runs once', (t) async {
    await t.pumpWidget(_host((c) => ElevatedButton(onPressed: () => runCouponsFirstUse(c), child: const Text('open'))));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.byType(CouponHowItWorks), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('coupons_howitworks_seen'), true);
  });

  test('coupon tickets carry no rupee amounts', () {
    for (final d in kWideCoupons) {
      expect(d.line.contains('₹'), false, reason: d.code);
    }
  });
}
