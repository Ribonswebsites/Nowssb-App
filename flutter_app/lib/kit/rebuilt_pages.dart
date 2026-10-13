/// Page bots add ONE line here to plug their rebuilt screen into the
/// registry. It only shows while `newui_<flag>` is on (admins by default).
///
///   AppRoutes.registerRebuilt(AppPage.coupons, (c, a) => CouponsHome(tab: a.tab));
library;

import '../features/rewards_newui/rewards_page.dart';
import 'app_routes.dart';

bool _done = false;

void registerRebuiltPages() {
  if (_done) return;
  _done = true;
  AppRoutes.registerRebuilt(AppPage.rewards, (c, a) => const RewardsNewUiPage());
  // ignore: unused_local_variable
  const pages = AppPage.values; // keeps the import live until the first line lands
}
