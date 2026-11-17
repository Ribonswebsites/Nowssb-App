// Practice tab: every tile shows the same picture Sound Library uses for
// that word (the player's cover), the Today's session art follows the
// selected word chip, and no word ever falls back to a generic theme still.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/admin/template/editable.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/day_part.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/word_posters.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/widgets/restyle_kit.dart';

import 'fake_video_platform.dart';

Finder _pill(String word) => find.byKey(ValueKey('practice-chip-$word'), skipOffstage: false);

String? _heroCover(WidgetTester t) {
  final hero = find.byKey(const ValueKey('practice-hero'));
  final imgs = find
      .descendant(of: hero, matching: find.byType(EditableImage))
      .evaluate()
      .map((e) => (e.widget as EditableImage).source)
      .toList();
  return imgs.isEmpty ? null : imgs.last;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(() {
    VideoPool.instance.debugDropAll();
    DayClock.clock = null;
  });

  test('playerCoverArtFor uses the Sound Library image, never a theme still', () {
    const library = [
      'AAROGYA', 'PRANA', 'SHAKTI', 'ANANDA', 'SOMA', 'TEJAS', //
      'OJAS', 'VATA', 'PITTA', 'KAPHA', 'SURYA', 'CHANDRA',
    ];
    for (var i = 0; i < library.length; i++) {
      final w = Word.from({'word': library[i]})!;
      final art = playerCoverArtFor(w, i);
      expect(art, soundLibraryArtFor(library[i]), reason: library[i]);
      expect(art, isNot(startsWith('assets/word_posters/')), reason: library[i]);
      expect(kPlayerThemeImages, isNot(contains(art)), reason: library[i]);
      expect(File(art).existsSync(), isTrue, reason: art);
    }
    // Case and spacing do not matter.
    expect(playerCoverArtFor(Word.from({'word': 'Soma'})!, 3),
        soundLibraryArtFor('Soma'));

    // A theme still is ignored; the word still gets its library picture.
    final themed = Word.from({
      'word': 'SURYA',
      'img': kPlayerThemeImages.first,
    })!;
    expect(playerCoverArtFor(themed, 0), soundLibraryArtFor('SURYA'));

    // A word with its own picture keeps that picture.
    final withImg = Word.from({
      'word': 'ZZZCOVERTEST',
      'img': 'assets/player/t-wave.jpg',
    })!;
    expect(playerCoverArtFor(withImg, 0), 'assets/player/t-wave.jpg');

    // A theme still is not used; a nameless-to-the-library word still gets
    // the same hashed collection banner Sound Library would show.
    final stillImg = Word.from({
      'word': 'ZZZSTILL',
      'img': kPlayerThemeImages[2],
    })!;
    expect(playerCoverArtFor(stillImg, 2), soundLibraryArtFor('ZZZSTILL'));
    final bare = Word.from({'word': 'ZZZBARECOVER'})!;
    expect(playerCoverArtFor(bare, 2), soundLibraryArtFor('ZZZBARECOVER'));
    expect(playerCoverArtFor(null, 0), kNowssbPoster);
    expect(File(kNowssbPoster).existsSync(), isTrue);

    // Typography posters are only a fallback when there is no library image.
    expect(soundLibraryArtFor(''), isNull);
    expect(wordPosterFor(''), isNull);
  });

  testWidgets('Practice tiles use player covers, not letter art', (t) async {
    DayClock.clock = () => DateTime(2026, 11, 16, 22, 0);
    await t.runAsync(() async {
      await ContentStore.instance
          .start()
          .timeout(const Duration(seconds: 5), onTimeout: () {});
    });
    expect(ContentStore.instance.library, isNotEmpty);

    t.view.physicalSize = const Size(390 * 3, 1400 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    await t.pumpWidget(const MediaQuery(
      data: MediaQueryData(
        size: Size(390, 1400),
        devicePixelRatio: 3,
        disableAnimations: true,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: PracticeScreen(),
      ),
    ));
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(KitWordArt), findsNothing);
    expect(find.text('Night Restoration'), findsOneWidget);
    expect(find.text('This session'), findsOneWidget);

    final session = ['SOMA', 'PITTA', 'KAPHA', 'CHANDRA'];
    for (final w in session) {
      expect(find.text(w), findsWidgets, reason: w);
    }

    expect(_heroCover(t), soundLibraryArtFor('SOMA'),
        reason: 'SOMA is first in the night session, same as the library');

    // Each This session row shows that word's player cover.
    final pane = find.byKey(const ValueKey('practice-session-pane'));
    expect(pane, findsOneWidget);
    final rowImgs = find
        .descendant(of: pane, matching: find.byType(EditableImage))
        .evaluate()
        .map((e) => (e.widget as EditableImage).source)
        .toList();
    expect(rowImgs.length, greaterThanOrEqualTo(4));
    expect(rowImgs.take(4).toList(),
        [for (final w in session) soundLibraryArtFor(w)]);

    // Also today rows, if present, must also be covers not letter tiles.
    final also = find.byKey(const ValueKey('practice-also-pane'));
    if (also.evaluate().isNotEmpty) {
      final alsoImgs = find
          .descendant(of: also, matching: find.byType(EditableImage))
          .evaluate();
      expect(alsoImgs, isNotEmpty);
      for (final e in alsoImgs) {
        final src = (e.widget as EditableImage).source;
        expect(
          src.startsWith('assets/store/collections/') ||
              src.startsWith('assets/word_posters/'),
          isTrue,
          reason: src,
        );
      }
    }

    // Selecting a chip crossfades the hero to that word's player cover.
    Future<void> select(String word) async {
      final f = _pill(word);
      await t.ensureVisible(f);
      await t.pump();
      await t.tap(f);
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(_heroCover(t), soundLibraryArtFor(word), reason: word);
    }

    await select('PITTA');
    await select('KAPHA');
    await select('CHANDRA');
    await select('SOMA');

    expect(find.byType(KitWordArt), findsNothing);
    expect(t.takeException(), isNull);
  });
}
