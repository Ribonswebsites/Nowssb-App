// B012: every label of the Edition film and the subscription teaser shows
// whole at 390dp x1.0 and 320dp x1.3, with the film kept at its own size.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/play_subscriptions.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/shared_sections.dart';

import 'fake_video_platform.dart';
import 'sub_teaser_play_price_test.dart' show setPlayInr;

// The app sets DM Sans. The test font (Ahem) draws every glyph as a full
// square, about twice as wide, so it would flag labels that fit on a phone.
const _dmSans = '/usr/share/fonts/truetype/sand-box/google/DM Sans/DMSans-VariableFont_opsz,wght.ttf';

void main() {
  final haveFont = File(_dmSans).existsSync();
  setUpAll(() async {
    if (!haveFont) return;
    final bytes = File(_dmSans).readAsBytesSync();
    for (final f in ['Roboto', 'DM Sans']) {
      await (FontLoader(f)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });
  setUp(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  for (final prices in [false, true])
  for (final (w, scale) in [(390.0, 1.0), (320.0, 1.3)]) {
    testWidgets('every Edition/teaser label unclipped at ${w.toInt()} x$scale${prices ? ' with Play prices' : ''}', (t) async {
      if (!haveFont) return markTestSkipped('DM Sans not installed');
      prices ? setPlayInr() : PlaySubscriptions.instance.debugSetProducts(const []);
      t.view.physicalSize = Size(w * 3, 4000 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(w, 4000), textScaler: TextScaler.linear(scale)),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: Column(children: [EditionSection(), SubscriptionSection()]),
            ),
          ),
        ),
      ));
      await t.pump(const Duration(milliseconds: 500));
      expect(t.takeException(), isNull, reason: 'no overflow');

      var checked = 0;
      for (final e in find.byType(RichText).evaluate()) {
        final r = e.renderObject! as RenderParagraph;
        if (r.text.toPlainText().trim().isEmpty) continue;
        checked++;
        final label = r.text.toPlainText();
        expect(r.didExceedMaxLines, isFalse, reason: '"$label" is cut');
        // A FittedBox may scale a label down, but never past what is legible.
        final m = r.getTransformTo(null).getMaxScaleOnAxis();
        expect(m, greaterThan(0.6), reason: '"$label" scaled to $m');
        // The painted text lies inside every clip above it.
        final box = MatrixUtils.transformRect(r.getTransformTo(null), Offset.zero & r.size);
        RenderObject? n = r.parent;
        while (n != null) {
          if (n is RenderClipRect || n is RenderClipRRect) {
            final c = MatrixUtils.transformRect(n.getTransformTo(null), Offset.zero & (n as RenderBox).size);
            expect(c.inflate(0.5).contains(box.topLeft) && c.inflate(0.5).contains(box.bottomRight), isTrue,
                reason: '"$label" $box is cut by a clip $c');
          }
          n = n.parent;
        }
      }
      expect(checked, greaterThan(8));
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 1));
    });
  }
}
