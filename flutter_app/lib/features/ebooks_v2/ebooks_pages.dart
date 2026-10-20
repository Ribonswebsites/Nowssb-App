/// E-books v2 (Oct 20 round): library (Discover / My books / Saved), search,
/// detail, buy / gift / coupon, sample and a basic reader, first-use guide.
/// Cards follow the approved designs (approved-1 meditation card, approved-2
/// coupon tickets) over the app's original background video.
library;

import 'package:flutter/material.dart';

import '../../data/store_catalog.dart';
import '../../screens/store/store_actions.dart';
import '../../shell/nwsb_links.dart';
import '../../widgets/app_backdrop.dart';
import 'ebooks_data.dart';
import 'ebooks_glass.dart';

/// Side effects; injectable for tests.
class EbooksActions {
  const EbooksActions({this.buy, this.gift, this.coupon});
  final void Function(BuildContext, EbBook)? buy, gift, coupon;
  void doBuy(BuildContext c, EbBook b) => buy != null ? buy!(c, b) : storeBuyNow(c, ebookBagItem(title: b.title, sub: b.sub, img: b.cover, price: b.price));
  void doGift(BuildContext c, EbBook b) => gift != null ? gift!(c, b) : storeAddToCart(c, ebookBagItem(title: b.title, sub: b.sub, img: b.cover, price: b.price));
  void doCoupon(BuildContext c, EbBook b) => coupon != null ? coupon!(c, b) : NwsbLinks.cart(c);
}

/// Shared page state passed to sub-pages.
class EbooksScope {
  EbooksScope({required this.data, required this.actions, required this.background});
  final EbooksData data;
  final EbooksActions actions;
  final Widget background;
  final ValueNotifier<Set<String>> saved = ValueNotifier(<String>{});
  void toggleSave(EbBook b) {
    final s = {...saved.value};
    s.contains(b.key) ? s.remove(b.key) : s.add(b.key);
    saved.value = s;
  }
}

Color _accent(int i) => EbTok.accents[i % EbTok.accents.length];
String _price(EbooksScope s, EbBook b) => s.data.owns(b) ? 'Yours' : money(s.data.priceCents(b));

class _Frame extends StatelessWidget {
  const _Frame({required this.scope, required this.title, required this.body, this.actions = const [], this.bottom});
  final EbooksScope scope;
  final String title;
  final Widget body;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Positioned.fill(child: IgnorePointer(child: scope.background)),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, elevation: 0, title: Text(title, overflow: TextOverflow.ellipsis), actions: actions, bottom: bottom),
          body: body,
        ),
      ]);
}

class EbooksV2Page extends StatefulWidget {
  EbooksV2Page({super.key, EbooksData? data, this.actions = const EbooksActions(), this.background = const AppBackdrop(), this.autoGuide = true}) : data = data ?? LiveEbooksData();
  final EbooksData data;
  final EbooksActions actions;
  final Widget background;
  final bool autoGuide;
  @override
  State<EbooksV2Page> createState() => _EbooksV2PageState();
}

class _EbooksV2PageState extends State<EbooksV2Page> with SingleTickerProviderStateMixin {
  late final EbooksScope scope = EbooksScope(data: widget.data, actions: widget.actions, background: widget.background);
  late final TabController _tabs = TabController(length: 3, vsync: this);
  late Future<List<EbBook>> _f = _load();

