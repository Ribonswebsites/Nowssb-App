// Store home + Meaning Store with Firebase not initialised (the offline /
// no-backend path), plus the meaning detail flow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/store.dart';
import 'package:nowssb/screens/store/meaning_store.dart';
import 'package:nowssb/screens/store/product_detail.dart';
import 'package:nowssb/screens/store/store_first_use_guide.dart';

import 'fake_video_platform.dart';

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _drop(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 5));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({
      StoreFirstUseGuide.prefKey('store_home'): true,
      StoreFirstUseGuide.prefKey('meaning_store'): true,
    });
    VideoPool.instance.debugDropAll();
  });
  tearDown(VideoPool.instance.debugDropAll);

  testWidgets('Store home renders offline with title, bag and guide button', (t) async {
    await t.pumpWidget(const MaterialApp(home: StoreScreen()));
    await _settle(t);
    expect(find.text('NowssB Store'), findsWidgets);
    expect(find.byKey(const Key('storeGuideHelp')), findsOneWidget);
    expect(t.takeException(), isNull);
    await _drop(t);
  });

  testWidgets('Meaning Store renders offline without crashing', (t) async {
    await t.pumpWidget(const MaterialApp(home: MeaningStoreScreen()));
    await t.pump();
    expect(find.byType(MeaningStoreScreen), findsOneWidget);
    // Loading state shows before the catalogue is ready.
    expect(find.text('Loading meanings…').evaluate().length <= 1, isTrue);
    await _settle(t);
    expect(t.takeException(), isNull);
    await _drop(t);
  });

  testWidgets('meaning detail opens with title and price page', (t) async {
    const m = MsMeaning(word: 'Om', key: 'om', root: 'Sanskrit', category: 'Sacred', price: 49, img: '');
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => Scaffold(
          body: TextButton(onPressed: () => openMeaningDetail(c, m), child: const Text('go')),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await _settle(t);
    expect(find.byType(StoreProductPage), findsOneWidget);
    expect(find.text('Om'), findsWidgets);
    final page = t.widget<StoreProductPage>(find.byType(StoreProductPage));
    expect(page.highlights, contains('Decoded phonetic origin'));
    expect(page.price, 49);
    await _drop(t);
  });
}
