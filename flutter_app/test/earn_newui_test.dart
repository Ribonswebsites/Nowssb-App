import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/earn/newui/earn_newui_page.dart';
import 'package:nowssb/features/earn/newui/earn_newui_screen.dart';
import 'package:nowssb/features/earn/newui/earn_downline_page.dart';
import 'package:nowssb/kit/data_layer.dart';
import 'package:nowssb/features/earn/newui/earn_view_data.dart';

Widget _wrap(Widget w) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: const Size(400, 860), disableAnimations: true),
        child: child!,
      ),
      home: w,
    );

const _team = [
  EarnTeamMember(id: 'a', name: 'Asha', rank: 'Officer', words: 12),
  EarnTeamMember(id: 'b', name: 'Ben'),
  EarnTeamMember(id: 'c', name: 'Cy', level: 2),
];

void main() {
  earnVideoOff = true;
  group('EarnViewData', () {
    test('targets follow 100/500/1000/2000', () {
      expect(const EarnViewData(wordsSold: 0).nextTarget, 100);
      expect(const EarnViewData(wordsSold: 250).nextTarget, 500);
      expect(const EarnViewData(wordsSold: 250).targetProgress, closeTo(0.375, 1e-9));
      expect(const EarnViewData(wordsSold: 2000).nextTarget, isNull);
      expect(const EarnViewData(wordsSold: 2000).targetProgress, 1);
    });
    test('medal follows server metal, unknown is Bronze', () {
      expect(const EarnViewData(metal: 'Gold').rankIndex, 2);
      expect(const EarnViewData(metal: '').rankIndex, 0);
    });
    test('fromSummary maps server reply honestly', () {
      final d = EarnViewData.fromSummary({
        'standing': {'title': 'Officer', 'metal': 'Silver', 'ratePct': 22},
        'words': 140,
        'targets': [{'words': 500}, {'words': 100}],
        'team': [
          {'uid': 'a', 'name': 'Asha', 'level': 1, 'words': 12},
          {'uid': 'b', 'name': 'Ben', 'level': 2},
          {'uid': 'c', 'name': 'Cy', 'level': 7},
        ],
      });
      expect(d.load, EarnLoad.ready);
      expect(d.rank, 'Officer');
      expect(d.ratePct, 22);
      expect(d.targets, [100, 500]);
      expect(d.nextTarget, 500);
      expect(d.teamSize, 3);
      expect(d.team.last.level, 2); // capped at 2 levels
    });
    test('fresh agent is empty; errors map to states', () {
      expect(EarnViewData.fromSummary({}).load, EarnLoad.empty);
      expect(EarnViewData.fromError(const KitErr('x', code: 'offline')).load, EarnLoad.offline);
      expect(EarnViewData.fromError(const KitErr('x', code: 'unauthenticated')).load, EarnLoad.empty);
      expect(EarnViewData.fromError(const KitErr('Boom')).errorMessage, 'Boom');
    });
  });

  testWidgets('loading state', (t) async {
    await t.pumpWidget(_wrap(const EarnNewUiPage(data: EarnViewData())));
    expect(find.byKey(const Key('earn-loading')), findsOneWidget);
  });

  testWidgets('empty state signed out asks to sign in', (t) async {
    var tapped = false;
    await t.pumpWidget(_wrap(EarnNewUiPage(
      data: const EarnViewData(load: EarnLoad.empty),
      actions: EarnActions(onSignIn: () => tapped = true),
    )));
    expect(find.byKey(const Key('earn-empty')), findsOneWidget);
    await t.tap(find.text('Sign in'));
    expect(tapped, isTrue);
  });

  testWidgets('error state retries', (t) async {
    var n = 0;
    await t.pumpWidget(_wrap(EarnNewUiPage(
      data: const EarnViewData(load: EarnLoad.error),
      actions: EarnActions(onRetry: () => n++),
    )));
    expect(find.byKey(const Key('earn-error')), findsOneWidget);
    await t.tap(find.text('Try again'));
    expect(n, 1);
  });

  testWidgets('offline state', (t) async {
    await t.pumpWidget(_wrap(const EarnNewUiPage(data: EarnViewData(load: EarnLoad.offline))));
    expect(find.byKey(const Key('earn-offline')), findsOneWidget);
    expect(find.text('You are offline'), findsOneWidget);
  });

  testWidgets('ready shows rank, stats, progress and task taps', (t) async {
    var earnings = 0;
    await t.pumpWidget(_wrap(EarnNewUiPage(
      data: const EarnViewData(load: EarnLoad.ready, signedIn: true, rank: 'Officer', metal: 'Silver', ratePct: 20, wordsSold: 120, team: _team),
      actions: EarnActions(onEarnings: () => earnings++),
    )));
    expect(find.text('Officer'), findsOneWidget);
    expect(find.text('Silver rank'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('380 more words to 500'), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const Key('earn-task-earnings')), 200);
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.byKey(const Key('earn-task-earnings')));
    expect(earnings, 1);
  });

  testWidgets('help opens how-it-works', (t) async {
    await t.pumpWidget(_wrap(Builder(
      builder: (ctx) => EarnNewUiPage(
        data: const EarnViewData(load: EarnLoad.ready, signedIn: true, wordsSold: 5),
        actions: EarnActions(onHelp: () => showEarnHowItWorks(ctx)),
      ),
    )));
    await t.tap(find.byKey(const Key('earn-help')));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Join as an agent'), findsOneWidget);
    await t.tap(find.text('Next'));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Sell words and plans'), findsWidgets);
  });

  testWidgets('screen loads through EarnRepository result', (t) async {
    await t.pumpWidget(_wrap(EarnNewUiScreen(load: () async => const KitErr('x', code: 'offline'))));
    await t.pump();
    expect(find.byKey(const Key('earn-offline')), findsOneWidget);
  });

  testWidgets('downline empty state', (t) async {
    await t.pumpWidget(_wrap(const EarnDownlinePage(data: EarnViewData(load: EarnLoad.ready))));
    expect(find.byKey(const Key('earn-team-empty')), findsOneWidget);
  });

  testWidgets('downline shows 2 levels and node stats', (t) async {
    await t.pumpWidget(_wrap(const EarnDownlinePage(data: EarnViewData(load: EarnLoad.ready, team: _team))));
    await t.pump();
    expect(find.text('2 direct · 1 through your team'), findsOneWidget);
    await t.tap(find.byKey(const Key('earn-node-a')));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Asha'), findsOneWidget);
    expect(find.textContaining('Words sold: 12'), findsOneWidget);
  });

  testWidgets('honesty note shows on ready', (t) async {
    await t.pumpWidget(_wrap(const EarnNewUiPage(data: EarnViewData(load: EarnLoad.ready, signedIn: true, wordsSold: 5))));
    await t.scrollUntilVisible(find.byKey(const Key('earn-honesty-note')), 200);
    expect(find.byKey(const Key('earn-honesty-note')), findsOneWidget);
  });

  testWidgets('with motion on, numbers count up to real values', (t) async {
    t.view.physicalSize = const Size(1200, 3000);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(
      home: EarnNewUiPage(data: EarnViewData(load: EarnLoad.ready, signedIn: true, ratePct: 20, wordsSold: 120, team: _team)),
    ));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('120'), findsNothing);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('120'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    await t.pumpWidget(const SizedBox()); // dispose repeating controllers
  });
}
