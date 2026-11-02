// B035: each R27 page (+ Lucky draw, Plus) shows its how-it-works pop-up once
// (persisted seen flag); "?" reopens it; 'How rewards work' opens it too.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/draw/lucky_draw_screen.dart';
import 'package:nowssb/screens/fashion_plus.dart';
import 'package:nowssb/screens/store/store_first_use_guide.dart';
import 'package:nowssb/widgets/concept/r27/live.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/r27_fit.dart';

Future<void> _pump(WidgetTester t, Widget w) async {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: w));
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  setUpAll(loadR27Fonts);
  for (final c in const [(390.0, 1.0, 'B035-390'), (320.0, 1.3, 'B035-320')]) {
    testWidgets('shot ${c.$3}', (t) async {
      SharedPreferences.setMockInitialValues({});
      final key = GlobalKey();
      t.view.physicalSize = Size(c.$1 * 3, 760 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(RepaintBoundary(key: key, child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'DM Sans'),
          home: Builder(builder: (ctx) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(c.$2)),
              child: const R27RewardsLivePage())))));
      await t.runAsync(() async {
        for (final e in find.byType(Image).evaluate().toList()) {
          try { await precacheImage((e.widget as Image).image, e).timeout(const Duration(seconds: 5)); } catch (_) {}
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.byKey(const Key('storeGuideCard')), findsOneWidget);
      // Title and body only: no icon on the card.
      expect(find.descendant(of: find.byKey(const Key('storeGuideCard')), matching: find.byType(Icon)), findsNothing);
      expect(t.takeException(), isNull);
      await shotR27(t, key, c.$3);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 2));
    });
  }
  final pages = <String, (Widget, String)>{
    'r27_rewards': (const R27RewardsLivePage(), 'How rewards work'),
    'r27_gifts': (const R27GiftsLivePage(), 'How gifts work'),
    'r27_earn': (const R27EarnLivePage(), 'How Earn works'),
    'r27_coupons': (const R27CouponsLivePage(), 'How coupons work'),
    'lucky_draw': (const LuckyDrawScreen(), 'How the lucky draw works'),
  };
  for (final e in pages.entries) {
    testWidgets('${e.key}: pop-up once, persisted, "?" reopens', (t) async {
      SharedPreferences.setMockInitialValues({});
      await _pump(t, e.value.$1);
      expect(find.byKey(const Key('storeGuideCard')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('storeGuideCard')), matching: find.text(e.value.$2)), findsOneWidget);
      await t.tap(find.byKey(const Key('storeGuideSkip')));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('storeGuideCard')), findsNothing);
      final p = await SharedPreferences.getInstance();
      expect(p.getBool(StoreFirstUseGuide.prefKey(e.key)), isTrue);
      await t.tap(find.byKey(const Key('storeGuideHelp')));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('storeGuideCard')), findsOneWidget);
      // Seen: a fresh open does not pop it again.
      await t.pumpWidget(const SizedBox());
      await _pump(t, e.value.$1);
      expect(find.byKey(const Key('storeGuideCard')), findsNothing);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 2));
    });
  }

  testWidgets("'How rewards work' opens the pop-up, not the Vault", (t) async {
    SharedPreferences.setMockInitialValues({StoreFirstUseGuide.prefKey('r27_rewards'): true});
    await _pump(t, const R27RewardsLivePage());
    expect(find.byKey(const Key('storeGuideCard')), findsNothing);
    final link = find.text('How rewards work  →');
    await t.ensureVisible(link);
    await t.pump();
    await t.tap(link);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('storeGuideCard')), findsOneWidget);
    expect(find.byType(R27RewardsLivePage), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(minutes: 2));
  });

  testWidgets('Plus page has its pop-up', (t) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(t, const FashionPlusScreen());
    final enter = find.textContaining('ENTER');
    if (enter.evaluate().isNotEmpty) {
      await t.tap(enter.first);
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
    }
    expect(find.text('How Plus works'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(minutes: 2));
  });
}

