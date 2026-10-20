import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowssb/features/economy/money.dart';
import 'package:nowssb/screens/store/store_first_use_guide.dart';

Widget _host() => const MaterialApp(
      home: StoreFirstUseGuide(guideKey: 't', child: Scaffold(body: Text('page'))),
    );

void main() {
  testWidgets('guide shows once, steps through, and stays dismissed', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(_host());
    await t.pumpAndSettle();
    expect(find.byKey(const Key('storeGuideCard')), findsOneWidget);
    expect(find.text('Welcome to the Store'), findsOneWidget);
    await t.tap(find.byKey(const Key('storeGuideNext')));
    await t.pumpAndSettle();
    expect(find.text('Word Atelier'), findsOneWidget);
    await t.tap(find.byKey(const Key('storeGuideSkip')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('storeGuideCard')), findsNothing);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool(StoreFirstUseGuide.prefKey('t')), isTrue);

    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(_host());
    await t.pumpAndSettle();
    expect(find.byKey(const Key('storeGuideCard')), findsNothing);
    expect(find.bySemanticsLabel('Open store guide'), findsOneWidget);
    await t.tap(find.byKey(const Key('storeGuideHelp')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('storeGuideCard')), findsOneWidget);
  });

  test('no hardcoded INR rate: rupee amounts stay in base currency until FX loads', () {
    final fx = FxBook.instance;
    expect(fx.rates.containsKey('INR'), isFalse);
    expect(fx.formatRupees(99, locale: 'en_US'), contains('99'));
    expect(fx.formatRupees(99, locale: 'en_US'), isNot(contains(r'$')));
  });
}
