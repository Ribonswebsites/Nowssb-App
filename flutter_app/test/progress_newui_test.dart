import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/progress/newui/progress_flag.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/screens/progress/newui/progress_new_screen.dart';

/// Video can't play in widget tests: use a still frame of the app's own backdrop.
final _bg = Image.asset(Settings.fashionImages.first, fit: BoxFit.cover);

ProgressView _view({int sessions = 5}) => ProgressView(
      streak: 3,
      totalSessions: sessions,
      totalMinutes: 42,
      uniqueWords: 4,
      todaySessions: 1,
      weekPercent: 57,
      week: [
        for (var i = 0; i < 7; i++) (date: '2026-10-${12 + i}', done: i < 2, isToday: i == 1, isFuture: i > 1),
      ],
      recent: const ['Calm', 'Focus'],
    );

Finder _main() => find.descendant(of: find.byKey(const Key('pg-ready')), matching: find.byType(Scrollable)).first;

Widget _app(Widget w) => MediaQuery(data: const MediaQueryData(disableAnimations: true), child: MaterialApp(home: w));

void main() {
  testWidgets('loading state', (t) async {
    await t.pumpWidget(_app(ProgressNewScreen(background: _bg, load: ProgressLoad.loading)));
    expect(find.byKey(const Key('pg-loading')), findsOneWidget);
  });

  testWidgets('empty state offers a start action', (t) async {
    var started = false;
    await t.pumpWidget(_app(ProgressNewScreen(background: _bg, load: ProgressLoad.ready, view: _view(sessions: 0), onStart: () => started = true)));
    expect(find.byKey(const Key('pg-empty')), findsOneWidget);
    await t.tap(find.text('Start a practice'));
    expect(started, isTrue);
  });

  testWidgets('error state retries', (t) async {
    var retried = false;
    await t.pumpWidget(_app(ProgressNewScreen(background: _bg, load: ProgressLoad.error, onRetry: () => retried = true)));
    await t.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('offline shows banner and cached data', (t) async {
    await t.pumpWidget(_app(ProgressNewScreen(background: _bg, load: ProgressLoad.offline, view: _view())));
    expect(find.byKey(const Key('pg-offline')), findsOneWidget);
    expect(find.text('3 days'), findsOneWidget);
  });

  testWidgets('large text scale does not overflow', (t) async {
    await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true, textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(home: ProgressNewScreen(background: _bg, load: ProgressLoad.ready, view: _view()))));
    expect(t.takeException(), isNull);
  });

  testWidgets('ready flow: stats, week, recent, back', (t) async {
    var back = false;
    await t.pumpWidget(_app(ProgressNewScreen(background: _bg, load: ProgressLoad.ready, view: _view(), onBack: () => back = true)));
    expect(find.byKey(const Key('pg-offline')), findsNothing);
    expect(find.text('57%'), findsOneWidget);
    await t.scrollUntilVisible(find.text('42'), 200, scrollable: _main());
    expect(find.text('42'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Calm'), 200, scrollable: _main());
    expect(find.text('Calm'), findsOneWidget);
    await t.tap(find.byTooltip('Back'));
    expect(back, isTrue);
  });

  testWidgets('milestones are honest; card sits on the app backdrop', (t) async {
    await t.pumpWidget(_app(ProgressNewScreen(background: _bg, load: ProgressLoad.ready, view: _view())));
    await t.scrollUntilVisible(find.byKey(const Key('pg-next-milestone')), 200, scrollable: _main());
    expect(find.byKey(const Key('pg-next-milestone')), findsOneWidget);
    expect(find.text('Next: 7-day streak (3/7)'), findsOneWidget);
    expect(find.text('Meditation streak'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('animated mode settles to real values', (t) async {
    await t.pumpWidget(MaterialApp(home: ProgressNewScreen(background: _bg, load: ProgressLoad.ready, view: _view())));
    await t.pump(const Duration(seconds: 2));
    expect(find.text('3 days'), findsOneWidget);
  });

  test('flag override wins', () {
    expect(newUiProgressEnabled(override: true), isTrue);
    expect(newUiProgressEnabled(override: false), isFalse);
  });
}
