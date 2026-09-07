/// Signature Store — rarest words + meanings with gold Signature tags.
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/intro_gate.dart';
import '../../widgets/page_shell.dart';
import 'product_detail.dart';
import 'store_cards.dart';

class SignatureStoreScreen extends StatelessWidget {
  const SignatureStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => IntroGate(
        tag: 'Shabdapathy · The Rarest',
        eyebrow: '',
        title: 'Words & Meanings',
        body: 'One per category. Owned once, never restocked.',
        stats: const ['15 Words', '5 Meanings', 'Never Restocked'],
        art: 'assets/store/intro-signature.webp',
        fullBleed: true,
        enterLabel: 'Enter Signature Store',
        onBack: () => Navigator.of(context).pop(),
        child: PageShell(
          eyebrow: 'NowssB Store',
          title: 'Words & Meanings',
          film: 'assets/video/signature-store.mp4',
          onBack: () => Navigator.of(context).pop(),
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
    final words = kRmCategories.where((c) => c.signature != null).map((c) => c.signature!).toList();
    final half = (words.length / 2).ceil();
    final w1 = words.take(half).toList();
    final w2 = words.skip(half).toList();
    final meanings = kMsSignature.entries.toList();
    final mh = (meanings.length / 2).ceil();
    final m1 = meanings.take(mh).toList();
    final m2 = meanings.skip(mh).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const NwsbVideo(
                  asset: 'assets/video/signature-store.mp4',
                  poster: 'assets/video/signature-store-poster.webp',
                  priority: ClipPriority.feature,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33060C18), Color(0xEE060C18)],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SHABDAPATHY · THE RAREST', style: TextStyle(fontSize: 10, letterSpacing: 2.2, color: NwsbColors.gold)),
                        SizedBox(height: 6),
                        Text('Words & Meanings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const RmCatBanner(
          title: 'Signature Words',
          sub: 'One per collection — the rarest word each one has',
        ),
        RmWordRow(
          children: [
            for (final s in w1)
              RmWordCard(
                name: s.name,
                root: 'Most Exclusive',
                imgUrl: s.img,
                signature: true,
                price: kMsSignaturePrice,
                onTap: () => openAtelierWord(context, word: s.name, root: 'Most Exclusive', img: s.img, signature: true),
              ),
          ],
        ),
        if (w2.isNotEmpty) ...[
          const RmCatBanner(
            title: 'Signature Words · II',
            sub: 'The rest of the collection',
          ),
          RmWordRow(
            children: [
              for (final s in w2)
                RmWordCard(
                  name: s.name,
                  root: 'Most Exclusive',
                  imgUrl: s.img,
                  signature: true,
                  price: kMsSignaturePrice,
                  onTap: () => openAtelierWord(context, word: s.name, root: 'Most Exclusive', img: s.img, signature: true),
                ),
            ],
          ),
        ],
        const RmCatBanner(
          title: 'Signature Meanings',
          sub: 'The full decoded origin, not the base entry',
        ),
        MsGrid(
          children: [
            for (final e in m1)
              MsCard(
                word: e.value.word,
                root: e.value.root,
                imgUrl: kMsSignatureImg,
                price: kMsSignaturePrice,
                signature: true,
                onTap: () => openMeaningDetail(
                  context,
                  MsMeaning(
                    word: e.value.word,
                    key: e.value.key,
                    root: e.value.root,
                    category: e.key,
                    price: kMsSignaturePrice,
                    img: kMsSignatureImg,
                  ),
                  signature: true,
                ),
              ),
          ],
        ),
        if (m2.isNotEmpty) ...[
          const RmCatBanner(
            title: 'Signature Meanings · II',
            sub: 'The rest of the collection',
          ),
          MsGrid(
            children: [
              for (final e in m2)
                MsCard(
                  word: e.value.word,
                  root: e.value.root,
                  imgUrl: kMsSignatureImg,
                  price: kMsSignaturePrice,
                  signature: true,
                  onTap: () => openMeaningDetail(
                    context,
                    MsMeaning(
                      word: e.value.word,
                      key: e.value.key,
                      root: e.value.root,
                      category: e.key,
                      price: kMsSignaturePrice,
                      img: kMsSignatureImg,
                    ),
                    signature: true,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Container(
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
                    Text('Signature · Words & Meanings', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: NwsbColors.gold)),
                    SizedBox(height: 4),
                    Text('Request a Signature', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 3),
                    Text('Personally crafted & delivered within 48 hours.', style: TextStyle(fontSize: 12, color: Color(0x8CFFFFFF))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const StoreDisclaimer(
          text: 'Signatures are one-of-a-kind. Owned once, never restocked. For educational and wellness purposes only.',
        ),
      ],
    );
  }
}