  Future<List<EbBook>> _load() {
    final f = widget.data.load();
    f.ignore();
    return f;
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoGuide) {
      widget.data.guideSeen().then((seen) {
        if (!seen && mounted) {
          widget.data.markGuideSeen();
          showEbooksGuide(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Frame(
        scope: scope,
        title: 'E-books',
        actions: [
          IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search_rounded),
              onPressed: () async {
                final books = await _f.catchError((_) => <EbBook>[]);
                if (context.mounted) _openSearch(context, scope, books);
              }),
          IconButton(tooltip: 'How it works', icon: const Icon(Icons.help_outline_rounded), onPressed: () => showEbooksGuide(context)),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: EbTok.textLo,
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Discover'), Tab(text: 'My books'), Tab(text: 'Saved')],
        ),
        body: FutureBuilder<List<EbBook>>(
          future: _f,
          builder: (context, s) {
            if (s.connectionState != ConnectionState.done) return const _Loading();
            if (s.hasError) {
              final off = widget.data.offline;
              return _StateCard(
                key: Key(off ? 'eb-offline' : 'eb-error'),
                icon: off ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                title: off ? "You're offline" : 'Something went wrong',
                text: off ? 'Books you own still open in the Reader once you reconnect.' : "We couldn't load the library.",
                cta: 'Try again',
                onCta: () => setState(() {
                  _f = _load();
                }),
              );
            }
            final books = s.data ?? const <EbBook>[];
            if (books.isEmpty) {
              return const _StateCard(key: Key('eb-empty'), icon: Icons.auto_stories_outlined, title: 'No e-books yet', text: 'New titles arrive soon. Check back here.', cta: null);
            }
            return TabBarView(controller: _tabs, children: [
              _Discover(scope: scope, books: books),
              _MyBooks(scope: scope, books: books, onBrowse: () => _tabs.animateTo(0)),
              _Saved(scope: scope, books: books, onBrowse: () => _tabs.animateTo(0)),
            ]);
          },
        ),
      );
}

void openEbook(BuildContext context, EbooksScope scope, EbBook b, int i) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EbookDetailV2(scope: scope, book: b, index: i)));

void openReader(BuildContext context, EbooksScope scope, EbBook b, {int? chapter}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EbookReaderV2(scope: scope, book: b, start: chapter ?? scope.data.progressOf(b))));

