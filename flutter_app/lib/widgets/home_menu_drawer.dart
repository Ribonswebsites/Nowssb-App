/// Shared hamburger menu — website `#menuDrawer` / `openMenu` (part012.js).
///
/// Full-screen slide-in from the right, same sections and copy as index.html,
/// same CDN icons. Fashion mirrors App Settings styling (solid deep + gold
/// wash, HeavyGlassPanel groups, NestedDarkWrap rows). Normal opens the
/// neumorphic light look (`body.nm-mode #menuDrawer`). Quick Links (part061)
/// is a different sheet — this is only the hamburger.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../data/app_control.dart';
import '../data/firebase.dart';
import '../data/content.dart';
import '../screens/app_settings.dart';
import '../features/bazaar/bazaar_screen.dart';
import '../features/earn/earn_hub_screen.dart';
import '../features/economy/economy_api.dart';
import '../features/earn/earnings_screen.dart';
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
import '../theme/tokens.dart';
import '../widgets/nwsb_icon.dart';
import 'black_glass_banner.dart';
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

  /// Kept for callers; both homes open the same dark, calm menu.
  final bool light;
  final void Function(int tab) goTab;

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
    final resale = AppControl.instance.flag('resale', fallback: false);
    return Material(
      color: NwsbColors.deep,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // CLiQ-style: deep night with one soft gold moon wash.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                  center: Alignment(0.9, -1.0),
                  radius: 1.2,
                  colors: [Color(0x33E8D5A3), Color(0x00060C18)]),
            ),
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(20, top + 10, 20, bottom + 36),
            children: [
              Row(children: [
                const Expanded(
                  child: Text('Menu',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8)),
                ),
                _RoundBtn(
                    icon: Icons.close_rounded, onTap: () => _close(context)),
              ]),
              const SizedBox(height: 18),
              _MemberCard(onTap: () => _goTab(context, 4)),
              const SizedBox(height: 22),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 10,
                childAspectRatio: 0.74,
                children: [
                  _Tile3D(
                      mark: NwsbMarks.play,
                      viewBox: 22,
                      label: 'Practice',
                      onTap: () => _goTab(context, 1)),
                  _Tile3D(
                      mark: NwsbMarks.sound,
                      label: 'Sounds',
                      onTap: () => _push(context, const SoundLibraryScreen())),
                  _Tile3D(
                      mark: NwsbMarks.trending,
                      viewBox: 22,
                      label: 'Progress',
                      onTap: () => _push(
                          context,
                          PracticeProgressScreen(
                              words: ContentStore.instance.library))),
                  _Tile3D(
                      mark: NwsbMarks.bag,
                      label: 'Store',
                      onTap: () => _goTab(context, 3)),
                  _Tile3D(
                      mark: NwsbMarks.piggy,
                      label: 'Earn',
                      onTap: () => _push(context, const EarnHubScreen())),
                  _Tile3D(
                      mark: NwsbMarks.rewards,
                      label: 'Rewards',
                      onTap: () => _push(context, const VaultScreen())),
                  _Tile3D(
                      mark: NwsbMarks.gift,
                      label: 'Gifts',
                      onTap: () => _push(context, const GiftsScreen())),
                  _Tile3D(
                      mark: NwsbMarks.coupon,
                      label: 'Coupons',
                      onTap: () => _push(context, const CouponScreen())),
                ],
              ),
              const _Label('Explore'),
              _Row(
                  mark: NwsbMarks.house,
                  label: 'Home',
                  sub: 'Your dashboard',
                  onTap: () => _goTab(context, 0)),
              _Row(
                  mark: NwsbMarks.flame,
                  label: 'My Routines',
                  sub: 'Five routine slots',
                  onTap: () => _push(context, const _RoutinesPage())),
              _Row(
                  mark: NwsbMarks.book,
                  label: 'Word Science',
                  sub: 'How NowssB works',
                  onTap: () =>
                      _push(context, const AboutNowssbScreen(science: true))),
              _Row(
                  mark: NwsbMarks.signature,
                  label: 'Shabdapathy',
                  sub: 'Foundations to read',
                  onTap: () => _push(context, const ReaderHubScreen())),
              _Row(
                  mark: NwsbMarks.meaning,
                  label: 'Meaning Store',
                  sub: 'True hidden meanings',
                  onTap: () => _push(context, const MeaningStoreScreen()),
                  last: true),
              const _Label('Money'),
              if (resale)
                _Row(
                    mark: NwsbMarks.bag,
                    label: 'Resell',
                    sub: 'Listings inside the Store',
                    onTap: () => _push(context, const BazaarScreen())),
              _Row(
                  mark: NwsbMarks.bars,
                  label: 'Earnings',
                  sub: 'Balance and payouts',
                  onTap: () => _push(context, const EarningsScreen()),
                  last: true),
              const _Label('Community'),
              _Row(
                  mark: NwsbMarks.user,
                  label: 'Word Print',
                  sub: 'Your public page',
                  onTap: () => _push(context, const WordPrintScreen())),
              _Row(
                  mark: NwsbMarks.feed,
                  label: 'Echo Wall',
                  sub: 'Reflections from others',
                  onTap: () => _push(context, const EchoWallScreen()),
                  last: true),
              const _Label('You'),
              _Row(
                  mark: NwsbMarks.user,
                  label: 'Profile',
                  sub: 'Account and details',
                  onTap: () => _goTab(context, 4)),
              _Row(
                  mark: NwsbMarks.gear,
                  label: 'Settings',
                  sub: 'Preferences',
                  onTap: () => _push(context, const AppSettingsScreen())),
              _Row(
                  mark: NwsbMarks.bell,
                  label: 'Notifications',
                  sub: 'Reminders on this phone',
                  onTap: () =>
                      _push(context, const NotificationsSettingsPage()),
                  last: true),
              const SizedBox(height: 36),
              const Center(
                child: EditableLabel(
                  'home_menu_drawer.HomeMenuDrawer',
                  'Shabdapathy · v9.5',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3,
                      color: Color(0x4DFFFFFF)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});
  final IconData icon;
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
          color: const Color(0x12FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x24FFFFFF)),
        ),
        child: Icon(icon, size: 20, color: Colors.white70),
      ),
    );
  }
}

