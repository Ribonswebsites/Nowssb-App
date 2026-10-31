import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/screens/normal/calm_v3.dart';
import 'package:nowssb/screens/profile_mind.dart';
import 'package:nowssb/widgets/editeaze.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _slides = [
  EzSlide(image: 'assets/home/ez/ez-med-beach.webp', title: 'A'),
  EzSlide(image: 'assets/home/ez/ez-med-candle.webp', title: 'B'),
  EzSlide(image: 'assets/home/ez/ez-med-home.webp', title: 'C'),
];

/// Any dot / page indicator widget, by type or by name.
final _indicators = find.byWidgetPredicate((w) {
  final n = w.runtimeType.toString().toLowerCase();
  return w is TabPageSelector || w is TabPageSelectorIndicator || n.contains('indicator') && !n.contains('progress') && !n.contains('overscroll') || n.contains('dot');
});

Future<void> _pumpCarousel(WidgetTester t) async {
  t.view.physicalSize = const Size(360, 700);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: Padding(padding: EdgeInsets.all(16), child: EzOrangeCarousel(slides: _slides, height: 300)))));
}

EzOrangeCarouselState _state(WidgetTester t) => t.state(find.byType(EzOrangeCarousel));

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('carousel: swipe moves, no dots or indicators anywhere', (t) async {
    await _pumpCarousel(t);
    expect(_state(t).index, 0);
    await t.fling(find.byKey(const ValueKey('ez-carousel')), const Offset(-250, 0), 1200);
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(_state(t).index, 1);
    await t.drag(find.byKey(const ValueKey('ez-carousel')), const Offset(260, 0));
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    expect(_state(t).index, 0);
    expect(_indicators, findsNothing);
    expect(find.byType(PageView), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('carousel auto-rotates and pauses while touched', (t) async {
    await _pumpCarousel(t);
    await t.pump(const Duration(milliseconds: 4100));
    await t.pumpAndSettle();
    expect(_state(t).index, 1, reason: 'auto-advanced');
    final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('ez-carousel'))));
    expect(_state(t).held, isTrue);
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(_state(t).index, 1, reason: 'paused while held');
    await g.up();
    await t.pump(const Duration(seconds: 3));
    expect(_state(t).held, isFalse);
    await t.pump(const Duration(milliseconds: 4100));
    await t.pumpAndSettle();
    expect(_state(t).index, 2, reason: 'resumed after release');
  });

  testWidgets('split strip: handle drags, tiles and Add more tap', (t) async {
    var left = 0, right = 0, add = 0;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: EzSplitStrip(
                  left: EzTile(image: 'assets/home/ez/ez-med-studio.webp', label: 'Her path', onTap: () => left++),
                  right: EzTile(image: 'assets/home/ez/ez-med-rock.webp', label: 'His path', onTap: () => right++),
                  onAdd: () => add++,
                )))));
    final before = t.getTopLeft(find.byKey(const ValueKey('ez-split-handle'))).dx;
    await t.drag(find.byKey(const ValueKey('ez-split-handle')), const Offset(60, 0));
    await t.pump();
    expect(t.getTopLeft(find.byKey(const ValueKey('ez-split-handle'))).dx, greaterThan(before + 20));
    await t.tap(find.text('Her path'));
    await t.tap(find.text('His path'));
    await t.tap(find.byKey(const ValueKey('ez-add-more')));
    expect([left, right, add], [1, 1, 1]);
    expect(_indicators, findsNothing);
  });

  testWidgets('Normal home hero is the orange carousel and swipes', (t) async {
    t.view.physicalSize = const Size(360, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: CalmToday()))));
    await t.pump(const Duration(milliseconds: 300));
    final hero = find.byKey(const ValueKey('cv3-ez-hero'));
    expect(hero, findsOneWidget);
    final s = t.state<EzOrangeCarouselState>(hero);
    await t.fling(hero, const Offset(-250, 0), 1200);
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(s.index, 1);
    expect(_indicators, findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Profile mind: honest empty state with no sessions', (t) async {
    t.view.physicalSize = const Size(360, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ProfileMind()))));
    await t.pump();
    expect(find.text('Practice once to see this'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  test('hero pill copy is short and friendly', () {
    expect(ezHeroLine(0, 0, 0), 'Start your first session');
    expect(ezHeroLine(0, 3, 0), 'Start your first session');
    expect(ezHeroLine(2, 3, 4), '2 of 3 done · 4-day streak');
    expect(ezHeroLine(1, 3, 0), '1 of 3 done');
  });
}
