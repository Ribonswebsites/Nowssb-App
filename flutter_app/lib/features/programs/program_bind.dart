/// Loads the real Earn, Rewards, Coupons, Gifts and Earnings pages into
/// [Programmes]. Imported from main so every entry opens the working page.
library;

import '../circle/circle_screen.dart';
import '../earn/earnings_screen.dart';
import '../economy/coupon_screen.dart';
import '../gifts/gifts_screen.dart';
import '../vault/vault_screen.dart';
import '../coins/coins_wallet_screen.dart';
import 'program_router.dart';
import 'rewards_program.dart' show isCoinHistoryTab;

final bool programPagesBound = _bind();

bool _bind() {
  Programmes.bind(Programme.earn, (tab) => CircleScreen(initialTab: tab));
  Programmes.bind(Programme.rewards, (tab) => isCoinHistoryTab(tab) ? const CoinsWalletScreen(initialTab: CoinsTab.history) : VaultScreen(initialTab: tab));
  Programmes.bind(Programme.coupons, (tab) => CouponScreen(initialTab: tab));
  Programmes.bind(Programme.gifts, (tab) => GiftsScreen(initialTab: tab));
  Programmes.bind(Programme.earnings, (_) => const EarningsScreen());
  return true;
}
