import 'package:flutter/material.dart';
import '../../../admin/admin_state.dart';
import '../../../data/app_control.dart';
import 'coins_flag.dart';
import 'coins_wallet_page.dart';
import 'economy_wallet_source.dart';

/// Route entry: shows the new wallet when `newui_coins` is on (admins always),
/// otherwise the existing [legacy] page. Wire into the route registry once
/// Bug Hunter's registry lands.
class CoinsWalletEntry extends StatelessWidget {
  const CoinsWalletEntry({super.key, required this.legacy, this.onOpenBoost});
  final Widget legacy;
  final VoidCallback? onOpenBoost;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([AppControl.instance, AdminState.instance]),
        builder: (_, __) => newUiCoinsEnabled()
            ? CoinsWalletPage(source: EconomyWalletSource(), onOpenBoost: onOpenBoost)
            : legacy,
      );
}
