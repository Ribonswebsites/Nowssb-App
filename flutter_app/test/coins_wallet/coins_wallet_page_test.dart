import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nowssb/features/coins/wallet/coins_flag.dart';
import 'package:nowssb/features/coins/wallet/coins_wallet_data.dart';
import 'package:nowssb/features/coins/wallet/coins_wallet_page.dart';

class _Src implements CoinsWalletSource {
  _Src(this.f);
  final Future<CoinsWalletState> Function() f;
  @override
  Future<CoinsWalletState> load() => f();
}

Widget _app(CoinsWalletSource s) => MaterialApp(home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true, size: Size(400, 900)), child: CoinsWalletPage(source: s)));

final _full = CoinsWalletState(balance: 500, worthLabel: '\$5.00', expiringSoon: 40,
    expiresOn: DateTime.now().add(const Duration(days: 5)), ledger: [
  LedgerEntry(kind: LedgerKind.earned, amount: 10, label: 'Check-in', at: DateTime(2026)),
  LedgerEntry(kind: LedgerKind.spent, amount: 100, label: 'Word', at: DateTime(2026)),
  LedgerEntry(kind: LedgerKind.expired, amount: 5, label: 'Expired', at: DateTime(2026)),
]);

void main() {
  test('flag: off for users by default, on for admins, on when flag set', () {
    expect(newUiCoinsEnabled(isAdmin: false, flags: {}), isFalse);
    expect(newUiCoinsEnabled(isAdmin: true, flags: {}), isTrue);
    expect(newUiCoinsEnabled(isAdmin: false, flags: {kNewUiCoinsFlag: true}), isTrue);
  });

  test('calculator respects cap and balance', () {
    final a = CoinCalc.of(price: 10, balance: 1000, capPercent: 35);
    expect(a.coinsUsable, 350);
    expect(a.youPay, closeTo(6.5, 1e-9));
    final b = CoinCalc.of(price: 10, balance: 100, capPercent: 35);
    expect(b.coinsUsable, 100);
    expect(b.youPay, closeTo(9.0, 1e-9));
    expect(CoinCalc.of(price: 0, balance: 5, capPercent: 35).coinsUsable, 0);
  });

  test('ledger parsing', () {
    expect(LedgerEntry.fromMap({'amount': -20}).kind, LedgerKind.spent);
    expect(LedgerEntry.fromMap({'amount': 5, 'kind': 'expired'}).kind, LedgerKind.expired);
    expect(LedgerEntry.fromMap({'amount': 5}).kind, LedgerKind.earned);
  });

  testWidgets('loading then ready', (t) async {
    final c = Completer<CoinsWalletState>();
    await t.pumpWidget(_app(_Src(() => c.future)));
    expect(find.byKey(const Key('coins_loading')), findsOneWidget);
    c.complete(_full);
    await t.pumpAndSettle();
    expect(find.text('500'), findsOneWidget);
    expect(find.textContaining('Worth up to \$5.00'), findsOneWidget);
    expect(find.byKey(const Key('coins_expiry')), findsOneWidget);
    expect(find.byKey(const Key('coins_boost')), findsOneWidget);
  });

  testWidgets('empty state', (t) async {
    await t.pumpWidget(_app(_Src(() async => const CoinsWalletState(balance: 0))));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('coins_empty')), findsOneWidget);
  });

  testWidgets('error state with retry', (t) async {
    var n = 0;
    await t.pumpWidget(_app(_Src(() async {
      if (n++ == 0) throw StateError('x');
      return _full;
    })));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('coins_error')), findsOneWidget);
    await t.tap(find.text('Try again'));
    await t.pumpAndSettle();
    expect(find.text('500'), findsOneWidget);
  });

  testWidgets('offline state', (t) async {
    await t.pumpWidget(_app(_Src(() async => throw const SocketException('no net'))));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('coins_offline')), findsOneWidget);
  });

  testWidgets('Earn, Use calculator, History filters', (t) async {
    await t.pumpWidget(_app(_Src(() async => _full)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('coins_earn')));
    await t.pumpAndSettle();
    expect(find.textContaining('Check in today, +10 coins'), findsOneWidget);
    Navigator.of(t.element(find.byKey(const Key('coins_earn_sheet')))).pop();
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('coins_use')));
    await t.pumpAndSettle();
    expect(find.text('Coins you can use: 350, You pay: \$6.50'), findsOneWidget);
    await t.enterText(find.byKey(const Key('coins_price_field')), '1');
    await t.pump();
    expect(find.text('Coins you can use: 35, You pay: \$0.65'), findsOneWidget);
    Navigator.of(t.element(find.byKey(const Key('coins_use_sheet')))).pop();
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('coins_history')));
    await t.pumpAndSettle();
    expect(find.text('Word'), findsOneWidget);
    await t.tap(find.byKey(const Key('coins_filter_earned')));
    await t.pumpAndSettle();
    expect(find.text('Word'), findsNothing);
    expect(find.text('Check-in'), findsOneWidget);
  });
}
