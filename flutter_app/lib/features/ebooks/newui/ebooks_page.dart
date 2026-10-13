/// E-books rebuild (spec 14 / 14.3 / 19), behind `newui_ebooks`.
/// Library of 2:3 outline cards with price strips → detail with procedural
/// hero, description, sample and Buy / Gift / Add coupon → Reader entry.
library;

import 'package:flutter/material.dart';

import '../../../data/store_catalog.dart';
import '../../../screens/store/store_cards.dart' show inr;
import '../../../screens/store/store_actions.dart';
import '../../../shell/nwsb_links.dart';
import 'ebooks_kit.dart';
import 'ebooks_source.dart';

/// Side effects, injectable for tests.
class EbooksActions {
  const EbooksActions({this.buy, this.gift, this.coupon, this.read});
  final void Function(BuildContext, EbBook)? buy, gift, coupon, read;

  void doBuy(BuildContext c, EbBook b) => buy != null
      ? buy!(c, b)
      : storeBuyNow(c, ebookBagItem(title: b.title, sub: b.sub, img: b.cover, price: b.price));
  void doGift(BuildContext c, EbBook b) => gift != null
      ? gift!(c, b)
      : storeAddToCart(c, ebookBagItem(title: b.title, sub: b.sub, img: b.cover, price: b.price));
  void doCoupon(BuildContext c, EbBook b) => coupon != null
      ? coupon!(c, b)
      : NwsbLinks.cart(c);
  void doRead(BuildContext c, EbBook b) => read != null ? read!(c, b) : NwsbLinks.reader(c);
}

const _outlines = [Color(0xFF8E7CFF), Color(0xFF5FD4C4), Color(0xFFF2A0C8), Color(0xFFE8C46A)];
Color _outline(int i) => _outlines[i % _outlines.length];

class EbooksNewUiPage extends StatefulWidget {
  const EbooksNewUiPage({super.key, this.source = const LiveEbooksSource(), this.actions = const EbooksActions(), this.reduceEffects = false});
  final EbooksSource source;
  final EbooksActions actions;
  final bool reduceEffects;
  @override
  State<EbooksNewUiPage> createState() => _EbooksNewUiPageState();
}

class _EbooksNewUiPageState extends State<EbooksNewUiPage> {
  late Future<List<EbBook>> _f = _load();
  Future<List<EbBook>> _load() {
    final f = widget.source.load();
    f.ignore(); // FutureBuilder still sees the error; avoid unhandled reports
    return f;
  }
  void _retry() => setState(() {
        _f = _load();
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: EbColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: EbColors.ink,
          title: const Text('E-books'),
          actions: [
            IconButton(
              tooltip: 'How it works',
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => showEbooksHowItWorks(context),
            ),
          ],
        ),
        body: FutureBuilder<List<EbBook>>(
          future: _f,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) return const _Loading();
            if (s.hasError) {
              return widget.source.offline
                  ? _Message(key: const Key('eb-offline'), icon: Icons.cloud_off_rounded, text: "You're offline. Your downloaded books still open in the Reader.", button: 'Try again', onTap: _retry)
                  : _Message(key: const Key('eb-error'), icon: Icons.error_outline_rounded, text: "We couldn't load the library.", button: 'Try again', onTap: _retry);
            }
            final books = s.data ?? const <EbBook>[];
            if (books.isEmpty) {
              return _Message(key: const Key('eb-empty'), icon: Icons.auto_stories_outlined, text: 'No e-books yet. New titles arrive soon.', button: 'Open the Reader', onTap: () => widget.actions.doRead(context, kEbBooks.first));
            }
            return _Library(books: books, page: widget);
          },
        ),
      );
}

class _Library extends StatelessWidget {
  const _Library({required this.books, required this.page});
  final List<EbBook> books;
  final EbooksNewUiPage page;
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        SliverToBoxAdapter(child: EbPagesOfLight(height: 180, reduce: page.reduceEffects)),
        if (page.source.offline)
          const SliverToBoxAdapter(
            child: Padding(
              key: Key('eb-offline-banner'),
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text("Offline: showing saved library", style: TextStyle(color: EbColors.gold)),
            ),
          ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text('Library', style: TextStyle(color: EbColors.ink, fontSize: 22, fontWeight: FontWeight.w800)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.52),
            itemCount: books.length,
            itemBuilder: (c, i) => _BookCard(book: books[i], index: i, page: page),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            child: EbPill(label: 'Your e-books, ready to read', icon: Icons.menu_book_outlined, onTap: () => page.actions.doRead(context, books.first)),
          ),
        ),
      ]);
}

String _priceLabel(EbooksSource s, EbBook b) => s.owns(b) ? 'Yours' : inr(s.priceOf(b));

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.index, required this.page});
  final EbBook book;
  final int index;
  final EbooksNewUiPage page;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${book.title}, ${_priceLabel(page.source, book)}',
        child: GestureDetector(
          key: Key('eb-card-${book.key}'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => EbookDetailNewUi(book: book, index: index, source: page.source, actions: page.actions, reduceEffects: page.reduceEffects),
          )),
          child: EbGlass(
            padding: const EdgeInsets.all(8),
            outline: _outline(index),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AspectRatio(aspectRatio: 2 / 3, child: Hero(tag: 'eb-${book.key}', child: _Cover(url: book.cover, title: book.title, color: _outline(index)))),
              const SizedBox(height: 8),
              Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EbColors.ink, fontWeight: FontWeight.w700)),
              const Spacer(),
              EbPriceStrip(label: _priceLabel(page.source, book), color: _outline(index)),
            ]),
          ),
        ),
      );
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, required this.title, required this.color});
  final String url, title;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withValues(alpha: 0.7), EbColors.bg]),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: EbColors.ink, fontWeight: FontWeight.w700)),
    );
    if (url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (_, child, p) => p == null ? child : fallback),
    );
  }
}

