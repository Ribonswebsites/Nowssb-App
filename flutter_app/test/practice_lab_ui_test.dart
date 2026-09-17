import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Practice Lab ships 3D ripples, word breakdown and session craft', () {
    final src = File('lib/screens/practice_overlay.dart').readAsStringSync();
    expect(src, contains('_WaterRipplePainter'));
    expect(src, contains('THE WORD'));
    expect(src, contains('SESSION CRAFT'));
    expect(src, contains('Fourteen cuts that make the word feel native'));
    expect(src, contains('Hold to speak'));
    expect(src, contains('assets/icons/microphone.svg'));
    expect(src, contains('PracticeDockOrb'));
    expect(src, contains('INSET'));
  });

  test('Now Playing dock uses the 3D practice orb', () {
    final src = File('lib/screens/practice_player.dart').readAsStringSync();
    expect(src, contains('PracticeDockOrb(onTap: onPractice'));
    expect(src, contains('onPractice: _openPracticeLab'));
  });
}
