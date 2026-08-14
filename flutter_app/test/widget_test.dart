/// A smoke test for the shell — and the reason this file has to exist.
///
/// `flutter create` writes a default test/widget_test.dart when there is not
/// one, and the one it writes builds `MyApp`. This app's root is `NowssbApp`,
/// so every CI run generated a file that could not compile and `flutter
/// analyze` failed before it ever reached the build. The APK job had never
/// once produced an APK.
///
/// flutter create leaves files that already exist alone, so claiming the name
/// with a real test fixes it permanently rather than by deleting a generated
/// file after the fact.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(FakeVideoPlatform.new);
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('the shell builds and every destination is reachable',
      (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: NavShell()));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);

    // The five destinations of #ig-bottomnav. Tapping each one must not throw
    // and must not overflow — the placeholders are as much a part of the app
    // as the home until they are ported.
    for (final label in ['Connect', 'Practice', 'Library', 'Store', 'Profile']) {
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: '$label threw');
    }
  });
}
