/// E-books rebuild (spec 14 / 19) in the approved design (Ribon, Oct 13):
/// every card is the frosted MeditationCard or the frosted coupon-ticket row
/// from approved-1/2, over the app's original background (NAppBackdrop).
library;

import 'package:flutter/material.dart';

import '../../../data/store_catalog.dart';
import '../../../kit/kit.dart';
import '../../../nowssb_ui/nowssb_ui.dart';
import '../../../screens/store/store_actions.dart';
import '../../../shell/nwsb_links.dart';
import 'ebooks_source.dart';

/// Side effects, injectable for tests.
class EbooksActions {
  const EbooksActions({this.buy, this.gift, this.coupon, this.read});
  final void Function(BuildContext, EbBook)? buy, gift, coupon, read;

  void doBuy(BuildContext c, EbBook b) => buy != null ? buy!(c, b) : storeBuyNow(c, ebookBagItem(title: b.title, sub: b.sub, img: b.cover, price: b.price));
  void doGift(BuildContext c, EbBook b) => gift != null ? gift!(c, b) : storeAddToCart(c, ebookBagItem(title: b.title, sub: b.sub, img: b.cover, price: b.price));
  void doCoupon(BuildContext c, EbBook b) => coupon != null ? coupon!(c, b) : NwsbLinks.cart(c);
  void doRead(BuildContext c, EbBook b) => read != null ? read!(c, b) : NwsbLinks.reader(c);
}

String _money(int cents) => KitMoney.cents(cents);

/// Rarity-style accent per book, cycling through the approved ticket pills.
const _accents = [Rarity.epic, Rarity.rare, Rarity.legendary, Rarity.common];
Rarity _accent(int i) => _accents[i % _accents.length];

String _priceLabel(EbooksSource s, EbBook b) => s.owns(b) ? 'Yours' : _money(s.priceCents(b));

const _label = TextStyle(color: NTokens.mint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6);

/// Round cover photo (approved card: circle near the top). Same ring, border
/// and glow as nowssb_ui CircleImage; the network cover sits on top and
/// falls back to the kit's violet circle when it can't load.
class _CoverCircle extends StatelessWidget {
  const _CoverCircle({required this.url, this.size = 140, this.ring = NTokens.violet});
  final String url;
  final double size;
  final Color ring;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(fit: StackFit.expand, children: [
          CircleImage(image: null, size: size, ring: ring),
          if (url.startsWith('http'))
            Padding(
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            ),
        ]),
      );
}

/// The approved MeditationCard (nowssb_ui V1, approved-1/2): frosted outer
/// card, round photo, inner frosted panel with bold title, small grey body,
/// a left text link, a white "Next"-style pill and page dots. Same radii,
/// paddings and type as nowssb_ui MeditationCard; this copy only takes a
/// widget for the photo so network covers can fall back safely.
class _MedCard extends StatelessWidget {
  const _MedCard({required this.photo, required this.title, this.body, this.link, this.onLink, required this.cta, this.onCta, this.dots, this.dotIndex = 0});
  final Widget photo;
  final String title, cta;
  final String? body, link;
  final VoidCallback? onLink, onCta;
  final int? dots;
  final int dotIndex;
  @override
  Widget build(BuildContext context) => NGlass(
        radius: NTokens.rHero,
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          photo,
          const SizedBox(height: 20),
          NGlass(
            radius: NTokens.rCard,
            elevation: .3,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.15, fontWeight: FontWeight.w800)),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(body!, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NTokens.textLo, fontSize: 12, height: 1.4)),
              ],
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: link == null
                      ? const SizedBox.shrink()
                      : GestureDetector(
                          onTap: onLink,
                          child: Text(link!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
                        ),
                ),
                const SizedBox(width: 8),
                GlassPill(label: cta, style: PillStyle.white, dense: true, onTap: onCta),
              ]),
              if (dots != null) ...[const SizedBox(height: 10), Center(child: PageDots(count: dots!, index: dotIndex))],
            ]),
          ),
        ]),
      );
}

