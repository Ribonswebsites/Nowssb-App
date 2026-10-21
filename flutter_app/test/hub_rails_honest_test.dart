import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nowssb/widgets/hub_rails.dart';

void main() {
  test('people label only for real counts', () {
    expect(railPeople(null), isNull);
    expect(railPeople(0), isNull);
    expect(railPeople(12), '+12');
    expect(railPeople(2400), '+2k');
  });

  testWidgets('Rewards rails show no placeholder counts or ratings', (t) async {
    t.view.physicalSize = const Size(780, 4000);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: IdentityRails(RailKind.rewards)))));
    await t.pump(const Duration(seconds: 1));
    for (final fake in ['+12', '+8', '+2k', '+6', '+19', '4.7', '4.8', '4.9', '4.6', '5.0', '18h 9m', '12h 24m']) {
      expect(find.text(fake), findsNothing, reason: fake);
    }
  });
}
