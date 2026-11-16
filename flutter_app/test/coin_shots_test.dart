// 390-wide shots of the Normal-home NOWSSB EARN card, plus the Coins
// page wallet hero and top pill (the official NowssB coin).
//
// dart-define COIN_SHOT_PREFIX=before|after (default after).
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/coins/coins_screen.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/screens/normal/home_v4.dart';
import 'package:nowssb/widgets/nwsb_coin_fly.dart';

import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

final _shots = Directory('/workspace/team-plan/shots/coin')
  ..createSync(recursive: true);

const _prefix =
    String.fromEnvironment('COIN_SHOT_PREFIX', defaultValue: 'after');

final _summary = <String, dynamic>{
  'wallet': {'coins': 1240},
  'today': {
    'freeCoins': 63,
    'ceiling': 250,
    'ceilingNow': 250,
    'minutes': 22,
    'actions': const [],
    'timeLadder': const [],
  },
  'recentCoins': const [],
  'config': const {'coinsPerRupee': 10},
};

Widget _light(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Builder(
        builder: (c) => MediaQuery(
          data: MediaQuery.of(c).copyWith(
            textScaler: TextScaler.noScaling,
            disableAnimations: true,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              key: const ValueKey('shot'),
              child: ColoredBox(
                color: const Color(0xFFEDEFF3),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

Widget _dark(Key key, Widget child) => RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
        home: Scaffold(
          backgroundColor: const Color(0xFF0B0A12),
          body: SafeArea(child: child),
        ),
      ),
    );

Future<void> _png(WidgetTester t, Finder finder, String name) async {
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 80));
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(finder);
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ImageByteFormat.png);
    File('${_shots.path}/$_prefix-$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    if (!homeFontsReady) {
      for (final fam in ['DM Sans', 'Roboto']) {
        await (FontLoader(fam)
              ..addFont(Future.value(ByteData.sublistView(
                File('assets/fonts/NotoSans-PIE.ttf').readAsBytesSync(),
              ))))
            .load();
      }
    }
  });

  testWidgets('NOWSSB EARN card at 390', (t) async {
    t.view.physicalSize = const Size(390 * 3, 1400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(_light(V4StoreEarn(onStore: () {})));
    await _png(t, find.byKey(const ValueKey('shot')), 'store-earn');
    expect(find.text('NOWSSB EARN'), findsOneWidget);
    expect(find.text('Your share of the net.'), findsOneWidget);
    expect(find.text('Join today'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('Coins wallet hero and top pill at 390', (t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    EconomyMirror.instance.summary = _summary;

    final pageKey = GlobalKey();
    await t.pumpWidget(_dark(pageKey, CoinsBody(summary: _summary)));
    await _png(t, find.byKey(pageKey), 'coins-page');
    expect(find.text('1240'), findsOneWidget);

    final pillKey = GlobalKey();
    await t.pumpWidget(_dark(
      pillKey,
      const Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 10),
          child: CoinWalletPill(total: 1250, width: 358),
        ),
      ),
    ));
    await _png(t, find.byKey(pillKey), 'coins-pill');
    expect(find.text('1250'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
