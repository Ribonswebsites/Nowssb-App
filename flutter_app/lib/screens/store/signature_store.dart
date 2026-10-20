/// Signature Store — rarest Signature words & meanings.
/// Same store family fixes: one-line subtitle, no double banner title,
/// taller subscribe + pill right-centre, Signature-appropriate labels.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/glass_system.dart';

import '../../data/store_catalog.dart';
import '../../theme/tokens.dart';
import '../../widgets/banner_mix.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/page_shell.dart';
import 'product_detail.dart';
import 'store_cards.dart';
import 'store_home_sections.dart';
import 'store_section_mix.dart';
import 'store_select_sheet.dart';
import '../../widgets/sections/artist_cards_section.dart';
import 'store_actions.dart';
import 'store_art.dart';
import 'store_routes.dart';
import 'store_shelf.dart';
import '../../widgets/routine_deck.dart';
import 'store_terms_sheet.dart';
import 'request_words.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';

class SignatureStoreScreen extends StatelessWidget {
  const SignatureStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'signature',
        head: 'Signatures described by sound',
        child: PageShell(
        eyebrow: '',
        title: 'NowssB Store',
        subtitle: 'The Signature Store',
        film: 'assets/video/subscription-bg.mp4',
        usePageFilm: true,
        onBack: () => Navigator.of(context).pop(),
        onStorePicker: () => showStoreSelectSheet(
          context,
          current: 'signature',
          onSelect: (id) =>
              openStoreFromPicker(context, id, current: 'signature'),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            sliver: SliverList.list(children: const [SignatureBody()]),
          ),
        ],
        ),
      );
}

/// Tabs on the Signature page.
const kSignatureTabs = ['All', 'Words', 'Meanings', 'Places', 'Upcoming'];

/// Upcoming locked drops (name, rarity, drop label).
const kSignatureDrops = [
  ('Aurora', 'Legendary', 'Next drop'),
  ('Solace', 'Epic', 'Coming soon'),
  ('Lumen', 'Rare', 'Coming soon'),
];

const kSignatureGuide = [
  'Signature words are the rarest marks in NowssB: each one is crafted for you and delivered within 48 hours.',
  'Use the tabs to switch between Signature words, meanings, places and the upcoming drops.',
  'Tap a card to open it, the bag to add it to your cart, or Buy to check out now.',
  'Locked cards are upcoming drops. Tap one and choose Notify me to hear when it opens.',
  'Can\'t find your word? Tap Request a Signature and we\'ll craft it.',
];

Color signatureRarityColor(String rarity) => switch (rarity) {
      'Legendary' => const Color(0xFFE8C26A),
      'Epic' => const Color(0xFFC79BFF),
      _ => const Color(0xFF8FD3FF),
    };

class SignatureBody extends StatefulWidget {
  const SignatureBody({super.key, this.autoGuide = true, this.showRooms = true});

  /// The store room deck on top (off in isolated tests).
  final bool showRooms;

  /// Shows the first-use guide once the store terms are agreed.
  final bool autoGuide;

  @override
  State<SignatureBody> createState() => _SignatureBodyState();
}

