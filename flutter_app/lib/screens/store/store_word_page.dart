/// The Store word / meaning page, laid out like Ribon's Nov 23 reference
/// (a travel app's "Nature Power" page): a bold title, small category pills,
/// one big picture that shows what the word means with the word and a short
/// line over it, small stat chips, the buy actions, then sections as cards
/// and a list of more words with pictures, chips and a favourite star.
///
/// Only the layout comes from the reference. Colours and glass are NowssB's
/// own (GlassWrap / KitPane from restyle_kit), and the actions are the same
/// working Wishlist, Add to Cart and Yours / Buy buttons as before.
library;

import 'package:flutter/material.dart';

import '../../data/app_haptics.dart';
import '../../data/cart_bag.dart';
import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import '../../data/word_art.dart';
import '../../data/word_photos.dart';
import '../../data/word_posters.dart';
import '../../theme/tokens.dart';
import '../../widgets/restyle_kit.dart';
import '../poster/poster_kit.dart' show inr;
import 'store_actions.dart';
import 'store_cards.dart' show StoreNetImage;

/// The picture a Store word or meaning page shows: an admin-set picture,
/// else the word's practice poster, else its own photograph, else [fallback].
String storeWordPicture(String word, String fallback) {
  final admin = WordArt.instance.imageOf(word);
  if (admin != null && admin.isNotEmpty) return admin;
  return wordPosterFor(word) ?? wordPhotoFor(word) ?? fallback;
}

/// One more word for the "More in …" list.
class StoreWordLink {
  const StoreWordLink({required this.word, required this.root, this.meaning});
  final String word;
  final String root;
  final MsMeaning? meaning;
  String get title => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}';
  String get id => meaning != null ? 'meaning:${word.toLowerCase()}' : 'word:${word.toLowerCase()}';
}

/// What the catalogue knows about a word, for the pills and chips.
class StoreWordFacts {
  const StoreWordFacts({
    required this.category,
    required this.categorySub,
    required this.origin,
    required this.rootForm,
    required this.family,
    required this.line,
    required this.related,
  });

  final String category;
  final String categorySub;

  /// The source language ("Greek", "Proto-Germanic").
  final String origin;

  /// The old form when the catalogue has one ("erþō"), else ''.
  final String rootForm;

  /// The language family [origin] belongs to, or ''.
  final String family;

  /// The short line over the picture.
  final String line;
  final List<StoreWordLink> related;

  static StoreWordFacts of(String title, String root, {required bool meaning}) {
    final key = WordArt.keyOf(title);
    final parts = root.split('·');
    final origin = parts.first.trim();
    final rootForm = parts.length > 1 ? parts.sublist(1).join('·').trim() : '';
    if (meaning) {
      MsMeaning? m;
      for (final e in kMsBaseMeanings) {
        if (e.key == key) m = e;
      }
      final cat = m?.category ?? '';
      return StoreWordFacts(
        category: cat,
        categorySub: kMsCatSub[cat] ?? '',
        origin: origin,
        rootForm: rootForm,
        family: languageFamily(origin),
        line: plainText(kMsWordBlurb[key] ?? kMsCatSub[cat] ?? ''),
        related: [
          for (final e in kMsBaseMeanings)
            if (e.category == cat && e.key != key) StoreWordLink(word: e.word, root: e.root, meaning: e),
        ],
      );
    }
    RmCategory? cat;
    for (final c in kRmCategories) {
      if (c.id == 'off50') continue;
      if (c.words.any((w) => WordArt.keyOf(w.word) == key)) {
        cat = c;
        break;
      }
    }
    return StoreWordFacts(
      category: cat?.label ?? '',
      categorySub: cat?.sub ?? '',
      origin: origin,
      rootForm: rootForm,
      family: languageFamily(origin),
      line: cat?.sub ?? '',
      related: [
        if (cat != null)
          for (final w in cat.words)
            if (WordArt.keyOf(w.word) != key) StoreWordLink(word: w.word, root: w.root),
      ],
    );
  }
}

/// The family a source language belongs to (plain linguistics), or ''.
String languageFamily(String origin) {
  final o = origin.toLowerCase();
  const romance = ['latin', 'old french', 'french', 'italian', 'spanish', 'portuguese'];
  const germanic = ['old english', 'middle english', 'proto-germanic', 'old norse', 'dutch', 'german'];
  if (romance.contains(o)) return 'Romance';
  if (germanic.contains(o)) return 'Germanic';
  if (o.contains('greek')) return 'Hellenic';
  if (o == 'proto-indo-european') return 'Indo-European';
  if (o == 'sanskrit' || o == 'hindi' || o == 'persian') return 'Indo-Iranian';
  if (o == 'japanese') return 'Japonic';
  if (o == 'arabic' || o == 'hebrew' || o == 'phoenician' || o == 'akkadian') return 'Semitic';
  if (o == 'ancient egyptian') return 'Afroasiatic';
  if (o == 'scottish gaelic') return 'Celtic';
  if (o == 'ojibwe') return 'Algonquian';
  if (o == 'tungus') return 'Tungusic';
  return '';
}

/// Catalogue copy ported from the website carries HTML entities.
String plainText(String s) => s
    .replaceAll('&rsquo;', '’')
    .replaceAll('&lsquo;', '‘')
    .replaceAll('&mdash;', '—')
    .replaceAll('&amp;', '&');

