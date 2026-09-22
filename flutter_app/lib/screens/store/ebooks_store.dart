/// NowssB Ebooks store — ebooks-only (not a Word Atelier / Meaning paste).
/// One hero/video max; no word mid-rail banner stacks; ebook icons only.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/colored_split_promo_banner.dart';
import 'product_detail.dart';
import 'store_actions.dart';
import 'store_cards.dart';
import 'store_home_sections.dart';
import 'store_select_sheet.dart';
import 'store_routes.dart';
import '../sound_library.dart';

class EbooksStoreScreen extends StatelessWidget {
  const EbooksStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => PageShell(
        eyebrow: 'NowssB Store',
        title: 'The NowssB Ebooks',
        film: 'assets/video/hero-ebooks.mp4',
        usePageFilm: false,
        onBack: () => Navigator.of(context).pop(),
        onStorePicker: () => showStoreSelectSheet(
          context,
          current: 'ebooks',
          onSelect: (id) =>
              openStoreFromPicker(context, id, current: 'ebooks'),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList.list(children: const [_EbooksBody()]),
          ),
        ],
      );
}

class _EbooksBody extends StatelessWidget {
  const _EbooksBody();

  List<EbBook> get _books {
    final live = ContentStore.instance.books;
    if (live.isEmpty) return kEbBooks;
    final keys = {for (final b in kEbBooks) b.key};
    final merged = [...kEbBooks];
    for (final b in live) {
      if (!keys.contains(b.key)) {
        merged.add(
          EbBook(
            key: b.key,
            title: b.title,
            sub: b.sub,
            price: b.price,
            cover: b.cover.isNotEmpty ? b.cover : kEbBooks.first.cover,
            about: b.sub,
            contents: const ['Published from the NowssB studio'],
          ),
        );
      }
    }
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final books = _books;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Single hero/video — no back-to-back promo / word-banner stacks.
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black,
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const NwsbVideo(
                  asset: 'assets/video/hero-ebooks.mp4',
                  poster: 'assets/video/hero-ebooks-poster.webp',
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
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'READ · LEARN · PRACTICE',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w700,
                                color: NwsbColors.goldLight,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'The NowssB Ebooks',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          kEbProductArt,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            kEbIntroArt,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(width: 56, height: 56),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Text(
          'Deep-dive guides on sound, phonetic origin and healing practice — '
          'yours to keep, read anywhere, forever. Not a word catalogue.',
          style: TextStyle(fontSize: 13, height: 1.6, color: Color(0x80FFFFFF)),
        ),
        const SizedBox(height: 18),
        _EbookBrowseStrip(
          onOpen: (b) => openEbookDetail(context, b),
          books: books,
        ),
        const SizedBox(height: 12),
        ColoredSplitPromoBanner.forSurface(
          SplitPromoSurface.ebooksStore,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SoundLibraryScreen(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final b in books) _EbookRow(book: b),
        StoreDisclaimer(text: kEbDisclaimer),
      ],
    );
  }
}

/// Unique ebook goal/browse strip — ebook picker art only, no word bag.
class _EbookBrowseStrip extends StatelessWidget {
  const _EbookBrowseStrip({required this.books, required this.onOpen});

  final List<EbBook> books;
  final void Function(EbBook book) onOpen;

  static const _goals = <(String, String, Color)>[
    ('Guides', kEbProductArt, Color(0xFF5CE1FF)),
    ('Origins', kEbIntroArt, Color(0xFFFFB74D)),
    ('Atlas', kEbProductArt, Color(0xFF81C784)),
    ('Practice', kEbIntroArt, Color(0xFFB388FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse ebooks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final g = _goals[i];
                return GestureDetector(
                  onTap: books.isEmpty ? null : () => onOpen(books[i % books.length]),
                  child: SizedBox(
                    width: 86,
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: g.$3, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: g.$3.withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              g.$2,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const ColoredBox(color: Color(0xFF0A0F1C)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          g.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EbookRow extends StatelessWidget {
  const _EbookRow({required this.book});
  final EbBook book;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openEbookDetail(context, book),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 92,
                    height: 120,
                    child: StoreNetImage(url: book.cover),
                  ),
                ),
                Container(
                  width: 1,
                  height: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: const Color(0x26FFFFFF),
                ),
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.sub,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0x8CFFFFFF),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          inr(book.price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: NwsbColors.goldLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              book.about,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.55,
                color: Color(0x73FFFFFF),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Add to Cart',
                  child: GestureDetector(
                    onTap: () {
                      storeAddToCart(
                        context,
                        ebookBagItem(
                          title: book.title,
                          sub: book.sub,
                          img: book.cover,
                          price: book.price,
                        ),
                      );
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xE60A101C),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x66E8D5A3)),
                      ),
                      child: const NwsbIcon(
                        NwsbMarks.cart,
                        size: 18,
                        color: Color(0xFFE8D5A3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Buy Now',
                    child: GestureDetector(
                      onTap: () {
                        storeBuyNow(
                          context,
                          ebookBagItem(
                            title: book.title,
                            sub: book.sub,
                            img: book.cover,
                            price: book.price,
                          ),
                        );
                      },
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF3E4B7), Color(0xFFC8A96E)],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Buy Now',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: NwsbColors.ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                kEbProductArt,
                                width: 18,
                                height: 18,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const NwsbIcon(
                                  NwsbMarks.bag,
                                  size: 16,
                                  color: NwsbColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
