/// Signature Store — rarest Signature words & meanings.
/// Same store family fixes: one-line subtitle, no double banner title,
/// taller subscribe + pill right-centre, Signature-appropriate labels.
library;

import 'package:flutter/material.dart';

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
import 'store_routes.dart';
import 'store_shelf.dart';
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
        film: 'assets/video/player-bg-loop.mp4',
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
            sliver: SliverList.list(children: const [_SignatureBody()]),
          ),
        ],
        ),
      );
}

class _SignatureBody extends StatelessWidget {
  const _SignatureBody();

  @override
  Widget build(BuildContext context) {
    final words =
        kRmCategories.where((c) => c.signature != null).map((c) => c.signature!).toList();
    final meanings = kMsSignature.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // Server-driven order (Admin → UI Editor); bundled order by default.
      children: layoutChildren(context, 'store.signature', [
        // Video hero — no stacked title overlay (header has subtitle).
        const LSection('hero', 'Hero film', StorePixelsHero(
          videoAsset: 'assets/video/signature-store-hero.mp4',
          videoTitle: '',
        )),
        const LSection('rooms', 'Store rooms', StoreRoomDeck(current: 'signature')),
        // UI-7 varied mix: artists → glassy → hype → spotlight (no two alike).
        LSection(
          'artists',
          'Signature artists',
          StoreMixRow(
            title: 'Rarest signatures',
            child: ArtistCardsSection(
              config: SignatureMix.artists,
              onTap: (item) {
                for (final c in kRmCategories) {
                  final s = c.signature;
                  if (s != null && s.key == item.id) {
                    openAtelierWord(
                      context,
                      word: s.name,
                      root: 'Most Exclusive',
                      img: s.img,
                      signature: true,
                    );
                    return;
                  }
                }
                storeMixOpenLink(context, item);
              },
            ),
          ),
        ),
        LSection(
          'glassy',
          'Explore the stores',
          StoreMixRow(
            title: 'Explore the stores',
            child: StoreRegistrySection(config: SignatureMix.glassy),
          ),
        ),
        LSection(
          'spotlight',
          'Signature spotlight',
          StoreRegistrySection(config: SignatureMix.spotlight),
        ),
        // Subscribe banner uses #3 only — never Signature hero film.
        const LSection('subscribe', 'Subscribe banner', StoreSubscribeBanner(
          videoAsset: StoreSubscribeBanner.kSubscriptionOfferVideo,
        )),
        StoreShelf(
          labels: const ['Signatures', 'Saved', 'Guides', 'Glass', 'Clear'],
          pieces: [
            for (final s in words)
              StorePiece(
                title: s.name,
                line: 'Most Exclusive',
                art: s.img,
                group: 'Language',
                onTap: () => openAtelierWord(context, word: s.name, root: 'Most Exclusive', img: s.img, signature: true),
              ),
            for (final e in meanings)
              StorePiece(
                title: e.value.word,
                line: e.value.root,
                art: kMsSignatureImg,
                group: storeGroup(e.value.word),
                onTap: () => openMeaningDetail(
                  context,
                  MsMeaning(word: e.value.word, key: e.value.key, root: e.value.root, category: e.key, price: kMsSignaturePrice, img: kMsSignatureImg),
                  signature: true,
                ),
              ),
            for (final row in kPlaceRows)
              StorePiece(
                title: row.$1,
                line: row.$2,
                art: kMsSignatureImg,
                group: row.$3,
                onTap: () => openAtelierWord(context, word: row.$1, root: row.$2, img: kMsSignatureImg),
              ),
          ],
        ),
        const SizedBox(height: 18),
        LSection('info', 'About signatures', Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x26E8D5A3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.add, color: NwsbColors.goldLight),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditableLabel('signature_store.SignatureBody', 'Signature · Request',
                        style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.5,
                            color: NwsbColors.gold)),
                    SizedBox(height: 4),
                    EditableLabel('signature_store.SignatureBody', 'Request a Signature',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    SizedBox(height: 3),
                    EditableLabel('signature_store.SignatureBody',
                      'Personally crafted & delivered within 48 hours.',
                      style:
                          TextStyle(fontSize: 12, color: Color(0x8CFFFFFF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 36),
        LSection('promo2', 'Promo banner', ColoredSplitPromoBanner(
          spec: SplitPromoExtras.at(10, onTap: () => openRequestWords(context)),
          margin: const EdgeInsets.only(bottom: 40),
        )),
        const LSection('mix', 'Banner mix', BannerMix(seed: 0)),
        const SizedBox(height: 12),
        LSection('promo3', 'Promo banner 2', ColoredSplitPromoBanner(
          spec: SplitPromoExtras.at(11, onTap: () => openRequestWords(context)),
        )),
        const LSection('disclaimer', 'Disclaimer', StoreDisclaimer(
          text:
              'Signatures are one-of-a-kind. Owned once, never restocked. For educational and wellness purposes only.',
        )),
      ]),
    );
  }
}
