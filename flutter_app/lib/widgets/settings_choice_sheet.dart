/// A Settings-styled picker: dark glass, a badge-headed pane, black rows,
/// and a white pill on the current choice. Used by Settings rows that have
/// more than one option, so a tap opens a list instead of flipping the value.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_list_card.dart';

class SettingsChoice<T> {
  const SettingsChoice({
    required this.value,
    required this.label,
    this.sub,
    this.icon,
  });

  final T value;
  final String label;
  final String? sub;
  final IconData? icon;
}

Future<T?> showSettingsChoiceSheet<T>({
  required BuildContext context,
  required IconData icon,
  required String overline,
  required String title,
  required T current,
  required List<SettingsChoice<T>> choices,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99000000),
    isScrollControlled: true,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: IntrinsicHeight(
            child: GlassListCard(
              key: const ValueKey('settings-choice-sheet'),
              margin: EdgeInsets.zero,
              icon: icon,
              overline: overline,
              title: title,
              children: [
                for (final choice in choices)
                  GlassTile(
                    key: ValueKey('settings-choice-${choice.label}'),
                    icon: choice.icon ?? icon,
                    title: choice.label,
                    sub: choice.sub,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(ctx).pop(choice.value);
                    },
                    trailing: choice.value == current
                        ? const _CurrentPill()
                        : const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: kGlassMuted,
                          ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CurrentPill extends StatelessWidget {
  const _CurrentPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child:
          const Icon(Icons.check_rounded, size: 16, color: Color(0xFF0B0B10)),
    );
  }
}
