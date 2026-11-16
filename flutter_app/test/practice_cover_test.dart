// Practice tab: every letter tile is replaced by the word's player cover,
// and the Today's session art follows the selected word chip.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/admin/template/editable.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/day_part.dart';
import 'package:nowssb/data/models.dart';
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

  test('playerCoverArtFor uses the word image, else the player theme still', () {
    expect(playerCoverArtFor(null, 0), kPlayerThemeImages[0]);
    expect(playerCoverArtFor(null, 1), kPlayerThemeImages[1]);
    expect(playerCoverArtFor(null, kPlayerThemeImages.length),
        kPlayerThemeImages[0]);

    final withImg = Word.from({
      'word': 'ZZZCOVERTEST',
      'img': 'assets/player/t-wave.jpg',
    })!;
    expect(playerCoverArtFor(withImg, 0), 'assets/player/t-wave.jpg');

    final bare = Word.from({'word': 'ZZZBARECOVER'})!;
    expect(playerCoverArtFor(bare, 2), kPlayerThemeImages[2]);
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

    expect(_heroCover(t), kPlayerThemeImages[0],
        reason: 'SOMA is first in the night session, same as the player');

    // Each This session row shows that word's player cover.
    final pane = find.byKey(const ValueKey('practice-session-pane'));
    expect(pane, findsOneWidget);
    final rowImgs = find
        .descendant(of: pane, matching: find.byType(EditableImage))
        .evaluate()
        .map((e) => (e.widget as EditableImage).source)
        .toList();
    expect(rowImgs.length, greaterThanOrEqualTo(4));
    expect(rowImgs.take(4).toList(), kPlayerThemeImages.take(4).toList());

    // Also today rows, if present, must also be covers not letter tiles.
    final also = find.byKey(const ValueKey('practice-also-pane'));
    if (also.evaluate().isNotEmpty) {
      final alsoImgs = find
          .descendant(of: also, matching: find.byType(EditableImage))
          .evaluate();
      expect(alsoImgs, isNotEmpty);
    }

    // Selecting a chip crossfades the hero to that word's player cover.
    Future<void> select(String word, int index) async {
      final f = _pill(word);
      await t.ensureVisible(f);
      await t.pump();
      await t.tap(f);
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(_heroCover(t), kPlayerThemeImages[index], reason: word);
    }

    await select('PITTA', 1);
    await select('KAPHA', 2);
    await select('CHANDRA', 3);
    await select('SOMA', 0);

    expect(find.byType(KitWordArt), findsNothing);
    expect(t.takeException(), isNull);
  });
}
