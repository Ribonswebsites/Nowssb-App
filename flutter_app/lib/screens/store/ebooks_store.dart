/// NowssB Ebooks store — ebooks-only (not a Word Atelier / Meaning paste).
/// One hero/video max; no word mid-rail banner stacks; ebook icons only.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/entitlements.dart';
import '../../data/store_prices.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../shell/nwsb_links.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../../widgets/page_shell.dart';
import '../../widgets/hype_rail.dart';
import '../../widgets/banner_mix.dart';
import '../../widgets/colored_split_promo_banner.dart';
import 'product_detail.dart';
import 'store_actions.dart';
import 'store_cards.dart';
import 'store_home_sections.dart';
import 'store_section_mix.dart';
import 'store_select_sheet.dart';
import 'store_routes.dart';
import 'store_terms_sheet.dart';
import '../../shell/nwsb_links.dart';
import '../../admin/template/editable.dart';
import '../../admin/layout/layout_sections.dart';

const _slot = 'ebooks_store.Reading';

/// Public entry; Store home tiles open `const EbooksStoreScreen()`.
class EbooksStoreScreen extends StatelessWidget {
  const EbooksStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => StoreTermsHost(
        which: 'ebooks',
        head: 'Ebooks described by sound',
        child: PageShell(
          eyebrow: '',
          title: 'NowssB Store',
          subtitle: 'The Ebooks Store',
          film: 'assets/video/player-bg-loop.mp4',
          usePageFilm: true,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
              sliver: SliverList.list(children: const [_Reading()]),
            ),
          ],
        ),
      );
}

class _EbooksBody extends StatelessWidget {
  const _EbooksBody();

num _price(EbBook b) => StorePrices.instance
    .priceFor('ebook:${b.title.toLowerCase()}', shown: b.price);

bool _owned(EbBook b) =>
    Entitlements.instance.canOpenEbook(b.title, price: _price(b));

class _Reading extends StatefulWidget {
  const _Reading();
  @override
  State<_Reading> createState() => _ReadingState();
}

class _ReadingState extends State<_Reading> {
  int _focus = 0;

