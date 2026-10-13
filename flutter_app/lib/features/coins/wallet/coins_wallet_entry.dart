import 'package:flutter/material.dart';
import '../../../kit/kit.dart';
import 'coins_wallet_page.dart';
import 'kit_wallet_source.dart';

/// Coins wallet screen as registered in the kit route registry
/// (`AppPage.coins`, gated by `newui_coins`).
Widget buildCoinsWallet(BuildContext context, RouteArgs args) => CoinsWalletPage(
      source: KitWalletSource(),
      onOpenBoost: () => AppRoutes.open(context, AppPage.coinsBoost, source: 'coins_wallet'),
    );

/// Standalone gate for callers outside the registry: new wallet while
/// `newui_coins` is on (admins by default), [legacy] otherwise.
class CoinsWalletEntry extends StatelessWidget {
  const CoinsWalletEntry({super.key, required this.legacy});
  final Widget legacy;
  @override
  Widget build(BuildContext context) => NewUiGate(
      page: 'coins', legacy: (_) => legacy, rebuilt: (c) => buildCoinsWallet(c, const RouteArgs()));
}
