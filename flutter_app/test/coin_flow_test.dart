// The daily "Open the app" coins: the Collect pop-up always shows, nothing is
// credited without a tap on Collect, the fly-in and count-up run only after
// the credit is confirmed, and Later leaves the coins waiting. Set
// COINFLOW_SHOTS=<dir> for renders.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/economy/coin_collect.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/economy/reward_overlay.dart';
import 'package:nowssb/screens/quotes_live.dart' show DailyQuoteGate;
import 'package:nowssb/screens/splash.dart' show SplashGate;
import 'package:nowssb/widgets/nwsb_coin_fly.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/home_render.dart';

const _shots = String.fromEnvironment('COINFLOW_SHOTS');

Map<String, dynamic> _summary({int free = 40, int openDone = 0}) => {
      'wallet': {'coins': 1240},
      'today': {
        'freeCoins': free, 'ceiling': 250, 'ceilingNow': 250,
        'actions': [
          {'id': 'open', 'title': 'Open the app', 'coins': 5, 'per': 'day', 'limit': 1, 'done': openDone, 'free': true},
          {'id': 'word_of_day', 'title': 'Word of the day', 'coins': 10, 'per': 'day', 'limit': 1, 'done': 0, 'free': true},
        ],
      },
    };

final _key = GlobalKey();

Future<void> _app(WidgetTester t) async {
  t.view.physicalSize = const Size(390 * 2, 844 * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DM Sans'),
    navigatorKey: RewardOverlay.navigatorKey,
    builder: (c, child) => RepaintBoundary(key: _key, child: child),
    home: const Scaffold(backgroundColor: Color(0xFF05070D), body: SizedBox.expand()),
  ));
  await precacheAll(t);
}

Future<void> _snap(WidgetTester t, String name) async {
  if (_shots.isEmpty) return;
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 16));
  await t.runAsync(() async {
    final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: 2);
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_shots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(b!.buffer.asUint8List());
  });
}

/// An activity happened. (The offer's own storage waits for real I/O, so give
/// it a moment, then let the fake clock see what it started.)
Future<void> _offer(WidgetTester t, String action) async {
  // Inside the test's own fake-async zone, so a play left by an earlier test cannot block this one.
  RewardOverlay.debugReset();
  unawaited(PendingCoins.instance.offer(action));
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
  await t.pump();
}

final _card = find.byKey(const Key('coin-collect-button'));

