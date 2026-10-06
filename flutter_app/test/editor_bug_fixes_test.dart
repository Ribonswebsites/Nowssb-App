import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/preview.dart';
import 'package:nowssb/admin/layout/layout_sections.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/section_pinch.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';

Widget _frame(SectionEntry entry, Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 300, child: SectionFrame(pageId: 'home.normal', entry: entry, child: child)),
      ),
    );

EditorController _controller(String page, List<SectionEntry> entries) {
  final c = EditorController()..pageId = page;
  c.preview.reported[page] = [for (final e in entries) SectionInfo(e.id, e.id, e)];
  return c;
}

List<String> _order(EditorController c) => [for (final e in c.entries) e.id];

void main() {
  group('pinch height scales built-in sections both ways', () {
    const key = ValueKey('content');
    const content = SizedBox(key: key, width: 300, height: 100);

    testWidgets('bigger: the section grows instead of adding blank space', (tester) async {
      await tester.pumpWidget(_frame(const SectionEntry(id: 'hero', props: {'height': 200}), content));
      final fit = tester.renderObject<RenderSectionFitHeight>(find.byType(SectionFitHeight));
      expect(fit.size.height, 200);
      expect(fit.scale, closeTo(2, 0.001));
      // The content is painted twice as tall as it is laid out.
      final box = tester.renderObject<RenderBox>(find.byKey(key));
      final top = box.localToGlobal(Offset.zero);
      final bottom = box.localToGlobal(box.size.bottomLeft(Offset.zero));
      expect(bottom.dy - top.dy, closeTo(200, 0.01));
    });

    testWidgets('smaller: the section still shrinks to fit', (tester) async {
      await tester.pumpWidget(_frame(const SectionEntry(id: 'hero', props: {'height': 50}), content));
      final fit = tester.renderObject<RenderSectionFitHeight>(find.byType(SectionFitHeight));
      expect(fit.size.height, 50);
      expect(fit.scale, closeTo(0.5, 0.001));
    });

    testWidgets('no height: untouched', (tester) async {
      await tester.pumpWidget(_frame(const SectionEntry(id: 'hero', props: {'padTop': 0}), content));
      expect(find.byType(SectionFitHeight), findsNothing);
    });
  });

  group('dragging a section reorders the page', () {
    test('drag distance becomes places, bounded by the page', () {
      expect(shiftSteps(0, 3, 3), 0);
      expect(shiftSteps(kShiftStep * 0.9, 3, 3), 0, reason: 'a short drag does nothing');
      expect(shiftSteps(kShiftStep * 1.2, 3, 3), 1);
      expect(shiftSteps(-kShiftStep * 2.5, 3, 3), -2);
      expect(shiftSteps(kShiftStep * 9, 3, 1), 1, reason: 'cannot go past the last section');
      expect(shiftSteps(-kShiftStep * 9, 0, 4), 0, reason: 'the first section cannot go up');
    });

    test('shift moves among live sections, skipping deleted ones', () {
      final c = _controller('p', const [
        SectionEntry(id: 'a'),
        SectionEntry(id: 'b'),
        SectionEntry(id: 'gone', deleted: true),
        SectionEntry(id: 'c'),
        SectionEntry(id: 'd'),
      ]);
      addTearDown(c.dispose);
      c.goTo(1); // the preview is on b, as when it is dragged
      expect(c.shiftRange('b'), (1, 2));
      c.shift('b', 1);
      expect(_order(c), ['a', 'gone', 'c', 'b', 'd'], reason: 'b passes c, not the deleted one');
      expect(c.index, 3, reason: 'the preview follows the moved section');
      c.shift('b', -5);
      expect(_order(c), ['b', 'a', 'gone', 'c', 'd'], reason: 'clamped at the top');
    });

    testWidgets('a saved vertical offset no longer draws a section over its neighbours', (tester) async {
      await tester.pumpWidget(_frame(
        const SectionEntry(id: 'hero', props: {'dy': 80, 'dx': 12}),
        const SizedBox(key: ValueKey('c'), width: 300, height: 100),
      ));
      final t = tester.widget<Transform>(find.byType(Transform));
      final m = t.transform.getTranslation();
      expect(m.x, 12);
      expect(m.y, 0);
    });
  });
}
