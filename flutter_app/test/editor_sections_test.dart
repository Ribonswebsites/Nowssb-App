/// Step 3a: the Sections drawer tab. Every section and banner drawn live,
/// carried out with a gold insertion line, dropped exactly between two
/// sections; saved through the normal Publish path and drawn on the
/// published page; editable by touch at once (type in place). Pages that
/// used to be one block now take sections and orbs.
library;

import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/preview.dart';
import 'package:nowssb/admin/editor/ui_editor_screen.dart';
import 'package:nowssb/admin/layout/anims/anim_core.dart';
import 'package:nowssb/admin/layout/coupon_sections.dart';
import 'package:nowssb/admin/layout/layout_sections.dart';
import 'package:nowssb/admin/layout/placed_orbs.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/template_sections.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';
import 'package:nowssb/admin/template/slot_keys.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

const _screen = Size(412, 915);

Future<void> _settle(WidgetTester tester, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The test font is taller than the app's: some fixed-height cards in the
/// thumbnails overflow by a line here and not on a phone.
void _ignoreOverflow() {
  final onError = FlutterError.onError;
  FlutterError.onError = (d) {
    if (!d.toString().contains('overflowed by')) onError?.call(d);
  };
  addTearDown(() => FlutterError.onError = onError);
}

Future<EditorController> _open(WidgetTester tester, [String page = 'home.normal']) async {
  tester.view.physicalSize = _screen * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final c = EditorController();
  await tester.pumpWidget(MaterialApp(home: NavScope(go: (_) {}, child: UiEditorScreen(controller: c))));
  await _settle(tester, 6);
  if (page != 'home.normal') {
    c.openPage(page);
    await _settle(tester, 12);
  }
  return c;
}

Rect _rectOf(EditorController c, String id) {
  final box = c.preview.sectionBoxes['${c.layoutPage}/$id']!;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Two live sections next to each other, both well on screen.
(String, String) _neighbours(EditorController c) {
  final live = [
    for (final s in c.sections)
      if (s.entry.showsNow && c.preview.sectionBoxes['${c.layoutPage}/${s.id}']?.attached == true) s.id
  ];
  for (var i = 0; i + 1 < live.length; i++) {
    final a = _rectOf(c, live[i]), b = _rectOf(c, live[i + 1]);
    if (a.height > 30 && b.height > 60 && a.top > 60 && b.top < 560) return (live[i], live[i + 1]);
  }
  throw StateError('no two sections on screen');
}

Future<void> _openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(const ValueKey('editor-add')));
  await _settle(tester, 4);
  await tester.ensureVisible(find.byKey(ValueKey('drawer-tab-$tab')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('drawer-tab-$tab')));
  await _settle(tester, 4);
}

/// Holds [from], carries it to [to]; [whileHeld] runs before letting go.
Future<void> _carry(WidgetTester tester, Offset from, Offset to, {void Function()? whileHeld}) async {
  final g = await tester.startGesture(from, kind: PointerDeviceKind.touch);
  await tester.pump(const Duration(milliseconds: 300));
  for (var i = 1; i <= 14; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 14)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump(const Duration(milliseconds: 200));
  whileHeld?.call();
  await g.up();
  await tester.pump();
}

const _page = 'test.sections';

