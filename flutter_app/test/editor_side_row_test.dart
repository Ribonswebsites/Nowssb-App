/// A smaller section sits left, in the middle or right (long-press and
/// carry it sideways), and pictures, words, buttons, animations and small
/// templates go anywhere in the room beside it — saved as data and drawn
/// the same in the published app.
library;

import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/preview.dart';
import 'package:nowssb/admin/editor/ui_editor_screen.dart';
import 'package:nowssb/admin/layout/layout_sections.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/section_pinch.dart';
import 'package:nowssb/admin/layout/side_row.dart';
import 'package:nowssb/admin/layout/template_sections.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

const _screen = Size(412, 915);

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _carry(WidgetTester tester, Offset from, Offset to, {Duration hold = const Duration(milliseconds: 300)}) async {
  final g = await tester.startGesture(from, kind: PointerDeviceKind.touch);
  await tester.pump(hold);
  for (var i = 1; i <= 14; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 14)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump(const Duration(milliseconds: 200));
  await g.up();
  await tester.pump();
}

Rect _rectOf(EditorController c, String id) {
  final b = c.preview.sectionBoxes['${c.layoutPage}/$id'];
  if (b == null || !b.attached) return Rect.zero;
  return b.localToGlobal(Offset.zero) & b.size;
}

