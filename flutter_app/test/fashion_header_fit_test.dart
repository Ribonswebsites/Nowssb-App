// B010: on a 320dp screen at text x1.3 the Fashion header keeps its icons
// on screen; the word mark scales down instead of pushing them off.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/fashion/header.dart';

void main() {
  for (final (w, scale) in [(390.0, 1.0), (320.0, 1.3)]) {
    testWidgets('header fits at ${w.toInt()} x$scale', (t) async {
      t.view.physicalSize = Size(w * 3, 800 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(w, 800), textScaler: TextScaler.linear(scale)),
          child: const Scaffold(body: HomeHeader(notifications: 3)),
        ),
      ));
      await t.pump();
      expect(t.takeException(), isNull, reason: 'no overflow');
      final word = t.getRect(find.text('NowssB'));
      expect(word.left, greaterThanOrEqualTo(0));
      expect(word.right, lessThanOrEqualTo(w));
      await t.pumpWidget(const SizedBox());
    });
  }
}
