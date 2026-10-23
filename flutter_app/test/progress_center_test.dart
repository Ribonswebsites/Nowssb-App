import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/progress/progress_center.dart';
import 'package:nowssb/features/progress/progress_popup.dart';

void main() {
  late DateTime now;
  late ProgressCenter c;
  setUp(() {
    now = DateTime(2026, 10, 23, 10);
    c = ProgressCenter(clock: () => now);
  });

  test('partial progress does not pop up', () {
    expect(c.report(ProgressKind.tasks, 1, 3), isFalse);
    expect(c.popup.value, isNull);
    expect(c.itemOf(ProgressKind.tasks)!.value, closeTo(1 / 3, 1e-9));
  });

  test('completion pops up once per kind per day', () {
    c.report(ProgressKind.tasks, 2, 3);
    expect(c.report(ProgressKind.tasks, 3, 3), isTrue);
    expect(c.popup.value!.kind, ProgressKind.tasks);
    expect(c.popup.value!.line, 'Daily tasks 3/3 done');
    c.dismiss();
    expect(c.popup.value, isNull);
    c.report(ProgressKind.tasks, 2, 3);
    expect(c.report(ProgressKind.tasks, 3, 3), isFalse);
    now = now.add(const Duration(days: 1));
    expect(c.itemOf(ProgressKind.tasks), isNull);
    expect(c.report(ProgressKind.tasks, 3, 3), isTrue);
  });

  test('each kind keeps its own progress', () {
    c.report(ProgressKind.coins, 1, 2);
    c.report(ProgressKind.routine, 3, 3);
    expect(c.itemOf(ProgressKind.coins)!.complete, isFalse);
    expect(c.popup.value!.kind, ProgressKind.routine);
    expect(c.report(ProgressKind.coins, 2, 2), isTrue);
    expect(c.popup.value!.line, 'Daily coins 2/2 collected');
    expect(c.items.length, ProgressKind.values.length);
  });

  test('quests pop up once per quest id', () {
    expect(c.report(ProgressKind.quest, 1, 1, key: 'a'), isTrue);
    expect(c.report(ProgressKind.quest, 1, 1, key: 'a'), isFalse);
    expect(c.report(ProgressKind.quest, 1, 1, key: 'b'), isTrue);
  });

  test('zero total never completes', () {
    expect(c.report(ProgressKind.tasks, 0, 0), isFalse);
  });

  testWidgets('host shows the pop-up and auto-dismisses', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ProgressPopupHost(center: c, child: const SizedBox.expand())));
    c.report(ProgressKind.checkin, 1, 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Daily check-in 1/1 checked in'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ProgressPopupCard), findsNothing);
  });

  testWidgets('panel lists every kind with its own bar', (tester) async {
    c.report(ProgressKind.tasks, 3, 3);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProgressPanel(center: c))));
    expect(find.byType(ProgressBarLine), findsNWidgets(ProgressKind.values.length));
    expect(find.text('1 of 5 today'), findsOneWidget);
  });
}