class _SignatureBodyState extends State<SignatureBody> {
  String _tab = 'All';
  final Set<String> _notify = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _notify
      ..clear()
      ..addAll(prefs.getStringList('nwsb_signature_notify') ?? const []));
    if (!widget.autoGuide) return;
    final agreed = prefs.getString('nwsb_terms_signature') == '1';
    final seen = prefs.getBool('nwsb_signature_guide_seen') ?? false;
    if (agreed && !seen) {
      await prefs.setBool('nwsb_signature_guide_seen', true);
      if (mounted) _guide();
    }
  }

  void _guide() => PageGuide.show(context,
      title: 'How Signature works', lines: kSignatureGuide);

  Future<void> _toggleNotify(String name) async {
    final on = !_notify.contains(name);
    setState(() => on ? _notify.add(name) : _notify.remove(name));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('nwsb_signature_notify', _notify.toList());
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(on
            ? 'We\'ll let you know when $name opens.'
            : 'Reminder for $name turned off.')));
  }

  void _openDrop((String, String, String) d) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassWrapper(
          blur: true,
          radius: 28,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.lock_rounded, color: Colors.white70),
                const SizedBox(width: 8),
                _RarityPill(d.$2),
              ]),
              const SizedBox(height: 14),
              Text(d.$1,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('${d.$3}. This Signature is still locked. Turn on a reminder and we\'ll tell you the moment it opens.',
                  style: const TextStyle(color: Colors.white70, height: 1.4)),
              const SizedBox(height: 18),
              Row(children: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close',
                        style: TextStyle(color: Colors.white70))),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder()),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _toggleNotify(d.$1);
                  },
                  child: Text(_notify.contains(d.$1)
                      ? 'Stop reminder'
                      : 'Notify me'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final t in kSignatureTabs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: ValueKey('sig-tab-$t'),
                    label: Text(t),
                    selected: _tab == t,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                        color: _tab == t ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600),
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                    shape: const StadiumBorder(),
                    onSelected: (_) => setState(() => _tab = t),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 4, runSpacing: 0, children: [
            TextButton.icon(
              key: const ValueKey('sig-guide'),
              onPressed: _guide,
              icon: const Icon(Icons.help_outline_rounded, color: Colors.white70, size: 18),
              label: const Text('How it works', style: TextStyle(color: Colors.white)),
            ),
            TextButton.icon(
              key: const ValueKey('sig-request'),
              onPressed: () => openRequestWords(context),
              icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
              label: const Text('Request a Signature', style: TextStyle(color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 8),
        ],
      );

  Widget _upcoming() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 10),
            child: Text('Upcoming drops',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kSignatureDrops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _LockedCard(
                drop: kSignatureDrops[i],
                notify: _notify.contains(kSignatureDrops[i].$1),
                onTap: () => _openDrop(kSignatureDrops[i]),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );

  @override
  Widget build(BuildContext context) {
    bool show(String t) => _tab == 'All' || _tab == t;
    final words =
        kRmCategories.where((c) => c.signature != null).map((c) => c.signature!).toList();
    final meanings = kMsSignature.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // Server-driven order (Admin → UI Editor); bundled order by default.
      children: [
        if (widget.showRooms) const StoreRoomDeck(current: 'signature'),
        _header(),
        if (show('Upcoming')) _upcoming(),
        if (show('Words'))
        RoutineDeck(
          title: 'Signature words',
          banner: 'Most exclusive',
          bannerSub: 'The mark on a word',
          cards: [
            for (final s in words)
              WorkCard(
                category: 'Signature',
                title: s.name,
                meta: 'Most exclusive',
                action: 'Open',
                image: kNowssbStoreMark,
                flip: storeWaveFor(s.name),
                onTap: () => openAtelierWord(context, word: s.name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true),
                onCart: () => storeAddToCart(context, wordBagItem(name: s.name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true)),
                onBuy: () => storeBuyNow(context, wordBagItem(name: s.name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true)),
              ),
          ],
        ),
        if (show('Meanings'))
        RoutineDeck(
          title: 'Signature meanings',
          banner: 'Meanings',
          bannerSub: 'The mark on a meaning',
          cards: [
            for (final e in meanings)
              WorkCard(
                category: e.key,
                title: e.value.word,
                meta: e.value.root,
                action: 'Open',
                image: kMeaningsIcon,
                flip: storeMeaningFlip(e.value.word),
                onTap: () => openMeaningDetail(
                  context,
                  MsMeaning(word: e.value.word, key: e.value.key, root: e.value.root, category: e.key, price: kMsSignaturePrice, img: kNowssbStoreMark),
                  signature: true,
                ),
                onCart: () => storeAddToCart(context, meaningBagItem(word: e.value.word, root: e.value.root, img: kNowssbStoreMark, price: kMsSignaturePrice, signature: true)),
                onBuy: () => storeBuyNow(context, meaningBagItem(word: e.value.word, root: e.value.root, img: kNowssbStoreMark, price: kMsSignaturePrice, signature: true)),
              ),
          ],
        ),
        if (show('Places'))
        for (final group in const ['Countries', 'Capitals', 'Currency', 'Language'])
          RoutineDeck(
            title: group,
            banner: group,
            bannerSub: 'The ${group.toLowerCase()} row',
            cards: [
              for (final row in kPlaceRows)
                if (row.$3 == group)
                  WorkCard(
                    category: group,
                    title: row.$1,
                    meta: row.$2,
                    action: 'Open',
                    image: kNowssbStoreMark,
                    flip: storeWaveFor(row.$1),
                    onTap: () => openAtelierWord(context, word: row.$1, root: row.$2, img: kNowssbStoreMark),
                    onCart: () => storeAddToCart(context, wordBagItem(name: row.$1, root: row.$2, img: kNowssbStoreMark, signature: true)),
                    onBuy: () => storeBuyNow(context, wordBagItem(name: row.$1, root: row.$2, img: kNowssbStoreMark, signature: true)),
                  ),
            ],
          ),
      ],
    );
  }
}

class _RarityPill extends StatelessWidget {
  const _RarityPill(this.rarity);
  final String rarity;
  @override
  Widget build(BuildContext context) {
    final c = signatureRarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.withValues(alpha: 0.8)),
      ),
      child: Text(rarity,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// Tall portrait locked card: frosted glass, gold inner frame, rarity glow.
class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.drop, required this.notify, required this.onTap});
  final (String, String, String) drop;
  final bool notify;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glow = signatureRarityColor(drop.$2);
    return Semantics(
      button: true,
      label: 'Locked ${drop.$1}, ${drop.$2}',
      child: GestureDetector(
        key: ValueKey('sig-drop-${drop.$1}'),
        onTap: onTap,
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.35), blurRadius: 18)],
          ),
          child: GlassWrapper(
            radius: 26,
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8C26A).withValues(alpha: 0.85), width: 1.2),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RarityPill(drop.$2),
                  const Spacer(),
                  Center(child: Icon(Icons.lock_rounded, size: 40, color: Colors.white.withValues(alpha: 0.85))),
                  const Spacer(),
                  Text(drop.$1,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(notify ? 'Reminder on' : drop.$3,
                      style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