/// Frosted ticket row (approved-2 coupon list / nowssb_ui CouponListCard):
/// notched glass, round photo, dashed divider, rarity-style pill + badge,
/// small label, bold value, mint action link.
class _Ticket extends StatelessWidget {
  const _Ticket({super.key, required this.photo, required this.rarity, required this.tag, this.badge, required this.label, required this.value, required this.action, this.onTap, this.dim = false});
  final Widget photo;
  final Rarity rarity;
  final String tag, label, value, action;
  final String? badge;
  final VoidCallback? onTap;
  final bool dim;
  @override
  Widget build(BuildContext context) {
    Widget card = ClipPath(
      clipper: const NotchClipper(radius: 22, notch: 10),
      child: NGlass(
        radius: 22,
        accent: rarity.color,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(children: [
          photo,
          const SizedBox(width: 12),
          const SizedBox(height: 64, child: DashedLine(vertical: true)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, runSpacing: 4, children: [
                NGlass(
                  radius: NTokens.rPill,
                  accent: rarity.color,
                  tint: rarity.color,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(tag, style: TextStyle(color: Color.lerp(rarity.color, Colors.white, .5), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
                if (badge != null) GlassBadge(badge!),
              ]),
              const SizedBox(height: 6),
              Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text(action, style: const TextStyle(color: NTokens.mint, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    );
    if (dim) card = ExpiredOverlay(label: 'Yours', child: card);
    return card;
  }
}

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
  Widget build(BuildContext context) => NAppBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: NTokens.textHi,
            title: const Text('E-books'),
            actions: [
              IconButton(tooltip: 'How it works', icon: const Icon(Icons.help_outline_rounded), onPressed: () => showEbooksHowItWorks(context)),
            ],
          ),
          body: FutureBuilder<List<EbBook>>(
            future: _f,
            builder: (context, s) {
              if (s.connectionState != ConnectionState.done) return const _Loading();
              if (s.hasError) {
                return widget.source.offline
                    ? _State(key: const Key('eb-offline'), circle: 'milky_way', title: "You're offline", text: 'Your downloaded books still open in the Reader.', button: 'Try again', onTap: _retry)
                    : _State(key: const Key('eb-error'), circle: 'stones', title: 'Something went wrong', text: "We couldn't load the library.", button: 'Try again', onTap: _retry);
              }
              final books = s.data ?? const <EbBook>[];
              if (books.isEmpty) {
                return _State(
                    key: const Key('eb-empty'),
                    circle: 'lotus',
                    title: 'No e-books yet',
                    text: 'New titles arrive soon. Your books open in the Reader.',
                    button: 'Open Reader',
                    onTap: () => widget.actions.doRead(context, kEbBooks.first));
              }
              return _Library(books: books, page: widget);
            },
          ),
        ),
      );
}

void _openDetail(BuildContext context, EbooksNewUiPage page, EbBook book, int index) => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EbookDetailNewUi(book: book, index: index, source: page.source, actions: page.actions, reduceEffects: page.reduceEffects),
    ));

class _Library extends StatefulWidget {
  const _Library({required this.books, required this.page});
  final List<EbBook> books;
  final EbooksNewUiPage page;
  @override
  State<_Library> createState() => _LibraryState();
}

class _LibraryState extends State<_Library> {
  final _pc = PageController(viewportFraction: .84);
  int _i = 0;
  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = widget.books, page = widget.page, src = page.source;
    return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
      if (src.offline)
        const Padding(
          key: Key('eb-offline-banner'),
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text('Offline: showing saved library', style: TextStyle(color: NTokens.gold)),
        ),
      SizedBox(
        height: 470,
        child: PageView.builder(
          controller: _pc,
          itemCount: books.length,
          onPageChanged: (n) => setState(() => _i = n),
          itemBuilder: (c, n) {
            final b = books[n];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              // Large text scales the card down instead of overflowing.
              child: LayoutBuilder(
                builder: (c, box) => FittedBox(
                  alignment: Alignment.topCenter,
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                      width: box.maxWidth,
                      child: Semantics(
                        button: true,
                        label: '${b.title}, ${_priceLabel(src, b)}',
                        child: GestureDetector(
                          key: Key('eb-card-${b.key}'),
                          onTap: () => _openDetail(context, page, b, n),
                          child: _MedCard(
                            photo: _CoverCircle(url: b.cover, ring: _accent(n).color),
                            title: b.title,
                            body: b.sub,
                            link: _priceLabel(src, b),
                            cta: src.owns(b) ? 'Read' : 'Preview',
                            onCta: () => _openDetail(context, page, b, n),
                            dots: books.length,
                            dotIndex: _i,
                          ),
                        ),
                      )),
                ),
              ),
            );
          },
        ),
      ),
      const Padding(padding: EdgeInsets.fromLTRB(24, 16, 24, 10), child: Text('BOOK LIST', style: _label)),
      for (var n = 0; n < books.length; n++)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _Ticket(
            key: Key('eb-row-${books[n].key}'),
            photo: _CoverCircle(url: books[n].cover, size: 64, ring: _accent(n).color),
            rarity: _accent(n),
            tag: 'E-BOOK',
            badge: src.owns(books[n]) ? 'OWNED' : (n == books.length - 1 ? 'NEW' : null),
            label: books[n].title,
            value: _priceLabel(src, books[n]),
            action: src.owns(books[n]) ? 'Open in Reader >' : 'View book >',
            onTap: () => _openDetail(context, page, books[n], n),
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Center(child: GlassPill(label: 'Your e-books, ready to read', icon: Icons.menu_book_outlined, style: PillStyle.outlined, onTap: () => page.actions.doRead(context, books.first))),
      ),
    ]);
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
    final accent = _accent(index);
    return NAppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: NTokens.textHi, title: Text(book.title, overflow: TextOverflow.ellipsis)),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), children: [
          _MedCard(
            photo: _CoverCircle(url: book.cover, ring: accent.color),
            title: book.title,
            body: book.about,
            link: owned ? 'Yours' : _money(source.priceCents(book)),
            cta: owned ? 'Open in Reader' : 'Buy',
            onCta: () => owned ? actions.doRead(context, book) : actions.doBuy(context, book),
          ),
          if (!owned)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("You'll be charged through Google Play.", textAlign: TextAlign.center, style: TextStyle(color: NTokens.textLo, fontSize: 12)),
            ),
          const Row(children: [
            Padding(padding: EdgeInsets.fromLTRB(8, 16, 0, 10), child: Text('PRICE', style: _label)),
            _Info(
                title: 'Price', text: 'One payment, the book is yours to read anywhere in the NowssB Reader.', example: 'Shown in your local currency. Coins can cover part of the price at checkout.'),
          ]),
          _Ticket(
            photo: _CoverCircle(url: book.cover, size: 64, ring: accent.color),
            rarity: accent,
            tag: 'E-BOOK',
            badge: owned ? 'OWNED' : null,
            label: book.sub,
            value: owned ? 'Yours' : _money(source.priceCents(book)),
            action: owned ? 'Open in Reader >' : 'Buy >',
            onTap: () => owned ? actions.doRead(context, book) : actions.doBuy(context, book),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(8, 20, 8, 10), child: Text('SAMPLE', style: _label)),
          NGlass(
            key: const Key('eb-sample'),
            radius: NTokens.rCard,
            elevation: .3,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var n = 0; n < book.contents.length && n < 3; n++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${n + 1}.  ${book.contents[n]}', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35)),
                ),
              if (book.contents.length > 3) Text('+ ${book.contents.length - 3} more chapters', style: const TextStyle(color: NTokens.textLo, fontSize: 12)),
            ]),
          ),
          if (!owned) ...[
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GlassPill(label: 'Gift', icon: Icons.card_giftcard_rounded, style: PillStyle.outlined, onTap: () => actions.doGift(context, book)),
              const SizedBox(width: 12),
              GlassPill(label: 'Add coupon', icon: Icons.confirmation_number_outlined, style: PillStyle.outlined, onTap: () => actions.doCoupon(context, book)),
            ]),
          ],
          const SizedBox(height: 24),
          const Text(kEbDisclaimer, style: TextStyle(color: NTokens.textLo, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => ListView(
        key: const Key('eb-loading'),
        padding: const EdgeInsets.all(16),
        children: const [GlassSkeleton(height: 400), SizedBox(height: 14), GlassSkeleton(height: 92), SizedBox(height: 12), GlassSkeleton(height: 92)],
      );
}

/// Empty / error / offline: the approved meditation card with the kit's
/// bundled circle photo, one line and one action.
class _State extends StatelessWidget {
  const _State({super.key, required this.circle, required this.title, required this.text, required this.button, required this.onTap});
  final String circle, title, text, button;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: MeditationCard(title: title, subtitle: text, image: NCircles.of(circle), cta: button, onCta: onTap),
        ),
      );
}

