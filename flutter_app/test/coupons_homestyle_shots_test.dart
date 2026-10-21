import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/coupons/coupon_home_style.dart';
import 'package:nowssb/features/coupons/coupon_pages.dart';
import 'package:nowssb/features/economy/coupon_tickets.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _key = GlobalKey();

Future<void> _shot(WidgetTester t, String name) async {
  final dir = Platform.environment['COUPON_SHOTS'];
  if (dir == null) return;
  await t.runAsync(() async {
    final b = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Widget _phone(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (_, nav) => RepaintBoundary(key: _key, child: ColoredBox(color: const Color(0xFF08090B), child: nav)),
      home: child,
    );

Future<void> _fonts() async {
  const dir = '/workspace/flutter/bin/cache/artifacts/material_fonts';
  if (!Directory(dir).existsSync()) return;
  Future<void> load(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.view(File('$dir/$f').readAsBytesSync().buffer)));
    }
    await l.load();
  }
  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf', 'Roboto-Light.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

void main() {
  setUpAll(() async {
    if (Platform.environment['COUPON_SHOTS'] != null) await _fonts();
  });
  setUp(() => SharedPreferences.setMockInitialValues({'coupons_howitworks_seen': true}));

  Future<void> phone(WidgetTester t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  testWidgets('coupon list in Today\'s offer style opens detail', (t) async {
    await phone(t);
    WideCouponData? opened;
    var shop = 0;
    await t.pumpWidget(_phone(CouponSubPage(
      title: 'NowssB Coupons',
      body: ListView(padding: const EdgeInsets.all(16), children: [
        CouponOfferSection(onDetail: (d) => opened = d, onShop: () => shop++),
      ]),
    )));
    await t.pumpAndSettle();
    expect(find.text('Today’s coupons'), findsOneWidget);
    expect(find.text(kWideCoupons.first.banner.toUpperCase()), findsOneWidget);
    expect(find.textContaining('₹'), findsNothing);
    await _shot(t, 'coupons-1');
    await t.tap(find.byKey(Key('details_${kWideCoupons.first.code}')));
    expect(opened, kWideCoupons.first);
    await t.scrollUntilVisible(find.byKey(const Key('coupons_shop_now')), 300);
    await t.pumpAndSettle();
    await _shot(t, 'coupons-2');
    await t.tap(find.byKey(const Key('coupons_shop_now')));
    expect(shop, 1);
  });

  testWidgets('coupon detail: timeline, copy, apply pill, terms', (t) async {
    await phone(t);
    final d = kWideCoupons.first;
    await t.pumpWidget(_phone(Scaffold(backgroundColor: Colors.transparent, body: Builder(builder: (c) => Center(child: ElevatedButton(onPressed: () => showCouponDetail(c, d), child: const Text('open')))))));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text(d.copy.toUpperCase()), findsOneWidget);
    expect(find.text('Apply now'), findsOneWidget);
    expect(find.text('APPLIES TO'), findsOneWidget);
    await _shot(t, 'coupons-3');
    await t.ensureVisible(find.byKey(const Key('detail_terms')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('detail_terms')));
    await t.pumpAndSettle();
    expect(find.byType(CouponTermsPage), findsOneWidget);
    await _shot(t, 'coupons-4');
  });

  testWidgets('hub sub-page uses Home top bar and back works', (t) async {
    await phone(t);
    await t.pumpWidget(_phone(Builder(builder: (c) => Center(child: ElevatedButton(onPressed: () => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const CouponTermsPage())), child: const Text('open'))))));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sub_back')));
    await t.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
