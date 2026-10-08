/// Editing happens only in the admin UI Editor. The user app shows no
/// pencils, no floating Edit button, and no per-section "Edit" / "Pinch"
/// chips; the editor shows nothing on a page until a section is tapped,
/// then only a subtle highlight on that one section.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/admin_state.dart';
import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/glass.dart';
import 'package:nowssb/admin/editor/preview.dart';
import 'package:nowssb/admin/editor/ui_editor_screen.dart';
import 'package:nowssb/admin/layout/app_pages.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

const _screen = Size(412, 915);

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _noEditChrome() {
  expect(find.byIcon(Icons.edit_rounded), findsNothing, reason: 'no pencils');
  expect(find.byIcon(Icons.movie_edit), findsNothing);
  expect(find.byTooltip('Edit layout (hold for Admin)'), findsNothing, reason: 'no floating Edit button');
  expect(find.text('Edit'), findsNothing, reason: 'no Edit chip on sections');
  expect(find.textContaining('Pinch '), findsNothing, reason: 'no Pinch 1.00× chip');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  tearDown(VideoPool.instance.debugDropAll);

  for (final id in ['home.normal', 'store.home', 'profile']) {
    testWidgets('the user app ($id) renders no edit affordances', (tester) async {
      SharedPreferences.setMockInitialValues({'nwsb_admin_edit_fab': true});
      tester.view.physicalSize = _screen * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final onError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (!d.toString().contains('overflowed by')) onError?.call(d);
      };
      addTearDown(() => FlutterError.onError = onError);
      await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: appPage(id)!.build())));
      await _settle(tester, 10);
      _noEditChrome();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }

  test('the old pencil / floating Edit flag is cleaned up', () async {
    SharedPreferences.setMockInitialValues({'nwsb_admin_edit_fab': true, 'other': 1});
    await dropLegacyEditPrefs();
    final p = await SharedPreferences.getInstance();
    expect(p.containsKey('nwsb_admin_edit_fab'), isFalse);
    expect(p.getInt('other'), 1);
  });

  test('no code path left for pencils or a floating Edit button', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final s = f.readAsStringSync();
      for (final w in ['EditMode', 'editModeOn', 'SlotBadge', 'AdminEditFab', 'Pencils on', 'Floating Edit']) {
        if (s.contains(w)) hits.add('${f.path}: $w');
      }
    }
    expect(hits, isEmpty);
  });

  group('the editor', () {
    setUp(() => SharedPreferences.setMockInitialValues({kTouchHintSeen: true}));

    testWidgets('idle: no outlines or chips on any section; a tap: one subtle highlight', (tester) async {
      tester.view.physicalSize = _screen * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final c = EditorController();
      await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: UiEditorScreen(controller: c))));
      await _settle(tester, 8);
      _noEditChrome();
      expect(find.byKey(const ValueKey('section-outline')), findsNothing, reason: 'nothing until a tap');
      Iterable<BoxDecoration> goldBoxes() => tester
          .widgetList<DecoratedBox>(find.descendant(of: find.byType(EditorPreview), matching: find.byType(DecoratedBox)))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border is Border && (d.border as Border).top.color.toARGB32() & 0xFFFFFF == kGold.toARGB32() & 0xFFFFFF);
      expect(goldBoxes(), isEmpty);

      // Tap one section.
      final id = c.sections.firstWhere((s) {
        final b = c.preview.sectionBoxes['${c.layoutPage}/${s.id}'];
        return b != null && b.attached && b.size.height > 80 && b.localToGlobal(Offset.zero).dy > 60;
      }).id;
      final box = c.preview.sectionBoxes['${c.layoutPage}/$id']!;
      final r = box.localToGlobal(Offset.zero) & box.size;
      await tester.tapAt(Offset(r.right - 6, r.center.dy));
      await _settle(tester, 4);
      final choose = find.byKey(const ValueKey('choose-section'));
      if (choose.evaluate().isNotEmpty) {
        await tester.tap(choose);
        await _settle(tester, 4);
      }
      expect(c.sectionPicked, isTrue);
      final outline = find.byKey(const ValueKey('section-outline'));
      expect(outline, findsOneWidget);
      final d = tester
          .widget<DecoratedBox>(find.descendant(of: outline, matching: find.byType(DecoratedBox)))
          .decoration as BoxDecoration;
      final edge = (d.border as Border).top;
      expect(edge.width, lessThanOrEqualTo(1.5), reason: 'subtle');
      expect(edge.color.a, lessThan(0.6));
      expect(goldBoxes().length, 1, reason: 'only that one section, no element boxes');
      _noEditChrome();
      expect(find.byKey(const ValueKey('strip-delete')), findsOneWidget, reason: 'its labelled Delete');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });
}
