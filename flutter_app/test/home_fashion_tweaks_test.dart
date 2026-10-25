import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/black_glass_banner.dart';
import 'fake_video_platform.dart';
import 'support/home_render.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });

  testWidgets(
      'Fashion: Make it yours heading + heavy practice banner, no overflow at 320@1.3',
      (t) async {
    t.view.physicalSize = const Size(320 * 1.3, 800 * 1.3);
    t.view.devicePixelRatio = 1.3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: NavScope(go: (_) {}, child: const HomeFashion())));
    final errors = <String>[];
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
      final e = t.takeException();
      if (e != null) errors.add('$e');
    }
    for (var step = 0; step < 40; step++) {
      if (find
              .byKey(const ValueKey('fash-herorow-heading'))
              .evaluate()
              .isNotEmpty &&
          find.byType(RoutineStyleBlackBanner).evaluate().isNotEmpty) {
        break;
      }
      await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await t.pump(const Duration(milliseconds: 200));
      final e = t.takeException();
      if (e != null) errors.add('$e');
    }
    if (homeFontsReady)
      expect(errors.where((e) => e.contains('overflow')), isEmpty);
    expect(find.text('Make it yours'), findsOneWidget);
    final b = t.widget<RoutineStyleBlackBanner>(
        find.byType(RoutineStyleBlackBanner).first);
    expect(b.heavy, isTrue);
  }, skip: !homeFontsReady); // needs real fonts, see support/home_render.dart
}
