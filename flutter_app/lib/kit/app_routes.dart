/// One canonical route per page (spec §23), following the section 22
/// inventory's canonical screens. Each route builds today's screen
/// ([KitRoute.legacy]); a page bot registers its rebuilt screen in
/// `rebuilt_pages.dart`, and [AppRoutes.open] shows it only while
/// `newui_<flag>` is on (admins first, see [NewUi]).
///
/// Additive: no existing entry point is rerouted yet.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../features/circle/circle_screen.dart';
import '../features/coins/coinback_page.dart';
import '../features/coins/free_coins_page.dart';
import '../features/coins/multiplier_page.dart';
import '../features/earn/earn_hub_screen.dart';
import '../features/earn/earnings_screen.dart';
import '../features/economy/coupon_screen.dart';
import '../features/economy/partner_screen.dart';
import '../features/economy/reference_screen.dart';
import '../features/gifts/gifts_screen.dart';
import '../features/vault/vault_screen.dart';
import '../screens/store.dart';
import '../screens/store/cart_pages.dart';
import '../screens/subscription.dart';
import '../shell/nav_shell.dart';
import 'feature_flags.dart';
import 'rebuilt_pages.dart';

/// Arguments every route accepts. `tab` is the sub-page key; `id` a detail id.
class RouteArgs {
  const RouteArgs({this.tab, this.id, this.extra = const {}});
  final String? tab;
  final String? id;
  final Map<String, String> extra;
}

typedef KitPageBuilder = Widget Function(BuildContext context, RouteArgs args);

enum AppPage {
  coupons, couponsScratch, rewards, coins, coinsHistory, coinsFree, coinsStore, coinsBoost,
  gifts, partner, earn, earnings, reference, store, storeWords, storeMeanings, storeSignature,
  storeEbooks, subscription, cart,
}

class KitRoute {
  const KitRoute({required this.page, required this.path, required this.screenId, required this.flag, required this.legacy, this.tabIndex});
  final AppPage page;

  /// `/coupons`, `/store/words` … also the deep-link path (`nowssb://coupons`).
  final String path;

  /// Shown by the debug screen-id label / Inspector.
  final String screenId;

  /// `newui_<flag>` gates the rebuilt screen. Shared by a page and its sub-pages.
  final String flag;
  final KitPageBuilder legacy;

  /// Bottom-nav tab to switch to instead of pushing (Store = 3).
  final int? tabIndex;
}

abstract final class AppRoutes {
  static final Map<AppPage, KitRoute> routes = {
    for (final r in <KitRoute>[
      KitRoute(page: AppPage.coupons, path: '/coupons', screenId: 'coupons', flag: 'coupons',
          legacy: (_, a) => CouponScreen(initialTab: a.tab)),
      KitRoute(page: AppPage.couponsScratch, path: '/coupons/scratch', screenId: 'coupons.scratch', flag: 'coupons',
          legacy: (_, a) => const CouponScreen(initialTab: 'scratch')),
      KitRoute(page: AppPage.rewards, path: '/rewards', screenId: 'rewards', flag: 'rewards',
          legacy: (_, a) => VaultScreen(initialTab: a.tab)),
      // No canonical Coins wallet yet: EarnHubScreen carries the coin ledger today.
      KitRoute(page: AppPage.coins, path: '/coins', screenId: 'coins', flag: 'coins',
          legacy: (_, a) => const EarnHubScreen()),
      KitRoute(page: AppPage.coinsHistory, path: '/coins/history', screenId: 'coins.history', flag: 'coins',
          legacy: (_, a) => const EarnHubScreen()),
      KitRoute(page: AppPage.coinsFree, path: '/coins/free', screenId: 'coins.free', flag: 'coins',
          legacy: (_, a) => const FreeCoinsPage()),
      KitRoute(page: AppPage.coinsStore, path: '/coins/store', screenId: 'coins.store', flag: 'coins',
          legacy: (_, a) => const CoinbackPage()),
      KitRoute(page: AppPage.coinsBoost, path: '/coins/boost', screenId: 'coins.boost', flag: 'coins',
          legacy: (_, a) => const MultiplierPage()),
      KitRoute(page: AppPage.gifts, path: '/gifts', screenId: 'gifts', flag: 'gifts',
          legacy: (_, a) => GiftsScreen(initialTab: a.tab, startOnRedeem: a.tab == 'redeem')),
      KitRoute(page: AppPage.partner, path: '/partner', screenId: 'partner', flag: 'partner',
          legacy: (_, a) => PartnerScreen(initialTab: a.tab)),
      KitRoute(page: AppPage.earn, path: '/earn', screenId: 'earn', flag: 'earn',
          legacy: (_, a) => CircleScreen(initialTab: a.tab)),
      KitRoute(page: AppPage.earnings, path: '/earnings', screenId: 'earnings', flag: 'earnings',
          legacy: (_, a) => const EarningsScreen()),
      KitRoute(page: AppPage.reference, path: '/reference', screenId: 'reference', flag: 'reference',
          legacy: (_, a) => ReferenceScreen(initialTab: a.tab)),
      KitRoute(page: AppPage.store, path: '/store', screenId: 'store', flag: 'store', tabIndex: 3,
          legacy: (_, a) => const StoreScreen()),
      KitRoute(page: AppPage.storeWords, path: '/store/words', screenId: 'store.words', flag: 'store',
          legacy: (_, a) => const WordAtelierScreen()),
      KitRoute(page: AppPage.storeMeanings, path: '/store/meanings', screenId: 'store.meanings', flag: 'store',
          legacy: (_, a) => const MeaningStoreScreen()),
      KitRoute(page: AppPage.storeSignature, path: '/store/signature', screenId: 'store.signature', flag: 'signature',
          legacy: (_, a) => const SignatureStoreScreen()),
      KitRoute(page: AppPage.storeEbooks, path: '/store/ebooks', screenId: 'store.ebooks', flag: 'ebooks',
          legacy: (_, a) => const EbooksStoreScreen()),
      KitRoute(page: AppPage.subscription, path: '/subscription', screenId: 'subscription', flag: 'subscription',
          legacy: (_, a) => const SubscriptionScreen()),
      KitRoute(page: AppPage.cart, path: '/cart', screenId: 'cart', flag: 'store',
          legacy: (_, a) => const CartPage()),
    ])
      r.page: r,
  };

