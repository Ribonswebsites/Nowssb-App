// Picked for you card on the Normal home: real words by body area, its own
// daily order that never opens with New releases' lead tiles, working taps,
// the black container and edge fade, and no overflow at 360/390 x 1.0/1.3.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/screens/normal/new_releases.dart';
import 'package:nowssb/screens/normal/picked_for_you.dart';
import 'package:nowssb/screens/practice_player.dart';

import 'support/test_fonts.dart';

Word _word(String key, String organ) => Word.from({
      'key': key,
      'word': key.toUpperCase(),
      'organ': organ,
      'meaning': '',
      'benefit': '',
      'img': '',
    })!;

final _sample = [
  _word('aarogya', 'Immune System'),
  _word('prana', 'Lungs · Heart'),
  _word('shakti', 'Solar Plexus'),
  _word('ananda', 'Nervous System'),
  _word('soma', 'Brain'),
  _word('tejas', 'Eyes · Skin'),
  _word('ojas', 'Immune · Vitality'),
  _word('vata', 'Nervous System'),
  _word('pitta', 'Liver · Digestion'),
  _word('kapha', 'Lungs · Joints'),
  _word('surya', 'Heart · Energy'),
  _word('chandra', 'Mind · Emotions'),
];

final _day1 = DateTime(2026, 11, 17, 9);

Widget _app({required Widget child, double width = 390, double scale = 1}) =>
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, 900),
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

void main() {
  setUpAll(() async {
    await loadDmSans();
    await loadMaterialIcons();
  });

  test('every word once, stable in a day, never leading with New releases', () {
    for (var d = 0; d < 60; d++) {
      final day = DateTime(2026, 11, 1 + d, 10);
      final picked = pickedForYouWords(_sample, on: day);
      expect(picked.length, _sample.length);
      expect(picked.map((w) => w.key).toSet().length, _sample.length);
      final lead = newReleaseWords(_sample, on: day)
          .take(kPickedAvoidLead)
          .map((w) => w.key)
          .toSet();
      for (final w in picked.take(_sample.length - kPickedAvoidLead)) {
        expect(lead.contains(w.key), isFalse, reason: 'day $d: ${w.key}');
      }
      expect(
        pickedForYouWords(_sample, on: DateTime(day.year, day.month, day.day))
            .map((w) => w.key),
        picked.map((w) => w.key),
      );
    }
    final leads = {
      for (var d = 0; d < 7; d++)
        pickedForYouWords(_sample, on: DateTime(2026, 11, 17 + d)).first.key,
    };
    expect(leads.length, greaterThan(2));
    expect(pickedForYouWords(const []), isEmpty);
  });

  test('subtitle names the body areas', () {
    final items = pickedForYouWords(_sample, on: _day1);
    final s = pickedSubtitle(items);
    expect(s, startsWith('By body area · '));
    expect(s, contains(items.first.organ));
    expect(pickedSubtitle(const []), 'By body area');
  });

  testWidgets('renders a bigger lead tile, real covers and the black card',
      (t) async {
    t.view.physicalSize = const Size(390 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    await t.pumpWidget(_app(
      child: PickedForYouCard(
        words: _sample,
        today: _day1,
        onWord: (_) {},
        onSeeAll: () {},
      ),
    ));
    await t.pump();

    expect(find.text('Picked for you'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    final items = pickedForYouWords(_sample, on: _day1);
    expect(find.text(items.first.word), findsOneWidget);

    final leadSize =
        t.getSize(find.byKey(ValueKey('picked-tile-${items[0].key}')));
    final nextSize =
        t.getSize(find.byKey(ValueKey('picked-tile-${items[1].key}')));
    expect(leadSize.width, greaterThan(nextSize.width));

    final imgs = t.widgetList<Image>(find.byType(Image)).toList();
    for (var i = 0; i < imgs.length && i < items.length; i++) {
      expect((imgs[i].image as AssetImage).assetName,
          playerCoverArtFor(items[i], i));
    }
    expect(t.widget<ShaderMask>(find.byType(ShaderMask)).blendMode,
        BlendMode.dstIn);
    final box = t.widget<DecoratedBox>(find
        .descendant(
          of: find.byKey(const ValueKey('picked-for-you')),
          matching: find.byType(DecoratedBox),
        )
        .first);
    expect((box.decoration as BoxDecoration).color, Colors.black);
  });

  testWidgets('See all and a tile call through', (t) async {
    t.view.physicalSize = const Size(390 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    var seeAll = 0;
    final tapped = <String>[];
    await t.pumpWidget(_app(
      child: PickedForYouCard(
        words: _sample,
        today: _day1,
        onWord: (w) => tapped.add(w.word),
        onSeeAll: () => seeAll++,
      ),
    ));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('picked-see-all')));
    expect(seeAll, 1);
    final lead = pickedForYouWords(_sample, on: _day1).first;
    await t.tap(find.byKey(ValueKey('picked-tile-${lead.key}')));
    expect(tapped, [lead.word]);
  });

  testWidgets('live clock mode builds and disposes cleanly', (t) async {
    await t.pumpWidget(_app(
      child: PickedForYouCard(
        words: _sample,
        onWord: (_) {},
        onSeeAll: () {},
      ),
    ));
    await t.pump();
    expect(find.text('Picked for you'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
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
        child: PickedForYouCard(
          words: _sample,
          today: _day1,
          onWord: (_) {},
          onSeeAll: () {},
        ),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(overflows, isEmpty, reason: 'overflows at $tag: $overflows');
      expect(find.text('Picked for you'), findsOneWidget);
    });
  }
}
