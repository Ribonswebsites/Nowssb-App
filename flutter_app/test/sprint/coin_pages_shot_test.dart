import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/features/coins/free_coins_page.dart';

/// Shaped like GET /api/economy summary (functions/_lib/economy/summary.js).
final summary = <String, dynamic>{
  'now': DateTime(2026, 10, 10, 18).millisecondsSinceEpoch, // a Saturday
  'wallet': {'coins': 1240, 'coinsBackBonusPct': 5, 'streak': 6},
  'today': {
    'freeCoins': 38,
    'ceiling': 120,
    'spin': {'used': 0, 'freeLeft': 1, 'paidLeft': 0, 'cost': 0, 'next': 'free'},
    'actions': [
      {'id': 'open', 'title': 'Open the app', 'coins': 5, 'per': 'day', 'limit': 1, 'done': 1},
      {'id': 'word_of_day', 'title': 'Word of the day', 'coins': 10, 'per': 'day', 'limit': 1, 'done': 0},
      {'id': 'sound_bath', 'title': 'Sound Bath session', 'coins': 10, 'per': 'day', 'limit': 2, 'done': 1},
      {'id': 'read_meaning', 'title': 'Read one meaning to the end', 'coins': 8, 'per': 'day', 'limit': 3, 'done': 0},
      {'id': 'close_stage', 'title': 'Close a stage', 'coins': 40, 'per': 'key', 'limit': 1, 'done': 0},
      {'id': 'reminders_on', 'title': 'Turn on reminders', 'coins': 50, 'per': 'once', 'limit': 1, 'done': 0},
    ],
  },
  'config': {
    'rewards': {
      'buying': {'coinsBackPct': 4, 'bundleBonusPct': 5, 'firstPurchase': {'coins': 100, 'coupon': 'rare'}, 'renewalBonus': {'3': 100, '6': 250, '12': 600}},
      'eventMultiplier': 1,
      'events': [
        {'id': 'wknd', 'title': 'Double-coin weekend', 'multiplier': 2, 'weekdays': [6, 0]},
        {'id': 'diwali', 'title': 'Festival of light', 'multiplier': 3, 'startsAt': '2026-11-07T00:00:00+05:30', 'endsAt': '2026-11-09T23:59:00+05:30'},
      ],
    },
  },
};

Future<void> shot(WidgetTester tester, Widget page, String file, {double h = 1600}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(_loadRoboto);
  await tester.binding.setSurfaceSize(Size(412, h));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto')),
    home: RepaintBoundary(key: const ValueKey('shot'), child: page),
  ));
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump(const Duration(milliseconds: 600));
  await expectLater(find.byKey(const ValueKey('shot')), matchesGoldenFile(file));
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 5));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Free coins page', (tester) async {
    await shot(tester, FreeCoinsPage(preset: summary, showWheel: false), 'free_coins.png', h: 1100);
    expect(find.text('FREE TODAY'), findsNothing); // tree torn down
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
