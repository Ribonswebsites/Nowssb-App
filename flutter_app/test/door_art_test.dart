import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/screens/concept/doors/door_fashion_plus.dart';
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

  test('Start art Meanings/eBooks, Fashion Plus Store + TV use the doors art', () {
    expect(doorStillArt('Meanings Clean', 'x'), 'assets/doors/meanings.webp');
    expect(doorStillArt('eBooks Pair', 'x'), 'assets/doors/hour-kapha.webp');
    expect(doorStillArt('Fashion', 'x'), 'assets/doors/fashion_plus_tv.webp');
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
    final store = DoorFashionPlusScreen.jumps.firstWhere((j) => j.id == 'store').art;
    expect(store, 'assets/doors/fashion_plus_store.webp');
    expect(DoorHeroStyle.all.firstWhere((h) => h.id == 'tv').art, 'assets/doors/fashion_plus_tv.webp');
    for (final f in ['meanings', 'ebooks', 'fashion_plus_store', 'fashion_plus_tv']) {
      expect(File('assets/doors/$f.webp').existsSync(), isTrue, reason: f);
    }
    // Hero 'Full screen' + Store jump: no printed 'FASHION' / model face under the title.
    expect(DoorHeroStyle.all.firstWhere((h) => h.id == 'full').art, 'assets/doors/hour-ananda.webp');
    expect(DoorFashionPlusScreen.jumps.firstWhere((j) => j.id == 'practice').art, 'assets/doors/practice.webp');
    // Make it yours: Player Settings + Healing carry no printed 'Chose Your Path'.
    final make = DoorFashionPlusScreen.make(Settings.instance);
    expect(make.firstWhere((j) => j.id == 'player').art, 'assets/doors/hour-prana.webp');
    expect(make.firstWhere((j) => j.id == 'healing').art, 'assets/doors/hour-aarogya.webp');
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/doors/'));
    for (final f in Directory('assets/doors').listSync()) {
      expect(File('pubspec.yaml').readAsStringSync(), contains('- ${f.path}'), reason: 'not bundled');
    }
  });
}
