/// Feature flag `newui_rewards`: OFF for users, ON for admins, until Ribon
/// approves. The old Rewards page (VaultScreen) stays live otherwise.
library;

import 'package:flutter/material.dart';

import '../../admin/admin_state.dart';
import '../../data/app_control.dart';
import '../vault/vault_screen.dart';
import 'rewards_page.dart';

const kNewUiRewardsFlag = 'newui_rewards';

bool newUiRewardsOn({bool? isAdmin, bool? flag}) =>
    (isAdmin ?? AdminState.instance.isAdmin) || (flag ?? AppControl.instance.flag(kNewUiRewardsFlag, fallback: false));

/// Drop-in for `Programme.rewards` in the route registry.
class RewardsEntry extends StatelessWidget {
  const RewardsEntry({super.key});
  @override
  Widget build(BuildContext context) => newUiRewardsOn() ? const RewardsNewUiPage() : const VaultScreen();
}
