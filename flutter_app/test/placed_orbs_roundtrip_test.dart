/// Orbs dropped in the UI Editor go through the normal save path (the
/// draft layout that Publish writes to `ui_layouts`) and come back on the
/// published page — outside the editor — at the same spot and size.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/layout/layout_sections.dart';
import 'package:nowssb/admin/layout/placed_orbs.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';

const _page = 'test.orbs';

/// A page built the way every app page is: sections through layoutChildren.
class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: UiLayouts.instance,
    builder: (context, _) => SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: layoutChildren(context, _page, const [
          LSection('a', 'First', SizedBox(height: 300, child: ColoredBox(color: Colors.blue))),
          LSection('b', 'Second', SizedBox(height: 400, child: ColoredBox(color: Colors.green))),
        ]),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('placed orb json: clamps, defaults and survives encode/decode', () {
    const o = PlacedOrb(id: 'orb1', orb: 'working', x: 0.25, y: 120, size: 260, circle: true);
    final back = PlacedOrb.from(jsonDecode(jsonEncode(o.toJson())))!;
    expect((back.id, back.orb, back.x, back.y, back.size, back.circle), ('orb1', 'working', 0.25, 120.0, 260.0, true));
    expect(back.state, OrbState.working);
    final odd = PlacedOrb.from({'id': 'z', 'x': 4, 'size': 9000})!;
    expect(odd.x, 1.0);
    expect(odd.size, PlacedOrb.kMaxSize);
    expect(PlacedOrb.from({'x': 1}), isNull, reason: 'no id, no orb');
  });

  testWidgets('drop → draft → ui_layouts json → published page renders it in place', (tester) async {
    tester.view.physicalSize = const Size(400 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(() => UiLayouts.instance.removeLocal(_page));

    // In the editor: drop two orbs and change one.
    final c = EditorController()..pageId = _page;
    addTearDown(c.dispose);
    c.preview.reported[_page] = const [
      SectionInfo('a', 'First', SectionEntry(id: 'a')),
      SectionInfo('b', 'Second', SectionEntry(id: 'b')),
    ];
    final id = c.addOrb('a', OrbState.working.name, 0.25, 120, size: 90);
    final id2 = c.addOrb('b', OrbState.listening.name, 0.8, 50);
    c.updateOrb('a', id, (o) => o.copyWith(size: 180, circle: true));
    expect(c.selectedOrb, isNotNull);
    expect(c.pendingCount, greaterThan(0), reason: 'the orbs wait for Publish like any edit');

    // What Publish writes: the draft layout, as stored in ui_layouts…
    final draft = c.preview.draftLayouts[_page]!;
    final doc = jsonDecode(jsonEncode(PageLayout(page: _page, sections: draft.sections, version: 1).toJson()))
        as Map<String, dynamic>;
    // …and what every app reads back from it.
    final live = PageLayout.from(_page, doc)!;
    UiLayouts.instance.applyLocal(live);

    // The published page — no editor around it.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Page())));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(EditorPreviewScope), findsNothing);
    final views = find.byType(PlacedOrbView);
    expect(views, findsNWidgets(2));

    final a = tester.getRect(find.byWidgetPredicate((w) => w is PlacedOrbView && w.orb.id == id));
    expect(a.center.dx, moreOrLessEquals(400 * 0.25, epsilon: 0.5));
    expect(a.center.dy, moreOrLessEquals(120, epsilon: 0.5));
    expect(a.width, moreOrLessEquals(180, epsilon: 0.5));
    final aw = tester.widget<PlacedOrbView>(find.byWidgetPredicate((w) => w is PlacedOrbView && w.orb.id == id));
    expect(aw.orb.circle, isTrue);
    expect(aw.orb.state, OrbState.working);

    final b = tester.getRect(find.byWidgetPredicate((w) => w is PlacedOrbView && w.orb.id == id2));
    expect(b.center.dx, moreOrLessEquals(400 * 0.8, epsilon: 0.5));
    expect(b.center.dy, moreOrLessEquals(300 + 50, epsilon: 0.5), reason: 'y is from the top of its own section');
    expect(b.width, moreOrLessEquals(PlacedOrb.kDefaultSize, epsilon: 0.5));

    // Deleting it in the editor and publishing again removes it for people.
    c.deleteOrb('a', id);
    c.deleteOrb('b', id2);
    final again = PageLayout.from(
      _page,
      jsonDecode(jsonEncode(PageLayout(page: _page, sections: c.preview.draftLayouts[_page]!.sections, version: 2).toJson()))
          as Map<String, dynamic>,
    )!;
    UiLayouts.instance.applyLocal(again);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PlacedOrbView), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
