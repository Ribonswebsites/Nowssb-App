/// Shared hamburger menu — website `#menuDrawer` / `openMenu` (part012.js).
///
/// Full-screen slide-in from the right, same sections and copy as index.html,
/// same CDN icons. Fashion mirrors App Settings styling (solid deep + gold
/// wash, HeavyGlassPanel groups, NestedDarkWrap rows). Normal opens the
/// neumorphic light look (`body.nm-mode #menuDrawer`). Quick Links (part061)
/// is a different sheet — this is only the hamburger.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_control.dart';
import '../data/content.dart';
import '../screens/app_settings.dart';
import '../features/bazaar/bazaar_screen.dart';
import '../features/earn/earn_hub_screen.dart';
import '../features/earn/earnings_screen.dart';
import '../features/social/connect_screen.dart';
import '../features/social/echo_wall_screen.dart';
import '../features/gifts/gifts_screen.dart';
import '../features/economy/coupon_screen.dart';
import '../features/vault/vault_screen.dart';
import '../features/wordprint/word_print_screen.dart';
import '../screens/features_page.dart';
import '../screens/notifications_settings.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/reader/reader_hub.dart';
import '../screens/shared_sections.dart';
import '../screens/sound_library.dart';
import '../screens/store/meaning_store.dart';
import '../screens/subscription.dart';
import '../shell/nav_shell.dart';
import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/nwsb_icon.dart';
import 'black_glass_banner.dart';
import 'hub_rails.dart';
import 'routine_deck.dart';
import '../admin/template/editable.dart';

/// Opens the website hamburger (`#menuDrawer`) over the current route.
Future<void> showHomeMenuDrawer(
  BuildContext context, {
  required void Function(int tab) goTab,
}) {
  HapticFeedback.lightImpact();
  // Both homes open the same dark menu. The pale drawer was a different page.
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Menu',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, anim, secondary) {
      return HomeMenuDrawer(
        light: false,
        goTab: goTab,
      );
    },
    transitionBuilder: (ctx, anim, secondary, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: const Cubic(0.4, 0, 0.2, 1),
      );
      return Stack(
        children: [
          FadeTransition(
            opacity: curved,
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Color(0x00000000)),
            ),
          ),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ],
      );
    },
  );
}

class HomeMenuDrawer extends StatelessWidget {
  const HomeMenuDrawer({
    super.key,
    required this.light,
    required this.goTab,
  });

  /// `true` = Normal / neumorphic home (`body.nm-mode`).
  final bool light;
  final void Function(int tab) goTab;

  // Drawn marks only — no remote icon photos.
  // ignore: unused_field
  static const _mark = {
    'home': NwsbMarks.house,
    'practice': NwsbMarks.play,
    'routines': NwsbMarks.flame,
    'library': NwsbMarks.sound,
    'science': NwsbMarks.book,
    'shabda': NwsbMarks.signature,
    'progress': NwsbMarks.trending,
    'store': NwsbMarks.bag,
    'meaning': NwsbMarks.meaning,
    'profile': NwsbMarks.user,
    'settings': NwsbMarks.gear,
    'connect': NwsbMarks.reader,
  };

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  void _goTab(BuildContext context, int tab) {
    Navigator.of(context).pop();
    goTab(tab);
  }

