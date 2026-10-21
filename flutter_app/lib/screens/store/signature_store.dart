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
import '../../widgets/app_backdrop.dart';
import '../../widgets/home_skin.dart';
import '../../widgets/home_parts.dart';
import '../../media/nwsb_video.dart';
import '../fashion/header.dart';
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
import '../../widgets/n_motion.dart';

class SignatureStoreScreen extends StatelessWidget {
  const SignatureStoreScreen({super.key});

  /// Styled like NowssB Home: Home's backdrop film and veil, Home's top bar,
  /// dark-glass section panes, 3D banners and Enter/Shop pills.
  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'signature',
        head: 'Signatures described by sound',
        child: Scaffold(
          backgroundColor: NwsbColors.deep,
          body: Stack(
            children: [
              const Positioned.fill(child: AppBackdrop()),
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.1),
                        radius: 0.88,
                        colors: [Color(0x00000000), Color(0x24000000), Color(0x57000000), Color(0x94000000)],
                        stops: [0.30, 0.58, 0.80, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  HomeHeader(
                    onMenu: () => showStoreSelectSheet(
                      context,
                      current: 'signature',
                      onSelect: (id) => openStoreFromPicker(context, id, current: 'signature'),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 48),
                      children: [
                        Row(children: [
                          IconButton(
                            key: const ValueKey('sig-back'),
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          ),
                          const Expanded(
                            child: Text('The Signature Store',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        const SignatureBody(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
  const SignatureBody({super.key, this.autoGuide = true, this.showRooms = true, this.banners = true});

  /// Plays the 3D banner films (off in tests).
  final bool banners;

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
    showNSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xF20B0B12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: NwsbColors.goldLight.withValues(alpha: 0.55)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.lock_rounded, color: NwsbColors.goldLight),
                const SizedBox(width: 8),
                _RarityPill(d.$2),
              ]),
              const SizedBox(height: 14),
              Text(d.$1,
                  style: const TextStyle(
                      color: NwsbColors.goldLight,
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
                  child: GestureDetector(
                    key: ValueKey('sig-tab-$t'),
                    onTap: () => setState(() => _tab = t),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: _tab == t ? Colors.white : const Color(0xFF0B0B12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: _tab == t ? Colors.white : const Color(0x24FFFFFF)),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _tab == t ? Colors.black : NwsbColors.goldLight)),
                    ),
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
          const SizedBox(height: 4),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SignatureRxCard(
            banner: widget.banners,
            words: [for (final w in words.take(2)) (w.name, 'Most exclusive')],
            onWord: (i) => openAtelierWord(context, word: words[i].name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true),
            onEnter: () => setState(() => _tab = 'Words'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SectionPane(child: _header()),
        ),
        if (show('Upcoming')) SignaturePane(eyebrow: 'Upcoming drops', child: _upcoming()),
        if (show('Words'))
        SignaturePane(
          eyebrow: 'Signature words',
          onShop: words.isEmpty ? null : () => storeBuyNow(context, wordBagItem(name: words.first.name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true)),
          child: RoutineDeck(
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
                image: storeSubjectArt(s.name),
                flip: storeWaveFor(s.name),
                onTap: () => openAtelierWord(context, word: s.name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true),
                onCart: () => storeAddToCart(context, wordBagItem(name: s.name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true)),
                onBuy: () => storeBuyNow(context, wordBagItem(name: s.name, root: 'Most Exclusive', img: kNowssbStoreMark, signature: true)),
              ),
          ],
        ),
        ),
        if (show('Meanings'))
        SignaturePane(
          eyebrow: 'Signature meanings',
          child: RoutineDeck(
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
                    image: storeSubjectArt(row.$1),
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

/// The Signature hero, built like Home's NowssB Prescription card: 3D fiery
/// banner, gold eyebrow, italic quote, two black word tiles in gold and a
/// "Tap word to practice" row with an Enter pill.
class SignatureRxCard extends StatelessWidget {
  const SignatureRxCard({super.key, required this.words, this.onWord, this.onEnter, this.banner = true});
  final List<(String, String)> words;
  final void Function(int index)? onWord;
  final VoidCallback? onEnter;
  final bool banner;

  @override
  Widget build(BuildContext context) => SectionPane(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRect(
                child: banner
                    ? const NwsbVideo(asset: 'assets/video/rx-banner.mp4', slot: 'signature_store.SignatureRxCard')
                    : const ColoredBox(color: Color(0xFF2A0E06)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Container(width: 9, height: 9, color: NwsbColors.goldLight),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('NOWSSB SIGNATURE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700, color: NwsbColors.goldLight)),
                    ),
                    const Text('Most exclusive', style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
                  ]),
                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0x14FFFFFF)),
                  const SizedBox(height: 14),
                  const Text('"A word crafted only for you — your mark, delivered within 48 hours."',
                      style: TextStyle(fontSize: 13.5, fontStyle: FontStyle.italic, color: Color(0xCCFFFFFF), height: 1.5)),
                  const SizedBox(height: 16),
                  Row(children: [
                    for (var i = 0; i < words.length && i < 2; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          key: ValueKey('sig-rx-word-$i'),
                          onTap: () => onWord?.call(i),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 96,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B0B12),
                              border: Border.all(color: const Color(0x14FFFFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(words[i].$1.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: NwsbColors.goldLight)),
                                const SizedBox(height: 4),
                                Text(words[i].$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Color(0xB3FFFFFF))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Expanded(
                      child: Text('Tap word to practice',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Color(0x8CFFFFFF))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14141C),
                        border: Border.all(color: const Color(0x24FFFFFF)),
                      ),
                      child: EnterPill(key: const ValueKey('sig-rx-enter'), onTap: onEnter),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      );
}

/// A dark-glass Home pane with a gold eyebrow and a Shop pill.
class SignaturePane extends StatelessWidget {
  const SignaturePane({super.key, required this.eyebrow, required this.child, this.onShop});
  final String eyebrow;
  final Widget child;
  final VoidCallback? onShop;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: SectionPane(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(width: 9, height: 9, color: NwsbColors.goldLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(eyebrow.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700, color: NwsbColors.goldLight)),
                ),
                if (onShop != null) EnterPill(label: 'Shop', onTap: onShop),
              ]),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      );
}
