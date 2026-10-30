// Coins page + wallet pill. Set COINS_SHOTS=<dir> to write coins-v2-*.png renders.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/coins/coins_screen.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/widgets/nwsb_coin_fly.dart';

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
}

// Shape of the server `summary` (functions/_lib/economy/summary.js).
final summary = <String, dynamic>{
  'wallet': {'coins': 1240},
  'today': {
    'freeCoins': 63, 'ceiling': 250, 'ceilingNow': 250, 'minutes': 22,
    'actions': [
      {'id': 'open', 'title': 'Open the app', 'coins': 5, 'per': 'day', 'limit': 1, 'done': 1},
      {'id': 'ring_say', 'title': 'Practice Ring · say it aloud', 'coins': 8, 'per': 'day', 'limit': 1, 'done': 0},
      {'id': 'sound_bath', 'title': 'Sound Bath session', 'coins': 10, 'per': 'day', 'limit': 2, 'done': 1},
      {'id': 'read_meaning', 'title': 'Read one meaning to the end', 'coins': 8, 'per': 'day', 'limit': 3, 'done': 2},
      {'id': 'profile_complete', 'title': 'Complete your profile', 'coins': 50, 'per': 'once', 'limit': 1, 'done': 0},
    ],
    'timeLadder': [{'minutes': 10, 'coins': 10}, {'minutes': 20, 'coins': 20}, {'minutes': 40, 'coins': 40}],
  },
  'recentCoins': [
    {'delta': 20, 'reason': 'ladder'}, {'delta': 5, 'reason': 'action:open'}, {'delta': 10, 'reason': 'login'},
  ],
  'config': {'coinsPerRupee': 10, 'cart': {'noCouponCoinPct': 30, 'coinCapBands': [{'pct': 30}, {'pct': 35}, {'pct': 40}]}},
};

void main() {
  final shots = Platform.environment['COINS_SHOTS'];
  Future<void> shot(WidgetTester t, GlobalKey key, String name) async {
    if (shots == null) return;
    await t.pump(const Duration(milliseconds: 100));
    await t.runAsync(() async {
      final img = await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 1);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/coins-v2-$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  setUpAll(() => _font('Roboto', '/usr/share/fonts/truetype/sand-box/google/Roboto/Roboto-VariableFont_wdth,wght.ttf'));

  Widget frame(GlobalKey key, Widget child) => RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', brightness: Brightness.dark),
          home: Scaffold(backgroundColor: const Color(0xFF0B0A12), body: SafeArea(child: child)),
        ),
      );

  testWidgets('Coins page shows today, caps, sources and the Store rule', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    await t.pumpWidget(frame(key, CoinsBody(summary: summary)));
    expect(find.text('1240'), findsOneWidget);
    expect(find.text('Earned today 63'), findsOneWidget);
    expect(find.text('187 left to earn'), findsOneWidget);
    expect(find.text('16 of 24 · 2 of 3 today'), findsOneWidget);
    expect(find.text('Enter today\u2019s draw'), findsOneWidget);
    expect(find.text('Winners and reviews'), findsOneWidget);
    await shot(t, key, '1-top');
    await t.scrollUntilVisible(find.textContaining('Store: up to 30%'), 300);
    expect(find.textContaining('with a coupon, up to 40%'), findsOneWidget);
    await shot(t, key, '2-use');
  });

  testWidgets('Wallet pill: total, progress bar and glass wallet circle', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    EconomyMirror.instance.summary = summary;
    await t.pumpWidget(frame(key, const Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: 10), child: CoinWalletPill(total: 1250, width: 358)))));
    expect(find.text('1250'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    expect(find.text('today 63 / 250'), findsOneWidget);
    await shot(t, key, '3-pill');
  });
}
