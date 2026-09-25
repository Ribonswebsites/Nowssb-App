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
import '../screens/app_settings.dart';
import '../screens/notifications_settings.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/reader/reader_hub.dart';
import '../screens/saved_words.dart';
import '../screens/shared_sections.dart';
import '../screens/sound_library.dart';
import '../screens/store/meaning_store.dart';
import '../shell/nav_shell.dart';
import '../theme/tokens.dart';
import '../widgets/nwsb_icon.dart';
import 'black_glass_banner.dart';

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
                            mark: _mark['home']!,
                            label: 'Home',
                            sub: 'Dashboard',
                            onTap: () => _goTab(context, 0),
                          ),
                          _Row(
                            light: light,
                            mark: _mark['practice']!,
                            viewBox: 22,
                            label: 'Daily Practice',
                            sub: 'Morning ritual',
                            onTap: () => _goTab(context, 1),
                          ),
                          _Row(
                            light: light,
                            mark: _mark['routines']!,
                            label: 'My Routines',
                            sub: '5 routine slots',
                            onTap: () => _push(context, const _RoutinesPage()),
                          ),
                        ],
                      ),
                      _SectionLabel('Content', light: light),
                      _Group(
                        light: light,
                        children: [
                          _Row(
                            light: light,
                            mark: _mark['library']!,
                            label: 'Sound Library',
                            sub: 'Root frequencies',
                            onTap: () =>
                                _push(context, const SoundLibraryScreen()),
                          ),
                          _Row(
                            light: light,
                            mark: _mark['science']!,
                            label: 'Word Science',
                            sub: 'NOWSBANSIU system',
                            onTap: () => _goTab(context, 2),
                          ),
                          _Row(
                            light: light,
                            mark: _mark['shabda']!,
                            label: 'Shabdapathy',
                            sub: 'Foundations',
                            onTap: () =>
                                _push(context, const ReaderHubScreen()),
                          ),
                        ],
                      ),
                      _SectionLabel('Journey', light: light),
                      _Group(
                        light: light,
                        children: [
                          _Row(
                            light: light,
                            mark: _mark['progress']!,
                            viewBox: 22,
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
                            mark: _mark['store']!,
                            label: 'NowssB Store',
                            sub: 'Word & Meaning Libraries',
                            onTap: () => _goTab(context, 3),
                          ),
                          _Row(
                            light: light,
                            mark: _mark['meaning']!,
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
                            mark: _mark['profile']!,
                            label: 'Profile',
                            sub: 'Settings & account',
                            onTap: () => _goTab(context, 4),
                          ),
                          _Row(
                            light: light,
                            mark: _mark['settings']!,
                            label: 'Settings',
                            sub: 'Preferences',
                            onTap: () =>
                                _push(context, const AppSettingsScreen()),
                          ),
                          _Row(
                            light: light,
                            mark: NwsbMarks.bell,
                            label: 'Notifications',
                            sub: 'Turn them on for this phone',
                            onTap: () => _push(
                              context,
                              const NotificationsSettingsPage(),
                            ),
                          ),
                          _Row(
                            light: light,
                            mark: _mark['connect']!,
                            label: 'NowssB Connect',
                            sub: 'Saved and liked words',
                            last: true,
                            onTap: () =>
                                _push(context, const SavedWordsScreen()),
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
        title: const Text('My Routines'),
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
