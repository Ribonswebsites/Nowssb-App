import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// The Get Started stepper: one node per step, joined by a line.
///
/// A node shows its number until that step is really done, then a check on
/// gold. The node of the card in view has a bright outline. Tapping a node
/// jumps the carousel to that step.
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

  static const gold = Color(0xFFE2BD72);

  @override
  Widget build(BuildContext context) {
    final idle = glass ? const Color(0x33FFFFFF) : const Color(0xFFC7CDD9);
    final ink = glass ? Colors.white : const Color(0xFF263142);
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          Semantics(
            button: true,
            selected: i == active,
            label: 'Step ${i + 1}${done.contains(i) ? ', done' : ''}',
            child: GestureDetector(
              key: ValueKey('routine-step-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: onTap == null ? null : () => onTap!(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: AnimatedContainer(
                  key: ValueKey('routine-step-$i-${done.contains(i) ? 'done' : 'todo'}'),
                  duration: const Duration(milliseconds: 240),
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done.contains(i)
                        ? gold
                        : (glass ? const Color(0x14FFFFFF) : const Color(0xFFECEEF2)),
                    border: Border.all(
                        color: i == active ? ink : (done.contains(i) ? gold : idle),
                        width: i == active ? 2 : 1.2),
                    boxShadow: glass ? null : NwsbShadows.raisedXs,
                  ),
                  child: done.contains(i)
                      ? const Icon(Icons.check_rounded, size: 15, color: Colors.black)
                      : Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: ink.withValues(alpha: i == active ? 1 : .6))),
                ),
              ),
            ),
          ),
          if (i != count - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: done.contains(i) && done.contains(i + 1) ? gold : idle,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
