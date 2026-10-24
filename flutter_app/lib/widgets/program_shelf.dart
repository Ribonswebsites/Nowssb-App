/// The shared pieces every program tab uses: a white-circle composing orb,
/// a glass line of text, and a sideways shelf of the program posters.
library;

import 'package:flutter/material.dart';

import '../features/programs/program_router.dart';
import '../shell/nav_shell.dart';

import 'glass_wrap.dart';
import 'nwsb_icon.dart';
import '../admin/template/editable.dart';

/// White circle with the section's own SVG. Never the composing animation.
class WhiteCircleOrb extends StatelessWidget {
  const WhiteCircleOrb({super.key, this.size = 18, this.mark = NwsbMarks.word});
  final double size;
  final String mark;

  @override
  Widget build(BuildContext context) {
    final circle = size + 16;
    return Container(
      width: circle,
      height: circle,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: NwsbIcon(mark, size: size, color: const Color(0xFF111111), strokeWidth: 1.7),
    );
  }
}

class GlassLine extends StatelessWidget {
  const GlassLine({super.key, required this.text, this.mark = NwsbMarks.word});
  final String text;
  final String mark;

  @override
  Widget build(BuildContext context) {
    return GlassWrap(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          WhiteCircleOrb(size: 18, mark: mark),
          const SizedBox(width: 10),
          Expanded(
            child: EditableLabel('program_shelf.GlassLine',
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

