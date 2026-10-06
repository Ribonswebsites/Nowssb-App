/// The touch-only, full-screen editor: undo/redo, Put back, and on the real
/// editor screen — the page edge to edge with nothing permanent on it but a
/// small pill and +, the + drawer, picking a section, drag onto the trash,
/// long-press menu, the section's edges, pinch, effects dropped from the
/// drawer (applied and played, on a section or the picked element), orbs
/// and library animations placed / moved / pinched / trashed / re-inked,
/// elements moved / resized / removed, and the one-time hint.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/preview.dart';
import 'package:nowssb/admin/editor/tab_animation.dart' show DragTile;
import 'package:nowssb/admin/editor/ui_editor_screen.dart';
import 'package:nowssb/admin/layout/anims/anim_library.dart';
import 'package:nowssb/admin/layout/anims/effects.dart';
import 'package:nowssb/admin/layout/placed_orbs.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';
import 'package:nowssb/admin/template/slot_keys.dart';
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

const _screen = Size(412, 915);

/// The editor on the Normal home with [c], on a phone-sized screen;
/// returns the section count.
Future<int> _open(WidgetTester tester, EditorController c) async {
  tester.view.physicalSize = _screen * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: UiEditorScreen(controller: c))));
  await _settle(tester, 10);
  expect(tester.takeException(), isNull);
  return c.sections.length;
}

