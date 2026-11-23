// Shots for the word-page store mark and stacked cards, and the restored
// Profile / My progress mind rows.
// flutter test test/wordplus_shots_test.dart --dart-define=WORDPLUS_SHOTS=<dir>
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/progress/my_progress_kit.dart';
import 'package:nowssb/features/progress/progress_center.dart';
import 'package:nowssb/features/progress/progress_popup.dart';
import 'package:nowssb/features/progress/progress_sources.dart';
import 'package:nowssb/features/progress/today_progress_screen.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:nowssb/screens/profile_mind.dart';
import 'package:nowssb/screens/store/product_detail.dart';
import 'package:nowssb/screens/store/store_art.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

const _out = String.fromEnvironment('WORDPLUS_SHOTS');
final _key = GlobalKey();

Future<void> _settle(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await t.pump(const Duration(milliseconds: 80));
  }
}

Future<void> _shot(WidgetTester t, String name) async {
  if (_out.isEmpty) return;
  await precacheAll(t);
  await t.pump(const Duration(milliseconds: 100));
  final ro = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await t.runAsync(() async {
    final img = await ro.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory(_out).createSync(recursive: true);
    File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Map<String, dynamic> _seed() {
  final now = DateTime.now();
  final out = <String, dynamic>{};
  final hours = [7, 8, 19, 21, 13, 7, 20, 22, 8];
  for (var i = 0; i < hours.length; i++) {
    final d = DateTime(now.year, now.month, now.day - (i ~/ 2), hours[i]);
    final ymd =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    out['${ymd}_w$i'] = {
      'date': ymd,
      'word': 'w$i',
      'completedAt': d.toIso8601String(),
      'durationSec': 300,
    };
  }
  return out;
}

void main() {
  setUpAll(() async {
    await setUpHomeRender();
    final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
    if (emoji.existsSync()) {
      await (FontLoader('NotoColorEmoji')
            ..addFont(Future.value(ByteData.sublistView(emoji.readAsBytesSync()))))
          .load();
    }
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
  });

  testWidgets('wordplus shots', (t) async {
    if (_out.isEmpty) return;

    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
      await CartBag.instance.load();
    });

    Future<void> openWord({String word = 'ocean', String root = 'Old French', double w = 390, double h = 844}) async {
      t.view.physicalSize = Size(w, h);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const SizedBox());
      await t.pump();
      await t.pumpWidget(RepaintBoundary(
        key: _key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
          home: NavScope(
            go: (_) {},
            child: Builder(builder: (c) {
              return Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: TextButton(
                    key: const ValueKey('go'),
                    onPressed: () => openAtelierWord(c, word: word, root: root, img: kNowssbStoreMark),
                    child: const Text('go'),
                  ),
                ),
              );
            }),
          ),
        ),
      ));
      await t.tap(find.byKey(const ValueKey('go')));
      await _settle(t, 14);
    }

    await openWord();
    await _shot(t, '01_word_top_store_mark');
    await _shot(t, 'phone1_ours');

    final list = find.byKey(const ValueKey('store-word-list'));

    Future<void> scrollTo(Key key, {int tries = 8}) async {
      for (var i = 0; i < tries; i++) {
        final f = find.byKey(key);
        if (f.evaluate().isNotEmpty) {
          final box = t.renderObject<RenderBox>(f);
          final origin = box.localToGlobal(Offset.zero);
          if (origin.dy > 20 && origin.dy < 420) return;
          await t.ensureVisible(f);
          await _settle(t, 4);
          return;
        }
        await t.drag(list, const Offset(0, -360));
        await _settle(t, 4);
      }
    }

    // Phone 3: the detail card with the photo hero, star and nested buy card.
    await scrollTo(const ValueKey('word-detail-card'));
    await _shot(t, 'phone3_ours');

    // Stacked practice cards (added styling, word photos).
    await scrollTo(const ValueKey('word-practice-stack'));
    await _shot(t, '02_word_stacked_cards');

    // Phone 2: More in / Popular — title, circles, dark card, carousel.
    await scrollTo(const ValueKey('word-more-title'));
    await _shot(t, 'phone2_ours');

    // Profile mind: Focus today + the two restored rows.
    await t.pumpWidget(const SizedBox());
    await t.pump();
    SharedPreferences.setMockInitialValues({'nwsb_native_sessions': jsonEncode(_seed())});
    await t.runAsync(() => PracticeProgress.instance.start());
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    await t.pumpWidget(RepaintBoundary(
      key: _key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
        home: const ColoredBox(
          color: Colors.black,
          child: Stack(children: [
            Positioned.fill(child: ColoredBox(color: Colors.black)),
            Positioned.fill(child: FaintFilm()),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Material(
                  type: MaterialType.transparency,
                  child: ProfileMind(paletteIndex: 6),
                ),
              ),
            ),
          ]),
        ),
      ),
    ));
    await _settle(t, 10);
    await _shot(t, '03_profile_mind_rows');

    // My progress with the same rows and some practice.
    ProgressCenter.instance.reset();
    ProgressRoutes.goTab = (_, __) {};
    EconomyMirror.instance.summary = const {};
    await DailyTasks.publish();
    final lib = ContentStore.instance.library;
    final now = DateTime.now();
    final s = <String, Map<String, dynamic>>{};
    void add(int daysAgo, int hour, int i, int secs) {
      if (lib.length <= i) return;
      final d = DateTime(now.year, now.month, now.day - daysAgo, hour, 10);
      final k = dayKey(d);
      s['${k}_${lib[i].word}'] = {
        'date': k,
        'word': lib[i].word,
        'completedAt': d.toIso8601String(),
        'durationSec': secs,
      };
    }
    add(0, 7, 0, 240);
    add(0, 19, 1, 180);
    add(1, 9, 2, 300);
    add(2, 21, 3, 200);
    if (s.isEmpty) s.addAll(_seed().cast<String, Map<String, dynamic>>());
    PracticeProgress.instance.debugSetSessionsForTest(s);
    ProgressSources.instance.sync();
    await t.pumpWidget(const SizedBox());
    await t.pump();
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    await t.pumpWidget(RepaintBoundary(
      key: _key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
        builder: (c, child) => Stack(children: [
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          const Positioned.fill(child: FaintFilm()),
          child ?? const SizedBox(),
        ]),
        home: const TodayProgressScreen(),
      ),
    ));
    await _settle(t, 12);
    // Scroll the mind rows into view.
    final rows = find.byKey(const ValueKey('progress-mind-rows'));
    if (rows.evaluate().isNotEmpty) {
      await t.ensureVisible(rows);
      await _settle(t, 6);
    }
    await _shot(t, '04_progress_mind_rows');

    // Also a 360 word-page top, to confirm the store mark still fits.
    await openWord(w: 360, h: 800);
    await _shot(t, '05_word_top_360');

    // Two more words: their own photo, and a no-photo word (default art).
    await openWord(word: 'serenity', root: 'Latin');
    await _shot(t, '06_word_serenity');
    await openWord(word: 'shield', root: 'Old English');
    await _shot(t, '07_word_shield');
  });
}
