// B029: the Earn rank ladder at the top rank (Diamond II, 'You' tag on the
// tallest step) must not overflow at 390 or 320 @1.3, section or page.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart';
import 'package:nowssb/widgets/concept/r27/data.dart';
import 'package:nowssb/widgets/concept/r27/kit.dart';
import 'package:nowssb/widgets/concept/r27/pages.dart';
import 'package:nowssb/widgets/concept/r27/sections.dart';

import 'support/r27_fit.dart';

const top = R27Earn(ranks: kR27RankDefaults, wordsSold: 3200, ratePct: 50, nextTarget: 0, code: 'NWSB42');
const low = R27Earn(ranks: kR27RankDefaults, wordsSold: 140, ratePct: 22, nextTarget: 500, code: 'NWSB42');

void main() {
  setUpAll(loadR27Fonts);
  void ok(int i) {}
  final cases = <String, (Widget, Color)>{
    'normal': (R27EarnSection(data: top, onOpen: () {}, onRank: ok), nBase),
    'fashion': (R27EarnSection(fashion: true, data: top, onOpen: () {}, onRank: ok), r27Black),
    'page': (R27EarnPage(data: top, onBack: () {}, onHub: () {}, onInvite: () {}, onRank: ok), r27Black),
    'normal-low': (R27EarnSection(data: low, onOpen: () {}, onRank: ok), nBase),
  };
  for (final (w, sc) in [(390.0, 1.0), (320.0, 1.3)]) {
    for (final e in cases.entries) {
      testWidgets('earn ladder ${e.key} fits at ${w.toInt()}@$sc', (t) async {
        final key = await pumpR27(t, e.value.$1, w, sc, e.value.$2);
        expect(t.takeException(), isNull, reason: 'overflow in ${e.key} at $w@$sc');
        await shotR27(t, key, 'B029-${e.key}-${w.toInt()}');
      });
    }
  }
  testWidgets('B029 shot strip', (t) async {
    for (final (w, sc) in [(390.0, 1.0), (320.0, 1.3)]) {
      final key = await pumpR27(
          t,
          ColoredBox(
              color: r27Black,
              child: Column(children: [
                R27EarnSection(data: top, onOpen: () {}, onRank: ok),
                R27EarnSection(fashion: true, data: top, onOpen: () {}, onRank: ok),
                R27EarnPage(data: top, onBack: () {}, onHub: () {}, onInvite: () {}, onRank: ok),
              ])),
          w,
          sc,
          r27Black,
          height: 3400);
      expect(t.takeException(), isNull);
      await shotR27(t, key, 'B029-${w.toInt()}');
    }
  });
}
