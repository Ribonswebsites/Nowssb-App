// Settings rows with a choice open a picker sheet. Tapping an option
// applies it, keeps it, and shows a short confirmation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

Future<void> _size(WidgetTester t, {double h = 2000}) async {
  t.view.physicalSize = Size(390 * 3, h * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

Future<void> _pumpSettings(WidgetTester t) async {
  await _size(t);
  await t.pumpWidget(MediaQuery(
    data: const MediaQueryData(size: Size(390, 2000), disableAnimations: true),
    child: MaterialApp(
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: const AppSettingsScreen(),
    ),
  ));
  await t.pump();
  await t.pump(const Duration(milliseconds: 200));
}

Future<void> _openRow(WidgetTester t, String title) async {
  final row = find.text(title);
  await t.ensureVisible(row);
  await t.tap(row);
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
}

Future<void> _pick(WidgetTester t, String label) async {
  await t.tap(find.byKey(ValueKey('settings-choice-$label')));
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
}

Future<void> _tapBarrier(WidgetTester t) async {
  await t.tapAt(const Offset(195, 20));
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await setUpHomeRender();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Settings.instance.setFashionHome(false);
    await Settings.instance.setFashionPlus(true);
    await Settings.instance.setNavConfig(color: 'black');
  });

  testWidgets('Home picker opens, applies, persists and confirms', (t) async {
    await _pumpSettings(t);
    expect(find.text('Simple home'), findsWidgets);
    await _openRow(t, 'Home');
    expect(find.byKey(const ValueKey('settings-choice-sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-choice-Simple home')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('settings-choice-NowssB home')),
        findsOneWidget);

    await _pick(t, 'NowssB home');
    expect(find.byKey(const ValueKey('settings-choice-sheet')), findsNothing);
    expect(Settings.instance.fashionHome, isTrue);
    expect(find.text('Home set to NowssB home'), findsOneWidget);
    expect(find.text('NowssB home'), findsWidgets);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('nwsb_home_mode'), isTrue);
    await Settings.instance.load();
    expect(Settings.instance.fashionHome, isTrue);
  });

  testWidgets('Zen Plus picker applies Moving or Still', (t) async {
    await Settings.instance.setFashionPlus(true);
    await _pumpSettings(t);
    await _openRow(t, 'Zen Plus');
    expect(find.byKey(const ValueKey('settings-choice-sheet')), findsOneWidget);
    await _pick(t, 'Still');
    expect(Settings.instance.fashionPlus, isFalse);
    expect(find.text('Zen Plus set to Still'), findsOneWidget);
    expect(find.text('Still'), findsWidgets);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('nwsb_fashplus'), isFalse);
    await Settings.instance.load();
    expect(Settings.instance.fashionPlus, isFalse);
  });

  testWidgets('Nav Bar picker applies Glass or Black', (t) async {
    await Settings.instance.setNavConfig(color: 'black');
    await _pumpSettings(t);
    await _openRow(t, 'Nav Bar');
    expect(find.byKey(const ValueKey('settings-choice-sheet')), findsOneWidget);
    await _pick(t, 'Glass');
    expect(Settings.instance.navColor, 'glass');
    expect(find.text('Nav Bar set to Glass'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nwsb_nav_color'), 'glass');
    await Settings.instance.load();
    expect(Settings.instance.navColor, 'glass');
  });

  testWidgets('Keep Screen Awake picker applies and confirms', (t) async {
    await _pumpSettings(t);
    await t.tap(find.text('This phone'));
    await t.pump();
    await _openRow(t, 'Keep Screen Awake');
    expect(find.byKey(const ValueKey('settings-choice-sheet')), findsOneWidget);
    await _pick(t, 'Can sleep');
    expect(find.text('Keep Screen Awake set to Can sleep'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ss_screen_wake'), isFalse);
  });

  testWidgets('tapping the current Home choice still confirms', (t) async {
    await Settings.instance.setFashionHome(false);
    await _pumpSettings(t);
    await _openRow(t, 'Home');
    await _pick(t, 'Simple home');
    expect(Settings.instance.fashionHome, isFalse);
    expect(find.text('Home set to Simple home'), findsOneWidget);
  });


  testWidgets('each Settings picker closes on a barrier tap without changing the setting', (t) async {
    await _pumpSettings(t);

    Future<void> openAndDismiss(String row) async {
      await _openRow(t, row);
      expect(find.byKey(const ValueKey('settings-choice-sheet')), findsOneWidget);
      await _tapBarrier(t);
      expect(find.byKey(const ValueKey('settings-choice-sheet')), findsNothing);
    }

    await openAndDismiss('Home');
    expect(Settings.instance.fashionHome, isFalse);

    await openAndDismiss('Zen Plus');
    expect(Settings.instance.fashionPlus, isTrue);

    await openAndDismiss('Nav Bar');
    expect(Settings.instance.navColor, 'black');

    await t.tap(find.text('This phone'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await openAndDismiss('Keep Screen Awake');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ss_screen_wake'), isNull);

    await t.tap(find.text('Account'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    await openAndDismiss('Appear in Discover');
    expect(prefs.getBool('ss_appear_discover'), isNull);
  });

  testWidgets('Nav Bar picker closes on the Android back button without changing the setting', (t) async {
    await _pumpSettings(t);
    await _openRow(t, 'Nav Bar');
    expect(find.byKey(const ValueKey('settings-choice-sheet')), findsOneWidget);
    await t.binding.handlePopRoute();
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('settings-choice-sheet')), findsNothing);
    expect(Settings.instance.navColor, 'black');
  });

  testWidgets('Nav Bar picker closes on a downward swipe without changing the setting', (t) async {
    await _pumpSettings(t);
    await _openRow(t, 'Nav Bar');
    expect(find.byKey(const ValueKey('settings-choice-sheet')), findsOneWidget);
    await t.fling(find.byKey(const ValueKey('settings-choice-sheet')), const Offset(0, 400), 2000);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-choice-sheet')), findsNothing);
    expect(Settings.instance.navColor, 'black');
  });
}
