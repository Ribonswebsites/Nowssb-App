import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/features/earn/earn_hub_screen.dart';
import 'package:nowssb/features/economy/economy_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Rewards / coin balance: signed in, hero shows the server balance (test data)', (tester) async {
    // TEST DATA shaped like the EconomyMirror fields the server summary fills.
    final m = EconomyMirror.instance
      ..uid = 'test-uid'
      ..coins = 12480
      ..cash = 34750
      ..plan = 'Plus'
      ..sellerTier = 'Seller II'
      ..wordsSold = 62
      ..nextSellerTarget = 100
      ..circleTier = 'Circle'
      ..code = 'RIBON7';
    addTearDown(() => m
      ..uid = null
      ..coins = 0
      ..cash = 0
      ..plan = 'Free'
      ..sellerTier = 'Seller'
      ..wordsSold = 0
      ..nextSellerTarget = 100
      ..circleTier = 'Member'
      ..code = '');
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_loadRoboto);
    await tester.binding.setSurfaceSize(const Size(412, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark().copyWith(textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
      builder: (context, child) => RepaintBoundary(key: const ValueKey('shot'), child: child),
      home: const EarnHubScreen(),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    // Decode the real hero banner and coin images (fake-async can't).
    final ctx = tester.element(find.byType(EarnHubScreen));
    await tester.runAsync(() async {
      for (final a in ['assets/icons/nwsb-coin.webp']) {
        await precacheImage(AssetImage(a), ctx);
      }
    });
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('12,480'), findsOneWidget);
    await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('rewards_coin_balance.png'));
    // Open the referral sheet from the new row and shoot it.
    await tester.tap(find.text('Share your code'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('Copy code'), findsOneWidget);
    await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile('rewards_share_sheet.png'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });
}

Future<void> _loadRoboto() async {
  final dir = Directory('/home/box/flutter/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  final loader = FontLoader('Roboto');
  for (final f in dir.listSync().whereType<File>()) {
    final n = f.uri.pathSegments.last;
    if (n.startsWith('Roboto-') && n.endsWith('.ttf') && !n.contains('Italic')) {
      loader.addFont(f.readAsBytes().then(ByteData.sublistView));
    }
  }
  await loader.load();
  final icons = File('/home/box/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then(ByteData.sublistView))).load();
  }
}
