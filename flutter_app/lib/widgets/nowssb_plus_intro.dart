/// Full-bleed intro for NowssB Plus.
///
/// The poster fills the screen, edge to edge, and a glass pane at the foot
/// holds the short copy and the enter pill. Enter opens the page underneath,
/// same as the old intro gate — it does not flip the motion switch by itself.
library;

import 'package:flutter/material.dart';

import 'restyle_kit.dart';

class NowssbPlusIntro extends StatelessWidget {
  const NowssbPlusIntro({super.key, required this.child, this.onBack});

  /// What is underneath, revealed when Enter is pressed.
  final Widget child;

  final VoidCallback? onBack;

  static const art = 'assets/fashion/nowssb-plus-intro.webp';

  static const copy =
      'Turns on motion backgrounds on the Zen home tiles and pages. '
      'It uses more battery. You can switch it off in Settings > Zen Plus.';

  void _open(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => child));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          Positioned.fill(
            child: Image.asset(
              art,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x59000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x99000000),
                      Color(0xF2000000),
                    ],
                    stops: [0, 0.14, 0.46, 0.72, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: KitBackButton(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
                const Spacer(),
                GlassWrap(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHead(
                        eyebrow: 'NowssB Plus',
                        title: 'Motion on the Zen home',
                        mark: NwsbMarks.play,
                      ),
                      const Text(
                        copy,
                        style: TextStyle(
                          color: kKitMuted,
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      KitActionPill(
                        'Enter NowssB Plus',
                        onTap: () => _open(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
