import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tab switches do not pop a center destination pill', () {
    final src = File('lib/shell/nav_shell.dart').readAsStringSync();
    expect(src, isNot(contains('_tabTransitioning')));
    expect(src, isNot(contains('_transitionTarget')));
    expect(src, isNot(contains('_tabTransitionTimer')));
    expect(src, isNot(contains('Icons.auto_awesome')));
    expect(src, isNot(contains("'Opening'")));
    expect(src, isNot(contains('hearing_safety_player')));
    expect(src, isNot(contains('HearingSafetyPlayerScreen')));
    expect(src, isNot(contains('Opaque chin')));
    expect(src, isNot(contains('ColoredBox(color: NwsbColors.deep)')));
    expect(src, contains('_openMiniPlayer'));
    expect(src, contains('PracticePlayerScreen'));
    expect(src, contains('systemNavigationBarColor'));
  });

  test('hearing safety player is gone', () {
    expect(
      File('lib/screens/hearing_safety_player.dart').existsSync(),
      isFalse,
    );
  });

  test('mini player is a rounded glass stadium with white circle buttons', () {
    final src = File('lib/widgets/mini_player_pill.dart').readAsStringSync();
    expect(src, contains('assets/store/nowssb-bag-headphones.webp'));
    expect(src, contains('_WhiteCircleBtn'));
    expect(src, contains('BorderRadius.circular(35)'));
    expect(src, contains('height: 70'));
    expect(src, contains('BackdropFilter'));
    expect(src, isNot(contains('HearingSafety')));
  });
}
