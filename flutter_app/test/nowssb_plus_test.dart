// NowssB Plus intro: full-bleed poster, kit styling, factual copy, and
// the enter button still opens the page where the motion switch works.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion_plus.dart';
import 'package:nowssb/widgets/nowssb_plus_intro.dart';
import 'package:nowssb/widgets/restyle_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    'nwsb_terms_hub': '1',
    'guide_seen_plus': true,
  });

  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  Future<void> pump(WidgetTester t, {Size size = const Size(390, 844)}) async {
    t.view.physicalSize = Size(size.width * 2, size.height * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await Settings.instance.setFashionPlus(false);
    await t.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          devicePixelRatio: 2,
          disableAnimations: true,
        ),
        child: const MaterialApp(home: FashionPlusScreen()),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('intro is named NowssB Plus and has no Fashion copy', (t) async {
    await pump(t);
    expect(find.text('NowssB Plus'), findsWidgets);
    expect(find.text('Enter NowssB Plus'), findsOneWidget);
    expect(find.text('Motion on the Zen home'), findsOneWidget);
    expect(find.text(NowssbPlusIntro.copy), findsOneWidget);
    expect(find.textContaining('Fashion'), findsNothing);
    expect(find.text('ENTER ZEN PLUS'), findsNothing);
    expect(find.textContaining('The still ones'), findsNothing);
    expect(find.text('Zen · Plus'), findsNothing);
    expect(find.byType(KitBackButton), findsOneWidget);
    expect(find.byType(KitActionPill), findsOneWidget);
    // The poster fills the stack (cover), it is not a contained letterbox.
    final images = t.widgetList<Image>(find.byType(Image));
    expect(
      images.any(
        (i) =>
            i.image is AssetImage &&
            (i.image as AssetImage).assetName == NowssbPlusIntro.art &&
            i.fit == BoxFit.cover,
      ),
      isTrue,
    );
  });

  testWidgets('Enter opens the page and the switch still moves the setting', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.text('Enter NowssB Plus'));
    await t.pumpAndSettle();

    expect(find.text('Motion is off'), findsOneWidget);
    expect(Settings.instance.fashionPlus, isFalse);
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();

    expect(Settings.instance.fashionPlus, isTrue);
    expect(find.text('Motion is on'), findsOneWidget);

    await Settings.instance.setFashionPlus(false);
  });

  testWidgets('intro builds at a narrow phone without overflowing', (t) async {
    FlutterError.onError = (d) {
      if (d.toString().contains('overflowed')) {
        fail(d.toString());
      }
    };
    await pump(t, size: const Size(320, 640));
    expect(t.takeException(), isNull);
    expect(find.text('Enter NowssB Plus'), findsOneWidget);
  });
}
