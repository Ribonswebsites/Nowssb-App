/// The Store word / meaning page, built one-to-one on Ribon's Nov 23
/// reference (an outdoor travel app: "Hi, Morgan", the huge two-line
/// "Nature / Power" title with a tall search pill, a black chip row, a
/// cut-out forest photo with "The Sounds of Nature", three stat items and a
/// "Start Trip" pill over it, a "Popular" list with a dark avatar card and
/// tall photo cards, a detail card with a nested hotel card, and a floating
/// bottom bar) in NowssB's dark glass.
///
///  * "Hi, name 👋" and the coin balance in a white circle (the weather badge).
///  * The word's origin in small caps (the flag and country), in plain words.
///  * The word over its collection as the huge title; Wishlist is the tall pill.
///  * Meaning / Listen / Practice chips; the selected one is the white pill.
///  * The word's own photo as a soft cut-out with its headline, a two-line
///    meaning, three stat items and an outlined Add to Cart / Yours pill.
///  * A glass detail card with the price pills and a nested buy card.
///  * "More in <collection>": the dark avatar card and tall photo cards.
///
/// Every action works as before: wishlist, cart, buy or Yours, other words.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/app_haptics.dart';
import '../../data/cart_bag.dart';
import '../../data/store_catalog.dart';
import '../../data/store_prices.dart';
import '../../data/word_art.dart';
import '../../data/word_photos.dart';
import '../../data/word_posters.dart';
import '../../features/earn/earn_kit.dart' show earnFirstName;
import '../../features/economy/economy_api.dart' show EconomyMirror;
import '../../media/nwsb_video.dart';
import '../../media/video_pool.dart';
import '../../shell/tablet.dart' show isTablet;
import '../../theme/tokens.dart';
import '../../widgets/glass_wrap.dart';
import '../../widgets/nwsb_coin_fly.dart' show NwsbCoinDisc;
import '../poster/poster_kit.dart' show inr;
import 'bag_ui.dart';
import 'store_actions.dart';
import 'store_cards.dart' show StoreNetImage;

/// The picture a Store word or meaning page shows: an admin-set picture,
/// else the word's practice poster, else its own photograph, else [fallback].
String storeWordPicture(String word, String fallback) {
  final admin = WordArt.instance.imageOf(word);
  if (admin != null && admin.isNotEmpty) return admin;
  return wordPosterFor(word) ?? wordPhotoFor(word) ?? fallback;
}

/// True when [word] has a picture of its own (admin art, poster or photo);
/// false when the page shows the default Store art instead.
bool storeWordHasOwnPicture(String word) {
  final admin = WordArt.instance.imageOf(word);
  return (admin != null && admin.isNotEmpty) || wordPosterFor(word) != null || wordPhotoFor(word) != null;
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
    required this.line,
    required this.related,
  });

  final String category;
  final String categorySub;

  /// The source language ("Greek", "Proto-Germanic").
  final String origin;

  /// The old form when the catalogue has one ("erþō"), else ''.
  final String rootForm;

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
      line: cat?.sub ?? '',
      related: [
        if (cat != null)
          for (final w in cat.words)
            if (WordArt.keyOf(w.word) != key) StoreWordLink(word: w.word, root: w.root),
      ],
    );
  }
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

/// The source language in plain words a normal reader knows: no
/// "Proto-Indo-European" or "Tungus" labels.
String plainOrigin(String origin) {
  final o = drawableRoot(origin).trim();
  switch (o.toLowerCase()) {
    case 'proto-indo-european':
      return 'Ancient roots';
    case 'proto-germanic':
      return 'Old Germanic';
    case 'ancient greek':
      return 'Old Greek';
    case 'tungus':
      return 'Siberian';
    case 'ancient egyptian':
      return 'Old Egyptian';
  }
  return o;
}

const _kBg = Color(0xFF07090F);
const _kGlass = Color(0x1AFFFFFF);
const _kLine = Color(0x33FFFFFF);
const _kMuted = Color(0xA6FFFFFF);
const _kDarkCard = Color(0xF20D1312);

/// A word with no picture of its own shows the NowssB Store box.
const kNowssbWordFallback = 'assets/store/nowssb-store-mark.png';

/// The three chips under the title (the reference's Hiking / Kayaking /
/// Biking): what the panel over the photo talks about.
enum StoreWordMode { meaning, listen, practice }

