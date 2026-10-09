import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/editor/editor_store.dart';
import 'package:nowssb/admin/editor/preview.dart';
import 'package:nowssb/admin/editor/tab_content.dart';
import 'package:nowssb/admin/layout/layout_sections.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/section_pinch.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';
import 'package:nowssb/admin/template/editable.dart';
import 'package:nowssb/admin/template/slot_keys.dart';
import 'package:nowssb/admin/template/ui_overrides.dart';

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
  group('pinch height sizes the section without zooming it', () {
    const key = ValueKey('content');
    const content = SizedBox(key: key, width: 300, height: 100);

    testWidgets('bigger: the box grows and the content stays its own size', (tester) async {
      await tester.pumpWidget(_frame(const SectionEntry(id: 'hero', props: {'height': 200}), content));
      final fit = tester.renderObject<RenderSectionFitHeight>(find.byType(SectionFitHeight));
      expect(fit.size.height, 200);
      expect(fit.scale, closeTo(1, 0.001));
      final box = tester.renderObject<RenderBox>(find.byKey(key));
      final top = box.localToGlobal(Offset.zero);
      final bottom = box.localToGlobal(box.size.bottomLeft(Offset.zero));
      expect(bottom.dy - top.dy, closeTo(100, 0.01), reason: 'taller is not a zoom');
    });

    testWidgets('smaller: the whole section shrinks and nothing is cut', (tester) async {
      await tester.pumpWidget(_frame(const SectionEntry(id: 'hero', props: {'height': 50}), content));
      final fit = tester.renderObject<RenderSectionFitHeight>(find.byType(SectionFitHeight));
      expect(fit.size.height, closeTo(50, 0.5));
      expect(fit.scale, closeTo(0.5, 0.02));
      final box = tester.renderObject<RenderBox>(find.byKey(key));
      final top = box.localToGlobal(Offset.zero);
      final bottom = box.localToGlobal(box.size.bottomLeft(Offset.zero));
      expect(bottom.dy - top.dy, closeTo(50, 1), reason: 'the whole block is still there, just smaller');
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

  group('template words have one source of truth', () {
    test('template slots map back to their entry and field', () {
      expect(isTemplateSlot('tpl.home.normal.textBlock~1.title'), isTrue);
      expect(isTemplateSlot('home_normal.HomeNormal.title'), isFalse);
      expect(templateSlotField('tpl.home.normal.textBlock~1.title', 'home.normal'), ('textBlock~1', 'title'));
      expect(templateSlotField('tpl.program.tab2.cta~3.cta', 'program.tab2'), ('cta~3', 'cta'));
      expect(templateSlotField('tpl.home.normal.textBlock~1.title', 'home.fashion'), isNull);
    });

    testWidgets('a text override never beats the template field', (tester) async {
      final preview = EditorPreviewController();
      addTearDown(preview.dispose);
      const tpl = 'tpl.p.textBlock~1.title';
      const plain = 'p.Hero.welcome';
      preview.draftOverrides[tpl] = const UiOverride(slot: tpl, type: SlotType.text, text: 'Stale words');
      preview.draftOverrides[plain] = const UiOverride(slot: 'p.Hero', type: SlotType.text, text: 'New welcome');
      await tester.pumpWidget(MaterialApp(
        home: EditorPreviewScope(
          controller: preview,
          child: const Column(children: [
            EditableLabel('tpl.p.textBlock~1', 'From the field', id: 'title'),
            EditableLabel('p.Hero', 'Welcome', id: 'welcome'),
          ]),
        ),
      ));
      expect(find.text('From the field'), findsOneWidget);
      expect(find.text('Stale words'), findsNothing);
      expect(find.text('New welcome'), findsOneWidget, reason: 'ordinary slots still take text overrides');
    });
  });

  test('a tabbed page\'s history includes its tabs\' layouts', () {
    expect(historyBelongsTo('program', 'program'), isTrue);
    expect(historyBelongsTo('program.week2', 'program'), isTrue, reason: 'layouts are saved per tab');
    expect(historyBelongsTo('program-old', 'program'), isFalse);
    expect(historyBelongsTo('programs', 'program'), isFalse);
    expect(historyBelongsTo('home.normal', 'home.fashion'), isFalse);
    final sorted = sortHistory([
      HistoryEntry('a', {'page': 'program', 'at': 10}),
      HistoryEntry('b', {'page': 'program.week2', 'at': 30}),
      HistoryEntry('c', {'page': 'program', 'at': 20}),
    ]);
    expect([for (final h in sorted) h.id], ['b', 'c', 'a']);
  });

  test('a schedule cannot end before it starts', () {
    expect(scheduleOk(0, 0), isTrue);
    expect(scheduleOk(100, 0), isTrue, reason: 'no end');
    expect(scheduleOk(0, 100), isTrue, reason: 'no start');
    expect(scheduleOk(100, 200), isTrue);
    expect(scheduleOk(200, 100), isFalse);
    expect(scheduleOk(100, 100), isFalse);

    final c = _controller('p', const [SectionEntry(id: 'a')]);
    addTearDown(c.dispose);
    c.setSchedule('a', 200, 100);
    expect(c.pendingCount, 0, reason: 'refused, nothing pending');
    c.setSchedule('a', 100, 200);
    expect((c.entries.single.start, c.entries.single.end), (100, 200));
  });

  group('Reset page', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('with nothing live it is not a pending change, and drops unpublished edits', () {
      final c = _controller('reset.none', const [SectionEntry(id: 'a'), SectionEntry(id: 'b')]);
      addTearDown(c.dispose);
      c.resetPage();
      expect(c.pendingCount, 0);
      c.setVisible('a', false);
      expect(c.pendingCount, 1);
      c.resetPage();
      expect(c.pendingCount, 0, reason: 'the shipped page is already what people see');
    });

    test('with a live layout it is one pending change', () {
      const page = 'reset.live';
      UiLayouts.instance.applyLocal(const PageLayout(page: page, sections: [SectionEntry(id: 'b'), SectionEntry(id: 'a')]));
      addTearDown(() => UiLayouts.instance.removeLocal(page));
      final c = _controller(page, const [SectionEntry(id: 'b'), SectionEntry(id: 'a')]);
      addTearDown(c.dispose);
      c.resetPage();
      expect(c.pendingCount, 1);
      expect(c.preview.draftLayouts[page]?.version, -1);
    });
  });

  testWidgets('typing is applied once per pause, not once per letter', (tester) async {
    final applied = <String>[];
    final d = Debouncer();
    for (final v in ['H', 'He', 'Hel', 'Hell', 'Hello']) {
      d(() => applied.add(v));
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(applied, isEmpty, reason: 'still typing');
    await tester.pump(const Duration(milliseconds: 300));
    expect(applied, ['Hello']);

    d(() => applied.add('Hello!'));
    d.flush();
    expect(applied.last, 'Hello!', reason: 'flush applies at once');

    d(() => applied.add('dropped'));
    d.cancel();
    await tester.pump(const Duration(milliseconds: 400));
    expect(applied.last, 'Hello!');

    d(() => applied.add('last letters'));
    d.dispose();
    await tester.pump();
    expect(applied.last, 'last letters', reason: 'leaving the field keeps what was typed');
  });
}
