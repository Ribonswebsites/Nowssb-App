/// Step 3b: the look of a touched thing (chips → tiles, never a wall of
/// settings), saved as data and drawn the same outside the editor; real
/// deletes; elements that reflow what is under them; and a + and folded
/// pill that can be moved out of the way and stay there.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/movable.dart';
import 'package:nowssb/admin/editor/preview.dart';
import 'package:nowssb/admin/editor/tab_look.dart';
import 'package:nowssb/admin/editor/ui_editor_screen.dart';
import 'package:nowssb/admin/layout/element_flow.dart';
import 'package:nowssb/admin/layout/layout_sections.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';
import 'package:nowssb/admin/template/editable.dart';
import 'package:nowssb/admin/template/slot_keys.dart';
import 'package:nowssb/admin/template/ui_overrides.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

const _screen = Size(412, 915);

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<EditorController> _open(WidgetTester tester) async {
  tester.view.physicalSize = _screen * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final c = EditorController();
  await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: UiEditorScreen(controller: c))));
  await _settle(tester, 6);
  return c;
}

Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

const _page = 'test.look';
const _words = 'test.look.words';
const _pic = 'test.look.pic';

/// A page built the way app pages are, with one text and one picture
/// element in its first section.
class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([UiLayouts.instance, UiOverrides.instance]),
        builder: (context, _) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: layoutChildren(context, _page, [
              LSection(
                'a',
                'First',
                Builder(
                  builder: (context) => Column(children: [
                    const EditableLabel(_page, 'Hello', id: 'words'),
                    slotChrome(context, _pic, SlotType.image, '',
                        const SizedBox(width: 160, height: 90, child: ColoredBox(color: Colors.orange))),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
              const LSection('b', 'Second', SizedBox(height: 200, child: ColoredBox(color: Colors.green))),
            ]),
          ),
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a bigger or lower element pushes what is under it down (reflow); a deleted one takes no room',
      (tester) async {
    Future<double> below(Map<String, dynamic> look) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topCenter,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            elementPlacement(look, const SizedBox(width: 100, height: 50)),
            const SizedBox(key: ValueKey('below'), width: 10, height: 10),
          ]),
        ),
      ));
      return tester.getTopLeft(find.byKey(const ValueKey('below'))).dy;
    }

    expect(await below(const {}), 50);
    expect(await below(const {'scale': 2.0}), 100, reason: 'twice the size, twice the room');
    expect(find.byType(ElementFlow), findsOneWidget);
    expect(await below(const {'dy': 30.0}), 80, reason: 'moved down: the rest follows');
    expect(await below(const {'scale': 2.0, 'dy': -20.0}), 80);
    expect(await below(const {'removed': true}), 0, reason: 'deleted: gone, no gap');
    expect(await below(const {'hidden': true}), 0);
  });

  test('a deleted element is one undo step away from coming back', () {
    final c = EditorController()..pageId = _page;
    addTearDown(c.dispose);
    c.patchStyle(_words, SlotType.text, 'Hello', {'dx': 12.0});
    c.endStep();
    c.patchStyle(_words, SlotType.text, 'Hello', {'removed': true, 'hidden': null, 'dx': null, 'dy': null});
    c.endStep();
    expect(c.overrideOf(_words)!.style['removed'], isTrue);
    c.undo();
    expect(c.overrideOf(_words)!.style['removed'], isNull);
    expect(c.overrideOf(_words)!.style['dx'], 12.0);
  });

  testWidgets('section and element looks: Publish json → the published page draws them the same', (tester) async {
    tester.view.physicalSize = const Size(412 * 2, 1200 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    addTearDown(() {
      UiLayouts.instance.removeLocal(_page);
      UiOverrides.instance.removeLocal(_words);
      UiOverrides.instance.removeLocal(_pic);
    });
    final c = EditorController()..pageId = _page;
    addTearDown(c.dispose);
    c.preview.reported[_page] = const [
      SectionInfo('a', 'First', SectionEntry(id: 'a')),
      SectionInfo('b', 'Second', SectionEntry(id: 'b')),
    ];
    c.patchProps('a', {'fill': 0xFF7CFFCB, 'fill2': 0xFF2CB1FF, 'corner': 24, 'lift': 14});
    c.patchStyle(_pic, SlotType.image, '', {'round': 16, 'lift': 6, 'cropZoom': 2.0, 'cropX': -0.5, 'cropY': 0.25});
    c.patchStyle(_words, SlotType.text, 'Hello', {'shadow': 0xAAE8D5A3, 'shadowBlur': 14, 'font': 'Georgia'});

    // What Publish writes, read back the way the app reads Firestore.
    final doc = jsonDecode(jsonEncode(
            PageLayout(page: _page, sections: c.preview.draftLayouts[_page]!.sections, version: 1).toJson()))
        as Map<String, dynamic>;
    UiLayouts.instance.applyLocal(PageLayout.from(_page, doc)!);
    for (final e in c.preview.draftOverrides.entries) {
      final o = UiOverride.from(jsonDecode(jsonEncode(e.value!.toJson())) as Map<String, dynamic>)!;
      UiOverrides.instance.applyLocal(o);
    }

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Page())));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EditorPreviewScope), findsNothing);
    // Section: gradient behind, rounded 24, lifted.
    expect(
        find.byWidgetPredicate((w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            ((w.decoration as BoxDecoration).gradient as LinearGradient?)?.colors.first == const Color(0xFF7CFFCB)),
        findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is ClipRRect && w.borderRadius == BorderRadius.circular(24)), findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            ((w.decoration as BoxDecoration).boxShadow?.first.blurRadius ?? 0) == 28),
        findsOneWidget);
    // Picture: cropped (zoomed toward its left), rounded 16, shadow.
    final pic = find.byWidgetPredicate((w) => w is ColoredBox && w.color == Colors.orange);
    expect(find.ancestor(of: pic, matching: find.byWidgetPredicate((w) => w is ClipRRect && w.borderRadius == BorderRadius.circular(16))),
        findsOneWidget);
    final zoom = tester.widget<Transform>(find.ancestor(of: pic, matching: find.byType(Transform)).first);
    expect(zoom.transform.getMaxScaleOnAxis(), moreOrLessEquals(2));
    expect(zoom.alignment, const Alignment(-0.5, 0.25));
    // Words: the glow and the font.
    final t = tester.widget<Text>(find.text('Hello'));
    expect(t.style?.shadows?.first.color, const Color(0xAAE8D5A3));
    expect(t.style?.fontFamily, contains('Georgia'));
    await _close(tester);
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

    testWidgets('the + and the folded pill move out of the way and stay there next time', (tester) async {
      var c = await _open(tester);
      await tester.pump(kPillOpenFor + const Duration(milliseconds: 100));
      await _settle(tester, 4);
      final add = find.byKey(const ValueKey('editor-add'));
      final handle = find.byKey(const ValueKey('editor-pill-handle'));
      expect(handle, findsOneWidget);
      final add0 = tester.getCenter(add), handle0 = tester.getCenter(handle);

      await tester.drag(add, const Offset(-250, -320));
      await _settle(tester, 4);
      await tester.drag(handle, const Offset(140, 360));
      await _settle(tester, 4);
      final add1 = tester.getCenter(add), handle1 = tester.getCenter(handle);
      expect((add1 - (add0 + const Offset(-250, -320))).distance, lessThan(30), reason: 'followed the finger');
      expect(handle1.dy, greaterThan(handle0.dy + 300));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kAddSpotKey), isNotNull);
      expect(prefs.getString(kHandleSpotKey), isNotNull);
      // Still a button: a tap opens the drawer, not a move.
      expect(c.sectionPicked, isFalse);

      // Next time the editor opens, they are where they were left.
      await _close(tester);
      c = await _open(tester);
      await tester.pump(kPillOpenFor + const Duration(milliseconds: 100));
      await _settle(tester, 4);
      expect((tester.getCenter(add) - add1).distance, lessThan(1.5));
      expect((tester.getCenter(handle) - handle1).distance, lessThan(1.5));
      // The pill opens where its handle is.
      await tester.tap(handle);
      await _settle(tester, 4);
      expect(tester.getCenter(find.byType(EditorPill)).dy, greaterThan(handle0.dy + 250));
      await tester.tap(add);
      await _settle(tester, 4);
      expect(find.byKey(const ValueKey('editor-drawer')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _close(tester);
    });

    testWidgets('Look from a touched element and a touched section: chips → tiles → saved', (tester) async {
      final c = await _open(tester);
      final words = find.descendant(of: find.byType(EditorPreview), matching: find.textContaining('Ready for today'));
      await tester.tapAt(tester.getCenter(words));
      await _settle(tester, 3);
      final key = c.selectedSlot!;
      await tester.tap(find.byKey(const ValueKey('strip-look')));
      await _settle(tester, 4);
      expect(find.byType(LookSheet), findsOneWidget);
      for (final chip in ['colour', 'font', 'shadow', 'shape']) {
        expect(find.byKey(ValueKey('look-chip-$chip')), findsOneWidget);
      }
      expect(find.byType(Slider), findsNothing, reason: 'tiles, not a wall of sliders');
      await tester.tap(find.byKey(const ValueKey('look-grad-1')));
      await _settle(tester, 2);
      expect(c.overrideOf(key)!.style['gradient'], kLookGradients[1]);
      await tester.tap(find.byKey(const ValueKey('look-chip-shadow')));
      await _settle(tester, 3);
      await tester.tap(find.byKey(const ValueKey('look-tshadow-Glow')));
      await _settle(tester, 2);
      expect(c.overrideOf(key)!.style['shadow'], 0xAAE8D5A3);
      await tester.tap(find.byKey(const ValueKey('look-chip-font')));
      await _settle(tester, 3);
      await tester.tap(find.byKey(const ValueKey('look-font-Georgia')));
      await _settle(tester, 2);
      expect(c.overrideOf(key)!.style['font'], 'Georgia');
      // One tap, one undo step.
      c.undo();
      expect(c.overrideOf(key)!.style['font'], isNull);
      expect(c.overrideOf(key)!.style['shadow'], 0xAAE8D5A3);
      Navigator.of(tester.element(find.byType(LookSheet))).pop();
      await _settle(tester, 4);

      // A section: background, corners, shadow.
      final id = [
        for (final s in c.sections)
          if (c.preview.sectionBoxes['${c.layoutPage}/${s.id}']?.attached == true &&
              c.preview.sectionBoxes['${c.layoutPage}/${s.id}']!.size.height > 80)
            s.id
      ].first;
      c.pickSection(id);
      await _settle(tester, 3);
      await tester.tap(find.byKey(const ValueKey('strip-look')));
      await _settle(tester, 4);
      expect(find.byKey(const ValueKey('look-chip-fill')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('look-fill-grad-2')));
      await _settle(tester, 2);
      await tester.tap(find.byKey(const ValueKey('look-chip-corners')));
      await _settle(tester, 3);
      await tester.tap(find.byKey(const ValueKey('look-corner-24')));
      await _settle(tester, 2);
      await tester.tap(find.byKey(const ValueKey('look-chip-lift')));
      await _settle(tester, 3);
      await tester.tap(find.byKey(const ValueKey('look-lift-14')));
      await _settle(tester, 2);
      final p = c.entries.firstWhere((e) => e.id == id).props;
      expect([p['fill'], p['fill2'], p['corner'], p['lift']], [...kLookGradients[2], 24, 14]);
      expect(find.byWidgetPredicate((w) => w is ClipRRect && w.borderRadius == BorderRadius.circular(24)),
          findsWidgets, reason: 'drawn on the page right away');
      await tester.tap(find.byKey(const ValueKey('look-reset')));
      await _settle(tester, 2);
      final q = c.entries.firstWhere((e) => e.id == id).props;
      expect([q['fill'], q['fill2'], q['corner'], q['lift']], everyElement(isNull));
      expect(tester.takeException(), isNull);
      await _close(tester);
    });
  });
}
