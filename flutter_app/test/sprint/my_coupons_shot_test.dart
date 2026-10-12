import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/features/programs/coupons_program.dart';

/// Renders the My Coupons tab exactly as ProgramTabsBlock builds it, from a
/// summary map. The "filled" summary is TEST DATA shaped like
/// functions/_lib/economy/summary.js (coupons / scratchCards / tokens).
Future<void> _shot(WidgetTester tester, Map<String, dynamic> s, String golden, Size size, Finder mustShow) async {
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(_loadFonts);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final mine = kCouponsSpec.tabs.firstWhere((t) => t.id == 'mine');
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF050607),
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
    ),
    home: RepaintBoundary(
      key: const ValueKey('shot'),
      child: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (context) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: mine.build(context, s),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Coupons for you'), findsOneWidget);
  expect(mustShow, findsOneWidget);
  await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile(golden));
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 5));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Scratch ticket: part-scratched, prize from the (fake) server call', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    await tester.binding.setSurfaceSize(const Size(412, 280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var calls = 0;
    // TEST DATA: a summary.scratchCards entry and a revealScratch reply.
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF050607), textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
      home: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CouponScratchTicket(
              card: const {'id': 's1', 'rarity': 'rare', 'source': 'streak', 'paid': false},
              reveal: (c) async {
                calls++;
                return {'label': '15% off a word, cap ₹50', 'rarity': 'rare', 'granted': {'type': 'percentOff', 'pct': 15, 'capINR': 50, 'scope': 'word'}};
              },
            ),
          ),
        ),
      ),
    ));
    final panel = tester.getRect(find.byType(CouponScratchTicket));
    final g = await tester.startGesture(Offset(panel.left + 120, panel.top + 60));
    for (final dy in [0.0, 22.0, 44.0]) {
      for (var i = 0; i < 9; i++) {
        await g.moveBy(Offset(dy == 22.0 ? -16 : 16, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.moveBy(const Offset(0, 22));
    }
    await g.up();
    // Let the random foil flakes settle so the golden is deterministic.
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(calls, 1);
    expect(find.text('15% off a word, cap ₹50'), findsOneWidget);
    await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('my_coupons_scratch.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets('Scratch ticket: cleared, burst reveal after the server result', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadFonts);
    await tester.binding.setSurfaceSize(const Size(412, 280));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF050607), textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
      home: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CouponScratchTicket(
              card: const {'id': 's7', 'rarity': 'legendary', 'source': 'quest', 'paid': false},
              // TEST DATA shaped like a revealScratch reply.
              reveal: (c) async => {'label': '30% off a subscription, cap ₹300', 'rarity': 'legendary', 'already': true},
            ),
          ),
        ),
      ),
    ));
    final r = tester.getRect(find.byType(CouponScratchTicket));
    final g = await tester.startGesture(Offset(r.left + 112, r.top + 46));
    for (var row = 0; row < 9 && find.byKey(const ValueKey('coupon_burst')).evaluate().isEmpty; row++) {
      for (var i = 0; i < 18; i++) {
        await g.moveBy(Offset(row.isEven ? 15 : -15, 0));
        await tester.pump(const Duration(milliseconds: 8));
      }
      await g.moveBy(const Offset(0, 19));
    }
    await g.up();
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.text('30% off a subscription, cap ₹300'), findsOneWidget);
    expect(find.byKey(const ValueKey('coupon_burst')), findsOneWidget);
    // Mid-burst frame: scratch flakes and confetti are random, so this one is
    // saved as a screenshot, not compared pixel-for-pixel.
    final prior = goldenFileComparator;
    goldenFileComparator = _SaveOnly(prior);
    await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('my_coupons_reveal.png'));
    goldenFileComparator = prior;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets('Scratch ticket: failed server call keeps the card sealed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CouponScratchTicket(card: const {'id': 's9', 'rarity': 'common'}, reveal: (c) async => throw Exception('offline')),
        ),
      ),
    ));
    final panel = tester.getRect(find.byType(CouponScratchTicket));
    final g = await tester.startGesture(Offset(panel.left + 130, panel.top + 60));
    await g.moveBy(const Offset(20, 0));
    await g.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('still sealed'), findsOneWidget);
    expect(find.text('Scratch to open'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets('My Coupons: calm empty state', (tester) async {
    await _shot(tester, const {}, 'my_coupons_empty.png', const Size(412, 900), find.textContaining('No discounts yet'));
  });

  testWidgets('My Coupons: tickets from server-shaped summary (test data)', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const day = 86400000;
    await _shot(tester, {
      'coupons': [
        {'id': 'c1', 'label': '15% off a word, cap ₹50', 'pct': 15, 'capINR': 50, 'scope': 'word', 'source': 'scratch', 'expiresAt': now + day},
        {'id': 'c2', 'label': '30% off a subscription, cap ₹300', 'pct': 30, 'capINR': 300, 'scope': 'subscription', 'source': 'ticket', 'expiresAt': now + 20 * day},
        {'id': 'c3', 'label': '5% off any item, cap ₹15', 'pct': 5, 'capINR': 15, 'scope': 'any', 'source': 'daily'},
      ],
      'scratchCards': [
        {'id': 's1', 'rarity': 'rare'},
        {'id': 's2', 'rarity': 'common', 'source': 'daily'},
        {'id': 's3', 'rarity': 'epic', 'source': 'purchase', 'paid': true},
      ],
      'tokens': [
        {'item': 'stage1-signature', 'label': 'Stage 1 Signature', 'source': 'rare card', 'at': now - 2 * day},
      ],
    }, 'my_coupons_filled.png', const Size(412, 2000), find.text('15% off'));
    // Hero: sum of the three server caps (50 + 300 + 15), nothing invented.
  });

  testWidgets('My Coupons hero: uncapped discount falls back to the real count', (tester) async {
    await _shot(tester, {
      'coupons': [
        {'id': 'c1', 'label': '10% off any item', 'pct': 10, 'capINR': 0, 'scope': 'any'},
      ],
      'scratchCards': [
        {'id': 's1', 'rarity': 'rare'},
        {'id': 's2', 'rarity': 'common'},
      ],
    }, 'my_coupons_count.png', const Size(412, 1200), find.text('3'));
  });
}

Future<void> _loadFonts() async {
  const dir = '/home/box/flutter/bin/cache/artifacts/material_fonts';
  if (!Directory(dir).existsSync()) return;
  final roboto = FontLoader('Roboto');
  for (final f in Directory(dir).listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) {
      roboto.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
  }
  await roboto.load();
  final icons = File('$dir/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then(ByteData.sublistView))).load();
  }
}

class _SaveOnly extends GoldenFileComparator {
  _SaveOnly(this.inner);
  final GoldenFileComparator inner;
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await inner.update(golden, imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) => inner.update(golden, imageBytes);
}
