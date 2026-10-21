import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/header.dart';
import 'package:nowssb/screens/store.dart';
import 'package:nowssb/screens/store/store_first_use_guide.dart';
import 'package:nowssb/screens/store/store_luxe.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({StoreFirstUseGuide.prefKey('store_home'): true});
    VideoPool.instance.debugDropAll();
  });

  testWidgets('Store home: Home header, gold category tabs and Spotlight Picks', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: StoreScreen()));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(HomeHeader), findsOneWidget);
    expect(find.byType(StoreCategoryTabs), findsOneWidget);
    for (final l in ['All', 'Words', 'Meanings']) {
      expect(find.bySemanticsLabel(l), findsWidgets, reason: l);
    }
    expect(find.text('Spotlight Picks'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Word Atelier.*Shop now')), findsOneWidget);
    final src = File('lib/screens/store.dart').readAsStringSync();
    expect(src, contains("'assets/video/normal-glass-background.mp4'"), reason: 'Home background video');
    await expectLater(find.byType(StoreScreen), matchesGoldenFile('goldens/store-style-1.png'));
    await t.drag(find.byType(ListView).first, const Offset(0, -700));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    await expectLater(find.byType(StoreScreen), matchesGoldenFile('goldens/store-style-2.png'));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('Category tab opens its department', (t) async {
    var opened = '';
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StoreCategoryTabs(categories: [
          const StoreCategory('All', null),
          StoreCategory('Words', () => opened = 'words'),
        ]),
      ),
    ));
    await t.tap(find.text('Words'));
    expect(opened, 'words');
  });
}
