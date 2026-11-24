// Coins come only from finishing a real task or the daily check-in (the
// first launch of the IST day, once). Opening pages never offers coins,
// Later does not bring the card back on the next page, and the card is in
// the NowssB frosted glass. Set COINS_POPUP_SHOTS=<dir> for renders.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/features/coins/coins_screen.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/features/economy/coin_collect.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/economy/reward_fx.dart' show reportEarn;
import 'package:nowssb/features/economy/reward_overlay.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/quotes_live.dart' show DailyQuoteGate;
import 'package:nowssb/screens/splash.dart' show SplashGate;
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/theme/theme.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'package:nowssb/widgets/nwsb_coin_fly.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

final _shots = Platform.environment['COINS_POPUP_SHOTS'] ?? '';
final _key = GlobalKey();
final _card = find.byKey(const Key('coin-collect-button'));

Map<String, dynamic> _summary({int openDone = 0, int listenDone = 0}) => {
      'wallet': {'coins': 1240},
      'today': {
        'freeCoins': 40, 'ceiling': 250, 'ceilingNow': 250,
        'actions': [
          {'id': 'open', 'title': 'Open the app', 'coins': 5, 'per': 'day', 'limit': 1, 'done': openDone, 'free': true},
          {'id': 'ring_listen', 'title': 'Practice Ring · listen', 'coins': 5, 'per': 'day', 'limit': 1, 'done': listenDone, 'free': true},
          {'id': 'explore', 'title': 'Visit a program page', 'coins': 2, 'per': 'day', 'limit': 6, 'done': 0, 'free': true},
        ],
      },
    };

Future<void> _settle(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _shot(WidgetTester t, String name) async {
  if (_shots.isEmpty) return;
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_shots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(b!.buffer.asUint8List());
  });
}

