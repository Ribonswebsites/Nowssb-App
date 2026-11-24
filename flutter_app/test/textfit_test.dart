// Text on the Zen practice banner and the home Store row must show in
// full: no clipped last line, no ellipsized deal % or price. Also sweeps
// both homes at 360/390 and normal / large text scale for overflow.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/home_cards.dart';
import 'package:nowssb/screens/fashion/sections_top.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/widgets/black_glass_banner.dart';

import 'fake_video_platform.dart';
import 'support/test_fonts.dart';

const _shots = '/workspace/team-plan/shots/textfit';
const _prefix = String.fromEnvironment('SHOT_PREFIX', defaultValue: 'after');

final _bannerPool = [
  PracticeBannerSpec("Today's Practice", "Begin today’s session", () {}),
  PracticeBannerSpec('Sit with one word', 'Five quiet minutes', () {}),
  PracticeBannerSpec('Your word ritual', 'Pick up where you left', () {}),
  PracticeBannerSpec(
      'Listen, then repeat', 'Three, seven or twenty-one reps', () {}),
  PracticeBannerSpec('Morning practice', 'The card knows the hour', () {}),
  PracticeBannerSpec('Speak it back', 'Scored from 0 to 100', () {}),
  PracticeBannerSpec('Words for today', 'Queued and ready to play', () {}),
  PracticeBannerSpec('Breathe and repeat', 'Start a word session', () {}),
  PracticeBannerSpec(
      'Follow your routine', 'Your words, your order, your time', () {}),
];

List<StoreNowItem> _storeItems() => [
      StoreNowItem(
        word: 'ZEUS',
        category: 'Mythical Edition',
        price: '₹99',
        percent: 25,
        onTap: () {},
      ),
      StoreNowItem(
        word: 'SOMA',
        category: 'Ancient Civilizations',
        price: '₹1,299',
        percent: 60,
        onTap: () {},
      ),
      StoreNowItem(
        word: 'AAROGYA',
        category: 'Sacred & Divine',
        price: '₹499',
        percent: 20,
        onTap: () {},
      ),
    ];

Widget _frame({
  required Widget child,
  required double width,
  required double scale,
  Key? shotKey,
  Color bg = const Color(0xFF2A0A4A),
}) {
  return MediaQuery(
    data: MediaQueryData(
        size: Size(width, 1800), textScaler: TextScaler.linear(scale)),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'DM Sans', brightness: Brightness.dark),
      home: Scaffold(
        backgroundColor: bg,
        body: shotKey == null
            ? child
            : RepaintBoundary(
                key: shotKey,
                child: ColoredBox(color: bg, child: child),
              ),
      ),
    ),
  );
}

