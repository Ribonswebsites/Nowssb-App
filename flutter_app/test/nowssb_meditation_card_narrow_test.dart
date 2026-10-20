import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/nowssb_ui/nowssb_ui.dart';

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('MeditationCard fits a 320px screen (text scale $scale)', (t) async {
      t.view.physicalSize = const Size(320, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(home: MediaQuery(
        data: MediaQueryData(size: const Size(320, 900), textScaler: TextScaler.linear(scale)),
        child: const Scaffold(body: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(16),
          child: MeditationCard(title: '30 days Meditation Challenge',
              subtitle: '100+ guided meditations covering anxiety, focus, stress, gratitude and more.',
              secondary: 'Skip for now', cta: 'Get started', dots: 5, dotIndex: 2, blur: 0)))),
      )));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('Get started'), findsOneWidget);
    });
  }
}
