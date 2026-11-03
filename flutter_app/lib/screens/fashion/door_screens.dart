/// Live wiring for the designer's door screens (df678da): each picker reads
/// and writes the real [Settings].
library;

import 'package:flutter/material.dart';

import '../../data/content.dart';
import '../../data/day_part.dart';
import '../../data/fashion_bg_dim.dart';
import '../../data/home_widget_sync.dart';
import '../../data/practice_progress.dart';
import '../../data/settings.dart';
import '../notifications_settings.dart';
import '../player_settings.dart';
import '../practice.dart';
import '../profile.dart';
import '../sound_library.dart';
import '../store.dart';
import '../store/meaning_store.dart';
import '../fashion_plus.dart';
import '../quick_access.dart';
import '../concept/doors/door_access.dart';
import '../concept/doors/door_background.dart';
import '../concept/doors/door_checkout.dart';
import '../../data/cart_bag.dart';
import '../../data/entitlements.dart';
import '../../data/store_prices.dart';
import '../store/cart_pages.dart';
import '../../shell/nwsb_links.dart';
import '../concept/doors/door_start_art.dart';

/// Background door → film picker. Writes Settings.fashionVideoIndex and the
/// Fashion Plus motion flag.
class DoorBackgroundScreen extends StatelessWidget {
  const DoorBackgroundScreen({super.key});

