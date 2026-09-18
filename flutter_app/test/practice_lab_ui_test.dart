import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Practice Lab is a compact black tab with a blender orb', () {
    final src = File('lib/screens/practice_overlay.dart').readAsStringSync();
    expect(src, contains('_BlenderOrbPainter'));
    expect(src, contains('_BlackTab'));
    expect(src, contains("'Waiting'"));
    expect(src, contains("'Listening'"));
    expect(src, contains("'Analyzing'"));
    expect(src, contains("'Replace'"));
    expect(src, contains("'Start'"));
    expect(src, contains('PracticeDockOrb'));
    expect(src, contains('assets/icons/microphone.svg'));
    expect(src, isNot(contains('_GlassShell')));
    expect(src, isNot(contains('ImageFilter.blur')));
    expect(src, isNot(contains('SESSION CRAFT')));
    expect(
        src, isNot(contains('Fourteen cuts that make the word feel native')));
    expect(src, isNot(contains('CAPCUT WORKFLOW')));
    expect(src, isNot(contains('NwsbVideo(')));
    expect(src, isNot(contains('Composing')));
  });

  test('Now Playing dock uses the practice orb', () {
    final src = File('lib/screens/practice_player.dart').readAsStringSync();
    expect(src, contains('PracticeDockOrb(onTap: onPractice'));
    expect(src, contains('onPractice: _openPracticeLab'));
  });
}