void main() {
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({kTouchHintSeen: true});
    VideoPool.instance.debugDropAll();
  });
  tearDown(VideoPool.instance.debugDropAll);

  test('two things put beside in a row are both kept', () {
    final c = EditorController()..pageId = 'p';
    addTearDown(c.dispose);
    c.preview.reported['p'] = const [SectionInfo('a', 'A', SectionEntry(id: 'a'))];
    c.addBeside('a', BesideKind.image, 0.1, 0.5);
    c.addBeside('a', BesideKind.text, 0.3, 0.5, value: 'Hi');
    final id = c.addBeside('a', BesideKind.button, 0.3, 0.8);
    expect(c.besideIn('a').map((i) => i.kind), [BesideKind.image, BesideKind.text, BesideKind.button]);
    c.removeBeside('a', id);
    expect(c.besideIn('a'), hasLength(2));
  });

  test('side and beside things are saved whole', () {
    expect(sideAlignOf(const {}), 0);
    expect(sideAlignOf(const {'align': 'left'}), -1);
    expect(sideAlignOf(const {'align': 'right'}), 1);
    expect(alignFor(0.1), 'left');
    expect(alignFor(0.5), isNull);
    expect(alignFor(0.9), 'right');
    final items = [
      const BesideItem(id: 'a', kind: BesideKind.image, value: 'x.png', x: 0.8, y: 0.3, width: 140),
      const BesideItem(id: 'b', kind: BesideKind.button, value: 'Go', x: 0.7, y: 0.9),
      const BesideItem(id: 'c', kind: BesideKind.template, value: 'textBlock'),
    ];
    final saved = jsonDecode(jsonEncode(besidePatch(items))) as Map<String, dynamic>;
    final back = besideOf(saved);
    expect([for (final i in back) jsonEncode(i.toJson())], [for (final i in items) jsonEncode(i.toJson())]);
    expect(besidePatch(const []), {'beside': null}, reason: 'none left: the prop goes');
    expect(besideOf(const {'beside': [{'kind': 'nope', 'id': 'x'}, 7]}), isEmpty);
  });

  testWidgets('published: a smaller section on the right, with things beside it on the left', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final entry = SectionEntry(id: 'a', props: {
      'height': 150, // half of its 300: half as wide too
      'align': 'right',
      ...besidePatch(const [
        BesideItem(id: 'p', kind: BesideKind.text, value: 'Hello there', x: 0.25, y: 0.3),
        BesideItem(id: 'q', kind: BesideKind.button, value: 'Go', x: 0.25, y: 0.75),
      ]),
    });
    final json = jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>;
    final back = SectionEntry.from(json)!;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: SectionFrame(
              pageId: 'p',
              entry: back,
              child: const SizedBox(height: 300, child: ColoredBox(key: ValueKey('me'), color: Colors.green)),
            ),
          ),
        ),
      ),
    ));
    expect(find.byType(EditorPreviewScope), findsNothing);
    final me = tester.getRect(find.byKey(const ValueKey('me')));
    expect(me.width, closeTo(200, 0.5));
    expect(me.right, closeTo(400, 0.5), reason: 'sits on the right');
    expect(find.text('Hello there'), findsOneWidget);
    expect(tester.getCenter(find.text('Hello there')).dx, closeTo(100, 1));
    expect(tester.getCenter(find.text('Hello there')).dy, closeTo(45, 2));
    expect(tester.getCenter(find.text('Go')).dx, closeTo(100, 1));
    expect(tester.getSize(find.byKey(const ValueKey('beside-q'))).height, greaterThanOrEqualTo(48));
  });

  testWidgets('in the editor: carry a smaller section sideways; drop a picture and a button beside it', (tester) async {
    tester.view.physicalSize = _screen * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final c = EditorController();
    await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: UiEditorScreen(controller: c))));
    await _settle(tester, 10);

    // A built-in section on screen, made half its height (and so half as wide).
    final live = [for (final s in c.sections) if (!s.entry.deleted && !s.entry.isTemplate) s.id];
    final id = live.firstWhere((i) {
      final r = _rectOf(c, i);
      return r.height > 90 && r.top > 60 && r.bottom < 560;
    });
    final full = _rectOf(c, id).height;
    c.patchProps(id, {'height': (full / 2).roundToDouble()});
    c.endStep();
    await _settle(tester, 4);
    final row = _rectOf(c, id);
    c.pickSection(id);
    await _settle(tester, 2);

    // Hold it and carry it to the left.
    await _carry(tester, Offset(row.center.dx, row.center.dy), Offset(row.left + 30, row.center.dy),
        hold: const Duration(milliseconds: 700));
    await _settle(tester, 4);
    final entry = c.entries.firstWhere((e) => e.id == id);
    expect(entry.props['align'], 'left');
    expect(c.entries.map((e) => e.id).toList().indexOf(id), greaterThanOrEqualTo(0));
    // …and to the middle again, then the right.
    await _carry(tester, Offset(row.left + row.width / 4, row.center.dy), Offset(row.right - 10, row.center.dy),
        hold: const Duration(milliseconds: 700));
    await _settle(tester, 4);
    expect(c.entries.firstWhere((e) => e.id == id).props['align'], 'right');
    ScaffoldMessenger.of(tester.element(find.byType(UiEditorScreen))).clearSnackBars();
    await _settle(tester, 2);

    // A picture from the drawer into the room on the left.
    await tester.tap(find.byKey(const ValueKey('editor-add')));
    await _settle(tester, 4);
    await tester.tap(find.byKey(const ValueKey('drawer-tab-Sections')));
    await _settle(tester, 4);
    final tile = find.byKey(const ValueKey('add-beside-image'));
    expect(tile, findsOneWidget);
    expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
    final spot = Offset(row.left + row.width / 4, row.center.dy);
    await _carry(tester, tester.getCenter(tile), spot);
    await _settle(tester);
    var items = c.besideIn(id);
    expect(items, hasLength(1));
    expect(items.single.kind, BesideKind.image);
    expect(items.single.x, closeTo(0.25, 0.05));
    expect(find.byKey(ValueKey('beside-${items.single.id}')), findsOneWidget, reason: 'drawn on the page');

    // A template dropped in the empty side becomes a real neighbour,
    // sharing the row, not a thumbnail under the section.
    final before = c.entries.length;
    await tester.tap(find.byKey(const ValueKey('editor-add')));
    await _settle(tester, 4);
    await tester.tap(find.byKey(const ValueKey('drawer-tab-Sections')));
    await _settle(tester, 4);
    await _carry(tester, tester.getCenter(find.byKey(ValueKey('add-${kTemplateGallery.first}'))),
        Offset(row.left + 20, row.top + 12));
    await _settle(tester);
    expect(c.entries.length, before + 1);
    final host = c.entries.firstWhere((e) => e.id == id);
    expect(host.props['shrink'], isNotNull);
    expect(host.props['align'], 'right');
    final added = c.entries.where((e) => e.id != id && e.props['shrink'] != null);
    expect(added, isNotEmpty);

    // Long-press the picture and move it down a little.
    final pic = items.first;
    final at = tester.getCenter(find.byKey(ValueKey('beside-${pic.id}')));
    await _carry(tester, at, at + const Offset(0, 20), hold: const Duration(milliseconds: 700));
    await _settle(tester, 3);
    expect(c.besideIn(id).first.y, greaterThan(pic.y));

    // Saved in the layout that Publish sends.
    final doc = jsonDecode(jsonEncode(c.preview.draftLayouts[c.layoutPage]!.toJson())) as Map<String, dynamic>;
    expect(jsonEncode(doc), contains('"beside"'));
    expect(jsonEncode(doc), contains('"align":"right"'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('an added banner pinched in gets narrower (whole), and can then sit on a side', (tester) async {
    tester.view.physicalSize = _screen * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final c = EditorController();
    await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: UiEditorScreen(controller: c))));
    await _settle(tester, 10);
    final id = c.insertTemplate('ctaGradient', 1);
    await _settle(tester, 8);
    c.pickSection(id);
    await _settle(tester, 2);
    final r = _rectOf(c, id);
    expect(r.width, greaterThan(380));
    final a = await tester.startGesture(r.center - const Offset(90, 0));
    final b = await tester.startGesture(r.center + const Offset(90, 0));
    await tester.pump(const Duration(milliseconds: 16));
    for (var i = 0; i < 10; i++) {
      await a.moveBy(const Offset(4.5, 0));
      await b.moveBy(const Offset(-4.5, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await a.up();
    await b.up();
    await _settle(tester, 4);
    final shrink = (c.entries.firstWhere((e) => e.id == id).props['shrink'] as num).toDouble();
    expect(shrink, inInclusiveRange(0.4, 0.7));
    final fit = tester.renderObjectList<RenderSectionFitHeight>(find.byType(SectionFitHeight)).firstWhere((f) {
      final box = c.preview.sectionBoxes['${c.layoutPage}/$id']!;
      RenderObject? x = f;
      while (x != null && x != box) {
        x = x.parent;
      }
      return x == box;
    });
    expect(fit.contentRect.width, closeTo(fit.size.width * shrink, 2), reason: 'whole, just smaller');
    c.patchProps(id, {'align': 'left'});
    await _settle(tester, 2);
    expect(fit.contentRect.left, closeTo(0, 1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
