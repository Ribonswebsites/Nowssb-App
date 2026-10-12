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
import '../../media/video_pool.dart';
import '../../theme/tokens.dart';
import '../../widgets/nwsb_icon.dart';
import '../word_detail.dart';
import '../../widgets/glass_black_card.dart';
import '../../theme/ui_tokens.dart';
import 'bag_ui.dart';
import 'store_actions.dart';
import 'store_cards.dart';
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
          ? Entitlements.instance
              .canOpenStoreWord(word, signature: true, price: kMsSignaturePrice)
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
            ? 'The rarest word in its collection. One signature exists per collection, it is never discounted on its own, and it is never restocked.'
            : 'Every word carries a vibrational signature that predates its dictionary definition. Unlock the phonetic origin of ${_titleCase(word)} — what the sound does inside your body, and where it existed before anyone wrote it down.',
        highlights: const [
          'Native pronunciation audio, generated on demand',
          'Full phonetic root breakdown and origin story',
          'Permanent access — owned words never expire',
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
  final blurb = kMsWordBlurb[m.key] ??
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

  void _wish() {
    CartBag.instance.addWishlist(_bagItem);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Saved to wishlist'),
        behavior: SnackBarBehavior.floating));
  }

  void _buy() {
    if (_open) {
      Navigator.of(context).pop();
      return;
    }
    storeBuyNow(context, _bagItem);
  }

  void _about() => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(UiSpace.md),
            child: GlassBlackCard(
              child: Text(disclaimer == null ? about : '$about\n\n$disclaimer',
                  style: const TextStyle(
                      color: Color(0xB3FFFFFF), fontSize: 13, height: 1.5)),
            ),
          ),
        ),
      );

  /// Rebuild C (Ribon 8:26): Myntra item layout on the original NowssB
  /// colours, glass and media — hero art, name, price, Wishlist + Add to Bag
  /// side by side, one full-width Buy. Nothing else.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable:
          Listenable.merge([StorePrices.instance, Entitlements.instance]),
      builder: (context, _) {
        final priceText = _open
            ? (price <= 0
                ? 'Free'
                : (Entitlements.instance.ownsItem(_id)
                    ? 'Owned'
                    : 'In your plan'))
            : inr(price);
        return PageShell(
          eyebrow: '',
          title: 'NowssB Store',
          subtitle: title,
          film: 'assets/video/player-bg-loop.mp4',
          usePageFilm: false,
          background: const ColoredBox(color: NwsbColors.deep),
          onBack: () => Navigator.of(context).pop(),
          onStorePicker: () => showStoreSelectSheet(
            context,
            onSelect: (id) => openStoreFromPicker(context, id, current: ''),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
              sliver: SliverList.list(children: [
                GlassBlackCard(
                  padding: const EdgeInsets.all(UiSpace.sm),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(UiRadii.card - UiSpace.sm),
                    child: AspectRatio(
                      aspectRatio: heroVideo != null ? 16 / 9 : 1,
                      child: heroVideo != null
                          ? NwsbVideo(
                              asset: heroVideo!,
                              priority: ClipPriority.feature,
                              slot: 'product_detail.StoreProductPage',
                            )
                          : StoreNetImage(url: img, word: title),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: EditableLabel(
                        'product_detail.StoreProductPage', title,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1)),
                  ),
                  IconButton(
                    tooltip: 'About',
                    onPressed: _about,
                    icon: const Icon(Icons.info_outline,
                        color: Color(0x80FFFFFF)),
                  ),
                ]),
                const SizedBox(height: 10),
                Text(priceText,
                    style: const TextStyle(
                        color: NwsbColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),
                Row(children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _wish,
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: const Text('Wishlist'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0x40FFFFFF)),
                            shape: const StadiumBorder()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        key: _addCartKey,
                        onPressed: _open
                            ? null
                            : () => storeAddToCart(context, _bagItem,
                                origin: _addCartKey),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('Add to Bag'),
                        style: FilledButton.styleFrom(
                            backgroundColor: NwsbColors.gold,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: const Color(0x22FFFFFF),
                            shape: const StadiumBorder()),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _buy,
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder()),
                    child: Text(_open ? 'Open in Library' : 'Buy Now',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ],
        );
      },
    );
  }
}

class _ActBtn extends StatelessWidget {
  const _ActBtn({
    super.key,
    required this.label,
    required this.mark,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final String mark;
  final bool filled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ink = filled ? NwsbColors.ink : const Color(0xB8FFFFFF);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: filled ? 8 : 15,
          horizontal: filled ? 8 : 0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: filled
              ? const LinearGradient(
                  colors: [Color(0xF2E8D5A3), Color(0xE6C8A96E)],
                )
              : null,
          color: filled ? null : const Color(0x14FFFFFF),
          border: filled ? null : Border.all(color: const Color(0x24FFFFFF)),
        ),
        child: Row(
          mainAxisAlignment: filled
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.center,
          children: [
            if (filled) const SizedBox(width: 8),
            if (!filled) NwsbIcon(mark, size: 16, color: ink),
            if (!filled) const SizedBox(width: 8),
            EditableLabel(
              'product_detail.ActBtn',
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled ? NwsbColors.ink : const Color(0xB8FFFFFF),
              ),
            ),
            if (!filled) const SizedBox.shrink(),
            if (filled)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: NwsbIcon(mark, size: 16, color: NwsbColors.ink),
              ),
          ],
        ),
      ),
    );
  }
}
