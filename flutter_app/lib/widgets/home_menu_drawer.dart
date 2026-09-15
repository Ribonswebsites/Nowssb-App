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

import '../data/content.dart';
import '../data/settings.dart';
import '../media/nwsb_image.dart';
import '../screens/app_settings.dart';
import '../screens/notifications_settings.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/sound_library.dart';
import '../screens/store/meaning_store.dart';
import '../theme/tokens.dart';
import 'black_glass_banner.dart';

/// Opens the website hamburger (`#menuDrawer`) over the current route.
Future<void> showHomeMenuDrawer(
  BuildContext context, {
  required void Function(int tab) goTab,
}) {
  HapticFeedback.lightImpact();
  final light = !Settings.instance.fashionHome;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Menu',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, anim, secondary) {
      return HomeMenuDrawer(
        light: light,
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

  // Icon URLs — index.html `#menuDrawer` rows, verbatim.
  static const _ico = {
    'home':
        'https://media.nowssb.com/migrated-images/4815ce65fb831cbf_569b91f0-578c-11f1-b67f-cfd32a085e10_pm6xc7.png',
    'practice':
        'https://media.nowssb.com/migrated-images/44ed38a222535b9c_38538b80-56d8-11f1-8fad-095787cce754_xam2bb.png',
    'routines':
        'https://media.nowssb.com/migrated-images/307233cd22669455_file_00000000f740820ba6aaa761133e8889_fitm0p.png',
    'library':
        'https://media.nowssb.com/migrated-images/62e5d0908e54a2a6_c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png',
    'science':
        'https://media.nowssb.com/migrated-images/18d60349303620d7_f89da3a0-578a-11f1-9331-1302872077be_xfgkbq.png',
    'shabda':
        'https://media.nowssb.com/migrated-images/8d5ed439e0e80c36_49a3a200-578a-11f1-9331-1302872077be_jgmnss.png',
    'progress':
        'https://media.nowssb.com/migrated-images/8cf0327e534eb7d4_a7b04840-5789-11f1-9331-1302872077be_bqobig.png',
    'store':
        'https://media.nowssb.com/migrated-images/86a1283688196499_ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png',
    'meaning':
        'https://media.nowssb.com/migrated-images/fb6b31dcda617790_cb456de0-56cf-11f1-8fad-095787cce754_zplzrc.png',
    'profile':
        'https://media.nowssb.com/migrated-images/3979b9fa35b579e6_62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png',
    'settings':
        'https://media.nowssb.com/migrated-images/523b5889d13cb14a_260480b0-56d8-11f1-8fad-095787cce754_rz6zbi.png',
    'connect':
        'https://media.nowssb.com/migrated-images/ea559460014dd8d9_file_00000000b84c7209ab496862cacd6a7f_kagsie.png',
  };

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  void _goTab(BuildContext context, int tab) {
    Navigator.of(context).pop();
    Future<void>.delayed(const Duration(milliseconds: 280), () => goTab(tab));
  }

  void _push(BuildContext context, Widget page) {
    final root = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).pop();
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      root.push(MaterialPageRoute<void>(builder: (_) => page));
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Fashion menu mirrors AppSettingsScreen exactly (solid deep + gold wash,
    // not the old photo backdrop). Normal keeps neumorphic light look.
    final bg = light ? const Color(0xFFEEF1F7) : const Color(0xFF060C18);
    final headerBg = light ? const Color(0xFFEEF1F7) : const Color(0xEB060C18);
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
                child: ColoredBox(color: Color(0xFF060C18)),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.6, -0.8),
                      radius: 1.1,
                      colors: [Color(0x44E8D5A3), Color(0x00060C18)],
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
                                text: 'NOWSBANSIU',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
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
                      _SectionLabel('Practice', light: light),
                      _Group(
                        light: light,
                        children: [
                          _Row(
                            light: light,
                            iconUrl: _ico['home']!,
                            label: 'Home',
                            sub: 'Dashboard',
                            onTap: () => _goTab(context, 0),
                          ),
                          _Row(
                            light: light,
                            iconUrl: _ico['practice']!,
                            label: 'Daily Practice',
                            sub: 'Morning ritual',
                            onTap: () => _goTab(context, 1),
                          ),
                          _Row(
                            light: light,
                            iconUrl: _ico['routines']!,
                            iconSize: 26,
                            label: 'My Routines',
                            sub: '5 routine slots',
                            onTap: () => _goTab(context, 1),
                          ),
                        ],
                      ),
                      _SectionLabel('Content', light: light),
                      _Group(
                        light: light,
                        children: [
                          _Row(
                            light: light,
                            iconUrl: _ico['library']!,
                            label: 'Sound Library',
                            sub: 'Root frequencies',
                            onTap: () =>
                                _push(context, const SoundLibraryScreen()),
                          ),
                          _Row(
                            light: light,
                            iconUrl: _ico['science']!,
                            label: 'Word Science',
                            sub: 'NOWSBANSIU system',
                            onTap: () => _goTab(context, 2),
                          ),
                          _Row(
                            light: light,
                            iconUrl: _ico['shabda']!,
                            label: 'Shabdapathy',
                            sub: 'Foundations',
                            onTap: () => _goTab(context, 2),
                          ),
                        ],
                      ),
                      _SectionLabel('Journey', light: light),
                      _Group(
                        light: light,
                        children: [
                          _Row(
                            light: light,
                            iconUrl: _ico['progress']!,
                            label: 'My Progress',
                            sub: 'Healing journey',
                            onTap: () => _push(
                              context,
                              PracticeProgressScreen(
                                words: ContentStore.instance.library,
                              ),
                            ),
                          ),
                          _Row(
                            light: light,
                            iconUrl: _ico['store']!,
                            label: 'NowssB Store',
                            sub: 'Word & Meaning Libraries',
                            onTap: () => _goTab(context, 3),
                          ),
                          _Row(
                            light: light,
                            iconUrl: _ico['meaning']!,
                            label: 'Meaning Store',
                            sub: 'True hidden meanings',
                            onTap: () =>
                                _push(context, const MeaningStoreScreen()),
                          ),
                        ],
                      ),
                      _SectionLabel('Account', light: light),
                      _Group(
                        light: light,
                        children: [
                          _Row(
                            light: light,
                            iconUrl: _ico['profile']!,
                            label: 'Profile',
                            sub: 'Settings & account',
                            onTap: () => _goTab(context, 4),
                          ),
                          _Row(
                            light: light,
                            iconUrl: _ico['settings']!,
                            label: 'Settings',
                            sub: 'Preferences',
                            onTap: () =>
                                _push(context, const AppSettingsScreen()),
                          ),
                          _Row(
                            light: light,
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              size: 21,
                              color: NwsbColors.gold,
                            ),
                            label: 'Notifications',
                            sub: 'Turn them on for this phone',
                            onTap: () => _push(
                              context,
                              const NotificationsSettingsPage(),
                            ),
                          ),
                          _Row(
                            light: light,
                            iconUrl: _ico['connect']!,
                            roundIcon: true,
                            label: 'NowssB Connect',
                            sub: 'Saved, liked, settings & theme',
                            onTap: () => _goTab(context, 0),
                          ),
                          _Row(
                            light: light,
                            icon: const Icon(
                              Icons.download_rounded,
                              size: 20,
                              color: NwsbColors.gold,
                            ),
                            label: 'Download App',
                            sub: 'Install NowssB on your device',
                            last: true,
                            onTap: () {
                              final messenger = ScaffoldMessenger.maybeOf(context);
                              _close(context);
                              messenger?.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'You are already in the NowssB app.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(light ? 24 : 4, 40, light ? 24 : 4, 0),
                        child: Text(
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
    this.iconUrl,
    this.icon,
    this.iconSize = 22,
    this.roundIcon = false,
    this.last = false,
  });

  final bool light;
  final String label;
  final String sub;
  final VoidCallback onTap;
  final String? iconUrl;
  final Widget? icon;
  final double iconSize;
  final bool roundIcon;
  final bool last;

  @override
  Widget build(BuildContext context) {
    if (!light) {
      // Match AppSettingsScreen _NavRow → NestedDarkWrap.
      final leading = icon ??
          ClipRRect(
            borderRadius: BorderRadius.circular(roundIcon ? 18 : 8),
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: NwsbImage(url: iconUrl!, fit: BoxFit.contain),
            ),
          );
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
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
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
                  borderRadius: BorderRadius.circular(roundIcon ? 18 : 8),
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
                child: icon ??
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(roundIcon ? 18 : 0),
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: NwsbImage(
                          url: iconUrl!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
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
