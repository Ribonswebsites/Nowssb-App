import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nowssb/screens/player_guide.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('player guide ports the website walkthrough slides and chrome', () {
    final src = File('lib/screens/player_guide.dart').readAsStringSync();
    expect(src, contains('renderPwGuide'));
    expect(src, contains('Welcome to Your Practice Player'));
    expect(src, contains('Listen & Navigate'));
    expect(src, contains('Practice & Get Scored'));
    expect(src, contains('Build Your Library & Sentences'));
    expect(src, contains('Word Info & Player Settings'));
    expect(src, contains('Grow Your Collection'));
    expect(src, contains('Unlock a Signature Word'));
    expect(src, contains('You’re All Set'));
    expect(src, contains('Try it now'));
    expect(src, contains("'Begin'"));
    expect(src, contains('NowssB Player Guide'));
    // The website's remote slide art is bundled now (assets/player/guide).
    for (final m in RegExp(r"'(assets/player/guide/[^']+)'").allMatches(src)) {
      expect(File(m.group(1)!).existsSync(), isTrue, reason: m.group(1));
    }
    expect(src, contains('assets/player/guide/'));
    expect(src, contains('Alignment.topCenter'));
    expect(src, isNot(contains('kPlayerBoxFilm')));
  });

  test('practice player shows the guide before the intro', () {
    final player = File('lib/screens/practice_player.dart').readAsStringSync();
    expect(player, contains("import 'player_guide.dart';"));
    expect(player, contains('if (!_guideDone)'));
    expect(player, contains('PlayerGuideScreen'));
    expect(player, contains('if (!_introDone)'));
    final guideIdx = player.indexOf('if (!_guideDone)');
    final introIdx = player.indexOf('if (!_introDone)');
    expect(guideIdx, greaterThan(0));
    expect(introIdx, greaterThan(guideIdx));
  });

  test('settings can replay the player guide', () {
    final settings = File('lib/screens/app_settings.dart').readAsStringSync();
    expect(settings, contains("import 'player_guide.dart';"));
    expect(settings, contains("title: 'Player Guide'"));
    expect(settings, contains('PlayerGuideScreen'));
  });

  testWidgets('first setup page shows welcome copy and chrome', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerGuideScreen(onDone: () => done = true),
      ),
    );
    await tester.pump();
    expect(find.text('NowssB Player Guide'), findsOneWidget);
    expect(find.text('Welcome to Your Practice Player'), findsOneWidget);
    expect(find.text('Try it now'), findsWidgets);
    expect(find.text('Begin'), findsNothing);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(done, isTrue);
  });
}
