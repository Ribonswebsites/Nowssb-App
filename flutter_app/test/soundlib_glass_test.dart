// The Sound Library's glass layouts: nothing is removed, taps play / open the
// real item, and the now-playing card drives the real player state.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/content.dart';
import 'package:nowssb/data/models.dart';
import 'package:nowssb/data/playback_session.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/practice_player.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/widgets/sound_glass.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';
import 'support/test_fonts.dart';

class FakePlayer extends ChangeNotifier implements SlPlayer {
  FakePlayer({this.active = false, this.playing = false, this.word});
  @override
  bool active;
  @override
  bool playing;
  @override
  Word? word;
  int toggles = 0;

  @override
  Future<void> toggle() async {
    toggles++;
    playing = !playing;
    notifyListeners();
  }

  void go(Word w, {required bool play}) {
    active = true;
    word = w;
    playing = play;
    notifyListeners();
  }
}

List<SlPick> _picks(List<Word> words) => [
      for (var i = 0; i < words.length; i++)
        SlPick(
            word: words[i],
            art: SoundArtPool.tiles[i % SoundArtPool.tiles.length]),
    ];

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
      ),
    );

void main() {
  late List<Word> words;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(
        {'nwsb_terms_hub': '1', 'nwsb_player_guide_seen': true});
    await setUpHomeRender();
    await loadRoboto();
    await setUpOfflineGoogleFonts();
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (c) async => 1);
    await ContentStore.instance
        .start()
        .timeout(const Duration(seconds: 5), onTimeout: () {});
    words = ContentStore.instance.library;
  });

  test('fixture has words to lay out',
      () => expect(words.length, greaterThanOrEqualTo(9)));

  group('GlassQuickGrid (A)', () {
    testWidgets('every pick is reachable: 8 on page one, the rest on the next',
        (t) async {
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final list = words.take(12).toList();
      final played = <String>[];
      await t.pumpWidget(_host(GlassQuickGrid(
        picks: _picks(list),
        onPlay: (w) => played.add(w.word),
        player: FakePlayer(),
      )));
      await t.pump();
      expect(find.byKey(const ValueKey('sl-quick-pages-')), findsOneWidget);
      final seen = <String>{};
      List<String> visible() => [
            for (final w in list)
              if (find
                  .byKey(ValueKey('sl-quick-${w.word}'))
                  .evaluate()
                  .isNotEmpty)
                w.word
          ];
      expect(visible().length, 8);
      seen.addAll(visible());
      await t.drag(
          find.byKey(const ValueKey('sl-quick-pages-')), const Offset(-400, 0));
      await t.pumpAndSettle();
      seen.addAll(visible());
      expect(seen, list.map((w) => w.word).toSet(), reason: 'no pick lost');
      // A tap plays that word.
      await t.tap(find.byKey(ValueKey('sl-quick-${list[9].word}')));
      expect(played, [list[9].word]);
    });

    testWidgets(
        'filter chips only narrow while selected; All brings everything back',
        (t) async {
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final list = words.take(12).toList();
      final practised = {list[0].word, list[1].word};
      await t.pumpWidget(_host(GlassQuickGrid(
        picks: _picks(list),
        onPlay: (_) {},
        chips: const ['All', 'Practised', 'New'],
        matches: (chip, p) => chip == 'Practised'
            ? practised.contains(p.word.word)
            : !practised.contains(p.word.word),
        player: FakePlayer(),
      )));
      int shown() => [
            for (final w in list)
              if (find
                  .byKey(ValueKey('sl-quick-${w.word}'))
                  .evaluate()
                  .isNotEmpty)
                w
          ].length;
      expect(shown(), 8);
      await t.tap(find.byKey(const ValueKey('sl-chip-Practised')));
      await t.pumpAndSettle();
      expect(shown(), 2);
      await t.tap(find.byKey(const ValueKey('sl-chip-All')));
      await t.pumpAndSettle();
      expect(shown(), 8);
    });

    testWidgets('long-press opens the word', (t) async {
      final opened = <String>[];
      await t.pumpWidget(_host(GlassQuickGrid(
        picks: _picks(words.take(4).toList()),
        onPlay: (_) {},
        onOpen: (w) => opened.add(w.word),
        player: FakePlayer(),
      )));
      await t.longPress(find.byKey(ValueKey('sl-quick-${words[2].word}')));
      expect(opened, [words[2].word]);
    });
  });

  group('GlassNowPlayingGrid (B)', () {
    testWidgets(
        'all tiles show; nothing playing → suggested track; play starts it',
        (t) async {
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final list = words.take(12).toList();
      final played = <String>[];
      await t.pumpWidget(_host(GlassNowPlayingGrid(
        picks: _picks(list),
        onPlay: (w) => played.add(w.word),
        headerArt: (_) => SoundArtPool.tiles.last,
        player: FakePlayer(),
      )));
      await t.pump();
      for (final w in list) {
        expect(find.byKey(ValueKey('sl-tile-${w.word}')), findsOneWidget,
            reason: w.word);
      }
      expect(find.byKey(const ValueKey('sl-np-label')).evaluate().length, 1);
      expect((t.widget(find.byKey(const ValueKey('sl-np-label'))) as Text).data,
          'SUGGESTED FOR YOU');
      expect((t.widget(find.byKey(const ValueKey('sl-np-title'))) as Text).data,
          list.first.word);
      // The round button starts the suggested track.
      await t.tap(find.byKey(const ValueKey('sl-np-toggle')));
      expect(played, [list.first.word]);
      // A tile plays its own word.
      await t.tap(find.byKey(ValueKey('sl-tile-${list[5].word}')));
      expect(played.last, list[5].word);
    });

    testWidgets('last played is shown when nothing is live', (t) async {
      final list = words.take(6).toList();
      await t.pumpWidget(_host(GlassNowPlayingGrid(
        picks: _picks(list),
        lastPlayed: list[3],
        onPlay: (_) {},
        headerArt: (_) => SoundArtPool.tiles.last,
        player: FakePlayer(),
      )));
      expect((t.widget(find.byKey(const ValueKey('sl-np-label'))) as Text).data,
          'LAST PLAYED');
      expect((t.widget(find.byKey(const ValueKey('sl-np-title'))) as Text).data,
          list[3].word);
    });

    testWidgets('pause and play drive the real player state', (t) async {
      final list = words.take(6).toList();
      final p = FakePlayer()..go(list[2], play: true);
      final played = <String>[];
      await t.pumpWidget(_host(GlassNowPlayingGrid(
        picks: _picks(list),
        lastPlayed: list[0],
        onPlay: (w) => played.add(w.word),
        headerArt: (_) => SoundArtPool.tiles.last,
        player: p,
      )));
      await t.pump();
      String label() =>
          (t.widget(find.byKey(const ValueKey('sl-np-label'))) as Text).data!;
      expect(label(), 'NOW PLAYING');
      expect((t.widget(find.byKey(const ValueKey('sl-np-title'))) as Text).data,
          list[2].word);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      // Pause.
      await t.tap(find.byKey(const ValueKey('sl-np-toggle')));
      await t.pump();
      expect(p.toggles, 1);
      expect(p.playing, isFalse);
      expect(label(), 'PAUSED');
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      // Play again — resumes the live session, does not reopen the player.
      await t.tap(find.byKey(const ValueKey('sl-np-toggle')));
      await t.pump();
      expect(p.toggles, 2);
      expect(p.playing, isTrue);
      expect(label(), 'NOW PLAYING');
      expect(played, isEmpty);
      // The tile of the live word is marked.
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
      // Dispose the looping progress bar.
      await t.pumpWidget(const SizedBox());
    });
  });

  testWidgets('the real PlaybackSession drives the now-playing header',
      (t) async {
    final list = words.take(6).toList();
    String label() =>
        (t.widget(find.byKey(const ValueKey('sl-np-label'))) as Text).data!;
    String title() =>
        (t.widget(find.byKey(const ValueKey('sl-np-title'))) as Text).data!;
    await t.pumpWidget(_host(GlassNowPlayingGrid(
      picks: _picks(list),
      onPlay: (_) {},
      headerArt: (_) => SoundArtPool.tiles.last,
    )));
    expect(label(), 'SUGGESTED FOR YOU');
    // A session that exists but is not sounding shows as paused.
    await t.runAsync(() => PlaybackSession.instance
        .start(words: [list[4]], title: 'x', autoplay: false));
    await t.pump();
    expect(label(), 'PAUSED');
    expect(title(), list[4].word);
    expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
    await t.runAsync(() => PlaybackSession.instance.dismiss());
    await t.pump();
    expect(label(), 'SUGGESTED FOR YOU');
  });

  group('GlassStationRow (C)', () {
    testWidgets('every station is there and opens its page', (t) async {
      t.view.physicalSize = const Size(390, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final opened = <String>[];
      final held = <String>[];
      final ids = ['Calm', 'Focus', 'Sleep', 'Heal', 'Breath', 'Joy'];
      await t.pumpWidget(_host(GlassStationRow(stations: [
        for (final id in ids)
          SlStation(
            id: id,
            title: id,
            subtitle: '3 words · A, B, C',
            avatars: SoundArtPool.avatars.take(3).toList(),
            onTap: () => opened.add(id),
            onLongPress: () => held.add(id),
          ),
      ])));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('sl-station-Calm')));
      await t.longPress(find.byKey(const ValueKey('sl-station-Focus')));
      expect(opened, ['Calm']);
      expect(held, ['Focus']);
      // Scrolling the rail reaches the last one.
      await t.drag(find.byType(ListView), const Offset(-2000, 0));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('sl-station-Joy')), findsOneWidget);
    });
  });

  group('art ledger', () {
    test('hands out each picture once while the pool lasts', () {
      final l = SoundArtLedger();
      final got = [
        for (var i = 0; i < SoundArtPool.tiles.length; i++) l.pick('w$i')
      ];
      expect(got.toSet().length, got.length);
      final av = [
        for (var i = 0; i < SoundArtPool.avatars.length; i++)
          l.pick('a$i', avatar: true)
      ];
      expect(av.toSet().length, av.length);
      expect(l.pick('w0'), got.first, reason: 'same seed, same picture');
    });
    test('no red-haired or Cleopatra plates in the pool', () {
      const banned = [
        'card-02',
        'card-03',
        'card-04',
        'card-09',
        'card-13',
        'card-20',
        'cleo'
      ];
      for (final a in [...SoundArtPool.tiles, ...SoundArtPool.avatars]) {
        for (final b in banned) {
          expect(a.contains(b), isFalse, reason: a);
        }
      }
    });
  });

  group('Sound Library screen: nothing removed', () {
    testWidgets(
        'every word, category and old section is still on the page; taps open the real player',
        (t) async {
      t.view.physicalSize = const Size(390, 6400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      // The test font is wider than the real one, so older sections overflow
      // here; collect layout errors and fail only on ones from the glass code.
      final errs = <FlutterErrorDetails>[];
      final prev = FlutterError.onError;
      FlutterError.onError = errs.add;
      try {
        await t.pumpWidget(
            const MaterialApp(home: SoundLibraryScreen(embedded: true)));
        for (var i = 0; i < 12; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        final all = ContentStore.instance.library;
        final top12 = all.take(12).toList();

        // Trending tile grid: one tile per word, as before one row per word.
        for (final w in top12) {
          expect(find.byKey(ValueKey('sl-tile-${w.word}')), findsOneWidget,
              reason: 'trending ${w.word}');
        }
        // Quick picks: the first page is on screen, the rest are one swipe away.
        final quickOnPage = top12
            .where((w) => find
                .byKey(ValueKey('sl-quick-${w.word}'))
                .evaluate()
                .isNotEmpty)
            .length;
        expect(quickOnPage, 8);
        await t.drag(find.byKey(const ValueKey('sl-quick-pages-')),
            const Offset(-400, 0));
        for (var i = 0; i < 8; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        final quickAll = top12
            .where((w) => find
                .byKey(ValueKey('sl-quick-${w.word}'))
                .evaluate()
                .isNotEmpty)
            .length;
        expect(quickAll, top12.length - 8);

        // Browse by category: one station per category (the old rail capped at 10).
        final cats = <String>{for (final w in all) ...w.categories};
        // The rail builds lazily; swipe along it and collect what appears.
        final seenStations = <String>{};
        void collect() {
          for (final c in cats) {
            if (find.byKey(ValueKey('sl-station-$c')).evaluate().isNotEmpty)
              seenStations.add(c);
          }
        }

        final rail =
            find.byKey(ValueKey('sl-station-${(cats.toList()..sort()).first}'));
        await t.ensureVisible(rail);
        collect();
        for (var i = 0;
            i < cats.length && seenStations.length < cats.length;
            i++) {
          await t.drag(
              rail.hitTestable().evaluate().isNotEmpty
                  ? rail
                  : find.byType(GlassStationRow),
              const Offset(-170, 0));
          for (var k = 0; k < 4; k++) {
            await t.pump(const Duration(milliseconds: 100));
          }
          collect();
        }
        expect(seenStations, cats, reason: 'every category has a station card');

        // Every other section is still there.
        for (final title in [
          'Quick picks',
          'Trending songs for you',
          'Browse by category',
          'Your sentences',
          'Collections',
          "Today's Global Hits",
          'Listen again',
        ]) {
          expect(find.text(title), findsWidgets, reason: title);
        }

        // Tap a tile → the real player opens on that word.
        await t.ensureVisible(find.byKey(ValueKey('sl-tile-${top12[4].word}')));
        await t.tap(find.byKey(ValueKey('sl-tile-${top12[4].word}')));
        for (var k = 0; k < 6; k++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(PracticePlayerScreen), findsOneWidget);
        final player =
            t.widget<PracticePlayerScreen>(find.byType(PracticePlayerScreen));
        expect(player.words.map((w) => w.word), [top12[4].word]);
        await t.pumpWidget(const SizedBox());
      } finally {
        FlutterError.onError = prev;
      }
      final mine = errs
          .where((d) =>
              '${d.stack}'.contains('sound_glass') ||
              '${d.exception}'.contains('sound_glass'))
          .toList();
      expect(mine, isEmpty,
          reason: mine.map((d) => d.exceptionAsString()).join('\n'));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