  @override
  Widget build(BuildContext context) {
    final books = _allBooks();
    if (books.isEmpty) return const SizedBox.shrink();
    final i = _focus.clamp(0, books.length - 1);
    final book = books[i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // Fresh section ids (rb.*) so saved layouts of the old mix match nothing.
      children: layoutChildren(context, 'store.ebooks', [
        const LSection('rb2.film', 'Hero film', _HeroFilm()),
        const SizedBox(height: 36),
        LSection('rb.hero', 'Floating book', _FloatingBook(book: book)),
        const SizedBox(height: UiSpace.xl),
        LSection(
            'rb.picker',
            'Book picker',
            _Picker(
              books: books,
              focus: i,
              onPick: (n) => setState(() => _focus = n),
            )),
        const SizedBox(height: 40),
        LSection('rb.focus', 'Book in focus', _FocusPanel(book: book)),
        const SizedBox(height: 72),
        LSection(
            'rb.shelf',
            'On the shelf',
            _Shelf(
              books: [
                for (var n = 0; n < books.length; n++)
                  if (n != i) (n, books[n])
              ],
              onPick: (n) => setState(() => _focus = n),
            )),
        const SizedBox(height: 56),
        const LSection('rb.reader', 'Reader link', _ReaderRow()),
        const LSection('rb.disclaimer', 'Disclaimer',
            StoreDisclaimer(text: kEbDisclaimer)),
      ]),
    );
  }
}

// ── Hero: one book, floating and slowly turning in deep glass ──────────────

class _FloatingBook extends StatefulWidget {
  const _FloatingBook({required this.book});
  final EbBook book;
  @override
  State<_FloatingBook> createState() => _FloatingBookState();
}

class _FloatingBookState extends State<_FloatingBook>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (still) {
      _t.value = 0.15;
    } else if (!_t.isAnimating) {
      _t.repeat();
    }
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final books = _books;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // Server-driven order (Admin → UI Editor); bundled order by default.
      children: layoutChildren(context, 'store.ebooks', [
        // Single hero/video — no back-to-back promo / word-banner stacks.
        LSection('hero', 'Hero film', Container(
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
                  slot: 'ebooks_store.EbooksBody',
                ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x22060C18), Color(0xE6060C18)],
                      ),
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
                            EditableLabel('ebooks_store.EbooksBody',
                              'READ · LEARN · PRACTICE',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w700,
                                color: NwsbColors.goldLight,
                              ),
                            ),
                            SizedBox(height: 6),
                            EditableLabel('ebooks_store.EbooksBody',
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
                        child: EditableImage.asset(
                          kEbProductArt,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => EditableImage.asset(
                            kEbIntroArt,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(width: 56, height: 56),
                                slot: 'ebooks_store.EbooksBody',
                          ),
                          slot: 'ebooks_store.EbooksBody',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
        // UI-7 varied mix: coupons → tiles → glassy → hype (no two alike).
        LSection(
          'tiles',
          'Category tiles',
          StoreRegistrySection(config: EbooksMix.tiles),
        ),
        const LSection('intro', 'Intro line', Text(
          'Deep-dive guides on sound, phonetic origin and healing practice — '
          'yours to keep, read anywhere, forever. Not a word catalogue.',
          style: TextStyle(fontSize: 13, height: 1.6, color: Color(0x80FFFFFF)),
        )),
        const SizedBox(height: 28),
        LSection('browse', 'Browse strip', _EbookBrowseStrip(
          onOpen: (b) => openEbookDetail(context, b),
          books: books,
        )),
        const SizedBox(height: 24),
        LSection('promo', 'Split promo banner', StoreTextCap(child: ColoredSplitPromoBanner.forSurface(
          SplitPromoSurface.ebooksStore,
          onTap: books.isEmpty ? null : () => openEbookDetail(context, books.first),
          margin: const EdgeInsets.only(bottom: 8),
        ))),
        const SizedBox(height: 20),
        LSection.group('books', 'All books', align: CrossAxisAlignment.start, [for (final b in books) _EbookRow(book: b)]),
        const SizedBox(height: 40),
        LSection('promo2', 'Promo banner', StoreTextCap(child: ColoredSplitPromoBanner(
          spec: SplitPromoExtras.at(12).copyWith(
            title: 'Read the science\nbehind the sound.',
            cta: 'Read a guide',
            onTap: books.isEmpty
                ? null
                : () => openEbookDetail(context, books[1 % books.length]),
          ),
          margin: const EdgeInsets.only(bottom: 48),
        ))),
        const LSection('mix', 'Banner mix', StoreTextCap(child: BannerMix(seed: 0))),
        const SizedBox(height: 12),
        LSection('promo3', 'Promo banner 2', StoreTextCap(child: ColoredSplitPromoBanner(
          spec: SplitPromoExtras.at(13).copyWith(
            title: 'Your ebooks,\nready to read.',
            cta: 'Open Reader',
            onTap: () => NwsbLinks.reader(context),
          ),
        ))),
        const LSection('disclaimer', 'Disclaimer', StoreDisclaimer(text: kEbDisclaimer)),
      ],
          // Brief B (calm): the hype row is retired; ships off, admin can
          // re-enable it.
          hiddenByDefault: const {'hype'}),
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
          const EditableLabel('ebooks_store.EbookBrowseStrip',
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
                            color: g.$3,
                            border: Border.all(color: g.$3, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: g.$3.withValues(alpha: 0.35),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: ColoredBox(
                              color: g.$3,
                              child: EditableImage.asset(
                                g.$2,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: Color(0xFF0A0F1C)),
                                    slot: 'ebooks_store.EbookBrowseStrip',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // UI-9: one line that shrinks under large text.
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              g.$1,
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
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
                    child: StoreNetImage(url: book.cover, word: book.title),
                  ),
                ),
                Container(
                  width: 1,
                  height: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: const Color(0x26FFFFFF),
                ),
                // UI-9: was a fixed 120px column — at 1.3×/2× text on a
                // ~320px phone the title + sub ran far past it. Now at least
                // the cover height, growing with the text; price stays last.
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              book.title,
                              // UI-9: room for long titles at 2× text.
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
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
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: Color(0x8CFFFFFF),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                        Text(
                          Entitlements.instance.canOpenEbook(book.title, price: StorePrices.instance.priceFor('ebook:${book.title.toLowerCase()}', shown: book.price))
                              ? 'Yours'
                              : inr(StorePrices.instance.priceFor('ebook:${book.title.toLowerCase()}', shown: book.price)),
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
                        // UI-9: label + art scale down inside the 42px button.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const EditableLabel('ebooks_store.EbookRow',
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
                              child: EditableImage.asset(
                                kEbProductArt,
                                width: 18,
                                height: 18,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const NwsbIcon(
                                  NwsbMarks.bag,
                                  size: 16,
                                  color: NwsbColors.ink,
                                ),
                                slot: 'ebooks_store.EbookRow',
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(fit: StackFit.expand, children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A2214), Color(0xFF07070A)],
                ),
              ),
            ),
            // Real NowssB ebooks render under the cover (shows while the
            // cover loads; admin can replace it).
            EditableImage.asset(kEbProductArt,
                slot: 'ebooks_store.EbooksBody',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            EditableImage.network(book.cover,
                slot: 'store.ebooks.cover',
                word: book.title,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, p) =>
                    p == null ? child : const SizedBox.shrink(),
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            // Spine highlight for the 3D read.
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)]),
                ),
              ),
            ),
          ]),
        ),
      );
}