void main() {
  late List<String> calls;

  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1', 'nwsb_player_guide_seen': true});
    RewardOverlay.debugPlayInTests = true;
    RewardOverlay.debugReset();
    NwsbCoinFly.debugPlayInTests = true;
    PendingCoins.debugIgnoreGates = true;
    await PendingCoins.instance.debugReset();
    EconomyMirror.instance.summary = _summary();
    calls = [];
    EconomyApi.debugHandler = (name, data) async {
      calls.add('$name:${data['action'] ?? ''}');
      return name == 'reportAction' ? {'coins': 5, 'action': data['action']} : _summary(openDone: 1);
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

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() => ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {}));
    await t.pumpWidget(MaterialApp(
      theme: NwsbTheme.light,
      debugShowCheckedModeBanner: false,
      navigatorKey: RewardOverlay.navigatorKey,
      builder: (c, child) => RepaintBoundary(
          key: _key,
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: Colors.black)),
            const Positioned.fill(child: FaintFilm()),
            child ?? const SizedBox(),
          ])),
      home: const NavShell(),
    ));
    await _settle(t, 14);
    final agree = find.text('I Agree · Continue');
    if (agree.evaluate().isNotEmpty) {
      await t.tap(agree.first, warnIfMissed: false);
      await _settle(t, 8);
    }
  }

  Future<void> tapNav(WidgetTester t, String label) async {
    final f = find.text(label);
    expect(f, findsWidgets, reason: label);
    await t.tap(f.last, warnIfMissed: false);
    await _settle(t, 8);
  }

  testWidgets('first launch of the day: +5 Daily check-in once; Later; 5 pages open with no pop-up and no coins', (t) async {
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {};
    try {
      // The Zen home (the 'Afternoon Session' page the pop-up was seen on).
      await t.runAsync(() => Settings.instance.setFashionHome(true));
      await boot(t);
      await _settle(t, 10);
      expect(_card, findsOneWidget, reason: 'the first launch of the day offers the check-in');
      expect(find.text('+5 coins'), findsOneWidget);
      expect(find.text('Daily check-in'), findsOneWidget);
      // NowssB glass, not the gold card.
      expect(find.text('COLLECT · RECEIVE · KEEP'), findsNothing);
      expect(find.descendant(of: find.byType(CoinOfferCard), matching: find.byType(BackdropFilter)), findsOneWidget);
      expect(calls.where((c) => c.startsWith('reportAction')), isEmpty, reason: 'never auto-collected');
      await t.tap(find.text('Later'));
      await _settle(t, 8);
      expect(_card, findsNothing);

      // Five pages: Library, Store, Profile, Practice, back to Connect (home).
      for (final page in ['Library', 'Store', 'Profile', 'Practice', 'Connect']) {
        await tapNav(t, page);
        await _settle(t, 12);
        expect(_card, findsNothing, reason: 'no pop-up after opening $page');
      }
      expect(calls.where((c) => c.startsWith('reportAction')), isEmpty, reason: 'no coins for opening pages');
      expect(PendingCoins.instance.items.map((e) => e.action), ['open'], reason: 'pages offered nothing new');
      await _shot(t, '02-home-after-5-pages-no-popup');

      // The Coins wallet's Collect brings the waiting check-in back, by choice.
      unawaited(PendingCoins.instance.showWaiting());
      await _settle(t, 12);
      expect(_card, findsOneWidget);
      expect(find.text('Daily check-in'), findsOneWidget);
      await _shot(t, '01-popup-daily-check-in');
      await t.tap(find.text('Later'));
      await _settle(t, 8);
      expect(_card, findsNothing);

      // The old page-visit trigger and a rebuilt home shell are both silent now.
      reportEarn('explore', key: 'store');
      await PendingCoins.instance.showOnLaunch();
      await _settle(t, 12);
      expect(_card, findsNothing);
      expect(PendingCoins.instance.items.length, 1);
    } finally {
      FlutterError.onError = prev;
      await t.runAsync(() => Settings.instance.setFashionHome(false));
    }
  });

  test('a second launch the same day offers nothing', () async {
    await PendingCoins.instance.offer('open');
    expect(PendingCoins.instance.total, 5);
    expect(await PendingCoins.instance.collect(), 5);
    // New launch, same day: the phone remembers today's check-in.
    await PendingCoins.instance.debugReset();
    EconomyMirror.instance.summary = _summary(); // even before the server summary updates
    await PendingCoins.instance.offer('open');
    expect(PendingCoins.instance.items, isEmpty);
  });

  test('a reinstall the same day offers nothing when the server has the check-in', () async {
    await PendingCoins.instance.offer('open');
    await PendingCoins.instance.collect();
    SharedPreferences.setMockInitialValues({}); // the phone's storage is wiped
    await PendingCoins.instance.debugReset();
    EconomyMirror.instance.summary = _summary(openDone: 1);
    await PendingCoins.instance.offer('open');
    expect(PendingCoins.instance.items, isEmpty);
  });

  test('visiting a page never offers coins', () async {
    for (final p in ['earn', 'store', 'coins', 'circle', 'print']) {
      reportEarn('explore', key: p);
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(PendingCoins.instance.items, isEmpty);
    expect(CoinDay.fromSummary(_summary())!.left, 10, reason: 'page visits are not counted as coins left today');
  });

  testWidgets('Later keeps it away for the run; a new task shows only itself; next launch shows it once', (t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      navigatorKey: RewardOverlay.navigatorKey,
      home: const Scaffold(backgroundColor: Color(0xFF05070D), body: SizedBox.expand()),
    ));
    Future<void> run(Future<void> Function() f) async {
      RewardOverlay.debugReset(); // in this test's own fake-async zone
      unawaited(f());
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
      await t.pump(const Duration(milliseconds: 900));
      await t.pump(const Duration(milliseconds: 600));
    }

    await run(() => PendingCoins.instance.offer('open'));
    expect(_card, findsOneWidget);
    await t.tap(find.text('Later'));
    await t.pump(const Duration(milliseconds: 700));
    await t.pump(const Duration(milliseconds: 700));
    expect(_card, findsNothing);
    // The shell rebuilt / launch hook again in the same run: nothing.
    await run(() => PendingCoins.instance.showOnLaunch());
    await run(() => PendingCoins.instance.showOnLaunch());
    expect(_card, findsNothing);
    // A real task finishes: its own card, without the check-in put away.
    await run(() => PendingCoins.instance.offer('ring_listen'));
    expect(_card, findsOneWidget);
    expect(find.text('Practice Ring · listen'), findsOneWidget);
    expect(find.text('Daily check-in'), findsNothing);
    await t.tap(find.text('Later'));
    await t.pump(const Duration(milliseconds: 700));
    await t.pump(const Duration(milliseconds: 700));
    // The Coins wallet can still open everything waiting.
    await run(() => PendingCoins.instance.showWaiting());
    expect(find.text('2 rewards ready'), findsOneWidget);
    await t.tap(find.text('Later'));
    await t.pump(const Duration(milliseconds: 700));
    await t.pump(const Duration(milliseconds: 700));
    expect(calls.where((c) => c.startsWith('reportAction')), isEmpty);
    // Next launch: offered once, then not again.
    await PendingCoins.instance.debugReset();
    await run(() => PendingCoins.instance.showOnLaunch());
    expect(_card, findsOneWidget);
    expect(find.text('+10 coins'), findsOneWidget);
    await t.tap(find.text('Later'));
    await t.pump(const Duration(milliseconds: 700));
    await t.pump(const Duration(milliseconds: 700));
    await run(() => PendingCoins.instance.showOnLaunch());
    expect(_card, findsNothing);
  });

  testWidgets('finishing a practice offers its reward once', (t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.runAsync(() => ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {}));
    final word = ContentStore.instance.library.first;
    await t.pumpWidget(MaterialApp(
      navigatorKey: RewardOverlay.navigatorKey,
      home: const Scaffold(backgroundColor: Color(0xFF05070D), body: SizedBox.expand()),
    ));
    RewardOverlay.debugReset(); // in this test's own fake-async zone
    unawaited(PracticeProgress.instance.recordCompletedWord(word));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    expect(_card, findsOneWidget);
    expect(find.text('+5 coins'), findsOneWidget);
    expect(find.text('Practice Ring · listen'), findsOneWidget);
    await t.tap(_card);
    await t.pump();
    await t.pump(const Duration(seconds: 5));
    expect(calls.where((c) => c == 'reportAction:ring_listen').length, 1);
    // A second finished practice the same day: no second offer.
    unawaited(PracticeProgress.instance.recordCompletedWord(word));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    expect(_card, findsNothing);
    expect(PendingCoins.instance.items, isEmpty);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('the Coins wallet lists what is waiting and Collect opens the card', (t) async {
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    RewardOverlay.debugReset();
    unawaited(PendingCoins.instance.offer('open'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
      navigatorKey: RewardOverlay.navigatorKey,
      builder: (c, child) => RepaintBoundary(key: _key, child: child),
      home: Scaffold(
        backgroundColor: const Color(0xFF0B0A12),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: PendingCoins.instance,
            builder: (context, _) => CoinsBody(summary: _summary(openDone: 1)),
          ),
        ),
      ),
    ));
    // The launch card for the offer: put it away with Later.
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    if (_card.evaluate().isNotEmpty) {
      await t.tap(find.text('Later'));
      await t.pump(const Duration(milliseconds: 700));
      await t.pump(const Duration(milliseconds: 700));
    }
    expect(_card, findsNothing);
    expect(find.text('Waiting to collect'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('coins-waiting')), matching: find.text('Daily check-in')), findsOneWidget);
    expect(find.text('Visit a program page'), findsNothing, reason: 'page visits are not listed as a way to earn');
    await _shot(t, '03-coins-wallet-waiting');
    await t.tap(find.byKey(const Key('coins-waiting-collect')));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 600));
    expect(_card, findsOneWidget);
    expect(calls.where((c) => c.startsWith('reportAction')), isEmpty, reason: 'still only on the Collect tap');
    await t.tap(_card);
    await t.pump();
    await t.pump(const Duration(seconds: 5));
    expect(calls.where((c) => c == 'reportAction:open').length, 1);
    expect(PendingCoins.instance.items, isEmpty);
    await t.pump(const Duration(seconds: 2));
  });

  test('only tasks and the daily check-in offer coins anywhere in the app', () {
    const allowed = {'open', 'ring_listen', 'first_share', 'echo_first_post', 'profile_complete', 'referral_welcome', 'referral_friend'};
    final re = RegExp(r'''(?:reportEarn|PendingCoins\.instance\.offer)\(\s*'([a-z0-9_]+)''');
    final found = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final m in re.allMatches(f.readAsStringSync())) {
        found.add(m.group(1)!);
        expect(allowed, contains(m.group(1)), reason: '${f.path} offers coins for "${m.group(1)}"');
      }
    }
    expect(found, contains('open'));
    expect(found, isNot(contains('explore')));
    expect(File('lib/features/programs/program_kit.dart').readAsStringSync(), isNot(contains('reportExplore')));
  });
}
