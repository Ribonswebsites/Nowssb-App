/// Feature flag `newui_rewards` via the shared kit ([NewUi]): remote on →
/// everyone; otherwise admins only. The old Rewards page stays live for users.
library;

import 'package:flutter/material.dart';

import '../../kit/feature_flags.dart';
import '../vault/vault_screen.dart';
import 'rewards_page.dart';

const kNewUiRewardsFlag = 'newui_rewards';

bool newUiRewardsOn({bool? isAdmin, bool? flag}) =>
    (isAdmin == null && flag == null) ? NewUi.isOn('rewards') : NewUi.decide(NewUiInputs(isAdmin: isAdmin ?? false, remote: flag));

class RewardsEntry extends StatelessWidget {
  const RewardsEntry({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: NewUi.listenable,
        builder: (_, __) => newUiRewardsOn() ? const RewardsNewUiPage() : const VaultScreen(),
      );
}
