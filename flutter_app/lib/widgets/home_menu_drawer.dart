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
import '../features/circle/circle_screen.dart';
import '../features/earn/earnings_screen.dart';
import '../features/social/connect_screen.dart';
import '../features/social/echo_wall_screen.dart';
import '../features/wordprint/word_print_screen.dart';
import '../screens/about_page.dart';
import '../screens/notifications_settings.dart';
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
import 'glass_list_card.dart';
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
                      GlassListCard(
                        icon: Icons.explore_outlined,
                        overline: 'NowssB menu · Go',
                        title: 'Home, practice, library',
                        children: [
                          GlassTile(icon: Icons.home_rounded, title: 'Home', sub: 'Dashboard', onTap: () => _goTab(context, 0)),
                          GlassTile(icon: Icons.self_improvement_rounded, title: 'Daily Practice', sub: 'Morning ritual', onTap: () => _goTab(context, 1)),
                          GlassTile(icon: Icons.graphic_eq_rounded, title: 'Sound Library', sub: 'Root frequencies', onTap: () => _push(context, const SoundLibraryScreen())),
                          GlassTile(icon: Icons.science_outlined, title: 'Word Science', sub: 'The NowssB system', onTap: () => _push(context, const AboutNowssbScreen(science: true))),
                        ],
                      ),
                      GlassListCard(
                        icon: Icons.person_rounded,
                        overline: 'NowssB menu · Account',
                        title: 'Store, profile, settings',
                        children: [
                          GlassTile(icon: Icons.shopping_bag_outlined, title: 'NowssB Store', sub: 'Word and meaning libraries', onTap: () => _goTab(context, 3)),
                          GlassTile(icon: Icons.menu_book_rounded, title: 'Meaning Store', sub: 'Hidden meanings', onTap: () => _push(context, const MeaningStoreScreen())),
                          GlassTile(icon: Icons.person_outline_rounded, title: 'Profile', sub: 'Account and earnings', onTap: () => _goTab(context, 4)),
                          GlassTile(icon: Icons.settings_outlined, title: 'Settings', sub: 'Player, look, alerts', onTap: () => _push(context, const AppSettingsScreen())),
                          GlassTile(icon: Icons.workspace_premium_outlined, title: 'Plans', sub: 'Resonance, Frequency, Frequency X', onTap: () => _push(context, const SubscriptionScreen())),
                          GlassTile(icon: Icons.notifications_none_rounded, title: 'Notifications', sub: 'This phone', onTap: () => _push(context, const NotificationsSettingsPage())),
                          GlassTile(icon: Icons.toll_rounded, title: 'NowssB Earn', sub: 'Agents, codes, commission', onTap: () => _push(context, const CircleScreen())),
                          GlassTile(icon: Icons.fingerprint_rounded, title: 'Word Print', sub: 'Public profile', onTap: () => _push(context, const WordPrintScreen())),
                          GlassTile(icon: Icons.forum_outlined, title: 'Echo Wall', sub: 'Reflections', onTap: () => _push(context, const EchoWallScreen())),
                          GlassTile(icon: Icons.account_balance_wallet_outlined, title: 'Earnings', sub: 'Payouts and commissions', onTap: () => _push(context, const EarningsScreen())),
                          GlassTile(icon: Icons.receipt_long_outlined, title: 'Activity', sub: 'Coin and cash ledger', onTap: () => _push(context, const EarningsScreen())),
                          GlassTile(icon: Icons.people_outline_rounded, title: 'NowssB Connect', sub: 'Thoughts, quotes & images', onTap: () => _push(context, const ConnectScreen())),
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
