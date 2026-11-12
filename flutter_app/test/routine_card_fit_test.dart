// B030: the Zen home Get Started cards must not overflow at 320 wide / text x1.3.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/normal/horizontal_routine_cards.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/r27_fit.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    NmHorizontalRoutineCards.autoAdvance = false;
    await loadR27Fonts();
  });
  for (final c in const [(390.0, 1.0, 'B030-390'), (320.0, 1.3, 'B030-320')]) {
    testWidgets('routine card fits at ${c.$1}@${c.$2}', (t) async {
      final key = await pumpR27(t, const NmHorizontalRoutineCards(fashion: true), c.$1, c.$2,
          Colors.black, height: 900);
      expect(t.takeException(), isNull);
      expect(find.text("Meet today's word"), findsOneWidget);
      await shotR27(t, key, c.$3);
    });
  }
  // Hunter's run used the wide default test font (Ahem) where meta and
  // title both wrap; that is what overflowed on main.
  testWidgets('routine card fits with wide test font at 320@1.3', (t) async {
    t.view.physicalSize = const Size(960, 2700);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 900), textScaler: TextScaler.linear(1.3)),
            child: const Scaffold(
                backgroundColor: Colors.black,
                body: SingleChildScrollView(child: NmHorizontalRoutineCards(fashion: true))))));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.takeException(), isNull);
  });
}