/// A page built the way app pages are: sections through layoutChildren.
class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: UiLayouts.instance,
        builder: (context, _) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: layoutChildren(context, _page, const [
              LSection('a', 'First', SizedBox(height: 200, child: ColoredBox(color: Colors.blue))),
              LSection('b', 'Second', SizedBox(height: 200, child: ColoredBox(color: Colors.green))),
            ]),
          ),
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('controller', () {
    EditorController two() {
      final c = EditorController()..pageId = _page;
      c.preview.reported[_page] = const [
        SectionInfo('a', 'First', SectionEntry(id: 'a')),
        SectionInfo('b', 'Second', SectionEntry(id: 'b')),
      ];
      return c;
    }

    test('a section inserted between two lands between them, and undo takes it out', () {
      final c = two();
      addTearDown(c.dispose);
      final id = c.insertTemplate('couponBanner', c.entryIndexBefore('b'));
      expect(c.entries.map((e) => e.id), ['a', id, 'b']);
      expect(c.entries[1].kind, 'couponBanner');
      c.endStep();
      final end = c.insertTemplate('textBlock', c.entryIndexBefore(null));
      expect(c.entries.last.id, end);
      c.endStep();
      c.undo();
      expect(c.entries.map((e) => e.id), ['a', id, 'b']);
    });

    test('a template’s words and pictures write its own props', () {
      final c = two();
      addTearDown(c.dispose);
      final id = c.insertTemplate('cardRow', 1);
      c.setText('tpl.$_page.$id.title', 'Picked for you', 'Fresh picks');
      c.setMedia('tpl.$_page.$id.card1', SlotType.image, '', 'https://x.test/p.png', 'ui/p');
      c.setText('tpl.$_page.$id.card2title', 'Card three', 'Third');
      final p = c.entries[1].props;
      expect(p['title'], 'Fresh picks');
      expect((p['cards'] as List)[1]['image'], 'https://x.test/p.png');
      expect((p['cards'] as List)[2]['title'], 'Third');
      expect(c.preview.draftOverrides, isEmpty, reason: 'one source of truth: the props');
      // Ordinary slots still take overrides.
      c.setText('home.x.hello', 'Hi', 'Hello');
      expect(c.overrideOf('home.x.hello')!.text, 'Hello');
    });
  });

  testWidgets('a coupon banner dropped between sections: Publish json → published page, in place', (tester) async {
    _ignoreOverflow();
    tester.view.physicalSize = const Size(412 * 2, 1400 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(() => UiLayouts.instance.removeLocal(_page));
    final c = EditorController()..pageId = _page;
    addTearDown(c.dispose);
    c.preview.reported[_page] = const [
      SectionInfo('a', 'First', SectionEntry(id: 'a')),
      SectionInfo('b', 'Second', SectionEntry(id: 'b')),
    ];
    final ticket = c.insertTemplate('couponTicket', c.entryIndexBefore('b'));
    final banner = c.insertTemplate('couponBanner', c.entryIndexBefore(null));
    // Its words, tapped and typed in the editor, are the coupon's own.
    c.setText('tpl.$_page.$ticket.c0headline', 'DISCOUNT COUPON', 'BIG SALE');
    expect(couponsOf(c.entries[1].props).first['headline'], 'BIG SALE');
    expect(c.pendingCount, greaterThan(0));

    final draft = c.preview.draftLayouts[_page]!;
    final doc = jsonDecode(jsonEncode(PageLayout(page: _page, sections: draft.sections, version: 1).toJson()))
        as Map<String, dynamic>;
    UiLayouts.instance.applyLocal(PageLayout.from(_page, doc)!);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Page())));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EditorPreviewScope), findsNothing);
    expect(find.byType(CouponSection), findsOneWidget);
    expect(find.text('BIG SALE'), findsOneWidget);
    expect(find.text('DISCOUNT COUPON'), findsNothing);
    final a = tester.getRect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == Colors.blue));
    final b = tester.getRect(find.byWidgetPredicate((w) => w is ColoredBox && w.color == Colors.green));
    final t = tester.getRect(find.byType(CouponSection));
    expect(t.top, greaterThanOrEqualTo(a.bottom - 0.5), reason: 'below the first');
    expect(t.bottom, lessThanOrEqualTo(b.top + 0.5), reason: 'above the second: the page reflowed');
    expect(find.byWidgetPredicate((w) => w is TemplateSection && w.entry.id == banner), findsOneWidget);
    expect(tester.getRect(find.byWidgetPredicate((w) => w is TemplateSection && w.entry.id == banner)).top,
        greaterThanOrEqualTo(b.bottom - 0.5));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
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

    testWidgets('Sections tab: live thumbnails; carry a coupon, see the line, drop it between two sections',
        (tester) async {
      _ignoreOverflow();
      final c = await _open(tester);
      final (above, below) = _neighbours(c);
      final b = _rectOf(c, below);
      final a = _rectOf(c, above);
      await _openTab(tester, 'Sections');
      expect(find.byType(TemplateThumb), findsWidgets, reason: 'live thumbnails');
      final tile = find.byKey(const ValueKey('add-couponTicket'));
      expect(tile, findsOneWidget);
      expect(find.descendant(of: tile, matching: find.byType(CouponSection)), findsOneWidget,
          reason: 'the real coupon, drawn small');

      final drop = Offset(200, b.top + 12);
      await _carry(tester, tester.getCenter(tile), drop, whileHeld: () {
        final line = find.byKey(const ValueKey('insert-line'));
        expect(line, findsOneWidget, reason: 'a clear line where it lands');
        final y = tester.getRect(line).center.dy;
        expect(y, inInclusiveRange(a.bottom - 12, b.top + 12), reason: 'between the two');
      });
      await _settle(tester);
      final ids = [for (final e in c.entries) e.id];
      final at = ids.indexOf(below);
      expect(ids[at - 1], startsWith('couponTicket~'), reason: 'right above the one it was dropped on');
      expect(ids[at - 2], above);
      expect(c.current!.id, ids[at - 1], reason: 'picked, ready to edit');
      expect(c.sectionPicked, isTrue);
      expect(find.byType(CouponSection), findsOneWidget, reason: 'drawn on the page');
      expect(find.byKey(const ValueKey('editor-drawer')), findsNothing);
      // The page reflowed: the section below moved down by the coupon.
      expect(_rectOf(c, below).top, greaterThan(b.top + 100));
      c.undo();
      await _settle(tester);
      expect(c.entries.any((e) => e.kind == 'couponTicket'), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dropped words are typed in place: tap, tap again, type', (tester) async {
      _ignoreOverflow();
      final c = await _open(tester);
      final (_, below) = _neighbours(c);
      c.endStep();
      final id = c.insertTemplate('textBlock', c.entryIndexBefore(below));
      await _settle(tester);
      final heading = find.text('A heading');
      expect(heading, findsOneWidget);
      await tester.tapAt(tester.getCenter(heading));
      await _settle(tester, 3);
      expect(c.selectedSlot, 'tpl.home.normal.$id.title');
      await tester.tapAt(tester.getCenter(heading));
      await _settle(tester, 3);
      final box = find.byKey(const ValueKey('type-in-place'));
      expect(box, findsOneWidget);
      await tester.enterText(find.descendant(of: box, matching: find.byType(TextField)), 'Hello there');
      await _settle(tester, 3);
      expect(c.entries.firstWhere((e) => e.id == id).props['title'], 'Hello there');
      await tester.tap(find.byKey(const ValueKey('type-done')));
      await _settle(tester, 3);
      expect(box, findsNothing);
      expect(find.text('Hello there'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final page in ['reader', 'store.request', 'quotes', 'sentence', 'sound.library']) {
      testWidgets('$page (one block before) takes a section and an orb', (tester) async {
        _ignoreOverflow();
        final c = await _open(tester, page);
        expect(c.layoutPage, page);
        expect(c.sections.length, greaterThanOrEqualTo(2), reason: 'built-in parts are sections now');
        final first = c.sections.first.id;
        final r = _rectOf(c, first);

        // A section between its built-in parts…
        await _openTab(tester, 'Sections');
        await _carry(tester, tester.getCenter(find.byKey(const ValueKey('add-couponCards'))),
            Offset(200, r.bottom - 4));
        await _settle(tester);
        final ids = [for (final e in c.entries) e.id];
        expect(ids.indexWhere((x) => x.startsWith('couponCards~')), ids.indexOf(first) + 1);

        // …and a library animation dropped on the page.
        await _openTab(tester, 'Loaders');
        final spot = Offset(200, (r.top + 40).clamp(120.0, 600.0));
        await _carry(tester, tester.getCenter(find.byKey(const ValueKey('anim-tile-ld.arc'))), spot);
        await _settle(tester);
        final sel = c.selectedOrb;
        expect(sel, isNotNull);
        expect(c.orbById(sel!.$1, sel.$2)!.anim, 'ld.arc');
        expect(find.byType(PlacedOrbView), findsOneWidget);
        expect(find.byType(AnimView), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