/// Where a section (default: the current one) is on screen.
Rect _sectionRect(EditorController c, [String? id]) {
  final box = c.preview.sectionBoxes['${c.layoutPage}/${id ?? c.current!.id}']!;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Picks the first section that is on screen and tall enough to grab.
String _pickFirst(EditorController c) {
  final s = c.sections.firstWhere((s) {
    final b = c.preview.sectionBoxes['${c.layoutPage}/${s.id}'];
    return b != null && b.attached && b.size.height > 80 && (b.localToGlobal(Offset.zero).dy) < 500;
  });
  c.pickSection(s.id);
  return s.id;
}

/// Holds [from] (a drawer tile), drags it to [to] and lets go.
Future<void> _carry(WidgetTester tester, Offset from, Offset to) async {
  final g = await tester.startGesture(from, kind: PointerDeviceKind.touch);
  await tester.pump(const Duration(milliseconds: 300));
  for (var i = 1; i <= 12; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 12)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await tester.pump();
}

/// Two fingers around [mid], spread apart by [grow] each.
Future<void> _pinch(WidgetTester tester, Offset mid, double grow) async {
  final a = await tester.startGesture(mid - const Offset(0, 20), pointer: 7);
  final b = await tester.startGesture(mid + const Offset(0, 20), pointer: 8);
  for (var i = 1; i <= 10; i++) {
    await a.moveTo(mid - Offset(0, 20 + grow * i / 10));
    await b.moveTo(mid + Offset(0, 20 + grow * i / 10));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await a.up();
  await b.up();
}

/// A one-finger drag from [from] to [to], slowly enough to read as a carry.
Future<void> _drag(WidgetTester tester, Offset from, Offset to) async {
  final g = await tester.startGesture(from);
  for (var i = 1; i <= 12; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 12)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
}

Future<void> _openDrawerTab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(const ValueKey('editor-add')));
  await _settle(tester, 4);
  await tester.ensureVisible(find.byKey(ValueKey('drawer-tab-$tab')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('drawer-tab-$tab')));
  await _settle(tester, 4);
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

    testWidgets('full screen: the page edge to edge; no phone frame, no tab bar, no page strip', (tester) async {
      final c = EditorController();
      final n = await _open(tester, c);
      expect(n, greaterThan(3), reason: 'the page reported its sections');
      final page = tester.getRect(find.byKey(const ValueKey('page-home.normal')));
      expect(page, Offset.zero & _screen, reason: 'the real page fills the whole screen');
      // Nothing permanent but the pill and +.
      for (final t in ['Content', 'Style', 'Animation', 'Layout', 'Publish', 'UI Editor']) {
        expect(find.text(t), findsNothing, reason: '"$t" is not on screen until asked for');
      }
      expect(find.byKey(const ValueKey('editor-drawer')), findsNothing);
      expect(find.byKey(const ValueKey('context-strip')), findsNothing, reason: 'nothing is picked yet');
      final pill = tester.getRect(find.byKey(const ValueKey('editor-pill')));
      expect(pill.height, lessThanOrEqualTo(52));
      expect(pill.width, lessThan(_screen.width * 0.95));
      expect(find.byKey(const ValueKey('editor-undo')), findsNothing, reason: 'undo shows only once there is a change');
      final add = tester.getRect(find.byKey(const ValueKey('editor-add')));
      expect(add.width, lessThanOrEqualTo(56));

      // + opens the drawer, with its tabs inside it; ✕ closes it.
      await tester.tap(find.byKey(const ValueKey('editor-add')));
      await _settle(tester, 4);
      expect(find.byKey(const ValueKey('editor-drawer')), findsOneWidget);
      for (final t in ['Sections', 'Effects', 'Orbs', 'Loaders', 'Backgrounds', 'Particles', 'Celebrate', 'Map']) {
        expect(find.byKey(ValueKey('drawer-tab-$t')), findsOneWidget);
      }
      await tester.tap(find.byTooltip('Close'));
      await _settle(tester, 4);
      expect(find.byKey(const ValueKey('editor-drawer')), findsNothing);

      // The pill folds into a small handle after a few seconds…
      await tester.pump(kPillOpenFor + const Duration(milliseconds: 100));
      await _settle(tester, 4);
      expect(find.byKey(const ValueKey('editor-pill')), findsNothing);
      final handle = tester.getRect(find.byKey(const ValueKey('editor-pill-handle')));
      expect(handle.width, lessThanOrEqualTo(60));
      expect(handle.height, lessThanOrEqualTo(40));
      // …and a tap opens it again; its page title opens every page.
      await tester.tap(find.byKey(const ValueKey('editor-pill-handle')));
      await _settle(tester, 4);
      expect(find.byKey(const ValueKey('editor-pill')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('editor-pages')));
      await _settle(tester, 6);
      expect(find.text('Which page?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('one finger scrolls the page until a section is picked', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      final page = find.byKey(const ValueKey('page-home.normal'));
      final before = c.sections.map((s) => s.id).toList();
      ScrollPosition vertical() => tester
          .stateList<ScrollableState>(find.descendant(of: page, matching: find.byType(Scrollable)))
          .firstWhere((s) => s.axisDirection == AxisDirection.down)
          .position;
      expect(vertical().pixels, 0);
      await _drag(tester, const Offset(200, 700), const Offset(200, 300));
      await _settle(tester);
      expect(c.sections.map((s) => s.id).toList(), before, reason: 'nothing moved');
      expect(c.pendingCount, 0);
      expect(vertical().pixels, greaterThan(200), reason: 'the page scrolled under the finger');
      expect(tester.getRect(page), Offset.zero & _screen);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pick a section and drag it onto the trash: deleted, with Undo', (tester) async {
      final c = EditorController();
      final n = await _open(tester, c);
      // Let the pill fold away first: the change has to bring it back.
      await tester.pump(kPillOpenFor + const Duration(milliseconds: 100));
      await _settle(tester, 3);
      expect(find.byKey(const ValueKey('editor-undo')), findsNothing);
      _pickFirst(c);
      await _settle(tester, 2);
      expect(find.byKey(const ValueKey('context-strip')), findsOneWidget, reason: 'its small strip shows');
      final from = _sectionRect(c).center;
      final g = await tester.startGesture(from);
      for (var i = 1; i <= 12; i++) {
        await g.moveTo(Offset(from.dx, from.dy + (_screen.height - 30 - from.dy) * i / 12));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byIcon(Icons.delete_rounded), findsOneWidget, reason: 'the trash shows while dragging');
      expect(find.byKey(const ValueKey('context-strip')), findsNothing, reason: 'the bottom is cleared for the trash');
      expect(find.byKey(const ValueKey('editor-add')), findsNothing);
      await g.up();
      await _settle(tester);
      expect(find.textContaining('Deleted “'), findsOneWidget);
      expect(_live(c), n - 1);
      expect(find.byKey(const ValueKey('editor-undo')), findsOneWidget, reason: 'the pill opens with undo after a change');
      await tester.tap(find.text('Undo'));
      await _settle(tester);
      expect(_live(c), n);
      expect(c.canRedo, isTrue);
    });

    testWidgets('long-press shows the short menu; Hide works', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      final id = _pickFirst(c);
      await _settle(tester, 2);
      await tester.longPressAt(_sectionRect(c).center);
      await _settle(tester, 4);
      for (final t in ['Put back', 'Hide', 'Delete']) {
        expect(find.text(t), findsOneWidget);
      }
      await tester.tap(find.text('Hide'));
      await _settle(tester);
      expect(c.sections.firstWhere((s) => s.id == id).entry.visible, isFalse);
      c.undo();
      await _settle(tester);
      expect(c.sections.firstWhere((s) => s.id == id).entry.visible, isTrue);
    });

    testWidgets('drag the top edge for space above; pinch to resize', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      final id = _pickFirst(c);
      await _settle(tester, 2);
      final r = _sectionRect(c);
      await tester.timedDragFrom(Offset(r.center.dx, r.top + 2), const Offset(0, 60), const Duration(milliseconds: 400));
      await _settle(tester);
      final pad = c.current!.entry.props['padTop'];
      expect(pad, isA<num>());
      expect(pad as num, greaterThan(20));
      expect(c.current!.id, id, reason: 'an edge drag does not move the section');

      final before = c.preview.sectionHeights['${c.layoutPage}/$id']!;
      await _pinch(tester, _sectionRect(c).center, 40);
      await _settle(tester);
      final h = c.current!.entry.props['height'] as num;
      expect(h, greaterThan(before * 1.5), reason: 'pinching apart makes it bigger');
    });

    testWidgets('an effect dropped on a section applies and plays right away', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      await _openDrawerTab(tester, 'Effects');
      final target = c.sections.firstWhere((s) {
        final b = c.preview.sectionBoxes['${c.layoutPage}/${s.id}'];
        return b != null && b.attached && b.size.height > 80;
      });
      final to = _sectionRect(c, target.id).center;
      final ticks = c.preview.replayTick;
      final tile = tester.getCenter(find.text('Fade up'));
      final g = await tester.startGesture(tile, kind: PointerDeviceKind.touch);
      await tester.pump(const Duration(milliseconds: 300));
      await g.moveTo(tile - const Offset(0, 40));
      await _settle(tester, 4);
      expect(c.fxDragging, isTrue);
      final drawerTop = tester.getTopLeft(find.byKey(const ValueKey('editor-drawer'))).dy;
      expect(drawerTop, greaterThan(_screen.height - 20), reason: 'the drawer slides away while carrying');
      for (var i = 1; i <= 10; i++) {
        await g.moveTo(Offset.lerp(tile - const Offset(0, 40), to, i / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _settle(tester);
      expect(c.sections.firstWhere((s) => s.id == target.id).entry.props['entrance'], 'fadeUp');
      expect(c.preview.replayTick, greaterThan(ticks), reason: 'it plays as soon as it lands');
      expect(find.byKey(const ValueKey('editor-drawer')), findsNothing, reason: 'the drawer closes on drop');
      expect(c.fxDragging, isFalse);
    });

    testWidgets('orbs: drop at an exact spot, drag, pinch bigger, trash with undo', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      await _openDrawerTab(tester, 'Orbs');
      const spot = Offset(150, 260);
      await _carry(tester, tester.getCenter(find.text('Working')), spot);
      await _settle(tester);
      expect(find.byKey(const ValueKey('editor-drawer')), findsNothing, reason: 'the drawer closes on drop');
      final sel = c.selectedOrb;
      expect(sel, isNotNull, reason: 'the new orb is picked');
      final view = find.byType(PlacedOrbView);
      expect(view, findsOneWidget);
      expect((tester.getCenter(view) - spot).distance, lessThan(1.5), reason: 'it lands exactly under the finger');
      expect(tester.getSize(view).width, PlacedOrb.kDefaultSize);
      expect(c.orbById(sel!.$1, sel.$2)!.orb, 'working');
      expect(find.byKey(const ValueKey('context-strip')), findsOneWidget);

      // Drag it anywhere.
      await _drag(tester, spot, spot + const Offset(90, 140));
      await _settle(tester);
      expect((tester.getCenter(find.byType(PlacedOrbView)) - (spot + const Offset(90, 140))).distance, lessThan(2));

      // Pinch it bigger than the drawer ever offers.
      await _pinch(tester, tester.getCenter(find.byType(PlacedOrbView)), 80);
      await _settle(tester);
      final s = c.selectedOrb!;
      final grown = c.orbById(s.$1, s.$2)!.size;
      expect(grown, greaterThan(PlacedOrb.kDefaultSize * 2));
      expect(tester.getSize(find.byType(PlacedOrbView)).width, moreOrLessEquals(grown, epsilon: 0.5));

      // Onto the trash, then Undo.
      final at = tester.getCenter(find.byType(PlacedOrbView));
      await _drag(tester, at, Offset(at.dx, _screen.height - 30));
      await _settle(tester);
      expect(find.byType(PlacedOrbView), findsNothing);
      expect(find.text('Orb removed'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await _settle(tester);
      expect(find.byType(PlacedOrbView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('elements: tap, drag to move, pinch to resize, trash to remove', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      // On the page (the Deleted snackbar names it too).
      final words = find.descendant(of: find.byType(EditorPreview), matching: find.textContaining('Ready for today'));
      expect(words, findsOneWidget);
      await tester.tapAt(tester.getCenter(words));
      await _settle(tester, 3);
      final key = c.selectedSlot;
      expect(key, isNotNull);
      expect(c.selectedType, SlotType.text);
      expect(find.byKey(const ValueKey('context-strip')), findsOneWidget);

      final from = tester.getCenter(words);
      await _drag(tester, from, from + const Offset(30, 50));
      await _settle(tester);
      final st = c.overrideOf(key!)!.style;
      expect((st['dx'] as num).toDouble(), moreOrLessEquals(30, epsilon: 2));
      expect((st['dy'] as num).toDouble(), moreOrLessEquals(50, epsilon: 2));
      expect((tester.getCenter(words) - (from + const Offset(30, 50))).distance, lessThan(3), reason: 'it follows');

      await _pinch(tester, tester.getCenter(words), 60);
      await _settle(tester);
      expect((c.overrideOf(key)!.style['size'] as num).toDouble(), greaterThan(18), reason: 'bigger than its 12.5');

      final at = tester.getCenter(words);
      await _drag(tester, at, Offset(at.dx, _screen.height - 30));
      await _settle(tester);
      // Really gone (not just faded), and Undo brings it back where it was.
      expect(c.overrideOf(key)!.style['removed'], isTrue);
      expect(words, findsNothing);
      expect(find.textContaining('Deleted “'), findsOneWidget);
      expect(find.text('Show'), findsNothing);
      await tester.tap(find.text('Undo'));
      await _settle(tester, 3);
      expect(c.overrideOf(key)?.style['removed'], isNull);
      expect(words, findsOneWidget);
      expect((c.overrideOf(key)!.style['dx'] as num).toDouble(), moreOrLessEquals(30, epsilon: 2));
      ScaffoldMessenger.of(tester.element(find.byType(UiEditorScreen))).clearSnackBars();
      await _settle(tester, 2);

      // A flick throws it away too.
      await tester.tapAt(tester.getCenter(words));
      await _settle(tester, 3);
      expect(c.selectedSlot, key);
      await tester.flingFrom(tester.getCenter(words), const Offset(260, 0), 4000);
      await _settle(tester, 3);
      expect(c.overrideOf(key)!.style['removed'], isTrue);
      expect(words, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('library: an animation carried from its tab lands in place; ink and Another', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      await _openDrawerTab(tester, 'Loaders');
      final tile = find.byKey(const ValueKey('anim-tile-ld.arc'));
      expect(tile, findsOneWidget);
      expect(find.byType(AnimView), findsWidgets, reason: 'live thumbnails');
      const spot = Offset(200, 300);
      await _carry(tester, tester.getCenter(tile), spot);
      await _settle(tester);
      expect(find.byKey(const ValueKey('editor-drawer')), findsNothing);
      final sel = c.selectedOrb!;
      expect(c.orbById(sel.$1, sel.$2)!.anim, 'ld.arc');
      final view = find.byType(PlacedOrbView);
      expect((tester.getCenter(view) - spot).distance, lessThan(1.5), reason: 'exactly under the finger');
      AnimInk ink() => tester.widget<AnimView>(find.descendant(of: view, matching: find.byType(AnimView))).ink;
      expect(ink().onLight, isTrue, reason: 'auto: dark ink on the light page');

      // Ink: auto → dark → light → auto.
      for (final want in ['dark', 'light', null]) {
        await tester.tap(find.byKey(const ValueKey('orb-ink')));
        await _settle(tester, 2);
        expect(c.orbById(sel.$1, sel.$2)!.ink, want);
      }
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('orb-ink')));
        await _settle(tester, 2);
      }
      expect(ink().onLight, isFalse, reason: 'light ink when picked');

      // Another: the next one in the same category, same spot.
      await tester.tap(find.byTooltip('Another'));
      await _settle(tester, 2);
      expect(c.orbById(sel.$1, sel.$2)!.anim, 'ld.bounce');
      expect((tester.getCenter(find.byType(PlacedOrbView)) - spot).distance, lessThan(1.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a loop dropped on the picked element goes on it; elsewhere on the section', (tester) async {
      final c = EditorController();
      await _open(tester, c);
      final words = find.textContaining('Ready for today');
      await tester.tapAt(tester.getCenter(words));
      await _settle(tester, 3);
      final key = c.selectedSlot!;
      final at = tester.getCenter(words);
      await _openDrawerTab(tester, 'Effects');
      final pulse = find.widgetWithText(DragTile, 'Pulse');
      await tester.scrollUntilVisible(pulse, 120, scrollable: find.descendant(of: find.byKey(const ValueKey('editor-drawer')), matching: find.byType(Scrollable)).last);
      await _settle(tester, 2);
      await _carry(tester, tester.getCenter(pulse), at);
      await _settle(tester);
      expect(c.overrideOf(key)!.style['loop'], 'pulse');
      expect(find.ancestor(of: words, matching: find.byType(LoopFx)), findsOneWidget, reason: 'it plays at once');
      final sec = c.sections.firstWhere((s) => s.entry.props['loop'] != null, orElse: () => c.sections.first);
      expect(sec.entry.props['loop'], isNull, reason: 'the section itself is untouched');

      // Dropped away from the element: the section under it gets it.
      final wordsRect = tester.getRect(words).inflate(40);
      String? other;
      Offset? drop;
      for (var y = 160.0; y < 620 && other == null; y += 40) {
        for (var x = 60.0; x < 380 && other == null; x += 80) {
          final p = Offset(x, y);
          if (wordsRect.contains(p)) continue;
          for (final s in c.sections) {
            final b = c.preview.sectionBoxes['${c.layoutPage}/${s.id}'];
            if (b == null || !b.attached || s.entry.deleted) continue;
            if (_sectionRect(c, s.id).deflate(8).contains(p)) {
              other = s.id;
              drop = p;
              break;
            }
          }
        }
      }
      expect(other, isNotNull);
      await _openDrawerTab(tester, 'Effects');
      final float = find.widgetWithText(DragTile, 'Float');
      await tester.scrollUntilVisible(float, 120, scrollable: find.descendant(of: find.byKey(const ValueKey('editor-drawer')), matching: find.byType(Scrollable)).last);
      await _settle(tester, 2);
      await _carry(tester, tester.getCenter(float), drop!);
      await _settle(tester);
      expect(c.sections.firstWhere((s) => s.id == other).entry.props['loop'], 'float');
      expect(c.overrideOf(key)!.style['loop'], 'pulse');
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the touch hint shows once and any touch dismisses it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final c = EditorController();
    await _open(tester, c);
    expect(find.text('Touch anywhere to start'), findsOneWidget);
    for (final t in ['to select, again to type', 'to move', 'to resize', 'for more', 'to delete', 'to add']) {
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
