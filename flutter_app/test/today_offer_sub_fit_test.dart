// B041: on the Zen/Fashion home at 320 the "Today's Offer" bar's sub line was
// cut at "tap to redeem today's" (3-line cap). The whole sub must show; other bars keep their cap.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/sections_bottom.dart';
import 'fake_video_platform.dart';
import 'support/r27_fit.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await loadR27Fonts();
  });
  for (final c in const [(390.0, 1.0, '390'), (320.0, 1.3, '320')]) {
    testWidgets("Today's Offer sub shows in full at ${c.$1}@${c.$2}", (t) async {
      final key = await pumpR27(t, const FashOffer(), c.$1, c.$2, Colors.black, height: 900);
      final p = t.renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((r) => r.text.toPlainText().startsWith('Rotating store coupons'));
      expect(p.didExceedMaxLines, isFalse, reason: 'sub is cut off');
      expect(t.takeException(), isNull);
      await shotR27(t, key, 'B041-${c.$3}');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 2));
    });
  }
}
