import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/screens/word_level_changer.dart';

Word _w(List<WordStage> stages) => Word(
      key: 'om', word: 'Om', deva: '', translit: '', phonetic: '', parts: const [],
      audioMale: '', audioFemale: '', organ: '', origin: '', benefit: '', meaning: '',
      mouthPos: '', resonance: '', mistake: '', tip: '', categories: const [],
      gender: 'both', time: 'any', price: 0, img: '', stages: stages,
    );

Widget _host(Word w, {bool open = true}) =>
    MaterialApp(home: Scaffold(body: WordLevelChanger(word: w, open: open)));

void main() {
  testWidgets('changes between 10 levels with buttons and chips', (t) async {
    await t.pumpWidget(_host(_w(const [
      WordStage(title: 'Breath', text: 'Slow in', audio: ''),
      WordStage(title: 'Hum', text: 'Low hum', audio: ''),
    ])));
    expect(find.text('Level 1 of 10'), findsOneWidget);
    expect(find.text('Slow in'), findsOneWidget);
    await t.tap(find.byKey(const Key('wordLevelNext')));
    await t.pump();
    expect(find.text('Level 2 of 10'), findsOneWidget);
    expect(find.text('Low hum'), findsOneWidget);
    await t.tap(find.byKey(const Key('wordLevelPrev')));
    await t.pump();
    expect(find.text('Level 1 of 10'), findsOneWidget);
    await t.drag(find.byType(ListView), const Offset(-400, 0));
    await t.pump();
    await t.tap(find.byKey(const Key('wordLevel10')));
    await t.pump();
    expect(find.text('Level 10 of 10'), findsOneWidget);
    expect(find.textContaining("isn't available"), findsOneWidget);
    expect(find.bySemanticsLabel('Next level'), findsOneWidget);
  });

  testWidgets('empty word: honest empty state', (t) async {
    await t.pumpWidget(_host(_w(const [])));
    expect(find.textContaining("isn't available"), findsOneWidget);
  });

  testWidgets('locked word: higher levels ask to unlock', (t) async {
    await t.pumpWidget(_host(_w(const [
      WordStage(title: 'A', text: 'a', audio: ''),
      WordStage(title: 'B', text: 'b', audio: ''),
    ]), open: false));
    await t.tap(find.byKey(const Key('wordLevelNext')));
    await t.pump();
    expect(find.textContaining('Unlock this word to practise level 2'), findsOneWidget);
  });
}
