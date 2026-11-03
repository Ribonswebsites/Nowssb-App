/// R27 sections and pages wired to live data and real screens.
/// NowssB Earn: one section opening its real page (Circle).
library;

import 'package:flutter/material.dart';

import '../../../features/economy/economy_api.dart';
import '../../../features/circle/circle_screen.dart';
import 'data.dart';
import 'sections.dart';

void _push(BuildContext c, Widget w) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => w));

class _Live extends StatelessWidget {
  const _Live({required this.builder});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: EconomyMirror.instance, builder: (c, _) => builder(c));
}

// ── sections (both homes) ──
class R27LiveSections extends StatelessWidget {
  const R27LiveSections({super.key, this.fashion = false});
  final bool fashion;
  @override
  Widget build(BuildContext context) => _Live(builder: (c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        R27EarnSection(
            key: ValueKey('r27-earn-$fashion'),
            fashion: fashion,
            data: R27Live.earn(),
            onOpen: () => _push(c, const CircleScreen()),
            onRank: (_) => _push(c, const CircleScreen())),
      ]));
}
