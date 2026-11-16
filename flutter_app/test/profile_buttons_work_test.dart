// Profile: week tiles and Sign Out work; removed motto / about / quote banners.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

Future<void> _open(WidgetTester t) async {
  FakeVideoPlatform();
  VideoPool.debugDeadlines = false;
  t.view.physicalSize = const Size(390 * 3, 6000 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(const MaterialApp(home: ProfileScreen()));
  await t.pump(const Duration(milliseconds: 500));
}

Future<void> _close(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(minutes: 1));
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  setUpAll(setUpHomeRender);

  testWidgets('removed Profile banners are gone; week and sign out remain',
      (t) async {
    await _open(t);
    expect(find.text('MY MOTTO'), findsNothing);
    expect(find.text('About NowssB'), findsNothing);
    expect(find.text('Long before there was language, there was only sound.'),
        findsNothing);
    expect(find.text("Start today's practice now."), findsNothing);
    expect(find.text('PRACTICE'), findsNothing);
    expect(find.byKey(const ValueKey('profile-practice-card')), findsNothing);
    expect(find.byKey(const ValueKey('profile-week-tracker')), findsOneWidget);
    expect(find.text('Practice Duration'), findsOneWidget);
    expect(find.text('Daily Reminder'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
    await t.tap(find.text('Sign Out'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Sign out?'), findsOneWidget);
    await t.tap(find.text('Stay signed in'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Sign out?'), findsNothing);
    await _close(t);
  });

  testWidgets('progress card says Back, not Skip', (t) async {
    await _open(t);
    await t.tap(find.text('Progress').first);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Back'), findsOneWidget);
    await _close(t);
  });
}
