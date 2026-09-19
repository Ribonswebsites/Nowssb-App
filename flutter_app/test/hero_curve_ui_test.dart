import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/widgets/hero_curve_stage.dart';

void main() {
  test('curve assets ship with the bundle', () {
    expect(File('assets/hero-curve/subject.webp').existsSync(), isTrue);
    expect(File('assets/hero-curve/stillness.webp').existsSync(), isTrue);
    expect(File('assets/hero-curve/countries.webp').existsSync(), isTrue);
    expect(File('assets/hero-curve/cosmos.webp').existsSync(), isTrue);
    expect(File('assets/hero-curve/tab-subject.webp').existsSync(), isTrue);
    expect(File('assets/hero-curve/tab-window.webp').existsSync(), isTrue);
    expect(HeroCurveAssets.tabCards, hasLength(6));
  });

  test('normal home parks the curve under search', () {
    expect(kNormalSectionOrder.indexOf('heroCurve'),
        kNormalSectionOrder.indexOf('search') + 1);
  });

  testWidgets('curve stage shows the NowssB wordmark', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HeroCurveStage())),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('NowssB.'), findsOneWidget);
    expect(find.text('Sound that finds you'), findsOneWidget);
    expect(find.text('Pronunciation & sound healing, wherever you are'),
        findsOneWidget);
    expect(find.text('Word Science'), findsNothing);
    expect(find.textContaining('she stays'), findsNothing);
    expect(find.byType(HeroCurveStage), findsOneWidget);
  });

  testWidgets('embedded curve paints the blonde cutout', (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 220,
            child: HeroCurveStage(
              embedded: true,
              subject: HeroCurveAssets.tabSubject,
              cards: HeroCurveAssets.tabCards,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('NowssB.'), findsNothing);
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(
      images.any((i) {
        final img = i.image;
        return img is AssetImage &&
            img.assetName == HeroCurveAssets.tabSubject;
      }),
      isTrue,
    );
  });
}
