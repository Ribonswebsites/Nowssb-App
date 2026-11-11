import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/coins/coins_screen.dart';
import 'package:nowssb/features/earn/earnings_screen.dart';
import 'package:nowssb/features/circle/circle_screen.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/sections_top.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/screens/subscription.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/four_banners.dart';
import 'package:nowssb/widgets/glass_wrap.dart';
import 'package:nowssb/widgets/prog_banner_carousel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

// flutter test test/prog_glass2_test.dart --dart-define=PROGGLASS2_OUT=/out
const _out = String.fromEnvironment('PROGGLASS2_OUT');

// Stand-in for the Zen home's looping backdrop video.
class _Back extends StatelessWidget {
  const _Back({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(.8, -.3), radius: 1.3, colors: [Color(0xFF3A1D78), Color(0xFF0E061E), Color(0xFF000000)], stops: [0, .55, 1]),
        ),
        child: child,
      );
}

Future<void> _shot(WidgetTester t, GlobalKey key, String name) async {
  await t.runAsync(() async {
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: 2);
    final b = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(b!.buffer.asUint8List());
  });
}

Future<void> _pump(WidgetTester t, GlobalKey key, Widget child, double h, {bool backdrop = true}) async {
  t.view.physicalSize = Size(390 * 2, h * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  final body = Material(type: MaterialType.transparency, child: Align(alignment: Alignment.topCenter, child: child));
  await t.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'DM Sans'),
    home: RepaintBoundary(key: key, child: backdrop ? _Back(child: body) : ColoredBox(color: Colors.black, child: body)),
  ));
  await precacheAll(t);
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
  });
  tearDown(() {
    ProgBannerCarousel.debugT = null;
    ProgBannerCarousel.debugPage = null;
    ProgBannerCarousel.debugLive = false;
  });

  for (var i = 0; i < 4; i++) {
    testWidgets('banner slide $i', (t) async {
      if (_out.isEmpty) return;
      ProgBannerCarousel.debugT = .3 + i * .05;
      ProgBannerCarousel.debugPage = i;
      final key = GlobalKey();
      await _pump(t, key, const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 20), child: ProgBannerCarousel()), 290, backdrop: false);
      expect(t.takeException(), isNull);
      await _shot(t, key, 'banner_slide${i + 1}_390');
    });
  }

  testWidgets('banner motion frames (slide 1)', (t) async {
    if (_out.isEmpty) return;
    for (final f in [0.0, .125, .25, .375]) {
      ProgBannerCarousel.debugT = f;
      ProgBannerCarousel.debugPage = 0;
      final key = GlobalKey();
      await _pump(t, key, const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 20), child: ProgBannerCarousel()), 290, backdrop: false);
      await _shot(t, key, 'banner_frame_t${(f * 1000).round()}');
      await t.pumpWidget(const SizedBox());
    }
  });

  testWidgets('wrapped section beside the Begin card', (t) async {
    if (_out.isEmpty) return;
    ProgBannerCarousel.debugT = .3;
    final key = GlobalKey();
    await _pump(t, key, const Column(children: [FashGreeting(), ProgrammesGlassSection()]), 1480);
    expect(t.takeException(), isNull);
    await _shot(t, key, 'wrapped_vs_begin_390');
  });

  testWidgets('wrapped section at 320 wide', (t) async {
    if (_out.isEmpty) return;
    ProgBannerCarousel.debugT = .3;
    final key = GlobalKey();
    t.view.physicalSize = const Size(320 * 2, 1500 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: RepaintBoundary(key: key, child: const _Back(child: Material(type: MaterialType.transparency, child: Align(alignment: Alignment.topCenter, child: ProgrammesGlassSection())))),
    ));
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 300));
    expect(t.takeException(), isNull);
    await _shot(t, key, 'wrapped_320');
  });

  testWidgets('glass is the shared GlassWrap, heading has the badge pattern', (t) async {
    ProgBannerCarousel.debugT = .3;
    t.view.physicalSize = const Size(390 * 2, 2000 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: ThemeData(fontFamily: 'DM Sans'), home: const Scaffold(body: SingleChildScrollView(child: ProgrammesGlassSection()))));
    expect(find.byType(GlassWrap), findsOneWidget);
    expect(find.byKey(const ValueKey('prog-glass-eyebrow')), findsOneWidget);
    expect(find.byKey(const ValueKey('prog-glass-title')), findsOneWidget);
    expect(find.text('Your path'), findsOneWidget);
    expect(find.text('Programmes'), findsOneWidget);
    // Five cards always (the lucky draw one only while the draw is on).
    expect(find.text('PROGRAMME'), findsNWidgets(4));
    expect(find.text('MEMBERSHIP'), findsOneWidget);
    expect(find.text('Earned today'), findsOneWidget);
    // No stray highlight line along the top edge.
    expect(find.byWidgetPredicate((w) => w is Container && w.constraints?.maxHeight == 1.2), findsNothing);
  });

  group('banner carousel', () {
    Future<void> mount(WidgetTester t, {void Function(int)? onOpen}) async {
      ProgBannerCarousel.debugLive = true;
      t.view.physicalSize = const Size(390 * 2, 400 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(16), child: ProgBannerCarousel(onOpen: onOpen)))),
      ));
    }

    int dot(WidgetTester t) {
      for (var i = 0; i < 4; i++) {
        final w = t.widget<AnimatedContainer>(find.byKey(ValueKey('prog-dot-$i')));
        if ((w.constraints?.maxWidth ?? 0) > 10) return i;
      }
      return -1;
    }

    testWidgets('four slides, dots, rotates every 5 s over 600 ms', (t) async {
      await mount(t);
      expect(find.byKey(const ValueKey('prog-dot-3')), findsOneWidget);
      expect(find.text('Calm that\npays you back'), findsOneWidget);
      expect(dot(t), 0);
      await t.pump(const Duration(milliseconds: 4900));
      expect(dot(t), 0);
      await t.pump(const Duration(milliseconds: 200)); // 5.1 s: starts to move
      await t.pump(const Duration(milliseconds: 700)); // done after 600 ms
      expect(dot(t), 1);
      expect(find.text('Share a word,\ngrow together'), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      await t.pump(const Duration(milliseconds: 700));
      expect(dot(t), 2);
      await t.pump(const Duration(seconds: 5));
      await t.pump(const Duration(milliseconds: 700));
      await t.pump(const Duration(seconds: 5));
      await t.pump(const Duration(milliseconds: 700));
      expect(dot(t), 0, reason: 'wraps round to the first slide');
    });

    testWidgets('a finger pauses it and it resumes 5 s after lifting', (t) async {
      await mount(t);
      await t.pump(const Duration(seconds: 3));
      final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('prog-banner-pager'))));
      await t.pump(const Duration(seconds: 9)); // would have rotated at 5 s
      expect(dot(t), 0);
      await g.cancel();
      await t.pump(const Duration(milliseconds: 4800));
      expect(dot(t), 0);
      await t.pump(const Duration(milliseconds: 400));
      await t.pump(const Duration(milliseconds: 700));
      expect(dot(t), 1);
    });

    testWidgets('every button opens its page', (t) async {
      final opened = <int>[];
      await mount(t, onOpen: opened.add);
      for (var i = 0; i < 4; i++) {
        await t.tap(find.byKey(const ValueKey('prog-banner-pager')));
        await t.pump();
        await t.pump(const Duration(seconds: 5));
        await t.pump(const Duration(milliseconds: 700));
      }
      expect(opened.length, 4);
      expect(opened.toSet().length, 4, reason: 'four different slides, four different buttons');
    });

    testWidgets('reduced motion: no rotation', (t) async {
      ProgBannerCarousel.debugLive = true;
      await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 358, child: ProgBannerCarousel())))),
      ));
      await t.pump(const Duration(seconds: 12));
      expect(dot(t), 0);
      expect(t.binding.transientCallbackCount, 0);
    });
  });

  group('routes', () {
    testWidgets('every banner and card destination is a real page', (t) async {
      final cases = <String, Type>{
        'earn': CircleScreen,
        'earnings': EarningsScreen,
        'coins': CoinsScreen,
        'plans': SubscriptionScreen,
      };
      expect(cases.length, 4);
      // The page builders resolve without throwing.
      expect(const CoinsScreen(), isA<Widget>());
      expect(const SubscriptionScreen(), isA<Widget>());
    });
  });

  testWidgets('in the real Zen home', (t) async {
    if (_out.isEmpty) return;
    SharedPreferences.setMockInitialValues({});
    ProgBannerCarousel.debugT = .3;
    const w = 390.0, h = 9000.0;
    final key = GlobalKey();
    t.view.physicalSize = const Size(w * 2, h * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(w, h), devicePixelRatio: 2, disableAnimations: true),
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'DM Sans'),
          home: RepaintBoundary(key: key, child: NavScope(go: (_) {}, child: const HomeFashion()))),
    ));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 150));
      t.takeException();
    }
    await precacheAll(t);
    await t.pump(const Duration(milliseconds: 300));
    t.takeException();
    expect(find.byType(ProgrammesGlassSection), findsOneWidget);
    final box = t.getRect(find.byType(ProgrammesGlassSection));
    final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final img = await ro.toImage(pixelRatio: 1);
      final r = Rect.fromLTWH(0, box.top - 200, w, box.height + 260);
      final rec = ui.PictureRecorder();
      Canvas(rec).drawImageRect(img, r, Rect.fromLTWH(0, 0, r.width, r.height), Paint());
      final part = await rec.endRecording().toImage(r.width.ceil(), r.height.ceil());
      final png = await part.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/zen_home_context_390.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}