class EbookDetailNewUi extends StatelessWidget {
  const EbookDetailNewUi({super.key, required this.book, required this.index, required this.source, required this.actions, this.reduceEffects = false});
  final EbBook book;
  final int index;
  final EbooksSource source;
  final EbooksActions actions;
  final bool reduceEffects;

  @override
  Widget build(BuildContext context) {
    final owned = source.owns(book);
    final price = source.priceOf(book);
    return Scaffold(
      backgroundColor: EbColors.bg,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: EbColors.ink, title: Text(book.title, overflow: TextOverflow.ellipsis)),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 40), children: [
        Stack(alignment: Alignment.center, children: [
          EbPagesOfLight(height: 240, reduce: reduceEffects),
          SizedBox(height: 200, child: AspectRatio(aspectRatio: 2 / 3, child: Hero(tag: 'eb-${book.key}', child: _Cover(url: book.cover, title: book.title, color: _outline(index))))),
        ]),
        const SizedBox(height: 16),
        Text(book.title, style: const TextStyle(color: EbColors.ink, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(book.sub, style: const TextStyle(color: EbColors.dim)),
        Row(children: [
          Text(owned ? 'Yours' : inr(price), style: const TextStyle(color: EbColors.gold, fontSize: 20, fontWeight: FontWeight.w800)),
          const EbInfo(title: 'Price', text: 'One payment, the book is yours to read anywhere in the NowssB Reader.', example: 'Coins can cover part of the price at checkout.'),
        ]),
        const SizedBox(height: 12),
        EbGlass(child: Text(book.about, style: const TextStyle(color: EbColors.dim, height: 1.6))),
        const SizedBox(height: 16),
        const Text('Sample', style: TextStyle(color: EbColors.lilac, letterSpacing: 2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        EbGlass(
          key: const Key('eb-sample'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var n = 0; n < book.contents.length && n < 3; n++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${n + 1}.  ${book.contents[n]}', style: const TextStyle(color: EbColors.ink)),
              ),
            if (book.contents.length > 3)
              Text('+ ${book.contents.length - 3} more chapters', style: const TextStyle(color: EbColors.dim)),
          ]),
        ),
        const SizedBox(height: 20),
        if (owned)
          EbPill(label: 'Open in Reader', filled: true, icon: Icons.menu_book_rounded, onTap: () => actions.doRead(context, book))
        else ...[
          EbPill(label: 'Buy', filled: true, onTap: () => actions.doBuy(context, book)),
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 12),
            child: Text("You'll be charged through Google Play.", textAlign: TextAlign.center, style: TextStyle(color: EbColors.dim, fontSize: 12)),
          ),
          Row(children: [
            Expanded(child: EbPill(label: 'Gift', icon: Icons.card_giftcard_rounded, onTap: () => actions.doGift(context, book))),
            const SizedBox(width: 12),
            Expanded(child: EbPill(label: 'Add coupon', icon: Icons.confirmation_number_outlined, onTap: () => actions.doCoupon(context, book))),
          ]),
        ],
        const SizedBox(height: 24),
        const Text(kEbDisclaimer, style: TextStyle(color: EbColors.dim, fontSize: 11)),
      ]),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => GridView.count(
        key: const Key('eb-loading'),
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.52,
        children: List.generate(4, (_) => const EbGlass(child: SizedBox.expand())),
      );
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.icon, required this.text, required this.button, required this.onTap});
  final IconData icon;
  final String text, button;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: EbColors.lilac),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: EbColors.ink, fontSize: 16)),
            const SizedBox(height: 20),
            EbPill(label: button, filled: true, onTap: onTap),
          ]),
        ),
      );
}

/// Layer 1 guide (spec 19.1): Browse → Preview → Read anywhere.
Future<void> showEbooksHowItWorks(BuildContext context) => showDialog<void>(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: _HowItWorks(onDone: () => Navigator.pop(c)),
      ),
    );

class _HowItWorks extends StatefulWidget {
  const _HowItWorks({required this.onDone});
  final VoidCallback onDone;
  @override
  State<_HowItWorks> createState() => _HowItWorksState();
}

class _HowItWorksState extends State<_HowItWorks> {
  static const _slides = [
    (Icons.grid_view_rounded, 'Browse', 'Pick a book from the library.'),
    (Icons.visibility_outlined, 'Preview', 'Read the description and a sample first.'),
    (Icons.menu_book_rounded, 'Read anywhere', 'Your books open in the Reader on any phone.'),
  ];
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final s = _slides[_i];
    final last = _i == _slides.length - 1;
    return EbGlass(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xE6000000), borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(s.$1, size: 48, color: EbColors.lilac),
          const SizedBox(height: 12),
          Text(s.$2, style: const TextStyle(color: EbColors.ink, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(s.$3, textAlign: TextAlign.center, style: const TextStyle(color: EbColors.dim)),
          const SizedBox(height: 8),
          Text('Step ${_i + 1} of ${_slides.length}', style: const TextStyle(color: EbColors.dim, fontSize: 12)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(onPressed: widget.onDone, child: const Text('Skip')),
            TextButton(onPressed: last ? widget.onDone : () => setState(() => _i++), child: Text(last ? 'Done' : 'Next')),
          ]),
        ]),
      ),
    );
  }
}
