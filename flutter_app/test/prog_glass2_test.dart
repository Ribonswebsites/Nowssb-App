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
import 'package:nowssb/screens/fashion/home_cards.dart';
import 'package:nowssb/widgets/earn_now_section.dart';
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

/// The real NowssB Store section, as the Zen home builds it.
Widget _store() => StoreNowCarousel(
      items: [
        StoreNowItem(word: 'Sovereign', category: 'Premium', price: '₹99.00', onTap: () {}),
        StoreNowItem(word: 'Storm', category: 'Elements', price: '\$0.94', percent: 20, onTap: () {}),
      ],
      onHeader: () {},
    );

void main() {
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await setUpHomeRender();
    await setUpOfflineGoogleFonts();
  });
  tearDown(() {
  });

  testWidgets('NowssB Earn stacked under the real NowssB Store', (t) async {
    if (_out.isEmpty) return;
    final key = GlobalKey();
    await _pump(t, key, Column(children: [_store(), const EarnNowSection()]), 520);
    expect(t.takeException(), isNull);
    await _shot(t, key, 'earn_under_store_390');
  });

  testWidgets('each Earn card', (t) async {
    if (_out.isEmpty) return;
    for (var i = 0; i < 4; i++) {
      final key = GlobalKey();
      await _pump(t, key, const EarnNowSection(), 260);
      // Bring card i to the front.
      final pager = find.byType(PageView);
      for (var k = 0; k < i; k++) {
        await t.drag(pager, const Offset(-300, 0));
        await t.pump(const Duration(milliseconds: 700));
      }
      await t.pump(const Duration(milliseconds: 200));
      await _shot(t, key, 'earn_card${i + 1}_390');
      await t.pumpWidget(const SizedBox());
    }
  });

  testWidgets('the Earn section is the Store section: same glass, header, card, height', (t) async {
    t.view.physicalSize = const Size(390 * 2, 600 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'DM Sans'),
      home: Scaffold(body: Column(children: [_store(), const EarnNowSection()])),
    ));
    final carousels = find.byType(StoreNowCarousel);
    expect(carousels, findsNWidgets(2));
    expect(find.byType(GlassWrap), findsNWidgets(2), reason: 'the Store wrapper and the Earn wrapper');
    expect(t.getSize(carousels.at(0)), t.getSize(carousels.at(1)), reason: 'same wrapper size');
    final cards = find.byType(StoreNowCard);
    expect(t.getSize(cards.at(0)), t.getSize(cards.last), reason: 'same card size');
    expect(t.getSize(cards.first).height, StoreNowCard.h);
    expect(find.text('NowssB Store'), findsOneWidget);
    expect(find.text('NowssB Earn'), findsOneWidget);
    expect(find.text('Buy · Sell today'), findsOneWidget);
    expect(find.text('Earn · Collect today'), findsOneWidget);
    expect(find.text('EARN COINS'), findsOneWidget);
    expect(find.text('EARN'), findsOneWidget);
    expect(find.text('Daily coins'), findsOneWidget);
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
    expect(find.text('MEMBERSHIP'), findsWidgets);
    expect(find.text('Earned today'), findsOneWidget);
    // No stray highlight line along the top edge.
    expect(find.byWidgetPredicate((w) => w is Container && w.constraints?.maxHeight == 1.2), findsNothing);
  });

  group('Earn row', () {
    Future<void> mount(WidgetTester t, {void Function(String)? onOpen}) async {
      t.view.physicalSize = const Size(390 * 2, 400 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'DM Sans'),
        home: Scaffold(body: Center(child: EarnNowSection(onOpen: onOpen))),
      ));
    }

    // Frames like a phone's: the cycle only counts a wrap it sees.
    Future<void> elapse(WidgetTester t, int ms) async {
      for (var spent = 0; spent < ms; spent += 100) {
        await t.pump(Duration(milliseconds: ms - spent < 100 ? ms - spent : 100));
      }
    }

    double px(WidgetTester t) => t.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;

    testWidgets('four different cards, the next one peeking in from the right', (t) async {
      await mount(t);
      for (final w in ['EARN', 'REFERENCE', 'COINS', 'ZEN PLUS']) {
        // Built as the user scrolls; the first two are on screen already.
        if (w == 'EARN' || w == 'REFERENCE') expect(find.text(w), findsOneWidget);
      }
      expect(find.text('EARN COINS'), findsOneWidget);
      expect(find.text('YOUR LINKS'), findsOneWidget, reason: 'the second card peeks in');
    });

    testWidgets('moves every 5 s over 600 ms with easeInOutCubic', (t) async {
      await mount(t);
      final start = px(t);
      await elapse(t, 4900);
      expect(px(t), start, reason: 'still on the first card at 4.9 s');
      await elapse(t, 200); // starts moving at 5 s
      await elapse(t, 250); // part way
      final mid = px(t);
      expect(mid, greaterThan(start));
      await elapse(t, 600);
      final one = px(t) - start;
      expect(one, greaterThan(250), reason: 'one card along');
      expect(mid - start, lessThan(one * 0.9));
      await elapse(t, 5000);
      await elapse(t, 700);
      expect(px(t) - start, closeTo(one * 2, 2));
    });

    testWidgets('a finger pauses it and it resumes 5 s after lifting', (t) async {
      await mount(t);
      final start = px(t);
      await elapse(t, 3000);
      final g = await t.startGesture(t.getCenter(find.byType(PageView)));
      await elapse(t, 9000); // would have moved at 5 s
      expect(px(t), start);
      await g.cancel();
      await elapse(t, 4800);
      expect(px(t), start, reason: 'not before 5 s after the lift');
      await elapse(t, 500);
      await elapse(t, 700);
      expect(px(t), greaterThan(start + 250));
    });

    testWidgets('the Store row keeps its own drift (3 s, no pause)', (t) async {
      t.view.physicalSize = const Size(390 * 2, 400 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: _store()))));
      final start = t.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
      await elapse(t, 3200);
      await elapse(t, 700);
      expect(t.state<ScrollableState>(find.byType(Scrollable).first).position.pixels, greaterThan(start));
    });

    testWidgets('every card opens its page', (t) async {
      final opened = <String>[];
      await mount(t, onOpen: opened.add);
      for (var i = 0; i < 4; i++) {
        final cards = find.byType(StoreNowCard).evaluate().map((e) => e.renderObject! as RenderBox).toList();
        final onScreen = cards.firstWhere((b) {
          final x = b.localToGlobal(Offset.zero).dx;
          return x >= 0 && x < 100;
        });
        await t.tapAt(onScreen.localToGlobal(onScreen.size.center(Offset.zero)));
        await t.pump();
        await elapse(t, 5300);
        await elapse(t, 700);
      }
      expect(opened.length, 4);
      expect(opened.toSet().length, 4);
      expect(opened, containsAll(['earn', 'reference', 'coins', 'plus']));
    });
  });

  group('pictures', () {
    testWidgets('four different pictures, none used anywhere else', (t) async {
      final art = kEarnNowArt;
      expect(art.length, 4);
      expect(art.toSet().length, 4);
      final others = StringBuffer();
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart') || f.path.endsWith('earn_now_section.dart')) continue;
        others.write(f.readAsStringSync());
      }
      final src = others.toString();
      for (final a in art) {
        expect(File(a).existsSync(), isTrue, reason: '$a exists');
        expect(src.contains(a), isFalse, reason: '$a must not appear elsewhere');
      }
      for (final other in ['prog-letter', 'prog-sill', 'prog-bowl', 'rail-stones', 'quiet-room', 'rail-well', 'hands-raise', 'nowssb-store']) {
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