  static String _poster(String mp4) => mp4.replaceFirst(RegExp(r'\.mp4$'), '-poster.webp');

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => DoorBackgroundPicker(
        videos: [
          for (var i = 0; i < Settings.fashionVideos.length; i++)
            DoorVideo(
                id: '$i',
                name: Settings.fashionVideoNames[i],
                poster: _poster(Settings.fashionVideos[i]),
                asset: Settings.fashionVideos[i]),
        ],
        selectedId: '${s.fashionVideoIndex}',
        motionOn: s.fashionPlus,
        onPickVideo: (id) => s.setFashionVideo(int.parse(id)),
        onToggleMotion: s.setFashionPlus,
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// Start art door → still picker. "Black" (-1) clears the saved still.
class DoorStartArtScreen extends StatelessWidget {
  const DoorStartArtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => DoorStartArtPicker(
        stills: [
          const DoorStill(id: '-1', name: 'NowssB Black'),
          for (var i = 0; i < Settings.fashionImages.length; i++)
            DoorStill(id: '$i', name: Settings.fashionImageName(i), asset: doorStillArt(Settings.fashionImageName(i), Settings.fashionImages[i])),
        ],
        selectedId: '${s.fashionImageIndex}',
        onPickImage: (id) {
          final i = int.parse(id);
          s.setFashionImage(i < 0 ? null : i);
        },
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// Start art tiles show the text-free doors art (the real stills carry
/// printed type). Display only: [Settings.fashionImages] is unchanged.
String doorStillArt(String name, String asset) {
  if (name == 'Zen') return 'assets/doors/fashion_plus_tv.webp';
  if (name == 'Store') return 'assets/doors/store.webp';
  if (name.startsWith('Word')) return 'assets/doors/wordscience.webp';
  if (name == 'Meanings Clean') return 'assets/doors/meanings.webp';
  if (name == 'Meanings Brand') return 'assets/doors/hour-shakti.webp';
  if (name == 'Meanings Swirl') return 'assets/doors/hour-vata.webp';
  if (name == 'Meanings Device') return 'assets/doors/hour-chandra.webp';
  if (name == 'eBooks Headphones') return 'assets/doors/ebooks.webp';
  if (name == 'eBooks Pair') return 'assets/doors/hour-kapha.webp';
  return asset;
}

/// Per-feature rolodex art (local, text-free posters) and socket icons.
const _accessArt = <String, String>{
  'connect': 'assets/doors/connect.webp',
  'practice': 'assets/doors/practice.webp',
  'library': 'assets/doors/library.webp',
  'store': 'assets/doors/store.webp',
  'profile': 'assets/doors/profile.webp',
  'wordscience': 'assets/doors/wordscience.webp',
  'meaningstore': 'assets/doors/meaningstore.webp',
  'search': 'assets/doors/search.webp',
  'cart': 'assets/doors/cart.webp',
  'wishlist': 'assets/doors/wishlist.webp',
  'chat': 'assets/doors/chat.webp',
  'ai': 'assets/doors/ai.webp',
  'streak': 'assets/doors/streak.webp',
  'journal': 'assets/doors/journal.webp',
  'settings': 'assets/doors/settings.webp',
  'everything': 'assets/doors/everything.webp',
};

/// Every Access feature's own art (one file each), for the test.
@visibleForTesting
Map<String, String> get doorAccessArt => _accessArt;
const _accessIcon = <String, IconData>{
  'connect': Icons.people_outline,
  'practice': Icons.mic_none_rounded,
  'library': Icons.library_music_outlined,
  'store': Icons.storefront_outlined,
  'profile': Icons.person_outline,
  'progress': Icons.insights_outlined,
  'wordscience': Icons.science_outlined,
  'meaningstore': Icons.menu_book_outlined,
  'search': Icons.search,
  'cart': Icons.shopping_cart_outlined,
  'wishlist': Icons.favorite_border,
  'chat': Icons.chat_bubble_outline,
  'ai': Icons.auto_awesome,
  'streak': Icons.local_fire_department_outlined,
  'journal': Icons.edit_note,
  'settings': Icons.settings_outlined,
  'everything': Icons.apps,
};

/// Access door → socket bar + rolodex. Features are QuickAccessScreen's real
/// list; writes Settings nav slots (nwsb_nav_slots).
class DoorAccessScreen extends StatelessWidget {
  const DoorAccessScreen({super.key});

  static List<DoorFeature> get features => [
        for (final f in quickAccessFeatures)
          DoorFeature(
              id: f['id']!,
              label: f['label']!,
              icon: _accessIcon[f['id']] ?? Icons.apps,
              art: _accessArt[f['id']],
              image: f['img']),
      ];

  /// Puts [id] in socket [i]; if it already sits in another socket the two swap.
  static List<String> place(List<String> slots, int i, String id) {
    final next = [...slots];
    if (i < 0 || i >= next.length) return next;
    final was = next.indexOf(id);
    if (was >= 0) next[was] = next[i];
    next[i] = id;
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => DoorAccessPicker(
        features: features,
        slots: s.navSlots,
        onSetSlot: (i, id) => s.setNavConfig(slots: place(s.navSlots, i, id)),
        onBack: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// Checkout door: the cart (or a Buy-now item) as the card stack, total from
/// main's chip-inr money logic. It writes nothing itself: "Place order"
/// opens CheckoutPage for the payable lines (Google Play flow); an all-in-plan
/// bag's "Add to library" takes the open lines out of the cart (like Done).
class DoorCheckoutScreen extends StatefulWidget {
  const DoorCheckoutScreen({super.key, this.items, this.debugPhase, this.debugFront});

  /// Just these (Buy now); null = the whole cart.
  final List<BagItem>? items;
  final double? debugPhase;
  final int? debugFront;

  @override
  State<DoorCheckoutScreen> createState() => _DoorCheckoutScreenState();
}

class _DoorCheckoutScreenState extends State<DoorCheckoutScreen> {
  late List<BagItem>? _only = widget.items == null ? null : [...widget.items!];
  List<BagItem> get _items => _only ?? CartBag.instance.cart;

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([CartBag.instance, Entitlements.instance, StorePrices.instance]),
        builder: (context, _) {
          final items = _items;
          final toBuy = [for (final it in items) if (!checkoutLineOpen(it)) it];
          return DoorCheckout(
            items: [
              for (final it in items)
                DoorLine(
                  id: it.id,
                  title: it.title,
                  kind: it.kind,
                  priceLabel: checkoutPriceLabel(it),
                  image: it.image,
                  meaning: it.subtitle.isEmpty ? null : it.subtitle,
                  status: checkoutLineStatus(it),
                  included: checkoutLineOpen(it),
                ),
            ],
            totalLabel: checkoutTotalLabel(items),
            cartCount: CartBag.instance.cart.length,
            debugPhase: widget.debugPhase,
            debugFront: widget.debugFront,
            onBack: () => Navigator.of(context).maybePop(),
            onOpenCart: () => NwsbLinks.cart(context),
            onOpenWishlist: () => _push(const WishlistPage()),
            onRemove: (id) {
              if (_only != null) {
                setState(() => _only = [for (final b in _only!) if (b.id != id) b]);
              } else {
                CartBag.instance.removeCart(id);
              }
            },
            onPlaceOrder: toBuy.isEmpty ? null : () => _push(CheckoutPage(items: toBuy)),
            onAddToLibrary: () {
              for (final it in items) {
                if (checkoutLineOpen(it)) CartBag.instance.removeCart(it.id);
              }
              Navigator.of(context).maybePop();
            },
          );
        },
      );
}
