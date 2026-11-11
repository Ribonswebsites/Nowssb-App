// The Sound Library "Currently Playing" chip: one glass wrapper, artwork on
// the left, controls on the right, no thinking orb on the play button, real
// player wiring — and the banner film actually opens and plays.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/playback_session.dart';
import 'package:nowssb/media/nwsb_video.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/currently_playing_album.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/widgets/app_thinking_loader.dart';
import 'package:nowssb/widgets/glass_wrap.dart';
import 'package:nowssb/widgets/sound_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

class FakeTransport extends ChangeNotifier implements SlTransport {
  FakeTransport({this.active = false, this.playing = false, this.word});
  @override
  bool active;
  @override
  bool playing;
  @override
  Word? word;
  int toggles = 0, nexts = 0, prevs = 0;

  @override
  Future<void> toggle() async {
    toggles++;
    playing = !playing;
    notifyListeners();
  }

  @override
  Future<void> next() async => nexts++;
  @override
  Future<void> previous() async => prevs++;

  void go(Word w, {required bool play}) {
    active = true;
    word = w;
    playing = play;
    notifyListeners();
  }
}

void main() {
  late List<Word> words;
  late FakeVideoPlatform fake;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(
        {'nwsb_terms_hub': '1', 'nwsb_player_guide_seen': true});
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    fake = FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (c) async => 1);
    await ContentStore.instance
        .start()
        .timeout(const Duration(seconds: 5), onTimeout: () {});
    words = ContentStore.instance.library;
  });

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(390, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  Widget album(List<Word> list, {FakeTransport? p, List<Word>? played}) =>
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CurrentlyPlayingAlbum(
              words: list,
              art: (_) => 'assets/icons/nwsb-coin.webp',
              counts: const {},
              onPlay: (w) => played?.add(w),
              onOpen: (_) {},
            ),
          ),
        ),
      );

  Widget hero(List<Word> list,
          {required FakeTransport p, List<Word>? played}) =>
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CurrentlyPlayingHero(
              words: list,
              art: (_) => 'assets/icons/nwsb-coin.webp',
              onPlay: (w) => played?.add(w),
              onOpen: (_) {},
              onDownload: () {},
              player: p,
            ),
          ),
        ),
      );

  testWidgets('no thinking orb anywhere in the Currently Playing block',
      (t) async {
    phone(t);
    await t.pumpWidget(album(words.take(5).toList()));
    await t.pump();
    expect(find.byType(AppThinkingLoader), findsNothing);
    final toggle = find.byKey(const ValueKey('cp-hero-toggle'));
    expect(toggle, findsOneWidget);
    expect(
        find.descendant(of: toggle, matching: find.byType(AppThinkingLoader)),
        findsNothing);
    expect(find.descendant(of: toggle, matching: find.byType(Icon)),
        findsOneWidget);
  });

  testWidgets('one glass wrapper holds art (left), title, controls (right)',
      (t) async {
    phone(t);
    await t.pumpWidget(album(words.take(5).toList()));
    await t.pump();
    final wrap = find.byKey(const ValueKey('cp-hero'));
    expect(wrap, findsOneWidget);
    expect(t.widget(wrap), isA<GlassWrap>());
    for (final k in [
      'cp-hero-art',
      'cp-hero-title',
      'cp-hero-eyebrow',
      'cp-hero-prev',
      'cp-hero-toggle',
      'cp-hero-next',
      'cp-hero-download',
      'cp-hero-save',
      'cp-hero-chat',
      'cp-hero-more',
    ]) {
      expect(find.descendant(of: wrap, matching: find.byKey(ValueKey(k))),
          findsOneWidget,
          reason: k);
    }
    final art = t.getRect(find.byKey(const ValueKey('cp-hero-art')));
    final title = t.getRect(find.byKey(const ValueKey('cp-hero-title')));
    final toggle = t.getRect(find.byKey(const ValueKey('cp-hero-toggle')));
    expect(art.right, lessThan(title.left), reason: 'artwork is on the left');
    expect(art.right, lessThan(toggle.left));
    final box = t.getRect(wrap);
    expect(box.contains(art.topLeft) && box.contains(toggle.bottomRight), true);
    expect(box.width, lessThanOrEqualTo(390));
  });

  testWidgets('play / pause drives the player; prev / next skip', (t) async {
    phone(t);
    final list = words.take(5).toList();
    final p = FakeTransport(active: true, playing: false, word: list[2]);
    await t.pumpWidget(hero(list, p: p));
    await t.pump();
    String title() =>
        (t.widget(find.byKey(const ValueKey('cp-hero-title'))) as Text).data!;
    String eyebrow() =>
        (t.widget(find.byKey(const ValueKey('cp-hero-eyebrow'))) as Text).data!;
    expect(title(), list[2].word);
    expect(eyebrow(), 'PAUSED');
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('cp-hero-toggle')));
    await t.pump();
    expect(p.toggles, 1);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(eyebrow(), 'NOW PLAYING');

    await t.tap(find.byKey(const ValueKey('cp-hero-next')));
    await t.tap(find.byKey(const ValueKey('cp-hero-prev')));
    await t.tap(find.byKey(const ValueKey('cp-hero-prev')));
    expect((p.nexts, p.prevs), (1, 2));

    // The session moving on to another word is what the card shows.
    p.go(list[3], play: true);
    await t.pump();
    expect(title(), list[3].word);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('with nothing live, play starts the shown word; skip steps',
      (t) async {
    phone(t);
    final list = words.take(4).toList();
    final played = <Word>[];
    final p = FakeTransport();
    await t.pumpWidget(hero(list, p: p, played: played));
    await t.pump();
    String title() =>
        (t.widget(find.byKey(const ValueKey('cp-hero-title'))) as Text).data!;
    expect(title(), list[0].word);
    await t.tap(find.byKey(const ValueKey('cp-hero-next')));
    await t.pump();
    expect(title(), list[1].word);
    await t.tap(find.byKey(const ValueKey('cp-hero-prev')));
    await t.tap(find.byKey(const ValueKey('cp-hero-prev')));
    await t.pump();
    expect(title(), list.last.word, reason: 'wraps round');
    await t.tap(find.byKey(const ValueKey('cp-hero-toggle')));
    expect(played.map((w) => w.word), [list.last.word]);
    expect(p.toggles, 0);
  });

  testWidgets('wired to the real PlaybackSession', (t) async {
    phone(t);
    final list = words.take(4).toList();
    final s = PlaybackSession.instance;
    await t.runAsync(() => s.start(words: list, title: 'Test', autoplay: false));
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CurrentlyPlayingHero(
            words: list,
            art: (_) => 'assets/icons/nwsb-coin.webp',
            onPlay: (_) {},
            onOpen: (_) {},
            onDownload: () {},
          ),
        ),
      ),
    ));
    await t.pump();
    String title() =>
        (t.widget(find.byKey(const ValueKey('cp-hero-title'))) as Text).data!;
    expect(s.active, true);
    final first = s.word!.word;
    expect(title(), first);
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('cp-hero-next')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await t.pump();
    expect(s.word!.word, list[1].word, reason: 'next moved the real session');
    expect(title(), list[1].word);
    await t.runAsync(() async {
      await t.tap(find.byKey(const ValueKey('cp-hero-prev')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await t.pump();
    expect(s.word!.word, first, reason: 'previous moved it back');
    await t.pumpWidget(const SizedBox());
    await t.runAsync(s.dismiss);
  });

  testWidgets('banner film: widget is there, its decoder opens and plays',
      (t) async {
    phone(t);
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {};
    try {
      await t.pumpWidget(
          const MaterialApp(home: SoundLibraryScreen(embedded: true)));
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.tap(find.text('Currently Playing').first);
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
      }
      final banner = find.byKey(const ValueKey('sl-banner-video'));
      expect(banner, findsOneWidget);
      final v = t.widget<NwsbVideo>(banner);
      expect(v.asset, 'assets/video/sound-library-banner.mp4');
      expect(v.autoplay, true);
      expect(v.loop, true);
      expect(v.priority, ClipPriority.feature);
      // Poster fallback sits under the film.
      expect(
          find.descendant(
              of: banner,
              matching: find.byWidgetPredicate((w) =>
                  w is Image &&
                  w.image is AssetImage &&
                  (w.image as AssetImage).assetName ==
                      'assets/video/sound-library-banner-poster.webp')),
          findsOneWidget);
      // The pool granted it a decoder and it is playing.
      final st = VideoPool.instance.debugSnapshot['states']! as Map;
      expect(st['assets/video/sound-library-banner.mp4'], 'playing');
      expect(fake.alive, greaterThan(0));
      // And it is not buried under a heavy dark overlay: the film's own
      // layer is at full opacity once it is ready.
      final fade = t.widget<AnimatedOpacity>(find
          .descendant(of: banner, matching: find.byType(AnimatedOpacity))
          .first);
      expect(fade.opacity, 1);
      // The orb is gone from the hero but the page is otherwise intact.
      expect(find.byKey(const ValueKey('cp-hero')), findsOneWidget);
    } finally {
      FlutterError.onError = prev;
      await t.pumpWidget(const SizedBox());
      VideoPool.instance.debugDropAll();
    }
  });
}
