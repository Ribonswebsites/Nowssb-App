/// Every page the UI Editor can open, and every place a template section's
/// button can go. One list, so a page added here is both editable and a
/// button destination.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/content.dart';
import '../../data/models.dart';
import '../../features/earn/earn_hub_screen.dart';
import '../../features/programs/coupons_program.dart';
import '../../features/programs/earn_program.dart';
import '../../features/programs/gifts_program.dart';
import '../../features/programs/partner_program.dart';
import '../../features/programs/reference_program.dart';
import '../../features/programs/rewards_program.dart';
import '../../screens/app_settings.dart';
import '../../screens/fashion_plus.dart';
import '../../screens/healing_path.dart';
import '../../screens/home_fashion.dart';
import '../../screens/home_normal.dart';
import '../../screens/library.dart';
import '../../screens/personal_coach.dart';
import '../../screens/player_settings.dart';
import '../../screens/practice.dart';
import '../../screens/practice_player.dart';
import '../../screens/profile.dart';
import '../../screens/progress/progress_screen.dart';
import '../../screens/quick_access.dart';
import '../../screens/quotes_live.dart';
import '../../screens/reader/reader_hub.dart';
import '../../screens/saved_words.dart';
import '../../screens/sentence_builder.dart';
import '../../screens/sound_library.dart';
import '../../screens/store.dart';
import '../../screens/store/request_words.dart';
import '../../screens/subscription.dart';
import '../../screens/widgets_page.dart';
import '../../shell/nav_shell.dart';

class AppPage {
  const AppPage(this.id, this.title, this.group, this.icon, this.build, {this.tab, this.jumpTo});

  /// Also the layout id the page passes to applyLayout/layoutChildren.
  final String id;
  final String title;
  final String group;
  final IconData icon;
  final Widget Function() build;

  /// For pages that are a bottom tab: going there switches the tab.
  final int? tab;

  /// A shortcut into another page's section (e.g. Footer → home.normal).
  final (String, String)? jumpTo;
}

List<Word> _words() => ContentStore.instance.library;

