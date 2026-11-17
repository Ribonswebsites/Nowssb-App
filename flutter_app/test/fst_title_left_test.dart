/// The Learn-guide title card ("NowssB / Follow the steps") must sit on
/// the LEFT of the television's screen so it never runs into the wave on
/// the right. The same sizes Ribon asked us to check: 360 and 390 wide,
/// at text scale 1.0 and 1.3. Step cards have no image on the right, but
/// they still must not overflow or clip at those sizes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/media/video_pool.dart';
import 'package:nowssb/screens/fashion/follow_steps.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/shell/nav_shell.dart';

import 'fake_video_platform.dart';

const _cases = <(double, double, String)>[
  (360, 1.0, '360@1.0'),
  (360, 1.3, '360@1.3'),
  (390, 1.0, '390@1.0'),
  (390, 1.3, '390@1.3'),
];

Future<void> revealNav(WidgetTester tester) async {
  final nav = find.byType(FstNav);
  expect(nav, findsWidgets);
  // tester.ensureVisible can park the foot under the sticky header, where
  // the Next disc is no longer hit-testable. Jump the vertical home
  // scroll (never the hero PageView) so the row sits in the open viewport.
  const wantTop = 260.0;
  for (final e in find.byType(Scrollable).evaluate()) {
    final s = (e as StatefulElement).state as ScrollableState;
    if (s.axisDirection != AxisDirection.down) continue;
    final r = tester.getRect(nav.first);
    final next = (s.position.pixels + r.top - wantTop)
        .clamp(0.0, s.position.maxScrollExtent);
    s.position.jumpTo(next);
    await tester.pump();
    break;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() {
    FakeVideoPlatform();
    VideoPool.debugDeadlines = false;
  });
  setUp(VideoPool.instance.debugDropAll);
  tearDown(VideoPool.instance.debugDropAll);

  Future<List<String>> openGuide(
    WidgetTester tester, {
    required double width,
    required double scale,
  }) async {
    tester.view.physicalSize = Size(width * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final overflows = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      final s = d.exceptionAsString();
      if (s.contains('overflowed') || s.contains('overflow')) {
        overflows.add(s.split('\n').first);
      }
      old?.call(d);
    };
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => MediaQuery(
            data: MediaQuery.of(ctx).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: NavScope(go: (_) {}, child: const HomeFashion()),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final disc = find.bySemanticsLabel('How this app works — follow the steps');
    await tester.ensureVisible(disc);
    await tester.pump();
    await tester.tap(disc);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Follow the steps'), findsOneWidget);
    expect(find.byType(FstTitle), findsOneWidget);
    // ensureVisible on the Learn disc can park the foot under the sticky
    // header, where the Next disc is no longer hit-testable. Bring the
    // title card back into the open viewport.
    await revealNav(tester);
    return overflows;
  }

  for (final c in _cases) {
    testWidgets('title copy stays left of the wave at ${c.$3}', (tester) async {
      final overflows = await openGuide(tester, width: c.$1, scale: c.$2);
      expect(overflows, isEmpty, reason: 'overflow at ${c.$3}: $overflows');

      final screen = tester.getRect(find.byType(FstTitle));
      final copy = tester.getRect(find.byKey(const ValueKey('fst-title-copy')));
      final follow = tester.getRect(find.text('Follow the steps'));

      // Left-aligned, not centred: starts in the left padding band.
      expect(copy.left, greaterThanOrEqualTo(screen.left + 10),
          reason: '${c.$3}: copy is too close to the left edge');
      expect(copy.left, lessThan(screen.left + screen.width * 0.20),
          reason: '${c.$3}: copy is not on the left of the screen');

      // Never crosses the mid-screen wave edge (~50%), with a little air.
      final wave = screen.left + screen.width * 0.48;
      expect(copy.right, lessThanOrEqualTo(wave + 0.6),
          reason: '${c.$3}: NowssB crosses into the wave '
              '(copy.right=${copy.right}, wave=$wave, screen=$screen)');
      expect(follow.right, lessThanOrEqualTo(wave + 0.6),
          reason: '${c.$3}: "Follow the steps" crosses into the wave');

      // Fully inside the aperture — never clipped by the screen.
      expect(copy.left, greaterThanOrEqualTo(screen.left - 0.6));
      expect(copy.top, greaterThanOrEqualTo(screen.top - 0.6));
      expect(copy.right, lessThanOrEqualTo(screen.right + 0.6));
      expect(copy.bottom, lessThanOrEqualTo(screen.bottom + 0.6));
      expect(follow.left, greaterThanOrEqualTo(screen.left - 0.6));
      expect(follow.right, lessThanOrEqualTo(screen.right + 0.6));

      // Vertically centred in the aperture.
      final dy = (copy.center.dy - screen.center.dy).abs();
      expect(dy, lessThan(screen.height * 0.22),
          reason: '${c.$3}: copy is not vertically centred '
              '(dy=$dy, screen.h=${screen.height})');
    });
  }

  for (final c in _cases) {
    testWidgets('every guide slide fits at ${c.$3}', (tester) async {
      final overflows = await openGuide(tester, width: c.$1, scale: c.$2);

      for (var i = 1; i <= kFstSteps.length; i++) {
        final next = find.bySemanticsLabel('Next step').hitTestable();
        expect(next, findsWidgets,
            reason: '${c.$3}: Next step is not tappable');
        await tester.tap(next.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 420));
        expect(find.text('Step $i of ${kFstSteps.length}'), findsOneWidget,
            reason: '${c.$3}: step $i did not arrive');
        expect(find.text(kFstSteps[i - 1].title), findsWidgets);
      }
      expect(overflows, isEmpty, reason: 'overflow at ${c.$3}: $overflows');
    });
  }
}