/// The whole word / meaning page. The caller owns the shopping actions.
class StoreWordScreen extends StatefulWidget {
  const StoreWordScreen({
    super.key,
    required this.title,
    required this.meaning,
    required this.facts,
    required this.picture,
    required this.about,
    required this.highlights,
    required this.open,
    required this.price,
    required this.itemId,
    required this.item,
    required this.cartKey,
    required this.onAddToCart,
    required this.onBuy,
    required this.onOpenOwned,
    required this.onOpenLink,
    required this.onStorePicker,
    this.film = 'assets/video/subscription-bg.mp4',
  });

  final String title;
  final bool meaning;
  final StoreWordFacts facts;
  final String picture;
  final String about;
  final List<String> highlights;

  /// This account can already open it (owned or in its plan).
  final bool open;
  final num price;
  final String itemId;
  final BagItem Function() item;
  final GlobalKey cartKey;
  final VoidCallback onAddToCart;
  final VoidCallback onBuy;
  final VoidCallback onOpenOwned;
  final void Function(StoreWordLink link) onOpenLink;
  final VoidCallback onStorePicker;
  final String film;

  @override
  State<StoreWordScreen> createState() => _StoreWordScreenState();
}

class _StoreWordScreenState extends State<StoreWordScreen> {
  StoreWordMode _mode = StoreWordMode.meaning;

  String get _title => widget.title;
  StoreWordFacts get _f => widget.facts;
  int get _letters => _title.replaceAll(RegExp(r'[^A-Za-z]'), '').length;
  String get _origin => plainOrigin(_f.origin);
  String get _collection => _f.category.isNotEmpty ? _f.category : (widget.meaning ? 'Meanings' : 'Words');

  String get _priceLabel => widget.open ? 'Yours' : inr(widget.price, sku: widget.itemId);

