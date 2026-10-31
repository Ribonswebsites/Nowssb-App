import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/features/programs/earn_program.dart';

Map<String, dynamic> _summary({bool ready = false, num available = 0}) => {
      'enabled': true,
      'countryOk': true,
      'words': 120,
      'words90': 40,
      'standing': {'metal': 'Silver', 'title': 'Officer', 'ratePct': 10, 'nextWords': 200, 'nextTitle': 'Senior', 'keep90': 30, 'canEarn': true, 'teamMax': 5, 'leg': [3, 1], 'appoints': ['Officer']},
      'balances': {'pendingINR': 50, 'availableINR': available, 'lifetimeINR': 900, 'minPayoutINR': 500},
      'payoutAccount': ready ? {'ready': true, 'email': 'me@example.com', 'country': 'US'} : <String, dynamic>{},
      'ledger': [
        {'type': 'direct', 'note': null, 'inr': 12.5, 'at': 0, 'availableAt': 0},
        {'type': 'reversal', 'note': 'Refund', 'inr': -3, 'at': 0, 'availableAt': 0},
      ],
      'targets': [
        {'words': 200, 'cashINR': 100, 'coins': 0, 'coupon': null, 'reached': false},
      ],
      'ranks': [
        {'title': 'Officer', 'minWords': 100, 'ratePct': 10, 'leg': [3, 1], 'plan': 'any', 'metal': 'Silver'},
      ],
      'team': [
        {'name': null, 'rank': 'Officer', 'level': 2, 'words': 5, 'words90': 1},
      ],
      'invites': [],
      'sentInvites': [
        {'toName': null, 'rank': 'Officer', 'status': 'pending', 'at': 0},
      ],
    };

Future<List<(String, Map<String, dynamic>)>> _open(WidgetTester tester, String tab, {bool ready = false, num available = 0, bool content = true}) async {
  SharedPreferences.setMockInitialValues({});
  final calls = <(String, Map<String, dynamic>)>[];
  EconomyApi.debugHandler = (name, data) async {
    calls.add((name, data));
    return name == 'earnSummary' ? _summary(ready: ready, available: available) : <String, dynamic>{'ready': true};
  };
  addTearDown(() => EconomyApi.debugHandler = null);
  await tester.binding.setSurfaceSize(const Size(430, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => content
                  ? Scaffold(body: ListView(children: kEarnSpec.tabs[earnTabIndex(tab)].build(context, const {})))
                  : EarnProgramPage(initialTab: earnTabIndex(tab)),
            )),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('go'));
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return calls;
}

String _allText(WidgetTester tester) => tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? t.textSpan?.toPlainText() ?? '').join('\n');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Earn tab opens in one page and Android back returns', (tester) async {
    await _open(tester, 'sales', content: false);
    expect(find.byType(EarnTabsPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('go'), findsOneWidget);
    expect(find.byType(EarnTabsPage), findsNothing);
  });

  testWidgets('Sales ledger: no rupee sign, no "null"', (tester) async {
    await _open(tester, 'sales');
    final text = _allText(tester);
    expect(text.contains('\u20b9'), isFalse);
    expect(text.contains('null'), isFalse);
    expect(text, contains('Your sale'));
  });

  testWidgets('Targets: no empty coupon card, shows words to go', (tester) async {
    await _open(tester, 'targets');
    final text = _allText(tester);
    expect(text, contains('80 to go'));
    expect(text.contains(' card'), isFalse);
    expect(text.contains('Net'), isFalse);
  });

  testWidgets('Team: missing names read plainly; invite needs a code', (tester) async {
    await _open(tester, 'team');
    final text = _allText(tester);
    expect(text.contains('null'), isFalse);
    expect(text, contains('Team member'));
    final send = find.widgetWithText(TextButton, 'Send invitation');
    await tester.ensureVisible(send);
    expect(tester.widget<TextButton>(send).onPressed, isNull);
    await tester.enterText(find.byType(TextField).first, 'ABC123');
    await tester.pump();
    expect(tester.widget<TextButton>(send).onPressed, isNotNull);
  });

  testWidgets('Payouts: global form, no UPI/PAN/KYC, saves country+email', (tester) async {
    final calls = await _open(tester, 'payouts');
    final text = _allText(tester);
    for (final bad in ['UPI', 'PAN', 'KYC', 'TDS', '\u20b9']) {
      expect(text.contains(bad), isFalse, reason: bad);
    }
    final save = find.widgetWithText(TextButton, 'Save payout details');
    await tester.ensureVisible(save);
    expect(tester.widget<TextButton>(save).onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('earn.payout.email')), 'me@example.com');
    await tester.enterText(find.byKey(const ValueKey('earn.payout.name')), 'Ana Ray');
    await tester.pump();
    final country = find.byKey(const ValueKey('earn.payout.country'));
    final hasCountry = tester.widget<DropdownButtonFormField<String>>(country).initialValue != 'XX';
    if (!hasCountry) {
      await tester.ensureVisible(country);
      await tester.tap(country);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Canada').last);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump(const Duration(milliseconds: 300));
    final saved = calls.where((c) => c.$1 == 'savePayoutAccount').single.$2;
    expect(saved['email'], 'me@example.com');
    expect(saved.containsKey('pan'), isFalse);
    expect(saved.containsKey('upi'), isFalse);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Payouts: Request explains why it is off', (tester) async {
    await _open(tester, 'payouts', ready: true, available: 100);
    expect(_allText(tester), contains('once '));
    final req = find.widgetWithText(TextButton, 'Request payout');
    expect(tester.widget<TextButton>(req).onPressed, isNull);
  });

  test('Helpers', () {
    expect(looksLikeEmail('a@b.co'), isTrue);
    expect(looksLikeEmail('ab.co'), isFalse);
    expect(payoutReady({'kyc': true}), isTrue);
    expect(payoutReady({}), isFalse);
    expect(defaultPayoutCountry('ZZ'), 'XX');
    expect(defaultPayoutCountry('CA'), 'CA');
  });
}
