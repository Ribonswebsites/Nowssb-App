import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/screens/fashion/door_screens.dart';
import 'package:nowssb/screens/quick_access.dart';

void main() {
  test('every Access feature has its own doors art, and it exists', () {
    final ids = [for (final f in quickAccessFeatures) f['id']!];
    final art = [for (final f in DoorAccessScreen.features) f.art];
    expect(art.length, ids.length);
    for (var i = 0; i < ids.length; i++) {
      expect(art[i], 'assets/doors/${ids[i]}.webp', reason: ids[i]);
      expect(File(art[i]!).existsSync(), isTrue, reason: art[i]);
    }
    expect(art.toSet().length, art.length, reason: 'art is unique per feature');
    expect(doorAccessArt.keys.toSet(), ids.toSet());
  });

  test('Start art Meanings/eBooks, Zen Plus Store + TV use the doors art', () {
    expect(doorStillArt('Meanings Clean', 'x'), 'assets/doors/meanings.webp');
    expect(doorStillArt('eBooks Pair', 'x'), 'assets/doors/hour-kapha.webp');
    expect(doorStillArt('Zen', 'x'), 'assets/doors/fashion_plus_tv.webp');
    expect(doorStillArt('Store', 'x'), 'assets/doors/store.webp');
    expect(doorStillArt('Word Atelier', 'x'), 'assets/doors/wordscience.webp');
    // Every Start art tile has its own art: no two tiles share a file.
    final tiles = [
      for (var i = 0; i < Settings.fashionImages.length; i++)
        doorStillArt(Settings.fashionImageName(i), Settings.fashionImages[i])
    ];
    expect(tiles.toSet().length, tiles.length, reason: '$tiles');
    // Every Start art tile uses text-free doors art that exists.
    for (var i = 0; i < Settings.fashionImages.length; i++) {
      final a = doorStillArt(Settings.fashionImageName(i), Settings.fashionImages[i]);
      expect(a, startsWith('assets/doors/'), reason: Settings.fashionImageName(i));
      expect(File(a).existsSync(), isTrue, reason: a);
    }
    for (final f in ['meanings', 'ebooks', 'fashion_plus_store', 'fashion_plus_tv']) {
      expect(File('assets/doors/$f.webp').existsSync(), isTrue, reason: f);
    }
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/doors/'));
    for (final f in Directory('assets/doors').listSync()) {
      expect(File('pubspec.yaml').readAsStringSync(), contains('- ${f.path}'), reason: 'not bundled');
    }
  });
}
