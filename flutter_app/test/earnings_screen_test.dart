import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "dart:ui" show ImageByteFormat;
import "package:flutter/rendering.dart";
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/earn/earnings_data.dart';
import 'package:nowssb/features/earn/earnings_screen.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSource implements EarningsSource {
  FakeSource(this.stream);
  final Stream<EarningsSnapshot> stream;
  @override
  Stream<EarningsSnapshot> watch(String uid) => stream;
}

final _sample = EarningsSnapshot(rows: [
  EarningRow(tab: 'words', title: 'Word sale · Serenity', cents: 250, status: 'Available', at: DateTime(2026, 10, 12)),
  EarningRow(tab: 'words', title: 'Word sale · Calm', cents: 199, status: 'Pending', at: DateTime(2026, 10, 18)),
  EarningRow(tab: 'subscriptions', title: 'Yearly plan', cents: 900, status: 'Reversed', at: DateTime(2026, 9, 2)),
  EarningRow(tab: 'bonuses', title: 'Team sale · level 1', cents: 120, status: 'Pending', at: DateTime(2026, 10, 3)),
], payouts: [
  EarningRow(tab: 'payout', title: 'Withdrawal', cents: 1500, status: 'Paid', at: DateTime(2026, 9, 30)),
]);

final _key = GlobalKey();

/// main has no assets/icons/nwsb-coin.webp yet (flagged); serve the app's
/// existing rewards coin art in its place so the coin pill renders in tests.
class _Bundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      rootBundle.load(key == 'assets/icons/nwsb-coin.webp' ? 'assets/rails/rewards-coins.png' : key);
}

