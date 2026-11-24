// The Player's Stages tab (lib/screens/select_level.dart): no banners or
// video, the current stage and the next two, expandable to every stage with
// the rest locked, Devanagari stage names, a locked "Coming soon" slot for a
// stage the teacher has not recorded, "Request more stages", and "Buy next 3
// stages" through the normal checkout, which opens the next three stages.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/entitlements.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/word_requests.dart';
import 'package:nowssb/features/stage_practice/stage_access.dart';
import 'package:nowssb/features/stage_practice/stage_practice_screen.dart';
import 'package:nowssb/features/stage_practice/stage_progress.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/select_level.dart';
import 'package:nowssb/screens/store/cart_pages.dart';
import 'package:nowssb/widgets/colored_split_promo_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';

Word _soma() => Word.from({
      'key': 'soma',
      'word': 'Soma',
      'deva': 'सोम',
      'price': 99,
      'parts': [
        {'roman': 'so', 'deva': 'सो'},
        {'roman': 'ma', 'deva': 'म'},
      ],
      'stages': [
        for (var i = 1; i <= 7; i++) {'title': 'Stage $i', 'text': 'Soma, line $i'},
      ],
    })!;

void main() {
  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StageProgressStore.debugAccount = 'stages-tab';
    StageProgressStore.instance.debugReset();
    ContentStore.instance.debugSetClientWords(
        (jsonDecode(File('assets/content/client_words.json').readAsStringSync()) as Map)['items'] as List);
    Entitlements.instance.debugSet(uid: 'stages-tab', tier: 'resonance', until: DateTime.now().add(const Duration(days: 30)));
  });

  Future<void> pumpTab(WidgetTester t, Word w) async {
    t.view.physicalSize = const Size(412 * 2, 1100 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: SelectLevelScreen(word: w))));
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('no banners or video; current + next two; expand and collapse; Devanagari', (t) async {
    await pumpTab(t, _soma());
    expect(find.byType(ColoredSplitPromoBanner), findsNothing);
    expect(find.text('SELECT FREQUENCY'), findsNothing);
    expect(find.text('सोम'), findsOneWidget, reason: 'the word in Devanagari, no English split');
    expect(find.text('so'), findsNothing);
    expect(find.byKey(const ValueKey('stages-row-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('stages-row-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('stages-row-4')), findsNothing);
    await t.tap(find.byKey(const ValueKey('stages-expand')));
    await t.pump(const Duration(milliseconds: 200));
    for (var n = 1; n <= 7; n++) {
      expect(find.byKey(ValueKey('stages-row-$n')), findsOneWidget);
    }
    expect(find.text('Locked · in the next 3 stages'), findsNWidgets(4));
    await t.tap(find.byKey(const ValueKey('stages-expand')));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('stages-row-4')), findsNothing);
  });

  testWidgets('picking an open stage sets the Player stage', (t) async {
    await pumpTab(t, _soma());
    await t.tap(find.byKey(const ValueKey('stages-row-2')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Stage 2 is now playing in the Player.'), findsOneWidget);
  });

  testWidgets('Buy next 3 stages opens checkout for stage:soma:4-6 and unlocks 4–6', (t) async {
    await pumpTab(t, _soma());
    expect(stagesOpenFor('soma', 7), 3);
    final buy = find.byKey(const ValueKey('stages-buy-next'));
    await t.ensureVisible(buy);
    await t.pump();
    expect(find.textContaining('Buy next 3 stages'), findsOneWidget);
    await t.tap(buy);
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(CheckoutPage), findsOneWidget);
    expect(find.textContaining('Soma · Stages 4–6'), findsWidgets);
    // Google Play confirms: checkout marks the line paid.
    Entitlements.instance.markPaid(['stage:soma:4-6']);
    expect(stagesOpenFor('soma', 7), 6);
    expect(stageBundleId('soma', 7), 'stage:soma:7-9');
  });

  testWidgets('Request more stages sends a stages request', (t) async {
    await pumpTab(t, _soma());
    final req = find.byKey(const ValueKey('stages-request'));
    await t.ensureVisible(req);
    await t.pump();
    await t.runAsync(() async {
      await t.tap(req);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Requested'), findsOneWidget);
    expect(WordRequestStore.instance.items.first.word, 'Soma');
  });

  testWidgets('America: Devanagari stages, Coming soon slot, practice opens, locks hold', (t) async {
    final america = ContentStore.instance.library.firstWhere((w) => w.key == 'america');
    await pumpTab(t, america);
    expect(find.text('अमेरिका'), findsOneWidget);
    expect(find.byKey(const ValueKey('stages-deva-1')), findsOneWidget);
    expect(find.text('ळमेरिका'), findsOneWidget);
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.byKey(const ValueKey('stages-buy-next')), findsNothing, reason: 'no stages to buy beyond the 3 included');
    expect(find.textContaining('Reference not added', findRichText: true), findsNothing);
    await t.tap(find.byKey(const ValueKey('stages-row-3')));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Stage 3 opens here as soon as your teacher records it.'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('stages-row-2')));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('Pass Stage 1 to open Stage 2.'), findsOneWidget);
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('stages-row-1')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(StagePracticeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('stage-deva')), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}
