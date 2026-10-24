import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../widgets/app_backdrop.dart';

/// The app's original background (AppBackdrop: the same video the home and
/// other screens use) behind a rebuilt page. No gradient, orbs or shapes.
class NAppBackdrop extends StatelessWidget {
  const NAppBackdrop({super.key, this.child});
  final Widget? child;
  /// Widget tests have no video plugin and VideoPool leaves an 8 s timeout
  /// timer pending, so under `flutter test` draw AppBackdrop's still colour.
  static final bool _inTest = !const bool.fromEnvironment('dart.library.js_util') &&
      Platform.environment.containsKey('FLUTTER_TEST');
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Positioned.fill(child: IgnorePointer(child: _inTest ? const ColoredBox(color: Color(0xFF08090B)) : const AppBackdrop())),
        if (child != null) child!,
      ]);
}
