/// Product detail sheets for Store catalogue items (Word / Meaning / Ebook).
/// Mirrors website rmd-* / ms-detail / ebd layouts without inventing copy.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../word_detail.dart';
import 'store_cards.dart';

void openAtelierWord(BuildContext context, {required String word, required String root, required String img, bool signature = false, num price = 49}) {
  final key = word.toLowerCase();
  final found = ContentStore.instance.library.where((w) => w.key == key || w.word.toLowerCase() == key).toList();
  if (found.isNotEmpty) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WordDetail(word: found.first)));
    return;
  }
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => StoreProductPage(
      kind: signature ? 'Signature Word' : 'Natural Origin',
      title: _titleCase(word),
      root: root,
      img: img,
      price: signature ? kMsSignaturePrice : price,
      about: signature
          ? 'The rarest word in its collection. One signature exists per collection, it is never discounted on its own, and it is never restocked.'
          : 'Every word carries a vibrational signature that predates its dictionary definition. Unlock the phonetic origin of ${_titleCase(word)} — what the sound does inside your body, and where it existed before anyone wrote it down.',
      highlights: const [
        'Native pronunciation audio, generated on demand',
        'Full phonetic root breakdown and origin story',
        'Permanent access — owned words never expire',
      ],
    ),
  ));
}

void openMeaningDetail(BuildContext context, MsMeaning m, {bool signature = false}) {
  final blurb = kMsWordBlurb[m.key] ??
      'Every word carries a vibration that predates its dictionary definition. Unlock the true phonetic origin of ${m.word}.';
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => StoreProductPage(
      kind: signature ? 'Signature Meaning' : 'Meaning · ${m.category}',
      title: signature ? m.word : m.word,
      root: m.root,
      // Always prefer catalogue / caller img — do not let live overlay swap art.
      img: signature ? kMsSignatureImg : m.img,
      price: signature ? kMsSignaturePrice : m.price,
      about: blurb,
      heroVideo: nwsbVideo(kMsMeaningVidFile),
      highlights: const [
        'Decoded phonetic origin',
        'Organ & vibration notes',
        'Owned forever once unlocked',
      ],
    ),
  ));
}

void openEbookDetail(BuildContext context, EbBook b) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => StoreProductPage(
      kind: 'NowssB Ebook',
      title: b.title,
      root: b.sub,
      img: b.cover,
      price: b.price,
      about: b.about,
      highlights: b.contents,
      disclaimer: kEbDisclaimer,
    ),
  ));
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

class StoreProductPage extends StatelessWidget {
  const StoreProductPage({
    super.key,
    required this.kind,
    required this.title,
    required this.root,
    required this.img,
    required this.price,
    required this.about,
    required this.highlights,
    this.disclaimer,
    this.heroVideo,
  });

  final String kind, title, root, img, about;
  final num price;
  final List<String> highlights;
  final String? disclaimer;

  /// Meaning detail hero clip (MS_MEANING_VID) — remote HTTPS URL.
  final String? heroVideo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NwsbColors.deep,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
                children: [
                  if (heroVideo != null) ...[
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: NwsbVideo(
                        asset: heroVideo!,
                        priority: ClipPriority.feature,
                      ),
                    ),
                    const SizedBox(height: 0),
                  ],
                  AspectRatio(
                    aspectRatio: 1,
                    child: StoreNetImage(url: img),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(kind.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 2.2, color: Color(0x8CC8E8F5), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)),
                        const SizedBox(height: 4),
                        Text(root, style: const TextStyle(fontSize: 12, color: Color(0x61FFFFFF))),
                        const SizedBox(height: 14),
                        Text(inr(price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: NwsbColors.goldLight)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _ActBtn(label: 'Wishlist', icon: Icons.favorite_border, filled: false, onTap: () {})),
                            const SizedBox(width: 10),
                            Expanded(child: _ActBtn(label: 'Add to Cart', icon: Icons.shopping_bag_outlined, filled: false, onTap: () {})),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _ActBtn(label: 'Buy Now', icon: Icons.lock_open, filled: true, onTap: () {}),
                        const SizedBox(height: 22),
                        const Text('ABOUT', style: TextStyle(fontSize: 9, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: Color(0x66FFFFFF))),
                        const SizedBox(height: 8),
                        Text(about, style: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xA6FFFFFF))),
                        const SizedBox(height: 22),
                        const Text("WHAT'S INCLUDED", style: TextStyle(fontSize: 9, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: Color(0x66FFFFFF))),
                        const SizedBox(height: 10),
                        for (final h in highlights)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check, size: 15, color: NwsbColors.goldLight),
                                const SizedBox(width: 10),
                                Expanded(child: Text(h, style: const TextStyle(fontSize: 12.5, color: Color(0x9EFFFFFF)))),
                              ],
                            ),
                          ),
                        if (disclaimer != null) ...[
                          const SizedBox(height: 16),
                          Text(disclaimer!, style: const TextStyle(fontSize: 11, height: 1.5, color: Color(0x66FFFFFF))),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActBtn extends StatelessWidget {
  const _ActBtn({required this.label, required this.icon, required this.filled, required this.onTap});
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: filled
              ? const LinearGradient(colors: [Color(0xF2E8D5A3), Color(0xE6C8A96E)])
              : null,
          color: filled ? null : const Color(0x14FFFFFF),
          border: filled ? null : Border.all(color: const Color(0x24FFFFFF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? NwsbColors.ink : const Color(0xB8FFFFFF)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: filled ? NwsbColors.ink : const Color(0xB8FFFFFF))),
          ],
        ),
      ),
    );
  }
}
