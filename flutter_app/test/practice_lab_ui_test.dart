import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Practice Lab is a compact glass tab with ripples and word breakdown',
    () {
      final src = File('lib/screens/practice_overlay.dart').readAsStringSync();
      expect(src, contains('_WaterRipplePainter'));
      expect(src, contains('THE WORD'));
      expect(src, contains('Hold to speak'));
      expect(src, contains('assets/icons/microphone.svg'));
      expect(src, contains('PracticeDockOrb'));
      expect(src, contains('_GlassShell'));
      expect(src, contains('maxHeight: h * 0.48'));
      expect(src, contains('ImageFilter.blur(sigmaX: 12, sigmaY: 12)'));
      expect(src, isNot(contains('SESSION CRAFT')));
      expect(
        src,
        isNot(contains('Fourteen cuts that make the word feel native')),
      );
      expect(src, isNot(contains('CAPCUT WORKFLOW')));
      expect(src, isNot(contains('NwsbVideo(')));
    },
  );

  test('Now Playing dock uses the 3D practice orb', () {
    final src = File('lib/screens/practice_player.dart').readAsStringSync();
    expect(src, contains('PracticeDockOrb(onTap: onPractice'));
    expect(src, contains('onPractice: _openPracticeLab'));
  });
}