/// Drops marks the app font cannot draw (the PIE syllabic ring below and
/// subscript laryngeal digits), so a root never shows an empty box.
String drawableRoot(String s) => s
    .replaceAll('\u0325', '')
    .replaceAll('\u0329', '')
    .replaceAllMapped(RegExp('[₀-₉]'), (m) => '${m[0]!.codeUnitAt(0) - 0x2080}');

/// A small glass pill with a white icon badge (the reference's category
/// pills, in NowssB's glass).
class StoreWordPill extends StatelessWidget {
  const StoreWordPill({super.key, required this.icon, required this.label, this.strong = false});
  final IconData icon;
  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
      decoration: BoxDecoration(
        color: strong ? Colors.white : const Color(0x24FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: strong ? Colors.white : const Color(0x40FFFFFF)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: strong ? const Color(0xFF111118) : Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, size: 13, color: strong ? Colors.white : const Color(0xFF111118)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
              color: strong ? const Color(0xFF111118) : Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            )),
      ]),
    );
  }
}

/// A small dark glass stat chip that sits on the picture.
class StoreWordChip extends StatelessWidget {
  const StoreWordChip({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x59000000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// The favourite star: on when the item is on the wishlist. Tapping it adds
/// or removes it (one selection haptic, on the tap only).
class StoreWordStar extends StatelessWidget {
  const StoreWordStar({super.key, required this.item, this.size = 40, this.onDark = true});
  final BagItem Function() item;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartBag.instance,
      builder: (context, _) {
        final it = item();
        final on = CartBag.instance.inWish(it.id);
        return Semantics(
          button: true,
          toggled: on,
          label: on ? 'Remove ${it.title} from wishlist' : 'Save ${it.title} to wishlist',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptics.selection();
              if (on) {
                CartBag.instance.removeWishlist(it.id);
              } else {
                CartBag.instance.addWishlist(it);
              }
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: on ? Colors.white : (onDark ? const Color(0x59000000) : const Color(0x24FFFFFF)),
                borderRadius: BorderRadius.circular(size / 2),
                border: Border.all(color: on ? Colors.white : const Color(0x40FFFFFF)),
              ),
              child: Icon(on ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size * 0.52, color: on ? NwsbColors.ink : Colors.white),
            ),
          ),
        );
      },
    );
  }
}

/// The big picture card: the word's photograph, its kind tag and star on
/// top, and the word, its short line and stat chips over the bottom.
class StoreWordHero extends StatelessWidget {
  const StoreWordHero({
    super.key,
    required this.picture,
    required this.title,
    required this.tag,
    required this.line,
    required this.chips,
    required this.star,
  });

  final String picture;
  final String title;
  final String tag;
  final String line;
  final List<Widget> chips;
  final Widget star;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(fit: StackFit.expand, children: [
          StoreNetImage(url: picture),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .28, .5, 1],
                colors: [Color(0x66000000), Color(0x00000000), Color(0x14000000), Color(0xE6000000)],
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x59000000),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x40FFFFFF)),
              ),
              child: Text(tag.toUpperCase(), style: kKitEyebrow.copyWith(color: Colors.white, fontSize: 10)),
            ),
          ),
          Positioned(right: 12, top: 12, child: star),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(title,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1,
                    )),
              ),
              if (line.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(line,
                    style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 14, height: 1.4, fontWeight: FontWeight.w500)),
              ],
              if (chips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: chips),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// "More in <category>": cards with the word's picture, chips and a star.
class StoreWordMore extends StatelessWidget {
  const StoreWordMore({super.key, required this.category, required this.links, required this.onOpen});
  final String category;
  final List<StoreWordLink> links;
  final void Function(StoreWordLink link) onOpen;

  BagItem _item(StoreWordLink l) {
    final m = l.meaning;
    final pic = storeWordPicture(l.word, kNowssbWordFallback);
    if (m != null) return meaningBagItem(word: m.word, root: m.root, img: pic, price: m.price);
    return wordBagItem(name: l.title, root: l.root, img: pic, price: StorePrices.instance.priceFor(l.id));
  }

  @override
  Widget build(BuildContext context) {
    return KitPane(
      eyebrow: 'More words',
      title: category.isEmpty ? 'More words' : 'More in $category',
      mark: NwsbMarks.word,
      child: Column(children: [
        for (final l in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  AppHaptics.selection();
                  onOpen(l);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                  ),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: StoreNetImage(url: storeWordPicture(l.word, kNowssbWordFallback)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          _MiniChip(drawableRoot(l.root.split('·').first.trim())),
                          ListenableBuilder(
                            listenable: StorePrices.instance,
                            builder: (_, __) => _MiniChip(
                              inr(l.meaning != null ? StorePrices.instance.priceFor(l.id, shown: l.meaning!.price) : StorePrices.instance.priceFor(l.id), sku: l.id),
                              gold: true,
                            ),
                          ),
                        ]),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    StoreWordStar(item: () => _item(l), size: 36, onDark: false),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// A word with no picture of its own shows the NowssB Store box.
const kNowssbWordFallback = 'assets/store/nowssb-store-mark.png';

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label, {this.gold = false});
  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
            color: gold ? NwsbColors.goldLight : const Color(0xCCFFFFFF),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          )),
    );
  }
}
