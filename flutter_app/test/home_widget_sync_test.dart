import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/home_widget_sync.dart';
import 'package:nowssb/data/models.dart';

Word _w(String word, {num price = 0, String meaning = '', String deva = ''}) => Word(
      key: word.toLowerCase(),
      word: word,
      deva: deva,
      translit: '',
      phonetic: '',
      parts: const [],
      audioMale: '',
      audioFemale: '',
      organ: '',
      origin: 'Sanskrit',
      benefit: '',
      meaning: meaning,
      mouthPos: '',
      resonance: '',
      mistake: '',
      tip: '',
      categories: const [],
      gender: 'both',
      time: 'any',
      price: price,
      img: '',
    );

void main() {
  final lib = [
    _w('Ananda', meaning: 'Bliss', deva: 'आनन्द'),
    _w('Phoenix', price: 99),
    _w('Shanti', meaning: 'Peace'),
  ];

  test('word of the day is stable per day and prefers free words', () {
    final d = DateTime(2026, 10, 3);
    final a = HomeWidgetSync.wordFor(d, lib)!;
    expect(HomeWidgetSync.wordFor(d, lib)!.word, a.word);
    expect(a.price, 0);
    final next = HomeWidgetSync.wordFor(DateTime(2026, 10, 4), lib)!;
    expect(next.word, isNot(a.word));
    expect(HomeWidgetSync.wordFor(d, const []), isNull);
  });

  test('payload carries the streak and a week of words for the widget', () {
    final p = HomeWidgetSync.payload(
      now: DateTime(2026, 10, 3, 22),
      library: lib,
      streak: 5,
      lastDay: '2026-10-03',
    );
    expect(p['nw_streak'], '5');
    expect(p['nw_last_day'], '2026-10-03');
    for (var d = 3; d < 10; d++) {
      expect(p.containsKey('nw_word_2026-10-${d.toString().padLeft(2, '0')}'), isTrue);
    }
    expect(p['nw_word_fallback'], p['nw_word_2026-10-03']);
    expect(HomeWidgetSync.lineFor(lib.first), 'आनन्द · Bliss');
  });

  test('the Android widget is generated with the keys the app writes', () {
    final gen = File('../tools/flutter-android.mjs').readAsStringSync();
    expect(gen, contains('class NowssbHomeWidget : HomeWidgetProvider()'));
    expect(gen, contains('android.appwidget.action.APPWIDGET_UPDATE'));
    expect(gen, contains('@xml/nowssb_widget_info'));
    expect(gen, contains('es.antonborri.home_widget.action.LAUNCH'));
    for (final k in ['nw_streak', 'nw_last_day', 'nw_word_', 'nw_line_', 'nw_word_fallback']) {
      expect(gen, contains('"$k'), reason: k);
    }
    expect(HomeWidgetSync.qualifiedName, 'com.nowssb.nowssb.NowssbHomeWidget');
  });

  test('quick access offers a Journal shortcut that opens the inbox', () {
    final qa = File('lib/screens/quick_access.dart').readAsStringSync();
    final nav = File('lib/shell/nav_shell.dart').readAsStringSync();
    expect(qa, contains("'id': 'journal'"));
    expect(nav, contains("'journal' => const InboxScreen()"));
    expect(File('assets/icons/qa-journal.png').existsSync(), isTrue);
  });
}
