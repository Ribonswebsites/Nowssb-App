/// The UI Editor screen end to end on the Normal home: the full-screen page
/// reports its sections (with the screen no longer rebuilding it on every
/// change), and a picked section dragged down the page moves down it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/ui_editor_screen.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The one-time touch hint has been seen (it has its own test).
  SharedPreferences.setMockInitialValues({kTouchHintSeen: true});

  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('editor reports sections; a picked section dragged down moves down the page', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final c = EditorController();
    await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: UiEditorScreen(controller: c))));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    final n = c.sections.length;
    expect(n, greaterThan(3), reason: 'the page reported its sections');

    Rect? rect(String id) {
      final b = c.preview.sectionBoxes['${c.layoutPage}/$id'];
      if (b == null || !b.attached) return null;
      return b.localToGlobal(Offset.zero) & b.size;
    }

    // The first two sections on screen: drag the first onto the second.
    final onScreen = [
      for (final s in c.sections)
        if (rect(s.id) case final r? when r.height > 40 && r.bottom < 800) s.id,
    ];
    expect(onScreen.length, greaterThanOrEqualTo(2));
    final first = onScreen[0];
    final second = onScreen[1];
    c.pickSection(first);
    await tester.pump(const Duration(milliseconds: 100));
    final from = rect(first)!.center;
    final to = rect(second)!.center + const Offset(0, 4);
    final g = await tester.startGesture(from);
    for (var i = 1; i <= 12; i++) {
      await g.moveTo(Offset.lerp(from, to, i / 12)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    final ids = [for (final s in c.sections) if (!s.entry.deleted) s.id];
    expect(ids.indexOf(first), ids.indexOf(second) + 1, reason: 'it now sits after the one it was dropped on');
    expect(c.current!.id, first, reason: 'it stays picked');
    expect(c.sections.length, n);
  });
}
