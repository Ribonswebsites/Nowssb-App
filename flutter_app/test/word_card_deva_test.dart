// The Player's Practice word card (above the Practice sheet): the English
// word name stays the title, the Devanagari is the line under it, and the
// English syllable pills are gone. A word with no Devanagari shows nothing
// in that line. The Player art overlay shows neither pills nor Devanagari.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice_overlay.dart';

import 'fake_video_platform.dart';

Word _word(String key, String name, String deva, List<List<String>> parts) => Word.from({
      'key': key,
      'word': name,
      'deva': deva,
      'parts': [for (final p in parts) {'roman': p[0], 'deva': p[1]}],
      'syllables': [for (final p in parts) p[0]],
    })!;

void main() {
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  Future<void> pumpCard(WidgetTester t, Word w) async {
    t.view.physicalSize = const Size(412 * 2, 900 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: PracticeLabSheet(word: w, onSpeak: () async {}, onClose: () {}, video: ''),
      ),
    ));
    await t.pump(const Duration(milliseconds: 300));
  }

  void titleOverDeva(WidgetTester t, String title, String deva) {
    final head = find.text(title);
    final line = find.byKey(const ValueKey('practice-card-deva'));
    expect(head, findsOneWidget);
    expect((t.widget(line) as Text).data, deva);
    expect(t.getTopLeft(line).dy, greaterThan(t.getTopLeft(head).dy), reason: 'Devanagari under the English title');
    expect(find.text(deva), findsOneWidget, reason: 'never instead of the title');
  }

  testWidgets('Soma: title Soma, सोम under it, no so · ma pills', (t) async {
    await pumpCard(t, _word('soma', 'Soma', 'सोम', [['so', 'सो'], ['ma', 'म']]));
    titleOverDeva(t, 'Soma', 'सोम');
    expect(find.text('so'), findsNothing);
    expect(find.text('ma'), findsNothing);
  });

  testWidgets('America (shipped content): America on top, ळमेरिका below', (t) async {
    ContentStore.instance.debugSetClientWords(
        (jsonDecode(File('assets/content/client_words.json').readAsStringSync()) as Map)['items'] as List);
    final america = ContentStore.instance.library.firstWhere((w) => w.key == 'america');
    await pumpCard(t, america);
    titleOverDeva(t, 'America', 'ळमेरिका');
  });

  testWidgets('no Devanagari: title only, the line is empty, no pills', (t) async {
    await pumpCard(t, _word('plain', 'Plain', '', [['pl', ''], ['ain', '']]));
    expect(find.text('Plain'), findsOneWidget);
    expect(find.byKey(const ValueKey('practice-card-deva')), findsNothing);
    expect(find.text('pl'), findsNothing);
    expect(find.text('ain'), findsNothing);
  });

  test('the Player art overlay has no syllable pills and no Devanagari title', () {
    final src = File('lib/screens/practice_player.dart').readAsStringSync();
    expect(src.contains('_SyllablePill'), isFalse);
    expect(src.contains("ValueKey('word-card-deva')"), isFalse);
  });
}
