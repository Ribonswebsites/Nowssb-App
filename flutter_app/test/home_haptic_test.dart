/// The Normal home must stay quiet until a finger actually does something.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/app_haptics.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

List<String> _haptics(WidgetTester t) {
  final calls = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (c) async {
      if (c.method == 'HapticFeedback.vibrate') calls.add('${c.arguments}');
      return null;
    },
  );
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FakeVideoPlatform();
    // Deadlines own real Timers; this file runs on a fake clock.
    VideoPool.debugDeadlines = false;
  });
  setUp(() async {
    VideoPool.instance.debugDropAll();
    SharedPreferences.setMockInitialValues({});
    AppHaptics.debugReset();
    await AppHaptics.preload();
    AppHaptics.debugEnabled(true);
  });
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets(
    'normal home does not buzz on its own, then buzzes once on a tap',
    (t) async {
      t.view.physicalSize = const Size(412 * 3, 900 * 3);
      t.view.devicePixelRatio = 3.0;
      addTearDown(t.view.reset);

      final h = _haptics(t);
      await t.pumpWidget(
        MaterialApp(
          home: NavScope(go: (_) {}, child: const HomeNormal()),
        ),
      );
      await t.pump();
      // The Today's word carousel auto-advances every 6 seconds. Other
      // home rails also tick. Let all of that run with no finger input.
      await t.pump(const Duration(seconds: 6));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 3));
      expect(h, isEmpty,
          reason: 'auto-rotate, timers and rebuilds must stay quiet');

      final today = find.byKey(const ValueKey('today-progress-button'));
      expect(today, findsOneWidget);
      await t.tap(today);
      await t.pump();
      expect(h, hasLength(1));
    },
  );
}
