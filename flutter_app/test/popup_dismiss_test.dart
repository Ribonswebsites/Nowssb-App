// Pop-ups close on a tap outside the card, the same way a normal app works.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/programs/store_extras.dart';
import 'package:nowssb/screens/notifications_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _size(WidgetTester t) async {
  t.view.physicalSize = const Size(390 * 3, 844 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Notifications sheet closes when the dimmed barrier is tapped',
      (t) async {
    await _size(t);
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Scaffold(
        body: Builder(
          builder: (c) => TextButton(
            onPressed: () => showNotificationsSheet(c),
            child: const Text('Open'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('Open'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(NotificationsSheet), findsOneWidget);
    await t.tapAt(const Offset(20, 20));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(NotificationsSheet), findsNothing);
  });

  testWidgets('Share sheet closes when the dimmed barrier is tapped', (t) async {
    await _size(t);
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: ShareChip(kind: 'word', id: 'prana', title: 'PRANA')),
      ),
    ));
    await t.tap(find.byType(ShareChip));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Share PRANA'), findsOneWidget);
    await t.tapAt(const Offset(20, 20));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Share PRANA'), findsNothing);
  });
}
