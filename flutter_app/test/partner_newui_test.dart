import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/pages/partner/partner_home_page.dart';
import 'package:nowssb/pages/partner/partner_models.dart';
import 'package:nowssb/pages/partner/payout_provider.dart';

class _Repo implements PartnerRepository {
  _Repo(this.run);
  Future<PartnerData> Function() run;
  int calls = 0;
  @override
  Future<PartnerData> load() {
    calls++;
    return run();
  }
}

const _full = PartnerData(
  points: 120,
  perk: 'Silver',
  tier: 'Silver',
  toNextTier: 4,
  targets: [PartnerTarget(label: 'Basic subscriptions', goal: 50, done: 20, reward: 'Coins')],
  leaders: [PartnerLeader('Ava', 900)],
  referralLink: 'https://nowssb.app/r/abc',
  buyerDiscountUsdCents: 500,
);

const _empty = PartnerData(
  points: 0,
  perk: '',
  tier: 'Starter',
  toNextTier: 0,
  targets: [PartnerTarget(label: 'Basic subscriptions', goal: 50, done: 0, reward: 'Coins')],
  leaders: [],
  referralLink: '',
  buyerDiscountUsdCents: 0,
);

Widget _app(PartnerRepository r, {String cc = 'US'}) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: PartnerHomePage(repository: r, countryCode: cc),
      ),
    );

void main() {
  testWidgets('loading state', (t) async {
    final c = Completer<PartnerData>();
    await t.pumpWidget(_app(_Repo(() => c.future)));
    expect(find.byKey(const Key('partner-loading')), findsOneWidget);
    c.complete(_full);
    await t.pumpAndSettle();
  });

  testWidgets('empty state', (t) async {
    await t.pumpWidget(_app(_Repo(() async => _empty)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner-empty')), findsOneWidget);
  });

  testWidgets('error state retries', (t) async {
    var fail = true;
    final r = _Repo(() async => fail ? throw StateError('x') : _full);
    await t.pumpWidget(_app(r));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner-error')), findsOneWidget);
    fail = false;
    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner-hub')), findsOneWidget);
    expect(r.calls, 2);
  });

  testWidgets('offline state', (t) async {
    await t.pumpWidget(_app(_Repo(() async => throw const PartnerOfflineException())));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('partner-offline')), findsOneWidget);
  });

  testWidgets('hub shows points, targets, copy link, local discount, payout hand-off', (t) async {
    await t.pumpWidget(_app(_Repo(() async => _full), cc: 'DE'));
    await t.pumpAndSettle();
    expect(find.text('120'), findsOneWidget);
    expect(find.text('20 / 50 · Coins'), findsOneWidget);
    await t.tap(find.byKey(const Key('partner-copy')));
    await t.pump();
    expect(find.text('Link copied'), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const Key('partner-payout')), 200,
        scrollable: find.descendant(of: find.byKey(const Key('partner-hub')), matching: find.byType(Scrollable)).first);
    expect(find.textContaining('(DE)'), findsOneWidget);
    expect(find.textContaining('VAT ID'), findsOneWidget);
    expect(find.textContaining('₹'), findsNothing);
  });

  test('payout info is country-aware and never India-specific', () {
    final us = payoutInfoFor('us');
    expect(us.checks.any((c) => c.contains('W-9')), isTrue);
    final fr = payoutInfoFor('FR');
    expect(fr.checks.any((c) => c.contains('VAT')), isTrue);
    final jp = payoutInfoFor('JP');
    expect(jp.checks.every((c) => c.contains(kVerifyNote) || c.contains('onboarding')), isTrue);
    for (final c in [...us.checks, ...fr.checks, ...jp.checks]) {
      expect(c, isNot(matches(RegExp(r'UPI|PAN|Aadhaar|INR'))));
    }
  });
}
