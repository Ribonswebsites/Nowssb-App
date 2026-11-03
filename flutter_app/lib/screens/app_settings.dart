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
import '../features/economy/economy_api.dart';
import '../shell/nav_shell.dart';
import '../data/settings.dart';
import '../media/onboarding_warmup.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';
import '../widgets/black_glass_banner.dart';
import '../widgets/app_destinations.dart';
import '../widgets/glass_list_card.dart';
import '../widgets/routine_deck.dart';
import '../widgets/page_shell.dart';
import '../widgets/colored_split_promo_banner.dart';
import 'fashion_plus.dart';
import 'notifications_settings.dart';
import 'player_settings.dart';
import 'player_guide.dart';
import 'auth_gate.dart';
import 'quick_access.dart';
import 'quotes_live.dart';
import 'store/request_words.dart';
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
  int _set = 0;

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
      if (!mounted) return;
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
    if (!ok) {
      // Not saved anywhere that counts: put the switch back so it doesn't
      // claim a visibility the profile doesn't have.
      await _saveBool('ss_appear_discover', !v);
      if (mounted) {
        setState(() => _appearDiscover = !v);
        _toast('Sign in to change who can find your profile.');
      }
    }
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

  Widget _toggle(bool v, VoidCallback onTap) => Switch.adaptive(
        value: v,
        onChanged: (_) => onTap(),
        activeThumbColor: Colors.white,
      );

  List<List<GlassItemCard>> _groups(Settings s) {
    void wake() {
      final v = !_screenWake;
      setState(() => _screenWake = v);
      _saveBool('ss_screen_wake', v);
      DeviceFlags.keepAwake(v);
    }

    return [
      [
        GlassItemCard(icon: Icons.equalizer_rounded, overline: 'Player', title: 'Player Settings', pill: 'Equalizer, quality, sleep', pillSub: 'How words play', onTap: () => _push(const PlayerSettingsScreen())),
        GlassItemCard(icon: Icons.play_circle_outline_rounded, overline: 'Player', title: 'Player Guide', pill: 'Replay the setup', pillSub: 'A short tour of the player', onTap: () { OnboardingWarmup.playerGuide(context, firstOnly: true); _push(PlayerGuideScreen(onDone: () => Navigator.of(context).maybePop())); }),
        GlassItemCard(icon: Icons.auto_awesome_outlined, overline: 'Look', title: 'Zen Plus', pill: s.fashionPlus ? 'Motion on' : 'Still backgrounds', pillSub: 'Moving or still backgrounds', onTap: () => _push(const FashionPlusScreen())),
        GlassItemCard(icon: Icons.dashboard_customize_outlined, overline: 'Navigation', title: 'Quick Access', pill: 'Bottom navigation', pillSub: 'Shape, colour and icons', onTap: () => _push(const QuickAccessScreen())),
        GlassItemCard(icon: Icons.space_bar_rounded, overline: 'Navigation', title: 'Nav Bar', pill: s.navColor == 'glass' ? 'Glass' : 'Black', pillSub: 'Tap to switch glass or black', onTap: _cycleNav),
      ],
      [
        GlassItemCard(icon: Icons.notifications_none_rounded, overline: 'Alerts', title: 'Notifications', pill: 'Daily words and reminders', pillSub: 'What this phone tells you', onTap: () => _push(const NotificationsSettingsPage())),
        GlassItemCard(icon: Icons.light_mode_outlined, overline: 'Screen', title: 'Keep Screen Awake', pill: _screenWake ? 'Stays on' : 'Can sleep', pillSub: 'While a word is playing', onTap: wake, trailing: _toggle(_screenWake, wake)),
        GlassItemCard(icon: Icons.cleaning_services_outlined, overline: 'Storage', title: 'Cached Data', pill: 'Clear cache', pillSub: 'Temporary images and video', onTap: () { _clearCache(); }),
        GlassItemCard(icon: Icons.history_rounded, overline: 'History', title: 'Clear Practice History', pill: 'Clear history', pillSub: 'Session logs on this account', onTap: () { _confirmClearHistory(); }),
      ],
      [
        GlassItemCard(icon: Icons.travel_explore_rounded, overline: 'Privacy', title: 'Appear in Discover', pill: _appearDiscover ? 'Others can find you' : 'Hidden', pillSub: 'Your Word Print in Discover', onTap: () => _setDiscover(!_appearDiscover), trailing: _toggle(_appearDiscover, () => _setDiscover(!_appearDiscover))),
        GlassItemCard(icon: Icons.edit_note_rounded, overline: 'Words', title: 'Request Words', pill: 'Ask the atelier', pillSub: 'Request a word to be made', onTap: () => openRequestWords(context)),
        if (AdminState.instance.isAdmin) GlassItemCard(icon: Icons.admin_panel_settings_outlined, overline: 'Admin', title: 'Admin', pill: 'Words, quotes, editor', onTap: () => openAdminHome(context)),
        GlassItemCard(icon: Icons.info_outline_rounded, overline: 'About', title: 'About NowssB', pill: 'Version 9.5.0', pillSub: 'nowssb.com', onTap: () { _openAbout(); }),
        GlassItemCard(icon: Icons.privacy_tip_outlined, overline: 'Legal', title: 'Privacy Policy', pill: 'What NowssB keeps', pillSub: 'nowssb.com/privacy', onTap: () => _openUrl('https://nowssb.com/privacy')),
        GlassItemCard(icon: Icons.description_outlined, overline: 'Legal', title: 'Terms of Service', pill: 'Read terms', pillSub: 'nowssb.com/terms', onTap: () => _openUrl('https://nowssb.com/terms')),
        GlassItemCard(icon: Icons.logout_rounded, overline: 'Session', title: 'Sign Out', pill: 'End this session', danger: true, onTap: _signOut),
        GlassItemCard(icon: Icons.delete_outline_rounded, overline: 'Account', title: 'Delete Account', pill: 'Erase this account', pillSub: 'Cannot be undone', danger: true, onTap: _deleteAccount),
      ],
    ];
  }

  Widget _settingsFace(Settings s) {
    final groups = _groups(s);
    const names = ['Look and sound', 'This phone', 'Account'];
    final searching = _q.isNotEmpty;
    final cards = searching
        ? [for (final g in groups) ...g.where((c) => _match('${c.overline} ${c.title}', '${c.pill} ${c.pillSub ?? ''}'))]
        : groups[_set.clamp(0, 2)];
    final settingIds = {for (final g in groups) for (final c in g) c.title.toLowerCase()};
    final pages = searching
        ? [...menuDestinations, ...settingsDestinations]
            .where((d) => d.id != 'settings' && !settingIds.contains(d.title.toLowerCase()) && d.matches(_q))
            .toList()
        : const <AppDest>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSearchField(controller: _search, hint: 'Search settings and pages'),
        const SizedBox(height: 14),
        if (!searching) ...[
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xB30B0B10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Row(
              children: [
                for (var i = 0; i < names.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _set = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == _set ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          names[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: i == _set ? const Color(0xFF0B0B10) : Colors.white,
                            fontSize: 13,
                            fontWeight: i == _set ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (searching && cards.isEmpty && pages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Nothing called "${_search.text.trim()}" in NowssB.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0x99FFFFFF))),
          ),
        ...cards,
        for (final d in pages)
          GlassItemCard(
            icon: d.icon,
            overline: d.overline,
            title: d.title,
            pill: d.pill,
            pillSub: d.sub,
            onTap: () => openDest(context, d),
          ),
      ],
    );
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
      film: 'assets/video/subscription-bg.mp4',
      usePageFilm: true,
      quietFilm: true,
      onBack: () => Navigator.of(context).maybePop(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 40 + bottom),
          sliver: SliverList.list(
            // Server-driven order (Admin → UI Editor); bundled order by default.
            children: layoutChildren(context, 'settings', [
              LSection('face', 'Settings face', _settingsFace(s)),
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
              _openWebsite();
            },
            child: const EditableLabel(
                'app_settings.AppSettingsScreen', 'Website'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWebsite() async {
    await _openUrl('https://nowssb.com');
  }

  Future<void> _openUrl(String url) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
