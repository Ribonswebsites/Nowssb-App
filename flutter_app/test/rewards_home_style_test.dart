import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/programs/rewards_home_style.dart';
import 'package:nowssb/features/programs/rewards_more.dart';
import 'package:nowssb/features/programs/rewards_program.dart';
import 'package:nowssb/features/vault/vault_screen.dart';

final _s = <String, dynamic>{
  'wallet': {'coins': 240, 'streak': 4, 'nextLogin': 5},
  'today': {'login': false},
  'quests': {
    'starter': [
      {'id': 's1', 'title': 'Practise one word', 'value': 1, 'goal': 1, 'coins': 10, 'claimed': true},
      {'id': 's2', 'title': 'Save a meaning', 'value': 1, 'goal': 1, 'coins': 10},
    ],
    'weekly': [
      {'id': 'w1', 'title': 'Listen 30 minutes', 'value': 12, 'goal': 30, 'coins': 40},
      {'id': 'w2', 'title': 'Five practice days', 'value': 5, 'goal': 5, 'coins': 60, 'claimed': true},
      {'id': 'w3', 'title': 'Read one e-book page', 'value': 0, 'goal': 1, 'coins': 15},
    ],
  },
};

Widget _still() => Image.asset('assets/video/subscription-bg-poster.webp', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1B2230)));

bool get _shots => Platform.environment['REWARDS_SHOTS'] == '1';

Future<void> _shot(WidgetTester t, String name) async {
  if (!_shots) return;
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
  await t.pump();
  await t.runAsync(() async {
    final ro = t.firstRenderObject<RenderRepaintBoundary>(find.byKey(const Key('shotRoot')));
    final img = await ro.toImage(pixelRatio: 2);
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    File('/workspace/screens/$name.png').writeAsBytesSync(b!.buffer.asUint8List());
  });
}

Future<void> _pump(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(390 * 2, 844 * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(RepaintBoundary(key: const Key('shotRoot'), child: MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark(), home: w)));
  await t.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    if (!_shots) return;
    final dir = Directory('/workspace/flutter/bin/cache/artifacts/material_fonts');
    final l = FontLoader('Roboto');
    for (final f in dir.listSync().whereType<File>().where((f) => f.path.contains('Roboto-') && f.path.endsWith('.ttf'))) {
      l.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
    await l.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({RewardsGuide.prefKey: true}));

  test('quest counts come from data', () {
    final c = questCounts(questsOf(_s));
    expect(c[QuestFilter.all], 5);
    expect(c[QuestFilter.completed], 2);
    expect(c[QuestFilter.incomplete], 2);
    expect(c[QuestFilter.ready], 1);
  });

  testWidgets('quest board: course card, counted tabs, filtering', (t) async {
    await _pump(t, RewardsHomeShell(backdrop: _still(), child: ListView(padding: const EdgeInsets.all(16), children: [RewardsQuestBoard(_s)])));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('All 5'), findsOneWidget);
    expect(find.text('Completed 2'), findsOneWidget);
    expect(find.text('Incomplete 2'), findsOneWidget);
    await _shot(t, 'rewards-home-2');
    await t.tap(find.byKey(const ValueKey('qf-completed')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('LISTEN 30 MINUTES'), findsNothing);
    expect(find.text('FIVE PRACTICE DAYS'), findsOneWidget);
  });

  testWidgets('hub in Home style with Enter/Shop pills', (t) async {
    EconomyMirror.instance.summary = _s;
    addTearDown(() => EconomyMirror.instance.summary = const {});
    await _pump(t, VaultScreen(backdrop: _still()));
    expect(find.text('Your quests'), findsOneWidget);
    await _shot(t, 'rewards-home-1');
    await t.scrollUntilVisible(find.byKey(const ValueKey('hub-store')), 200, scrollable: find.byType(Scrollable).first);
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Shop Now'), findsOneWidget);
    expect(find.byKey(const ValueKey('hub-mine')), findsOneWidget);
    await _shot(t, 'rewards-home-3');
  });

  testWidgets('sub-page uses Home frame and the Rewards 3D banner', (t) async {
    EconomyMirror.instance.summary = _s;
    EconomyMirror.instance.uid = 'shot';
    addTearDown(() {
      EconomyMirror.instance.summary = const {};
      EconomyMirror.instance.uid = null;
    });
    await _pump(t, RewardsTabPage(tab: 'quests', backdrop: _still()));
    expect(find.text('NowssB Rewards'), findsWidgets);
    expect(find.text('All 5'), findsWidgets);
    await _shot(t, 'rewards-home-4');
  });
}
