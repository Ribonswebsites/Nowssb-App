// Earn pages in the betting-reference layout, NowssB glass (Ribon, Nov 23): the Your Earnings sheet, the
// Your day card, Complete your profile, every NowssB Earn Programmes tab and
// the coin pill that drops over the page header. Fit checks at 360 and 390,
// text scale 1.0 and 1.3. Shots: --dart-define=ES_SHOTS=<dir>.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/account/complete_profile_page.dart';
import 'package:nowssb/features/account/profile_details.dart';
import 'package:nowssb/features/account/referral_capture.dart';
import 'package:nowssb/features/circle/circle_screen.dart';
import 'package:nowssb/features/earn/earn_kit.dart';
import 'package:nowssb/features/earn/your_earnings_section.dart';
import 'package:nowssb/features/economy/coin_collect.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/header.dart';
import 'package:nowssb/screens/fashion/sections_top.dart';
import 'package:nowssb/widgets/nwsb_coin_fly.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

const _out = String.fromEnvironment('ES_SHOTS');
final _key = GlobalKey();

/// A brand-new account as the server starts it (Ribon's own screenshots).
Map<String, dynamic> _summary() => {
      'enabled': true,
      'countryOk': true,
      'words': 0,
      'words90': 0,
      'standing': {'metal': 'Bronze', 'title': 'Assistant Officer', 'ratePct': 0, 'nextWords': 100, 'nextTitle': 'Officer', 'keep90': 5, 'canEarn': false, 'teamMax': 0, 'leg': [0, 0], 'appoints': <String>[]},
      'balances': {'pendingINR': 0, 'availableINR': 0, 'lifetimeINR': 0, 'minPayoutINR': 1250},
      'payoutAccount': <String, dynamic>{},
      'ledger': <Map<String, dynamic>>[],
      'targets': [
        for (final (w, cash, coins, card) in const [(100, 1000, 300, 'rare'), (500, 3500, 1000, 'epic'), (1000, 4500, 2000, 'legendary'), (2000, 9000, 4000, 'legendary'), (3000, 10500, 6000, 'mythic')])
          {'words': w, 'cashINR': cash, 'coins': coins, 'coupon': card, 'reached': false},
      ],
      'ranks': [
        {'title': 'Assistant Officer', 'minWords': 0, 'ratePct': 0, 'leg': [0, 0], 'plan': 'any', 'metal': 'Bronze'},
        {'title': 'Officer', 'minWords': 100, 'ratePct': 10, 'leg': [3, 1], 'plan': 'any', 'metal': 'Silver'},
        {'title': 'Senior Officer', 'minWords': 500, 'ratePct': 15, 'leg': [4, 2], 'plan': 'top', 'metal': 'Gold'},
      ],
      'team': <Map<String, dynamic>>[],
      'invites': <Map<String, dynamic>>[],
      'sentInvites': <Map<String, dynamic>>[],
    };

Completer<Map<String, dynamic>>? _hold;

void _fake() {
  EconomyApi.debugHandler = (name, data) async {
    if (name == 'earnSummary') return _summary();
    if (name == 'linkHub') {
      if (_hold != null) return _hold!.future;
      return {'url': 'https://nowssb.com/w/app?r=RIBO2611', 'code': 'RIBO2611', 'links': <Map<String, dynamic>>[]};
    }
    return <String, dynamic>{};
  };
  final m = EconomyMirror.instance;
  m.live = true;
  m.uid = 'new-user';
  m.coins = 18;
  m.summary = {'earn': {'ranks': _summary()['ranks']}, 'today': {'freeCoins': 7, 'ceiling': 250, 'actions': []}};
}

Future<void> _mount(WidgetTester t, Widget home, {double w = 390, double h = 844, double scale = 1}) async {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(milliseconds: 600));
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale), padding: const EdgeInsets.only(top: 32, bottom: 16), disableAnimations: true),
      child: RepaintBoundary(key: _key, child: child!),
    ),
    home: home,
  ));
  await _settle(t);
}

