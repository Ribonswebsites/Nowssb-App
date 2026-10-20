import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/store/signature_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host() => const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SingleChildScrollView(child: SignatureBody(autoGuide: false, showRooms: false)),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tabs switch sections', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(_host());
    await t.pump();
    expect(find.text('Upcoming drops'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('sig-tab-Upcoming')));
    await t.pump();
    expect(find.text('Signature words'), findsNothing);
    expect(find.text('Upcoming drops'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('sig-tab-Words')));
    await t.pump();
    expect(find.text('Upcoming drops'), findsNothing);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('locked drop popup toggles reminder', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(_host());
    await t.pump();
    await t.tap(find.byKey(const ValueKey('sig-drop-Aurora')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Notify me'), findsOneWidget);
    await t.tap(find.text('Notify me'));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Reminder on'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('nwsb_signature_notify'), contains('Aurora'));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('How it works opens the guide', (t) async {
    t.view.physicalSize = const Size(900, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(_host());
    await t.pump();
    await t.tap(find.byKey(const ValueKey('sig-guide')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.textContaining('Signature', findRichText: true), findsWidgets);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}
