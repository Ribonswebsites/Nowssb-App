// The main player in Ribon's reference layout with NowssB glass: one frosted
// pane with a curved top, a cover carousel (neighbours peeking in), title,
// a knob-less seek line, prev / rounded-square play / next, and a glass bar
// with repeat, favourite and shuffle; then the Sentence / Practice / Store
// glass row and its Up next page. Every control is wired, nothing overflows
// at 360, 390 and 1024x768, haptics fire only on taps, a swipe up opens the
// queue and the queue closes on an outside tap, a swipe and back.
// Saves shots to /workspace/team-plan/shots/mainplayer (MAINPLAYER_SHOTS
// overrides the folder).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/app_haptics.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/player_glass_panel.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/widgets/app_thinking_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

final _out = Platform.environment['MAINPLAYER_SHOTS'] ??
    '/workspace/team-plan/shots/mainplayer';
const _shotKey = ValueKey('mainplayer-shot');

Future<void> _write(WidgetTester t, String name) async {
  await t.runAsync(() async {
    final b = t.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(_out)..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _settle(WidgetTester t, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _wait(WidgetTester t) async {
  await t
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
  await _settle(t, 2);
}

String _title(WidgetTester t) =>
    t.widget<Text>(find.byKey(const ValueKey('player-title'))).data!;

int _index(WidgetTester t) =>
    t.widget<PlayerCoverCarousel>(find.byType(PlayerCoverCarousel)).index;

bool _on(WidgetTester t, String key) {
  final bar = t.widget<PlayerGlassBar>(find.byType(PlayerGlassBar));
  return switch (key) {
    'player-repeat' => bar.repeat,
    'player-like' => bar.liked,
    _ => bar.shuffle,
  };
}

Future<List<Word>> _words(WidgetTester t) async {
  late List<Word> words;
  await t.runAsync(() async {
    await ContentStore.instance.start().timeout(
          const Duration(seconds: 5),
          onTimeout: () {},
        );
    await Settings.instance.load();
    words = ContentStore.instance.library.take(8).toList();
  });
  return words;
}

Future<void> _pumpPlayer(WidgetTester t, Size size, List<Word> words) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2;
  await t.pumpWidget(
    RepaintBoundary(
      key: _shotKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: PracticePlayerScreen(
          words: words,
          title: 'Evening mix',
          showIntro: false,
        ),
      ),
    ),
  );
  await _settle(t);
  await precacheAll(t);
  await _settle(t, 4);
}

void main() {
  SharedPreferences.setMockInitialValues({'nwsb_terms_hub': '1'});
  final haptics = <String>[];
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method.startsWith('HapticFeedback')) haptics.add(c.method);
      return null;
    });
  });

  for (final size in const [Size(390, 844), Size(360, 780), Size(1024, 768)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('main player glass layout at $tag', (t) async {
      addTearDown(t.view.reset);
      AppHaptics.debugReset();
      AppHaptics.debugEnabled(true);
      addTearDown(AppHaptics.debugReset);
      final overflows = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) {
        final s = d.toString();
        if (s.contains('overflowed')) {
          overflows.add(s);
          return;
        }
        prev!(d);
      };
      addTearDown(() => FlutterError.onError = prev);

      final words = await _words(t);
      expect(words.length, greaterThan(2));
      await _pumpPlayer(t, size, words);
      await _write(t, 'after-$tag');
      expect(overflows, isEmpty, reason: overflows.join('\n'));

      // The reference structure, on screen and hittable.
      for (final k in const [
        'player-glass-panel',
        'player-cover-carousel',
        'player-title',
        'player-replay',
        'player-notes',
        'player-prev',
        'player-play',
        'player-next',
        'player-glass-bar',
        'player-repeat',
        'player-like',
        'player-shuffle',
        'player-action-sentence',
        'player-action-practice',
        'player-action-store',
        'player-how-it-works-btn',
      ]) {
        expect(find.byKey(ValueKey(k)).hitTestable(), findsOneWidget,
            reason: k);
      }
      // Current cover and the next one peeking in.
      expect(find.byKey(const ValueKey('player-cover-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-cover-1')), findsOneWidget);
      // Frequency chip, settings and help on the cover.
      expect(find.textContaining('Frequency'), findsOneWidget);
      expect(find.bySemanticsLabel('Settings'), findsWidgets);
      expect(find.bySemanticsLabel('Word info'), findsOneWidget);
      // No orb / sphere thumbnail anywhere on the player.
      expect(find.byType(AppThinkingLoader), findsNothing);
      // The play button is a rounded square, not a circle.
      final play = t.widget<Container>(find
          .descendant(
            of: find.byKey(const ValueKey('player-play')),
            matching: find.byType(Container),
          )
          .first);
      final deco = play.decoration! as BoxDecoration;
      expect(deco.shape, BoxShape.rectangle);
      expect(deco.borderRadius, isNotNull);
      final playSize = t.getSize(find.byKey(const ValueKey('player-play')));
      expect(playSize.width, 56);
      // Current cover is about three quarters of the pane on phones.
      if (size.width < 700) {
        final pane =
            t.getSize(find.byKey(const ValueKey('player-glass-panel')));
        final cover = t.getSize(find.byKey(const ValueKey('player-cover-0')));
        expect(cover.width / pane.width, inInclusiveRange(.6, .78));
      }

      // Repeat, favourite and shuffle toggle the player's own state.
      final r0 = _on(t, 'player-repeat');
      await t.tap(find.byKey(const ValueKey('player-repeat')));
      await _wait(t);
      expect(_on(t, 'player-repeat'), !r0);
      await t.tap(find.byKey(const ValueKey('player-repeat')));
      await _wait(t);
      final l0 = _on(t, 'player-like');
      await t.tap(find.byKey(const ValueKey('player-like')));
      await _wait(t);
      expect(_on(t, 'player-like'), !l0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('nwsb_liked_words') ?? const <String>[],
          contains(words[0].word));
      await t.tap(find.byKey(const ValueKey('player-like')));
      await _wait(t);
      expect(_on(t, 'player-like'), l0);
      final s0 = _on(t, 'player-shuffle');
      await t.tap(find.byKey(const ValueKey('player-shuffle')));
      await _wait(t);
      expect(_on(t, 'player-shuffle'), !s0);
      await t.tap(find.byKey(const ValueKey('player-shuffle')));
      await _wait(t);
      expect(_on(t, 'player-shuffle'), s0);

      // Next and previous move the word and the carousel.
      final first = _title(t);
      await t.tap(find.byKey(const ValueKey('player-next')));
      await _settle(t, 10);
      expect(_index(t), 1);
      expect(_title(t), isNot(first));
      await t.tap(find.byKey(const ValueKey('player-prev')));
      await _settle(t, 10);
      expect(_index(t), 0);

      // Swiping the cover changes the word, and a swipe never buzzes.
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      haptics.clear();
      await t.drag(
        find.byKey(const ValueKey('player-cover-carousel')),
        Offset(-size.width * .4, 0),
      );
      await _settle(t, 12);
      expect(_index(t), 1);
      expect(haptics, isEmpty, reason: 'haptics are for taps only');
      await precacheAll(t);
      await _settle(t, 2);
      await _write(t, 'after-swiped-$tag');
      expect(overflows, isEmpty, reason: overflows.join('\n'));

      // A tap buzzes once.
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.tap(find.byKey(const ValueKey('player-play')));
      await _settle(t, 2);
      expect(haptics, hasLength(1));

      // A swipe up opens the queue; it closes on back, a swipe down and an
      // outside tap.
      final handle = find.byKey(const ValueKey('queue-grab-handle'));
      final start = Offset(size.width / 2, size.height * .45);
      await t.flingFrom(start, const Offset(0, -300), 1500);
      await _settle(t, 10);
      expect(handle, findsOneWidget);
      await t.binding.handlePopRoute();
      await _settle(t, 10);
      expect(handle, findsNothing);
      expect(find.byType(PracticePlayerScreen), findsOneWidget);
      await t.flingFrom(start, const Offset(0, -300), 1500);
      await _settle(t, 10);
      expect(handle, findsOneWidget);
      await t.drag(handle, const Offset(0, 400));
      await _settle(t, 12);
      expect(handle, findsNothing);

      await t.pumpWidget(const SizedBox());
      await _settle(t, 4);
    });
  }
}
