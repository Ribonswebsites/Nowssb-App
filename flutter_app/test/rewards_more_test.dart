import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/features/programs/rewards_more.dart';
import 'package:nowssb/features/programs/rewards_program.dart';

Widget _host(List<Widget> Function(BuildContext, Map<String, dynamic>) b, Map<String, dynamic> s) => MaterialApp(
      home: Scaffold(body: Builder(builder: (c) => ListView(children: b(c, s)))),
    );

final _s = <String, dynamic>{
  'wallet': {'coins': 120, 'streak': 3, 'nextLogin': 5},
  'today': {'login': false},
  'boost': {'available': true},
  'chests': [
    {'id': 'd3', 'title': 'Day 3 chest', 'day': 3},
    {'id': 'd7', 'title': 'Day 7 chest', 'day': 7},
  ],
  'coupons': [
    {'title': '10% off words', 'code': 'ABC'},
    {'title': 'Old coupon', 'expired': true},
  ],
  'gifts': [
    {'title': 'Calm gift'}
  ],
  'config': {
    'rewards': {
      'boost': {'multiplier': 2, 'hours': 24},
      'spend': {
        'theme': {'title': 'Calm theme', 'coins': 100},
        'big': {'title': 'Big item', 'coins': 500},
      },
    }
  },
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({RewardsGuide.prefKey: true}));

  test('spec 14.3 tabs exist', () {
    final ids = kRewardsSpec.tabs.map((t) => t.id).toList();
    for (final id in ['checkin', 'quests', 'streaks', 'chests', 'boost', 'store', 'mine', 'wallet']) {
      expect(ids, contains(id));
    }
    expect(kRewardsSpec.tabs.firstWhere((t) => t.id == 'wallet').title, 'Coin history');
  });

  testWidgets('check-in shows week and claim', (t) async {
    await t.pumpWidget(_host(rewardsCheckin, _s));
    await t.pump();
    expect(find.text('D1'), findsOneWidget);
    expect(find.text('Check in'), findsOneWidget);
  });

  testWidgets('chests: ready vs locked', (t) async {
    await t.pumpWidget(_host(rewardsChests, _s));
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
  });

  testWidgets('boost never claims spend cap changes', (t) async {
    await t.pumpWidget(_host(rewardsBoost, _s));
    expect(find.text('2x coins earned'), findsOneWidget);
    expect(find.textContaining('never changes how much of a price'), findsOneWidget);
  });

  testWidgets('store confirm dialog and insufficient coins', (t) async {
    await t.pumpWidget(_host(rewardsStore, _s));
    expect(find.text('Need 380'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('spend-theme')));
    await t.pumpAndSettle();
    expect(find.text('Get Calm theme?'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.text('Get Calm theme?'), findsNothing);
  });

  testWidgets('my rewards filters and empty', (t) async {
    await t.pumpWidget(_host(rewardsMine, _s));
    expect(find.text('10% off words'), findsOneWidget);
    expect(find.text('Calm gift'), findsOneWidget);
    await t.tap(find.text('Expired').first);
    await t.pump();
    expect(find.text('Old coupon'), findsOneWidget);
    expect(find.text('Calm gift'), findsNothing);
    await t.tap(find.text('Chests'));
    await t.pump();
    expect(find.text('No chests right now.'), findsOneWidget);
  });

  testWidgets('first-use guide shows once', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: RewardsGuide())));
    await t.pumpAndSettle();
    expect(find.text('Check in daily'), findsOneWidget);
    await t.tap(find.text('Next'));
    await t.pump();
    expect(find.text('Quests and chests'), findsOneWidget);
    await t.tap(find.text('Skip'));
    await t.pumpAndSettle();
    expect(find.text('Quests and chests'), findsNothing);
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: RewardsGuide(key: ValueKey(2)))));
    await t.pumpAndSettle();
    expect(find.text('Check in daily'), findsNothing);
  });
}
