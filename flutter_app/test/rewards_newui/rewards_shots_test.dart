// Renders phone-size PNGs of the Rewards page when REWARDS_SHOTS=<dir> and
// FLUTTER_ROOT_FONTS=<material_fonts dir> are set; otherwise just smoke-runs.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/rewards_newui/rewards_data.dart';
import 'package:nowssb/features/rewards_newui/rewards_page.dart';

RewardsData _demo() => RewardsData.fromSummary({
      'wallet': {'coins': 1240},
      'today': {'login': false},
      'streaks': {'current': 6},
      'quests': {'weekly': [{'claimed': false}, {'claimed': false}, {'claimed': true}]},
      'chests': {'ready': 1},
      'deal': {'title': 'Calm words bundle, 2x coins back', 'endsAt': DateTime.now().add(const Duration(hours: 5, minutes: 12)).toIso8601String()},
      'myRewards': [
        {'id': 'c1', 'kind': 'coupon', 'title': '20% off a word', 'validTill': '2026-12-31'},
        {'id': 'g1', 'kind': 'gift', 'title': 'Calm pack', 'caption': 'Won for 7-day streak', 'validTill': '2026-11-30'},
        {'id': 'h1', 'kind': 'chest', 'title': 'Weekly chest', 'caption': '3 quests done'},
        {'id': 'c2', 'kind': 'coupon', 'title': 'E-book 15% off', 'validTill': '2026-11-15'},
        {'id': 'x1', 'kind': 'coupon', 'title': 'Old coupon', 'validTill': '2026-01-01'},
        {'id': 'g2', 'kind': 'gift', 'title': 'Thank-you gift', 'caption': 'From a friend'},
      ],
    }, now: DateTime(2026, 10, 13));

void main() {
  final out = Platform.environment['REWARDS_SHOTS'];
  final fonts = Platform.environment['FLUTTER_ROOT_FONTS'];

  Future<void> shot(WidgetTester t, String name, RewardsLoader loader, {Future<void> Function()? then}) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
    if (out != null && fonts != null) {
      await t.runAsync(() async {
        Future<ByteData> f(String n) async => ByteData.sublistView(File('$fonts/$n').readAsBytesSync());
        await (FontLoader('Roboto')..addFont(f('Roboto-Regular.ttf'))..addFont(f('Roboto-Medium.ttf'))..addFont(f('Roboto-Bold.ttf'))).load();
        await (FontLoader('MaterialIcons')..addFont(f('MaterialIcons-Regular.otf'))).load();
      });
    }
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
        home: RewardsNewUiPage(loader: loader),
      ),
    ));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    if (then != null) await then();
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    if (out != null) {
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 2.625);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }
    await t.pumpWidget(const SizedBox());
  }

  Finder scroller() => find.descendant(of: find.byKey(const Key('rewards.scroll')), matching: find.byType(Scrollable)).first;

  testWidgets('1 hub top', (t) => shot(t, 'rewards-1', () async => _demo()));
  testWidgets('2 hub scrolled', (t) => shot(t, 'rewards-2', () async => _demo(), then: () => t.drag(scroller(), const Offset(0, -420))));
  testWidgets('3 my rewards grid', (t) => shot(t, 'rewards-3', () async => _demo(), then: () => t.drag(scroller(), const Offset(0, -1400))));
  testWidgets('4 loading', (t) => shot(t, 'rewards-4', () => Completer<RewardsData>().future));
  testWidgets('5 empty', (t) => shot(t, 'rewards-5', () async => RewardsData.fromSummary(const {})));
  testWidgets('6 error', (t) => shot(t, 'rewards-6', () async => throw Exception('x')));
  testWidgets('7 offline', (t) => shot(t, 'rewards-7', () async => throw const RewardsOffline()));
}
