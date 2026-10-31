import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/nwsb_video.dart';
import 'package:nowssb/media/video_pool.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => VideoPool.debugDeadlines = false);

  test("Today's quote poster is bundled", () async {
    final data = await rootBundle.load('assets/video/todays-quote-poster.webp');
    expect(data.lengthInBytes, greaterThan(0));
  });

  testWidgets("Today's quote clip shows its poster before the video is ready",
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SizedBox(
        width: 320,
        height: 180,
        child: NwsbVideo(
            asset: 'assets/video/todays-quote.mp4', fit: BoxFit.cover),
      ),
    ));
    final img = find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName ==
            'assets/video/todays-quote-poster.webp');
    expect(img, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
