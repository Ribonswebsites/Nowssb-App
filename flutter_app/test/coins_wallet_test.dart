import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/data/earn_wallet.dart';
import 'package:nowssb/features/coins/coins_wallet_screen.dart';

final _data = CoinsData(
  signedIn: true,
  coins: 420,
  claimedToday: false,
  streak: 6,
  history: [
    EarnActivity(at: DateTime(2026, 10, 19).millisecondsSinceEpoch, title: 'Daily check-in', detail: 'Day 6', coins: 10),
    EarnActivity(at: DateTime(2026, 10, 18).millisecondsSinceEpoch, title: 'Store order', detail: 'Coins used', coins: -60),
  ],
  expiring: [(80, DateTime.now().add(const Duration(days: 5)).millisecondsSinceEpoch)],
);

Widget _app(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Stack(children: [
        Positioned.fill(child: const ColoredBox(color: Color(0xFF1B2230))),
        child,
      ]),
    );

Future<void> _shot(WidgetTester t, String name) async {
  if (Platform.environment['COINS_SHOTS'] != '1') return;
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
  await t.pump();
  await t.runAsync(() async {
    final ro = t.firstRenderObject<RenderRepaintBoundary>(find.byKey(const Key('shotRoot')));
    final img = await ro.toImage(pixelRatio: 2);
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    File('/workspace/screens/$name.png').writeAsBytesSync(b!.buffer.asUint8List());
  });
}

Future<void> _pump(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(390 * 2, 844 * 2);
  t.view.devicePixelRatio = 2;
  await t.pumpWidget(RepaintBoundary(key: const Key('shotRoot'), child: _app(w)));
  await t.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(() async {
    // Real fonts so Home's header lays out as on a phone (Ahem is too wide).
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/workspace/flutter';
    final dir = Directory('$root/bin/cache/artifacts/material_fonts');
    if (!dir.existsSync()) return;
    final l = FontLoader('Roboto');
    for (final f in dir.listSync().whereType<File>().where((f) => f.path.contains('Roboto-') && f.path.endsWith('.ttf'))) {
      l.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
    await l.load();
    final m = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(File('${dir.path}/MaterialIcons-Regular.otf').readAsBytesSync().buffer)));
    await m.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({kCoinsGuideKey: true}));

  test('cap math never exceeds the cap or the balance', () {
    expect(coinQuote(1000, 9999).coins, (1000 * kCoinCapFraction).floor());
    expect(coinQuote(1000, 50).coins, 50);
    expect(coinQuote(1000, 50).cash, 950);
    expect(coinQuote(-5, 10).coins, 0);
    expect(kCoinCapFraction, inInclusiveRange(0.30, 0.40));
  });

  testWidgets('overview, every tab and calculator work', (t) async {
    await _pump(t, CoinsWalletScreen(data: _data, showGuide: false));
    expect(find.text('420'), findsOneWidget);
    expect(find.byKey(const Key('coinBoost')), findsOneWidget);
    expect(find.textContaining('80 coins expire'), findsOneWidget);
    await _shot(t, 'coins-1');
    await t.tap(find.byKey(const Key('coinsTab_earn')));
    await t.pumpAndSettle();
    expect(find.text('Daily check-in'), findsOneWidget);
    await _shot(t, 'coins-2');
    await t.tap(find.byKey(const Key('coinsTab_use')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('capPrice')), '1000');
    await t.pumpAndSettle();
    expect((t.widget(find.byKey(const Key('capUse'))) as Text).data, '300');
    expect((t.widget(find.byKey(const Key('capRest'))) as Text).data, '700');
    await _shot(t, 'coins-3');
    await t.tap(find.byKey(const Key('heroHistory')));
    await t.pumpAndSettle();
    expect(find.text('Store order'), findsOneWidget);
    await _shot(t, 'coins-4');
    await t.tap(find.text('Store order'));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('empty and signed-out states', (t) async {
    await _pump(t, const CoinsWalletScreen(initialTab: CoinsTab.history, showGuide: false, data: CoinsData(signedIn: true, coins: 0, claimedToday: true, streak: 0)));
    expect(find.byKey(const Key('historyEmpty')), findsOneWidget);
    expect(find.textContaining('None of your coins'), findsNothing);
    await _pump(t, const CoinsWalletScreen(showGuide: false, data: CoinsData(signedIn: false, coins: 0, claimedToday: false, streak: 0)));
    expect(find.text('Sign in to see your coins'), findsOneWidget);
  });

  testWidgets('Earn and Use hero sheets open and close', (t) async {
    await _pump(t, CoinsWalletScreen(data: _data, showGuide: false));
    await t.tap(find.byKey(const Key('heroEarn')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('earnSheet')), findsOneWidget);
    await _shot(t, 'coins-6');
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('earnSheet')), findsNothing);
    await t.tap(find.byKey(const Key('heroUse')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('useSheet')), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    await _shot(t, 'coins-7');
  });

  testWidgets('rules sub-page opens', (t) async {
    await _pump(t, CoinsWalletScreen(data: _data, showGuide: false));
    await t.ensureVisible(find.text('Coin rules'));
    await t.pumpAndSettle();
    await t.tap(find.text('Coin rules'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.text('What coins are'), findsOneWidget);
  });

  testWidgets('first-use guide shows once, steps and closes', (t) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(t, CoinsWalletScreen(data: _data));
    await t.pumpAndSettle();
    expect(find.byType(CoinsGuide), findsOneWidget);
    await _shot(t, 'coins-5');
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
    }
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(find.byType(CoinsGuide), findsNothing);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool(kCoinsGuideKey), true);
  });

  test('coin asset resolves inside flutter_app', () {
    // Builds copy ../assets/icons into the bundle (tools/flutter-assets.mjs).
    expect(File('assets/icons/nwsb-coin.webp').existsSync() || File('../assets/icons/nwsb-coin.webp').existsSync(), true);
  });
}
