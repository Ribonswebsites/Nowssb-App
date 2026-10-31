import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/data/billing_config.dart';
import 'package:flutter/services.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/screens/reader/reader_book.dart';
import 'package:nowssb/screens/store/product_detail.dart';

import 'fake_video_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final book = kEbBooks.first;
  final id = 'ebook:${book.title.toLowerCase()}';

  final obs = _Obs();

  Future<void> openDetail(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(430, 932));
    await t.pumpWidget(MaterialApp(
      navigatorObservers: [obs],
      home: Builder(builder: (c) => Scaffold(body: Center(child: TextButton(onPressed: () => openEbookDetail(c, book), child: const Text('go'))))),
    ));
    await t.tap(find.text('go'));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> done(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 30));
  }

  setUpAll(() {
    SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
    FakeVideoPlatform();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (c) async => '/tmp/pp');
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
  });

  testWidgets('Not owned: shows a local price and Buy on Google Play', (t) async {
    Entitlements.instance.debugSet(owned: {});
    await openDetail(t);
    expect(find.text('Buy on Google Play'), findsOneWidget);
    expect(find.text('Yours — read it now'), findsNothing);
    await done(t);
  });

  testWidgets('Owned ebook: "read it now" opens the reader, Add to Cart is refused', (t) async {
    Entitlements.instance.debugSet(owned: {ownedDocId(id)});
    await openDetail(t);
    expect(find.text('Yours — read it now'), findsOneWidget);
    final before = CartBag.instance.cart.length;
    await t.ensureVisible(find.text('Add to Cart'));
    await t.tap(find.text('Add to Cart'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('already yours'), findsOneWidget);
    expect(CartBag.instance.cart.length, before);
    await t.ensureVisible(find.text('Yours — read it now'));
    obs.pushed.clear();
    await t.tap(find.text('Yours — read it now'));
    // The reader route is pushed with this exact book (not built here:
    // its book fonts load from the network, and tests are offline).
    final r = obs.pushed.single as MaterialPageRoute<void>;
    final page = r.builder(t.element(find.byType(StoreProductPage))) as ReaderBookScreen;
    expect(page.kind, ReaderKind.ebook);
    expect(page.initialBook, same(book));
    await done(t);
  });
}


class _Obs extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushed.add(route);
}