/// Quiet small-caps heading, YouTube Music library style.
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 10.5,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
            color: Color(0x8CE8D5A3)),
      ),
    );
  }
}

/// Glass shortcut tile (SBI benefit-tile layout, NowssB glass and gold).
class _Tile3D extends StatelessWidget {
  const _Tile3D(
      {required this.mark,
      required this.label,
      required this.onTap,
      this.viewBox = 24});
  final String mark;
  final String label;
  final VoidCallback onTap;
  final double viewBox;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: HeavyGlassPanel(
              radius: 20,
              padding: const EdgeInsets.all(4),
              child: NestedDarkWrap(
                margin: EdgeInsets.zero,
                radius: 16,
                padding: EdgeInsets.zero,
                child: Center(
                    child: NwsbIcon(mark,
                        size: 24,
                        color: NwsbColors.goldLight,
                        viewBox: viewBox)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Color(0xEBFFFFFF),
                fontSize: 12.5,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

/// A flat list row: icon, title, subtitle, chevron, hairline divider.
class _Row extends StatelessWidget {
  const _Row({
    required this.mark,
    required this.label,
    required this.sub,
    required this.onTap,
    this.last = false,
  });

  final String mark;
  final String label;
  final String sub;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xB3000000),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x24FFFFFF)),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: NwsbIcon(mark, size: 18, color: NwsbColors.goldLight),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EditableLabel('home_menu_drawer.Row', label,
                  style: const TextStyle(
                      color: Color(0xEBFFFFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: Color(0x33FFFFFF)),
        ]),
      ),
    );
  }
}

/// Hero member card: metallic gold with a slow sweeping sheen and glow.
class _MemberCard extends StatefulWidget {
  const _MemberCard({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat(count: 6);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? u;
    try {
      u = NwsbFirebase.ready ? FirebaseAuth.instance.currentUser : null;
    } catch (_) {
      u = null;
    }
    final name = (u?.displayName?.trim().isNotEmpty ?? false)
        ? u!.displayName!.trim()
        : 'Welcome';
    return GestureDetector(
      onTap: widget.onTap,
      child: ListenableBuilder(
        listenable: Listenable.merge([EconomyMirror.instance, _c]),
        builder: (context, _) {
          final w = EconomyMirror.instance;
          final t = _c.value;
          final glow = 0.25 + 0.15 * math.sin(t * math.pi * 2).abs();
          return AspectRatio(
            aspectRatio: 1.62,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0x66E8D5A3)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3A2E17),
                    Color(0xFF000000),
                    Color(0xFF000000)
                  ],
                  stops: [0, 0.5, 1],
                ),
                boxShadow: [
                  BoxShadow(
                      color: NwsbColors.gold.withValues(alpha: glow),
                      blurRadius: 40,
                      spreadRadius: 2,
                      offset: const Offset(0, 14))
                ],
              ),
              child: Stack(children: [
                // Sweeping metallic sheen.
                Positioned.fill(
                  child: FractionalTranslation(
                    translation: Offset(-1.2 + 2.4 * t, 0),
                    child: Transform.rotate(
                      angle: 0.35,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Color(0x00FFFFFF),
                            Color(0x55FFFFFF),
                            Color(0x00FFFFFF)
                          ], stops: [
                            0.35,
                            0.5,
                            0.65
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('NOWSSB',
                              style: TextStyle(
                                  color: Color(0xFFE8D5A3),
                                  fontSize: 12,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE8D5A3),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                                w.uid == null ? 'GUEST' : w.plan.toUpperCase(),
                                style: const TextStyle(
                                    color: Color(0xFF000000),
                                    fontSize: 10.5,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ]),
                        const Spacer(),
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.05)),
                        const SizedBox(height: 4),
                        Text(
                            w.uid == null
                                ? 'Sign in'
                                : '${w.circleTier} member',
                            style: const TextStyle(
                                color: Color(0xB3FFFFFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        if (w.uid != null) ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            _Stat(value: '${w.coins}', label: 'coins'),
                            _Stat(value: '${w.streak}', label: 'day streak'),
                            _Stat(value: '${w.practice}', label: 'sessions'),
                          ]),
                        ],
                      ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            maxLines: 1,
            style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 10.5,
                fontWeight: FontWeight.w600)),
      ]),
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
        title:
            const EditableLabel('home_menu_drawer.RoutinesPage', 'My Routines'),
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
