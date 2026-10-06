/// The touch-only editor: undo/redo, Put back, and on the real editor
/// screen — drag onto the trash, long-press menu, the section's edges,
/// pinch, effects dropped from the drawer, and the one-time hint.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/ui_editor_screen.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

EditorController _controller(String page, List<SectionEntry> entries) {
  final c = EditorController()..pageId = page;
  c.preview.reported[page] = [for (final e in entries) SectionInfo(e.id, e.id, e)];
  return c;
}

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The editor on the Normal home with [c]; returns the section count.
Future<int> _open(WidgetTester tester, EditorController c) async {
  tester.view.physicalSize = const Size(640 * 3, 1000 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: UiEditorScreen(controller: c))));
  await _settle(tester, 10);
  expect(tester.takeException(), isNull);
  return c.sections.length;
}

/// Where the current section's content is on screen.
Rect _sectionRect(EditorController c) {
  final box = c.preview.sectionBoxes['${c.layoutPage}/${c.current!.id}']!;
  return box.localToGlobal(Offset.zero) & box.size;
}

int _live(EditorController c) => c.sections.where((s) => !s.entry.deleted).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('undo / redo', () {
    test('every change can be undone and redone', () {
      final c = _controller('u', const [SectionEntry(id: 'a'), SectionEntry(id: 'b')]);
      addTearDown(c.dispose);
      expect(c.canUndo, isFalse);
      c.patchProps('a', {'height': 300});
      c.endStep();
      c.delete('b');
      expect(c.canUndo, isTrue);
      expect(c.entries.last.deleted, isTrue);
      c.undo();
      expect(c.entries.last.deleted, isFalse);
      expect(c.entries.first.props['height'], 300);
      c.undo();
      expect(c.pendingCount, 0, reason: 'back to nothing changed');
      expect(c.canUndo, isFalse);
      c.redo();
      expect(c.entries.first.props['height'], 300);
      c.redo();
      expect(c.entries.last.deleted, isTrue);
      expect(c.canRedo, isFalse);
    });

    test('a gesture\'s many updates are one step; a new edit drops redo', () {
      final c = _controller('u2', const [SectionEntry(id: 'a')]);
      addTearDown(c.dispose);
      for (var h = 100; h <= 200; h += 10) {
        c.patchProps('a', {'height': h});
      }
      c.endStep();
      c.undo();
      expect(c.pendingCount, 0);
      c.redo();
      expect(c.entries.first.props['height'], 200);
      c.undo();
      c.patchProps('a', {'padTop': 8});
      expect(c.canRedo, isFalse);
    });

    test('Put back clears size, place and spacing in one step', () {
      final c = _controller('u3', const [
        SectionEntry(id: 'a', props: {'height': 300, 'dx': 4, 'padTop': 12, 'padH': 8, 'fit': 'contain', 'entrance': 'fade'}),
      ]);
      addTearDown(c.dispose);
      c.putBack('a');
      expect(c.entries.first.props, {'entrance': 'fade'}, reason: 'effects are not size or place');
      c.undo();
      expect(c.entries.first.props['height'], 300);
    });
  });

  group('on the editor screen', () {
    setUpAll(() {
      FakeVideoPlatform();
      VideoPool.debugDeadlines = false;
    });
    setUp(() {
      SharedPreferences.setMockInitialValues({kTouchHintSeen: true});
      VideoPool.instance.debugDropAll();
    });
    tearDown(VideoPool.instance.debugDropAll);

    testWidgets('drag a section onto the trash: deleted, with Undo', (tester) async {
      final c = EditorController();
      final n = await _open(tester, c);
      final pv = tester.getRect(find.byKey(const ValueKey('pv-home.normal')));
      final from = _sectionRect(c).center;
      final g = await tester.startGesture(from);
      // Down to the bottom of the phone, where the trash shows.
      for (var i = 1; i <= 12; i++) {
        await g.moveTo(Offset(from.dx, from.dy + (pv.bottom - 30 - from.dy) * i / 12));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byIcon(Icons.delete_rounded), findsOneWidget, reason: 'the trash shows while dragging');
      await g.up();
      await _settle(tester);
      expect(find.textContaining('Deleted “'), findsOneWidget);
      expect(_live(c), n - 1);
      await tester.tap(find.text('Undo'));
      await _settle(tester);
      expect(_live(c), n);
      expect(c.canRedo, isTrue);
    });

    testWidgets('long-press shows the short menu; Hide works', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      await tester.longPressAt(_sectionRect(c).center);
      await _settle(tester, 4);
      for (final t in ['Put back', 'Hide', 'Delete']) {
        expect(find.text(t), findsOneWidget);
      }
      await tester.tap(find.text('Hide'));
      await _settle(tester);
      expect(c.current!.entry.visible, isFalse);
      c.undo();
      await _settle(tester);
      expect(c.current!.entry.visible, isTrue);
    });

    testWidgets('drag the top edge for space above; pinch to resize', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      final r = _sectionRect(c);
      await tester.timedDragFrom(Offset(r.center.dx, r.top + 2), const Offset(0, 60), const Duration(milliseconds: 400));
      await _settle(tester);
      final pad = c.current!.entry.props['padTop'];
      expect(pad, isA<num>());
      expect(pad as num, greaterThan(20));
      expect(c.sections.indexOf(c.current!), 0, reason: 'an edge drag does not move the section');

      final before = c.preview.sectionHeights['${c.layoutPage}/${c.current!.id}']!;
      final mid = _sectionRect(c).center;
      final a = await tester.startGesture(mid - const Offset(0, 20), pointer: 7);
      final b = await tester.startGesture(mid + const Offset(0, 20), pointer: 8);
      for (var i = 1; i <= 10; i++) {
        await a.moveTo(mid - Offset(0, 20 + 4.0 * i));
        await b.moveTo(mid + Offset(0, 20 + 4.0 * i));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await a.up();
      await b.up();
      await _settle(tester);
      final h = c.current!.entry.props['height'] as num;
      expect(h, greaterThan(before * 1.5), reason: 'pinching apart makes it bigger');
    });

    testWidgets('an effect dragged from the drawer lands on the section', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      await tester.tap(find.text('Animation').last);
      await _settle(tester, 6);
      final tile = tester.getCenter(find.text('Fade up'));
      final to = tester.getCenter(find.byKey(const ValueKey('pv-home.normal')));
      final g = await tester.startGesture(tile, kind: PointerDeviceKind.touch);
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 1; i <= 10; i++) {
        await g.moveTo(Offset.lerp(tile, to, i / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _settle(tester);
      expect(c.current!.entry.props['entrance'], 'fadeUp');
    });
  });

  testWidgets('the touch hint shows once and any touch dismisses it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final c = EditorController();
    await _open(tester, c);
    expect(find.text('Touch anywhere to start'), findsOneWidget);
    for (final t in ['to select', 'to move', 'to resize', 'to add']) {
      expect(find.textContaining(t, findRichText: true), findsOneWidget);
    }
    await tester.tapAt(const Offset(20, 900));
    await _settle(tester, 2);
    expect(find.text('Touch anywhere to start'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kTouchHintSeen), isTrue);
    VideoPool.instance.debugDropAll();
  });
}
