// Guard: AMERICA is the client's own teacher-recorded word and must stay in
// the app. It was dropped once by a catalogue clean-up (Nov 23, 2026) while
// Ribon was showing the app to the client. If this test fails, do NOT
// "fix" it by removing America — put America back.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/data/word_photos.dart';
import 'package:nowssb/features/stage_practice/stage_pack.dart';
import 'package:nowssb/screens/store/store_word_page.dart';

List<dynamic> _shipped() =>
    (jsonDecode(File('assets/content/client_words.json').readAsStringSync()) as Map)['items'] as List;

void main() {
  setUp(() => ContentStore.instance.debugSetClientWords(_shipped()));

  test('America is never a removed word', () {
    expect(kRemovedWordKeys.contains('america'), isFalse);
    expect(isRemovedWord('America'), isFalse);
    expect(isRemovedItemId('word:america'), isFalse);
  });

  test('America ships in client_words.json with its stage recordings', () {
    final e = _shipped().cast<Map>().where((e) => e['key'] == 'america').toList();
    expect(e, hasLength(1), reason: 'America must ship in assets/content/client_words.json');
    final pack = StagePack.fromRaw(Map<String, dynamic>.from(e.single))!;
    expect(pack.stages, isNotEmpty);
    for (final s in pack.stages) {
      expect(File(s.audio).existsSync(), isTrue, reason: s.audio);
      expect(File(s.reference).existsSync(), isTrue, reason: s.reference);
    }
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/words/america/'));
  });

  test('America is in the catalogue (library), with its own photo and collection', () {
    final w = ContentStore.instance.library.where((w) => w.key == 'america').toList();
    expect(w, hasLength(1), reason: 'America must be in the library');
    expect(StagePack.forWord(w.single), isNotNull);
    final photo = wordPhotoFor('america');
    expect(photo, 'assets/word_photos/america.webp');
    expect(File(photo!).existsSync(), isTrue);
    expect(kWordPhotos.values.where((p) => p == photo), hasLength(1));
    expect(StoreWordFacts.of('America', 'Natural Origin', meaning: false).category, kRecordedStagesLabel);
  });

  test('America is practised only in the Player (no separate stage page or cards)', () {
    for (final f in [
      'lib/features/stage_practice/stage_practice_screen.dart',
      'lib/features/stage_practice/staged_words_card.dart',
      'lib/features/stage_practice/stage_access.dart',
    ]) {
      expect(File(f).existsSync(), isFalse, reason: f);
    }
    for (final f in ['lib/screens/sound_library.dart', 'lib/screens/store/store_word_page.dart', 'lib/screens/word_detail.dart']) {
      final src = File(f).readAsStringSync();
      expect(src, isNot(contains('openStagePractice')), reason: f);
      expect(src, isNot(contains('StagedWordsCard')), reason: f);
    }
  });
}
