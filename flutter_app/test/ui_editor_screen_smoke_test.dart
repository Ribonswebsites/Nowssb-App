/// The UI Editor screen end to end on the Normal home: the preview reports
/// its sections (with the screen no longer rebuilding it on every change),
/// and a drag in Layout reorders the page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/preview.dart';
import 'package:nowssb/admin/editor/ui_editor_screen.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('editor preview reports sections; a Layout drag reorders the page', (tester) async {
    // Wide enough for the top bar's pending-changes pill in the test font.
    tester.view.physicalSize = const Size(640 * 3, 1000 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: const UiEditorScreen())));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    final first = find.textContaining(RegExp(r'^Section 1 of \d+$'));
    expect(first, findsOneWidget, reason: 'the page reported its sections');
    final n = int.parse(RegExp(r'of (\d+)').firstMatch(tester.widget<Text>(first).data!)!.group(1)!);
    expect(n, greaterThan(3));

    // Layout tab: drag the first section down; it moves down the page.
    await tester.tap(find.text('Layout').last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final pv = find.byKey(const ValueKey('pv-home.normal'));
    expect(pv, findsOneWidget);
    // The phone picture is drawn scaled down: 3.5 places' worth of phone
    // points on screen moves the section 3 places.
    final scale = tester.getSize(pv).height / 952;
    await tester.timedDrag(pv, Offset(0, kShiftStep * 3.5 * scale), const Duration(milliseconds: 600));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Section 4 of $n'), findsOneWidget, reason: 'moved down 3 places and the preview followed it');
  });
}
