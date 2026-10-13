import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/coupons/coupon_models.dart';
import 'package:nowssb/pages/coupons/coupons_home_page.dart';

class FakeRepo implements CouponsRepo {
  FakeRepo({this.items = const [], this.fail, this.code = const CouponCodeResult(true, 'Coupon added')});
  List<NwCoupon> items;
  Object? fail;
  CouponCodeResult code;
  Completer<void>? gate;
  int loads = 0;

  @override
  Future<List<NwCoupon>> load() async {
    loads++;
    if (gate != null) await gate!.future;
    if (fail != null) throw fail!;
    return items;
  }

  @override
  Future<CouponCodeResult> addCode(String c) async => code;
}

const _a = NwCoupon(id: 'a', label: 'Special discount', offer: '20% OFF A WORD', scope: 'Cap 35', code: 'NWSB-SAVE20', category: 'Words', isNew: true);
const _b = NwCoupon(id: 'b', label: 'Special pass', offer: '7-DAY EBOOK', scope: 'After trial', code: 'NWSB-EBOOK7', category: 'E-books', rarity: CouponRarity.epic);

Future<void> _pump(WidgetTester t, CouponsRepo r) async {
  t.view.physicalSize = const Size(390 * 3, 844 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: CouponsHomePage(repo: r, banner: const SizedBox(height: 40, child: Text('BANNER')), onAllRewards: () {}, onScratch: () {}, animate: false),
  ));
}

void main() {
  testWidgets('loading state', (t) async {
    final r = FakeRepo(items: [_a])..gate = Completer();
    await _pump(t, r);
    await t.pump();
    expect(find.byKey(const Key('coupons-loading')), findsOneWidget);
    r.gate!.complete();
    await t.pump();
    await t.pump();
    expect(find.text('20% OFF A WORD'), findsOneWidget);
  });

  testWidgets('empty state', (t) async {
    await _pump(t, FakeRepo());
    await t.pump();
    expect(find.byKey(const Key('coupons-empty')), findsOneWidget);
    expect(find.text('You have 0 new coupons'), findsOneWidget);
  });

  testWidgets('error state retries', (t) async {
    final r = FakeRepo(fail: Exception('x'));
    await _pump(t, r);
    await t.pump();
    expect(find.byKey(const Key('coupons-error')), findsOneWidget);
    r.fail = null;
    r.items = [_a];
    await t.drag(find.byType(ListView), const Offset(0, -400));
    await t.pump();
    await t.tap(find.text('Try again'));
    await t.pump();
    await t.pump();
    expect(r.loads, 2);
    expect(find.text('20% OFF A WORD'), findsOneWidget);
  });

  testWidgets('offline state', (t) async {
    await _pump(t, FakeRepo(fail: const CouponsOffline()));
    await t.pump();
    expect(find.byKey(const Key('coupons-offline')), findsOneWidget);
  });

  testWidgets('list, hero count, banner, detail pop-up', (t) async {
    await _pump(t, FakeRepo(items: [_a, _b]));
    await t.pump();
    expect(find.text('BANNER'), findsOneWidget);
    expect(find.text('You have 1 new coupons'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    await t.scrollUntilVisible(find.text('20% OFF A WORD'), 200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('20% OFF A WORD'));
    await t.pumpAndSettle();
    expect(find.text('Coupon details'), findsOneWidget);
    expect(find.text('NWSB-SAVE20'), findsOneWidget);
    expect(find.text('Apply now'), findsOneWidget);
    await t.tap(find.text('Apply now'));
    await t.pumpAndSettle();
    expect(find.text('Coupon details'), findsNothing);
  });

  testWidgets('category filter', (t) async {
    await _pump(t, FakeRepo(items: [_a, _b]));
    await t.pump();
    await t.tap(find.text('Categories'));
    await t.pumpAndSettle();
    await t.tap(find.text('E-books'));
    await t.pump();
    await t.tap(find.text('Show coupons'));
    await t.pumpAndSettle();
    expect(find.text('7-DAY EBOOK'), findsOneWidget);
    expect(find.text('20% OFF A WORD'), findsNothing);
  });

  testWidgets('code field: empty, success, error', (t) async {
    final r = FakeRepo(items: [_a]);
    await _pump(t, r);
    await t.pump();
    await t.tap(find.text('Add coupon'));
    await t.pump();
    expect(find.text('Type a coupon code first.'), findsOneWidget);
    await t.enterText(find.byKey(const Key('coupon-code')), 'SAVE20');
    await t.tap(find.text('Add coupon'));
    await t.pump();
    await t.pump();
    expect(find.text('Coupon added'), findsOneWidget);
    r.code = const CouponCodeResult(false, 'That code is not valid.');
    await t.enterText(find.byKey(const Key('coupon-code')), 'BAD');
    await t.tap(find.text('Add coupon'));
    await t.pump();
    await t.pump();
    expect(find.text('That code is not valid.'), findsOneWidget);
  });
}
