/// Page bots add ONE line here to plug their rebuilt screen into the
/// registry. It only shows while `newui_<flag>` is on (admins by default).
///
///   AppRoutes.registerRebuilt(AppPage.coupons, (c, a) => CouponsHome(tab: a.tab));
library;

import '../features/gifts/newui/gifts_hub_page.dart';
import '../features/rewards_newui/rewards_page.dart';
import '../features/coins/wallet/coins_wallet_entry.dart';
import '../pages/partner/partner_home_page.dart';
import 'app_routes.dart';

bool _done = false;

void registerRebuiltPages() {
  if (_done) return;
  _done = true;
  AppRoutes.registerRebuilt(AppPage.rewards, (c, a) => const RewardsNewUiPage());
  AppRoutes.registerRebuilt(AppPage.gifts, (c, a) => GiftsNewUiPage(initialTab: a.tab));
  AppRoutes.registerRebuilt(AppPage.coins, buildCoinsWallet);
  AppRoutes.registerRebuilt(AppPage.partner, (c, a) => const PartnerHomePage());
  // ignore: unused_local_variable
  const pages = AppPage.values; // keeps the import live until the first line lands
}
