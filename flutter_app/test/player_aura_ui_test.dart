import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('player intro, setup and leftover intros share the same film', () {
    final aura = File('lib/theme/player_aura.dart').readAsStringSync();
    expect(aura, contains("kPlayerSharedFilm = 'assets/video/grok-video-use-this.mp4'"));
    expect(aura, contains('class PlayerAuraBackdrop'));
    expect(aura, contains('class PlayerAuraBackButton'));
    expect(aura, contains('Color(0xFF202731)'));

    final player = File('lib/screens/practice_player.dart').readAsStringSync();
    expect(player, contains('kPlayerSharedFilm'));
    expect(player, isNot(contains('player-liquid-splash.mp4')));

    final settings = File('lib/screens/player_settings.dart').readAsStringSync();
    expect(settings, contains('PlayerAuraBackdrop'));
    expect(settings, contains('PlayerAuraBackButton'));
    expect(settings, contains('Color(0xFF202731)'));
    expect(settings, isNot(contains('HeavyGlassPanel')));
    expect(settings, isNot(contains('NestedDarkWrap')));

    final dial = File('lib/screens/player_dial.dart').readAsStringSync();
    expect(dial, contains('PlayerAuraBackdrop'));
    expect(dial, contains('PlayerAuraBackButton'));

    final library = File('lib/screens/sound_library.dart').readAsStringSync();
    expect(library, contains('film: kPlayerSharedFilm'));
    expect(library, isNot(contains('assets/store/intro-words.webp')));

    final level = File('lib/screens/select_level.dart').readAsStringSync();
    expect(level, contains('PlayerAuraBackdrop'));

    final practice = File('lib/screens/practice.dart').readAsStringSync();
    expect(practice, contains('film: kPlayerSharedFilm'));
  });
}