  static final Map<AppPage, KitPageBuilder> _rebuilt = {};

  /// Page bots: call from `rebuilt_pages.dart` only.
  static void registerRebuilt(AppPage page, KitPageBuilder builder) => _rebuilt[page] = builder;
  static bool hasRebuilt(AppPage page) {
    registerRebuiltPages();
    return _rebuilt.containsKey(page);
  }

  @visibleForTesting
  static void clearRebuiltForTest() {
    _rebuilt.clear();
    _lastPage = null;
  }

  /// Records `source` for every open (analytics hook; Crashlytics/Analytics
  /// aren't in pubspec yet, so this is a debug log + listener for now).
  static void Function(AppPage page, String source)? onOpen;

  /// Builds the screen for [page], respecting the flag.
  static Widget build(BuildContext context, AppPage page, [RouteArgs args = const RouteArgs()]) {
    final r = routes[page]!;
    registerRebuiltPages();
    final next = _rebuilt[page];
    if (next == null) return r.legacy(context, args);
    return NewUiGate(page: r.flag, legacy: (c) => r.legacy(c, args), rebuilt: (c) => next(c, args));
  }

  static DateTime _lastOpen = DateTime.fromMillisecondsSinceEpoch(0);
  static AppPage? _lastPage;

  /// The one way to open a program page. Double taps within 600 ms on the
  /// same page are dropped. Tab pages (Store) switch the bottom tab when a
  /// [NavScope] is present and the rebuilt screen isn't on.
  static Future<void> open(BuildContext context, AppPage page,
      {required String source, String? tab, String? id, Map<String, String> extra = const {}}) async {
    final now = DateTime.now();
    if (_lastPage == page && now.difference(_lastOpen) < const Duration(milliseconds: 600)) return;
    _lastPage = page;
    _lastOpen = now;
    onOpen?.call(page, source);
    if (kDebugMode) debugPrint('AppRoutes.open ${page.name} from $source');
    final r = routes[page]!;
    final rebuiltOn = hasRebuilt(page) && NewUi.isOn(r.flag);
    if (r.tabIndex != null && !rebuiltOn && context.getInheritedWidgetOfExactType<NavScope>() != null) {
      NavScope.goTo(context, r.tabIndex!);
      return;
    }
    final args = RouteArgs(tab: tab, id: id, extra: extra);
    await Navigator.of(context).push(MaterialPageRoute<void>(
      settings: RouteSettings(name: r.path, arguments: args),
      builder: (c) => build(c, page, args),
    ));
  }

  /// Resolves `/coupons/scratch`, `nowssb://coupons?tab=mine`,
  /// `https://nowssb.com/earn` or a bare `coupons` to a page + args. Longest
  /// path wins; unknown → null (caller shows a friendly fallback).
  static ({AppPage page, RouteArgs args})? resolve(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return null;
    var path = uri.path;
    if (uri.scheme == 'nowssb' && uri.host.isNotEmpty) path = '/${uri.host}$path';
    if (!path.startsWith('/')) path = '/$path';
    if (path.length > 1 && path.endsWith('/')) path = path.substring(0, path.length - 1);
    KitRoute? best;
    for (final r in routes.values) {
      if ((path == r.path || path.startsWith('${r.path}/')) && (best == null || r.path.length > best.path.length)) best = r;
    }
    if (best == null) return null;
    final rest = path.substring(best.path.length);
    final q = uri.queryParameters;
    return (
      page: best.page,
      args: RouteArgs(
        tab: q['tab'],
        id: q['id'] ?? (rest.length > 1 ? rest.substring(1) : null),
        extra: Map.of(q)..remove('tab')..remove('id'),
      ),
    );
  }

  static KitRoute? byScreenId(String id) {
    for (final r in routes.values) {
      if (r.screenId == id) return r;
    }
    return null;
  }
}
