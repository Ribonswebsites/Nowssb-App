// Coins are offered, never credited silently: Collect card → server → bar.
// Set COINS_SHOTS=<dir> to write coin-collect-*.png renders.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/economy/coin_collect.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/economy/reward_fx.dart' show reportEarn;
import 'package:nowssb/widgets/nwsb_coin_fly.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
}

Map<String, dynamic> summary({int free = 40, int openDone = 0}) => {
      'wallet': {'coins': 1240},
      'today': {
        'freeCoins': free, 'ceiling': 250, 'ceilingNow': 250,
        'actions': [
          {'id': 'open', 'title': 'Open the app', 'coins': 5, 'per': 'day', 'limit': 1, 'done': openDone, 'free': true},
          {'id': 'word_of_day', 'title': 'Word of the day', 'coins': 10, 'per': 'day', 'limit': 1, 'done': 0, 'free': true},
          {'id': 'read_meaning', 'title': 'Read one meaning to the end', 'coins': 8, 'per': 'day', 'limit': 3, 'done': 1, 'free': true},
          {'id': 'profile_complete', 'title': 'Complete your profile', 'coins': 50, 'per': 'once', 'limit': 1, 'done': 0, 'free': false},
        ],
      },
    };

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PendingCoins.instance.debugReset();
    EconomyMirror.instance.summary = summary();
  });
  tearDown(() => EconomyApi.debugHandler = null);

  test('an activity only offers coins; nothing reaches the server until Collect', () async {
    final calls = <String>[];
    EconomyApi.debugHandler = (name, data) async {
      calls.add('$name:${data['action'] ?? ''}');
      return name == 'reportAction' ? {'coins': 5, 'action': data['action']} : summary(free: 45, openDone: 1);
    };
    reportEarn('open');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(calls, isEmpty);
    expect(PendingCoins.instance.total, 5);
    // A repeat offer the same day is not doubled.
    await PendingCoins.instance.offer('open');
    expect(PendingCoins.instance.items.length, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nwsb_pending_coins_v1'), contains('"open"'));

    final got = await PendingCoins.instance.collect();
    expect(got, 5);
    expect(calls.first, 'reportAction:open');
    expect(PendingCoins.instance.items, isEmpty);
  });

  test('already earned today on the server: no offer', () async {
    EconomyMirror.instance.summary = summary(openDone: 1);
    await PendingCoins.instance.offer('open');
    expect(PendingCoins.instance.items, isEmpty);
  });

  test('offline keeps the coins waiting', () async {
    EconomyApi.debugHandler = (name, data) async => throw EconomyException('offline', code: 'offline');
    await PendingCoins.instance.offer('word_of_day');
    expect(await PendingCoins.instance.collect(), 0);
    expect(PendingCoins.instance.total, 10);
  });

  test('today bar: collected vs left from real daily sources and the cap', () {
    final d = CoinDay.fromSummary(summary())!;
    expect(d.collected, 40);
    expect(d.left, 5 + 10 + 16); // open + word of day + 2 meanings; once-only excluded
    expect(CoinDay.fromSummary({'today': {'freeCoins': 245, 'ceilingNow': 250, 'actions': summary()['today']['actions']}})!.left, 5);
    expect(CoinDay.fromSummary(const {}), isNull);
  });

  testWidgets('Collect card: amount, today bar, Collect tap', (t) async {
    await _font('DMSans', '${Directory.current.path}/test/fonts/DMSans.ttf');
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    var tapped = false;
    final key = GlobalKey();
    final items = const [
      PendingEarn(action: 'open', coins: 5, title: 'Open the app'),
      PendingEarn(action: 'word_of_day', coins: 10, title: 'Word of the day'),
    ];
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DMSans'),
      home: RepaintBoundary(
        key: key,
        child: Scaffold(
          backgroundColor: const Color(0xFF05070D),
          body: Center(child: CoinOfferCard(items: items, day: CoinDay.fromSummary(summary()), onCollect: () => tapped = true, onLater: () {})),
        ),
      ),
    ));
    await t.runAsync(() => precacheImage(const AssetImage(NwsbCoinFly.disc), key.currentContext!));
    await t.pump(const Duration(milliseconds: 1200));
    expect(find.text('+15 coins'), findsOneWidget);
    expect(find.text('40 collected · 31 left'), findsOneWidget);
    await shot(t, key, 'popup');
    await t.tap(find.byKey(const Key('coin-collect-button')));
    expect(tapped, isTrue);
  });

  testWidgets('After collect: wallet pill with today bar', (t) async {
    t.view.physicalSize = const Size(390, 200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    EconomyMirror.instance.summary = summary(free: 55, openDone: 1);
    await _font('DMSans', '${Directory.current.path}/test/fonts/DMSans.ttf');
    final key = GlobalKey();
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DMSans'),
      home: RepaintBoundary(
        key: key,
        child: const Scaffold(backgroundColor: Color(0xFF05070D), body: Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: 20), child: CoinWalletPill(total: 1255, punch: 0.6, width: 358)))),
      ),
    ));
    expect(find.text('today 55 · 26 left'), findsOneWidget);
    await shot(t, key, 'bar');
  });

  testWidgets('Collect animation: coins fly into the wallet', (t) async {
    await _font('DMSans', '${Directory.current.path}/test/fonts/DMSans.ttf');
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    NwsbCoinFly.debugPlayInTests = true;
    addTearDown(() => NwsbCoinFly.debugPlayInTests = false);
    EconomyMirror.instance.summary = summary(free: 55, openDone: 1);
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DMSans'),
        home: const Scaffold(backgroundColor: Color(0xFF05070D), body: SizedBox.expand()),
      ),
    ));
    await t.runAsync(() => precacheImage(const AssetImage(NwsbCoinFly.disc), key.currentContext!));
    final ctx = t.element(find.byType(Scaffold));
    final done = NwsbCoinFly.show(ctx, coins: 15, from: 1240, to: 1255);
    await t.pump();
    for (var i = 0; i < 13; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(CoinWalletPill), findsOneWidget);
    await shot(t, key, 'animation');
    await t.pump(const Duration(seconds: 4));
    await t.pumpAndSettle();
    await done;
  });
}


Future<void> shot(WidgetTester t, GlobalKey key, String name) async {
  final dir = Platform.environment['COINS_SHOTS'];
  if (dir == null || dir.isEmpty) return;
  await t.runAsync(() async {
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/coin-collect-$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
