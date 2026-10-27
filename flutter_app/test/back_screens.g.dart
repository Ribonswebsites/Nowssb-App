// GENERATED
import 'package:flutter/widgets.dart';
import 'package:nowssb/features/bazaar/bazaar_screen.dart';
import 'package:nowssb/features/circle/circle_screen.dart';
import 'package:nowssb/features/earn/earn_hub_screen.dart';
import 'package:nowssb/features/earn/earn_topic_page.dart';
import 'package:nowssb/features/earn/earnings_screen.dart';
import 'package:nowssb/features/economy/coupon_screen.dart';
import 'package:nowssb/features/economy/partner_screen.dart';
import 'package:nowssb/features/economy/reference_screen.dart';
import 'package:nowssb/features/gifts/gifts_screen.dart';
import 'package:nowssb/features/gifts/spin_wheel.dart';
import 'package:nowssb/features/notifications/inbox_screen.dart';
import 'package:nowssb/features/notifications/notif_preferences_screen.dart';
import 'package:nowssb/features/notifications/notif_router.dart';
import 'package:nowssb/features/programs/coupons_program.dart';
import 'package:nowssb/features/programs/earn_program.dart';
import 'package:nowssb/features/programs/gifts_program.dart';
import 'package:nowssb/features/programs/partner_program.dart';
import 'package:nowssb/features/programs/program_hub.dart';
import 'package:nowssb/features/programs/reference_program.dart';
import 'package:nowssb/features/programs/rewards_program.dart';
import 'package:nowssb/features/social/connect_screen.dart';
import 'package:nowssb/features/social/echo_wall_screen.dart';
import 'package:nowssb/features/vault/vault_screen.dart';
import 'package:nowssb/features/wordprint/word_print_screen.dart';
import 'package:nowssb/screens/app_settings.dart';
import 'package:nowssb/screens/aura_sound_library.dart';
import 'package:nowssb/screens/concept/drop_v4_concepts.dart';
import 'package:nowssb/screens/daily_tasks.dart';
import 'package:nowssb/screens/fashion/door_screens.dart';
import 'package:nowssb/screens/fashion/drop_studio.dart';
import 'package:nowssb/screens/fashion/sections_mid.dart';
import 'package:nowssb/screens/fashion_plus.dart';
import 'package:nowssb/screens/features_page.dart';
import 'package:nowssb/screens/healing_path.dart';
import 'package:nowssb/screens/home_fashion.dart';
import 'package:nowssb/screens/home_normal.dart';
import 'package:nowssb/screens/library.dart';
import 'package:nowssb/screens/normal/sections_top.dart';
import 'package:nowssb/screens/notifications_settings.dart';
import 'package:nowssb/screens/nwsb_sign_in_sheet.dart';
import 'package:nowssb/screens/personal_coach.dart';
import 'package:nowssb/screens/player_guide.dart';
import 'package:nowssb/screens/player_settings.dart';
import 'package:nowssb/screens/poster/poster_pages.dart';
import 'package:nowssb/screens/practice.dart';
import 'package:nowssb/screens/profile.dart';
import 'package:nowssb/screens/progress/progress_screen.dart';
import 'package:nowssb/screens/quick_access.dart';
import 'package:nowssb/screens/quotes_live.dart';
import 'package:nowssb/screens/reader/reader_book.dart';
import 'package:nowssb/screens/reader/reader_hub.dart';
import 'package:nowssb/screens/saved_words.dart';
import 'package:nowssb/screens/select_level.dart';
import 'package:nowssb/screens/sentence_builder.dart';
import 'package:nowssb/screens/sound_library.dart';
import 'package:nowssb/screens/store.dart';
import 'package:nowssb/screens/store/cart_pages.dart';
import 'package:nowssb/screens/store/request_words.dart';
import 'package:nowssb/screens/subscription.dart';
import 'package:nowssb/screens/widgets_page.dart';
import 'package:nowssb/shell/nav_shell.dart';
import 'package:nowssb/screens/notifications_sheet.dart';
final btScreens = <String, Widget Function()>{
  'NotificationsSheet': () => const NotificationsSheet(),
  'HomeFashion': () => const HomeFashion(name: 'Healer'),
  'HomeNormal': () => const HomeNormal(name: 'Healer'),
  'NavShell': () => const NavShell(),
  'AboutNowssbScreen': () => const AboutNowssbScreen(),
  'AppSettingsScreen': () => const AppSettingsScreen(),
  'AuraSoundLibraryScreen': () => const AuraSoundLibraryScreen(),
  'BazaarScreen': () => const BazaarScreen(),
  'CartPage': () => const CartPage(),
  'CheckoutPage': () => const CheckoutPage(),
  'CircleScreen': () => const CircleScreen(),
  'ConnectScreen': () => const ConnectScreen(),
  'CouponScreen': () => const CouponScreen(),
  'CouponsProgramPage': () => const CouponsProgramPage(),
  'DailyTasksPage': () => const DailyTasksPage(),
  'DoorAccessScreen': () => const DoorAccessScreen(),
  'DoorBackgroundScreen': () => const DoorBackgroundScreen(),
  'DoorCheckoutScreen': () => const DoorCheckoutScreen(),
  'DoorFashionPlusScreen': () => const DoorFashionPlusScreen(),
  'DoorStartArtScreen': () => const DoorStartArtScreen(),
  'DoorsFoldingScreen': () => const DoorsFoldingScreen(),
  'DropStudioScreen': () => const DropStudioScreen(),
  'EarnHubScreen': () => const EarnHubScreen(),
  'EarnProgramPage': () => const EarnProgramPage(),
  'EarningsScreen': () => const EarningsScreen(),
  'EbooksStoreScreen': () => const EbooksStoreScreen(),
  'EchoWallScreen': () => const EchoWallScreen(),
  'FashStore': () => const FashStore(),
  'FashionPlusScreen': () => const FashionPlusScreen(),
  'FeaturesPage': () => const FeaturesPage(),
  'GiftsProgramPage': () => const GiftsProgramPage(),
  'GiftsScreen': () => const GiftsScreen(),
  'HealingPathScreen': () => const HealingPathScreen(),
  'InboxScreen': () => const InboxScreen(),
  'LatestUpdatePage': () => const LatestUpdatePage(),
  'LibraryScreen': () => const LibraryScreen(),
  'MeaningStoreScreen': () => const MeaningStoreScreen(),
  'NmStore': () => const NmStore(),
  'NotifPreferencesScreen': () => const NotifPreferencesScreen(),
  'NotificationsSettingsPage': () => const NotificationsSettingsPage(),
  'NwsbSignInPage': () => const NwsbSignInPage(),
  'PartnerProgramPage': () => const PartnerProgramPage(),
  'PartnerScreen': () => const PartnerScreen(),
  'PersonalCoachScreen': () => const PersonalCoachScreen(),
  'PlayerSettingsScreen': () => const PlayerSettingsScreen(),
  'PracticeProgressScreen': () => const PracticeProgressScreen(),
  'PracticeScreen': () => const PracticeScreen(),
  'ProfileScreen': () => const ProfileScreen(),
  'QuickAccessScreen': () => const QuickAccessScreen(),
  'QuotesWeekScreen': () => const QuotesWeekScreen(),
  'ReaderHubScreen': () => const ReaderHubScreen(),
  'ReferenceProgramPage': () => const ReferenceProgramPage(),
  'ReferenceScreen': () => const ReferenceScreen(),
  'RequestWordsScreen': () => const RequestWordsScreen(),
  'RewardsProgramPage': () => const RewardsProgramPage(),
  'SavedWordsScreen': () => const SavedWordsScreen(),
  'SelectLevelScreen': () => const SelectLevelScreen(),
  'SentenceBuilderScreen': () => const SentenceBuilderScreen(),
  'SignatureStoreScreen': () => const SignatureStoreScreen(),
  'SoundLibraryScreen': () => const SoundLibraryScreen(),
  'SpinWheelPage': () => const SpinWheelPage(),
  'StoreScreen': () => const StoreScreen(),
  'SubscriptionScreen': () => const SubscriptionScreen(),
  'SubscriptionTermsScreen': () => const SubscriptionTermsScreen(),
  'TrendingScreen': () => const TrendingScreen(),
  'VaultScreen': () => const VaultScreen(),
  'WidgetsPage': () => const WidgetsPage(),
  'WishlistPage': () => const WishlistPage(),
  'WordAtelierScreen': () => const WordAtelierScreen(),
  'WordPrintScreen': () => const WordPrintScreen(),
};
