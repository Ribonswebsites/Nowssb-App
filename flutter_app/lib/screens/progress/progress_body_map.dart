/// Body & Mind section — bodymap.svg + organ chips.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models.dart';
import '../../data/practice_progress.dart';
import 'progress_tokens.dart';

const _chips = [
  'Brain & Mind',
  'Lungs & Breath',
  'Heart & Energy',
  'Core & Digestion',
  'Liver & Detox',
  'Immune System',
  'Nervous System',
  'Skin & Eyes',
  'Vitality & Hormones',
  'Joints & Mobility',
];

class ProgressBodyMap extends StatelessWidget {
  const ProgressBodyMap({super.key, required this.progress, required this.words});
  final PracticeProgress progress;
  final List<Word> words;

  @override
  Widget build(BuildContext context) {
    final practiced = progress.sessionsSnapshot
        .map((s) => '${s['word'] ?? ''}')
        .where((w) => w.isNotEmpty)
        .toSet();
    final organs = words
        .where((w) => practiced.contains(w.word) && w.organ.isNotEmpty)
        .map((w) => w.organ.toLowerCase())
        .toSet();

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 520;
        final visual = ProgressGlass(
          radius: 25,
          child: SizedBox(
            height: narrow ? 300 : 360,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Plain SVG like website <img src=bodymap.svg> — no srcIn
                // ColorFilter (that flattens multi-stop / organ fills).
                Opacity(
                  opacity: organs.isEmpty ? 0.72 : 0.98,
                  child: SvgPicture.asset(
                    'assets/icons/bodymap.svg',
                    width: 170,
                    height: 270,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => const SizedBox(
                      width: 170,
                      height: 270,
                      child: Center(child: Icon(Icons.accessibility_new, color: Color(0x66FFFFFF), size: 48)),
                    ),
                  ),
                ),
                const Positioned(
                  left: 18,
                  right: 18,
                  bottom: 28,
                  child: Text(
                    'Explore the areas you want to understand and improve through your practice.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, height: 1.55, color: Color(0xFFA2A7A8)),
                  ),
                ),
              ],
            ),
          ),
        );

        final chips = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in _chips)
              _Chip(
                label: label,
                lit: organs.any((o) => label.toLowerCase().contains(o.split(' ').first) || o.contains(label.split(' ').first.toLowerCase())),
              ),
          ],
        );

        if (narrow) {
          return Column(children: [visual, const SizedBox(height: 12), chips]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: visual),
            const SizedBox(width: 12),
            Expanded(flex: 1, child: chips),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.lit});
  final String label;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x7A000000),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: lit ? Colors.white.withOpacity(0.28) : const Color(0x1AFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lit ? MpColors.gold : const Color(0xFF606365),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: lit ? MpColors.white : const Color(0xFFBFC3C4),
            ),
          ),
        ],
      ),
    );
  }
}
