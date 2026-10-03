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
  _Feature('rewards', 'NowssB Rewards', 'Daily coins, streaks, quests, season and leagues.', NwsbMarks.rewards, (c) => Programmes.open(c, Programme.rewards)),
  _Feature('coupons', 'NowssB Coupons', 'Your daily scratch card and coupon tickets.', NwsbMarks.coupon, (c) => Programmes.open(c, Programme.coupons)),
  _Feature('gifts', 'NowssB Gifts', 'Free gift boxes, gift cards, send and redeem.', NwsbMarks.gift, (c) => Programmes.open(c, Programme.gifts)),
  _Feature('reference', 'NowssB Reference', 'Your links: friends get a discount, you get rewards.', NwsbMarks.reference, (c) => Programmes.open(c, Programme.reference)),
  _Feature('earn', 'NowssB Earn', 'Ranks, team, sales and payouts.', NwsbMarks.piggy, (c) => Programmes.open(c, Programme.earn)),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
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

class _Intro extends StatelessWidget {
  const _Intro();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1B1408), Color(0xFF000000)]),
          border: Border.all(color: const Color(0x66E4C56A)),
          boxShadow: const [BoxShadow(color: Color(0x33E4C56A), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EditableLabel('features_page.Intro', 'EVERYTHING IN NOWSSB', style: TextStyle(color: NwsbColors.gold, letterSpacing: 1.6, fontSize: 11, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          EditableLabel('features_page.Intro', 'One tap to every part of the app', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          EditableLabel('features_page.Intro', 'Each tile opens its own page. Customize how Home looks from the Customize tile.', style: TextStyle(color: NwsbColors.mist, height: 1.35)),
        ]),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.eyebrow, required this.title, required this.items});
  final String eyebrow;
  final String title;
  final List<_Feature> items;

  @override
  Widget build(BuildContext context) => GlassWrap(
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          EditableLabel('features_page.Group', eyebrow, style: const TextStyle(color: NwsbColors.gold, letterSpacing: 1.4, fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          EditableLabel('features_page.Group', title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 10) / 2;
            return Wrap(spacing: 10, runSpacing: 10, children: [for (final f in items) SizedBox(width: w, child: _Tile(f))]);
          }),
        ]),
      );
}

class _Tile extends StatefulWidget {
  const _Tile(this.f);
  final _Feature f;
  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final f = widget.f;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => f.open(context),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 132,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _down ? const Color(0xAAE4C56A) : const Color(0x29FFFFFF)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1FE4C56A)),
              alignment: Alignment.center,
              child: NwsbIcon(f.mark, size: 18, color: NwsbColors.goldLight),
            ),
            const SizedBox(height: 8),
            EditableLabel('features_page.${f.id}', f.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
            const SizedBox(height: 3),
            Expanded(
              child: EditableLabel('features_page.${f.id}', f.line, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NwsbColors.mist, fontSize: 11.5, height: 1.3)),
            ),
          ]),
        ),
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
