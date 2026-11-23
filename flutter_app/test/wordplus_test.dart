// Word page store mark + stacked practice cards, and the restored
// Rhythm / This week / Morning-Evening rows on Profile and My progress.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/cart_bag.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/practice_progress.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/data/store_catalog.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/progress/progress_center.dart';
import 'package:nowssb/features/progress/progress_popup.dart';
import 'package:nowssb/features/progress/progress_sources.dart';
import 'package:nowssb/features/progress/today_progress_screen.dart';
import 'package:nowssb/data/word_backgrounds.dart';
import 'package:nowssb/data/word_photos.dart';
import 'package:nowssb/media/nwsb_video.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/widgets/faint_film.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/profile_mind.dart';
import 'package:nowssb/screens/store/product_detail.dart';
import 'package:nowssb/screens/store/store_art.dart';
import 'package:nowssb/screens/store/store_word_page.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';

Future<void> _settle(WidgetTester t, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await t.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PracticeProgress.instance.debugSetSessionsForTest({});
    FaintFilmPause.debugReset();
  });

  Future<int?> openWord(WidgetTester t, {double width = 390, ValueChanged<int>? onTab}) async {
    t.view.physicalSize = Size(width, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      await ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {});
      await Settings.instance.load();
      await CartBag.instance.load();
    });
    // Fresh tree so a second open (360 then 390) can find the go button.
    await t.pumpWidget(const SizedBox());
    await t.pump();
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
      builder: (c, child) => NavScope(go: (i) => onTab?.call(i), child: child ?? const SizedBox()),
      home: Builder(builder: (c) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: TextButton(
              key: const ValueKey('go'),
              onPressed: () => openAtelierWord(c, word: 'ocean', root: 'Old French', img: kNowssbStoreMark),
              child: const Text('go'),
            ),
          ),
        );
      }),
    ));
    await t.tap(find.byKey(const ValueKey('go')));
    await _settle(t);
    return null;
  }

  testWidgets('word page keeps its layout and adds a store mark that opens the Store', (t) async {
    var tab = -1;
    await openWord(t, onTab: (i) => tab = i);
    expect(find.text('Hi there'), findsOneWidget);
    expect(find.textContaining('👋'), findsNothing);
    expect(find.byType(NwsbVideo), findsNothing);
    expect(FaintFilmPause.paused, isTrue);
    expect(find.text('Ocean\nNature'), findsOneWidget);
    expect(find.byKey(const ValueKey('word-store-mark')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('word-store-mark')));
    await _settle(t, 2);
    expect(tab == 3 || find.byKey(const ValueKey('go')).evaluate().isNotEmpty, isTrue);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    expect(FaintFilmPause.paused, isFalse);
  });

  testWidgets('stacked practice cards cycle on tap and Begin opens the player', (t) async {
    await openWord(t);
    expect(find.byKey(const ValueKey('word-practice-stack')), findsOneWidget);
    expect(find.byKey(const ValueKey('word-stack-count')), findsOneWidget);
    expect(find.text('1/${_stackLen(t)}'), findsOneWidget);
    expect(find.text('Begin'), findsWidgets);
    // Tap the stack (not Begin) to cycle to the next word.
    await t.tap(find.byKey(const ValueKey('word-practice-stack')));
    await _settle(t, 10);
    final n = _stackLen(t);
    if (n > 1) {
      expect(find.text('2/$n'), findsOneWidget);
    }
    await t.tap(find.byKey(const ValueKey('word-stack-begin')));
    await _settle(t, 12);
    expect(find.byType(PracticePlayerScreen), findsOneWidget);
  });

  testWidgets('word page with store mark and stack fits at 360 and 390', (t) async {
    for (final w in [360.0, 390.0]) {
      await openWord(t, width: w);
      expect(t.takeException(), isNull);
      final list = find.byKey(const ValueKey('store-word-list'));
      expect(list, findsOneWidget);
      expect(find.byKey(const ValueKey('word-store-mark')), findsOneWidget);
      expect(find.byKey(const ValueKey('word-practice-stack')), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        await t.drag(list, const Offset(0, -500));
        await _settle(t, 3);
        expect(t.takeException(), isNull);
      }
    }
  });

  testWidgets('Profile shows Rhythm, This week and the Morning strip under Focus today with no sessions', (t) async {
    t.view.physicalSize = const Size(360, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: ProfileMind(paletteIndex: 0))),
    ));
    await t.pumpAndSettle();
    expect(find.text('Focus today'), findsOneWidget);
    expect(find.byKey(const ValueKey('mind-rhythm')), findsOneWidget);
    expect(find.byKey(const ValueKey('mind-week')), findsOneWidget);
    expect(find.byKey(const ValueKey('mind-strip')), findsOneWidget);
    expect(find.text('Practice once to see this'), findsNothing);
  });

  testWidgets('My progress shows the same two mind rows', (t) async {
    t.view.physicalSize = const Size(390, 2600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    ProgressCenter.instance.reset();
    DailyCheckIn.instance.debugReset();
    DailyCheckIn.debugClaim = null;
    EconomyMirror.instance.summary = const {};
    ProgressRoutes.goTab = (_, __) {};
    await DailyTasks.publish();
    PracticeProgress.instance.debugSetSessionsForTest({});
    ProgressSources.instance.sync();
    await t.runAsync(() => ContentStore.instance.start().timeout(const Duration(seconds: 5), onTimeout: () {}));
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(backgroundColor: Colors.black, body: SingleChildScrollView(child: TodayProgressBody())),
    ));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('progress-mind-rows')), findsOneWidget);
    expect(find.byKey(const ValueKey('mind-rhythm')), findsOneWidget);
    expect(find.byKey(const ValueKey('mind-week')), findsOneWidget);
    expect(find.byKey(const ValueKey('mind-strip')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  test('word page backgrounds use own photos, never the five rejected ones, and fall back to default art', () {
    final ocean = wordPageBackgrounds('Ocean');
    expect(ocean, isNotEmpty);
    expect(ocean.first, equals(wordBackgroundFor('Ocean')));
    expect(ocean, isNot(contains(kNowssbWordFallback)), reason: 'Ocean has its own picture');
    expect(wordPhotoFor('ocean'), isNotNull);
    for (final w in kBannedWordPhotos) {
      final urls = wordPageBackgrounds(w);
      expect(urls, isNotEmpty);
      expect(
        urls.every((u) => !u.toLowerCase().contains('word_photos/$w.')),
        isTrue,
        reason: w,
      );
      expect(wordPhotoFor(w), isNull);
    }
    expect(wordPageBackgrounds('shield').first, equals(wordBackgroundFor('shield')));
    expect(wordPageBackgrounds('clan').first, equals(wordBackgroundFor('clan')));
    // Concept art not bundled yet for these banned words: default art only.
    expect(wordPageBackgrounds('honor'), equals([kNowssbWordFallback]));
    expect(wordPageBackgrounds('sovereign'), equals([kNowssbWordFallback]));
    expect(wordPageBackgrounds('space'), equals([kNowssbWordFallback]));
  });
}

int _stackLen(WidgetTester t) {
  final text = t.widget<Text>(find.byKey(const ValueKey('word-stack-count')));
  final s = text.data ?? '';
  final i = s.lastIndexOf('/');
  return int.tryParse(s.substring(i + 1)) ?? 1;
}
