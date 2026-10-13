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
import 'widgets_page.dart';
import '../admin/template/editable.dart';
import '../pages/menu_settings/glass_menu_settings_page.dart';
import '../pages/menu_settings/menu_settings_model.dart';
import '../pages/menu_settings/newui_flag.dart';

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
  int _tab = 0;

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

  List<SettingSection> _newUiSections(bool isAdmin) => [
        SettingSection('Your app', [
          SettingItem(id: 'notifications', title: 'Notifications', icon: Icons.notifications_none_rounded, onTap: () => _push(const NotificationsSettingsPage())),
          SettingItem(id: 'player', title: 'Player', icon: Icons.tune_rounded, onTap: () => _push(const PlayerSettingsScreen())),
          SettingItem(id: 'quick_access', title: 'Quick access', icon: Icons.dashboard_customize_outlined, onTap: () => _push(const QuickAccessScreen())),
          SettingItem(id: 'hero', title: 'Hero header', icon: Icons.view_agenda_outlined, onTap: () => _push(const WidgetsPage())),
          SettingItem(id: 'fashion_plus', title: 'Fashion Plus', icon: Icons.auto_awesome_outlined, onTap: () => _push(const FashionPlusScreen())),
          SettingItem(id: 'quote', title: "Today's quote", icon: Icons.format_quote_rounded, onTap: () => _push(const QuotesWeekScreen())),
        ]),
        SettingSection('Comfort', [
          SettingItem(id: 'screen_awake', title: 'Screen awake', icon: Icons.light_mode_outlined, kind: SettingKind.toggle, value: _screenWake, onChanged: (v) => _setWake(v)),
          SettingItem(id: 'nav', title: 'Nav bar', subtitle: Settings.instance.navColor, icon: Icons.space_dashboard_outlined, onTap: _cycleNav),
          SettingItem(id: 'discover', title: 'Appear in Discover', icon: Icons.travel_explore, kind: SettingKind.toggle, value: _appearDiscover, onChanged: (v) => _setDiscover(v)),
        ]),
        SettingSection('Data', [
          SettingItem(id: 'request_words', title: 'Request words', icon: Icons.edit_note_outlined, onTap: () => openRequestWords(context)),
          SettingItem(id: 'clear_cache', title: 'Clear cache', icon: Icons.cleaning_services_outlined, onTap: _clearCache),
          SettingItem(id: 'clear_history', title: 'Clear history', icon: Icons.history_toggle_off_rounded, destructive: true, onTap: () => _confirmClearHistory()),
        ]),
        if (isAdmin)
          SettingSection('Admin', [
            SettingItem(id: 'admin', title: 'Admin', icon: Icons.admin_panel_settings_outlined, onTap: () => openAdminHome(context)),
          ]),
        SettingSection('About', [
          SettingItem(id: 'privacy', title: 'Privacy', icon: Icons.lock_outline, onTap: () => _openUrl('https://nowssb.com/privacy')),
          SettingItem(id: 'terms', title: 'Terms', icon: Icons.description_outlined, onTap: () => _openUrl('https://nowssb.com/terms')),
          SettingItem(id: 'about', title: 'About', icon: Icons.info_outline, onTap: _openAbout),
        ]),
        SettingSection('Account', [
          SettingItem(id: 'sign_out', title: 'Sign out', icon: Icons.logout_rounded, onTap: _signOut),
          SettingItem(id: 'delete_account', title: 'Delete account', icon: Icons.person_remove_outlined, destructive: true, onTap: _deleteAccount),
        ]),
      ];

  @override
  Widget build(BuildContext context) {
    UiScope.watch(context); // the Admin row follows the admin flag live
    final s = Settings.instance;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final isAdmin = AdminState.instance.isAdmin;

    // newui_menu_settings: rebuilt glass page (admins ON, users OFF).
    if (NewUiMenuSettingsFlag.isOn) {
      return GlassMenuSettingsPage(
        load: () async => _newUiSections(isAdmin),
        displayName: FirebaseAuth.instance.currentUser?.displayName,
      );
    }

    // v4 (Ribon 8:22 PM): CLiQ Perks layout (member hero, one profile
    // action, two underlined tabs, rows) in NowssB's original colours, glass
    // and film. Titles only. Every setting,
    // toggle and route from before is kept.
    final mine = <Widget>[
      if (_match('Notifications'))
        _Row(icon: Icons.notifications_none_rounded, title: 'Notifications', onTap: () => _push(const NotificationsSettingsPage())),
      if (_match('Player Settings'))
        _Row(icon: Icons.tune_rounded, title: 'Player', onTap: () => _push(const PlayerSettingsScreen())),
      if (_match('Quick Access'))
        _Row(icon: Icons.dashboard_customize_outlined, title: 'Quick access', onTap: () => _push(const QuickAccessScreen())),
      if (_match('Player Guide'))
        _Row(icon: Icons.menu_book_outlined, title: 'Player Guide', onTap: () {
          // Decode the opening slide and orb badges during the transition.
          OnboardingWarmup.playerGuide(context, firstOnly: true);
          _push(PlayerGuideScreen(onDone: () => Navigator.of(context).maybePop()));
        }),
      if (_match('Hero header'))
        _Row(icon: Icons.view_agenda_outlined, title: 'Hero header', onTap: () => _push(const WidgetsPage())),
      if (_match('Fashion Plus'))
        _Row(icon: Icons.auto_awesome_outlined, title: 'Fashion Plus', onTap: () => _push(const FashionPlusScreen())),
      if (_match('Today\'s quote'))
        _Row(icon: Icons.format_quote_rounded, title: 'Today\'s quote', onTap: () => _push(const QuotesWeekScreen())),
      if (_match('Screen'))
        _Row(icon: Icons.light_mode_outlined, title: 'Screen awake',
            onTap: () => _setWake(!_screenWake),
            trailing: _Toggle(on: _screenWake, onTap: () => _setWake(!_screenWake))),
      if (_match('Nav'))
        _Row(icon: Icons.space_dashboard_outlined, title: 'Nav bar',
            onTap: _cycleNav,
            trailing: _Chip(s.navColor == 'glass' ? 'Glass' : 'Black')),
    ];
    final account = <Widget>[
      if (_match('Appear'))
        _Row(icon: Icons.travel_explore, title: 'Appear in Discover',
            onTap: () => _setDiscover(!_appearDiscover),
            trailing: _Toggle(on: _appearDiscover, onTap: () => _setDiscover(!_appearDiscover))),
      if (_match('Request') || _match('Word'))
        _Row(icon: Icons.edit_note_outlined, title: 'Request words', onTap: () => openRequestWords(context)),
      if (_match('Cached'))
        _Row(icon: Icons.cleaning_services_outlined, title: 'Clear cache', onTap: _clearCache),
      if (_match('Clear Practice') || _match('history'))
        _Row(icon: Icons.history_toggle_off_rounded, title: 'Clear history', onTap: () => _confirmClearHistory(), danger: true),
      // Only for an account the server marks as admin (admins/{uid}).
      if (isAdmin && (_match('Admin') || _match('Template') || _match('Edit')))
        _Row(icon: Icons.admin_panel_settings_outlined, title: 'Admin', onTap: () => openAdminHome(context)),
      if (_match('Privacy'))
        _Row(icon: Icons.lock_outline, title: 'Privacy', onTap: () => _openUrl('https://nowssb.com/privacy')),
      if (_match('Terms'))
        _Row(icon: Icons.description_outlined, title: 'Terms', onTap: () => _openUrl('https://nowssb.com/terms')),
      if (_match('About'))
        _Row(icon: Icons.info_outline, title: 'About', onTap: _openAbout),
      if (_match('Sign Out'))
        _Row(icon: Icons.logout_rounded, title: 'Sign out', onTap: _signOut),
      if (_match('Delete'))
        _Row(icon: Icons.person_remove_outlined, title: 'Delete account', onTap: _deleteAccount, danger: true),
    ];
    final rows = _q.isNotEmpty ? [...mine, ...account] : (_tab == 0 ? mine : account);

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
              // Profile is a bottom-nav root: switch tab, don't push.
              LSection('profile', 'Member card', _MemberHero(onProfile: () => NavScope.goTo(context, 4))),
              const SizedBox(height: 18),
              LSection('tabs', 'Tabs', _Tabs(
                index: _tab,
                labels: const ['YOUR SETTINGS', 'ACCOUNT'],
                onTap: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _tab = i);
                },
              )),
              const SizedBox(height: 14),
              LSection('search', 'Search settings', _SearchField(controller: _search)),
              const SizedBox(height: 14),
              LSection('rows', 'Settings', AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: rows.isEmpty
                    ? const SizedBox(key: ValueKey('none'), height: 1)
                    : HeavyGlassPanel(
                        key: ValueKey('$_tab$_q'),
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                        radius: 22,
                        child: Column(children: rows),
                      ),
              )),
            ]),
          ),
        ),
      ],
    );
  }

  void _setWake(bool v) {
    HapticFeedback.selectionClick();
    setState(() => _screenWake = v);
    _saveBool('ss_screen_wake', v);
    DeviceFlags.keepAwake(v);
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

const _gold = NwsbColors.goldLight;

/// CLiQ-style member hero in NowssB's own look: a frosted glass card over
/// the page film, greeting, plan, the original gold-ringed avatar, and the
/// page's single profile action.
class _MemberHero extends StatelessWidget {
  const _MemberHero({required this.onProfile});
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    String first = '';
    try {
      final n = FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
      if (n.isNotEmpty) first = n.split(' ').first;
    } catch (_) {}
    return HeavyGlassPanel(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      radius: 26,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0x22E8D5A3), Color(0x1CC8E8F5)]),
              border: Border.all(color: const Color(0x40E8D5A3), width: 2),
            ),
            child: const Icon(Icons.person_outline, color: NwsbColors.gold, size: 30),
          ),
          const SizedBox(height: 14),
          Text(first.isEmpty ? 'Hello' : 'Hello $first',
              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 14)),
          const SizedBox(height: 4),
          ListenableBuilder(
            listenable: EconomyMirror.instance,
            builder: (context, _) {
              final plan = EconomyMirror.instance.plan.trim();
              return Text("You're a ${plan.isEmpty ? 'FREE' : plan.toUpperCase()} member",
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700));
            },
          ),
          const SizedBox(height: 20),
          NestedDarkWrap(
            margin: EdgeInsets.zero,
            radius: 999,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            onTap: onProfile,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Open profile',
                    style: TextStyle(color: _gold, fontSize: 14.5, fontWeight: FontWeight.w700)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: _gold, size: 17),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.index, required this.labels, required this.onTap});
  final int index;
  final List<String> labels;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x24FFFFFF)))),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(labels[i],
                          style: TextStyle(
                            color: i == index ? Colors.white : const Color(0x73FFFFFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          )),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      height: 2,
                      color: i == index ? NwsbColors.gold : const Color(0x00000000),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    // Same field as the original Settings search.
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Color(0x59FFFFFF)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
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
    );
  }
}

/// A title-only row in the original nested dark wrap, with its own icon.
class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.onTap, this.trailing, this.danger = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xD9F87171);
    return NestedDarkWrap(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: danger ? red : NwsbColors.gold),
          const SizedBox(width: 14),
          Expanded(
            child: EditableLabel('app_settings.Row', title,
                style: TextStyle(color: danger ? red : Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
          ),
          trailing ??
              Icon(Icons.chevron_right, size: 16, color: danger ? const Color(0x80F87171) : const Color(0x55FFFFFF)),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: on,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: 46,
          height: 26,
          padding: const EdgeInsets.all(2),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: on ? const Color(0xE6E8D5A3) : const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? const Color(0xF2E8D5A3) : const Color(0x29FFFFFF)),
          ),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    // The original Nav Bar pill.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1AE8D5A3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x4DE8D5A3)),
      ),
      child: Text(label, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 12, fontWeight: FontWeight.w700)),
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


