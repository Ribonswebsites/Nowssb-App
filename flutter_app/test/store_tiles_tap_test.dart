/// Store home: each black tile under a department banner opens its page.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/kit/kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/admin/layout/ui_layouts.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/store.dart';
import 'package:nowssb/screens/subscription.dart';

import 'fake_video_platform.dart';

class _Obs extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushed.add(route);
}

void main() {
  // These cover the legacy Store screens; the rebuilt ones have store_newui_test.
  setUpAll(() => NewUi.setDebugOverride('store', false));
  tearDownAll(NewUi.resetForTest);

  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.createTempSync('tiles').path);
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    // The live layout Ribon sees: every department section shown.
    UiLayouts.instance
        .applyLocal(const PageLayout(page: 'store.home', sections: [
      SectionEntry(id: 'header'),
      SectionEntry(id: 'depttabs'),
      SectionEntry(id: 'spotlight'),
      SectionEntry(id: 'tabs'),
      SectionEntry(id: 'rotator'),
      SectionEntry(id: 'halfoff'),
      SectionEntry(id: 'atelier'),
      SectionEntry(id: 'meaning'),
      SectionEntry(id: 'signature'),
      SectionEntry(id: 'promo'),
      SectionEntry(id: 'connect'),
      SectionEntry(id: 'ebooks'),
      SectionEntry(id: 'plans'),
      SectionEntry(id: 'disclaimer'),
      SectionEntry(id: 'credits'),
    ]));
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  final cases = <String, Type>{
    'Build Your Personal Library': WordAtelierScreen,
    'Meanings beneath every word': MeaningStoreScreen,
    'NowssB Ebooks': EbooksStoreScreen,
    'Subscription Plans': SubscriptionScreen,
  };

  for (final c in cases.entries) {
    testWidgets('tile "${c.key}" opens ${c.value}', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      // The destination pages draw with the test font and no network
      // images; only navigation is under test here.
      final prev = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.library == 'rendering library' ||
            d.library == 'image resource service') {
          return;
        }
        prev?.call(d);
      };
      addTearDown(() => FlutterError.onError = prev);
      final obs = _Obs();
      await tester.pumpWidget(
          MaterialApp(navigatorObservers: [obs], home: const StoreScreen()));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      final f = find.text(c.key).hitTestable();
      await tester.scrollUntilVisible(find.text(c.key), 250,
          scrollable: find
              .byWidgetPredicate((w) =>
                  w is Scrollable && w.axisDirection == AxisDirection.down)
              .first);
      await tester.pump(const Duration(milliseconds: 200));
      final before = obs.pushed.length;
      await tester.tap(f.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(obs.pushed.length, greaterThan(before),
          reason: '${c.key} did not navigate');
      expect(find.byType(c.value, skipOffstage: false), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    });
  }

  testWidgets('tile "Get Verified" opens the verification sheet',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.library == 'rendering library' ||
          d.library == 'image resource service') {
        return;
      }
      prev?.call(d);
    };
    addTearDown(() => FlutterError.onError = prev);
    await tester.pumpWidget(const MaterialApp(home: StoreScreen()));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.scrollUntilVisible(find.text('Get Verified'), 250,
        scrollable: find
            .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down)
            .first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Get Verified').hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('verify-request')), findsOneWidget);
    expect(find.byType(SignatureStoreScreen), findsNothing);
    await tester.tap(find.text('Not now'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byKey(const ValueKey('verify-request')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 11));
  });
}
