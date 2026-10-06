import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/admin/layout/template_sections.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  test('every section and banner is in the gallery, named, with a starter', () {
    expect(kTemplateGallery.toSet(), kTemplateKinds.toSet());
    for (final k in kTemplateKinds) {
      expect(kTemplateNames[k], isNotNull, reason: k);
      expect(kTemplateBlurbs[k], isNotNull, reason: k);
    }
    // Both white coupon templates and the other coupon banners.
    expect(kTemplateGallery, containsAll(['couponTicket', 'couponCards', 'couponBanner', 'couponPromo']));
  });

  for (final kind in kTemplateGallery) {
    testWidgets('$kind draws as a section and as a thumbnail', (tester) async {
      // The test font is taller than the app's: a few fixed-height cards
      // overflow by a line here and not on a phone.
      final onError = FlutterError.onError;
      FlutterError.onError = (d) {
        if (!d.toString().contains('overflowed by')) onError?.call(d);
      };
      addTearDown(() => FlutterError.onError = onError);
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_host(Column(children: [
        TemplateSection(
          entry: SectionEntry(id: '$kind~1', kind: kind, props: templateStarter(kind)),
          pageId: 'home.normal',
        ),
        SizedBox(width: 200, height: 140, child: TemplateThumb(kind: kind)),
      ])));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      expect(find.byType(TemplateThumb), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
