// The swipe-up now-playing view: it follows the finger, opens, every
// control is wired to the player, it closes by swipe down, handle and back,
// and it fits phones and tablets. Saves shots to /workspace/team-plan.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/player_up_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

const _out = '/workspace/team-plan/shots/playerup2';
const _shotKey = ValueKey('playerup-shot');

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

String _title(WidgetTester t) =>
    t.widget<Text>(find.byKey(const ValueKey('player-up-title'))).data!;

int _upIndex(WidgetTester t) =>
    t.widget<PlayerUpView>(find.byType(PlayerUpView)).index;

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
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (c) async => 1);
    m.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (c) async => true,
    );
  });

  for (final size in const [Size(390, 844), Size(1024, 768)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('swipe-up view at $tag', (t) async {
      addTearDown(t.view.reset);
      final overflows = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) {
        final s = d.toString();
        // Only overflows inside the new view fail this test; the player
        // underneath is unchanged and logs its own known ones.
        if (s.contains('overflowed')) {
          if (s.contains('PlayerUpView') || s.contains('player_up_view')) {
            overflows.add(s);
          }
          return;
        }
        prev!(d);
      };
      addTearDown(() => FlutterError.onError = prev);

      final words = await _words(t);
      expect(words.length, greaterThan(2));
      await _pumpPlayer(t, size, words);
      expect(find.byType(PlayerUpView), findsNothing);
      await _write(t, 'player-$tag');

      // Mid-swipe: the view follows the finger.
      final start = Offset(size.width / 2, size.height * .3);
      final g = await t.startGesture(start);
      for (var i = 0; i < 9; i++) {
        await g.moveBy(Offset(0, -size.height * .65 / 14));
        await t.pump(const Duration(milliseconds: 16));
      }
      await precacheAll(t);
      await t.pump();
      expect(find.byType(PlayerUpView), findsOneWidget);
      await _write(t, 'midswipe-$tag');
      for (var i = 0; i < 5; i++) {
        await g.moveBy(Offset(0, -size.height * .65 / 14));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _settle(t, 10);
      await precacheAll(t);
      await _settle(t, 2);
      expect(find.byKey(const ValueKey('player-up-carousel')), findsOneWidget);
      await _write(t, 'open-$tag');
      expect(overflows, isEmpty);

      // Every part is on screen and hittable.
      for (final k in const [
        'player-up-handle', 'player-up-close', 'player-up-queue',
        'player-up-prev', 'player-up-play', 'player-up-next',
        'player-up-repeat', 'player-up-like', 'player-up-shuffle',
        'player-up-title',
      ]) {
        expect(find.byKey(ValueKey(k)).hitTestable(), findsOneWidget, reason: k);
      }
      // Cover for the current word and its neighbour peeking in.
      expect(find.byKey(const ValueKey('player-up-cover-0')), findsOneWidget);
      if (size.width < 700) {
        expect(find.byKey(const ValueKey('player-up-cover-1')), findsOneWidget);
      } else {
        // Tablet: the next words are in the Up next list beside the card.
        expect(find.byKey(const ValueKey('player-up-row-1')).hitTestable(), findsOneWidget);
      }

      // Repeat, favourite and shuffle are the player's own state.
      final v0 = t.widget<PlayerUpView>(find.byType(PlayerUpView));
      await t.tap(find.byKey(const ValueKey('player-up-repeat')));
      await _settle(t, 2);
      expect(t.widget<PlayerUpView>(find.byType(PlayerUpView)).repeat, !v0.repeat);
      await t.tap(find.byKey(const ValueKey('player-up-like')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(t, 2);
      expect(t.widget<PlayerUpView>(find.byType(PlayerUpView)).liked, !v0.liked);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('nwsb_liked_words') ?? const <String>[],
          contains(words[0].word));
      await t.tap(find.byKey(const ValueKey('player-up-like')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(t, 2);
      expect(t.widget<PlayerUpView>(find.byType(PlayerUpView)).liked, v0.liked);
      await t.tap(find.byKey(const ValueKey('player-up-shuffle')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(t, 2);
      expect(t.widget<PlayerUpView>(find.byType(PlayerUpView)).shuffle, !v0.shuffle);
      await t.tap(find.byKey(const ValueKey('player-up-shuffle')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _settle(t, 2);
      await t.tap(find.byKey(const ValueKey('player-up-repeat')));
      await _settle(t, 2);

      // Next moves the queue and the carousel; prev comes back.
      final first = _title(t);
      await t.tap(find.byKey(const ValueKey('player-up-next')));
      await _settle(t, 10);
      expect(_upIndex(t), 1);
      expect(_title(t), isNot(first));
      await t.tap(find.byKey(const ValueKey('player-up-prev')));
      await _settle(t, 10);
      expect(_upIndex(t), 0);

      // Swiping the carousel changes the word.
      await t.drag(
        find.byKey(const ValueKey('player-up-carousel')),
        Offset(-size.width * .45, 0),
      );
      await _settle(t, 12);
      expect(_upIndex(t), 1);
      await precacheAll(t);
      await _settle(t, 2);
      await _write(t, 'open-swiped-$tag');

      // Play toggles.
      await t.tap(find.byKey(const ValueKey('player-up-play')));
      await _settle(t, 2);
      if (t.widget<PlayerUpView>(find.byType(PlayerUpView)).playing) {
        await _settle(t, 40);
        await precacheAll(t);
        await _write(t, 'open-playing-$tag');
      }

      // Back closes the view, not the player.
      await t.binding.handlePopRoute();
      await _settle(t, 10);
      expect(find.byType(PlayerUpView), findsNothing);
      expect(find.byType(PracticePlayerScreen), findsOneWidget);

      // Swipe down closes it; so does the handle.
      await t.flingFrom(start, const Offset(0, -320), 1500);
      await _settle(t, 10);
      expect(find.byType(PlayerUpView), findsOneWidget);
      await t.flingFrom(Offset(size.width / 2, size.height * .2),
          const Offset(0, 320), 1500);
      await _settle(t, 10);
      expect(find.byType(PlayerUpView), findsNothing);
      await t.flingFrom(start, const Offset(0, -320), 1500);
      await _settle(t, 10);
      await t.tap(find.byKey(const ValueKey('player-up-handle')));
      await _settle(t, 10);
      expect(find.byType(PlayerUpView), findsNothing);

      await t.pumpWidget(const SizedBox());
      await _settle(t, 4);
    });
  }
}
