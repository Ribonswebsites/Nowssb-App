// Profile: motto tiles act, progress card says Back (not Skip).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:nowssb/screens/subscription.dart';
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

  testWidgets('Practice tile changes the time; Plan tile opens plans', (t) async {
    await _open(t);
    final before = find.text('No limit').evaluate().length;
    await t.tap(find.text('PRACTICE'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('No limit').evaluate().length, isNot(before));
    await t.tap(find.text('PLAN'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byType(SubscriptionScreen), findsOneWidget);
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
