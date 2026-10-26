// Hunter's 65d1347 review: own-plan price, Join tier, no '·' before a
// price, Orders opens the real orders page, no config = no Invite/Partner.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/screens/normal/home_v5.dart';
import 'package:nowssb/screens/store/cart_pages.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/screens/subscription.dart';
import 'package:nowssb/widgets/concept/normal/edition.dart';
import 'package:nowssb/widgets/concept/normal/invite.dart';
import 'package:nowssb/widgets/concept/normal/partner.dart';
import 'package:nowssb/widgets/concept/normal/surface.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

Finder _act(String l) => find.byWidgetPredicate(
    (w) => (w is NPress && w.label == l) || (w is Semantics && w.properties.button == true && w.properties.label == l));

Future<void> _pump(WidgetTester t, Widget child, {double w = 390, double ts = 1}) async {
  t.view.physicalSize = Size(w * 3, 3000 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MediaQuery(
    data: MediaQueryData(size: Size(w, 3000), textScaler: TextScaler.linear(ts), disableAnimations: true),
    child: MaterialApp(theme: ThemeData(fontFamily: 'DM Sans'), home: Scaffold(body: SingleChildScrollView(child: child))),
  ));
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
  });

  testWidgets('1: own plan selected shows Manage and no price line', (t) async {
    await _pump(t, NEdition(onJoin: (_) {}, prices: const {'frequency': '₹199', 'resonance': '₹99'},
        playAvailable: true, currentTier: 'frequency'));
    expect(find.text('Manage Frequency'), findsOneWidget);
    expect(find.textContaining('₹199'), findsNothing);
    await t.tap(_act('Resonance').first);
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Join Resonance'), findsOneWidget);
    expect(find.textContaining('₹99'), findsOneWidget);
  }, skip: !homeFontsReady);

  testWidgets('2: Join passes the chosen tier, and SubscriptionScreen opens on it', (t) async {
    final log = <String>[];
    await _pump(t, NEdition(onJoin: log.add, prices: const {}, playAvailable: true));
    await t.tap(_act('Frequency X').first);
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(_act('Join Frequency X').first);
    expect(log, ['frequencyX']);
    for (final (tier, name) in NEdition.plans) {
      expect(SubscriptionScreen.planNameAt(SubscriptionScreen.indexForTier(tier)), name, reason: tier);
    }
    expect(SubscriptionScreen.indexForTier(null), 0);
    expect(SubscriptionScreen.indexForTier('nope'), 0);
    expect(const SubscriptionScreen(initialTier: 'resonance').initialTier, 'resonance');
  }, skip: !homeFontsReady);

  testWidgets('3+4: no "·" before the Play price arrives; tab labels full size at 320 x1.3', (t) async {
    await _pump(t, NEdition(onJoin: (_) {}, prices: const {}, playAvailable: null), w: 320, ts: 1.3);
    expect(t.takeException(), isNull);
    expect(find.textContaining('·'), findsNothing);
    expect(find.text('Frequency'), findsWidgets);
    for (final (_, name) in NEdition.plans) {
      final txt = t.widget<Text>(find.text(name).first);
      expect(txt.style?.fontSize, nSub.fontSize, reason: name);
    }
  }, skip: !homeFontsReady);

  testWidgets('5: home Orders opens CartPage (bag + Your purchases), not a tab switch', (t) async {
    const w = 390.0, h = 22000.0;
    t.view.physicalSize = const Size(w * 3, h * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final tabs = <int>[];
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(w, h), devicePixelRatio: 3),
      child: MaterialApp(theme: ThemeData(fontFamily: 'DM Sans'),
          home: NavScope(go: tabs.add, child: const HomeNormal())),
    ));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
      t.takeException();
    }
    final f = _act('Orders');
    expect(f, findsWidgets);
    await t.tap(f.first, warnIfMissed: false);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    expect(find.byType(CartPage), findsOneWidget);
    expect(tabs, isEmpty);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(minutes: 2));
  }, skip: !homeFontsReady);

  testWidgets('6: no server config hides Invite and Partner entirely', (t) async {
    await _pump(t, Column(children: [
      V5RewardsInvite(onOpenRewards: () {}, onSignIn: () {}, onInvite: () {}),
      V5EditionPartner(onJoin: (_) {}, onPartner: () {}),
    ]));
    expect(find.byType(NInvite), findsNothing);
    expect(find.byType(NPartner), findsNothing);
    expect(find.text('Invite a friend'), findsNothing);
    expect(find.text('Partner points'), findsNothing);
    expect(find.byType(NEdition), findsOneWidget);
  }, skip: !homeFontsReady);
}
