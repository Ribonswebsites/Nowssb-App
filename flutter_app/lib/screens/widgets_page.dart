/// Settings → widgets & shortcuts — website `#sub-settings` / part082.js.
///
/// Current web `render()` is the hero-header picker (three looks). JUMP and
/// MAKE rails still live in part082 as the doors / make-it-yours set the
/// Features card promises ("Widgets and shortcuts"), so this page keeps:
///   1. Hero header cards (tv / full / plain)
///   2. Jump to — screens that already exist
///   3. Make it yours — Fashion Plus, Profile, Player Settings (AURA), etc.
///
/// Backdrop follows Fashion Plus film when motion is on, otherwise the
/// still `fp-intro` plate — same rule as `paintBg()` in part082.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../data/settings.dart';
import '../media/nwsb_video.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';
import 'fashion_plus.dart';
import 'notifications_settings.dart';
import 'player_settings.dart';
import 'practice.dart';
import 'store.dart';
import 'profile.dart';
import 'progress/progress_screen.dart';
import 'quick_access.dart';
import 'sound_library.dart';
import 'store/meaning_store.dart';

class WidgetsPage extends StatefulWidget {
  const WidgetsPage({super.key});

  @override
  State<WidgetsPage> createState() => _WidgetsPageState();
}

class _WidgetsPageState extends State<WidgetsPage> {
  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onSettings);
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }


  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final filmOn = s.fashionPlus && s.fashionHome;

    return Scaffold(
      backgroundColor: const Color(0xFF05070E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // #stBg
          Positioned.fill(
            child: filmOn
                ? NwsbVideo(
                    asset: s.fashionVideoAsset,
                    fit: BoxFit.cover,
                  )
                : (s.fashionImageAsset != null
                    ? Image.asset(
                        s.fashionImageAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFF05070E),
                        ),
                      )
                    : Image.asset(
                        'assets/fashion/fp-intro.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const AppBackdrop(),
                      )),
          ),
          // .st-page scrim
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x9E05070E),
                    Color(0x8005070E),
                    Color(0xB305070E),
                  ],
                  stops: [0, 0.46, 1],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18, top + 12, 18, 14),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            size: 19, color: NwsbColors.ink),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Hero header',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, bottom + 40),
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your hero header',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Three ways the top of your home can look. Pick one — it changes straight away.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              color: Color(0x99FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Rail(
                      title: 'Hero header',
                      child: _HeroRail(current: s.heroStyle),
                    ),
                    const SizedBox(height: 8),
                    _Rail(
                      title: 'Jump to',
                      sub: 'Screens that already exist',
                      child: _JumpRail(
                        onPractice: () => _push(const PracticeScreen()),
                        onLibrary: () =>
                            _push(const SoundLibraryScreen()),
                        onProgress: () => _push(
                          PracticeProgressScreen(
                            words: ContentStore.instance.library,
                          ),
                        ),
                        onStore: () => _push(const StoreScreen()),
                        onMeaning: () =>
                            _push(const MeaningStoreScreen()),
                        onConnect: () { Navigator.of(context).maybePop(); },
                        onNotifs: () =>
                            _push(const NotificationsSettingsPage()),
                        onProfile: () => _push(const ProfileScreen()),
                      ),
                    ),
                    _Rail(
                      title: 'Make it yours',
                      sub: 'How the app looks and plays',
                      child: _MakeRail(
                        fashionPlus: s.fashionPlus,
                        fashionHome: s.fashionHome,
                        onFashionPlusPage: () =>
                            _push(const FashionPlusScreen()),
                        onQuickAccess: () =>
                            _push(const QuickAccessScreen()),
                        onPlayer: () =>
                            _push(const PlayerSettingsScreen()),
                        onTogglePlus: s.setFashionPlus,
                        onToggleHome: s.setFashionHome,
                        onProfile: () => _push(const ProfileScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.title, required this.child, this.sub});
  final String title;
  final String? sub;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0x80FFFFFF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _HeroRail extends StatelessWidget {
  const _HeroRail({required this.current});
  final String current;

  static const _heroes = [
    ('tv', 'On the television', 'The set, on the page'),
    ('full', 'Full screen', 'The photographs, edge to edge'),
    ('plain', 'Plain header', 'No pictures, no set'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
        itemCount: _heroes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final (v, t, s) = _heroes[i];
          final on = current == v;
          return _HeroCard(
            title: t,
            sub: s,
            on: on,
            previewKind: v,
            onApply: () {
              HapticFeedback.mediumImpact();
              Settings.instance.setHeroStyle(v);
            },
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.sub,
    required this.on,
    required this.previewKind,
    required this.onApply,
  });

  final String title;
  final String sub;
  final bool on;
  final String previewKind;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0x0BFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: on ? const Color(0x6BE8D5A3) : const Color(0x1AFFFFFF),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x57000000),
            blurRadius: 26,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x22FFFFFF)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: previewKind == 'tv'
                        ? const [Color(0xFF1A2238), Color(0xFF0A1020)]
                        : previewKind == 'full'
                            ? const [Color(0xFF2A1A30), Color(0xFF0C0814)]
                            : const [Color(0xFF14202E), Color(0xFF0A121C)],
                  ),
                ),
                child: Stack(
                  children: [
                    if (previewKind == 'full')
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.55,
                          child: Image.asset(
                            'assets/fashion/fp-intro.webp',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    if (previewKind == 'tv')
                      Center(
                        child: Container(
                          width: 120,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF05070E),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: const Color(0x44FFFFFF)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x88000000),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'TV',
                            style: TextStyle(
                              color: Color(0x66FFFFFF),
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (previewKind == 'plain')
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Nowsbansiu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0x85FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (on)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x33E8D5A3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'In use',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: NwsbColors.goldLight,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: onApply,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                      ),
                      child: const Text(
                        'Apply now',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JumpRail extends StatelessWidget {
  const _JumpRail({
    required this.onPractice,
    required this.onLibrary,
    required this.onProgress,
    required this.onStore,
    required this.onMeaning,
    required this.onConnect,
    required this.onNotifs,
    required this.onProfile,
  });

  final VoidCallback onPractice;
  final VoidCallback onLibrary;
  final VoidCallback onProgress;
  final VoidCallback onStore;
  final VoidCallback onMeaning;
  final VoidCallback onConnect;
  final VoidCallback onNotifs;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, VoidCallback)>[
      (Icons.mic_none_rounded, 'Practice', "Today's word ritual", onPractice),
      (Icons.library_music_outlined, 'Sound Library', 'Every word you own',
          onLibrary),
      (Icons.insights_outlined, 'Progress', 'How far you have come',
          onProgress),
      (Icons.storefront_outlined, 'Store', 'Words and frequencies', onStore),
      (Icons.menu_book_outlined, 'Meaning', 'What it truly means', onMeaning),
      (Icons.people_outline, 'Connect', 'The social space', onConnect),
      (Icons.notifications_none, 'Notifications', 'What you have missed',
          onNotifs),
      (Icons.person_outline, 'Profile', 'Your account', onProfile),
    ];
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final (ico, t, s, go) = items[i];
          return _GoCard(icon: ico, title: t, sub: s, onTap: go);
        },
      ),
    );
  }
}

