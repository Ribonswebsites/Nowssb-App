import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/admin/layout/layout_sections.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';

void main() {
  testWidgets('editor preview measures a section and replays its entrance', (tester) async {
    final preview = EditorPreviewController();
    addTearDown(preview.dispose);
    const entry = SectionEntry(id: 'hero', props: {'entrance': 'fade'});
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: EditorPreviewScope(
        controller: preview,
        child: const Align(
          alignment: Alignment.topCenter,
          child: SectionFrame(pageId: 'home.normal', entry: entry, child: SizedBox(height: 120, width: 200)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(preview.sectionHeights['home.normal/hero'], 120);

    double opacity() => tester.widget<Opacity>(find.byType(Opacity).first).opacity;
    expect(opacity(), 1);
    preview.replay();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(opacity(), lessThan(1), reason: 'the fade starts over');
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });
}