Future<void> _size(WidgetTester t, double w, {double h = 1800}) async {
  t.view.physicalSize = Size(w * 3, h * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

Future<void> _shot(WidgetTester t, Key key, String name) async {
  await t.runAsync(() async {
    final ro = t.renderObject(find.byKey(key)) as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: 3);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory(_shots).createSync(recursive: true);
    File('$_shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// Every glyph of [textFinder] must sit inside [boxFinder], and the line
/// must not have been ellipsized or clipped by maxLines.
void expectTextInside(WidgetTester t, Finder textOrHost, Finder boxFinder,
    {required String reason}) {
  final box = t.getRect(boxFinder.first);
  final paras = <RenderParagraph>[];
  for (final e in textOrHost.evaluate()) {
    if (e.renderObject is RenderParagraph) {
      paras.add(e.renderObject! as RenderParagraph);
    } else {
      for (final d in find
          .descendant(
              of: find.byElementPredicate((el) => el == e),
              matching: find.byType(RichText))
          .evaluate()) {
        if (d.renderObject is RenderParagraph) {
          paras.add(d.renderObject! as RenderParagraph);
        }
      }
    }
  }
  expect(paras, isNotEmpty, reason: '$reason: no paragraph found');
  for (final p in paras) {
    final text = p.text.toPlainText();
    expect(p.didExceedMaxLines, isFalse,
        reason: '$reason: "$text" exceeded maxLines');
    if (p.overflow == TextOverflow.ellipsis) {
      expect(p.didExceedMaxLines, isFalse,
          reason: '$reason: ellipsis on "$text"');
    }
    for (var i = 0; i < text.length; i++) {
      if (text[i].trim().isEmpty) continue;
      for (final b in p.getBoxesForSelection(
          TextSelection(baseOffset: i, extentOffset: i + 1))) {
        final g = MatrixUtils.transformRect(p.getTransformTo(null), b.toRect());
        expect(
          g.height > 0.5 &&
              g.top >= box.top - 1.5 &&
              g.bottom <= box.bottom + 1.5 &&
              g.left >= box.left - 1.5 &&
              g.right <= box.right + 1.5,
          isTrue,
          reason: '$reason: glyph $i "${text[i]}" $g outside $box in "$text"',
        );
      }
    }
  }
}

void main() {
  SharedPreferences.setMockInitialValues({});
  setUpAll(() async {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
    await loadDmSans();
    await loadMaterialIcons();
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  const sizes = [
    (360.0, 1.0, '360'),
    (390.0, 1.0, '390'),
    (360.0, 1.3, '360x1.3'),
    (390.0, 1.3, '390x1.3')
  ];

  for (final (w, s, tag) in sizes) {
    testWidgets('practice banners show every line at $tag', (t) async {
      await _size(t, w, h: 2000);
      await t.pumpWidget(_frame(
        width: w,
        scale: s,
        child: ListView(
          children: [
            for (final b in _bannerPool)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: RoutineStyleBlackBanner(
                  key: ValueKey('b-${b.title}'),
                  title: b.title,
                  subtitle: b.subtitle,
                  onTap: () {},
                  heavy: true,
                ),
              ),
          ],
        ),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
      for (final b in _bannerPool) {
        final banner = find.byKey(ValueKey('b-${b.title}'));
        expect(banner, findsOneWidget);
        final text =
            find.descendant(of: banner, matching: find.byType(RichText));
        expect(t.getRect(banner).height, greaterThanOrEqualTo(95.5),
            reason: '${b.title} must stay at least the original 96 tall');
        expectTextInside(t, text, banner,
            reason: '${b.title} / ${b.subtitle} at $tag');
        final plain = text.evaluate().map((e) {
          final ro = e.renderObject;
          return ro is RenderParagraph ? ro.text.toPlainText() : '';
        }).join(' ');
        expect(plain, contains(b.title));
        expect(plain, contains(b.subtitle.split(' ').last),
            reason: 'last word of "${b.subtitle}" missing at $tag in "$plain"');
      }
    });
  }

  for (final (w, s, tag) in sizes) {
    testWidgets('home Store row shows deal % and price at $tag', (t) async {
      await _size(t, w, h: 1200);
      // One carousel per deal so long category/price cards are fully on
      // screen; the multi-item row is also built for the header check.
      await t.pumpWidget(_frame(
        width: w,
        scale: s,
        child: ListView(
          children: [
            StoreNowCarousel(items: _storeItems(), onHeader: () {}),
            for (final item in _storeItems())
              StoreNowCarousel(items: [item], onHeader: () {}),
          ],
        ),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.textContaining("TODAY'S DEAL"), findsWidgets);
      expect(find.textContaining('-25%'), findsWidgets);
      expect(find.textContaining('-60%'), findsWidgets);
      expect(find.textContaining('Mythical Edition'), findsWidgets);
      expect(find.textContaining('Ancient Civilizations'), findsWidgets);
      expect(find.textContaining('₹99'), findsWidgets);
      expect(find.textContaining('₹1,299'), findsWidgets);
      expect(find.text('NowssB Store'), findsWidgets);
      expect(find.text('Buy · Sell today'), findsWidgets);
      for (final e in find.byType(StoreNowCard).evaluate()) {
        final card = e.widget as StoreNowCard;
        final rect = t.getRect(find.byWidget(card));
        if (rect.right <= 0 || rect.left >= w) continue;
        expect(rect.height, greaterThanOrEqualTo(StoreNowCard.h - 0.5));
        expectTextInside(
          t,
          find.descendant(
              of: find.byWidget(card), matching: find.byType(RichText)),
          find.byWidget(card),
          reason: 'store card "${card.item.word}" at $tag',
        );
      }
    });
  }

  testWidgets('shots at 390 and other sizes', (t) async {
    const key = ValueKey('shot');
    await _size(t, 390, h: 2000);
    await t.pumpWidget(_frame(
      shotKey: key,
      width: 390,
      scale: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            for (final b in _bannerPool)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: RoutineStyleBlackBanner(
                    title: b.title,
                    subtitle: b.subtitle,
                    onTap: () {},
                    heavy: true),
              ),
          ],
        ),
      ),
    ));
    await t.pump();
    await _shot(t, key, '$_prefix-banners-390');
    await t.pumpWidget(const SizedBox());

    for (final (w, s, tag) in sizes) {
      await _size(t, w, h: 900);
      final k = ValueKey('shot-$tag');
      await t.pumpWidget(_frame(
        shotKey: k,
        width: w,
        scale: s,
        child: Column(
          children: [
            const SizedBox(height: 16),
            PracticeBannerCarousel(
              banners: [
                PracticeBannerSpec('Listen, then repeat',
                    'Three, seven or twenty-one reps', () {}),
                PracticeBannerSpec('Follow your routine',
                    'Your words, your order, your time', () {}),
                PracticeBannerSpec(
                    'Sit with one word', 'Five quiet minutes', () {}),
              ],
            ),
            StoreNowCarousel(items: _storeItems(), onHeader: () {}),
          ],
        ),
      ));
      await t.pump();
      // The listen banner in the carousel must show "reps".
      final car = find.byType(PracticeBannerCarousel);
      expect(car, findsOneWidget);
      expectTextInside(
          t,
          find.descendant(of: car, matching: find.byType(RichText)),
          find.byType(RoutineStyleBlackBanner),
          reason: 'carousel listen banner at $tag');
      expect(find.textContaining('reps'), findsWidgets);
      await _shot(t, k, '$_prefix-banner-store-$tag');
      await t.pumpWidget(const SizedBox());
    }
  });

  for (final (w, s, tag) in sizes) {
    testWidgets('Zen home and normal home: no overflow at $tag', (t) async {
      await _size(t, w, h: 900);
      final overflows = <String>[];
      final old = FlutterError.onError;
      addTearDown(() => FlutterError.onError = old);
      FlutterError.onError = (d) {
        final msg = d.exceptionAsString();
        if (msg.contains('overflow') || msg.contains('OVERFLOW')) {
          overflows.add(msg.split('\n').first);
        }
      };

      Future<void> pumpHome(Widget home) async {
        overflows.clear();
        await t.pumpWidget(MediaQuery(
          data: MediaQueryData(
              size: Size(w, 900), textScaler: TextScaler.linear(s)),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'DM Sans'),
            home: NavScope(go: (_) {}, child: home),
          ),
        ));
        await t.pump();
        await t.pump(const Duration(milliseconds: 200));
        for (final banner in find.byType(RoutineStyleBlackBanner).evaluate()) {
          expectTextInside(
            t,
            find.descendant(
                of: find.byWidget(banner.widget),
                matching: find.byType(RichText)),
            find.byWidget(banner.widget),
            reason: 'home practice banner at $tag',
          );
        }
        for (final card in find.byType(StoreNowCard).evaluate()) {
          final rect = t.getRect(find.byWidget(card.widget));
          if (rect.right <= 0 || rect.left >= w) continue;
          expectTextInside(
            t,
            find.descendant(
                of: find.byWidget(card.widget),
                matching: find.byType(RichText)),
            find.byWidget(card.widget),
            reason: 'home StoreNowCard at $tag',
          );
        }
        expect(overflows, isEmpty, reason: 'overflows at $tag: $overflows');
        VideoPool.instance.debugDropAll();
        await t.pumpWidget(const SizedBox());
        // Flush leftover AutoCycle / video timers so the test can end.
        await t.pump(const Duration(seconds: 6));
      }

      await pumpHome(const HomeFashion());
      await pumpHome(const HomeNormal());
    });
  }
}