// ── Picker: real book chips ────────────────────────────────────────────────

class _Picker extends StatelessWidget {
  const _Picker(
      {required this.books, required this.focus, required this.onPick});
  final List<EbBook> books;
  final int focus;
  final ValueChanged<int> onPick;
  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: UiSpace.sm,
        runSpacing: UiSpace.sm,
        children: [
          for (var n = 0; n < books.length; n++)
            GestureDetector(
              onTap: () => onPick(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: n == focus
                      ? NwsbColors.goldLight
                      : const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(UiRadii.pill),
                  border: Border.all(
                      color: n == focus
                          ? NwsbColors.goldLight
                          : const Color(0x26FFFFFF)),
                ),
                child: Text(
                  books[n].title.replaceFirst(RegExp(r'^The '), ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        n == focus ? NwsbColors.ink : const Color(0xCCFFFFFF),
                  ),
                ),
              ),
            ),
        ],
      );
}

// ── Focus panel: what's inside + Buy / Add ─────────────────────────────────

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({required this.book});
  final EbBook book;
  @override
  Widget build(BuildContext context) {
    final owned = _owned(book);
    final item = ebookBagItem(
        title: book.title, sub: book.sub, img: book.cover, price: book.price);
    return GlassBlackCard(
      padding: const EdgeInsets.all(UiSpace.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: EditableLabel(_slot, 'INSIDE THIS BOOK',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w700,
                    color: NwsbColors.gold)),
          ),
          Text(owned ? 'Yours' : inr(_price(book)),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: NwsbColors.goldLight)),
        ]),
        const SizedBox(height: UiSpace.lg),
        Text(book.about,
            style: UiType.body
                .copyWith(height: 1.6, color: const Color(0xB3FFFFFF))),
        const SizedBox(height: UiSpace.xl),
        const Divider(height: 1, color: Color(0x14FFFFFF)),
        const SizedBox(height: UiSpace.xl),
        for (var n = 0; n < book.contents.length; n++)
          Padding(
            padding: const EdgeInsets.only(bottom: UiSpace.md),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 28,
                child: Text('${n + 1}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: NwsbColors.gold)),
              ),
              Expanded(child: Text(book.contents[n], style: UiType.body)),
            ]),
          ),
        const SizedBox(height: UiSpace.sm),
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => openEbookDetail(context, book),
          child: const EditableLabel(_slot, 'Read the full description',
              style: TextStyle(
                  color: NwsbColors.goldLight, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: UiSpace.md),
        if (owned)
          _Pill(
              label: 'Open in Reader',
              filled: true,
              onTap: () => NwsbLinks.reader(context))
        else
          Row(children: [
            Expanded(
                child: _Pill(
                    label: 'Buy now',
                    filled: false,
                    onTap: () => storeBuyNow(context, item))),
            const SizedBox(width: UiSpace.md),
            Expanded(
                child: _Pill(
                    label: 'Add to bag',
                    filled: true,
                    onTap: () => storeAddToCart(context, item))),
          ]),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UiRadii.pill),
              gradient: filled
                  ? const LinearGradient(
                      colors: [Color(0xFFF3E4B7), Color(0xFFC8A96E)])
                  : null,
              border:
                  filled ? null : Border.all(color: const Color(0x99E8D5A3)),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: filled ? NwsbColors.ink : NwsbColors.goldLight,
                )),
          ),
        ),
      );
}

