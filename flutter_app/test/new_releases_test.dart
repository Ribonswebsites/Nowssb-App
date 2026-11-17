// New releases card on the Normal home: real words and covers, working
// taps, edge fades, and no overflow at 360/390 and text scale 1.0/1.3.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/screens/normal/new_releases.dart';
import 'package:nowssb/screens/practice_player.dart';

import 'support/test_fonts.dart';

Word _word({
  required String key,
  required String word,
  String organ = '',
  String meaning = '',
  String benefit = '',
  String img = '',
}) =>
    Word.from({
      'key': key,
      'word': word,
      'organ': organ,
      'meaning': meaning,
      'benefit': benefit,
      'img': img,
    })!;

final _day1 = DateTime(2026, 11, 17, 9);

final _sample = [
  _word(key: 'aarogya', word: 'AAROGYA', organ: 'Immune System'),
  _word(key: 'prana', word: 'PRANA', organ: 'Lungs · Heart'),
  _word(key: 'shakti', word: 'SHAKTI', organ: 'Solar Plexus'),
  _word(
      key: 'soma',
      word: 'SOMA',
      organ: 'Brain',
      meaning: 'Nectar of consciousness'),
  _word(key: 'pitta', word: 'PITTA', organ: 'Liver · Digestion'),
  _word(key: 'kapha', word: 'KAPHA', organ: 'Lungs · Joints'),
  _word(key: 'chandra', word: 'CHANDRA', organ: 'Mind · Emotions'),
];

