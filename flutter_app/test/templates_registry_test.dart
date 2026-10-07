/// Every section and banner in the Sections tab: it builds, survives the
/// save → publish JSON, draws in the published app (layoutChildren) and as
/// its drawer thumbnail without errors, and its words are on screen (so a
/// tap can edit them). Plus: grouped under plain names, nothing lost.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/admin/layout/layout_sections.dart';
import 'package:nowssb/admin/layout/template_more.dart';
import 'package:nowssb/admin/layout/template_sections.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';

const _page = 'test.registry';

void main() {
  test('the registry: 60+ templates, each named, described, grouped once, with a starter', () {
    expect(kTemplateGallery.length, greaterThanOrEqualTo(60));
    expect(kMoreKinds.length, greaterThanOrEqualTo(40));
    expect(kTemplateGallery.toSet(), hasLength(kTemplateGallery.length), reason: 'no repeats');
    expect(kTemplateKinds.toSet(), kTemplateGallery.toSet());
    final grouped = [for (final (_, ks) in kTemplateCategories) ...ks];
    expect(grouped.toSet(), kTemplateGallery.toSet());
    expect(grouped, hasLength(kTemplateGallery.length), reason: 'each in one group');
    expect(kTemplateCategories.map((c) => c.$1), isNot(contains('More')));
    for (final k in kTemplateGallery) {
      expect(kTemplateNames[k], isNotNull, reason: k);
      expect(kTemplateBlurbs[k], isNotNull, reason: k);
      final name = kTemplateNames[k]!.toLowerCase();
      expect(name.contains('hero') || name.contains('curve'), isFalse, reason: 'plain words: $k');
    }
    for (final k in kMoreKinds) {
      expect(templateStarter(k), isNotEmpty, reason: k);
    }
    expect(kTemplateNames.values.toSet(), hasLength(kTemplateNames.length), reason: 'distinct names');
    // Several new coupons, on light and on dark.
    final coupons = kMoreTemplates.entries.where((e) => e.key.startsWith('coupon')).map((e) => e.value.$1).toList();
    expect(coupons.length, greaterThanOrEqualTo(5));
    expect(coupons.where((n) => n.contains('(light)')), isNotEmpty);
    expect(coupons.where((n) => n.contains('(dark)')), isNotEmpty);
  });

  for (final kind in kTemplateGallery) {
    testWidgets('$kind: save → publish → draws (page and thumbnail)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final onError = FlutterError.onError;
      FlutterError.onError = (d) {
        // The test font is taller than the phone's.
        if (!d.toString().contains('overflowed by')) onError?.call(d);
      };
      addTearDown(() => FlutterError.onError = onError);
      await tester.binding.setSurfaceSize(const Size(412, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final entry = SectionEntry(id: '$kind~1', kind: kind, props: templateStarter(kind));
      final layout = PageLayout(page: _page, sections: [entry]);
      final json = jsonDecode(jsonEncode(layout.toJson())) as Map<String, dynamic>;
      final back = PageLayout.from(_page, json)!;
      expect(jsonEncode(back.toJson()), jsonEncode(layout.toJson()), reason: 'saved whole');
      UiLayouts.instance.applyLocal(back);
      addTearDown(() => UiLayouts.instance.removeLocal(_page));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0B1120),
          body: Builder(
            builder: (context) => SingleChildScrollView(
              child: Column(children: [
                ...layoutChildren(context, _page, const []),
                SizedBox(width: 200, height: 140, child: TemplateThumb(kind: kind)),
              ]),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.byType(TemplateSection), findsNWidgets(2), reason: 'on the page and in its thumbnail');
      if (kMoreTemplates.containsKey(kind)) {
        // Its words are drawn (the editor makes each one tappable).
        for (final e in templateStarter(kind).entries) {
          if (e.value is! String || e.key == 'route' || (e.value as String).startsWith('assets/')) continue;
          expect(find.text(e.value as String), findsWidgets, reason: '$kind.${e.key}');
        }
        final page = find.byType(TemplateSection).first;
        expect(tester.getSize(page).height, greaterThan(40), reason: 'it takes room');
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
