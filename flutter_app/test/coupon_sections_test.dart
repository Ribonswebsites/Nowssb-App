import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/admin/layout/coupon_sections.dart';
import 'package:nowssb/admin/layout/template_sections.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  test('coupon templates are registered for the Add section gallery', () {
    for (final k in ['couponTicket', 'couponCards']) {
      expect(kTemplateKinds, contains(k));
      expect(kTemplateNames, contains(k));
      expect(couponsOf(templateStarter(k)), hasLength(2));
    }
  });

  testWidgets('coupon tickets render every editable line', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const e = SectionEntry(id: 'couponTicket~1', kind: 'couponTicket');
    await tester.pumpWidget(_host(TemplateSection(
      entry: SectionEntry(id: e.id, kind: e.kind, props: templateStarter('couponTicket')),
      pageId: 'home.normal',
    )));
    expect(tester.takeException(), isNull);
    expect(find.text('DISCOUNT COUPON'), findsOneWidget);
    expect(find.text('SAVE MORE'), findsOneWidget);
    expect(find.text('20% OFF YOUR PURCHASE'), findsOneWidget);
    expect(find.byType(CouponTicket), findsNWidgets(2));
  });

  testWidgets('coupon cards render and tapping a code copies it', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    await tester.pumpWidget(_host(TemplateSection(
      entry: SectionEntry(id: 'couponCards~1', kind: 'couponCards', props: templateStarter('couponCards')),
      pageId: 'home.normal',
    )));
    expect(tester.takeException(), isNull);
    expect(find.text('LIMITED TIME OFFER!'), findsOneWidget);
    expect(find.text('SPECIAL OFFER!'), findsOneWidget);
    await tester.tap(find.text('SAVE20'));
    await tester.pump();
    expect(copied, 'SAVE20');
  });
}
