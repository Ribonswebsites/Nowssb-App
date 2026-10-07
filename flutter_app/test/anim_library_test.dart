/// The animation library (lib/admin/layout/anims): 80+ distinct
/// animations, and every one builds, draws at any time on light and dark
/// pages, survives JSON, and can be dropped in the editor, published and
/// drawn on the live page.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/editor/editor_controller.dart';
import 'package:nowssb/admin/layout/anims/anim_library.dart';
import 'package:nowssb/admin/layout/anims/effects.dart';
import 'package:nowssb/admin/layout/layout_sections.dart';
import 'package:nowssb/admin/layout/placed_orbs.dart';
import 'package:nowssb/admin/layout/scopes.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';

const _page = 'test.anims';

class _Page extends StatelessWidget {
  const _Page();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: UiLayouts.instance,
    builder: (context, _) => SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: layoutChildren(context, _page, const [
          LSection('a', 'First', SizedBox(height: 300, child: ColoredBox(color: Colors.white))),
          LSection('b', 'Second', SizedBox(height: 300, child: ColoredBox(color: Colors.black))),
        ]),
      ),
    ),
  );
}

/// A 24 × 24 grey thumbnail of [s] at [t], normalised (mean 0, sd 1) so a
/// recolour of the same drawing compares as the same shape.
Future<List<double>> _signature(AnimSpec s, double t) async {
  const n = 24;
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.drawRect(const Rect.fromLTWH(0, 0, n * 1.0, n * 1.0), Paint()..color = const Color(0xFF808080));
  canvas.scale(n / 100);
  s.paint!(canvas, t, const AnimInk());
  final img = await rec.endRecording().toImage(n, n);
  final bytes = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final px = Uint8List.view(bytes.buffer);
  final g = [for (var i = 0; i < n * n; i++) 0.3 * px[i * 4] + 0.59 * px[i * 4 + 1] + 0.11 * px[i * 4 + 2]];
  final mean = g.reduce((a, b) => a + b) / g.length;
  final sd = math.sqrt(g.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / g.length);
  return [for (final v in g) sd < 1e-6 ? 0 : (v - mean) / sd];
}

