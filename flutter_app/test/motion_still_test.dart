/// Zen Plus motion (Settings.fashionPlus) freezes only page BACKGROUND films.
///
/// Still: a backdrop (AppBackdrop, FaintFilm, PageShell, Profile, the Zen
/// home) takes no decoder and its poster stays up. Moving: it plays again,
/// live. Every other clip — pop-ups, banners, cards, tiles, the player —
/// keeps playing in Still. The preference is the one Settings persists.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/data/settings.dart';
import 'package:nowssb/media/nwsb_video.dart';
import 'package:nowssb/media/quote_film.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:nowssb/screens/quotes_live.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/app_backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';

const _bg = 'assets/video/subscription-bg.mp4';
const _poster = 'assets/video/subscription-bg-poster.webp';

bool _leased(String asset) =>
    VideoPool.instance.debugLeases.any((l) => l.assetPath == asset);

int _leaseCountFor(String asset) =>
    VideoPool.instance.debugLeases.where((l) => l.assetPath == asset).length;

void _noop(int _) {}

Future<void> _shot(WidgetTester t, GlobalKey key, String path) async {
  try {
    await t.runAsync(() async {
      final box =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (box == null) return;
      final img = await box.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      File(path)
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(bytes.buffer.asUint8List());
    });
  } catch (_) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVideoPlatform platform;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    platform = FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Settings.instance.load();
    await Settings.instance.setFashionPlus(true);
    VideoPool.instance.debugDropAll();
    platform.reset();
  });

  tearDown(VideoPool.instance.debugDropAll);

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  Future<void> sizePhone(WidgetTester t) async {
    t.view.physicalSize = const Size(412 * 3, 900 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  Future<void> pumpClip(
    WidgetTester t, {
    bool obeyMotion = true,
    String asset = _bg,
    bool? explicit,
  }) async {
    await sizePhone(t);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 412,
            height: 900,
            child: explicit == false
                // No flag at all: the default every content clip uses.
                ? NwsbVideo(
                    asset: asset,
                    priority: ClipPriority.feature,
                    autoplay: true,
                    loop: true,
                  )
                : NwsbVideo(
                    asset: asset,
                    priority: ClipPriority.feature,
                    autoplay: true,
                    loop: true,
                    obeyMotion: obeyMotion,
                  ),
          ),
        ),
      ),
    );
    await settle(t);
  }

  Future<void> pumpZen(WidgetTester t) async {
    await sizePhone(t);
    await t.pumpWidget(
      MaterialApp(
        home: NavScope(go: (_) {}, child: const HomeFashion()),
      ),
    );
    await settle(t);
  }

  Future<void> pumpProfile(WidgetTester t) async {
    await sizePhone(t);
    await t.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await settle(t);
  }

  testWidgets('Still does not start a background NwsbVideo; Moving does',
      (t) async {
    await Settings.instance.setFashionPlus(false);
    await pumpClip(t);
    expect(_leased(_bg), isFalse);
    expect(VideoPool.instance.leaseCount, 0);

    await Settings.instance.setFashionPlus(true);
    await settle(t);
    expect(_leased(_bg), isTrue);

    await Settings.instance.setFashionPlus(false);
    await settle(t);
    expect(_leased(_bg), isFalse);
    expect(VideoPool.instance.leaseCount, 0);
  });

  testWidgets('user-started media still plays while motion is Still',
      (t) async {
    await Settings.instance.setFashionPlus(false);
    await pumpClip(t, obeyMotion: false, asset: 'assets/video/word-film.mp4');
    expect(_leased('assets/video/word-film.mp4'), isTrue);
  });

  testWidgets('content clips (pop-up, banner) default to playing in Still',
      (t) async {
    await Settings.instance.setFashionPlus(false);
    await pumpClip(t,
        explicit: false, asset: 'assets/video/sound-library-banner.mp4');
    expect(_leased('assets/video/sound-library-banner.mp4'), isTrue,
        reason: 'a section banner is not a background and keeps playing');
  });

  testWidgets('Quote pop-up film plays in Still while the backdrop is paused',
      (t) async {
    await Settings.instance.setFashionPlus(false);
    await QuoteFilm.debugReset();
    await sizePhone(t);
    late BuildContext ctx;
    await t.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: AppBackdrop());
      }),
    ));
    await settle(t);
    expect(_leaseCountFor(_bg), 0, reason: 'backdrop is paused in Still');

    showTodayQuote(ctx);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 60));
    }
    final c = QuoteFilm.controller.value;
    expect(c, isNotNull);
    expect(c!.value.isInitialized, isTrue);
    expect(platform.playing, isNotEmpty,
        reason: 'the pop-up wave keeps playing in Still');
    expect(_leaseCountFor(_bg), 0);
    await t.tap(find.byKey(const ValueKey('daily-quote-close')));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 60));
    }
    await QuoteFilm.debugReset();
  });

  testWidgets('Zen home background pauses on Still and resumes on Moving',
      (t) async {
    await pumpZen(t);
    expect(find.byType(AppBackdrop), findsWidgets);
    expect(_leaseCountFor(_bg), greaterThan(0));

    await Settings.instance.setFashionPlus(false);
    await settle(t);
    expect(_leaseCountFor(_bg), 0,
        reason: 'Zen home film must drop its decoder when motion is Still');

    await Settings.instance.setFashionPlus(true);
    await settle(t);
    expect(_leaseCountFor(_bg), greaterThan(0),
        reason: 'switching back to Moving must start the Zen home film again');
  });

  testWidgets('Zen home opened in Still never starts the background film',
      (t) async {
    await Settings.instance.setFashionPlus(false);
    final key = GlobalKey();
    await sizePhone(t);
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: NavScope(go: _noop, child: HomeFashion()),
        ),
      ),
    );
    await settle(t);
    expect(_leaseCountFor(_bg), 0);
    await _shot(t, key, '/workspace/tm-motionstop/shots/zen-home-still.png');
  });

  testWidgets('Profile backdrop pauses on Still and resumes on Moving',
      (t) async {
    await pumpProfile(t);
    expect(find.byType(NwsbVideo), findsWidgets);
    expect(_leaseCountFor(_bg), greaterThan(0));

    await Settings.instance.setFashionPlus(false);
    await settle(t);
    expect(_leaseCountFor(_bg), 0);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == _poster,
      ),
      findsWidgets,
    );

    await Settings.instance.setFashionPlus(true);
    await settle(t);
    expect(_leaseCountFor(_bg), greaterThan(0));
  });

  testWidgets('Still survives a Settings reload as a fresh launch would',
      (t) async {
    await Settings.instance.setFashionPlus(false);
    await Settings.instance.load();
    expect(Settings.instance.fashionPlus, isFalse);

    await pumpZen(t);
    expect(_leaseCountFor(_bg), 0);
  });
}
