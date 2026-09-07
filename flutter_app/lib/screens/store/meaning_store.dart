/// The Meaning Store — `.ms-grid` of `.ms-card` tiles + plain black banners.
/// Media matches index.html / app/js/part026.js (no collection photo banners).
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/intro_gate.dart';
import '../../widgets/page_shell.dart';
import 'product_detail.dart';
import 'store_cards.dart';

class MeaningStoreScreen extends StatelessWidget {
  const MeaningStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => IntroGate(
        tag: 'Shabdapathy · Origins',
        eyebrow: '',
        title: 'The Meaning Store',
        body: 'Base meanings, purchased words and AI-decoded origins — the truth behind the sound.',
        stats: const ['Base Meanings', 'AI-Decoded', 'Owned Forever'],
        art: 'assets/store/intro-meanings.webp',
        fullBleed: true,
        enterLabel: 'Enter The Meaning Store',
        onBack: () => Navigator.of(context).pop(),
        child: PageShell(
          eyebrow: 'NowssB Store',
          title: 'The Meaning Store',
          film: nwsbVideo(kStoreMeaningDoorVidFile),
          onBack: () => Navigator.of(context).pop(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              sliver: SliverList.list(children: const [_MeaningStoreBody()]),
            ),
          ],
        ),
      );
}

class _MeaningStoreBody extends StatefulWidget {
  const _MeaningStoreBody();
  @override
  State<_MeaningStoreBody> createState() => _MeaningStoreBodyState();
}

class _MeaningStoreBodyState extends State<_MeaningStoreBody> {
  final _search = TextEditingController();
  String _query = '';
  String _chip = 'ALL';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Prefer MS_BASE_MEANINGS card art from the catalogue. Live ContentStore
  /// may append unknown keys, but must not overwrite catalogue `img` URLs.
  List<MsMeaning> get _base {
    final live = ContentStore.instance.meanings;
    final byKey = {for (final m in kMsBaseMeanings) m.key: m};
    for (final m in live) {
      if (byKey.containsKey(m.key)) {
        final base = byKey[m.key]!;
        byKey[m.key] = MsMeaning(
          word: base.word,
          key: base.key,
          root: base.root,
          category: base.category,
          price: m.price > 0 ? m.price : base.price,
          img: base.img, // keep part026 per-meaning art
        );
      } else {
        byKey[m.key] = MsMeaning(
          word: m.name,
          key: m.key,
          root: m.sub.isNotEmpty ? m.sub : 'NowssB Meaning',
          category: 'Studio',
          price: m.price,
          img: m.img.isNotEmpty ? m.img : kMsCardImg,
        );
      }
    }
    return byKey.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = _base;
    final cats = <String, List<MsMeaning>>{};
    for (final m in all) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!m.word.toLowerCase().contains(q) &&
            !m.root.toLowerCase().contains(q) &&
            !m.category.toLowerCase().contains(q)) {
          continue;
        }
      }
      if (_chip != 'ALL' && m.category != _chip) continue;
      (cats[m.category] ??= []).add(m);
    }
    final order = [
      'Elements',
      'Human',
      'Emotions',
      'Cosmos',
      'Nations & People',
      ...cats.keys.where((k) => !const {'Elements', 'Human', 'Emotions', 'Cosmos', 'Nations & People'}.contains(k)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NwsbVideo(
                  asset: nwsbVideo(kStoreMeaningDoorVidFile),
                  priority: ClipPriority.feature,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22060C18), Color(0xE6060C18)],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'The Meaning Store',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Subscribe video banner — same clip as index / part026.
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NwsbVideo(
                  asset: nwsbVideo(kMsSubscribeVidFile),
                  priority: ClipPriority.decoration,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xAA060C18), Color(0x22060C18)],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xEE060C18),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: const Color(0x33E8D5A3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: Image.network(
                              kMsSubscribePillIcon,
                              width: 22,
                              height: 22,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 22, height: 22),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Subscribe Today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: NwsbColors.goldLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: StoreSearchBar(
            controller: _search,
            hint: 'Search meanings…',
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              StoreFilterChip(label: 'ALL', selected: _chip == 'ALL', onTap: () => setState(() => _chip = 'ALL')),
              const SizedBox(width: 7),
              for (final c in ['Elements', 'Human', 'Emotions', 'Cosmos', 'Nations & People']) ...[
                StoreFilterChip(label: c.toUpperCase(), selected: _chip == c, onTap: () => setState(() => _chip = c)),
                const SizedBox(width: 7),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final cat in order)
          if (cats[cat]?.isNotEmpty == true) ...[
            RmCatBanner(
              title: cat,
              sub: kMsCatSub[cat] ?? 'Decoded origins',
              logoUrl: kMsCatLogoUrl,
              logoAsset: kRmCatLogoAsset,
            ),
            MsGrid(
              children: [
                for (final m in cats[cat]!)
                  MsCard(
                    word: m.word,
                    root: m.root,
                    imgUrl: m.img,
                    price: m.price,
                    onTap: () => openMeaningDetail(context, m),
                  ),
                if (kMsSignature.containsKey(cat) && _query.isEmpty)
                  MsCard(
                    word: kMsSignature[cat]!.word,
                    root: kMsSignature[cat]!.root,
                    imgUrl: kMsSignatureImg,
                    price: kMsSignaturePrice,
                    signature: true,
                    onTap: () => openMeaningDetail(
                      context,
                      MsMeaning(
                        word: kMsSignature[cat]!.word,
                        key: kMsSignature[cat]!.key,
                        root: kMsSignature[cat]!.root,
                        category: cat,
                        price: kMsSignaturePrice,
                        img: kMsSignatureImg,
                      ),
                      signature: true,
                    ),
                  ),
              ],
            ),
          ],
        if (cats.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('No meanings match.', style: TextStyle(color: Color(0x8CFFFFFF)))),
          ),
        const StoreDisclaimer(
          text:
              'Meanings shared or sold here are for educational and wellness purposes only — nothing here is medical advice. Purchases are final once unlocked.',
        ),
      ],
    );
  }
}
