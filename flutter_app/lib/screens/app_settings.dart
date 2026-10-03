/// App Settings — website `#sub-social` / Preferences ported to Flutter.
///
/// Full working settings (not Widgets/Hero header). Wired from the hamburger
/// Settings row. Persists toggles via SharedPreferences. No emoji.
library;

import 'dart:ui' show ImageFilter;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../admin/admin_home.dart';
import '../admin/admin_state.dart';
import '../admin/layout/layout_sections.dart';
import '../admin/template/ui_overrides.dart';
import '../data/account_deletion.dart';
import '../data/device_flags.dart';
import '../data/phone_notifications.dart';
import '../data/practice_progress.dart';
import '../data/settings.dart';
import '../media/onboarding_warmup.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/black_glass_banner.dart';
import '../widgets/page_shell.dart';
import '../widgets/colored_split_promo_banner.dart';
import 'fashion_plus.dart';
import 'notifications_settings.dart';
import 'player_settings.dart';
import 'player_guide.dart';
import 'auth_gate.dart';
import 'profile.dart';
import 'quick_access.dart';
import 'quotes_live.dart';
import 'store/request_words.dart';
import 'widgets_page.dart';
import '../admin/template/editable.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _search = TextEditingController();
  String _q = '';

  bool _screenWake = true;
  bool _appearDiscover = true;

  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onSettings);
    _search.addListener(
        () => setState(() => _q = _search.text.trim().toLowerCase()));
    _loadLocal();
  }

  @override
  void dispose() {
    Settings.instance.removeListener(_onSettings);
    _search.dispose();
    super.dispose();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  Future<void> _loadLocal() async {
    try {
      final p = await SharedPreferences.getInstance();
      setState(() {
        _screenWake = p.getBool('ss_screen_wake') ?? true;
        _appearDiscover = p.getBool('ss_appear_discover') ?? true;
      });
      await DeviceFlags.keepAwake(_screenWake);
    } catch (_) {}
    // The real value lives on publicProfiles/{uid} (website Discover).
    final pub = await ProfileVisibility.load();
    if (pub != null && mounted) setState(() => _appearDiscover = pub);
  }

  Future<void> _setDiscover(bool v) async {
    setState(() => _appearDiscover = v);
    await _saveBool('ss_appear_discover', v);
    final ok = await ProfileVisibility.set(v);
    if (!ok && mounted) _toast('Sign in to change who can find your profile.');
  }

  Future<void> _saveBool(String k, bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(k, v);
    } catch (_) {}
  }

  bool _match(String label, [String? sub]) {
    if (_q.isEmpty) return true;
    return label.toLowerCase().contains(_q) ||
        (sub?.toLowerCase().contains(_q) ?? false);
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _cycleNav() {
    final s = Settings.instance;
    final next = s.navColor == 'glass' ? 'black' : 'glass';
    s.setNavConfig(color: next);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context); // the Admin row follows the admin flag live
    final s = Settings.instance;
    final bottom = MediaQuery.paddingOf(context).bottom;

    // Same shell as every settings sub-page (Notifications, Fashion Plus,
    // Quick access, Widgets): backdrop, white round back, glass sections.
    return PageShell(
      eyebrow: 'NowssB',
      title: 'Settings',
      film: 'assets/video/hero-bg.mp4',
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 40 + bottom),
          sliver: SliverList.list(
            // Server-driven order (Admin → UI Editor); bundled order by default.
            children: layoutChildren(context, 'settings', [
              LSection(
                  'profile',
                  'Profile card',
                  NestedDarkWrap(
                    onTap: () => _push(const ProfileScreen()),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0x22E8D5A3),
                                Color(0x1CC8E8F5),
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0x40E8D5A3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.person_outline,
                              color: NwsbColors.gold),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              EditableLabel(
                                'app_settings.AppSettingsScreen',
                                'Your profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              EditableLabel(
                                'app_settings.AppSettingsScreen',
                                'Account · plan · edit',
                                style: TextStyle(
                                  color: Color(0x85FFFFFF),
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 7),
                              _Badge('STARTER'),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Color(0x38FFFFFF), size: 18),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              LSection(
                  'promo',
                  'Promo banner',
                  ColoredSplitPromoBanner(
                    spec: SplitPromoExtras.at(13),
                    margin: EdgeInsets.zero,
                  )),
              const SizedBox(height: 18),
              LSection(
                  'search',
                  'Search settings',
                  Container(
                    height: 48,
                    margin: const EdgeInsets.only(bottom: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x24FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            size: 18, color: Color(0x59FFFFFF)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Search settings...',
                              hintStyle: TextStyle(color: Color(0x59FFFFFF)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (_match('Player Guide') ||
                  _match('Hero header') ||
                  _match('Fashion Plus') ||
                  _match('Quick Access') ||
                  _match('Today\'s quote') ||
                  _match('Player Settings'))
                LSection(
                    'intro-appearance',
                    'Intro & Appearance',
                    _Sec(
                      label: 'INTRO & APPEARANCE',
                      children: [
                        if (_match('Player Guide'))
                          _NavRow(
                            icon: Icons.menu_book_outlined,
                            title: 'Player Guide',
                            sub: 'Replay the player setup pages',
                            onTap: () {
                              // Decode the opening slide and orb badges
                              // during the route transition.
                              OnboardingWarmup.playerGuide(context,
                                  firstOnly: true);
                              _push(
                                PlayerGuideScreen(
                                  onDone: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              );
                            },
                          ),
                        if (_match('Hero header'))
                          _NavRow(
                            icon: Icons.view_agenda_outlined,
                            title: 'Hero header & widgets',
                            sub: 'TV · full · plain · shortcuts',
                            onTap: () => _push(const WidgetsPage()),
                          ),
                        if (_match('Fashion Plus'))
                          _NavRow(
                            icon: Icons.auto_awesome_outlined,
                            title: 'Fashion Plus',
                            sub: s.fashionPlus
                                ? 'Motion on'
                                : 'Still backgrounds',
                            onTap: () => _push(const FashionPlusScreen()),
                          ),
                        if (_match('Quick Access'))
                          _NavRow(
                            icon: Icons.dashboard_customize_outlined,
                            title: 'Quick Access',
                            sub: 'Customize bottom navigation',
                            onTap: () => _push(const QuickAccessScreen()),
                          ),
                        if (_match('Player Settings'))
                          _NavRow(
                            icon: Icons.tune_rounded,
                            title: 'Player Settings',
                            sub: 'AURA equalizer · quality · sleep',
                            last: true,
                            onTap: () => _push(const PlayerSettingsScreen()),
                          ),
                      ],
                    )),
              if (_match('Screen') || _match('Nav'))
                LSection(
                    'device',
                    'Device',
                    _Sec(
                      label: 'DEVICE',
                      children: [
                        if (_match('Screen'))
                          _ToggleRow(
                            icon: Icons.phone_android,
                            title: 'Keep Screen Awake',
                            sub: 'Stay on while NowssB is open',
                            value: _screenWake,
                            onChanged: (v) {
                              setState(() => _screenWake = v);
                              _saveBool('ss_screen_wake', v);
                              DeviceFlags.keepAwake(v);
                            },
                          ),
                        if (_match('Nav'))
                          _PillRow(
                            icon: Icons.space_dashboard_outlined,
                            title: 'Nav Bar',
                            sub: s.navColor == 'glass' ? 'Glass' : 'Black',
                            pill: s.navColor == 'glass' ? 'Glass' : 'Black',
                            last: true,
                            onTap: _cycleNav,
                          ),
                      ],
                    )),
              if (_match('Notification'))
                LSection(
                    'notifications',
                    'Notifications',
                    _Sec(
                      label: 'NOTIFICATIONS',
                      children: [
                        _NavRow(
                          icon: Icons.notifications_none,
                          title: 'Notifications',
                          sub: 'Daily words, streak and today’s offer',
                          last: true,
                          onTap: () => _push(const NotificationsSettingsPage()),
                        ),
                      ],
                    )),
              if (_match('Appear') || _match('Privacy') || _match('Delete'))
                LSection(
                    'privacy-social',
                    'Privacy & Social',
                    _Sec(
                      label: 'PRIVACY & SOCIAL',
                      children: [
                        if (_match('Appear'))
                          _ToggleRow(
                            icon: Icons.travel_explore,
                            title: 'Appear in Discover',
                            sub: 'Others can find your profile',
                            value: _appearDiscover,
                            onChanged: _setDiscover,
                          ),
                        if (_match('Privacy'))
                          _NavRow(
                            icon: Icons.lock_outline,
                            title: 'Privacy Policy',
                            sub: 'What NowssB keeps and why',
                            onTap: () => _openUrl('https://nowssb.com/privacy'),
                          ),
                        if (_match('Delete'))
                          _NavRow(
                            icon: Icons.person_remove_outlined,
                            title: 'Delete Account',
                            sub: 'Erase your account and its data',
                            last: true,
                            danger: true,
                            onTap: _deleteAccount,
                          ),
                      ],
                    )),
              if (_match('Cached') ||
                  _match('Clear Practice') ||
                  _match('About') ||
                  _match('Terms') ||
                  _match('Sign Out'))
                LSection(
                    'app-about',
                    'App & About',
                    _Sec(
                      label: 'APP & ABOUT',
                      children: [
                        if (_match('Cached'))
                          _NavRow(
                            icon: Icons.cleaning_services_outlined,
                            title: 'Cached Data',
                            sub: 'Clear temporary media cache',
                            onTap: _clearCache,
                          ),
                        if (_match('Clear Practice'))
                          _NavRow(
                            icon: Icons.delete_outline,
                            title: 'Clear Practice History',
                            sub: 'Remove session logs — cannot be undone',
                            danger: true,
                            onTap: () => _confirmClearHistory(),
                          ),
                        if (_match('Request') || _match('Word'))
                          _NavRow(
                            icon: Icons.edit_note_outlined,
                            title: 'Request Words',
                            sub: 'Ask the atelier for a new word',
                            onTap: () => openRequestWords(context),
                          ),
                        // Only for an account the server marks as admin
                        // (Firestore admins/{uid}) — see lib/admin.
                        if (AdminState.instance.isAdmin &&
                            (_match('Admin') ||
                                _match('Template') ||
                                _match('Edit')))
                          _NavRow(
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Admin',
                            sub: 'Words · quotes · requests · template editor',
                            onTap: () => openAdminHome(context),
                          ),
                        if (_match('About'))
                          _NavRow(
                            icon: Icons.info_outline,
                            title: 'About NowssB',
                            sub: 'v2.6.0 · nowssb.com',
                            onTap: _openAbout,
                          ),
                        if (_match('Terms'))
                          _NavRow(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            sub: 'nowssb.com/terms',
                            onTap: () => _openUrl('https://nowssb.com/terms'),
                          ),
                        if (_match('Sign Out'))
                          _NavRow(
                            icon: Icons.logout,
                            title: 'Sign Out',
                            sub: 'End this session',
                            last: true,
                            danger: true,
                            onTap: _signOut,
                          ),
                      ],
                    )),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _clearCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await VideoPool.instance.releaseAll();
    _toast('Temporary media cache cleared.');
  }

  Future<void> _openAbout() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171E),
        title: const EditableLabel(
            'app_settings.AppSettingsScreen', 'About NowssB',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const EditableLabel(
          'app_settings.AppSettingsScreen',
          'NowssB · Shabdapathy\nNatural Origin Word Science\nVersion 9.5.0\n\nnowssb.com',
          style: TextStyle(color: Color(0xE6FFFFFF), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const EditableLabel('app_settings.AppSettingsScreen', 'Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openTerms();
            },
            child: const EditableLabel(
                'app_settings.AppSettingsScreen', 'Website'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTerms() async {
    final uri = Uri.parse('https://nowssb.com');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) _toast('Could not open nowssb.com');
  }

  Future<void> _openUrl(String url) async {
    final opened =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && mounted) _toast('Could not open $url');
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171E),
        title: const EditableLabel(
            'app_settings.DeleteAccount', 'Delete your account?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const EditableLabel(
          'app_settings.DeleteAccount',
          'Your profile, practice data, wishlist, notifications and sign-in are erased. Purchases and plans cannot be restored afterwards; cancel any Google Play subscription in the Play Store first. This cannot be undone.',
          style: TextStyle(color: Color(0xB3FFFFFF), height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const EditableLabel(
                'app_settings.DeleteAccount', 'Keep my account'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const EditableLabel('app_settings.DeleteAccount', 'Delete',
                style: TextStyle(
                    color: Color(0xFFF87171), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _toast('Deleting your account…');
    final r = await AccountDeletion.deleteMyAccount();
    if (!mounted) return;
    _toast(r.message);
    if (!r.ok) return;
    NotificationBanner.items.value = const [];
    AuthGate.askForAccount();
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (ctx) => const _SignOutDialog(),
    );
    if (ok != true || !mounted) return;
    // "Remember me" keeps the person's own choice; signing out doesn't untick
    // it (that silently turned the next session's notifications off).
    const webClient =
        '1024709686012-h1h9glk84uti9cbqpht5d09igdqb8pgu.apps.googleusercontent.com';
    final google =
        GoogleSignIn(scopes: const ['email'], serverClientId: webClient);
    try {
      await google.disconnect();
    } catch (_) {}
    try {
      await google.signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    NotificationBanner.items.value = const [];
    AuthGate.askForAccount();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _confirmClearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171E),
        title: const EditableLabel(
            'app_settings.AppSettingsScreen', 'Clear practice history?',
            style: TextStyle(color: Colors.white)),
        content: const EditableLabel(
          'app_settings.AppSettingsScreen',
          'Session logs will be removed. This cannot be undone.',
          style: TextStyle(color: Color(0xB3FFFFFF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const EditableLabel('app_settings.AppSettingsScreen', 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const EditableLabel(
                'app_settings.AppSettingsScreen', 'Clear',
                style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await PracticeProgress.instance.clearAll();
      if (mounted) _toast('Practice history cleared.');
    }
  }
}

class _SignOutDialog extends StatelessWidget {
  const _SignOutDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Material(
              color: const Color(0xE6101014),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.logout_rounded, color: Colors.black),
                    ),
                    const SizedBox(height: 14),
                    const EditableLabel(
                      'app_settings.SignOutDialog',
                      'Sign out?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const EditableLabel(
                      'app_settings.SignOutDialog',
                      'You will need to choose an account the next time you sign in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xB3FFFFFF), height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => Navigator.pop(context, true),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: EditableLabel(
                              'app_settings.SignOutDialog',
                              'Sign out',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Material(
                          color: const Color(0x22FFFFFF),
                          child: InkWell(
                            onTap: () => Navigator.pop(context, false),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border:
                                    Border.all(color: const Color(0x55FFFFFF)),
                              ),
                              child: const EditableLabel(
                                'app_settings.SignOutDialog',
                                'Stay signed in',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x1AE8D5A3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x4DE8D5A3)),
      ),
      child: EditableLabel(
        'app_settings.Badge',
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: NwsbColors.goldLight,
        ),
      ),
    );
  }
}

class _Sec extends StatelessWidget {
  const _Sec({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: EditableLabel(
              'app_settings.Sec',
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: Color(0x73FFFFFF),
              ),
            ),
          ),
          HeavyGlassPanel(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            radius: 22,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    this.sub,
    required this.onTap,
    this.last = false,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String? sub;
  final VoidCallback onTap;
  final bool last;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return NestedDarkWrap(
      margin: EdgeInsets.only(bottom: last ? 0 : 8),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon,
              size: 22,
              color: danger ? const Color(0xD9F87171) : NwsbColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditableLabel(
                  'app_settings.NavRow',
                  title,
                  style: TextStyle(
                    color: danger ? const Color(0xD9F87171) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: const TextStyle(
                      color: Color(0x73FFFFFF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 16,
            color: danger ? const Color(0x80F87171) : const Color(0x55FFFFFF),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.last = false,
  });
  final IconData icon;
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return NestedDarkWrap(
      margin: EdgeInsets.only(bottom: last ? 0 : 8),
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Row(
        children: [
          Icon(icon, size: 22, color: NwsbColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditableLabel(
                  'app_settings.ToggleRow',
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                EditableLabel(
                  'app_settings.ToggleRow',
                  sub,
                  style: const TextStyle(
                    color: Color(0x73FFFFFF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            activeColor: NwsbColors.goldLight,
          ),
        ],
      ),
    );
  }
}

class _PillRow extends StatelessWidget {
  const _PillRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.pill,
    required this.onTap,
    this.last = false,
  });
  final IconData icon;
  final String title;
  final String sub;
  final String pill;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return NestedDarkWrap(
      margin: EdgeInsets.only(bottom: last ? 0 : 8),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: NwsbColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditableLabel(
                  'app_settings.PillRow',
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                EditableLabel(
                  'app_settings.PillRow',
                  sub,
                  style: const TextStyle(
                    color: Color(0x73FFFFFF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x1AE8D5A3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              pill,
              style: const TextStyle(
                color: NwsbColors.goldLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.id,
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });
  final String id, title, sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: id == 'black' || id == 'neo'
              ? Colors.black
              : const Color(0xFF0E1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? NwsbColors.goldLight : const Color(0x24FFFFFF),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: const Color(0x59000000),
              child: Column(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: selected
                          ? NwsbColors.goldLight
                          : const Color(0xBFFFFFFF),
                    ),
                  ),
                  EditableLabel(
                    'app_settings.ThemeCard',
                    sub,
                    style: const TextStyle(
                      fontSize: 7,
                      color: Color(0x73FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