Widget _app({
  required Widget child,
  double width = 390,
  double height = 900,
  double scale = 1,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: Size(width, height),
      textScaler: TextScaler.linear(scale),
      disableAnimations: true,
    ),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Scaffold(
        backgroundColor: const Color(0xFFEDEFF3),
        body: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await loadDmSans();
    await loadMaterialIcons();
  });

  test('newReleaseWords lists every word once, in a daily order', () {
    final a = newReleaseWords(_sample, on: _day1);
    expect(a.length, _sample.length);
    expect(a.map((w) => w.key).toSet(), _sample.map((w) => w.key).toSet());
    // Stable within a day, from early morning to just before midnight.
    expect(
      newReleaseWords(_sample, on: DateTime(2026, 11, 17, 0, 1))
          .map((w) => w.key),
      newReleaseWords(_sample, on: DateTime(2026, 11, 17, 23, 59))
          .map((w) => w.key),
    );
    // Over a week the row does not keep the same order every day.
    final orders = {
      for (var d = 0; d < 7; d++)
        newReleaseWords(_sample, on: DateTime(2026, 11, 17 + d))
            .map((w) => w.key)
            .join(','),
    };
    expect(orders.length, greaterThan(4));
    final leads = {
      for (var d = 0; d < 7; d++)
        newReleaseWords(_sample, on: DateTime(2026, 11, 17 + d)).first.key,
    };
    expect(leads.length, greaterThan(2));
    expect(newReleaseWords(const []), isEmpty);
  });

  test('homeDayNumber moves at local midnight only', () {
    expect(homeDayNumber(DateTime(2026, 11, 17, 0, 0)),
        homeDayNumber(DateTime(2026, 11, 17, 23, 59, 59)));
    expect(
        homeDayNumber(DateTime(2026, 11, 18)) -
            homeDayNumber(DateTime(2026, 11, 17, 23, 59)),
        1);
  });

  test('newReleaseSubtitle prefers organ, then meaning, then benefit', () {
    expect(newReleaseSubtitle(_sample.first), 'Immune System');
    expect(
      newReleaseSubtitle(
          _word(key: 'x', word: 'X', meaning: 'A short meaning')),
      'A short meaning',
    );
    expect(
      newReleaseSubtitle(
          _word(key: 'y', word: 'Y', benefit: 'Builds immunity')),
      'Builds immunity',
    );
    expect(newReleaseSubtitle(_word(key: 'z', word: 'Z')), isEmpty);
  });

  test('newReleaseQueue starts at the tapped word', () {
    final items = newReleaseWords(_sample, on: _day1);
    final q = newReleaseQueue(items, items[2]);
    expect(q.first.word, items[2].word);
    expect(q.length, items.length);
    expect(q.toSet().length, items.length);
  });

  testWidgets('renders titles, subtitles, covers and the edge fade', (t) async {
    t.view.physicalSize = const Size(390 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    await t.pumpWidget(_app(
      child: NewReleasesCard(
        words: _sample,
        today: _day1,
        onWord: (_) {},
        onSeeAll: () {},
      ),
    ));
    await t.pump();

    expect(find.text('New releases'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-releases')), findsOneWidget);

    // Today's lead word is the first tile, with its real subtitle.
    final lead = newReleaseWords(_sample, on: _day1).first;
    expect(find.text(lead.word), findsOneWidget);
    expect(find.text(newReleaseSubtitle(lead)), findsWidgets);

    final mask = t.widget<ShaderMask>(find.byType(ShaderMask));
    expect(mask.blendMode, BlendMode.dstIn);

    // Tiles use the same cover resolver the player uses.
    final imgs = t.widgetList<Image>(find.byType(Image)).toList();
    expect(imgs, isNotEmpty);
    final items = newReleaseWords(_sample, on: _day1);
    for (var i = 0; i < imgs.length && i < items.length; i++) {
      expect((imgs[i].image as AssetImage).assetName,
          playerCoverArtFor(items[i], i));
    }

    // The container itself is black.
    final box = t.widget<DecoratedBox>(find
        .descendant(
          of: find.byKey(const ValueKey('new-releases')),
          matching: find.byType(DecoratedBox),
        )
        .first);
    final deco = box.decoration as BoxDecoration;
    expect(deco.color, Colors.black);
  });

  testWidgets('See all and a tile call through', (t) async {
    t.view.physicalSize = const Size(390 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    var seeAll = 0;
    final tapped = <String>[];
    await t.pumpWidget(_app(
      child: NewReleasesCard(
        words: _sample,
        today: _day1,
        onWord: (w) => tapped.add(w.word),
        onSeeAll: () => seeAll++,
      ),
    ));
    await t.pump();

    await t.tap(find.byKey(const ValueKey('newrel-see-all')));
    expect(seeAll, 1);

    final lead = newReleaseWords(_sample, on: _day1).first;
    await t.tap(find.byKey(ValueKey('newrel-tile-${lead.key}')));
    expect(tapped, [lead.word]);
  });

  testWidgets('an empty library hides the card', (t) async {
    await t.pumpWidget(_app(
      child: NewReleasesCard(words: const [], onWord: (_) {}, onSeeAll: () {}),
    ));
    await t.pump();
    expect(find.text('New releases'), findsNothing);
    expect(find.byKey(const ValueKey('new-releases')), findsNothing);
  });

  for (final (w, s, tag) in [
    (360.0, 1.0, '360'),
    (390.0, 1.0, '390'),
    (360.0, 1.3, '360x1.3'),
    (390.0, 1.3, '390x1.3'),
  ]) {
    testWidgets('no overflow at $tag', (t) async {
      t.view.physicalSize = Size(w * 3, 900 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      final overflows = <String>[];
      final old = FlutterError.onError;
      addTearDown(() => FlutterError.onError = old);
      FlutterError.onError = (d) {
        old?.call(d);
        final msg = d.toString();
        if (msg.contains('overflow') || msg.contains('OVERFLOW')) {
          overflows.add(msg.split('\n').first);
        }
      };

      await t.pumpWidget(_app(
        width: w,
        scale: s,
        child: NewReleasesCard(
          words: _sample,
          onWord: (_) {},
          onSeeAll: () {},
        ),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(overflows, isEmpty, reason: 'overflows at $tag: $overflows');
      expect(find.text('New releases'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
    });
  }
}
