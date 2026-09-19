import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Practice Lab is a compact black tab with a looping orb film', () {
    final src = File('lib/screens/practice_overlay.dart').readAsStringSync();
    expect(src, contains('_OrbFilm'));
    expect(src, contains('_BlackTab'));
    expect(src, contains('_WordBreakTab'));
    expect(src, contains(_practiceOrbClipLiteral));
    expect(src, contains(_storeMarkLiteral));
    expect(src, contains('ClipOval'));
    expect(src, contains('IgnorePointer'));
    expect(src, contains("'Waiting'"));
    expect(src, contains("'Listening'"));
    expect(src, contains("'Analyzing'"));
    expect(src, contains("'Replay'"));
    expect(src, contains("'Start'"));
    expect(src, contains("'PRACTICE'"));
    expect(src, contains('HitTestBehavior.opaque'));
    expect(src, contains('BackdropFilter'));
    expect(src, contains('ImageFilter.blur'));
    expect(src, contains('PracticeDockOrb'));
    expect(src, contains('assets/icons/microphone.svg'));
    expect(src, contains('NwsbVideo('));
    expect(src, contains('ClipPriority.feature'));
    expect(src, contains('Alignment(0, 0.28)'));
    expect(src, contains('widget.word'));
    expect(src, isNot(contains('_RippleRingsPainter')));
    expect(src, isNot(contains("'Replace'")));
    expect(src, isNot(contains('_GlassShell')));
    expect(src, isNot(contains('SESSION CRAFT')));
    expect(
        src, isNot(contains('Fourteen cuts that make the word feel native')));
    expect(src, isNot(contains('CAPCUT WORKFLOW')));
    expect(src, isNot(contains('Composing')));
    expect(src, isNot(contains('_BlenderOrbPainter')));
  });

  test('Now Playing dock uses the practice orb', () {
    final src = File('lib/screens/practice_player.dart').readAsStringSync();
    expect(src, contains('PracticeDockOrb(onTap: onPractice'));
    expect(src, contains('onPractice: _openPracticeLab'));
    expect(src, contains('showGeneralDialog'));
    expect(src, contains('_practiceOpen'));
    expect(src, contains('assets/store/nowssb-bag-headphones.webp'));
    expect(src, contains('fontSize: 28'));
    expect(src, contains('FontWeight.w800'));
    expect(src, contains('_kPlayerBoxFilm'));
    expect(src, contains('assets/video/grok-video-use-this.mp4'));
    expect(src, contains('fontSize: 22'));
    expect(src, isNot(contains('player-liquid-splash.mp4')));
    expect(src, isNot(contains('grok_video_2026-09-05-15-32-08.mp4')));
    expect(src, isNot(contains('grok_video_2026-09-05-15-32-13.mp4')));
  });
}

const _practiceOrbClipLiteral = 'assets/video/practice-orb.mp4';
const _storeMarkLiteral = 'assets/store/nowssb-bag-headphones.webp';
