/// NowssB Ebooks store — full-width cover rows matching website `.eb-row`.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/store_catalog.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/page_shell.dart';
import 'product_detail.dart';
import 'store_actions.dart';
import 'store_cards.dart';
import 'request_words.dart';
import 'store_home_sections.dart';
import 'store_select_sheet.dart';
import 'store_routes.dart';

class EbooksStoreScreen extends StatelessWidget {
  const EbooksStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => PageShell(
      eyebrow: 'NowssB Store',
      title: 'The NowssB Ebooks',
      film: 'assets/video/store-verify-banner.mp4',
      usePageFilm: false,
      onBack: () => Navigator.of(context).pop(),
      onStorePicker: () => showStoreSelectSheet(
          context,
          current: 'ebooks',
          onSelect: (id) => openStoreFromPicker(context, id, current: 'ebooks'),
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
    // Prefer catalogue covers/copy; overlay live titles when studio published more.
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
        // Restored looping hero-ebooks film (keep elevated copy overlay).
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
                const Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
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
              ],
            ),
          ),
        ),
        const Text(
          'Deep-dive guides on word science, phonetic origin and sound healing — yours to keep, read anywhere, forever.',
          style: TextStyle(fontSize: 13, height: 1.6, color: Color(0x80FFFFFF)),
        ),
        const SizedBox(height: 18),
        StoreFrequencyPackage(
          onSelectCategory: (_) {},
          onSeeAll: () => showStoreViewAllPanel(
            context,
            title: 'Browse by Goal',
            items: storeDefaultViewAllItems(),
            onOpenWord: (_, __, ___, ____) {},
          ),
          onRequestWords: () => openRequestWords(context),
          onOpenWord: (_, __, ___, ____) {},
        ),
        StoreRecommendedSection(
          onSeeAll: () => showStoreViewAllPanel(
            context,
            title: 'Recommended for You',
            items: storeDefaultViewAllItems(),
            onOpenWord: (_, __, ___, ____) {},
          ),
          onOpenWord: (_, __, ___, ____) {},
        ),
        StoreFeaturedPlaylistSection(
          onSeeAll: () => showStoreViewAllPanel(
            context,
            title: 'Featured Playlist',
            items: storeDefaultViewAllItems(),
            onOpenWord: (_, __, ___, ____) {},
          ),
          onOpenWord: (_, __, ___, ____) {},
        ),
        StoreGlassPlaylistCarousel(
          onSeeAll: () => showStoreViewAllPanel(
            context,
            title: 'Playlists',
            items: storeDefaultViewAllItems(),
            onOpenWord: (_, __, ___, ____) {},
          ),
          onOpenWord: (_, __, ___, ____) {},
        ),
        ..._ebookRowsWithMidBanners(books),
        StoreDisclaimer(text: kEbDisclaimer),
      ],
    );
  }

  List<Widget> _ebookRowsWithMidBanners(List<EbBook> books) {
    final out = <Widget>[];
    var rail = 0;
    for (final b in books) {
      out.add(_EbookRow(book: b));
      rail++;
      if (rail % 2 == 0) {
        final mid = storeMidRailBannerAt((rail ~/ 2) - 1);
        if (mid != null) out.add(mid);
      }
    }
    final placed = rail ~/ 2;
    for (var i = placed; i < kStoreMidRailBanners.length; i++) {
      out.add(StoreMidRailBanner(data: kStoreMidRailBanners[i]));
    }
    return out;
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Buy Now',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: NwsbColors.ink,
                              ),
                            ),
                            SizedBox(width: 8),
                            NwsbIcon(
                              NwsbMarks.bag,
                              size: 16,
                              color: NwsbColors.ink,
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
