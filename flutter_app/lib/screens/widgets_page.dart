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
import '../data/practice_progress.dart';
import '../data/home_widget_sync.dart';
import '../data/settings.dart';
import '../media/nwsb_video.dart';
import '../theme/tokens.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/page_shell.dart';
import 'fashion_plus.dart';
import 'healing_path.dart';
import 'notifications_settings.dart';
import 'player_settings.dart';
import 'practice.dart';
import 'store.dart';
import 'profile.dart';
import 'progress/progress_screen.dart';
import 'quick_access.dart';
import 'sound_library.dart';
import 'store/meaning_store.dart';
import '../admin/template/editable.dart';
import '../admin/layout/layout_sections.dart';

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
    final bottom = MediaQuery.paddingOf(context).bottom;
    final filmOn = s.fashionPlus && s.fashionHome;

    // Settings sub-page shell — same backdrop (Fashion film / photo via
    // AppBackdrop), white round back and heading as its sibling pages.
    return PageShell(
      eyebrow: 'Widgets & features',
      title: 'Hero header',
      film: 'assets/video/hero-bg.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      // #stBg — the page's own Fashion film / photo, kept.
      background: filmOn
          ? NwsbVideo(
              asset: s.fashionVideoAsset,
              fit: BoxFit.cover,
              slot: 'widgets_page.WidgetsPage',
            )
          : (s.fashionImageAsset != null
              ? EditableImage.asset(
                  s.fashionImageAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF05070E),
                  ),
                  slot: 'widgets_page.WidgetsPage',
                )
              : EditableImage.asset(
                  'assets/fashion/fp-intro.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const AppBackdrop(),
                  slot: 'widgets_page.WidgetsPage',
                )),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(bottom: bottom + 40),
          sliver: SliverList.list(
            // Server-driven order (Admin → UI Editor); bundled order by default.
            children: layoutChildren(context, 'widgets', [
                    const LSection('intro', 'Intro', Padding(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EditableLabel('widgets_page.WidgetsPage',
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
                          EditableLabel('widgets_page.WidgetsPage',
                            'Three ways the top of your home can look. Pick one — it changes straight away.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              color: Color(0x99FFFFFF),
                            ),
                          ),
                        ],
                      ),
                    )),
                    LSection('homewidget', 'Home-screen widget', _Rail(
                      title: 'Home-screen widget',
                      sub: 'Your streak and the word of the day, on your phone',
                      child: const _HomeWidgetCard(),
                    )),
                    LSection('hero', 'Hero header styles', _Rail(
                      title: 'Hero header',
                      child: _HeroRail(current: s.heroStyle),
                    )),
                    const SizedBox(height: 8),
                    LSection('jump', 'Jump to', _Rail(
                      title: 'Jump to',
                      sub: 'Screens that already exist',
                      child: _JumpRail(
                        onPractice: () => _push(const PracticeScreen()),
                        onLibrary: () => _push(const SoundLibraryScreen()),
                        onProgress: () => _push(
                          PracticeProgressScreen(
                            words: ContentStore.instance.library,
                          ),
                        ),
                        onStore: () => _push(const StoreScreen()),
                        onMeaning: () => _push(const MeaningStoreScreen()),
                        onConnect: () {
                          Navigator.of(context).maybePop();
                        },
                        onNotifs: () =>
                            _push(const NotificationsSettingsPage()),
                        onProfile: () => _push(const ProfileScreen()),
                      ),
                    )),
                    LSection('make', 'Make it yours', _Rail(
                      title: 'Make it yours',
                      sub: 'How the app looks and plays',
                      child: _MakeRail(
                        fashionPlus: s.fashionPlus,
                        fashionHome: s.fashionHome,
                        onFashionPlusPage: () =>
                            _push(const FashionPlusScreen()),
                        onQuickAccess: () => _push(const QuickAccessScreen()),
                        onPlayer: () => _push(const PlayerSettingsScreen()),
                        onTogglePlus: s.setFashionPlus,
                        onToggleHome: s.setFashionHome,
                        showHealing: s.showHealing,
                        onToggleHealing: s.setShowHealing,
                        onHealing: () => _push(const HealingPathScreen()),
                        onProfile: () => _push(const ProfileScreen()),
                      ),
                    )),
            ]),
          ),
        ),
      ],
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
                EditableLabel('widgets_page.Rail',
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
                          child: EditableImage.asset(
                            'assets/fashion/fp-intro.webp',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                                slot: 'widgets_page.HeroCard',
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
                            border: Border.all(color: const Color(0x44FFFFFF)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x88000000),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const EditableLabel('widgets_page.HeroCard',
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
                          child: EditableLabel('widgets_page.HeroCard',
                            'NowssB',
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
                      EditableLabel('widgets_page.HeroCard',
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
                      EditableLabel('widgets_page.HeroCard',
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
                    child: const EditableLabel('widgets_page.HeroCard',
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
                      child: const EditableLabel('widgets_page.HeroCard',
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
      (
        Icons.library_music_outlined,
        'Sound Library',
        'Every word you own',
        onLibrary
      ),
      (
        Icons.insights_outlined,
        'Progress',
        'How far you have come',
        onProgress
      ),
      (Icons.storefront_outlined, 'Store', 'Words and frequencies', onStore),
      (Icons.menu_book_outlined, 'Meaning', 'What it truly means', onMeaning),
      (Icons.people_outline, 'Connect', 'The social space', onConnect),
      (
        Icons.notifications_none,
        'Notifications',
        'What you have missed',
        onNotifs
      ),
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
    required this.showHealing,
    required this.onToggleHealing,
    required this.onHealing,
    required this.onProfile,
  });

  final bool fashionPlus;
  final bool fashionHome;
  final VoidCallback onFashionPlusPage;
  final VoidCallback onQuickAccess;
  final VoidCallback onPlayer;
  final ValueChanged<bool> onTogglePlus;
  final ValueChanged<bool> onToggleHome;
  final bool showHealing;
  final ValueChanged<bool> onToggleHealing;
  final VoidCallback onHealing;
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
            icon: Icons.spa_outlined,
            title: 'Personalised Healing',
            sub: showHealing ? 'On your home' : 'Add it to home',
            onTap: onHealing,
            trailing: Switch(
              value: showHealing,
              onChanged: onToggleHealing,
              activeThumbColor: NwsbColors.goldLight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
        padding: const EdgeInsets.all(8),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0x12FFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x21FFFFFF)),
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
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
            EditableLabel('widgets_page.GoCard',
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            EditableLabel('widgets_page.GoCard',
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8,
                height: 1.1,
                color: Color(0x85FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live preview of the Android home-screen widget (same streak, same word
/// of the day — HomeWidgetSync) and the button that pins it.
class _HomeWidgetCard extends StatefulWidget {
  const _HomeWidgetCard();
  @override
  State<_HomeWidgetCard> createState() => _HomeWidgetCardState();
}

class _HomeWidgetCardState extends State<_HomeWidgetCard> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    PracticeProgress.instance.addListener(_tick);
    ContentStore.instance.addListener(_tick);
  }

  @override
  void dispose() {
    PracticeProgress.instance.removeListener(_tick);
    ContentStore.instance.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    if (!HomeWidgetSync.supported) {
      _say('The home-screen widget is on Android. Long-press your home screen → Widgets → NowssB.');
      return;
    }
    setState(() => _busy = true);
    await HomeWidgetSync.instance.push();
    final ok = await HomeWidgetSync.instance.requestPin();
    if (!mounted) return;
    setState(() => _busy = false);
    _say(ok
        ? 'Choose where it goes on your home screen.'
        : 'Long-press your home screen → Widgets → NowssB to add it.');
  }

  void _say(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: EditableLabel('widgets_page.HomeWidgetCard', text), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final p = PracticeProgress.instance;
    final w = HomeWidgetSync.wordFor(DateTime.now(), ContentStore.instance.library);
    final today = HomeWidgetSync.day(DateTime.now());
    final streak = p.streak;
    final status = p.lastPracticed == today
        ? 'Practised today · well done'
        : (streak > 0 ? 'Practise today to keep it' : 'Start a streak today');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Mirrors res/layout/nowssb_widget.xml.
        Container(
          height: 132,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x40E8D5A3)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF050A16), Color(0xFF0B1730), Color(0xFF14213D)],
            ),
            boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              constraints: const BoxConstraints(minWidth: 84),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x26FFFFFF)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFE8D5A3), size: 22),
                Text('$streak', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600, height: 1)),
                const SizedBox(height: 2),
                Text(streak == 1 ? 'DAY STREAK' : 'DAYS IN A ROW',
                    style: const TextStyle(color: Color(0xB3E8D5A3), fontSize: 9, letterSpacing: 1.1)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Expanded(
                    child: EditableLabel('widgets_page.HomeWidgetCard', 'WORD OF THE DAY',
                        style: TextStyle(color: Color(0xFFE8D5A3), fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w600)),
                  ),
                  EditableLabel('widgets_page.HomeWidgetCard', 'NOWSSB',
                      style: TextStyle(color: Color(0x66FFFFFF), fontSize: 8, letterSpacing: 2.4, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Text(w?.word ?? 'NowssB',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                Expanded(
                  child: Text(w == null ? "Open NowssB once to load today's word" : HomeWidgetSync.lineFor(w),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontWeight: FontWeight.w300)),
                ),
                Row(children: [
                  Expanded(
                    child: Text(status,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 10)),
                  ),
                  Container(
                    height: 30,
                    padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_arrow_rounded, size: 16, color: NwsbColors.ink),
                      SizedBox(width: 3),
                      EditableLabel('widgets_page.HomeWidgetCard', 'Practise',
                          style: TextStyle(color: NwsbColors.ink, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: _busy ? null : _add,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                color: const Color(0x33FFFFFF),
                border: Border.all(color: const Color(0x44FFFFFF)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_to_home_screen_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                EditableLabel('widgets_page.HomeWidgetCard', _busy ? 'Adding…' : 'Add to home screen',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