class _Discover extends StatefulWidget {
  const _Discover({required this.scope, required this.books});
  final EbooksScope scope;
  final List<EbBook> books;
  @override
  State<_Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<_Discover> {
  final _pc = PageController(viewportFraction: .86);
  int _i = 0;
  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scope, books = widget.books;
    return ListView(padding: const EdgeInsets.only(top: 8, bottom: 40), children: [
      if (s.data.offline)
        const Padding(key: Key('eb-offline-banner'), padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('Offline: showing your saved library', style: TextStyle(color: EbTok.gold))),
      SizedBox(
        height: 500,
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: s.saved,
          builder: (_, saved, __) => PageView.builder(
            controller: _pc,
            itemCount: books.length,
            onPageChanged: (n) => setState(() => _i = n),
            itemBuilder: (c, n) {
              final b = books[n];
              final owned = s.data.owns(b);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LayoutBuilder(
                  builder: (c, box) => FittedBox(
                    alignment: Alignment.topCenter,
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: box.maxWidth,
                      child: GestureDetector(
                        key: Key('eb-card-${b.key}'),
                        onTap: () => openEbook(context, s, b, n),
                        child: EbMedCard(
                          liked: saved.contains(b.key),
                          onLike: () => s.toggleSave(b),
                          photo: EbCircle(url: b.cover, ring: _accent(n)),
                          title: b.title,
                          body: b.sub,
                          link: _price(s, b),
                          cta: owned ? 'Read' : 'Preview',
                          onCta: () => owned ? openReader(context, s, b) : openEbook(context, s, b, n),
                          dots: books.length,
                          dotIndex: _i,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      const Padding(padding: EdgeInsets.fromLTRB(24, 18, 24, 10), child: Text('ALL E-BOOKS', style: EbTok.label)),
      for (var n = 0; n < books.length; n++) _row(context, s, books[n], n),
    ]);
  }
}

Widget _row(BuildContext context, EbooksScope s, EbBook b, int n) {
  final owned = s.data.owns(b);
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: EbTicket(
      key: Key('eb-row-${b.key}'),
      photo: EbCircle(url: b.cover, size: 64, ring: _accent(n)),
      accent: _accent(n),
      tag: 'E-BOOK',
      badge: owned ? 'OWNED' : null,
      label: b.title,
      value: _price(s, b),
      action: owned ? 'Continue reading >' : 'View book >',
      onTap: () => owned ? openReader(context, s, b) : openEbook(context, s, b, n),
    ),
  );
}

class _MyBooks extends StatelessWidget {
  const _MyBooks({required this.scope, required this.books, required this.onBrowse});
  final EbooksScope scope;
  final List<EbBook> books;
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) {
    final mine = [
      for (var i = 0; i < books.length; i++)
        if (scope.data.owns(books[i])) (i, books[i])
    ];
    if (mine.isEmpty) {
      return _StateCard(
          key: const Key('eb-mine-empty'),
          icon: Icons.menu_book_outlined,
          title: 'No books yet',
          text: 'Books you buy or receive as gifts appear here, ready to read.',
          cta: 'Browse e-books',
          onCta: onBrowse);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(0, 12, 0, 40), children: [
      const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 10), child: Text('YOUR LIBRARY', style: EbTok.label)),
      for (final (i, b) in mine) _row(context, scope, b, i),
    ]);
  }
}

class _Saved extends StatelessWidget {
  const _Saved({required this.scope, required this.books, required this.onBrowse});
  final EbooksScope scope;
  final List<EbBook> books;
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<String>>(
        valueListenable: scope.saved,
        builder: (_, saved, __) {
          final list = [
            for (var i = 0; i < books.length; i++)
              if (saved.contains(books[i].key)) (i, books[i])
          ];
          if (list.isEmpty) {
            return _StateCard(
                key: const Key('eb-saved-empty'),
                icon: Icons.favorite_border_rounded,
                title: 'Nothing saved',
                text: 'Tap the heart on any book to keep it here for later.',
                cta: 'Browse e-books',
                onCta: onBrowse);
          }
          return ListView(padding: const EdgeInsets.fromLTRB(0, 12, 0, 40), children: [for (final (i, b) in list) _row(context, scope, b, i)]);
        },
      );
}

void _openSearch(BuildContext context, EbooksScope scope, List<EbBook> books) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
        child: _SearchSheet(scope: scope, books: books),
      ),
    );

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.scope, required this.books});
  final EbooksScope scope;
  final List<EbBook> books;
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final hits = [
      for (var i = 0; i < widget.books.length; i++)
        if (q.isEmpty || '${widget.books[i].title} ${widget.books[i].sub}'.toLowerCase().contains(q.toLowerCase())) (i, widget.books[i])
    ];
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: EbGlass(
        radius: 30,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            key: const Key('eb-search'),
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration:
                const InputDecoration(hintText: 'Search e-books', hintStyle: TextStyle(color: EbTok.textLo), prefixIcon: Icon(Icons.search_rounded, color: Colors.white70), border: InputBorder.none),
            onChanged: (v) => setState(() => q = v),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: hits.isEmpty
                ? const Center(child: Text('No books match. Try another word.', style: TextStyle(color: EbTok.textLo)))
                : ListView(children: [
                    for (final (i, b) in hits)
                      ListTile(
                        leading: EbCircle(url: b.cover, size: 40, ring: _accent(i)),
                        title: Text(b.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(_price(widget.scope, b), style: const TextStyle(color: EbTok.textLo)),
                        onTap: () {
                          Navigator.pop(context);
                          openEbook(context, widget.scope, b, i);
                        },
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }
}

class EbookDetailV2 extends StatelessWidget {
  const EbookDetailV2({super.key, required this.scope, required this.book, required this.index});
  final EbooksScope scope;
  final EbBook book;
  final int index;
  @override
  Widget build(BuildContext context) {
    final owned = scope.data.owns(book);
    final a = _accent(index);
    return _Frame(
      scope: scope,
      title: book.title,
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: scope.saved,
        builder: (_, saved, __) => ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
          EbMedCard(
            liked: saved.contains(book.key),
            onLike: () => scope.toggleSave(book),
            photo: EbCircle(url: book.cover, ring: a),
            title: book.title,
            body: book.about,
            bodyLines: 6,
            link: owned ? 'Yours' : 'Read a sample',
            onLink: owned ? null : () => openReader(context, scope, book, chapter: 0),
            cta: owned ? 'Open in Reader' : 'Buy',
            onCta: () => owned ? openReader(context, scope, book) : scope.actions.doBuy(context, book),
          ),
          if (!owned)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text("You'll be charged in your local currency through Google Play.", textAlign: TextAlign.center, style: TextStyle(color: EbTok.textLo, fontSize: 12))),
          Row(children: [
            const Padding(padding: EdgeInsets.fromLTRB(8, 16, 0, 10), child: Text('PRICE', style: EbTok.label)),
            IconButton(
              tooltip: 'What is the price?',
              iconSize: 18,
              icon: const Icon(Icons.info_outline_rounded, color: EbTok.mint),
              onPressed: () => showEbPopup<void>(context, (c) => _InfoBody(onClose: () => Navigator.pop(c))),
            ),
          ]),
          EbTicket(
            photo: EbCircle(url: book.cover, size: 64, ring: a),
            accent: a,
            tag: 'E-BOOK',
            badge: owned ? 'OWNED' : null,
            label: book.sub,
            value: owned ? 'Yours' : money(scope.data.priceCents(book)),
            action: owned ? 'Open in Reader >' : 'Buy >',
            onTap: () => owned ? openReader(context, scope, book) : scope.actions.doBuy(context, book),
          ),
          if (!owned) ...[
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              EbPill('Gift', white: false, icon: Icons.card_giftcard_rounded, onTap: () => scope.actions.doGift(context, book)),
              const SizedBox(width: 12),
              EbPill('Add coupon', white: false, icon: Icons.confirmation_number_outlined, onTap: () => scope.actions.doCoupon(context, book)),
            ]),
          ],
          const Padding(padding: EdgeInsets.fromLTRB(8, 22, 8, 10), child: Text('CHAPTERS', style: EbTok.label)),
          EbGlass(
            key: const Key('eb-chapters'),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              for (var n = 0; n < book.contents.length; n++)
                ListTile(
                  dense: true,
                  leading: Text('${n + 1}', style: const TextStyle(color: EbTok.mint, fontWeight: FontWeight.w800)),
                  title: Text(book.contents[n], style: const TextStyle(color: Colors.white)),
                  trailing: Icon(owned || n == 0 ? Icons.chevron_right_rounded : Icons.lock_outline_rounded, color: Colors.white54, size: 18),
                  onTap: () => openReader(context, scope, book, chapter: n),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          const Text(kEbDisclaimer, style: TextStyle(color: EbTok.textLo, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _InfoBody extends StatelessWidget {
  const _InfoBody({required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Price', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('One payment. The book is yours to read anytime in the Reader.', style: TextStyle(color: EbTok.textLo, height: 1.5)),
        const SizedBox(height: 8),
        const Text('Shown in your local currency; coins can cover part of it at checkout.', style: TextStyle(color: EbTok.gold, height: 1.5)),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerRight, child: EbPill('Got it', onTap: onClose)),
      ]);
}

/// Basic reader: one chapter per page, swipe or Prev / Next, text size, a
/// progress bar, and chapter 1 free as the sample; later chapters ask to buy.
class EbookReaderV2 extends StatefulWidget {
  const EbookReaderV2({super.key, required this.scope, required this.book, this.start = 0});
  final EbooksScope scope;
  final EbBook book;
  final int start;
  @override
  State<EbookReaderV2> createState() => _EbookReaderV2State();
}

class _EbookReaderV2State extends State<EbookReaderV2> {
  late int _ch = widget.start.clamp(0, _count - 1);
  double _size = 17;
  int get _count => widget.book.contents.isEmpty ? 1 : widget.book.contents.length;
  bool get _owned => widget.scope.data.owns(widget.book);
  bool _locked(int n) => !_owned && n > 0;

  void _go(int n) {
    if (n < 0 || n >= _count) return;
    setState(() => _ch = n);
    if (!_locked(n)) widget.scope.data.saveProgress(widget.book, n);
  }

  String _title(int n) => widget.book.contents.isEmpty ? widget.book.title : widget.book.contents[n];

  @override
  Widget build(BuildContext context) {
    final b = widget.book;
    final locked = _locked(_ch);
    return _Frame(
      scope: widget.scope,
      title: b.title,
      actions: [
        IconButton(tooltip: 'Text size', icon: const Icon(Icons.text_fields_rounded), onPressed: _sizeSheet),
        IconButton(tooltip: 'Chapters', icon: const Icon(Icons.list_rounded), onPressed: _chaptersSheet),
      ],
      body: Column(children: [
        LinearProgressIndicator(key: const Key('eb-progress'), value: (_ch + 1) / _count, color: EbTok.mint, backgroundColor: Colors.white12, minHeight: 3),
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (d) => _go(_ch + ((d.primaryVelocity ?? 0) < 0 ? 1 : -1)),
            child: ListView(key: const Key('eb-reader'), padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
              EbGlass(
                radius: 24,
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('CHAPTER ${_ch + 1} OF $_count', style: EbTok.label),
                  const SizedBox(height: 8),
                  Text(_title(_ch), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 14),
                  if (locked)
                    Column(key: const Key('eb-locked'), crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('This chapter is part of the full book. Chapter 1 is free to read as a sample.', style: TextStyle(color: EbTok.textLo, height: 1.5)),
                      const SizedBox(height: 14),
                      EbPill('Buy to keep reading', onTap: () => widget.scope.actions.doBuy(context, b)),
                    ])
                  else
                    Text(
                      _ch == 0 ? '${b.about}\n\n${b.sub}' : '${b.about}\n\nThis chapter continues the book: ${_title(_ch).toLowerCase()}.',
                      style: TextStyle(color: Colors.white, fontSize: _size, height: 1.65),
                    ),
                ]),
              ),
            ]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(children: [
              EbPill('Previous', white: false, onTap: _ch > 0 ? () => _go(_ch - 1) : null),
              const Spacer(),
              EbDots(count: _count.clamp(1, 8), index: _ch.clamp(0, 7)),
              const Spacer(),
              _ch < _count - 1 ? EbPill('Next', onTap: () => _go(_ch + 1)) : EbPill('Done', onTap: () => Navigator.pop(context)),
            ]),
          ),
        ),
      ]),
    );
  }

  void _sizeSheet() => showEbPopup<void>(
        context,
        (c) => StatefulBuilder(
          builder: (c, set) => Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Text size', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            Slider(
              key: const Key('eb-size'),
              value: _size,
              min: 13,
              max: 26,
              divisions: 13,
              activeColor: EbTok.mint,
              onChanged: (v) {
                set(() {});
                setState(() => _size = v);
              },
            ),
            Text('Aa  ${_size.round()}', style: TextStyle(color: Colors.white, fontSize: _size)),
            const SizedBox(height: 12),
            EbPill('Done', onTap: () => Navigator.pop(c)),
          ]),
        ),
      );

  void _chaptersSheet() => showEbPopup<void>(
        context,
        (c) => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Chapters', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (var n = 0; n < _count; n++)
            ListTile(
              dense: true,
              title: Text('${n + 1}. ${_title(n)}', style: TextStyle(color: n == _ch ? EbTok.mint : Colors.white)),
              trailing: _locked(n) ? const Icon(Icons.lock_outline_rounded, color: Colors.white54, size: 18) : null,
              onTap: () {
                Navigator.pop(c);
                _go(n);
              },
            ),
        ]),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => ListView(key: const Key('eb-loading'), padding: const EdgeInsets.all(16), children: const [
        EbGlass(radius: 30, child: SizedBox(height: 380)),
        SizedBox(height: 14),
        EbGlass(radius: 22, child: SizedBox(height: 64)),
        SizedBox(height: 12),
        EbGlass(radius: 22, child: SizedBox(height: 64)),
      ]);
}

