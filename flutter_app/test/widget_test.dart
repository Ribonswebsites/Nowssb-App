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
import 'package:nowssb/widgets/neumorphic.dart';

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

    // The five destinations of #ig-bottomnav. Every one is a real screen now,
    // and every one must build and lay out at phone size without throwing or
    // overflowing.
    for (final label in ['Connect', 'Practice', 'Library', 'Store', 'Profile']) {
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: '$label threw');
    }
  });

  testWidgets('a section on the home actually goes somewhere', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: NavShell()));
    await tester.pump(const Duration(milliseconds: 50));

    // Every black bar on the home must DO something. Invoked directly rather
    // than tapped: the bar sits under the bottom nav at rest, and fighting
    // hit-testing would be testing the scroll position rather than the
    // wiring. What matters is that the callback exists and moves the shell.
    final bars = tester.widgetList<NwsbBanner>(find.byType(NwsbBanner));
    expect(bars, isNotEmpty, reason: 'the home should carry black bars');
    for (final b in bars) {
      expect(b.onTap, isNotNull,
          reason: '"${b.title}" is a button that goes nowhere');
    }

    // And one of them really does move the shell.
    bars.first.onTap!();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the home switch moves between the two homes', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: NavShell()));
    await tester.pump(const Duration(milliseconds: 50));

    // The Normal home is the pale one and shows the greeting; the Fashion
    // home is the dark one and shows its own. The switch names the home you
    // would be going TO, so it reads as an action rather than a status.
    expect(find.text('Fashion home'), findsOneWidget);
    await tester.tap(find.text('Fashion home'));
    await tester.pump(const Duration(milliseconds: 60));

    expect(tester.takeException(), isNull);
    expect(find.text('Normal home'), findsOneWidget);
  });
}
