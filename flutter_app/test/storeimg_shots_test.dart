// Store art: the shelf thumbnails and Drop Studio show the NowssB Store box /
// word frames only, never a person cut-out.
// STOREIMG_SHOTS=<dir> also writes the shots.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/drop_studio.dart';
import 'package:nowssb/screens/normal/home_v5.dart';
import 'package:nowssb/screens/store/store_art.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _out = String.fromEnvironment('STOREIMG_SHOTS');

void main() {
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });

  test('product art never shows a figure', () {
    for (final f in [
      'assets/hero-curve/cleopatra.webp',
      'assets/hero-curve/subject.webp',
      'assets/hero-curve/tab-subject.webp',
      'assets/hero-curve/pointer.webp',
      'assets/banners/promo/split-blonde-blazer.png',
    ]) {
      expect(productArt(f), kNowssbStoreMark, reason: f);
      expect(BagItem(id: 'a', title: 'a', subtitle: '', image: f, price: 1, kind: 'Word').image, kNowssbStoreMark);
    }
    expect(productArt('assets/store/words/calm.webp'), 'assets/store/words/calm.webp');
    expect(storeWordFrame('Calm'), 'assets/store/words/calm.webp');
    expect(storeWordFrame('zzz-unknown'), kNowssbStoreMark);
  });

  final key = GlobalKey();
  Future<void> shot(WidgetTester t, String name) async {
    if (_out.isEmpty) return;
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final im = await b.toImage(pixelRatio: 2);
      final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
      Directory(_out).createSync(recursive: true);
      File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> boot(WidgetTester t, Widget home, {double h = 844, bool dark = true}) async {
    t.view.physicalSize = Size(390 * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
      await CartBag.instance.load();
    });
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans', brightness: dark ? Brightness.dark : Brightness.light),
        home: NavScope(go: (_) {}, child: home),
      ),
    ));
    for (var i = 0; i < 12; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('On one shelf: the store box only', (t) async {
    SharedPreferences.setMockInitialValues({});
    NormalLoop.debugT = .4;
    addTearDown(() => NormalLoop.debugT = null);
    await t.runAsync(() => CartBag.instance.load());
    for (final f in ['assets/hero-curve/cleopatra.webp', 'assets/hero-curve/subject.webp', 'assets/store/words/calm.webp']) {
      await t.runAsync(() => CartBag.instance.addCart(BagItem(id: f, title: 'x', subtitle: '', image: f, price: 9, kind: 'Word')));
    }
    await boot(t, Scaffold(backgroundColor: const Color(0xFFEFF1F8), body: Center(child: V5Own(onCart: () {}, onWishlist: () {}, onOrders: () {}))), h: 330, dark: false);
    await shot(t, 'on-one-shelf');
    expect(find.byType(V5Own), findsOneWidget);
  });

  testWidgets('Drop Studio top', (t) async {
    SharedPreferences.setMockInitialValues({});
    await boot(t, const DropStudioScreen());
    await shot(t, 'drop-studio-top');
  });

  testWidgets('Drop Studio word deck', (t) async {
    SharedPreferences.setMockInitialValues({});
    await boot(t, const DropStudioScreen());
    await t.drag(find.byType(Scrollable).first, const Offset(0, -560));
    await t.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < 6; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 100));
    }
    await shot(t, 'drop-studio-deck');
  });
}
