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
import '../healing_path.dart';
import '../notifications_settings.dart';
import '../player_settings.dart';
import '../practice.dart';
import '../profile.dart';
import '../progress/progress_screen.dart';
import '../sound_library.dart';
import '../store.dart';
import '../store/meaning_store.dart';
import '../fashion_plus.dart';
import '../quick_access.dart';
import '../concept/doors/door_access.dart';
import '../concept/doors/door_background.dart';
import '../concept/doors/door_fashion_plus.dart';
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

/// Start art tiles: the Meanings and eBooks stills show the text-free doors
/// art (the real stills carry printed type); the others keep their own.
String doorStillArt(String name, String asset) {
  if (name.startsWith('Meanings')) return 'assets/doors/meanings.webp';
  if (name.startsWith('eBooks')) return 'assets/doors/ebooks.webp';
  return asset;
}

/// Per-feature rolodex art (local, text-free posters) and socket icons.
const _accessArt = <String, String>{
  'connect': 'assets/doors/connect.webp',
  'practice': 'assets/doors/practice.webp',
  'library': 'assets/doors/library.webp',
  'store': 'assets/doors/store.webp',
  'profile': 'assets/doors/profile.webp',
  'progress': 'assets/doors/progress.webp',
  'wordscience': 'assets/doors/wordscience.webp',
  'meaningstore': 'assets/doors/meaningstore.webp',
  'search': 'assets/doors/search.webp',
  'cart': 'assets/doors/cart.webp',
  'wishlist': 'assets/doors/wishlist.webp',
  'routines': 'assets/doors/routines.webp',
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
  'routines': Icons.event_repeat,
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

/// Themes door → the Fashion Plus page (WidgetsPage's real content): streak
/// + word of the day (HomeWidgetSync), Add to home screen, hero style,
/// the background-film dim dial, Jump to and Make it yours.
class DoorFashionPlusScreen extends StatefulWidget {
  const DoorFashionPlusScreen({super.key, this.debugPhase});
  final double? debugPhase;

  @visibleForTesting
  static List<DoorJump> get jumps => _DoorFashionPlusScreenState.jumps;

  @override
  State<DoorFashionPlusScreen> createState() => _DoorFashionPlusScreenState();
}

class _DoorFashionPlusScreenState extends State<DoorFashionPlusScreen> {
  bool _busy = false;
  late final Listenable _all = Listenable.merge(
      [Settings.instance, PracticeProgress.instance, ContentStore.instance, FashionBgDim.instance]);

  static String _poster(String mp4) => mp4.replaceFirst(RegExp(r'\.mp4$'), '-poster.webp');

  static const jumps = [
    DoorJump('practice', 'Practice', "Today's word ritual", 'assets/video/practice-halo-poster.webp'),
    DoorJump('library', 'Sound Library', 'Every word you own', 'assets/video/player-box-rings-poster.webp'),
    DoorJump('progress', 'Progress', 'How far you have come', 'assets/video/my-progress-scene-1-poster.webp'),
    DoorJump('store', 'Store', 'Words and frequencies', 'assets/doors/fashion_plus_store.webp'),
    DoorJump('meaning', 'Meaning', 'What it truly means', 'assets/video/nm-calm-stream-poster.webp'),
    DoorJump('connect', 'Connect', 'The social space', 'assets/video/nm-calm-clouds-poster.webp'),
    DoorJump('notifications', 'Notifications', 'What reaches you', 'assets/video/earth-night-poster.webp'),
    DoorJump('profile', 'Profile', 'Your account', 'assets/video/normal-glass-background-poster.webp'),
  ];

  static List<DoorJump> make(Settings s) => [
        DoorJump('fashionPlus', 'Fashion Plus', 'The motion mode', 'assets/video/fashion-plus-bg-6-poster.webp',
            toggle: s.fashionPlus),
        DoorJump('fashionHome', 'Fashion home', 'Dark film home', 'assets/video/hero-bg-poster.webp',
            toggle: s.fashionHome),
        const DoorJump('player', 'Player Settings', 'AURA playback', 'assets/video/player-aura-bg-poster.webp'),
        const DoorJump('homeButtons', 'Home buttons', 'Quick Access bar', 'assets/video/player-bg-loop-poster.webp'),
        DoorJump('healing', 'Personalised Healing', s.showHealing ? 'On your home' : 'Add it to home',
            'assets/video/healing-path-bg-poster.webp',
            toggle: s.showHealing),
      ];

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  void _jump(String id) {
    switch (id) {
      case 'practice':
        _push(const PracticeScreen());
      case 'library':
        _push(const SoundLibraryScreen());
      case 'progress':
        _push(PracticeProgressScreen(words: ContentStore.instance.library));
      case 'store':
        _push(const StoreScreen());
      case 'meaning':
        _push(const MeaningStoreScreen());
      case 'connect':
        NwsbLinks.connect(context);
      case 'notifications':
        _push(const NotificationsSettingsPage());
      case 'profile':
        _push(const ProfileScreen());
      case 'player':
        _push(const PlayerSettingsScreen());
      case 'homeButtons':
        _push(const DoorAccessScreen());
      case 'fashionPlus':
        _push(const FashionPlusScreen());
      case 'fashionHome':
        Settings.instance.setFashionHome(!Settings.instance.fashionHome);
      case 'healing':
        _push(const HealingPathScreen());
    }
  }

  void _toggle(String id, bool on) {
    final s = Settings.instance;
    switch (id) {
      case 'fashionPlus':
        s.setFashionPlus(on);
      case 'fashionHome':
        s.setFashionHome(on);
      case 'healing':
        s.setShowHealing(on);
    }
  }

  Future<void> _addToHome() async {
    final m = ScaffoldMessenger.maybeOf(context);
    if (!HomeWidgetSync.supported) {
      m?.showSnackBar(const SnackBar(
          content: Text('The home-screen widget is on Android. Long-press your home screen → Widgets → NowssB.')));
      return;
    }
    setState(() => _busy = true);
    await HomeWidgetSync.instance.push();
    final ok = await HomeWidgetSync.instance.requestPin();
    if (!mounted) return;
    setState(() => _busy = false);
    m?.showSnackBar(SnackBar(
        content: Text(ok
            ? 'Choose where it goes on your home screen.'
            : 'Long-press your home screen → Widgets → NowssB to add it.')));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _all,
        builder: (context, _) {
          final s = Settings.instance;
          final now = DayClock.now();
          final w = HomeWidgetSync.wordFor(now, ContentStore.instance.library);
          return DoorFashionPlusPage(
            backdrop: _poster(s.fashionVideoAsset),
            streak: PracticeProgress.instance.streak,
            wordOfDay: w?.word ?? 'NowssB',
            wordLine: w?.meaning ?? 'Your word of the day appears here',
            heroStyle: s.heroStyle,
            dim: 1 - FashionBgDim.instance.value,
            jumps: jumps,
            make: make(s),
            addingToHome: _busy,
            debugPhase: widget.debugPhase,
            onBack: () => Navigator.of(context).maybePop(),
            onPractise: () => _push(const PracticeScreen()),
            onAddToHome: _addToHome,
            onPickStyle: s.setHeroStyle,
            onDimChanged: (film) => FashionBgDim.instance.set(1 - film, persist: false),
            onDimChangeEnd: (film) => FashionBgDim.instance.set(1 - film),
            onJump: _jump,
            onMake: _jump,
            onToggle: _toggle,
          );
        },
      );
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
