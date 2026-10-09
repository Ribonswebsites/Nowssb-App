/// Product detail sheets for Store catalogue items (Word / Meaning / Ebook).
/// Mirrors website rmd-* / ms-detail / ebd layouts without inventing copy.
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/store_catalog.dart';
import '../../data/cart_bag.dart';
import '../../data/entitlements.dart';
import '../../data/store_prices.dart';
import '../../data/word_art.dart';
import '../../widgets/page_shell.dart';
import 'store_routes.dart';
import 'store_select_sheet.dart';
import '../../media/nwsb_video.dart';
import '../word_detail.dart';
import 'store_actions.dart';
import 'store_cards.dart';
import 'cart_pages.dart';
import '../../admin/template/editable.dart';

void openAtelierWord(
  BuildContext context, {
  required String word,
  required String root,
  required String img,
  bool signature = false,
  num price = 0,
}) {
  final key = word.toLowerCase();
  final found = ContentStore.instance.library
      .where((w) => w.key == key || w.word.toLowerCase() == key)
      .toList();
  // A library word opens straight in Word Detail only when this account can
  // already open it; otherwise the product page with its Buy button.
  final open = found.isNotEmpty &&
      (signature
          ? Entitlements.instance.canOpenStoreWord(word, signature: true, price: kMsSignaturePrice)
          : Entitlements.instance.canOpenWord(found.first));
  if (open) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WordDetail(word: found.first)),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => StoreProductPage(
        kind: signature ? 'Signature Word' : 'Natural Origin',
        title: _titleCase(word),
        root: root,
        img: img,
        price: signature ? kMsSignaturePrice : price,
        about: signature
            ? 'One signature word in this collection. It is not discounted on its own, and it is not restocked.'
            : '${_titleCase(word)} · $root. A word in the NowssB catalogue. Unlock it once and it stays on this account.',
        highlights: const [
          'Spoken once you own it',
          'Root and origin on the card',
          'Stays on this account',
        ],
      ),
    ),
  );
}

void openMeaningDetail(
  BuildContext context,
  MsMeaning m, {
  bool signature = false,
}) {
  final blurb =
      kMsWordBlurb[m.key] ??
      'Every word carries a vibration that predates its dictionary definition. Unlock the true phonetic origin of ${m.word}.';
  Navigator.of(context).push(
    MaterialPageRoute<void>(
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
    ),
  );
}

void openEbookDetail(BuildContext context, EbBook b) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
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
    ),
  );
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

class StoreProductPage extends StatefulWidget {
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
    this.itemId,
  });

  /// Bag / ownership id (word:x, signature:x, meaning:x, ebook:x). Derived
  /// from [kind] when not given.
  final String? itemId;

  final String kind, title, root, img, about;
  final num price;
  final List<String> highlights;
  final String? disclaimer;

  /// Meaning detail hero clip (MS_MEANING_VID) — remote HTTPS URL.
  final String? heroVideo;

  @override
  State<StoreProductPage> createState() => _StoreProductPageState();
}

