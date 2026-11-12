import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/profile_mind.dart';
import 'package:nowssb/widgets/editeaze.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'curated palettes: 8–12 entries, unique ids, distinct shades, contrast',
    () {
      expect(kMindPalettes.length, inInclusiveRange(8, 12));
      expect(
        kMindPalettes.map((p) => p.id).toSet().length,
        kMindPalettes.length,
      );
      for (final p in kMindPalettes) {
        final body = [p.focus, p.rhythm, p.week, p.tile];
        expect(
          body.toSet().length,
          4,
          reason: '${p.id} must use four different shades',
        );
        for (final c in body) {
          expect(
            _contrast(c, Colors.white),
            greaterThanOrEqualTo(4.5),
            reason: '${p.id} $c vs white',
          );
        }
      }
    },
  );

  test('pickMindPaletteIndex never repeats the last index', () {
    const n = 12;
    // First open (no last): any index in range.
    for (var seed = 0; seed < 40; seed++) {
      final r = math.Random(seed);
      final i = pickMindPaletteIndex(last: -1, length: n, nextInt: r.nextInt);
      expect(i, inInclusiveRange(0, n - 1));
    }
    // Every last index, every seed: next is in range and not last.
    for (var last = 0; last < n; last++) {
      for (var seed = 0; seed < 30; seed++) {
        final i = pickMindPaletteIndex(
          last: last,
          length: n,
          nextInt: math.Random(seed).nextInt,
        );
        expect(i, inInclusiveRange(0, n - 1));
        expect(i, isNot(last), reason: 'last=$last seed=$seed picked $i');
      }
    }
  });

  testWidgets('palette changes between opens and never repeats back to back', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final rng = math.Random(7);
    final seen = <int>[];

    Future<int> open() async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ProfileMind(random: rng)),
          ),
        ),
      );
      await t.pumpAndSettle();
      final p = await SharedPreferences.getInstance();
      final idx = p.getInt(kMindPalettePrefKey)!;
      final pal = kMindPalettes[idx];
      // Empty state uses the focus shade (no sessions in this test).
      final card = t.widget<EzOrangeCard>(
        find.byKey(const ValueKey('mind-empty')),
      );
      expect(card.color, pal.focus);
      expect(card.headerFade, isFalse);
      await t.pumpWidget(const SizedBox());
      await t.pump();
      return idx;
    }

    for (var i = 0; i < 16; i++) {
      seen.add(await open());
    }
    expect(
      seen.toSet().length,
      greaterThan(1),
      reason: 'opens must change palette over time',
    );
    for (var i = 1; i < seen.length; i++) {
      expect(
        seen[i],
        isNot(seen[i - 1]),
        reason: 'back-to-back repeat at $i: $seen',
      );
    }
  });

  testWidgets(
    'forced palettes paint Focus, Rhythm and This week in different shades',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      // Empty state only has the focus card. Forced index still colours it,
      // and a second pump with the same API stays on that palette.
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ProfileMind(paletteIndex: 2)),
          ),
        ),
      );
      await t.pumpAndSettle();
      final empty = t.widget<EzOrangeCard>(
        find.byKey(const ValueKey('mind-empty')),
      );
      expect(empty.color, kMindPalettes[2].focus);
      expect(empty.headerFade, isFalse);
      expect(empty.image, kMindPalettes[2].image);
      expect(_shownPhoto(t), kMindPalettes[2].image);
    },
  );

  test('each palette has its own existing, small, unique focus portrait', () {
    final images = [for (final p in kMindPalettes) p.image];
    expect(images.toSet().length, kMindPalettes.length);
    final digests = <String, String>{};
    for (final a in images) {
      final f = File(a);
      expect(f.existsSync(), isTrue, reason: '$a missing');
      expect(a, endsWith('.webp'));
      expect(f.lengthSync(), lessThanOrEqualTo(120 * 1024), reason: a);
      digests[a] = base64Encode(f.readAsBytesSync());
    }
    expect(digests.values.toSet().length, images.length,
        reason: 'two palettes share the same photo bytes');
    final own = images.map((a) => File(a).absolute.path).toSet();
    final dupes = <String>[];
    for (final e in Directory('assets').listSync(recursive: true)) {
      if (e is! File || own.contains(e.absolute.path)) continue;
      final b = base64Encode(e.readAsBytesSync());
      if (digests.containsValue(b)) dupes.add(e.path);
    }
    expect(dupes, isEmpty, reason: 'focus portraits reused elsewhere: $dupes');
  });

  testWidgets('the photo changes together with the palette on every open', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final rng = math.Random(11);
    String? lastPhoto;
    for (var i = 0; i < 12; i++) {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ProfileMind(random: rng)),
          ),
        ),
      );
      await t.pumpAndSettle();
      final idx = (await SharedPreferences.getInstance()).getInt(
        kMindPalettePrefKey,
      )!;
      final photo = _shownPhoto(t);
      expect(photo, kMindPalettes[idx].image);
      expect(
        find.byKey(const ValueKey('mind-photo-from')),
        findsNothing,
        reason: 'old portrait must be gone after the crossfade',
      );
      if (lastPhoto != null) expect(photo, isNot(lastPhoto));
      lastPhoto = photo;
      await t.pumpWidget(const SizedBox());
      await t.pump();
    }
  });

  testWidgets('portrait crossfades from the previous person over 600ms', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({kMindPalettePrefKey: 0});
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileMind(random: _Fixed(4)),
          ),
        ),
      ),
    );
    // Let prefs + precache resolve, then sit mid-way through the fade.
    for (var i = 0;
        i < 6 &&
            find.byKey(const ValueKey('mind-photo-from')).evaluate().isEmpty;
        i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.pump(const Duration(milliseconds: 200));
    final from =
        t.widget<Opacity>(find.byKey(const ValueKey('mind-photo-from')));
    final to = t.widget<Opacity>(find.byKey(const ValueKey('mind-photo-to')));
    expect(_assetOf(from.child! as Image), kMindPalettes[0].image);
    expect(_assetOf(to.child! as Image), kMindPalettes[5].image);
    expect(from.opacity, inExclusiveRange(0, 1));
    expect(to.opacity, 1);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('mind-photo-from')), findsNothing);
    expect(_shownPhoto(t), kMindPalettes[5].image);
  });

  test('focus portrait is unique and not reused elsewhere in the app', () {
    final focus = File('assets/home/ez/ez-med-focus.webp');
    expect(focus.existsSync(), isTrue);
    final bytes = focus.readAsBytesSync();
    expect(bytes, isNotEmpty);
    final others = <String>[];
    for (final entity in Directory('assets').listSync(recursive: true)) {
      if (entity is! File) continue;
      if (entity.path == focus.path) continue;
      if (entity.readAsBytesSync().length == bytes.length &&
          _same(entity.readAsBytesSync(), bytes)) {
        others.add(entity.path);
      }
    }
    expect(
      others,
      isEmpty,
      reason: 'ez-med-focus.webp must not duplicate another asset: $others',
    );

    final hits = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('profile_mind.dart')) continue;
      if (entity.readAsStringSync().contains('ez-med-focus')) {
        hits.add(entity.path);
      }
    }
    expect(
      hits,
      isEmpty,
      reason: 'focus photo must only be used by the practice mind section',
    );
  });
}

/// Always returns [v] (clamped); with last=0 the picker maps 4 -> index 5.
class _Fixed implements math.Random {
  _Fixed(this.v);
  final int v;
  @override
  int nextInt(int max) => v.clamp(0, max - 1);
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

String _assetOf(Image img) =>
    ((img.image as ResizeImage).imageProvider as AssetImage).assetName;

String _shownPhoto(WidgetTester t) {
  final o = t.widget<Opacity>(find.byKey(const ValueKey('mind-photo-to')));
  return _assetOf(o.child! as Image);
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  final hi = math.max(l1, l2), lo = math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}
