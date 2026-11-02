// B039: ref-section tags are DM Sans (not 'monospace') and the longest,
// 'OFFERS & EARNING · COUPONS · GIFTS', fits in 2 lines at 320@1.3.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/concept/ref_sections.dart';
import 'package:nowssb/widgets/concept/r27/kit.dart';

import 'support/r27_fit.dart';

void main() {
  setUpAll(loadR27Fonts);
  for (final (w, sc) in [(390.0, 1.0), (320.0, 1.3)]) {
    testWidgets('ref tags DM Sans, ≤2 lines at ${w.toInt()}@$sc', (t) async {
      final key = await pumpR27(t, const RefHomeSections(), w, sc, r27Black, height: 3400);
      expect(t.takeException(), isNull);
      for (final tag in ['OFFERS & EARNING · COUPONS · GIFTS', 'NOWSSB EARN · DAILY PRACTICE', 'NOWSSB REWARDS · VAULT']) {
        final e = find.text(tag).evaluate().single;
        final text = e.widget as Text;
        expect(text.style!.fontFamily, 'DM Sans', reason: text.data);
        final p = t.renderObject<RenderParagraph>(find.descendant(of: find.byWidget(text), matching: find.byType(RichText)));
        expect((p.size.height / (12.5 * sc * 1.35)).round(), lessThanOrEqualTo(2), reason: '${text.data} at $w@$sc');
      }
      await shotR27(t, key, 'B039-${w.toInt()}');
    });
  }
}