/// ⓘ next to a number (spec 19.3), opened in the kit's black-card popup.
class _Info extends StatelessWidget {
  const _Info({required this.title, required this.text, required this.example});
  final String title, text, example;
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'What is $title?',
        iconSize: 18,
        icon: const Icon(Icons.info_outline_rounded, color: NTokens.mint),
        onPressed: () => showGlassPopup<void>(
          context,
          builder: (c) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: NTokens.textHi, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: NTokens.textLo, height: 1.5)),
            const SizedBox(height: 8),
            Text(example, style: const TextStyle(color: NTokens.gold, height: 1.5)),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: GlassPill(label: 'Got it', style: PillStyle.white, dense: true, onTap: () => Navigator.pop(c))),
          ]),
        ),
      );
}

/// Layer 1 guide (spec 19.1): Browse → Preview → Read anywhere, as the
/// approved meditation card with Skip / Next and page dots.
Future<void> showEbooksHowItWorks(BuildContext context) => showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black54,
      pageBuilder: (c, _, __) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(type: MaterialType.transparency, child: _HowItWorks(onDone: () => Navigator.pop(c))),
          ),
        ),
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
    ('lotus', 'Browse', 'Pick a book from the library.'),
    ('candle_incense', 'Preview', 'Read the description and a sample first.'),
    ('lake', 'Read anywhere', 'Your books open in the Reader on any phone.'),
  ];
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final s = _slides[_i];
    final last = _i == _slides.length - 1;
    return _MedCard(
      photo: CircleImage(image: NCircles.of(s.$1)),
      title: s.$2,
      body: s.$3,
      link: 'Skip',
      onLink: widget.onDone,
      cta: last ? 'Done' : 'Next',
      onCta: last ? widget.onDone : () => setState(() => _i++),
      dots: _slides.length,
      dotIndex: _i,
    );
  }
}