  (String, String) get _panel {
    switch (_mode) {
      case StoreWordMode.meaning:
        final head = _f.categorySub.isNotEmpty ? _f.categorySub : 'What $_title means';
        return (head, widget.about);
      case StoreWordMode.listen:
        return ('Hear $_title said right', 'Native pronunciation of $_title, made for you when you open it. Listen first, then say it back.');
      case StoreWordMode.practice:
        return ('Practise $_title daily', 'Repeat it in the player and keep your streak, one word at a time. Yours to keep forever.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        Positioned.fill(
          child: NwsbVideo(
            asset: widget.film,
            priority: ClipPriority.decoration,
            autoplay: true,
            loop: true,
            obeyMotion: true,
            slot: 'store_word_page.film',
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xD907090F), Color(0xEB07090F), Color(0xF707090F)],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                key: const ValueKey('store-word-list'),
                padding: EdgeInsets.fromLTRB(20, 10, 20, 112 + bottomInset),
                children: [
                  _topRow(context),
                  const SizedBox(height: 22),
                  _OriginLabel(_origin),
                  const SizedBox(height: 6),
                  _titleRow(),
                  const SizedBox(height: 18),
                  _modeRow(),
                  const SizedBox(height: 8),
                  _hero(),
                  const SizedBox(height: 18),
                  _detailCard(),
                  if (_f.related.isNotEmpty) ..._more(),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12 + bottomInset,
          child: Center(child: _navBar(context)),
        ),
      ]),
    );
  }

  // ── phone 1 ──────────────────────────────────────────────────────────────

  Widget _topRow(BuildContext context) {
    final n = earnFirstName();
    return Row(children: [
      StoreWordCircle(
        key: const ValueKey('word-back'),
        icon: Icons.arrow_back_rounded,
        label: 'Back',
        onTap: () => Navigator.of(context).maybePop(),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text.rich(
          TextSpan(text: n == null ? 'Hi there' : 'Hi, $n', children: const [
            TextSpan(text: ' 👋', style: TextStyle(fontFamilyFallback: ['NotoColorEmoji', 'Apple Color Emoji', 'Segoe UI Emoji'])),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      const SizedBox(width: 10),
      const _CoinBadge(),
    ]);
  }

  Widget _titleRow() {
    final big = '$_title\n$_collection';
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              big,
              key: const ValueKey('word-title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w800,
                height: 1.02,
                letterSpacing: -1.6,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 14),
      _WishPill(item: widget.item),
    ]);
  }

  Widget _modeRow() {
    const modes = [
      (StoreWordMode.meaning, 'Meaning', Icons.menu_book_rounded),
      (StoreWordMode.listen, 'Listen', Icons.graphic_eq_rounded),
      (StoreWordMode.practice, 'Practice', Icons.self_improvement_rounded),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(children: [
        for (final m in modes) ...[
          _ModeChip(
            key: ValueKey('word-mode-${m.$2.toLowerCase()}'),
            label: m.$2,
            icon: m.$3,
            selected: _mode == m.$1,
            onTap: () {
              if (_mode == m.$1) return;
              AppHaptics.selection();
              setState(() => _mode = m.$1);
            },
          ),
          const SizedBox(width: 6),
        ],
      ]),
    );
  }

  Widget _hero() {
    final (head, body) = _panel;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      var h = (w * 1.14).clamp(360.0, 560.0);
      // Tablet: the picture stays at about half the screen's height, so the
      // meaning under it is on screen too. A phone keeps its height.
      if (isTablet(context)) {
        h = math.min(h, math.max(320.0, MediaQuery.sizeOf(context).height * .52));
      }
      return SizedBox(
        height: h,
        child: Stack(fit: StackFit.expand, children: [
          // The cut-out: the photo fades into the page on every side, with
          // no card edge, like the reference's misty forest.
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .16, .62, 1],
              colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            ).createShader(r),
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0, .14, .86, 1],
                colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
              ).createShader(r),
              child: Stack(fit: StackFit.expand, children: [
                // A word without a picture of its own shows the default Store
                // art whole in the upper part, clear of the text below it.
                if (!storeWordHasOwnPicture(widget.title))
                  Padding(
                    padding: EdgeInsets.only(top: h * .06, bottom: h * .4),
                    child: StoreNetImage(url: widget.picture, fit: BoxFit.contain),
                  )
                else
                  StoreNetImage(url: widget.picture),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, .45, 1],
                      colors: [Color(0x00000000), Color(0x26000000), Color(0xCC000000)],
                    ),
                  ),
                ),
              ]),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 8,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(head,
                  key: const ValueKey('word-hero-title'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2,
                      shadows: [Shadow(color: Color(0x99000000), blurRadius: 12)])),
              const SizedBox(height: 6),
              Text(body,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12.5, height: 1.4,
                      shadows: [Shadow(color: Color(0x99000000), blurRadius: 10)])),
              const SizedBox(height: 12),
              Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 6, children: [
                if (_origin.isNotEmpty) _Stat(icon: Icons.public_rounded, label: _origin),
                if (_letters > 0) _Stat(icon: Icons.text_fields_rounded, label: '$_letters letters'),
                const _Stat(icon: Icons.all_inclusive_rounded, label: 'Forever'),
              ]),
              const SizedBox(height: 14),
              _OutlinePill(
                key: widget.cartKey,
                label: widget.open ? 'Yours, open in Library' : 'Add to Cart',
                onTap: widget.open ? widget.onOpenOwned : widget.onAddToCart,
              ),
            ]),
          ),
        ]),
      );
    });
  }

  // ── phone 3: the detail card with the nested buy card ────────────────────

  Widget _detailCard() {
    return GlassWrap(
      margin: EdgeInsets.zero,
      radius: 26,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: _OriginLabel(_origin.isEmpty ? _collection : _origin)),
          StoreWordStar(item: widget.item, size: 36, onDark: false),
        ]),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(
            widget.meaning ? 'Discover what $_title really means' : 'Discover the sound of $_title',
            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.3),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _SmallPill(icon: Icons.sell_outlined, label: _priceLabel),
          const _SmallPill(icon: Icons.all_inclusive_rounded, label: 'Owned forever'),
          _SmallPill(icon: Icons.collections_bookmark_outlined, label: _collection),
        ]),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(widget.about, style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 13.5, height: 1.5)),
        ),
        const SizedBox(height: 10),
        for (final h in widget.highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.check_rounded, size: 16, color: NwsbColors.goldLight),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(h, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xCCFFFFFF)))),
            ]),
          ),
        const SizedBox(height: 6),
        _buyCard(),
      ]),
    );
  }

  Widget _buyCard() {
    return Container(
      key: const ValueKey('word-buy-card'),
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x8C000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(width: 56, height: 56, child: StoreNetImage(url: widget.picture)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text('NowssB Store · $_collection',
                  maxLines: 2,
                  style: const TextStyle(color: _kMuted, fontSize: 12, height: 1.3)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: _priceLabel,
                  style: const TextStyle(color: NwsbColors.goldLight, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: widget.open ? '  to keep' : ' / forever',
                  style: const TextStyle(color: _kMuted, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ),
          _WhitePill(
            key: const ValueKey('word-buy'),
            label: widget.open ? 'Open' : 'Buy on Google Play',
            onTap: widget.open ? widget.onOpenOwned : widget.onBuy,
          ),
        ]),
      ]),
    );
  }

  // ── phone 2: "Popular" ───────────────────────────────────────────────────

  List<Widget> _more() {
    final links = _f.related.take(6).toList();
    final all = _f.related;
    return [
      const SizedBox(height: 30),
      Text('More in\n$_collection',
          style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, height: 1.04, letterSpacing: -1.2)),
      const SizedBox(height: 16),
      Container(
        key: const ValueKey('word-more-card'),
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: _kDarkCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _OriginLabel('${all.length + 1} ${widget.meaning ? 'meanings' : 'words'}'),
                const SizedBox(height: 6),
                Text(_f.categorySub.isNotEmpty ? _f.categorySub : 'The $_collection collection',
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.25)),
                const SizedBox(height: 12),
                _Faces(links: all),
              ]),
            ),
            const SizedBox(width: 12),
            StoreWordCircle(
              key: const ValueKey('word-more-next'),
              icon: Icons.arrow_forward_rounded,
              label: 'Open ${links.first.title}',
              light: true,
              size: 46,
              onTap: () => widget.onOpenLink(links.first),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _SmallPill(icon: Icons.sell_outlined, label: 'From ${inr(widget.price <= 0 ? 49 : widget.price, sku: widget.itemId)}'),
            const _SmallPill(icon: Icons.all_inclusive_rounded, label: 'Owned forever'),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      for (final l in links) _PhotoCard(link: l, onOpen: () => widget.onOpenLink(l)),
    ];
  }

  Widget _navBar(BuildContext context) {
    Widget item(String key, IconData icon, String label, VoidCallback? onTap, {bool active = false}) {
      return Semantics(
        button: true,
        selected: active,
        label: label,
        child: GestureDetector(
          key: ValueKey('word-nav-$key'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap == null
              ? null
              : () {
                  AppHaptics.selection();
                  onTap();
                },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 22, color: active ? NwsbColors.ink : const Color(0xCCFFFFFF)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xF20B0B10),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0x2EFFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        item('store', Icons.storefront_rounded, 'Store', () => Navigator.of(context).maybePop()),
        const SizedBox(width: 6),
        item('word', Icons.graphic_eq_rounded, _title, null, active: true),
        const SizedBox(width: 6),
        item('wishlist', Icons.favorite_border_rounded, 'Wishlist', () => showBagSheet(context, BagKind.wishlist)),
        const SizedBox(width: 6),
        item('cart', Icons.shopping_bag_outlined, 'Cart', () => showBagSheet(context, BagKind.cart)),
        const SizedBox(width: 6),
        item('stores', Icons.grid_view_rounded, 'All stores', widget.onStorePicker),
      ]),
    );
  }
}

