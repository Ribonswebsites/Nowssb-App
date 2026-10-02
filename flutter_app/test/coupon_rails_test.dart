import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/features/economy/coupon_tickets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('coupon rails lay out at phone width', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(child: CouponRails()),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsWidgets);
    expect(find.text('LIMITED TIME OFFER!'), findsWidgets);
    expect(find.text('COUPON CODE:  '), findsWidgets);
  });
}
