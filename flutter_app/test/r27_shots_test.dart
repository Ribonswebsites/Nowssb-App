/// R27 (Ribon 10-27) shots at 390 and 320 @1.3x + hook checks.
/// Run: flutter test test/r27_shots_test.dart --dart-define=RITUAL_OUT=/tmp/r27
@Tags(['shots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nowssb/widgets/concept/normal/surface.dart';
import 'package:nowssb/widgets/concept/r27/anims.dart';
import 'package:nowssb/widgets/concept/r27/data.dart';
import 'package:nowssb/widgets/concept/r27/hero.dart';
import 'package:nowssb/widgets/concept/r27/kit.dart';
import 'package:nowssb/widgets/concept/r27/pages.dart';
import 'package:nowssb/widgets/concept/r27/sections.dart';

const _out = String.fromEnvironment('RITUAL_OUT', defaultValue: '/tmp/r27');
final hits = <String>[];
void Function() h(String k) => () => hits.add(k);

Future<void> _fonts() async {
  final dm = FontLoader('DM Sans');
  for (final f in ['Regular', 'Light', 'Medium', 'Bold', 'ExtraBold']) {
    final file = File('assets/icons/DMSans-$f.ttf');
    if (file.existsSync()) dm.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await dm.load();
  await (FontLoader('Anton')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Anton-Regular.ttf').readAsBytesSync())))).load();
  const mi = '/home/box/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (File(mi).existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File(mi).readAsBytesSync())))).load();
  }
}

// ── SAMPLE shot inputs (not app data). At runtime every value comes from
// R27Live (EconomyMirror summary / kGiftCatalog / GiftBook / EarnWallet). ──
// 492 coins mirrors Ribon's 10-27 screenshot.
const rewards = R27Rewards(coins: 492, streak: 3, loginToday: false);
const rewardsOut = R27Rewards(coins: 0, streak: 0, loginToday: false, signedIn: false);
// = _kGiftDefaults in lib/features/gifts/gifts_screen.dart
const gifts = R27Gifts(sent: 2, received: 1, cards: [
  R27Gift('stage', 'Stage card', 49), R27Gift('word', 'Word card', 99), R27Gift('bundle', 'Bundle card', 499),
  R27Gift('basic7', '7-day Basic', 79), R27Gift('ebook7', '7-day ebook', 49), R27Gift('standard30', '30-day Standard', 499),
  R27Gift('premium30', '30-day Premium', 999), R27Gift('signature3', '3-day Signature', 199),
  R27Gift('ebook30', '30-day ebook pass', 149), R27Gift('restore', 'Streak Restore', 99),
]);
const earn = R27Earn(ranks: kR27RankDefaults, wordsSold: 140, ratePct: 22, nextTarget: 500, code: 'NWSB42');
final coupons = R27Coupons(scratchedToday: false, sealed: const {'legendary': 1, 'rare': 2, 'common': 3}, coupons: [
  R27Coupon(label: '20% off any word', pct: 20, scope: 'words', capInr: 200, expiresAt: DateTime(2026, 11, 3).millisecondsSinceEpoch),
  const R27Coupon(label: '10% off a stage', pct: 10, scope: 'stages', capInr: 100),
]);
const couponsEmpty = R27Coupons(scratchedToday: true, sealed: {}, coupons: []);
const ojas = R27HourWord('ojas', 'OJAS', 'Essential vigor, life essence'); // = library.json 'ojas'

Widget _videoSwaps() => Column(children: [
      R27NeuFrame(child: Padding(padding: const EdgeInsets.only(right: 18, bottom: 12), child: Row(children: [
        const Expanded(child: R27Head(hello: 'Sound Library', title: 'Orb', sub: 'Replaces orb-loop.mp4')),
        const R27SoundOrb(size: 120),
      ]))),
      R27NeuFrame(child: Padding(padding: const EdgeInsets.only(right: 18, bottom: 12), child: Row(children: [
        const Expanded(child: R27Head(hello: 'Streak', title: '3 days', sub: 'Replaces player-aura-bg.mp4 (92 px well)')),
        Container(decoration: neu(r: 60), padding: const EdgeInsets.all(6), child: const R27BreathFlame(streak: 3, size: 92)),
      ]))),
      R27NeuFrame(child: Padding(padding: const EdgeInsets.only(right: 18, bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: R27Head(hello: 'Offers and earning', title: 'Words that carry meaning', sub: 'Replaces hero-meaning-store.mp4 and the coin Lottie')),
          Container(decoration: neu(r: 40), padding: const EdgeInsets.all(6), child: const R27Coin(size: 52)),
        ]),
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(20), child: const AspectRatio(aspectRatio: 2.2, child: R27PosterDrift(hours: ['soma', 'surya', 'chandra']))),
      ]))),
      R27NeuFrame(child: Padding(padding: const EdgeInsets.only(right: 18, bottom: 12), child: Row(children: [
        const Expanded(child: R27Head(hello: 'Ritual card', title: 'Meditator', sub: 'Replaces the Cleopatra and red-haired model cut-outs')),
        Container(
          decoration: BoxDecoration(color: r27Black, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(8),
          child: const R27Meditator(size: Size(120, 120)),
        ),
      ]))),
    ]);

