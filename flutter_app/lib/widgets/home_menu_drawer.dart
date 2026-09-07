/// Shared hamburger menu — website `#menuDrawer` / `openMenu` (part012.js).
///
/// Full-screen slide-in from the right, same sections and copy as index.html,
/// same CDN icons. Fashion opens the dark glass look; Normal opens the
/// neumorphic light look (`body.nm-mode #menuDrawer`). Quick Links (part061)
/// is a different sheet — this is only the hamburger.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../data/settings.dart';
import '../media/nwsb_image.dart';
import '../screens/notifications_settings.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/sound_library.dart';
import '../screens/store/meaning_store.dart';
import '../screens/widgets_page.dart';
import '../theme/tokens.dart';

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

  static const _bgFashion =
      'https://media.nowssb.com/migrated-images/3590ce677702261a_grok_image_1784093977513_alcdo3.jpg';

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
    final bg = light ? const Color(0xFFEEF1F7) : const Color(0xB7060C18);
    final headerBg = light ? const Color(0xFFEEF1F7) : const Color(0xEB060C18);
    final titleColor = light ? NwsbColors.ink : Colors.white;
    final labelColor = light ? NwsbColors.gold : const Color(0x4DFFFFFF);
    final footerColor =
        light ? const Color(0x66000000) : const Color(0x4DFFFFFF);

    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!light) ...[
              Positioned.fill(
                child: NwsbImage(url: _bgFashion, fit: BoxFit.cover),
              ),
              const Positioned.fill(
                child: ColoredBox(color: Color(0xB3060A14)),
              ),
            ] else
              Positioned.fill(child: ColoredBox(color: bg)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(20, top + 14, 20, 16),
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
                    padding: EdgeInsets.fromLTRB(0, 0, 0, bottom + 40),
                    children: [
                      _SectionLabel('Practice', color: labelColor),
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
                      _SectionLabel('Content', color: labelColor),
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
                      _SectionLabel('Journey', color: labelColor),
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
                      _SectionLabel('Account', color: labelColor),
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
                                _push(context, const WidgetsPage()),
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
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
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
          color: light ? Colors.white : const Color(0x14FFFFFF),
          shape: BoxShape.circle,
          border: light
              ? null
              : Border.all(color: const Color(0x22FFFFFF)),
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
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: light ? NwsbColors.ink : Colors.white,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w700,
          color: color,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: light ? const Color(0xFFF0F2F7) : const Color(0x09FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: light
            ? null
            : Border.all(color: const Color(0x1AFFFFFF)),
        boxShadow: light
            ? const [
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
              ]
            : null,
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
    final labelColor = light ? NwsbColors.ink : Colors.white;
    final subColor =
        light ? const Color(0x73000000) : const Color(0x6BFFFFFF);
    final chevColor =
        light ? const Color(0x47000000) : const Color(0x2EFFFFFF);

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
                : Border(
                    bottom: BorderSide(
                      color: light
                          ? const Color(0x0F000000)
                          : const Color(0x0DFFFFFF),
                    ),
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: light
                      ? const Color(0xFFEEF1F7)
                      : const Color(0x0FFFFFFF),
                  borderRadius: BorderRadius.circular(roundIcon ? 18 : 8),
                  border: light
                      ? null
                      : Border.all(color: const Color(0x14FFFFFF)),
                  boxShadow: light
                      ? const [
                          BoxShadow(
                            color: Color(0x21000000),
                            blurRadius: 7,
                            offset: Offset(3, 3),
                            spreadRadius: -1,
                            // inset feel approximated
                          ),
                        ]
                      : null,
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
