import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/programs/gifts_program.dart';

void main() {
  testWidgets('own-code Redeem pill fits at 320px with no overflow', (t) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            TextButton(onPressed: () {}, child: const Text('Back')),
            const Spacer(),
            const Flexible(child: GiftRedeemPill(label: 'Send this code to your friend')),
          ]),
        ),
      ),
    ));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('Send this code to your friend'), findsOneWidget);
    final pill = t.getRect(find.byKey(const Key('gift_redeem')));
    expect(pill.right, lessThanOrEqualTo(320));
  });
}
