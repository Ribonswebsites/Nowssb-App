/// RB2-signature (Oct 12, FINAL-FINAL): Signature Store.
///
/// Layout from the Nykaa "Spotlight Picks" ref (one banner, centred caps
/// heading, picks grid). Colours, page film and media are the ORIGINAL ones
/// from main 235ae99: player-bg-loop film, the signature-store-hero film via
/// StorePixelsHero, the Signature word art and kMsSignatureImg. Every card
/// is frosted glass like the Store home cards (store-keep/).
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../theme/tokens.dart';
import '../../widgets/banner_mix.dart';
import '../../widgets/colored_split_promo_banner.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/hype_rail.dart';
import 'product_detail.dart';
import 'store_cards.dart';
import 'store_home_sections.dart';
import 'store_routes.dart';
import 'store_select_sheet.dart';
import '../../widgets/sections/artist_cards_section.dart';
import 'store_routes.dart';
import 'store_terms_sheet.dart';
import 'request_words.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';

const _slot = 'signature_store.SignatureBody';

/// Public entry; Store home tiles open `const SignatureStoreScreen()`.
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
              sliver: SliverList.list(children: const [_SignatureBody()]),
            ),
          ],
        ),
      );
}

void _openWord(BuildContext context, RmSignatureEntry s) => openAtelierWord(
      context,
      word: s.name,
      root: 'Most Exclusive',
      img: s.img,
      signature: true,
    );

class _SignatureBody extends StatelessWidget {
  const _SignatureBody();

  @override
  Widget build(BuildContext context) {
    final words =
        kRmCategories.where((c) => c.signature != null).map((c) => c.signature!).toList();
    final half = (words.length / 2).ceil();
    final w1 = words.take(half).toList();
    final w2 = words.skip(half).toList();
    final meanings = kMsSignature.entries.toList();
    final mh = (meanings.length / 2).ceil();
    final m1 = meanings.take(mh).toList();
    final m2 = meanings.skip(mh).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // rb2.* ids: saved layouts of the old mix match nothing.
      children: layoutChildren(context, 'store.signature', [
        LSection(
          'rb2.hero',
          'Signature hero',
          _KeepCard(
            media: const StorePixelsHero(
              videoAsset: 'assets/video/signature-store-hero.mp4',
              videoTitle: '',
            ),
            eyebrow: 'SIGNATURE · RAREST',
            title: 'Owned once',
            icon: Icons.auto_awesome_outlined,
            onTap: words.isEmpty ? null : () => _openWord(context, words.first),
            trailing: const _InfoButton(),
          ),
        ),
        const SizedBox(height: 36),
        LSection('rb2.picks', 'Spotlight picks', _Picks(words: words)),
        const SizedBox(height: 36),
        const LSection('rb2.meanings', 'Signature meanings', _Meanings()),
        const SizedBox(height: 36),
        LSection(
          'rb2.request',
          'Request a Signature',
          _KeepCard(
            media: AspectRatio(
              aspectRatio: 16 / 9,
              child: EditableImage.asset(kMsSignatureImg,
                  slot: _slot,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: NwsbColors.plate)),
            ),
            eyebrow: 'MADE FOR YOU',
            title: 'Request a Signature',
            icon: Icons.edit_note_rounded,
            onTap: () => openRequestWords(context),
          ),
        ),
      ]),
    );
  }
}

/// The Store-home card: frosted glass, an inset media banner, then one black
/// row with an icon, a caps eyebrow, a short title and an arrow.
class _KeepCard extends StatelessWidget {
  const _KeepCard({
    required this.media,
    required this.eyebrow,
    required this.title,
    required this.icon,
    this.onTap,
    this.trailing,
  });
  final Widget media;
  final String eyebrow, title;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => GlassBlackCard(
        padding: const EdgeInsets.all(UiSpace.sm),
        radius: UiRadii.lg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(UiRadii.md),
            child: media,
          ),
          const SizedBox(height: UiSpace.sm),
          Material(
            color: const Color(0xFF07080C),
            borderRadius: BorderRadius.circular(UiRadii.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(UiRadii.md),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0x14FFFFFF)),
                    child: Icon(icon, size: 20, color: NwsbColors.goldLight),
                  ),
                  const SizedBox(width: UiSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EditableLabel(_slot, eyebrow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiType.caption.copyWith(letterSpacing: 1.6)),
                        const SizedBox(height: 2),
                        EditableLabel(_slot, title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                  trailing ??
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.arrow_forward_rounded,
                            color: Color(0xCCFFFFFF), size: 20),
                      ),
                ]),
              ),
            ),
          ),
        ]),
      );
}

class _InfoButton extends StatelessWidget {
  const _InfoButton();
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'About Signatures',
        icon: const Icon(Icons.info_outline_rounded, color: Color(0xCCE8D5A3)),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          backgroundColor: NwsbColors.plate,
          builder: (_) => const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: StoreDisclaimer(
              text:
                  'Signatures are one-of-a-kind. Owned once, never restocked. For educational and wellness purposes only.',
            ),
          ),
        ),
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: UiSpace.lg),
        child: EditableLabel(_slot, text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
                color: NwsbColors.gold)),
      );
}

class _Picks extends StatefulWidget {
  const _Picks({required this.words});
  final List<RmSignatureEntry> words;
  @override
  State<_Picks> createState() => _PicksState();
}

class _PicksState extends State<_Picks> {
  bool _all = false;
  @override
  Widget build(BuildContext context) {
    final shown = _all ? widget.words : widget.words.take(6).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Heading('SPOTLIGHT PICKS'),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: UiSpace.md,
        crossAxisSpacing: UiSpace.md,
        childAspectRatio: 0.78,
        children: [
          for (final s in shown)
            GlassBlackCard(
              padding: const EdgeInsets.all(UiSpace.xs),
              radius: UiRadii.card,
              onTap: () => _openWord(context, s),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(UiRadii.sm),
                        child: StoreNetImage(url: s.img, word: s.name),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                      child: Row(children: [
                        Expanded(
                          child: Text(s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                        Text(inr(kMsSignaturePrice),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: NwsbColors.goldLight)),
                      ]),
                    ),
                  ]),
            ),
        ],
      ),
      if (widget.words.length > 6)
        Center(
          child: TextButton(
            onPressed: () => setState(() => _all = !_all),
            child: Text(_all ? 'Show less' : 'Show all ${widget.words.length}',
                style: const TextStyle(
                    color: NwsbColors.goldLight, fontWeight: FontWeight.w700)),
          ),
        ),
    ]);
  }
}

class _Meanings extends StatelessWidget {
  const _Meanings();
  @override
  Widget build(BuildContext context) {
    final list = kMsSignature.entries.toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Heading('DECODED MEANINGS'),
      GlassBlackCard(
        padding: const EdgeInsets.symmetric(horizontal: UiSpace.lg),
        child: Column(children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0x14FFFFFF)),
            InkWell(
              onTap: () => openMeaningDetail(
                context,
                MsMeaning(
                  word: list[i].value.word,
                  key: list[i].value.key,
                  root: list[i].value.root,
                  category: list[i].key,
                  price: kMsSignaturePrice,
                  img: kMsSignatureImg,
                ),
                signature: true,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(children: [
                  Expanded(
                    child: Text(list[i].value.word,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0x80E8D5A3)),
                ]),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }
}