Widget _app(Widget child) => DefaultAssetBundle(bundle: _Bundle(), child: RepaintBoundary(key: _key, child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
      home: Material(
        type: MaterialType.transparency,
        child: Stack(children: [
          // Stand-in for the app's own background video (a still from the app's assets).
          Positioned.fill(child: Image.asset('assets/rails/earnings-01.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: const Color(0x66000000))),
          child,
        ]),
      ),
    )));

final _vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

Future<void> _toTabs(WidgetTester t) => t.scrollUntilVisible(find.byKey(const Key('earnings.tab.words')), 200, scrollable: _vertical);

Future<void> _shot(WidgetTester tester, int n) async {
  if (!Platform.environment.containsKey('EARNINGS_SHOTS')) return;
  await tester.runAsync(() async {
    for (final el in find.byType(Image).evaluate()) {
      await precacheImage((el.widget as Image).image, el);
    }
  });
  await tester.pump();
  await tester.runAsync(() async {
    final b = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    File('/workspace/screens/earnings-v2-$n.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _fonts() async {
  const dir = '/workspace/flutter/bin/cache/artifacts/material_fonts';
  if (!Directory(dir).existsSync()) return;
  final roboto = FontLoader('Roboto');
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']) {
    final file = File('$dir/$f');
    if (file.existsSync()) roboto.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File('$dir/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

void main() {
  setUpAll(() async {
    if (Platform.environment.containsKey('EARNINGS_SHOTS')) await _fonts();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({EarningsScreen.guideKey: true});
    final w = EconomyMirror.instance
      ..uid = 'u1'
      ..cash = 2450
      ..wordsSold = 62
      ..sellerTier = 'Seller'
      ..payoutRail = 'wise'
      ..country = 'US';
    w.coins = 0;
  });

  Future<void> phone(WidgetTester t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  testWidgets('loading then data, tabs switch', (t) async {
    await phone(t);
    final c = StreamController<EarningsSnapshot>();
    await t.pumpWidget(_app(EarningsScreen(source: FakeSource(c.stream))));
    await t.pump();
    await _toTabs(t);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    c.add(_sample);
    await t.pump();
    expect(find.text('Word sale · Serenity'), findsOneWidget);
    await t.drag(_vertical, const Offset(0, 2000));
    await t.pump();
    expect(find.text('Available'), findsWidgets);
    await _shot(t, 1);
    await _toTabs(t);
    await t.ensureVisible(find.byKey(const Key('earnings.tab.subscriptions')));
    await t.pump();
    await t.tap(find.byKey(const Key('earnings.tab.subscriptions')));
    await t.pump();
    expect(find.text('Reversed', skipOffstage: false), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('earnings.tab.meanings')));
    await t.pump();
    await t.tap(find.byKey(const Key('earnings.tab.meanings')));
    await t.pump();
    expect(find.textContaining('Nothing here yet', skipOffstage: false), findsOneWidget);
    await c.close();
  });

  testWidgets('error state', (t) async {
    await phone(t);
    await t.pumpWidget(_app(EarningsScreen(source: FakeSource(Stream.error('offline')))));
    await t.pump();
    await t.pump();
    await _toTabs(t);
    expect(find.textContaining('Could not load'), findsOneWidget);
  });

  testWidgets('signed out state', (t) async {
    await phone(t);
    EconomyMirror.instance.uid = null;
    await t.pumpWidget(_app(EarningsScreen(source: FakeSource(Stream.value(_sample)))));
    await t.pump();
    expect(find.text('Sign in to see your money'), findsOneWidget);
  });

  testWidgets('withdraw is 3 steps and ends in confirm', (t) async {
    await phone(t);
    await t.pumpWidget(_app(EarningsScreen(source: FakeSource(Stream.value(_sample)))));
    await t.pump();
    await t.tap(find.byKey(const Key('earnings.withdraw')));
    await t.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    await _shot(t, 2);
    await t.tap(find.byKey(const Key('withdraw.next')));
    await t.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    await t.tap(find.byKey(const Key('withdraw.next')));
    await t.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);
    await t.tap(find.byKey(const Key('withdraw.next')));
    await t.pumpAndSettle();
    expect(find.text('Withdraw now?'), findsOneWidget);
    await t.tap(find.text('Cancel').last);
    await t.pumpAndSettle();
  });

  testWidgets('no account linked asks to link first', (t) async {
    await phone(t);
    EconomyMirror.instance.payoutRail = '';
    await t.pumpWidget(_app(EarningsScreen(source: FakeSource(Stream.value(_sample)))));
    await t.pump();
    await t.tap(find.byKey(const Key('earnings.withdraw')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('withdraw.next')));
    await t.pumpAndSettle();
    expect(find.text('Link account'), findsOneWidget);
    await t.tap(find.byKey(const Key('withdraw.next')));
    await t.pumpAndSettle();
    expect(find.text('Link your payout account'), findsOneWidget);
    expect(find.textContaining('UPI'), findsNothing);
    expect(find.textContaining('PAN'), findsNothing);
    await _shot(t, 3);
    await t.tap(find.byKey(const Key('payout.save')));
    await t.pump();
    expect(find.text('Enter the email you use with Wise.'), findsOneWidget);
  });

  testWidgets('first-use guide shows once and help replays it', (t) async {
    await phone(t);
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(_app(EarningsScreen(source: FakeSource(Stream.value(_sample)))));
    await t.pumpAndSettle();
    expect(find.text('Share your link'), findsOneWidget);
    await _shot(t, 4);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
    }
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(EarningsScreen.guideKey), isTrue);
    await t.tap(find.byKey(const Key('earnings.help')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('help.replay')));
    await t.pumpAndSettle();
    expect(find.text('Share your link'), findsOneWidget);
  });

  testWidgets('info pop-up explains a number', (t) async {
    await phone(t);
    await t.pumpWidget(_app(EarningsScreen(source: FakeSource(Stream.value(_sample)))));
    await t.pump();
    await t.tap(find.byKey(const Key('earnings.info.Pending')));
    await t.pumpAndSettle();
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('statements sub-page groups by month', (t) async {
    await phone(t);
    await t.pumpWidget(_app(EarningsStatementsPage(source: FakeSource(Stream.value(_sample)))));
    await t.pump();
    await t.pump();
    expect(find.text('2026-10'), findsOneWidget);
    expect(find.text('2026-09'), findsOneWidget);
    await _shot(t, 5);
  });

  test('status and tab mapping', () {
    expect(statusLabel('pending_hold'), 'Pending');
    expect(statusLabel('reversed'), 'Reversed');
    expect(statusLabel('paid'), 'Paid');
    expect(tabFor('Meaning sale'), 'meanings');
    expect(tabFor('Subscription share'), 'subscriptions');
  });
}
