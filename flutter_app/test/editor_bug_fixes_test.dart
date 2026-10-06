import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/admin/layout/layout_sections.dart';
import 'package:nowssb/admin/layout/section_pinch.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';

Widget _frame(SectionEntry entry, Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 300, child: SectionFrame(pageId: 'home.normal', entry: entry, child: child)),
      ),
    );

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
}