double _corr(List<double> a, List<double> b) {
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    s += a[i] * b[i];
  }
  return s / a.length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('80+ animations, unique ids and names, in every category', () {
    expect(kAnimLibrary.length, greaterThanOrEqualTo(115), reason: '93 + the new ones');
    expect(kAnimLibrary.map((s) => s.id).toSet().length, kAnimLibrary.length, reason: 'ids are unique');
    expect(kAnimLibrary.map((s) => s.name).toSet().length, kAnimLibrary.length, reason: 'names are unique');
    final counts = {for (final c in AnimCategory.values) c: animsIn(c).length};
    // ignore: avoid_print
    print('animations: ${kAnimLibrary.length} — ${counts.entries.map((e) => '${kAnimCategoryNames[e.key]} ${e.value}').join(', ')}');
    for (final c in AnimCategory.values) {
      expect(counts[c], greaterThanOrEqualTo(10), reason: '${c.name} has a full grid');
    }
    for (final s in kAnimLibrary) {
      expect(animById(s.id), same(s));
      expect(s.name.split(' ').length, lessThanOrEqualTo(2), reason: 'one or two words: ${s.name}');
    }
  });

  test('every drawn animation is its own drawing, not a recolour of another', () async {
    final drawn = kAnimLibrary.where((s) => s.paint != null).toList();
    expect(drawn.length, greaterThanOrEqualTo(80), reason: '80+ even without the thinking orbs');
    final sigs = <String, List<List<double>>>{};
    for (final s in drawn) {
      sigs[s.id] = [for (final t in const [0.55, 1.3, 2.7]) await _signature(s, t)];
    }
    var worst = ('', '', -1.0);
    for (var i = 0; i < drawn.length; i++) {
      for (var j = i + 1; j < drawn.length; j++) {
        final a = sigs[drawn[i].id]!, b = sigs[drawn[j].id]!;
        // The same shape at every moment would mean the same animation.
        final r = [for (var k = 0; k < a.length; k++) _corr(a[k], b[k])].reduce(math.min);
        if (r > worst.$3) worst = (drawn[i].id, drawn[j].id, r);
      }
    }
    // ignore: avoid_print
    print('most alike pair: ${worst.$1} / ${worst.$2} (r = ${worst.$3.toStringAsFixed(2)})');
    expect(worst.$3, lessThan(0.9), reason: '${worst.$1} and ${worst.$2} look the same');
  });

  test('thinking orbs keep the old save format; library ids save as anim', () {
    final orb = PlacedOrb.fieldsFor('orb.working');
    expect((orb.orb, orb.anim), ('working', null));
    final conf = PlacedOrb.fieldsFor('cb.confetti');
    expect((conf.orb, conf.anim), ('composing', 'cb.confetti'), reason: 'older apps fall back to an orb');
    final unknown = PlacedOrb.from({'id': 'x', 'orb': 'solving', 'anim': 'from.a.newer.app'})!;
    expect(unknown.anim, 'from.a.newer.app', reason: 'kept, not dropped, on re-save');
    expect(PlacedOrb.from({'id': 'x', 'ink': 'purple'})!.ink, isNull);
  });

  group('every animation', () {
    for (final s in kAnimLibrary) {
      testWidgets('${s.id}: builds, draws, round-trips, drops and publishes', (tester) async {
        tester.view.physicalSize = const Size(400 * 2, 900 * 2);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        addTearDown(() => UiLayouts.instance.removeLocal(_page));

        // Draws at several moments, on light and dark pages, full and lite.
        for (final t in [0.0, 0.37, 1.9, 4.3, 61.7]) {
          await tester.pumpWidget(Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              AnimView(spec: s, size: 96, fixedT: t),
              AnimView(spec: s, size: 96, fixedT: t, ink: const AnimInk(onLight: true)),
              AnimView(spec: s, size: 40, fixedT: t, ink: const AnimInk(lite: true)),
            ]),
          ));
          expect(tester.takeException(), isNull, reason: 't = $t');
        }
        // And plays live.
        await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: AnimView(spec: s, size: 120))));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 40));
        }
        expect(tester.takeException(), isNull);

        // JSON round trip.
        final f = PlacedOrb.fieldsFor(s.id);
        final o = PlacedOrb(id: 'orb1', orb: f.orb, anim: f.anim, x: 0.3, y: 140, size: 120, ink: 'dark');
        final back = PlacedOrb.from(jsonDecode(jsonEncode(o.toJson())))!;
        expect(back.animId, s.id);
        expect((back.x, back.y, back.size, back.ink), (0.3, 140.0, 120.0, 'dark'));

        // Dropped in the editor, published, drawn on the live page.
        final c = EditorController()..pageId = _page;
        addTearDown(c.dispose);
        c.preview.reported[_page] = const [
          SectionInfo('a', 'First', SectionEntry(id: 'a')),
          SectionInfo('b', 'Second', SectionEntry(id: 'b')),
        ];
        final id = c.addAnim('b', s.id, 0.5, 150);
        expect(c.orbById('b', id)!.animId, s.id);
        final doc = jsonDecode(jsonEncode(
          PageLayout(page: _page, sections: c.preview.draftLayouts[_page]!.sections, version: 1).toJson(),
        )) as Map<String, dynamic>;
        UiLayouts.instance.applyLocal(PageLayout.from(_page, doc)!);
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: _Page())));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byType(EditorPreviewScope), findsNothing);
        final view = find.byType(PlacedOrbView);
        expect(view, findsOneWidget);
        expect(tester.widget<PlacedOrbView>(view).orb.animId, s.id);
        expect(tester.getCenter(view), const Offset(200, 300 + 150));
        final anim = tester.widget<AnimView>(find.descendant(of: view, matching: find.byType(AnimView)));
        expect(anim.spec, same(s));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  testWidgets('ink adapts to the page: dark on light pages, light on dark sections and the disc', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(theme: ThemeData(brightness: Brightness.light), home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    const o = PlacedOrb(id: 'o', orb: 'composing', anim: 'pt.sparkles', x: 0.5, y: 0);
    expect(placedOnLight(ctx, o), isTrue, reason: 'light theme → dark ink');
    expect(placedOnLight(ctx, o, sectionBg: 0xFF1B2437), isFalse, reason: 'dark section colour → light ink');
    expect(placedOnLight(ctx, o, sectionBg: 0xFFFFFFFF), isTrue);
    expect(placedOnLight(ctx, o.copyWith(circle: true)), isFalse, reason: 'on the black disc');
    expect(placedOnLight(ctx, o.copyWith(ink: 'light')), isFalse, reason: 'the owner picked light ink');
    expect(placedOnLight(ctx, o.copyWith(ink: 'dark'), sectionBg: 0xFF000000), isTrue);
  });

  testWidgets('every entrance and loop plays without errors', (tester) async {
    for (final kind in kEntranceNames.keys) {
      await tester.pumpWidget(MaterialApp(home: Center(child: SectionEntrance(kind: kind, child: const SizedBox(width: 80, height: 40, child: ColoredBox(color: Colors.amber))))));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: kind);
      // Ends where it started: in place, fully shown.
      expect(tester.getCenter(find.byType(ColoredBox).last), const Offset(400, 300), reason: kind);
    }
    for (final kind in kLoopNames.keys) {
      await tester.pumpWidget(MaterialApp(home: Center(child: LoopFx(kind: kind, child: const SizedBox(width: 80, height: 40, child: ColoredBox(color: Colors.teal))))));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: kind);
      await tester.pumpWidget(const SizedBox());
    }
    for (final k in kEntranceNames.keys) {
      if (!kClassicEntrances.contains(k) && k != 'none') expect(entranceEffects(k), isNotNull, reason: k);
    }
    for (final k in kLoopNames.keys) {
      if (k != 'none') expect(loopEffects(k), isNotNull, reason: k);
    }
  });
}
