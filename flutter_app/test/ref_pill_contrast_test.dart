// B033: every ref-section pill label reaches 4.5:1 on its pill colour
// ('Claim rewards' on red FF4D3D was white at 3.29:1).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/concept/ref_sections.dart';
import 'package:nowssb/widgets/concept/r27/kit.dart';

import 'support/r27_fit.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  setUpAll(loadR27Fonts);
  for (final (w, sc) in [(390.0, 1.0), (320.0, 1.3)]) {
    testWidgets('ref pills AA at ${w.toInt()}@$sc', (t) async {
      final key = await pumpR27(t, const RefHomeSections(), w, sc, r27Black, height: 3400);
      expect(t.takeException(), isNull);
      for (final cta in ['See offers', 'Start earning', 'Claim rewards']) {
        final text = t.widget<Text>(find.text(cta));
        final box = t.widget<Container>(find.ancestor(of: find.text(cta), matching: find.byType(Container)).first);
        final bg = (box.decoration! as BoxDecoration).color!;
        final r = contrast(text.style!.color!, bg);
        expect(r, greaterThanOrEqualTo(4.5), reason: '$cta label at ${r.toStringAsFixed(2)}:1');
      }
      if (w == 390) {
        await t.ensureVisible(find.text('Claim rewards'));
        await t.pump();
      }
      await shotR27(t, key, 'B033-${w.toInt()}');
    });
  }
  test('ink on red', () => expect(contrast(refPillInk(const Color(0xFFFF4D3D)), const Color(0xFFFF4D3D)), greaterThan(5.5)));
}
