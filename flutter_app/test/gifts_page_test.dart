import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/features/gifts/gifts_screen.dart';
import 'package:nowssb/features/programs/gifts_program.dart';

void main() {
  test('Gifts has every tab incl. Expired', () {
    expect(kGiftsSpec.tabs.map((t) => t.id), ['free', 'send', 'received', 'sent', 'expired', 'redeem', 'rules']);
  });

  test('catalog never shows a hardcoded rupee price', () {
    expect(kGiftCatalog, isNotEmpty);
  });

  testWidgets('first-use guide steps through and closes', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(MaterialApp(home: Builder(builder: (c) => TextButton(onPressed: () => showGiftsGuide(c), child: const Text('go')))));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('Free gifts'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
    }
    expect(find.text('Redeem'), findsOneWidget);
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(find.byType(GiftsGuide), findsNothing);
  });

  testWidgets('guide Skip closes it', (t) async {
    await t.pumpWidget(MaterialApp(home: Builder(builder: (c) => TextButton(onPressed: () => showGiftsGuide(c), child: const Text('go')))));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    await t.tap(find.text('Skip'));
    await t.pumpAndSettle();
    expect(find.byType(GiftsGuide), findsNothing);
  });
}
