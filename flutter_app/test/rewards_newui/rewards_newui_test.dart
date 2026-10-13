import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/rewards_newui/rewards_data.dart';
import 'package:nowssb/features/rewards_newui/rewards_flag.dart';
import 'package:nowssb/features/rewards_newui/rewards_page.dart';
import 'package:nowssb/features/rewards_newui/lotus_coin.dart';
import 'package:nowssb/nowssb_ui/nowssb_ui.dart';

final _now = DateTime(2026, 10, 13);
RewardsData _full() => RewardsData.fromSummary({
      'wallet': {'coins': 420},
      'today': {'login': false},
      'streaks': {'current': 7},
      'quests': {
        'weekly': [
          {'claimed': false},
          {'claimed': true}
        ]
      },
      'chests': {'ready': 1},
      'deal': {'title': 'Words bundle, 2x coins back'},
      'myRewards': [
        {'id': 'c1', 'kind': 'coupon', 'title': '20% off a word'},
        {'id': 'g1', 'kind': 'gift', 'title': 'Calm pack', 'caption': 'Won for 7-day streak'},
        {'id': 'x1', 'kind': 'chest', 'title': 'Old chest', 'validTill': '2026-01-01'},
      ],
    }, now: _now);

Future<void> _pump(WidgetTester t, RewardsLoader l, {void Function(String)? onOpen}) async {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 2.5;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: MediaQuery(data: const MediaQueryData(disableAnimations: true), child: RewardsNewUiPage(loader: l, onOpen: onOpen))));
}

Finder _chip(String l) => find.descendant(of: find.byType(FilterChipRow), matching: find.text(l));

void main() {
  test('flag: off for users, on for admins or when flag set', () {
    expect(newUiRewardsOn(isAdmin: false, flag: false), isFalse);
    expect(newUiRewardsOn(isAdmin: true, flag: false), isTrue);
    expect(newUiRewardsOn(isAdmin: false, flag: true), isTrue);
    expect(kNewUiRewardsFlag, 'newui_rewards');
  });

  test('summary mapping', () {
    final d = _full();
    expect(d.coins, 420);
    expect(d.streak, 7);
    expect(d.questsOpen, 1);
    expect(d.items.where((i) => i.expired).single.id, 'x1');
  });

  testWidgets('loading state', (t) async {
    final c = Completer<RewardsData>();
    await _pump(t, () => c.future);
    expect(find.byKey(const Key('rewards.loading')), findsOneWidget);
    c.complete(_full());
    await t.pump();
  });

  testWidgets('error state and retry', (t) async {
    var calls = 0;
    await _pump(t, () async {
      calls++;
      if (calls == 1) throw Exception('boom');
      return _full();
    });
    await t.pump();
    expect(find.byKey(const Key('rewards.error')), findsOneWidget);
    await t.tap(find.text('Try again'));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(calls, 2);
    expect(find.byKey(const Key('rewards.coins')), findsOneWidget);
  });

  testWidgets('offline state', (t) async {
    await _pump(t, () async => throw const RewardsOffline());
    await t.pump();
    expect(find.byKey(const Key('rewards.offline')), findsOneWidget);
  });

  testWidgets('empty state', (t) async {
    await _pump(t, () async => RewardsData.fromSummary(const {}));
    await t.pump();
    expect(find.byKey(const Key('rewards.empty')), findsOneWidget);
    expect(find.text('Check in'), findsOneWidget);
  });

  testWidgets('hub, filters and navigation', (t) async {
    final opened = <String>[];
    await _pump(t, () async => _full(), onOpen: opened.add);
    await t.pump();
    expect(find.text('420'), findsOneWidget);
    expect(find.text('24 hour deal'), findsOneWidget);
    expect(find.text('Unlocks tomorrow'), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const Key('rewards.tile.c1')), 200, scrollable: find.descendant(of: find.byKey(const Key('rewards.scroll')), matching: find.byType(Scrollable)).first);
    await t.ensureVisible(find.byType(FilterChipRow));
    await t.pump();
    await t.scrollUntilVisible(_chip('Expired'), 80, scrollable: find.descendant(of: find.byType(FilterChipRow), matching: find.byType(Scrollable)).first);
    await t.pump();
    await t.tap(_chip('Expired'));
    await t.pump();
    await t.scrollUntilVisible(find.byKey(const Key('rewards.tile.x1')), 200, scrollable: find.descendant(of: find.byKey(const Key('rewards.scroll')), matching: find.byType(Scrollable)).first);
    expect(find.byKey(const Key('rewards.tile.x1')), findsOneWidget);
    expect(find.byKey(const Key('rewards.tile.c1')), findsNothing);
    expect(find.text('Expired'), findsWidgets);
    await t.ensureVisible(find.byType(FilterChipRow));
    await t.pump();
    await t.scrollUntilVisible(_chip('Gifts'), 80, scrollable: find.descendant(of: find.byType(FilterChipRow), matching: find.byType(Scrollable)).first);
    await t.pump();
    await t.tap(_chip('Gifts'));
    await t.pump();
    await t.scrollUntilVisible(find.byKey(const Key('rewards.tile.g1')), 200, scrollable: find.descendant(of: find.byKey(const Key('rewards.scroll')), matching: find.byType(Scrollable)).first);
    expect(find.byKey(const Key('rewards.tile.g1')), findsOneWidget);
    await t.ensureVisible(find.text('Earn & Save'));
    await t.pump();
    await t.tap(find.text('Earn & Save'));
    await t.scrollUntilVisible(find.byKey(const Key('rewards.coins')), -300, scrollable: find.descendant(of: find.byKey(const Key('rewards.scroll')), matching: find.byType(Scrollable)).first);
    await t.tap(find.byKey(const Key('rewards.coins')));
    expect(opened, ['earn', 'coins']);
  });

  testWidgets('lotus coin animates with motion and count-up lands on server value', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: Column(children: [LotusCoin(), CountUpText(420)]))));
    await t.pump(const Duration(milliseconds: 1200));
    expect(find.text('420'), findsOneWidget);
    expect(find.byType(LotusCoin), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('honesty note shown', (t) async {
    await _pump(t, () async => _full());
    await t.pump();
    expect(find.textContaining('no cash value'), findsOneWidget);
  });
}
