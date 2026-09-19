import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'player intro and setup use the charcoal AURA film, not the gold box film',
      () {
    final aura = File('lib/theme/player_aura.dart').readAsStringSync();
    expect(
        aura, contains("kPlayerAuraFilm = 'assets/video/player-aura-bg.mp4'"));
    expect(aura,
        contains("kPlayerBoxFilm = 'assets/video/player-box-liquid.mp4'"));
    expect(aura, contains("kPlayerBoxWaveFilm = 'assets/video/player-box-wave.mp4'"));
    expect(aura, contains("kPlayerPageFilm = 'assets/video/player-bg-loop.mp4'"));
    expect(aura, contains('this.film = kPlayerAuraFilm'));
    expect(aura, contains('class PlayerAuraBackdrop'));
    expect(aura, contains('class PlayerAuraBackButton'));
    expect(aura, contains('kPlayerAuraBg'));
    expect(
        aura,
        isNot(contains(
            "kPlayerSharedFilm = 'assets/video/grok-video-use-this.mp4'")));

    final player = File('lib/screens/practice_player.dart').readAsStringSync();
    expect(player, contains('kPlayerBoxFilm'));
    expect(player, contains('PlayerIntroScreen'));
    expect(player, isNot(contains('player-liquid-splash.mp4')));

    final intro = File('lib/screens/player_intro.dart').readAsStringSync();
    expect(intro, contains('kPlayerIntroArt'));
    expect(intro, contains('BEGIN'));
    expect(intro, contains('SKIP'));
    expect(intro, contains('PlayerAuraBackButton'));
    expect(intro, contains('renderPracticeIntro'));

    final settings =
        File('lib/screens/player_settings.dart').readAsStringSync();
    expect(settings, contains('PlayerAuraBackdrop'));
    expect(settings, contains('PlayerAuraBackButton'));
    expect(settings, contains('film: kPlayerPageFilm'));
    expect(settings, isNot(contains('kPlayerBoxFilm')));
    expect(settings, contains('MUSIC PLAYER'));
    expect(settings, isNot(contains('HeavyGlassPanel')));
    expect(settings, isNot(contains('NestedDarkWrap')));

    final dial = File('lib/screens/player_dial.dart').readAsStringSync();
    expect(dial, contains('PlayerAuraBackdrop'));
    expect(dial, contains('PlayerAuraBackButton'));
    expect(dial, contains('film: kPlayerPageFilm'));
    expect(dial, contains('_GlassCircle'));
    expect(dial, contains('_GlassDatePill'));
    expect(dial, contains('onLibrary'));

    final library = File('lib/screens/sound_library.dart').readAsStringSync();
    expect(library, contains('film: kPlayerSharedFilm'));
    expect(library, isNot(contains('assets/store/intro-words.webp')));

    final level = File('lib/screens/select_level.dart').readAsStringSync();
    expect(level, contains('PlayerAuraBackdrop'));

    final practice = File('lib/screens/practice.dart').readAsStringSync();
    expect(practice, contains('film: kPlayerSharedFilm'));

    expect(File('assets/video/player-aura-bg.mp4').existsSync(), isTrue);
    expect(
        File('assets/video/player-aura-bg-poster.webp').existsSync(), isTrue);
    expect(File('assets/video/player-box-liquid.mp4').existsSync(), isTrue);
    expect(File('assets/video/player-box-wave.mp4').existsSync(), isTrue);
    expect(File('../assets/player/player-box-bloom.jpg').existsSync() ||
            File('assets/player/player-box-bloom.jpg').existsSync(),
        isTrue);
  });
}
