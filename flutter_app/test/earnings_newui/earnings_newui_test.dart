import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/kit/kit.dart';
import 'package:nowssb/nowssb_ui/nowssb_ui.dart';
import 'package:nowssb/pages/earnings/earnings_models.dart';
import 'package:nowssb/pages/earnings/earnings_page.dart';

String fmt(int c, {String? locale}) => '€${(c / 100).toStringAsFixed(2)}';

class FakeProvider implements PayoutProvider {
  String? onboarded;
  int payouts = 0;
  @override
  String get name => 'Wise';
  @override
  List<PayoutCountry> get countries => kPayoutCountries;
  @override
  Future<KitResult<PayoutOnboarding>> onboard(String country) async {
    onboarded = country;
    return const KitOk(PayoutOnboarding(message: 'Finish setup with Wise'));
  }
  @override
  Future<KitResult<Json>> requestPayout() async { payouts++; return const KitOk(<String, dynamic>{}); }
}

const ready = EarningsData(status: EarningsStatus.ready, balanceCents: 4250, rows: [
  EarningRow(kind: EarningKind.sale, title: 'Word sale: Serenity', cents: 1200, isNew: true),
  EarningRow(kind: EarningKind.commission, title: 'Commission', cents: 3050, status: 'credited'),
  EarningRow(kind: EarningKind.payout, title: 'Payout', cents: 2000, status: 'failed'),
]);

Widget app(EarningsData d, PayoutProvider p) => MaterialApp(home: MediaQuery(
    data: const MediaQueryData(size: Size(390, 2400), disableAnimations: true),
    child: EarningsNewUiPage(data: d, provider: p, money: fmt, background: const ColoredBox(color: Colors.black))));

void main() {
  setUp(NewUi.resetForTest);
  Future<void> tall(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(390, 2400));
    addTearDown(() => t.binding.setSurfaceSize(null));
  }

  test('flag is on by default for everyone', () {
    expect(NewUi.decide(const NewUiInputs(isAdmin: false, remote: null)), isTrue);
  });

  testWidgets('loading', (t) async {
    await t.pumpWidget(app(const EarningsData(), FakeProvider()));
    expect(find.byKey(const ValueKey('earnings-loading')), findsOneWidget);
  });
  testWidgets('empty', (t) async {
    await tall(t);
    await t.pumpWidget(app(const EarningsData(status: EarningsStatus.empty), FakeProvider()));
    expect(find.text('No earnings yet'), findsOneWidget);
  });
  testWidgets('error and offline and signed out', (t) async {
    await t.pumpWidget(app(const EarningsData(status: EarningsStatus.error), FakeProvider()));
    expect(find.text('Could not load earnings'), findsOneWidget);
    await t.pumpWidget(app(const EarningsData(status: EarningsStatus.offline), FakeProvider()));
    expect(find.text('You are offline'), findsOneWidget);
    await t.pumpWidget(app(const EarningsData(status: EarningsStatus.signedOut), FakeProvider()));
    expect(find.text('Sign in to see earnings'), findsOneWidget);
  });
  testWidgets('ready: kit MeditationCard, local currency, no INR, filter', (t) async {
    await tall(t);
    await t.pumpWidget(app(ready, FakeProvider()));
    expect(find.byType(MeditationCard), findsWidgets);
    expect(find.textContaining('€42.50'), findsOneWidget);
    expect(find.textContaining('₹'), findsNothing);
    expect(find.byType(EarningTicketRow), findsNWidgets(3));
    expect(find.byType(ExpiredOverlay), findsOneWidget);
    await t.ensureVisible(find.text('Payouts'));
    await t.pumpAndSettle();
    await t.tap(find.text('Payouts'));
    await t.pump();
    expect(find.byType(EarningTicketRow), findsOneWidget);
  });
  testWidgets('withdraw calls the provider', (t) async {
    final p = FakeProvider();
    await t.pumpWidget(app(ready, p));
    await t.tap(find.text('Withdraw'));
    await t.pump();
    expect(p.payouts, 1);
  });
  testWidgets('payout setup sends only the chosen country', (t) async {
    final p = FakeProvider();
    await t.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: PayoutSetupSheet(provider: p, onDone: (_) {})))));
    expect(find.textContaining('PAN'), findsNothing);
    expect(find.textContaining('UPI'), findsNothing);
    await t.tap(find.byKey(const ValueKey('country-DE')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('payout-continue')));
    await t.pump();
    expect(p.onboarded, 'DE');
  });
}