// ── Shelf: the other books as quiet rows ───────────────────────────────────

class _Shelf extends StatelessWidget {
  const _Shelf({required this.books, required this.onPick});
  final List<(int, EbBook)> books;
  final ValueChanged<int> onPick;
  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const EditableLabel(_slot, 'On the shelf',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: UiSpace.lg),
      for (final (n, b) in books) ...[
        GlassBlackCard(
          intensity: 0.35,
          padding: const EdgeInsets.all(UiSpace.md),
          onTap: () => onPick(n),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 52,
                height: 72,
                child: Stack(fit: StackFit.expand, children: [
                  const ColoredBox(color: Color(0xFF1A160E)),
                  StoreNetImage(url: b.cover, word: b.title),
                ]),
              ),
            ),
            const SizedBox(width: UiSpace.lg),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(b.sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: UiType.caption),
                  ]),
            ),
            const SizedBox(width: UiSpace.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UiRadii.pill),
                border: Border.all(color: const Color(0x66E8D5A3)),
              ),
              child: Text(_owned(b) ? 'Yours' : inr(_price(b)),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: NwsbColors.goldLight)),
            ),
          ]),
        ),
        const SizedBox(height: UiSpace.md),
      ],
    ]);
  }
}

class _ReaderRow extends StatelessWidget {
  const _ReaderRow();
  @override
  Widget build(BuildContext context) => GlassBlackCard(
        intensity: 0.35,
        onTap: () => NwsbLinks.reader(context),
        child: const Row(children: [
          Icon(Icons.menu_book_outlined, color: NwsbColors.goldLight),
          SizedBox(width: UiSpace.md),
          Expanded(
            child: EditableLabel(_slot, 'Your ebooks, ready to read',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
          Icon(Icons.chevron_right_rounded, color: Color(0x80E8D5A3)),
        ]),
      );
}

/// The original ebooks hero film (main 235ae99, same slot) in a Store-home
/// style frosted card.
class _HeroFilm extends StatelessWidget {
  const _HeroFilm();
  @override
  Widget build(BuildContext context) => GlassBlackCard(
        padding: const EdgeInsets.all(UiSpace.sm),
        radius: UiRadii.lg,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(UiRadii.md),
            child: const AspectRatio(
              aspectRatio: 16 / 9,
              child: NwsbVideo(
                asset: 'assets/video/hero-ebooks.mp4',
                poster: 'assets/video/hero-ebooks-poster.webp',
                priority: ClipPriority.feature,
                slot: 'ebooks_store.EbooksBody',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 14, 12, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EditableLabel(
                  'ebooks_store.EbooksBody', 'READ · LEARN · PRACTICE',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w700,
                      color: NwsbColors.goldLight)),
              SizedBox(height: 4),
              EditableLabel('ebooks_store.EbooksBody', 'The NowssB Ebooks',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ]),
          ),
        ]),
      );
}
