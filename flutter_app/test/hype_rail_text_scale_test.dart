import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/hype_rail.dart';

Future<void> _pump(WidgetTester tester, double scale) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: const Size(320, 900), textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: const Scaffold(body: SingleChildScrollView(child: NowssbHypeRail())),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('hype rail does not overflow at 320px with textScaler 2.0', (tester) async {
    await _pump(tester, 2.0);
    expect(tester.takeException(), isNull);
    expect(find.byType(NowssbHypeRail), findsOneWidget);
  });

  testWidgets('hype rail does not overflow at normal scale', (tester) async {
    await _pump(tester, 1.0);
    expect(tester.takeException(), isNull);
  });
}