final shots = <String, (Widget Function(), Color)>{
  'normal-rewards': (() => R27RewardsSection(data: rewards, onOpen: h('rewards'), onClaim: h('claim'), onSignIn: h('signin')), nBase),
  'normal-gifts': (() => R27GiftsSection(data: gifts, onGift: (id) => hits.add('gift:$id'), onRedeem: h('redeem'), onOpen: h('gifts')), nBase),
  'normal-earn': (() => R27EarnSection(data: earn, onOpen: h('earn'), onRank: (i) => hits.add('rank:$i')), nBase),
  'normal-coupons': (() => R27CouponsSection(data: coupons, onScratch: h('scratch'), onOpen: h('coupons'), onCoupon: (i) => hits.add('coupon:$i')), nBase),
  'normal-coupons-empty': (() => R27CouponsSection(data: couponsEmpty, onScratch: h('scratch'), onOpen: h('coupons'), onCoupon: (i) => hits.add('coupon:$i')), nBase),
  'normal-video-swaps': (_videoSwaps, nBase),
  'normal-meditation-banner': (() => R27MeditationBanner(hourCount: 12, onTap: h('meditation')), nBase),
  'fashion-rewards': (() => R27RewardsSection(fashion: true, data: rewards, onOpen: h('rewards'), onClaim: h('claim'), onSignIn: h('signin')), r27Black),
  'fashion-gifts': (() => R27GiftsSection(fashion: true, data: gifts, onGift: (id) => hits.add('gift:$id'), onRedeem: h('redeem'), onOpen: h('gifts')), r27Black),
  'fashion-earn': (() => R27EarnSection(fashion: true, data: earn, onOpen: h('earn'), onRank: (i) => hits.add('rank:$i')), r27Black),
  'fashion-coupons': (() => R27CouponsSection(fashion: true, data: coupons, onScratch: h('scratch'), onOpen: h('coupons'), onCoupon: (i) => hits.add('coupon:$i')), r27Black),
  'fashion-sound-hero': (() => R27SoundHero(hour: ojas, orbit: const ['surya', 'chandra', 'soma', 'ananda', 'tejas', 'prana'], onListen: h('listen'), onOwn: h('own')), r27Black),
  'page-rewards': (() => R27RewardsPage(data: rewards, onBack: h('back'), onClaim: h('claim'), onVault: h('vault'), onSignIn: h('signin'), onHowItWorks: h('how')), r27Black),
  'page-rewards-signedout': (() => R27RewardsPage(data: rewardsOut, onBack: h('back'), onClaim: h('claim'), onVault: h('vault'), onSignIn: h('signin'), onHowItWorks: h('how')), r27Black),
  'page-gifts': (() => R27GiftsPage(data: gifts, onBack: h('back'), onGift: (id) => hits.add('gift:$id'), onRedeem: h('redeem'), onHistory: h('history')), r27Black),
  'page-earn': (() => R27EarnPage(data: earn, onBack: h('back'), onHub: h('hub'), onInvite: h('invite'), onRank: (i) => hits.add('rank:$i')), r27Black),
  'page-coupons': (() => R27CouponsPage(data: coupons, onBack: h('back'), onScratch: h('scratch'), onCoupon: (i) => hits.add('coupon:$i'), onSealed: (r) => hits.add('sealed:$r'), onRules: h('rules')), r27Black),
};

