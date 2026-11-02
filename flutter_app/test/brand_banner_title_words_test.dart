// B040: BrandTopBanner title 'NowssB Rewards' broke mid-word ('Nowss B Rew
// ards') at 320@1.3 because its column is narrow. Each word must sit on one
// line, and the title stays at 14px or more.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/widgets/brand_top_banner.dart';
import 'package:nowssb/widgets/nwsb_icon.dart';
import 'support/r27_fit.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(loadR27Fonts);
  for (final c in const [(390.0, 1.0, '390'), (320.0, 1.3, '320')]) {
    testWidgets('banner title keeps words whole at ${c.$1}@${c.$2}', (t) async {
      const title = 'NowssB Rewards';
      final key = await pumpR27(
          t,
          // As on the Earn pane: bare, compact, inside the pane's inset.
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 34),
              child: BrandTopBanner(bare: true, compact: true, title: title, mark: NwsbMarks.rewards,
                  art: 'assets/rails/rewards-coins.png', artFit: BoxFit.cover, artAlignment: Alignment.center)),
          c.$1, c.$2, const Color(0xFF101010), height: 400);
      final p = t.renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((r) => r.text.toPlainText() == title);
      // Readable: the column widens before the font shrinks; never below 14px.
      expect(p.text.style!.fontSize!, greaterThanOrEqualTo(14));
      var start = 0;
      for (final w in title.split(' ')) {
        final boxes = p.getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: start + w.length));
        final tops = boxes.map((b) => b.top.round()).toSet();
        expect(tops.length, 1, reason: "'$w' is broken across lines");
        start += w.length + 1;
      }
      expect(t.takeException(), isNull);
      await shotR27(t, key, 'B040-${c.$3}');
    });
  }
}
