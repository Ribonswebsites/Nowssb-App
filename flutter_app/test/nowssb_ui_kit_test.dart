import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/nowssb_ui/nowssb_ui.dart';

void main() {
  testWidgets('kit widgets build', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(backgroundColor: NTokens.bgBottom, body: SingleChildScrollView(child: Column(children: [
      GlassPill(label: 'Next', style: PillStyle.white),
      GlassChip(label: 'Rarity', selected: true, dropdown: true),
      RarityChip(Rarity.epic),
      PageDots(count: 3, index: 1),
      CouponListCard(label: 'Words', offer: '40% off', isNew: true, image: null),
      GiftTile(color: NTokens.giftPink, wonFor: 'Quiz', validTill: '30 Oct', expired: true),
      DealCard(title: 'Deal', benefit: 'Save 10x', locked: true, unlockIn: Duration(hours: 3)),
      StatPanel(rows: [(Icons.star, '2x', 'scratch chance')]),
      Text3D('HELLO'),
    ])))));
    expect(find.text('Next'), findsOneWidget);
    expect(NCircles.all.length, NCircles.names.length);
  });
}