final List<AppPage> kAppPages = [
  AppPage('home.normal', 'Normal home', 'Home', Icons.home_rounded, () => const HomeNormal()),
  AppPage('home.fashion', 'Fashion home', 'Home', Icons.auto_awesome_rounded, () => const HomeFashion()),
  AppPage('footer', 'Footer', 'Home', Icons.vertical_align_bottom_rounded, () => const HomeNormal(),
      jumpTo: ('home.normal', 'footer')),
  AppPage('store.home', 'Store', 'Stores', Icons.storefront_rounded, () => const StoreScreen(), tab: 3),
  AppPage('store.atelier', 'Word Atelier', 'Stores', Icons.brush_rounded, () => const WordAtelierScreen()),
  AppPage('store.meaning', 'Meaning Store', 'Stores', Icons.menu_book_rounded, () => const MeaningStoreScreen()),
  AppPage('store.signature', 'Signature Store', 'Stores', Icons.draw_rounded, () => const SignatureStoreScreen()),
  AppPage('store.ebooks', 'eBooks', 'Stores', Icons.auto_stories_rounded, () => const EbooksStoreScreen()),
  AppPage('store.request', 'Request words', 'Stores', Icons.mark_email_unread_rounded, () => const RequestWordsScreen()),
  AppPage('practice', 'Practice', 'Player', Icons.self_improvement_rounded, () => const PracticeScreen(), tab: 1),
  AppPage('player.session', 'Player / Morning Ritual', 'Player', Icons.play_circle_rounded,
      () => PracticePlayerScreen(words: _words(), title: 'Morning Ritual', showIntro: false)),
  AppPage('player.settings', 'Player settings', 'Player', Icons.tune_rounded, () => const PlayerSettingsScreen()),
  AppPage('sound.library', 'Sound Library', 'Player', Icons.graphic_eq_rounded, () => const SoundLibraryScreen(embedded: true)),
  AppPage('library', 'Library', 'Learn', Icons.local_library_rounded, () => const LibraryScreen(), tab: 2),
  AppPage('reader', 'Reader', 'Learn', Icons.chrome_reader_mode_rounded, () => const ReaderHubScreen()),
  AppPage('saved', 'Saved words', 'Learn', Icons.bookmark_rounded, () => const SavedWordsScreen()),
  AppPage('sentence', 'Sentence builder', 'Learn', Icons.short_text_rounded, () => const SentenceBuilderScreen()),
  AppPage('quotes', 'Quotes of the week', 'Learn', Icons.format_quote_rounded, () => const QuotesWeekScreen()),
  AppPage('profile', 'Profile', 'You', Icons.person_rounded, () => const ProfileScreen(), tab: 4),
  AppPage('progress', 'Progress', 'You', Icons.insights_rounded, () => PracticeProgressScreen(words: _words())),
  AppPage('subscription', 'Subscription', 'You', Icons.workspace_premium_rounded, () => const SubscriptionScreen()),
  AppPage('quickaccess', 'Quick access', 'You', Icons.apps_rounded, () => const QuickAccessScreen()),
  AppPage('settings', 'Settings', 'You', Icons.settings_rounded, () => const AppSettingsScreen()),
  AppPage('fashionplus', 'Fashion Plus', 'Explore', Icons.checkroom_rounded, () => const FashionPlusScreen()),
  AppPage('healing', 'Healing path', 'Explore', Icons.spa_rounded, () => const HealingPathScreen()),
  AppPage('earn', 'Earn & gifts', 'Explore', Icons.toll_rounded, () => const EarnHubScreen()),
  AppPage('earn.program', 'NowssB Earn (program)', 'Programs', Icons.savings_rounded, () => const EarnProgramPage()),
  AppPage('rewards.program', 'NowssB Rewards', 'Programs', Icons.star_rounded, () => const RewardsProgramPage()),
  AppPage('coupons.program', 'NowssB Coupons', 'Programs', Icons.confirmation_number_rounded, () => const CouponsProgramPage()),
  AppPage('gifts.program', 'NowssB Gifts', 'Programs', Icons.card_giftcard_rounded, () => const GiftsProgramPage()),
  AppPage('reference.program', 'NowssB Reference', 'Programs', Icons.share_rounded, () => const ReferenceProgramPage()),
  AppPage('partner.program', 'Partner Program', 'Programs', Icons.workspace_premium_rounded, () => const PartnerProgramPage()),
  AppPage('coach', 'Personal coach', 'Explore', Icons.support_agent_rounded, () => const PersonalCoachScreen()),
  AppPage('widgets', 'Widgets & features', 'Explore', Icons.widgets_rounded, () => const WidgetsPage()),
];

AppPage? appPage(String id) {
  for (final p in kAppPages) {
    if (p.id == id) return p;
  }
  return null;
}

/// Where a template button can go: the five tabs, every page above, or a
/// web address (`url:https://…`).
const kTabRoutes = <String, String>{
  'tab:0': 'Connect tab',
  'tab:1': 'Practice tab',
  'tab:2': 'Library tab',
  'tab:3': 'Store tab',
  'tab:4': 'Profile tab',
};

Map<String, String> routeChoices() => {
      ...kTabRoutes,
      for (final p in kAppPages)
        if (p.jumpTo == null) 'page:${p.id}': p.title,
    };

String routeLabel(String id) {
  if (id.startsWith('url:')) return id.substring(4);
  return routeChoices()[id] ?? 'Nowhere';
}

Future<void> openRoute(BuildContext context, String id) async {
  if (id.isEmpty) return;
  if (id.startsWith('tab:')) {
    final i = int.tryParse(id.substring(4)) ?? 0;
    Navigator.of(context).popUntil((r) => r.isFirst);
    NavScope.goTo(context, i);
    return;
  }
  if (id.startsWith('url:')) {
    final u = Uri.tryParse(id.substring(4));
    if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
    return;
  }
  if (id.startsWith('page:')) {
    final p = appPage(id.substring(5));
    if (p == null) return;
    if (p.tab != null) {
      NavScope.goTo(context, p.tab!);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => p.build()));
  }
}
