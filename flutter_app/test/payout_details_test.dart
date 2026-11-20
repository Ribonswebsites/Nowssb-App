// Bank / payout details: country-aware methods, the server's checks made
// first on the phone, and only masked numbers shown back.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nowssb/features/account/payout_details_page.dart';
import 'package:nowssb/features/account/payout_methods.dart';
import 'package:nowssb/features/economy/economy_api.dart';
import 'package:nowssb/media/video_pool.dart';

const _all = ['upi', 'bank_in', 'us_ach', 'gb_bank', 'iban', 'paypal', 'wise'];

void main() {
  group('validators', () {
    test('India', () {
      expect(checkIfsc('HDFC0001234'), isNull);
      expect(checkIfsc('hdfc0001234'), isNull);
      expect(checkIfsc('HDFC1001234'), isNotNull, reason: '5th character must be 0');
      expect(checkIndianAccount('123456789012'), isNull);
      expect(checkIndianAccount('12345'), isNotNull);
      expect(checkUpi('ana.ray@okhdfcbank'), isNull);
      expect(checkUpi('ana.ray'), isNotNull);
      expect(checkPan('ABCDE1234F'), isNull);
      expect(checkPan('ABCD1234F'), isNotNull);
    });
    test('US routing checksum and account', () {
      expect(checkRouting('021000021'), isNull); // JPMorgan Chase
      expect(checkRouting('011000015'), isNull); // Federal Reserve Boston
      expect(checkRouting('021000022'), isNotNull);
      expect(checkRouting('12345'), isNotNull);
      expect(checkUsAccount('000123456789'), isNull);
      expect(checkUsAccount('12'), isNotNull);
    });
    test('UK and IBAN', () {
      expect(checkSortCode('12-34-56'), isNull);
      expect(checkSortCode('12345'), isNotNull);
      expect(checkGbAccount('31926819'), isNull);
      expect(checkIban('GB29 NWBK 6016 1331 9268 19'), isNull);
      expect(checkIban('DE89370400440532013000'), isNull);
      expect(checkIban('DE89370400440532013001'), isNotNull);
      expect(checkIban('DE8937040044053201300'), isNotNull, reason: 'wrong length');
      expect(checkBic(''), isNull);
      expect(checkBic('DEUTDEFF'), isNull);
      expect(checkBic('DEUT'), isNotNull);
    });
    test('masking', () {
      expect(maskTail('123456789012'), '•••• 9012');
      expect(maskTail('12'), '••••');
    });
    test('methods per country and what the live server takes', () {
      expect(methodsForCountry('IN'), [PayoutMethod.upi, PayoutMethod.bankIn]);
      expect(methodsForCountry('US').first, PayoutMethod.usAch);
      expect(methodsForCountry('GB').first, PayoutMethod.gbBank);
      expect(methodsForCountry('DE').first, PayoutMethod.iban);
      expect(methodsForCountry('JP'), [PayoutMethod.paypal, PayoutMethod.wise]);
      // Older server: India UPI only, elsewhere PayPal / Wise email.
      expect(availableMethods('IN', null), [PayoutMethod.upi]);
      expect(availableMethods('DE', null), [PayoutMethod.paypal, PayoutMethod.wise]);
      expect(availableMethods('IN', _all), [PayoutMethod.upi, PayoutMethod.bankIn]);
    });
  });

  group('page', () {
    late List<(String, Map<String, dynamic>)> calls;
    Map<String, dynamic> account = {};

    setUp(() {
      VideoPool.debugDeadlines = false; // the page's film backdrop
      SharedPreferences.setMockInitialValues({});
      calls = [];
      account = {'methods': _all};
      EconomyApi.debugHandler = (name, data) async {
        calls.add((name, data));
        if (name == 'savePayoutAccount') {
          account = {
            'methods': _all,
            'country': data['country'],
            'method': data['method'],
            'legalName': data['legalName'],
            'masked': '•••• ${('${data['accountNumber'] ?? ''}').substring(('${data['accountNumber'] ?? ''}').length - 4)}',
            'bankLine': 'IFSC ${data['ifsc']}',
            'kyc': true,
          };
          return {'saved': true, 'kyc': true, 'message': 'Saved. Payouts go to this bank account after a review.'};
        }
        return {
          'countryOk': true,
          'payoutAccount': {...account, if (!account.containsKey('country')) 'country': 'IN'},
          'balances': {'pendingINR': 420, 'availableINR': 0, 'minPayoutINR': 1250, 'payoutDay': 10},
          'lock': {'holdDays': 30},
        };
      };
    });
    tearDown(() => EconomyApi.debugHandler = null);

    testWidgets('India bank account: checks, saves once, shows it masked', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: PayoutDetailsPage()));
      await tester.pump();
      await tester.pump();
      expect(find.text('Bank / payout details'), findsOneWidget);
      expect(find.byKey(const Key('payout-method-upi')), findsOneWidget);
      await tester.tap(find.byKey(const Key('payout-method-bank_in')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('payout-holder')), 'Ana Ray');
      await tester.enterText(find.byKey(const Key('payout-account')), '123456789012');
      await tester.enterText(find.byKey(const Key('payout-account2')), '123456789000');
      await tester.enterText(find.byKey(const Key('payout-ifsc')), 'HDFC1234');
      await tester.enterText(find.byKey(const Key('payout-pan')), 'ABCDE1234F');
      await tester.tap(find.byKey(const Key('payout-save')));
      await tester.pump();
      expect(find.text('The two account numbers don’t match.'), findsOneWidget);
      expect(find.text('IFSC is 11 characters, like HDFC0001234.'), findsOneWidget);
      expect(calls.where((c) => c.$1 == 'savePayoutAccount'), isEmpty);

      await tester.enterText(find.byKey(const Key('payout-account2')), '123456789012');
      await tester.enterText(find.byKey(const Key('payout-ifsc')), 'hdfc0001234');
      await tester.tap(find.byKey(const Key('payout-save')));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      final sent = calls.where((c) => c.$1 == 'savePayoutAccount').single.$2;
      expect(sent['method'], 'bank_in');
      expect(sent['accountNumber'], '123456789012');
      expect(sent['ifsc'], 'HDFC0001234');
      expect(sent['pan'], 'ABCDE1234F');
      expect(sent['country'], 'IN');
      expect(find.byKey(const Key('payout-saved-card')), findsOneWidget);
      expect(find.text('•••• 9012'), findsOneWidget);
      expect(find.textContaining('123456789012'), findsNothing, reason: 'the full number is never shown back');
      expect(find.byKey(const Key('payout-when')), findsOneWidget);
      expect(find.textContaining('10th'), findsOneWidget);
    });

    testWidgets('older server: India shows UPI only (no dead options)', (tester) async {
      account = {};
      await tester.binding.setSurfaceSize(const Size(412, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: PayoutDetailsPage()));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('payout-method-upi')), findsOneWidget);
      expect(find.byKey(const Key('payout-method-bank_in')), findsNothing);
      expect(find.byKey(const Key('payout-upi')), findsOneWidget);
    });
  });
}