  /// Replaces the drawer route so the home never flashes underneath.
  void _push(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Fashion menu mirrors AppSettingsScreen exactly (solid deep + gold wash,
    // not the old photo backdrop). Normal keeps neumorphic light look.
    final bg = light ? const Color(0xFFEEF1F7) : const Color(0xFF060C18);
    final headerBg = light ? const Color(0xFFEEF1F7) : const Color(0x66060C18);
    final titleColor = light ? NwsbColors.ink : Colors.white;
    final footerColor =
        light ? const Color(0x66000000) : const Color(0x4DFFFFFF);

    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!light) ...[
              const Positioned.fill(
                child: NwsbVideo(
                  asset: 'assets/video/subscription-bg.mp4',
                  priority: ClipPriority.decoration,
                  autoplay: true,
                  loop: true,
                  fit: BoxFit.cover,
                  slot: 'home_menu_drawer.HomeMenuDrawer',
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x88060C18), Color(0x55060C18), Color(0x99060C18)],
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              Positioned.fill(child: ColoredBox(color: bg)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(
                    light ? 20 : 12,
                    top + (light ? 14 : 10),
                    light ? 20 : 16,
                    light ? 16 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: headerBg,
                    border: Border(
                      bottom: BorderSide(
                        color: light
                            ? const Color(0x12000000)
                            : const Color(0x12FFFFFF),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _BackBtn(light: light, onTap: () => _close(context)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'NOWSSB',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: NwsbColors.goldLight,
                                ),
                              ),
                              const TextSpan(text: '  '),
                              TextSpan(
                                text: 'Your Menu',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      light ? 0 : 16,
                      light ? 0 : 18,
                      light ? 0 : 16,
                      bottom + 40,
                    ),
                    children: [
                      const IdentityRails(RailKind.menu),
                      RoutineDeck(
                        title: 'Go',
                        banner: 'Your menu',
                        bannerSub: 'Home, practice, library',
                        onBanner: () => _goTab(context, 0),
                        cards: [
                          WorkCard(category: 'Home', title: 'Home', meta: 'Dashboard', action: 'Open home', image: 'assets/rails/gen-01.jpg', onTap: () => _goTab(context, 0)),
                          WorkCard(category: 'Practice', title: 'Daily Practice', meta: 'Morning ritual', action: 'Open practice', image: 'assets/rails/gen-02.jpg', onTap: () => _goTab(context, 1)),
                          WorkCard(category: 'Practice', title: 'My Routines', meta: 'Five routine slots', action: 'Open routines', image: 'assets/rails/gen-03.jpg', onTap: () => _push(context, const _RoutinesPage())),
                          WorkCard(category: 'Library', title: 'Sound Library', meta: 'Root frequencies', action: 'Open library', image: 'assets/rails/gen-04.jpg', onTap: () => _push(context, const SoundLibraryScreen())),
                          WorkCard(category: 'Science', title: 'Word Science', meta: 'The NowssB system', action: 'Open science', image: 'assets/rails/gen-05.jpg', onTap: () => _push(context, const AboutNowssbScreen(science: true))),
                          WorkCard(category: 'Read', title: 'Shabdapathy', meta: 'Foundations', action: 'Open reader', image: 'assets/rails/gen-06.jpg', onTap: () => _push(context, const ReaderHubScreen())),
                        ],
                      ),
                      RoutineDeck(
                        title: 'Account',
                        banner: 'You',
                        bannerSub: 'Progress, store, settings',
                        onBanner: () => _goTab(context, 4),
                        cards: [
                          WorkCard(category: 'Progress', title: 'My Progress', meta: 'Healing journey', action: 'Open progress', image: 'assets/rails/gen-07.jpg', onTap: () => _push(context, PracticeProgressScreen(words: ContentStore.instance.library))),
                          WorkCard(category: 'Store', title: 'NowssB Store', meta: 'Word and meaning libraries', action: 'Open store', image: 'assets/rails/gen-08.jpg', onTap: () => _goTab(context, 3)),
                          WorkCard(category: 'Store', title: 'Meaning Store', meta: 'Hidden meanings', action: 'Open meanings', image: 'assets/rails/gen-09.jpg', onTap: () => _push(context, const MeaningStoreScreen())),
                          WorkCard(category: 'You', title: 'Profile', meta: 'Account and earnings', action: 'Open profile', image: 'assets/rails/gen-10.jpg', onTap: () => _goTab(context, 4)),
                          WorkCard(category: 'Gear', title: 'Settings', meta: 'Player, look, alerts', action: 'Open settings', image: 'assets/rails/gen-11.jpg', onTap: () => _push(context, const AppSettingsScreen())),
                          WorkCard(category: 'Plans', title: 'Plans', meta: 'Resonance, Frequency, Frequency X', action: 'Open plans', image: 'assets/rails/rewards-03.jpg', onTap: () => _push(context, const SubscriptionScreen())),
                          WorkCard(category: 'Alerts', title: 'Notifications', meta: 'This phone', action: 'Open alerts', image: 'assets/rails/glass-01.jpg', onTap: () => _push(context, const NotificationsSettingsPage())),
                          WorkCard(category: 'Earn', title: 'NowssB Earn', meta: 'Agents, codes, commission', action: 'Open earn', image: 'assets/rails/earn-01.jpg', onTap: () => _push(context, const EarnHubScreen())),
                          WorkCard(category: 'Rewards', title: 'NowssB Rewards', meta: 'Coins, quests, invite', action: 'Open rewards', image: 'assets/rails/rewards-01.jpg', onTap: () => _push(context, const VaultScreen())),
                          WorkCard(category: 'Gifts', title: 'NowssB Gifts', meta: 'Boxes and gift cards', action: 'Open gifts', image: 'assets/rails/gifts-01.jpg', onTap: () => _push(context, const GiftsScreen())),
                          WorkCard(category: 'Coupons', title: 'NowssB Coupons', meta: 'Scratch and codes', action: 'Open coupons', image: 'assets/rails/coupons-01.jpg', onTap: () => _push(context, const CouponScreen())),
                          WorkCard(category: 'You', title: 'Word Print', meta: 'Public profile', action: 'Open print', image: 'assets/rails/glass-02.jpg', onTap: () => _push(context, const WordPrintScreen())),
                          WorkCard(category: 'Wall', title: 'Echo Wall', meta: 'Reflections', action: 'Open the wall', image: 'assets/rails/glass-03.jpg', onTap: () => _push(context, const EchoWallScreen())),
                          WorkCard(category: 'Cash', title: 'Earnings', meta: 'Payouts and commissions', action: 'Open earnings', image: 'assets/rails/earnings-01.jpg', onTap: () => _push(context, const EarningsScreen())),
                          WorkCard(category: 'Ledger', title: 'Activity', meta: 'Coin and cash ledger', action: 'Open activity', image: 'assets/rails/clear-04.jpg', onTap: () => _push(context, const EarnHubScreen())),
                          WorkCard(category: 'Connect', title: 'NowssB Connect', meta: 'Community', action: 'Open connect', image: 'assets/rails/glass-04.jpg', onTap: () => _push(context, const ConnectScreen())),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(light ? 24 : 4, 40, light ? 24 : 4, 0),
                        child: EditableLabel('home_menu_drawer.HomeMenuDrawer',
                          'Shabdapathy · v9.5',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 3,
                            color: footerColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.light, required this.onTap});
  final bool light;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: light
              ? const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(3, 3),
                  ),
                ]
              : null,
        ),
        child: Icon(
          light ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back,
          size: light ? 16 : 19,
          color: NwsbColors.ink,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.light});
  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) {
    // Fashion uses settings _Sec label metrics; Normal keeps drawer inset.
    return Padding(
      padding: light
          ? const EdgeInsets.fromLTRB(32, 20, 20, 8)
          : const EdgeInsets.only(left: 4, bottom: 10, top: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: light ? 9 : 10,
          letterSpacing: light ? 2.5 : 1.6,
          fontWeight: light ? FontWeight.w700 : FontWeight.w800,
          color: light ? NwsbColors.gold : const Color(0x73FFFFFF),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.light, required this.children});
  final bool light;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!light) {
      // Match AppSettingsScreen _Sec → HeavyGlassPanel.
      return Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: HeavyGlassPanel(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          radius: 22,
          child: Column(children: children),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(7, 7),
          ),
          BoxShadow(
            color: Color(0xF7FFFFFF),
            blurRadius: 14,
            offset: Offset(-5, -5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.light,
    required this.label,
    required this.sub,
    required this.onTap,
    this.mark,
    this.viewBox = 24,
    this.icon,
    this.last = false,
  });

  final bool light;
  final String label;
  final String sub;
  final VoidCallback onTap;
  final String? mark;
  final double viewBox;
  final Widget? icon;
  final bool last;

  Widget _glyph(Color color) {
    if (icon != null) return icon!;
    return NwsbIcon(
      mark ?? NwsbMarks.arrow,
      size: 22,
      color: color,
      viewBox: viewBox,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!light) {
      // Match AppSettingsScreen _NavRow → NestedDarkWrap.
      final leading = _glyph(NwsbColors.gold);
      return NestedDarkWrap(
        margin: EdgeInsets.only(bottom: last ? 0 : 8),
        onTap: onTap,
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditableLabel('home_menu_drawer.Row',
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  EditableLabel('home_menu_drawer.Row',
                    sub,
                    style: const TextStyle(
                      color: Color(0x73FFFFFF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: Color(0x55FFFFFF),
            ),
          ],
        ),
      );
    }

    final labelColor = NwsbColors.ink;
    final subColor = const Color(0x73000000);
    final chevColor = const Color(0x47000000);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0x0F000000)),
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1F7),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x21000000),
                      blurRadius: 7,
                      offset: Offset(3, 3),
                      spreadRadius: -1,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _glyph(NwsbColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditableLabel('home_menu_drawer.Row',
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    EditableLabel('home_menu_drawer.Row',
                      sub,
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: chevColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// The five routine slots, opened from the menu — not the practice tab.
class _RoutinesPage extends StatelessWidget {
  const _RoutinesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060C18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060C18),
        foregroundColor: Colors.white,
        title: const EditableLabel('home_menu_drawer.RoutinesPage', 'My Routines'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          RoutinesSection(
            fashion: true,
            onTap: () {
              Navigator.of(context).pop();
              NavScope.goTo(context, 1);
            },
          ),
        ],
      ),
    );
  }
}
