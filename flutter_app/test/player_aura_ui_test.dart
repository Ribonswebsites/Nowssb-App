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
        contains("kPlayerBoxFilm = 'assets/video/player-box-rings.mp4'"));
    expect(aura,
        contains("kPlayerBoxWaveFilm = 'assets/video/player-box-rings.mp4'"));
    expect(
        aura, contains("kPlayerPageFilm = 'assets/video/player-bg-loop.mp4'"));
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
    expect(player, contains('PlayerGuideScreen'));
    expect(player, contains('_guideDone'));
    expect(player, isNot(contains('player-liquid-splash.mp4')));

    final intro = File('lib/screens/player_intro.dart').readAsStringSync();
    expect(intro, contains('kPlayerIntroArt'));
    expect(intro, contains('BEGIN'));
    expect(intro, contains('SKIP'));
    expect(intro, contains('PlayerAuraBackButton'));
    expect(intro, contains('renderPracticeIntro'));

    final settings =
        File('lib/screens/player_settings.dart').readAsStringSync();
    // Settings and Saved words share the player shell (PlayerAuraPage =
    // AURA backdrop on the page film + white round back).
    expect(settings, contains('PlayerAuraPage('));
    expect(aura, contains('class PlayerAuraPage'));
    expect(aura, contains('this.film = kPlayerPageFilm'));
    expect(aura, contains('PlayerAuraBackButton('));
    expect(File('lib/screens/saved_words.dart').readAsStringSync(), contains('PlayerAuraPage('));
    expect(settings, isNot(contains('kPlayerBoxFilm')));
    expect(settings, contains('MUSIC PLAYER'));
    expect(settings, isNot(contains('HeavyGlassPanel')));
    expect(settings, isNot(contains('NestedDarkWrap')));

    // Ribon (Nov 24): the clock / "Music player settings" dial is gone; the
    // player's own settings stay reachable from the player.
    expect(File('lib/screens/player_dial.dart').existsSync(), isFalse);

    final library = File('lib/screens/sound_library.dart').readAsStringSync();
    expect(library, contains('film: kPlayerSharedFilm'));
    expect(library, isNot(contains('assets/store/intro-words.webp')));

    final level = File('lib/screens/select_level.dart').readAsStringSync();
    // The Stages tab is a plain tab: no film, orb video or promo banner.
    expect(level, isNot(contains('PlayerAuraBackdrop')));
    expect(level, isNot(contains('NwsbVideo')));
    expect(level, isNot(contains('ColoredSplitPromoBanner')));

    final practice = File('lib/screens/practice.dart').readAsStringSync();
    expect(practice, contains('film: kPlayerSharedFilm'));

    expect(File('assets/video/player-aura-bg.mp4').existsSync(), isTrue);
    expect(
        File('assets/video/player-aura-bg-poster.webp').existsSync(), isTrue);
    expect(File('assets/video/player-box-liquid.mp4').existsSync(), isTrue);
    expect(File('assets/video/player-box-wave.mp4').existsSync(), isTrue);
    expect(
        File('../assets/player/player-box-bloom.jpg').existsSync() ||
            File('assets/player/player-box-bloom.jpg').existsSync(),
        isTrue);
  });
}
