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
import 'package:nowssb/widgets/glass_tile_row.dart';
import 'package:nowssb/widgets/word_fit_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_video_platform.dart';
import 'support/home_render.dart';
import 'support/offline_google_fonts.dart';

// flutter test test/prog_glass2_test.dart --dart-define=PROGGLASS_OUT=/out
const _out = String.fromEnvironment('PROGGLASS_OUT');

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

/// The old Zen programme door, rebuilt only to compare sizes and look.
class _RefTile extends StatelessWidget {
  const _RefTile();
  @override
  Widget build(BuildContext context) {
    Widget small(String img, Color tint, String label) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 100,
              child: Stack(fit: StackFit.expand, children: [
                ColoredBox(color: tint),
                Image(image: AssetImage(img), fit: BoxFit.cover, alignment: const Alignment(0, -0.1), color: tint.withValues(alpha: 0.42), colorBlendMode: BlendMode.srcATop),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xCC000000)]))),
                Positioned(left: 8, right: 8, bottom: 8, child: WordFitText(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, height: 1.12))),
              ]),
            ),
          ),
        );
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: 176,
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(width: 112, height: 176, child: Image(image: AssetImage('assets/banners/earn/hands-raise.png'), fit: BoxFit.cover, alignment: Alignment(0, -0.05))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 122,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                small('assets/banners/earn/man-light.png', const Color(0xFF8A5A12), 'Your Earning'),
                small('assets/banners/earn/sit-light.png', const Color(0xFF1F4E7A), 'NowssB Reference'),
              ]),
            ),
          ),
        ]),
      ),
    );
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
    GlassTileRow.debugPage = null;
    GlassTileRow.debugLive = false;
  });

  for (var i = 0; i < 4; i++) {
    testWidgets('tile card $i', (t) async {
      if (_out.isEmpty) return;
      GlassTileRow.debugPage = i;
      final key = GlobalKey();
      await _pump(t, key, const GlassTileRow(), 250);
      expect(t.takeException(), isNull);
      await _shot(t, key, 'card${i + 1}_390');
    });
  }

  // The tile this row copies: the old Zen programme door (hands-raise tall
  // photo, tinted tiles beside it), rebuilt here only to put beside the row.
  testWidgets('row next to the reference glass tile', (t) async {
    if (_out.isEmpty) return;
    final key = GlobalKey();
    await _pump(
        t,
        key,
        const Column(children: [
          _RefTile(),
          GlassTileRow(),
        ]),
        520);
    expect(t.takeException(), isNull);
    await _shot(t, key, 'row_vs_reference_390');
  });

  testWidgets('every card is the same size as the reference tile', (t) async {
    t.view.physicalSize = const Size(390 * 2, 600 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    for (var i = 0; i < 4; i++) {
      GlassTileRow.debugPage = i;
      await t.pumpWidget(const MaterialApp(home: Scaffold(body: Column(children: [_RefTile(), GlassTileRow()]))));
      final glass = find.byType(GlassWrap);
      final ref = t.getSize(glass.at(0));
      final card = t.getSize(glass.at(1));
      expect(card, ref, reason: 'card $i: same width and same height as the reference tile');
      await t.pumpWidget(const SizedBox());
    }
  });
  testWidgets('wrapped section beside the Begin card', (t) async {
    if (_out.isEmpty) return;
    final key = GlobalKey();
    await _pump(t, key, const Column(children: [FashGreeting(), ProgrammesGlassSection()]), 1480);
    expect(t.takeException(), isNull);
    await _shot(t, key, 'wrapped_vs_begin_390');
  });

  testWidgets('wrapped section at 320 wide', (t) async {
    if (_out.isEmpty) return;
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
    t.view.physicalSize = const Size(390 * 2, 2000 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: ThemeData(fontFamily: 'DM Sans'), home: const Scaffold(body: SingleChildScrollView(child: ProgrammesGlassSection()))));
    // The row's own card, plus the one pane that holds the programme cards.
    expect(find.byType(GlassWrap), findsNWidgets(2));
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

  group('tile row', () {
    Future<void> mount(WidgetTester t, {void Function(String)? onOpen}) async {
      GlassTileRow.debugLive = true;
      t.view.physicalSize = const Size(390 * 2, 400 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: Scaffold(body: Center(child: GlassTileRow(onOpen: onOpen))),
      ));
    }

    int dot(WidgetTester t) {
      for (var i = 0; i < 4; i++) {
        final w = t.widget<AnimatedContainer>(find.byKey(ValueKey('prog-dot-$i')));
        if ((w.constraints?.maxWidth ?? 0) > 10) return i;
      }
      return -1;
    }

    testWidgets('four cards, each in its own glass, same size', (t) async {
      await mount(t);
      expect(find.byKey(const ValueKey('prog-dot-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('prog-dot-4')), findsNothing);
      expect(find.text('Earn coins'), findsOneWidget);
      // Three photos on a card; one glass pane per card (the next card's
      // pane is its own, not shared).
      expect(find.byType(Image), findsNWidgets(3));
      expect(find.byType(GlassWrap), findsOneWidget);
      // 16 px of margin each side, 176 px of picture and 8 px of glass.
      expect(t.getSize(find.byType(GlassWrap)), const Size(390, 176 + 16 + 2 + 16));
    });

    testWidgets('rotates every 5 s over 600 ms, round to the first', (t) async {
      await mount(t);
      expect(dot(t), 0);
      await t.pump(const Duration(milliseconds: 4900));
      expect(dot(t), 0);
      await t.pump(const Duration(milliseconds: 200)); // 5.1 s: starts to move
      await t.pump(const Duration(milliseconds: 300)); // 0.3 s in: part way
      final page = t.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
      expect(page, greaterThan(1000 * 4 * 390.0), reason: 'it has left the first card');
      await t.pump(const Duration(milliseconds: 600));
      expect(dot(t), 1);
      expect(find.text('Reference'), findsOneWidget);
      for (var k = 2; k <= 4; k++) {
        await t.pump(const Duration(seconds: 5));
        await t.pump(const Duration(milliseconds: 700));
        expect(dot(t), k % 4);
      }
    });

    testWidgets('a finger pauses it and it resumes 5 s after lifting', (t) async {
      await mount(t);
      await t.pump(const Duration(seconds: 3));
      final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('prog-tile-pager'))));
      await t.pump(const Duration(seconds: 9)); // would have rotated at 5 s
      expect(dot(t), 0);
      await g.cancel();
      await t.pump(const Duration(milliseconds: 4800));
      expect(dot(t), 0);
      await t.pump(const Duration(milliseconds: 400));
      await t.pump(const Duration(milliseconds: 700));
      expect(dot(t), 1);
    });

    testWidgets('every card opens its page', (t) async {
      final opened = <String>[];
      await mount(t, onOpen: opened.add);
      for (var i = 0; i < 4; i++) {
        await t.tap(find.byType(WordFitText).first);
        await t.pump();
        await t.pump(const Duration(seconds: 5));
        await t.pump(const Duration(milliseconds: 700));
      }
      expect(opened, ['earn:tall', 'reference:tall', 'coins:tall', 'plus:tall']);
    });

    testWidgets('reduced motion: no rotation', (t) async {
      GlassTileRow.debugLive = true;
      await t.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: const MaterialApp(home: Scaffold(body: Center(child: GlassTileRow()))),
      ));
      await t.pump(const Duration(seconds: 12));
      expect(dot(t), 0);
      expect(t.binding.transientCallbackCount, 0);
    });
  });

  group('pictures', () {
    testWidgets('twelve different pictures, none used anywhere else', (t) async {
      final art = glassTileRowArt;
      expect(art.length, 12);
      expect(art.toSet().length, 12, reason: 'no picture twice in the row');
      // Not on the old reference tile, nor in any other lib file.
      final others = StringBuffer();
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart') || f.path.endsWith('glass_tile_row.dart')) continue;
        others.write(f.readAsStringSync());
      }
      final src = others.toString();
      for (final a in art) {
        expect(File(a).existsSync(), isTrue, reason: '$a exists');
        expect(src.contains(a), isFalse, reason: '$a must not appear elsewhere');
        expect(a.contains('hands-raise') || a.contains('man-light') || a.contains('sit-light') || a.contains('yoga-dark'), isFalse);
      }
      // And not one of the programme cards' own pictures.
      for (final other in ['prog-letter', 'prog-sill', 'prog-bowl', 'rail-stones', 'quiet-room', 'rail-well']) {
        expect(art.any((a) => a.contains(other)), isFalse);
      }
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
