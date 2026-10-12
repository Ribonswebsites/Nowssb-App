/// What NowssB does, one tile per feature, each opening the real page.
/// "Features" on Home lands here; "Customize" stays the widgets page.
library;

import 'package:flutter/material.dart';

import '../admin/layout/layout_sections.dart';
import '../admin/template/editable.dart';
import '../data/content.dart';
import '../features/economy/economy_theme.dart';
import '../features/programs/program_router.dart';
import '../shell/nwsb_links.dart';
import '../theme/tokens.dart';
import '../widgets/glass_black_card.dart';
import '../widgets/glass_wrap.dart';
import '../widgets/nwsb_icon.dart';
import 'healing_path.dart';
import 'progress/progress_screen.dart';
import 'sound_library.dart';
import 'widgets_page.dart';

class _Feature {
  const _Feature(this.id, this.title, this.line, this.mark, this.open);
  final String id;
  final String title;
  final String line;
  final String mark;
  final void Function(BuildContext) open;
}

void _push(BuildContext c, Widget p) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => p));

final _practice = <_Feature>[
  _Feature('player', 'Practice player', 'Listen to a word, say it aloud, sit with it. Each sitting counts toward your streak.', NwsbMarks.play24, (c) => NwsbLinks.tab(c, 1)),
  _Feature('library', 'Sound Library', 'Every recorded word, with its own voice and meaning.', NwsbMarks.sound, (c) => _push(c, const SoundLibraryScreen())),
  _Feature('progress', 'My Progress', 'Sessions, minutes, streak and this week at a glance.', NwsbMarks.bars, (c) => _push(c, PracticeProgressScreen(words: ContentStore.instance.library))),
  _Feature('healing', 'Healing Path', 'A guided path of words for the way you feel.', NwsbMarks.verified, (c) => _push(c, const HealingPathScreen())),
  _Feature('coach', 'Personal Coach', 'Ask about a word, a practice, or where to begin.', NwsbMarks.people, (c) => NwsbLinks.coach(c)),
  _Feature('reader', 'Reader', 'Read meanings and the science behind the words.', NwsbMarks.reader, (c) => NwsbLinks.reader(c)),
];

final _store = <_Feature>[
  _Feature('store', 'The Store', 'Words, bundles and the plans, priced by Google Play.', NwsbMarks.bag, (c) => NwsbLinks.tab(c, 3)),
  _Feature('meanings', 'Meanings', 'The full meaning of a word, to keep.', NwsbMarks.meaning, (c) => NwsbLinks.meanings(c)),
  _Feature('signatures', 'Signatures', 'Signature recordings for the words you love.', NwsbMarks.signature, (c) => NwsbLinks.signatures(c)),
  _Feature('ebooks', 'Ebooks', 'Long reads on practice and sound.', NwsbMarks.ebook, (c) => NwsbLinks.ebooks(c)),
  _Feature('plans', 'Plans', 'Resonance, Frequency and Frequency X.', NwsbMarks.crown, (c) => NwsbLinks.subscription(c)),
  _Feature('request', 'Request a word', 'Ask for a word that is not in the library yet.', NwsbMarks.word, (c) => NwsbLinks.requestWord(c)),
];

final _programmes = <_Feature>[
  _Feature('nowssb', 'NowssB', 'Ranks, coupons, gifts and your link. One page.', NwsbMarks.piggy, (c) => Programmes.open(c, Programme.earn)),
  _Feature('partner', 'Partner Program', 'Milestones and perks. Never cash.', NwsbMarks.crown, (c) => Programmes.open(c, Programme.partner)),
];

