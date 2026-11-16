import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// The same raised 18px marker and 3px connector language used by Essentials,
/// laid out horizontally so it can track the horizontal Get Started carousel.
///
/// A filled gold/orange node means that step is done. The card in view uses
/// the original orange gradient. Tapping a node jumps the carousel there.
class NmEssentialsProcessLine extends StatelessWidget {
  const NmEssentialsProcessLine(
      {super.key,
      required this.active,
      this.count = 7,
      this.done = const <int>{},
      this.glass = false,
      this.onTap});

  final int active;
  final int count;

  /// Indexes of the steps that are done.
  final Set<int> done;
  final bool glass;

  /// Tapping a step jumps the routine carousel to that card.
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          GestureDetector(
              key: ValueKey('routine-step-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: onTap == null ? null : () => onTap!(i),
              child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    key: ValueKey(
                        'routine-step-$i-${done.contains(i) ? 'done' : 'todo'}'),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: i == active
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFB44D), Color(0xFFFF8A3D)],
                            )
                          : (done.contains(i)
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFE2BD72),
                                    Color(0xFFC99A4A)
                                  ],
                                )
                              : null),
                      color: (i == active || done.contains(i))
                          ? null
                          : (glass
                              ? const Color(0xCCFFFFFF)
                              : const Color(0xFFECEEF2)),
                      border: glass && i != active && !done.contains(i)
                          ? Border.all(color: Colors.white, width: 1.2)
                          : null,
                      // Fashion / glass: flat nodes — no soft dark drop-shadow glow.
                      boxShadow: glass
                          ? null
                          : (i == active
                              ? const [
                                  BoxShadow(
                                      color: Color(0x339C6B30),
                                      blurRadius: 7,
                                      spreadRadius: 3),
                                  BoxShadow(
                                      color: Color(0x55000000),
                                      offset: Offset(3, 3),
                                      blurRadius: 6),
                                  BoxShadow(
                                      color: Colors.white,
                                      offset: Offset(-2, -2),
                                      blurRadius: 6),
                                ]
                              : NwsbShadows.raisedXs),
                    ),
                  ))),
          if (i != count - 1)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                color:
                    glass ? const Color(0x99FFFFFF) : const Color(0xFFC7CDD9),
              ),
            ),
        ],
      ],
    );
  }
}