Future<void> _settle(WidgetTester t, [int n = 16]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _shot(WidgetTester t, String name) async {
  if (_out.isEmpty) return;
  try {
    await precacheAll(t);
  } catch (_) {}
  await _settle(t, 4);
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// The Zen top as on the home: greeting, Begin Your Healing Path, Your day.
Widget _zen() => Scaffold(
      backgroundColor: Colors.black,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(.8, -.3), radius: 1.3, colors: [Color(0xFF3A1D78), Color(0xFF0E061E), Color(0xFF000000)], stops: [0, .55, 1]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Builder(
              builder: (c) => Column(children: [
                HeroGreeting(name: 'Ribon', onQuickAccess: () {}),
                FashGreeting(below: HomeTrioSection(light: false, padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), onQuick: () {})),
              ]),
            ),
          ),
        ),
      ),
    );

Widget _profile() => CompleteProfilePage(
      uid: 'u1',
      initial: const ProfileDetails(name: 'Ribon Patil', country: 'IN', phoneCountry: 'IN'),
      onDone: () {},
      onSkip: () {},
    );

/// The coin pill exactly where the fly-in drops it, over the page.
Widget _withPill(Widget page) => Builder(
      builder: (c) => Stack(children: [
        page,
        Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.paddingOf(c).top + 10,
          child: Material(
            type: MaterialType.transparency,
            child: Center(
            child: CoinWalletPill(
              total: 18,
              width: MediaQuery.sizeOf(c).width - 32,
              day: const CoinDay(collected: 7, left: 243, ceiling: 250),
            ),
          ),
          ),
        ),
      ]),
    );