class _StateCard extends StatelessWidget {
  const _StateCard({super.key, required this.icon, required this.title, required this.text, required this.cta, this.onCta});
  final IconData icon;
  final String title, text;
  final String? cta;
  final VoidCallback? onCta;
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: EbMedCard(photo: EbCircle(url: '', icon: icon), title: title, body: text, cta: cta ?? 'OK', onCta: onCta ?? () => Navigator.maybePop(context)),
        ),
      );
}

/// First-use guide (spec 19.1): Browse → Preview → Read anywhere.
Future<void> showEbooksGuide(BuildContext context) => showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black54,
      pageBuilder: (c, _, __) => SafeArea(
        child: Center(
          child: Padding(padding: const EdgeInsets.all(24), child: Material(type: MaterialType.transparency, child: _Guide(onDone: () => Navigator.pop(c)))),
        ),
      ),
    );

class _Guide extends StatefulWidget {
  const _Guide({required this.onDone});
  final VoidCallback onDone;
  @override
  State<_Guide> createState() => _GuideState();
}

class _GuideState extends State<_Guide> {
  static const _slides = [
    (Icons.auto_stories_rounded, 'Browse', 'Swipe the cards or search for a book. Tap the heart to save one for later.'),
    (Icons.visibility_rounded, 'Preview', 'Open a book to see its chapters and read chapter 1 free.'),
    (Icons.menu_book_rounded, 'Read anywhere', 'Books you buy live in My books. The Reader keeps your place and text size.'),
  ];
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final s = _slides[_i];
    final last = _i == _slides.length - 1;
    return EbMedCard(
      key: const Key('eb-guide'),
      photo: EbCircle(url: '', icon: s.$1),
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
