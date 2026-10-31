/// Lucky draw on/off switch. Off unless the admin console sets the remote
/// flag `lucky_draw_enabled` to true in config/app `flags` (AppControl).
/// Keep it off until the server's draw endpoints are live.
library;

import 'package:flutter/widgets.dart';

import '../../data/app_control.dart';

const kLuckyDrawFlag = 'lucky_draw_enabled';

/// True only when the remote flag is explicitly on.
bool isLuckyDrawEnabled() => AppControl.instance.flag(kLuckyDrawFlag, fallback: false);

Future<bool> luckyDrawAvailable() async => isLuckyDrawEnabled();

/// Shows [child] only while the draw is switched on; otherwise nothing.
/// Rebuilds live when the flag changes.
class LuckyDrawGate extends StatelessWidget {
  const LuckyDrawGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppControl.instance,
    builder: (_, __) => isLuckyDrawEnabled() ? child : const SizedBox.shrink(),
  );
}