/// The small caps line over a title (the reference's flag and country).
class _OriginLabel extends StatelessWidget {
  const _OriginLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox(height: 14);
    return Row(children: [
      Container(
        width: 15,
        height: 10,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(colors: [Color(0xFFE8D5A3), Color(0xFFC8A96E)]),
        ),
      ),
      const SizedBox(width: 7),
      Flexible(
        child: Text(text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8)),
      ),
    ]);
  }
}

/// The coin balance in a white circle (the reference's weather badge).
class _CoinBadge extends StatelessWidget {
  const _CoinBadge();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EconomyMirror.instance,
      builder: (context, _) {
        final c = EconomyMirror.instance.coins;
        return Semantics(
          label: '$c NowssB coins',
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xF2FFFFFF), borderRadius: BorderRadius.circular(19)),
              child: const NwsbCoinDisc(size: 26),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text('Coins', style: TextStyle(color: _kMuted, fontSize: 11, fontWeight: FontWeight.w500)),
              Text('$c', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, height: 1.15)),
            ]),
          ]),
        );
      },
    );
  }
}

/// A round glass button (back, arrow): the reference's circles.
class StoreWordCircle extends StatelessWidget {
  const StoreWordCircle({super.key, required this.icon, required this.label, required this.onTap, this.light = false, this.size = 40});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? Colors.white : _kGlass,
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: light ? Colors.white : _kLine),
          ),
          child: Icon(icon, size: size * 0.46, color: light ? NwsbColors.ink : Colors.white),
        ),
      ),
    );
  }
}

