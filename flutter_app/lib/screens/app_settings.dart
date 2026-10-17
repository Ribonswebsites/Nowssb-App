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

  Widget _settingsFace(Settings s) {
    final groups = <List<WorkCard>>[
      [
        WorkCard(category: 'Player', title: 'Player Guide', meta: 'Replay the setup', action: 'Open the guide', image: 'assets/rails/02.png', onTap: () { OnboardingWarmup.playerGuide(context, firstOnly: true); _push(PlayerGuideScreen(onDone: () => Navigator.of(context).maybePop())); }),
        WorkCard(category: 'Look', title: 'Hero header', meta: 'TV, full, plain, shortcuts', action: 'Open widgets', image: 'assets/rails/03.png', onTap: () => _push(const WidgetsPage())),
        WorkCard(category: 'Look', title: 'Fashion Plus', meta: s.fashionPlus ? 'Motion on' : 'Still backgrounds', action: 'Open Fashion Plus', image: 'assets/rails/04.png', onTap: () => _push(const FashionPlusScreen())),
        WorkCard(category: 'Nav', title: 'Quick Access', meta: 'Bottom navigation', action: 'Customize', image: 'assets/rails/05.png', onTap: () => _push(const QuickAccessScreen())),
        WorkCard(category: 'Alerts', title: 'Notifications', meta: 'Daily words and streak', action: 'Open alerts', image: 'assets/rails/06.png', onTap: () => _push(const NotificationsSettingsPage())),
        WorkCard(category: 'Player', title: 'Player Settings', meta: 'Equalizer, quality, sleep', action: 'Open player', image: 'assets/rails/07.png', onTap: () => _push(const PlayerSettingsScreen())),
        WorkCard(category: 'Words', title: "Today's quote", meta: s.todayQuote.trim().isEmpty ? 'Quotes to live by' : s.todayQuote.trim(), action: 'Open quotes', image: 'assets/rails/08.png', onTap: () => _push(const QuotesWeekScreen())),
      ],
      [
        WorkCard(category: 'Screen', title: 'Keep Screen Awake', meta: _screenWake ? 'Stays on' : 'Can sleep', action: _screenWake ? 'Turn off' : 'Turn on', image: 'assets/rails/01.png', onTap: () { final v = !_screenWake; setState(() => _screenWake = v); _saveBool('ss_screen_wake', v); DeviceFlags.keepAwake(v); }),
        WorkCard(category: 'Nav', title: 'Nav Bar', meta: s.navColor == 'glass' ? 'Glass' : 'Black', action: 'Switch', image: 'assets/rails/09.png', onTap: _cycleNav),
        WorkCard(category: 'You', title: 'Your profile', meta: 'Account, plan, edit', action: 'Open profile', image: 'assets/rails/10.png', onTap: () => NavScope.goTo(context, 4)),
        WorkCard(category: 'Discover', title: 'Appear in Discover', meta: _appearDiscover ? 'Others can find you' : 'Hidden', action: _appearDiscover ? 'Hide' : 'Show', image: 'assets/rails/11.png', onTap: () => _setDiscover(!_appearDiscover)),
      ],
      [
        WorkCard(category: 'Privacy', title: 'Privacy Policy', meta: 'What NowssB keeps', action: 'Read', image: 'assets/rails/02.png', onTap: () => _openUrl('https://nowssb.com/privacy')),
        WorkCard(category: 'Account', title: 'Delete Account', meta: 'Erase this account', action: 'Delete', image: 'assets/rails/03.png', onTap: _deleteAccount),
        WorkCard(category: 'Cache', title: 'Cached Data', meta: 'Temporary media', action: 'Clear cache', image: 'assets/rails/04.png', onTap: () { _clearCache(); }),
        WorkCard(category: 'History', title: 'Clear Practice History', meta: 'Session logs', action: 'Clear history', image: 'assets/rails/05.png', onTap: () { _confirmClearHistory(); }),
        WorkCard(category: 'Words', title: 'Request Words', meta: 'Ask the atelier', action: 'Request', image: 'assets/rails/06.png', onTap: () => openRequestWords(context)),
        if (AdminState.instance.isAdmin) WorkCard(category: 'Admin', title: 'Admin', meta: 'Words, quotes, editor', action: 'Open admin', image: 'assets/rails/07.png', onTap: () => openAdminHome(context)),
        WorkCard(category: 'About', title: 'About NowssB', meta: 'v9.5.0', action: 'About', image: 'assets/rails/08.png', onTap: () { _openAbout(); }),
        WorkCard(category: 'Terms', title: 'Terms of Service', meta: 'nowssb.com/terms', action: 'Read terms', image: 'assets/rails/09.png', onTap: () => _openUrl('https://nowssb.com/terms')),
        WorkCard(category: 'Session', title: 'Sign Out', meta: 'End this session', action: 'Sign out', image: 'assets/rails/10.png', onTap: _signOut),
      ],
    ];
    final names = ['Look', 'Phone', 'Account'];
    final cards = groups[_set.clamp(0, 2)].where((c) => _match(c.title, c.meta)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => NavScope.goTo(context, 4),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF2A2038),
                child: Icon(Icons.settings, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0x33110A18),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x33FFFFFF)),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < names.length; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _set = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == _set ? const Color(0xCC2A2038) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              names[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: i == _set ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (cards.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Nothing in this filter.', textAlign: TextAlign.center, style: TextStyle(color: Color(0x99FFFFFF))),
          )
        else
          for (final card in cards) ...[
            GestureDetector(
              onTap: card.onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xF0101016), borderRadius: BorderRadius.circular(22)),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: Image.asset(card.image ?? 'assets/rails/02.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(card.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.1)),
                          const SizedBox(height: 6),
                          Text(card.meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(color: Color(0xFF2A2A32), shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