final _you = <_Feature>[
  _Feature('customize', 'Customize', 'Hero header, widgets and how Home looks.', NwsbMarks.sliders, (c) => _push(c, const WidgetsPage())),
  _Feature('connect', 'Connect', 'The Echo Wall: posts from people on NowssB.', NwsbMarks.connectPair, (c) => NwsbLinks.connect(c)),
  _Feature('saved', 'Saved words', 'The words you kept for later.', NwsbMarks.wishlist, (c) => NwsbLinks.saved(c)),
  _Feature('about', 'About NowssB', 'What NowssB is and how the practice works.', NwsbMarks.features, (c) => _push(c, const AboutNowssbScreen())),
];

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EconomyPage(
      title: 'Features',
      mark: NwsbMarks.features,
      showBalance: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(UiSpace.lg, UiSpace.sm, UiSpace.lg, 48),
        children: layoutChildren(context, 'features', [
          const LSection('intro', 'Intro', _Intro()),
          LSection('practice', 'Practice', _Group(eyebrow: 'PRACTICE', title: 'Listen, say, sit', items: _practice)),
          LSection('store', 'Store', _Group(eyebrow: 'STORE', title: 'Words to keep', items: _store)),
          LSection('programmes', 'Programmes', _Group(eyebrow: 'PROGRAMMES', title: 'Coins, gifts and links', items: _programmes)),
          LSection('you', 'You', _Group(eyebrow: 'YOURS', title: 'Make it yours', items: _you)),
        ]),
      ),
    );
  }
}

/// UD-2b: calm intro — type and whitespace only, no glow card.
class _Intro extends StatelessWidget {
  const _Intro();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(UiSpace.sm, UiSpace.xl, UiSpace.sm, UiSpace.xxl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EditableLabel('features_page.Intro', 'EVERYTHING IN NOWSSB', style: TextStyle(color: NwsbColors.gold, letterSpacing: 2.4, fontSize: 11, fontWeight: FontWeight.w600)),
          SizedBox(height: UiSpace.md),
          EditableLabel('features_page.Intro', 'One tap to every part of the app', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600, height: 1.2)),
          SizedBox(height: UiSpace.md),
          EditableLabel('features_page.Intro', 'Each tile opens its own page. Customize how Home looks from the Customize tile.', style: UiType.body),
        ]),
      );
}

/// UD-2b: one quiet glass-framed black card per group, rows with hairline
/// dividers instead of a grid of identical tiles.
class _Group extends StatelessWidget {
  const _Group({required this.eyebrow, required this.title, required this.items});
  final String eyebrow;
  final String title;
  final List<_Feature> items;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: UiSpace.xxl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(UiSpace.sm, 0, UiSpace.sm, UiSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EditableLabel('features_page.Group', eyebrow, style: const TextStyle(color: NwsbColors.gold, letterSpacing: 2.2, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: UiSpace.xs),
              EditableLabel('features_page.Group', title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
            ]),
          ),
          GlassBlackCard(
            radius: UiRadii.lg,
            padding: const EdgeInsets.symmetric(vertical: UiSpace.xs),
            child: Column(children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, thickness: 1, indent: 64, endIndent: UiSpace.lg, color: Color(0x14FFFFFF)),
                _Tile(items[i]),
              ],
            ]),
          ),
        ]),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.f);
  final _Feature f;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => f.open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: UiSpace.lg, vertical: UiSpace.lg),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          NwsbIcon(f.mark, size: 20, color: NwsbColors.goldLight),
          const SizedBox(width: UiSpace.xl),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EditableLabel('features_page.${f.id}', f.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: UiSpace.xs),
              EditableLabel('features_page.${f.id}', f.line, maxLines: 2, overflow: TextOverflow.ellipsis, style: UiType.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0)),
            ]),
          ),
          const SizedBox(width: UiSpace.md),
          const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0x66FFFFFF)),
        ]),
      ),
    );
  }
}

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
      cta: 'See every feature',
      onCta: () => _push(context, const FeaturesPage()),
    ));
    final sci = LSection('science', 'Word Science', _Prose(
      eyebrow: 'WORD SCIENCE',
      title: 'Why a word, said aloud',
      body: const [
        'Each word is recorded so you can hear how it is meant to sound, then repeat it in your own voice.',
        'The Reader carries the meaning and background of each word, so practice and understanding go together.',
        'Your progress page shows what you practised, for how long, and how steady the week has been.',
      ],
      cta: 'Open the Reader',
      onCta: () => NwsbLinks.reader(context),
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
  const _Prose({required this.eyebrow, required this.title, required this.body, required this.cta, required this.onCta});
  final String eyebrow;
  final String title;
  final List<String> body;
  final String cta;
  final VoidCallback onCta;

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
          const SizedBox(height: 6),
          GoldButton(label: cta, onTap: onCta),
        ]),
      );
}
