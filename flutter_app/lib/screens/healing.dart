/// Personalised Healing — the ten-category path.
library;

import 'package:flutter/material.dart';

import '../data/content.dart';
import '../widgets/page_shell.dart';
import 'word_detail.dart';

class HealingScreen extends StatelessWidget {
  const HealingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final words = ContentStore.instance.library;
    return PageShell(
      eyebrow: 'Choose your health journey',
      title: 'Healing Path',
      film: 'assets/video/healing-path-bg.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.list(children: [
            const DarkHead(
              eyebrow: 'Ten categories, matched to the body',
              title: 'The path',
              icon: Icons.favorite_border,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in [
                  'Fitness',
                  'Heart',
                  'Skin & Glow',
                  'Gut',
                  'Liver',
                  'Mind',
                  'Hormones',
                  'Immunity',
                  'Breath',
                  'Balance',
                ])
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x14FFFFFF)),
                    ),
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xCCFFFFFF))),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const DarkHead(
              eyebrow: 'Words on this path',
              title: 'The library',
              icon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 14),
            for (final w in words)
              WordRow(
                word: w.word,
                deva: w.deva,
                sub: w.organ.isNotEmpty ? w.organ : w.meaning,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => WordDetail(word: w)),
                ),
              ),
          ]),
        ),
      ],
    );
  }
}
