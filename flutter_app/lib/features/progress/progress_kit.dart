/// Shared look for the Today's progress and Quests pages: the Settings /
/// Sound Library family — app film behind, GlassWrap panes opened by a round
/// glass badge with an SVG mark, black cards inside.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_icon.dart';

/// SVG bodies for the goal marks (NwsbIcon draws them).
abstract final class GoalMarks {
  static const check = '<rect x="3.5" y="3.5" width="17" height="17" rx="5"/><path d="M8 12.4l2.8 2.8L16.4 9.4"/>';
  static const tasks = '<path d="M4 6.5l1.8 1.8L9 5"/><path d="M12 7h8"/><path d="M4 12.5l1.8 1.8L9 11"/><path d="M12 13h8"/><path d="M4 18.5l1.8 1.8L9 17"/><path d="M12 19h8"/>';
  static const practice = '<path d="M5 9v6"/><path d="M9 6v12"/><path d="M13 9v6"/><path d="M17 4v16"/><path d="M21 10v4"/>';
  static const coins = '<path d="M12 3l7.5 4.3v9.4L12 21l-7.5-4.3V7.3z"/><path d="M12 8v8"/><path d="M9.6 10.2h3.6a1.4 1.4 0 0 1 0 2.8h-2.4a1.4 1.4 0 0 0 0 2.8h3.6"/>';
  static const quest = '<path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z"/>';
  static const checkin = '<rect x="4" y="5" width="16" height="15" rx="3"/><path d="M8 3v4"/><path d="M16 3v4"/><path d="M8.5 13.5l2.4 2.4 4.6-4.8"/>';
  static const next = '<path d="M5 12h13"/><path d="M13 6l6 6-6 6"/>';
}

/// A GlassWrap pane with the badge heading.
class GoalSection extends StatelessWidget {
  const GoalSection({super.key, required this.mark, required this.eyebrow, required this.title, required this.children, this.trailing});
  final String mark;
  final String eyebrow;
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          GoalBadge(mark: mark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(eyebrow, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, color: Color(0x99FFFFFF), height: 1.2)),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2, letterSpacing: -0.4)),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class GoalBadge extends StatelessWidget {
  const GoalBadge({super.key, required this.mark, this.size = 46});
  final String mark;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x2EFFFFFF)),
        ),
        child: Center(child: NwsbIcon(mark, size: size * 0.46)),
      );
}

/// Black card with a press-in.
class GoalCard extends StatefulWidget {
  const GoalCard({super.key, required this.child, this.onTap, this.margin = const EdgeInsets.only(bottom: 10)});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  var _down = false;
  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      scale: _down ? 0.98 : 1,
      duration: const Duration(milliseconds: 110),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x24FFFFFF))),
        child: widget.child,
      ),
    );
    return Padding(
      padding: widget.margin,
      child: widget.onTap == null
          ? card
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _down = true),
              onTapCancel: () => setState(() => _down = false),
              onTapUp: (_) => setState(() => _down = false),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
              child: card,
            ),
    );
  }
}

/// Gold pill action ("Check in", "Open tasks").
class GoalAction extends StatelessWidget {
  const GoalAction({super.key, required this.label, required this.onTap, this.filled = true, this.busy = false});
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final on = onTap != null && !busy;
    return TextButton(
      onPressed: on
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      style: TextButton.styleFrom(
        backgroundColor: filled ? (on ? NwsbColors.goldLight : const Color(0x33E8D5A3)) : Colors.transparent,
        foregroundColor: filled ? Colors.black : NwsbColors.goldLight,
        disabledForegroundColor: filled ? const Color(0x99000000) : const Color(0x80E8D5A3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: filled ? Colors.transparent : const Color(0x66E8D5A3))),
      ),
      child: busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

/// Flat gold bar (the Daily tasks bar).
class GoalBar extends StatelessWidget {
  const GoalBar({super.key, required this.value, this.height = 6});
  final double value;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(value: value.clamp(0.0, 1.0), minHeight: height, color: NwsbColors.gold, backgroundColor: const Color(0x33FFFFFF)),
      );
}
