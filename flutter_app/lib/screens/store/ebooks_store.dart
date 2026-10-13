/// RB-ebooks (Oct 12 rebuild): the eBooks Store, rebuilt from scratch.
///
/// One hero moment: a single book floats in deep glass, slowly turning in
/// 3D with a soft gold glow beneath it. Real book chips pick the book in
/// focus; below it sits only what that book needs: its contents and
/// outlined Buy / filled Add pills. Then a quiet shelf of the other books
/// and the Reader. No carousels, coupon banners, hype rows or store-explore
/// sections. Research: /workspace/team-plan/research/ebooks/NOTES.md
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../admin/layout/layout_sections.dart';
import '../../admin/template/editable.dart';
import '../../data/content.dart';
import '../../data/entitlements.dart';
import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import '../../features/ebooks/newui/ebooks_flag.dart';
import '../../features/ebooks/newui/ebooks_page.dart';
import '../../features/economy/shop_faces.dart';
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../shell/nwsb_links.dart';
import '../../theme/tokens.dart';
import '../../widgets/glass_black_card.dart';
import '../../widgets/page_shell.dart';
import 'product_detail.dart';
import 'store_actions.dart';
import 'store_cards.dart';
import 'store_routes.dart';
import 'store_select_sheet.dart';
import 'store_terms_sheet.dart';

const _slot = 'ebooks_store.Reading';

/// Public entry; Store home tiles open `const EbooksStoreScreen()`.
class EbooksStoreScreen extends StatelessWidget {
  const EbooksStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => newUiEbooksEnabled()
      ? const EbooksNewUiPage()
      : const CoinbackPage(title: 'Ebooks', art: 'assets/store/intro-ebooks.webp');

  Widget _retired(BuildContext context) => StoreTermsHost(
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

/// Bundled books plus any the studio published live.
List<EbBook> _allBooks() {
  final live = ContentStore.instance.books;
  if (live.isEmpty) return kEbBooks;
  final keys = {for (final b in kEbBooks) b.key};
  return [
    ...kEbBooks,
    for (final b in live)
      if (!keys.contains(b.key))
        EbBook(
          key: b.key,
          title: b.title,
          sub: b.sub,
          price: b.price,
          cover: b.cover.isNotEmpty ? b.cover : kEbBooks.first.cover,
          about: b.sub,
          contents: const ['Published from the NowssB studio'],
        ),
  ];
}

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
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassBlackCard(
      radius: 32,
      intensity: 0.9,
      padding: const EdgeInsets.fromLTRB(UiSpace.xl, 56, UiSpace.xl, 40),
      child: Column(children: [
        SizedBox(
          height: 400,
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, child) {
              final a = _t.value * math.pi * 2;
              final lift = math.sin(a) * 8;
              final turn = -0.32 + math.sin(a) * 0.14;
              return Stack(alignment: Alignment.center, children: [
                // Gold glow pooled under the book.
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 170 - lift * 3,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [
                        NwsbColors.gold.withValues(alpha: 0.30),
                        NwsbColors.gold.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -lift - 10),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014)
                      ..rotateY(turn)
                      ..rotateX(0.06),
                    child: child,
                  ),
                ),
              ]);
            },
            child: _Cover(book: widget.book),
          ),
        ),
        const SizedBox(height: UiSpace.xl),
        Text(widget.book.title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 26,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: UiSpace.sm),
        Text(widget.book.sub,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: UiType.body),
      ]),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.book});
  final EbBook book;
  @override
  Widget build(BuildContext context) => Container(
        width: 180,
        height: 252,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
                color: Color(0xCC000000),
                blurRadius: 30,
                offset: Offset(14, 18)),
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