class _MakeRail extends StatelessWidget {
  const _MakeRail({
    required this.fashionPlus,
    required this.fashionHome,
    required this.onFashionPlusPage,
    required this.onQuickAccess,
    required this.onPlayer,
    required this.onTogglePlus,
    required this.onToggleHome,
    required this.onProfile,
  });

  final bool fashionPlus;
  final bool fashionHome;
  final VoidCallback onFashionPlusPage;
  final VoidCallback onQuickAccess;
  final VoidCallback onPlayer;
  final ValueChanged<bool> onTogglePlus;
  final ValueChanged<bool> onToggleHome;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
        children: [
          _GoCard(
            icon: Icons.auto_awesome_motion_outlined,
            title: 'Fashion Plus',
            sub: 'The motion mode',
            onTap: onFashionPlusPage,
            trailing: Switch(
              value: fashionPlus,
              onChanged: onTogglePlus,
              activeThumbColor: NwsbColors.goldLight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          _GoCard(
            icon: Icons.dark_mode_outlined,
            title: 'Fashion home',
            sub: 'Dark film home',
            onTap: () => onToggleHome(!fashionHome),
            trailing: Switch(
              value: fashionHome,
              onChanged: onToggleHome,
              activeThumbColor: NwsbColors.goldLight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          _GoCard(
            icon: Icons.graphic_eq_rounded,
            title: 'Player Settings',
            sub: 'AURA playback',
            onTap: onPlayer,
          ),
          const SizedBox(width: 12),
          _GoCard(
            icon: Icons.tune,
            title: 'Home buttons',
            sub: 'Quick Access bar',
            onTap: onQuickAccess,
          ),
          const SizedBox(width: 12),
          _GoCard(
            icon: Icons.person_outline,
            title: 'Profile',
            sub: 'Your account',
            onTap: onProfile,
          ),
        ],
      ),
    );
  }
}

class _GoCard extends StatelessWidget {
  const _GoCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0EFFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x1CFFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x57000000),
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0x12FFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x21FFFFFF)),
                  ),
                  child: Icon(icon, size: 21, color: Colors.white),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  SizedBox(
                    height: 28,
                    child: trailing,
                  ),
                ],
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                color: Color(0x85FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