class _StoreProductPageState extends State<StoreProductPage> {
  final _addCartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WordArt.instance.addListener(_onArt);
  }

  @override
  void dispose() {
    WordArt.instance.removeListener(_onArt);
    super.dispose();
  }

  void _onArt() {
    if (mounted) setState(() {});
  }

  String get kind => widget.kind;
  String get title => widget.title;
  String get root => widget.root;
  String get img => WordArt.instance.imageFor(title, widget.img);
  String get _id {
    if (widget.itemId != null) return widget.itemId!;
    final k = kind.toLowerCase();
    final t = title.toLowerCase();
    if (k.contains('ebook')) return 'ebook:$t';
    if (k.contains('meaning')) return 'meaning:$t';
    if (k.contains('signature')) return 'signature:$t';
    return 'word:$t';
  }

  /// What Google Play charges for this item (admin price, else default).
  num get price => StorePrices.instance.priceFor(_id, shown: widget.price);
  bool get _open => Entitlements.instance.ownsOrIncluded(_id, price: price);
  String get about => widget.about;
  List<String> get highlights => widget.highlights;
  String? get disclaimer => widget.disclaimer;
  String? get heroVideo => widget.heroVideo;

  BagItem get _bagItem => BagItem(
    id: _id,
    title: title,
    subtitle: root,
    image: img,
    price: price,
    kind: kind,
  );

  @override
  Widget build(BuildContext context) {
    // Same Store shell as the departments, cart and checkout.
    return ListenableBuilder(
      listenable: Listenable.merge([StorePrices.instance, Entitlements.instance]),
      builder: (context, _) => PageShell(
      eyebrow: '',
      title: 'NowssB Store',
      subtitle: title,
      film: '',
      plain: false,
      canvas: const Color(0xFF101010),
      usePageFilm: false,
      bodyMax: 980,
      onBack: () => Navigator.of(context).pop(),
      onStorePicker: () => showStoreSelectSheet(
        context,
        onSelect: (id) => openStoreFromPicker(context, id, current: ''),
      ),
      actions: [
        IconButton(
          tooltip: 'Cart',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CartPage()),
          ),
          icon: ListenableBuilder(
            listenable: CartBag.instance,
            builder: (_, __) {
              final n = CartBag.instance.cartCount;
              return Badge(
                isLabelVisible: n > 0,
                label: Text('$n'),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
              );
            },
          ),
        ),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
                [
                  LayoutBuilder(builder: (context, box) {
                    final wide = box.maxWidth >= 680;
                    final image = ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 6), blurRadius: 0)],
                        ),
                        child: SizedBox(
                        width: wide ? 320 : 260,
                        height: wide ? 320 : 260,
                        child: ColoredBox(
                          color: const Color(0xFF0A0A0A),
                          child: ListenableBuilder(
                            listenable: WordArt.instance,
                            builder: (_, __) {
                              final src = WordArt.instance.imageFor(title, img);
                              if (src.isEmpty || src == kRmWordImg) {
                                return WordSpecimen(word: title, root: root);
                              }
                              return StoreNetImage(url: src, word: title);
                            },
                          ),
                        ),
                      ),
                    ),
                    );
                    final info = _details();
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: image),
                          info,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        image,
                        const SizedBox(width: 28),
                        Expanded(child: info),
                      ],
                    );
                  }),
                ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _details() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.6,
              color: Color(0xFF9A9A9A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          EditableLabel(
            'product_detail.StoreProductPage',
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            root,
            style: const TextStyle(fontSize: 13, color: Color(0xFFB0B0B0)),
          ),
          const SizedBox(height: 10),
          Text(
            _open
                ? (price <= 0
                    ? 'Free'
                    : (Entitlements.instance.ownsItem(_id) ? 'Owned' : 'Included in your plan'))
                : inr(price),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActBtn(
                  label: 'Wishlist',
                  filled: false,
                  onTap: () {
                    CartBag.instance.addWishlist(_bagItem);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Saved $title to wishlist'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActBtn(
                  key: _addCartKey,
                  label: 'Add to cart',
                  filled: false,
                  onTap: () {
                    storeAddToCart(context, _bagItem, origin: _addCartKey);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $title to cart'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ActBtn(
            label: _open ? 'Yours — open it in the Library' : 'Buy on Google Play',
            filled: true,
            onTap: () {
              if (_open) {
                Navigator.of(context).pop();
                return;
              }
              storeBuyNow(context, _bagItem, origin: _addCartKey);
            },
          ),
          const SizedBox(height: 22),
          const EditableLabel(
            'product_detail.StoreProductPage',
            'ABOUT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            about,
            style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFFD6D6D6)),
          ),
          const SizedBox(height: 18),
          const EditableLabel(
            'product_detail.StoreProductPage',
            "WHAT'S INCLUDED",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          for (final h in highlights)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 15, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      h,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFE8E8E8)),
                    ),
                  ),
                ],
              ),
            ),
          if (disclaimer != null) ...[
            const SizedBox(height: 16),
            Text(
              disclaimer!,
              style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF9A9A9A)),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActBtn extends StatelessWidget {
  const _ActBtn({
    super.key,
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final bool filled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: filled ? Colors.white : const Color(0xFF161616),
          border: Border.all(color: filled ? Colors.white : const Color(0x44FFFFFF)),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: EditableLabel(
          'product_detail.ActBtn',
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: filled ? const Color(0xFF101010) : Colors.white,
          ),
        ),
      ),
    );
  }
}