void main() {
  setUpAll(() async {
    await _fonts();
    NormalMotion.freeze = .35;
  });

  Future<void> pump(WidgetTester t, Widget w, double width, double scale, Color bg, {GlobalKey? key}) async {
    t.view.physicalSize = Size(width * 3, 2400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Builder(builder: (ctx) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)),
        child: Scaffold(backgroundColor: bg, body: SingleChildScrollView(child: RepaintBoundary(key: key,
          child: Container(color: bg, padding: const EdgeInsets.symmetric(vertical: 14), child: w))))),
      )));
    await t.runAsync(() async {
      for (final e in find.byType(Image).evaluate().toList()) {
        await precacheImage((e.widget as Image).image, e);
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump(const Duration(milliseconds: 100));
  }

  Future<void> shot(WidgetTester t, String name, Widget w, double width, double scale, Color bg) async {
    final key = GlobalKey();
    await pump(t, w, width, scale, bg, key: key);
    expect(t.takeException(), isNull, reason: 'overflow in $name');
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 3);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      Directory(_out).createSync(recursive: true);
      File('$_out/r27-$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  for (final e in shots.entries) {
    testWidgets('${e.key} 390', (t) => shot(t, '${e.key}-390', e.value.$1(), 390, 1, e.value.$2));
    testWidgets('${e.key} 320', (t) => shot(t, '${e.key}-320', e.value.$1(), 320, 1.3, e.value.$2));
  }

  Future<void> tapText(WidgetTester t, String s) async {
    final f = find.textContaining(s);
    expect(f, findsWidgets, reason: 'missing "$s"');
    await t.ensureVisible(f.first);
    await t.pump();
    final v = find.textContaining(s).hitTestable();
    await t.tap(v.evaluate().isNotEmpty ? v.first : f.first, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 200));
  }

  testWidgets('hooks fire', (t) async {
    hits.clear();
    await pump(t, Column(children: [
      R27RewardsSection(data: rewards, onOpen: h('rewards'), onClaim: h('claim'), onSignIn: h('signin')),
      R27GiftsSection(data: gifts, onGift: (id) => hits.add('gift:$id'), onRedeem: h('redeem'), onOpen: h('gifts')),
      R27EarnSection(data: earn, onOpen: h('earn'), onRank: (i) => hits.add('rank:$i')),
      R27CouponsSection(data: coupons, onScratch: h('scratch'), onOpen: h('coupons'), onCoupon: (i) => hits.add('coupon:$i')),
    ]), 390, 1, nBase);
    for (final s in ['Open rewards', 'Redeem a gift code', 'All gifts', 'Open NowssB Earn', "Scratch today's card", 'Open coupons', 'Gift it', 'Assistant Officer']) {
      await tapText(t, s);
    }
    expect(hits, containsAll(['rewards', 'redeem', 'gifts', 'earn', 'scratch', 'coupons', 'rank:0']));
    expect(hits.any((e) => e.startsWith('gift:')), isTrue);
  });

  testWidgets('page hooks fire', (t) async {
    hits.clear();
    await pump(t, Column(children: [
      R27RewardsPage(data: rewards, onBack: h('back'), onClaim: h('claim'), onVault: h('vault'), onSignIn: h('signin'), onHowItWorks: h('how')),
      R27GiftsPage(data: gifts, onBack: h('back'), onGift: (id) => hits.add('gift:$id'), onRedeem: h('redeem'), onHistory: h('history')),
      R27EarnPage(data: earn, onBack: h('back'), onHub: h('hub'), onInvite: h('invite'), onRank: (i) => hits.add('rank:$i')),
      R27CouponsPage(data: coupons, onBack: h('back'), onScratch: h('scratch'), onCoupon: (i) => hits.add('coupon:$i'), onSealed: (r) => hits.add('sealed:$r'), onRules: h('rules')),
      R27SoundHero(hour: ojas, orbit: const ['surya', 'chandra'], onListen: h('listen'), onOwn: h('own')),
      R27MeditationBanner(hourCount: 12, onTap: h('meditation')),
    ]), 390, 1, r27Black);
    for (final s in ["Claim today's coin", 'Open the vault', 'How rewards work', 'Redeem a gift code someone', 'Gift history',
        'Open NowssB Earn', 'Invite with', "Scratch today's card", 'Rules and odds', 'Listen', 'Own this word', 'Begin', 'Tap to scratch', '20% off any word']) {
      await tapText(t, s);
    }
    print('PAGEHITS $hits');
    expect(hits, containsAll(['claim', 'vault', 'how', 'redeem', 'history', 'hub', 'invite', 'scratch', 'rules', 'listen', 'own', 'meditation', 'sealed:legendary', 'coupon:0']));
  });
}