const _tabs = ['overview', 'team', 'sales', 'targets', 'payouts', 'invite', 'academy', 'rules'];

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(() async {
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() async {
    VideoPool.instance.debugDropAll();
    await ReferralCapture.instance.debugReset();
    await PendingCoins.instance.debugReset();
    PendingCoins.debugIgnoreGates = true;
    PendingCoins.debugAutoShow = () => false;
    ReferralCapture.debugLinks = const Stream<Uri>.empty();
    ReferralCapture.debugInstallReferrer = () async => null;
    _hold = null;
    debugEarnName = 'Ribon';
    _fake();
  });
  tearDown(() {
    EconomyApi.debugHandler = null;
    ReferralCapture.debugLinks = null;
    ReferralCapture.debugInstallReferrer = null;
    PendingCoins.debugAutoShow = null;
    PendingCoins.debugIgnoreGates = false;
    VideoPool.instance.debugDropAll();
  });

  Future<void> done(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  }

  for (final w in const [360.0, 390.0]) {
    for (final s in const [1.0, 1.3]) {
      testWidgets('no overflow at ${w.toInt()}@$s: every Earn tab, the sheet, Your day, profile', (t) async {
        for (final id in _tabs) {
          await _mount(t, EarnTabsPage(initialTab: id), w: w, h: 2200, scale: s);
          expect(t.takeException(), isNull, reason: 'tab $id');
        }
        await _mount(t, _zen(), w: w, h: 1000, scale: s);
        expect(t.takeException(), isNull, reason: 'Your day');
        await t.tap(find.byKey(const ValueKey('trio-earnings')));
        await _settle(t);
        expect(t.takeException(), isNull, reason: 'sheet');
        await t.tap(find.byKey(const ValueKey('earn-sheet-expand')));
        await _settle(t);
        expect(t.takeException(), isNull, reason: 'sheet expanded');
        await _mount(t, _profile(), w: w, h: 1200, scale: s);
        expect(t.takeException(), isNull, reason: 'profile');
        await done(t);
      });
    }
  }

  testWidgets('tab row: the picked pill sits fully on screen', (t) async {
    for (final id in _tabs) {
      await _mount(t, EarnTabsPage(initialTab: id), w: 360, h: 1400);
      final label = {'overview': 'Overview', 'team': 'My Team', 'sales': 'Sales', 'targets': 'Targets and Bonuses', 'payouts': 'Payouts', 'invite': 'Invite friends', 'academy': 'Academy', 'rules': 'Rules and Disclaimer'}[id]!;
      final r = t.getRect(find.bySemanticsLabel(label).first);
      expect(r.left, greaterThanOrEqualTo(0), reason: id);
      expect(r.right, lessThanOrEqualTo(360), reason: id);
    }
    await done(t);
  });

  testWidgets('reference layout: header, balance card, icon chips and the detail pill row switch tabs', (t) async {
    await _mount(t, const EarnTabsPage(initialTab: 'overview'), w: 390, h: 2200);
    expect(find.byKey(const ValueKey('earn-avatar')), findsOneWidget);
    expect(find.text('Hey,'), findsOneWidget);
    expect(find.byKey(const ValueKey('earn-hey')), findsOneWidget);
    expect(find.byKey(const ValueKey('earn-bell')), findsOneWidget);
    expect(find.byKey(const ValueKey('earn-balance-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('earn-action-payout')), findsOneWidget);
    expect(find.byKey(const ValueKey('earn-action-invite')), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.byKey(const ValueKey('program-tab-pills')), findsOneWidget);
    // A round icon chip switches the tab.
    await t.tap(find.bySemanticsLabel('Sales').first);
    await _settle(t);
    expect(find.byKey(const ValueKey('earn-sales-card')), findsOneWidget);
    // The detail pill row switches it too.
    await t.ensureVisible(find.bySemanticsLabel('My Team tab'));
    await t.tap(find.bySemanticsLabel('My Team tab'));
    await _settle(t);
    expect(find.byKey(const ValueKey('earn-team-card')), findsOneWidget);
    await done(t);
  });

  testWidgets('shots', (t) async {
    if (_out.isEmpty) return;
    final warm = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) warm?.call(d);
    };
    await _mount(t, _zen());
    await _shot(t, '00_warm');
    FlutterError.onError = warm;

    await _mount(t, _zen());
    await _shot(t, '01_your_day');
    await t.tap(find.byKey(const ValueKey('trio-earnings')));
    await _settle(t);
    await _shot(t, '02_your_earnings_sheet');
    await t.tap(find.byKey(const ValueKey('earn-sheet-expand')));
    await _settle(t);
    await _shot(t, '03_your_earnings_sheet_expanded');

    await _mount(t, _profile());
    await _shot(t, '04_complete_profile');

    var i = 5;
    for (final id in _tabs) {
      await _mount(t, EarnTabsPage(initialTab: id), h: id == 'targets' || id == 'payouts' ? 1500 : 1100);
      await _shot(t, '${'$i'.padLeft(2, '0')}_programmes_$id');
      i++;
    }
    for (final id in _tabs) {
      await _mount(t, EarnTabsPage(initialTab: id), w: 360, h: id == 'targets' || id == 'payouts' ? 1700 : 1300, scale: 1.3);
      await _shot(t, '${'$i'.padLeft(2, '0')}_programmes_${id}_360_x1.3');
      i++;
    }
    await _mount(t, _zen(), w: 360, h: 1000, scale: 1.3);
    await t.tap(find.byKey(const ValueKey('trio-earnings')));
    await _settle(t);
    await t.tap(find.byKey(const ValueKey('earn-sheet-expand')));
    await _settle(t);
    await _shot(t, '${'$i'.padLeft(2, '0')}_your_earnings_sheet_360_x1.3');
    i++;
    await _mount(t, _profile(), w: 360, h: 1000, scale: 1.3);
    await _shot(t, '${'$i'.padLeft(2, '0')}_complete_profile_360_x1.3');
    i++;
    _hold = Completer();
    await _mount(t, const EarnTabsPage(initialTab: 'invite'));
    await _shot(t, '${'$i'.padLeft(2, '0')}_programmes_invite_loading');
    i++;
    _hold!.complete({'url': '', 'code': '', 'links': <Map<String, dynamic>>[]});
    await _mount(t, _withPill(const EarnTabsPage(initialTab: 'team')));
    await _shot(t, '${'$i'.padLeft(2, '0')}_programmes_team_coin_pill');
    await done(t);
  });
}
