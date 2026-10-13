import 'package:flutter/material.dart';

import '../widgets/app_backdrop.dart';

/// The app's original background (AppBackdrop: the same video the home and
/// other screens use) behind a rebuilt page. No gradient, orbs or shapes.
class NAppBackdrop extends StatelessWidget {
  const NAppBackdrop({super.key, this.child});
  final Widget? child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const Positioned.fill(child: IgnorePointer(child: AppBackdrop())),
        if (child != null) child!,
      ]);
}
