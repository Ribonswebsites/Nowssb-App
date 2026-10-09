/// Store departments as a plain catalogue: search, a chip per collection,
/// a tight product grid. No film, no glass, no stretched hero.
library;

import 'package:flutter/material.dart';

import '../../admin/layout/layout_sections.dart';
import '../../data/cart_bag.dart';
import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import '../../widgets/page_shell.dart';
import 'product_detail.dart';
import 'store_actions.dart';
import 'store_cards.dart';
import 'store_routes.dart';
import 'store_select_sheet.dart';

class ShopProduct {
  const ShopProduct({
    required this.title,
    required this.line,
    required this.image,
    required this.itemId,
    required this.kind,
    required this.shown,
    required this.open,
    required this.bag,
  });

  final String title;
  final String line;
  final String image;
  final String itemId;
  final String kind;
  final num shown;
  final void Function(BuildContext context) open;
  final BagItem bag;
}

class ShopGroup {
  const ShopGroup({required this.id, required this.label, required this.products});
  final String id;
  final String label;
  final List<ShopProduct> products;
}

String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');

List<ShopGroup> wordShopGroups() => [
      for (final c in kRmCategories)
        ShopGroup(
          id: _slug(c.id),
          label: c.label,
          products: [
            for (final w in c.words)
              ShopProduct(
                title: _title(w.word),
                line: w.root,
                image: kRmWordImg,
                itemId: 'word:${w.word.toLowerCase()}',
                kind: 'Word',
                shown: 0,
                open: (ctx) => openAtelierWord(ctx, word: w.word, root: w.root, img: kRmWordImg),
                bag: wordBagItem(name: w.word, root: w.root, img: kRmWordImg),
              ),
          ],
        ),
    ];

List<ShopGroup> meaningShopGroups() {
  final by = <String, List<MsMeaning>>{};
  for (final m in kMsBaseMeanings) {
    by.putIfAbsent(m.category, () => []).add(m);
  }
  return [
    for (final e in by.entries)
      ShopGroup(
        id: _slug(e.key),
        label: e.key,
        products: [
          for (final m in e.value)
            ShopProduct(
              title: m.word,
              line: m.root,
              image: m.img,
              itemId: 'meaning:${m.word.toLowerCase()}',
              kind: 'Meaning',
              shown: m.price,
              open: (ctx) => openMeaningDetail(ctx, m),
              bag: meaningBagItem(word: m.word, root: m.root, img: m.img, price: m.price),
            ),
        ],
      ),
  ];
}

