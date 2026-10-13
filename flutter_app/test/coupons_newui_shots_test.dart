// Phone-size screenshots of the newui Coupons page. Skipped unless
// COUPONS_SHOTS=<dir> is set; run with --update-goldens.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/coupons/coupon_models.dart';
import 'package:nowssb/pages/coupons/coupons_home_page.dart';

class _Repo implements CouponsRepo {
  _Repo(this.items, {this.fail});
  final List<NwCoupon> items;
  final Object? fail;
  @override
  Future<List<NwCoupon>> load() async {
    if (fail != null) throw fail!;
    return items;
  }

  @override
  Future<CouponCodeResult> addCode(String c) async => const CouponCodeResult(true, 'Coupon added');
}

const _items = [
  NwCoupon(id: 'a', label: 'Festive offer', offer: '20% OFF A WORD', scope: 'Cap ₹35. Does not stack.', code: 'NWSB-SAVE20', category: 'Words', isNew: true),
  NwCoupon(id: 'b', label: 'Special discount', offer: '15% OFF MEANINGS', scope: 'Cap ₹80. Catalogue, not cash.', code: 'NWSB-MEAN15', category: 'Meanings', rarity: CouponRarity.rare, isNew: true),
  NwCoupon(id: 'c', label: 'Special pass', offer: '3-DAY SIGNATURE', scope: 'Does not unlock Partner.', code: 'NWSB-SIG3', category: 'Subscriptions', rarity: CouponRarity.epic),
  NwCoupon(id: 'd', label: 'Special pass', offer: '30-DAY STANDARD', scope: 'Catalogue prize, not cash.', code: 'NWSB-STD30', category: 'Subscriptions', rarity: CouponRarity.legendary),
];

void main() {
  final out = Platform.environment['COUPONS_SHOTS'];
  final skip = out == null;

  Future<void> setup(WidgetTester t, CouponsRepo r) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      const d = '/workspace/flutter/bin/cache/artifacts/material_fonts';
      const b = '/workspace/flutter/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/Roboto';
      Future<ByteData> f(String p) async => ByteData.sublistView(File(p).readAsBytesSync());
      await (FontLoader('Roboto')
            ..addFont(f('$d/Roboto-Regular.ttf'))
            ..addFont(f('$d/Roboto-Medium.ttf'))
            ..addFont(f('$b/Roboto-Bold.ttf'))
            ..addFont(f('$d/Roboto-Black.ttf')))
          .load();
      await (FontLoader('MaterialIcons')..addFont(f('$d/MaterialIcons-Regular.otf'))).load();
    });
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
      home: CouponsHomePage(repo: r, banner: const _BannerStub(), onAllRewards: () {}, onScratch: () {}, animate: false),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
  }

  Future<void> shot(WidgetTester t, String n) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile('$out/coupons-$n.png'));

  testWidgets('1 home', (t) async {
    await setup(t, _Repo(_items));
    await shot(t, '1');
  }, skip: skip);

  testWidgets('2 home scrolled', (t) async {
    await setup(t, _Repo(_items));
    await t.drag(find.byType(ListView), const Offset(0, -600));
    await t.pumpAndSettle();
    await shot(t, '2');
  }, skip: skip);

  testWidgets('3 detail pop-up', (t) async {
    await setup(t, _Repo(_items));
    await t.scrollUntilVisible(find.text('20% OFF A WORD'), 200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('20% OFF A WORD'));
    await t.pumpAndSettle();
    await shot(t, '3');
  }, skip: skip);

  testWidgets('4 filter sheet', (t) async {
    await setup(t, _Repo(_items));
    await t.tap(find.text('Categories'));
    await t.pumpAndSettle();
    await t.tap(find.text('Words'));
    await t.pump();
    await shot(t, '4');
  }, skip: skip);

  testWidgets('5 empty', (t) async {
    await setup(t, _Repo(const []));
    await t.drag(find.byType(ListView), const Offset(0, -500));
    await t.pumpAndSettle();
    await shot(t, '5');
  }, skip: skip);

  testWidgets('6 offline', (t) async {
    await setup(t, _Repo(const [], fail: const CouponsOffline()));
    await t.drag(find.byType(ListView), const Offset(0, -500));
    await t.pumpAndSettle();
    await shot(t, '6');
  }, skip: skip);
}

/// Stand-in for the existing CouponBannerSection (needs app config/assets).
class _BannerStub extends StatelessWidget {
  const _BannerStub();
  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFF3A2A12), Color(0xFF1A140A)])),
        child: const Text('EXISTING COUPON BANNER', style: TextStyle(color: Color(0xFFF2C46B), fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      );
}
