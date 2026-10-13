import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/earn/newui/earn_newui_page.dart';
import 'package:nowssb/features/earn/newui/earn_newui_screen.dart';
import 'package:nowssb/features/earn/newui/earn_view_data.dart';

Widget _wrap(Widget w) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: const Size(400, 860), disableAnimations: true),
        child: child!,
      ),
      home: w,
    );

void main() {
  group('EarnViewData', () {
    test('targets follow 100/500/1000/2000', () {
      expect(const EarnViewData(wordsSold: 0).nextTarget, 100);
      expect(const EarnViewData(wordsSold: 250).nextTarget, 500);
      expect(const EarnViewData(wordsSold: 250).targetProgress, closeTo(0.375, 1e-9));
      expect(const EarnViewData(wordsSold: 2000).nextTarget, isNull);
      expect(const EarnViewData(wordsSold: 2000).targetProgress, 1);
    });
    test('rank index maps ladder, unknown is 0', () {
      expect(const EarnViewData(rank: 'Executive Officer').rankIndex, 2);
      expect(const EarnViewData(rank: 'Seller').rankIndex, 0);
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
      data: const EarnViewData(load: EarnLoad.ready, signedIn: true, rank: 'Officer', ratePct: 20, wordsSold: 120, teamSize: 3),
      actions: EarnActions(onEarnings: () => earnings++),
    )));
    expect(find.text('Officer'), findsOneWidget);
    expect(find.text('Silver rank'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('380 more words to 500'), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('earn-task-earnings')));
    await t.pumpAndSettle();
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
    await t.pumpAndSettle();
    expect(find.text('How it works'), findsOneWidget);
    expect(find.textContaining('Join as an agent'), findsOneWidget);
  });

  testWidgets('gate shows legacy when flag off, new when on', (t) async {
    await t.pumpWidget(_wrap(const EarnNewUiGate(legacy: Text('legacy'), newUi: Text('new'), debugOverride: false)));
    expect(find.text('legacy'), findsOneWidget);
    await t.pumpWidget(_wrap(const EarnNewUiGate(legacy: Text('legacy'), newUi: Text('new'), debugOverride: true)));
    expect(find.text('new'), findsOneWidget);
  });

  testWidgets('honesty note shows on ready', (t) async {
    await t.pumpWidget(_wrap(const EarnNewUiPage(data: EarnViewData(load: EarnLoad.ready, signedIn: true, wordsSold: 5))));
    await t.scrollUntilVisible(find.byKey(const Key('earn-honesty-note')), 200);
    expect(find.byKey(const Key('earn-honesty-note')), findsOneWidget);
  });

  testWidgets('with motion on, numbers count up to real values', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: EarnNewUiPage(data: EarnViewData(load: EarnLoad.ready, signedIn: true, ratePct: 20, wordsSold: 120, teamSize: 3)),
    ));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('120'), findsNothing);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('120'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    await t.pumpWidget(const SizedBox()); // dispose repeating controllers
  });
}