/// The tall pill beside the title (the reference's search pill): Wishlist.
class _WishPill extends StatelessWidget {
  const _WishPill({required this.item});
  final BagItem Function() item;

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
          label: on ? 'Remove ${it.title} from wishlist' : 'Wishlist',
          child: GestureDetector(
            key: const ValueKey('word-wish'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptics.selection();
              if (on) {
                CartBag.instance.removeWishlist(it.id);
              } else {
                CartBag.instance.addWishlist(it);
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                  content: Text('Saved ${it.title} to wishlist'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: Container(
              width: 52,
              height: 70,
              decoration: BoxDecoration(
                color: on ? Colors.white : _kGlass,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: on ? Colors.white : _kLine),
              ),
              child: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 22, color: on ? NwsbColors.ink : Colors.white),
            ),
          ),
        );
      },
    );
  }
}

/// One of the three chips: the selected one is the white pill (the
/// reference's black "Hiking" pill), the others plain text with an icon.
class _ModeChip extends StatelessWidget {
  const _ModeChip({super.key, required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? NwsbColors.ink : const Color(0xD9FFFFFF);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: fg, fontSize: 13.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

/// A tiny stat item over the photo ("7 days", "10 km", "8/10").
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Colors.white),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
    ]);
  }
}

/// The outlined pill over the photo (the reference's "Start Trip").
class _OutlinePill extends StatelessWidget {
  const _OutlinePill({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white, width: 1.2),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

/// A solid white pill button (the nested card's action).
class _WhitePill extends StatelessWidget {
  const _WhitePill({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
          child: Text(label, style: const TextStyle(color: NwsbColors.ink, fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

/// A small glass pill (the reference's date pills).
class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kGlass,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: const Color(0xCCFFFFFF)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Three overlapping word photos and "+N" (the reference's avatar stack).
class _Faces extends StatelessWidget {
  const _Faces({required this.links});
  final List<StoreWordLink> links;

  @override
  Widget build(BuildContext context) {
    final show = links.take(3).toList();
    final rest = links.length - show.length;
    return Row(children: [
      SizedBox(
        width: 30.0 + 20 * (show.length - 1),
        height: 30,
        child: Stack(children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: 20.0 * i,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _kDarkCard, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: StoreNetImage(url: storeWordPicture(show[i].word, kNowssbWordFallback)),
                ),
              ),
            ),
        ]),
      ),
      if (rest > 0) ...[
        const SizedBox(width: 8),
        Text('+$rest', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    ]);
  }
}

BagItem storeWordLinkItem(StoreWordLink l) {
  final m = l.meaning;
  final pic = storeWordPicture(l.word, kNowssbWordFallback);
  if (m != null) return meaningBagItem(word: m.word, root: m.root, img: pic, price: m.price);
  return wordBagItem(name: l.title, root: l.root, img: pic, price: StorePrices.instance.priceFor(l.id));
}

/// A tall photo card in "More in …" (the reference's forest card): the
/// photo with the word over it, a star in the corner and chips under it.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.link, required this.onOpen});
  final StoreWordLink link;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = link;
    final origin = plainOrigin(l.root.split('·').first.trim());
    final letters = l.word.replaceAll(RegExp(r'[^A-Za-z]'), '').length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Semantics(
        button: true,
        label: 'Open ${l.title}',
        child: GestureDetector(
          key: ValueKey('word-more-${l.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.selection();
            onOpen();
          },
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(
                height: 236,
                child: Stack(fit: StackFit.expand, children: [
                  StoreNetImage(url: storeWordPicture(l.word, kNowssbWordFallback)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .45, 1],
                        colors: [Color(0x33000000), Color(0x00000000), Color(0xD9000000)],
                      ),
                    ),
                  ),
                  Positioned(right: 12, top: 12, child: StoreWordStar(item: () => storeWordLinkItem(l), size: 38)),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      _OriginLabel(origin),
                      const SizedBox(height: 4),
                      Text(l.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ListenableBuilder(
                listenable: StorePrices.instance,
                builder: (_, __) => _SmallPill(
                  icon: Icons.sell_outlined,
                  label: inr(l.meaning != null ? StorePrices.instance.priceFor(l.id, shown: l.meaning!.price) : StorePrices.instance.priceFor(l.id), sku: l.id),
                ),
              ),
              if (letters > 0) _SmallPill(icon: Icons.text_fields_rounded, label: '$letters letters'),
              const _SmallPill(icon: Icons.all_inclusive_rounded, label: 'Owned forever'),
            ]),
          ]),
        ),
      ),
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