List<ShopGroup> signatureShopGroups() {
  final words = <ShopProduct>[
    for (final c in kRmCategories)
      if (c.signature != null)
        ShopProduct(
          title: c.signature!.name,
          line: c.label,
          image: c.signature!.img,
          itemId: 'signature:${c.signature!.name.toLowerCase()}',
          kind: 'Signature',
          shown: kMsSignaturePrice,
          open: (ctx) => openAtelierWord(
            ctx,
            word: c.signature!.name,
            root: c.label,
            img: c.signature!.img,
            signature: true,
            price: kMsSignaturePrice,
          ),
          bag: wordBagItem(
            name: c.signature!.name,
            root: c.label,
            img: c.signature!.img,
            signature: true,
            price: kMsSignaturePrice,
          ),
        ),
  ];
  final meanings = <ShopProduct>[
    for (final e in kMsSignature.entries)
      ShopProduct(
        title: e.value.word,
        line: e.value.root,
        image: kMsSignatureImg,
        itemId: 'meaning:${e.value.word.toLowerCase()}',
        kind: 'Signature Meaning',
        shown: kMsSignaturePrice,
        open: (ctx) => openMeaningDetail(
          ctx,
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
        bag: meaningBagItem(
          word: e.value.word,
          root: e.value.root,
          img: kMsSignatureImg,
          price: kMsSignaturePrice,
          signature: true,
        ),
      ),
  ];
  return [
    ShopGroup(id: 'words', label: 'Signature words', products: words),
    ShopGroup(id: 'meanings', label: 'Signature meanings', products: meanings),
  ];
}

List<ShopGroup> ebookShopGroups() => [
      ShopGroup(
        id: 'books',
        label: 'Books',
        products: [
          for (final b in kEbBooks)
            ShopProduct(
              title: b.title,
              line: b.sub,
              image: b.cover,
              itemId: 'ebook:${b.title.toLowerCase()}',
              kind: 'Ebook',
              shown: b.price,
              open: (ctx) => openEbookDetail(ctx, b),
              bag: ebookBagItem(title: b.title, sub: b.sub, img: b.cover, price: b.price),
            ),
        ],
      ),
    ];

String _title(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class NwsbShopPage extends StatefulWidget {
  const NwsbShopPage({
    super.key,
    required this.pageId,
    required this.which,
    required this.title,
    required this.groups,
  });

  final String pageId;
  final String which;
  final String title;
  final List<ShopGroup> groups;

  @override
  State<NwsbShopPage> createState() => _NwsbShopPageState();
}

class _NwsbShopPageState extends State<NwsbShopPage> {
  final _search = TextEditingController();
  String _q = '';
  String _chip = 'ALL';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ShopGroup> get _shown {
    final q = _q.trim().toLowerCase();
    final out = <ShopGroup>[];
    for (final g in widget.groups) {
      if (_chip != 'ALL' && g.id != _chip) continue;
      final products = [
        for (final p in g.products)
          if (q.isEmpty || p.title.toLowerCase().contains(q) || p.line.toLowerCase().contains(q)) p,
      ];
      if (products.isEmpty) continue;
      out.add(ShopGroup(id: g.id, label: g.label, products: products));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _shown;
    return PageShell(
      eyebrow: '',
      title: 'NowssB Store',
      subtitle: widget.title,
      film: '',
      plain: true,
      usePageFilm: false,
      bodyMax: 1120,
      onBack: () => Navigator.of(context).pop(),
      onStorePicker: () => showStoreSelectSheet(
        context,
        current: widget.which,
        onSelect: (id) => openStoreFromPicker(context, id, current: widget.which),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
          sliver: SliverToBoxAdapter(
            child: ListenableBuilder(
              listenable: StorePrices.instance,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: layoutChildren(context, widget.pageId, [
                  LSection('find', 'Search', _searchBox()),
                  LSection('chips', 'Collections', _chips()),
                  for (final g in groups) LSection(g.id, g.label, _block(g)),
                  if (groups.isEmpty)
                    const LSection(
                      'empty',
                      'No matches',
                      Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nothing matches that search.', style: TextStyle(color: Color(0xFF6A6258))),
                      ),
                    ),
                ], tabletRail: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4EE),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0xFFD5D0C6), offset: Offset(4, 4), blurRadius: 10),
            BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-4, -4), blurRadius: 10),
          ],
        ),
        child: TextField(
          controller: _search,
          onChanged: (v) => setState(() => _q = v),
          style: const TextStyle(color: Color(0xFF16181E), fontSize: 15),
          cursorColor: const Color(0xFF16181E),
          decoration: InputDecoration(
            hintText: 'Search ${widget.title}',
            hintStyle: const TextStyle(color: Color(0xFF8A847A), fontSize: 15),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF16181E), size: 20),
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFF16181E), width: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chips() {
    final chips = ['ALL', for (final g in widget.groups) g.id];
    final labels = {'ALL': 'All', for (final g in widget.groups) g.id: g.label};
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final id = chips[i];
          final on = id == _chip;
          return GestureDetector(
            onTap: () => setState(() => _chip = id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? const Color(0xFF16181E) : const Color(0xFFF7F4EE),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFD5D0C6), offset: Offset(3, 3), blurRadius: 8),
                  BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-3, -3), blurRadius: 8),
                ],
              ),
              child: Text(
                labels[id] ?? id,
                style: TextStyle(
                  color: on ? Colors.white : const Color(0xFF16181E),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _block(ShopGroup g) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(g.label, style: const TextStyle(color: Color(0xFF16181E), fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(g.products.length == 1 ? '1 item' : '${g.products.length} items', style: const TextStyle(color: Color(0xFF8A847A), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth;
            final cols = w >= 1000 ? 5 : w >= 760 ? 4 : w >= 520 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: g.products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: widget.which == 'word' ? 0.86 : _cardRatio(w, cols),
              ),
              itemBuilder: (_, i) => _card(g.products[i]),
            );
          }),
        ],
      ),
    );
  }

  double _cardRatio(double width, int cols) {
    final cell = (width - (cols - 1) * 10) / cols;
    return cell / (cell + 92);
  }

  Widget _card(ShopProduct p) {
    final price = StorePrices.instance.priceFor(p.itemId, kind: p.kind.toLowerCase().contains('ebook') ? 'ebook' : null, shown: p.shown);
    if (widget.which == 'word') {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => p.open(context),
        child: WordSpecimen(
          word: p.title,
          root: p.line,
          priceLabel: _ask(price),
          onAdd: () => storeAddToCart(context, p.bag),
        ),
      );
    }
    return Material(
      color: const Color(0xFFF7F4EE),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => p.open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: ColoredBox(
                color: const Color(0xFFE7E1D6),
                child: StoreNetImage(url: p.image, word: p.title),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF16181E), fontSize: 14, fontWeight: FontWeight.w800)),
                    Text(p.line, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF6A6258), fontSize: 11)),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _ask(price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF16181E), fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => storeAddToCart(context, p.bag),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16181E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text('ADD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ask(num price) {
    if (price <= 0) return 'Free';
    final n = price.round();
    final s = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '₹$buf';
  }
}