void main() {
  setUpAll(setUpHomeRender);

  late List<String> calls;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RewardOverlay.debugPlayInTests = true;
    NwsbCoinFly.debugPlayInTests = true;
    PendingCoins.debugIgnoreGates = true;
    await PendingCoins.instance.debugReset();
    EconomyMirror.instance.summary = _summary();
    calls = [];
    EconomyApi.debugHandler = (name, data) async {
      calls.add('$name:${data['action'] ?? ''}');
      return name == 'reportAction' ? {'coins': 5, 'action': data['action']} : _summary(free: 45, openDone: 1);
    };
  });
  tearDown(() async {
    RewardOverlay.debugPlayInTests = false;
    NwsbCoinFly.debugPlayInTests = false;
    PendingCoins.debugIgnoreGates = false;
    SplashGate.done.value = false;
    DailyQuoteGate.done.value = false;
    EconomyApi.debugHandler = null;
    await PendingCoins.instance.debugReset();
  });

  testWidgets('an uncollected reward always shows the pop-up', (t) async {
    await _app(t);
    await _offer(t, 'open');
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    expect(_card, findsOneWidget);
    expect(find.text('+5 coins'), findsOneWidget);
    await _snap(t, '1-popup');
    expect(calls, isEmpty, reason: 'showing the pop-up credits nothing');
  });

  testWidgets('the pop-up still comes when the screen is not ready yet', (t) async {
    // Offer first, with no navigator on screen at all (cold start).
    await _offer(t, 'open');
    await t.pump(const Duration(milliseconds: 900));
    expect(_card, findsNothing);
    await _app(t);
    await t.pump(const Duration(milliseconds: 1300));
    await t.pump(const Duration(milliseconds: 600));
    expect(_card, findsOneWidget, reason: 'it retries instead of giving up');
    expect(calls, isEmpty);
  });

  testWidgets('a reward left from an earlier launch comes back', (t) async {
    await _app(t);
    await _offer(t, 'open');
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Later'));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 600));
    expect(_card, findsNothing);
    // Next launch, same day: the reward is on the phone and shows again.
    await PendingCoins.instance.debugReset();
    unawaited(PendingCoins.instance.show());
    await t.pump(const Duration(milliseconds: 100));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pump(const Duration(milliseconds: 700));
    expect(_card, findsOneWidget);
    expect(calls, isEmpty);
  });

  testWidgets('it waits for the splash and the daily quote, then shows', (t) async {
    PendingCoins.debugIgnoreGates = false;
    SplashGate.done.value = false;
    DailyQuoteGate.done.value = false;
    await _app(t);
    await _offer(t, 'open');
    await t.pump(const Duration(seconds: 3));
    expect(_card, findsNothing, reason: 'not underneath the splash');
    SplashGate.done.value = true;
    await t.pump(const Duration(seconds: 1));
    expect(_card, findsNothing, reason: 'nor on top of the daily quote');
    DailyQuoteGate.done.value = true;
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 600));
    expect(_card, findsOneWidget);
  });

  testWidgets('nothing is credited without a tap on Collect', (t) async {
    await _app(t);
    await _offer(t, 'open');
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(seconds: 20));
    expect(_card, findsOneWidget, reason: 'it waits for the user');
    expect(calls, isEmpty);
    // A tap on the dim area is not a Collect and does not close it.
    await t.tapAt(const Offset(8, 8));
    await t.pump(const Duration(milliseconds: 600));
    expect(_card, findsOneWidget);
    expect(calls, isEmpty);
    expect(PendingCoins.instance.total, 5);
  });

  testWidgets('Later closes it and credits nothing, the coins stay waiting', (t) async {
    await _app(t);
    await _offer(t, 'open');
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.text('Later'));
    await t.pump(const Duration(milliseconds: 700));
    await t.pump(const Duration(seconds: 5));
    expect(_card, findsNothing);
    expect(find.byType(CoinWalletPill), findsNothing);
    expect(calls, isEmpty);
    expect(PendingCoins.instance.total, 5);
    final p = await t.runAsync(SharedPreferences.getInstance);
    expect(p!.getString('nwsb_pending_coins_v1'), contains('"open"'));
  });

  testWidgets('Collect does not fly or count up until the credit is confirmed', (t) async {
    final slow = Completer<void>();
    EconomyApi.debugHandler = (name, data) async {
      calls.add('$name:${data['action'] ?? ''}');
      if (name == 'reportAction') {
        await slow.future; // the server takes "forever"
        return {'coins': 5, 'action': data['action']};
      }
      return _summary(free: 45, openDone: 1);
    };
    await _app(t);
    await _offer(t, 'open');
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(_card);
    await t.pump(); // the tap's own frame
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 30)); // real frames, 300 ms in all
    }
    expect(find.byType(CoinWalletPill), findsNothing, reason: 'no fly-in before the credit is confirmed');
    expect(find.text('today 45 · 10 left'), findsNothing, reason: 'the wallet must not count up early');
    expect(find.text('1245'), findsNothing);
    expect(calls, ['reportAction:open'], reason: 'the server call is in flight, nothing credited yet');
    expect(PendingCoins.instance.total, 5, reason: 'still waiting for the server');
    expect(_card, findsOneWidget, reason: 'the card stays up while it waits');
    // The server answers late: then the fly-in and count-up run, once.
    slow.complete();
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 30));
    }
    expect(PendingCoins.instance.total, 0);
    expect(find.byType(CoinWalletPill), findsOneWidget, reason: 'the bar appears only after the credit');
    expect(find.text('today 45 · 10 left'), findsOneWidget, reason: 'with the confirmed coins counted');
    await _snap(t, '2-bar-after-credit');
    expect(calls.where((c) => c.startsWith('reportAction')).length, 1);
    await t.pump(const Duration(seconds: 4));
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(CoinWalletPill), findsNothing, reason: 'the flight has finished');
  });

  testWidgets('Collect works the same when the server is quick', (t) async {
    await _app(t);
    await _offer(t, 'open');
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(_card);
    await t.pump();
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 30));
    }
    expect(find.byType(CoinWalletPill), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
    expect(calls.first, 'reportAction:open');
    expect(calls, contains('summary:'), reason: "today's numbers refresh after, not before");
    expect(PendingCoins.instance.total, 0);
  });

  testWidgets('a double tap on Collect credits once', (t) async {
    await _app(t);
    await _offer(t, 'open');
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(_card, warnIfMissed: false);
    await t.tap(_card, warnIfMissed: false);
    await t.pump(const Duration(seconds: 5));
    expect(calls.where((c) => c.startsWith('reportAction')).length, 1);
  });

  testWidgets('offline: Collect does not fly or count up; coins stay pending; saved state is shown', (t) async {
    EconomyApi.debugHandler = (name, data) async {
      calls.add('$name:${data['action'] ?? ''}');
      throw EconomyException('offline', code: 'offline');
    };
    await _app(t);
    await _offer(t, 'open');
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('40 collected · 15 left'), findsOneWidget);
    await t.tap(_card);
    await t.pump();
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 30));
    }
    await t.pump(const Duration(milliseconds: 200));
    expect(find.byType(CoinWalletPill), findsNothing, reason: 'no fly-in when the credit never happened');
    expect(find.text('1245'), findsNothing, reason: 'the wallet must not count up');
    expect(find.text('today 45 · 10 left'), findsNothing);
    expect(PendingCoins.instance.total, 5, reason: 'nothing lost; still pending');
    expect(find.byKey(const Key('coin-collect-saved')), findsOneWidget);
    expect(find.text('Saved, will collect when online'), findsOneWidget);
    // The offer card's today bar is unchanged: no optimistic collected count.
    expect(find.text('40 collected · 15 left'), findsOneWidget);
    await _snap(t, '3-saved-offline');
  });

  testWidgets('a reward that arrives while the card is open is not collected by that tap', (t) async {
    await _app(t);
    await _offer(t, 'open');
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    await _offer(t, 'word_of_day');
    await t.tap(_card);
    await t.pump(const Duration(milliseconds: 200));
    await t.pump(const Duration(seconds: 4));
    expect(calls.where((c) => c.startsWith('reportAction')), ['reportAction:open'], reason: 'only what the card showed');
    // The new one gets its own card, still uncollected.
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 600));
    expect(_card, findsOneWidget);
    expect(find.text('+10 coins'), findsOneWidget);
    expect(PendingCoins.instance.total, 10);
  });
}
