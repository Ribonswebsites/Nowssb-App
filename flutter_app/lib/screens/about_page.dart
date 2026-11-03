/// About NowssB (Features page merged in, Nov 2 cleanup).
library;

import 'package:flutter/material.dart';

import '../admin/layout/layout_sections.dart';
import '../admin/template/editable.dart';
import '../data/content.dart';
import '../features/economy/economy_theme.dart';
import '../features/programs/program_router.dart';
import '../shell/nwsb_links.dart';
import '../theme/tokens.dart';
import '../widgets/glass_wrap.dart';
import '../widgets/routine_deck.dart';
import '../widgets/nwsb_icon.dart';
import 'store/meaning_store.dart';
import 'sound_library.dart';

/// About NowssB, with the Word Science explainer as its own section.
class AboutNowssbScreen extends StatelessWidget {
  const AboutNowssbScreen({super.key, this.science = false});

  /// Opened from a "Word Science" link: the science section leads.
  final bool science;

  @override
  Widget build(BuildContext context) {
    final about = LSection('about', 'About', _Prose(
      eyebrow: 'ABOUT',
      title: 'What NowssB is',
      body: const [
        'NowssB is a practice of words: you listen to a word in its own recorded voice, say it aloud, and sit with its meaning.',
        'The library holds the words; the store lets you keep meanings, signatures and ebooks; the plans open more of the library.',
        'Coins, coupons and gifts reward the practice itself. Coins have no cash value.',
      ],
    ));
    final sci = LSection('science', 'Word Science', _Prose(
      eyebrow: 'WORD SCIENCE',
      title: 'Why a word, said aloud',
      body: const [
        'Each word is recorded so you can hear how it is meant to sound, then repeat it in your own voice.',
        'Every word carries its meaning and background, so practice and understanding go together.',
        'Your progress page shows what you practised, for how long, and how steady the week has been.',
      ],
      cta: 'Open the Meaning Store',
      onCta: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MeaningStoreScreen())),
    ));
    return EconomyPage(
      title: science ? 'Word Science' : 'About NowssB',
      mark: NwsbMarks.features,
      showBalance: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: layoutChildren(context, 'about', science ? [sci, about] : [about, sci]),
      ),
    );
  }
}

class _Prose extends StatelessWidget {
  const _Prose({required this.eyebrow, required this.title, required this.body, this.cta, this.onCta});
  final String eyebrow;
  final String title;
  final List<String> body;
  final String? cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) => GlassWrap(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          EditableLabel('about.$eyebrow', eyebrow, style: const TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          EditableLabel('about.$eyebrow', title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final p in body)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EditableLabel('about.$eyebrow', p, style: const TextStyle(color: Color(0xDDFFFFFF), height: 1.45)),
            ),
          if (cta != null && onCta != null) ...[
            const SizedBox(height: 6),
            GoldButton(label: cta!, onTap: onCta!),
          ],
        ]),
      );
}
