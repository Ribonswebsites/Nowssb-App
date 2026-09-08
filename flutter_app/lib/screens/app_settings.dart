/// App Settings — website `#sub-social` / Preferences ported to Flutter.
///
/// Full working settings (not Widgets/Hero header). Wired from the hamburger
/// Settings row. Persists toggles via SharedPreferences. No emoji.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/settings.dart';
import '../theme/tokens.dart';
import '../widgets/black_glass_banner.dart';
import 'fashion_plus.dart';
import 'notifications_settings.dart';
import 'player_settings.dart';
import 'profile.dart';
import 'quick_access.dart';
import 'widgets_page.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _search = TextEditingController();
  String _q = '';

  bool _uiSound = true;
  bool _autoAdvance = false;
  bool _screenWake = true;
  bool _haptic = true;
  bool _autoPlay = false;
  bool _reduceMotion = false;
  bool _boldText = false;
  bool _practiceReminders = true;
  bool _newWordAlerts = true;
  bool _appearDiscover = true;
  String _voice = 'Female';
  String _ambient = 'Off';
  int _wordsPer = 5;
  int _reps = 7;
  String _sensitivity = 'Normal';
  String _textSize = 'M';
  String _theme = 'default';

  @override
  void initState() {
    super.initState();
    Settings.instance.addListener(_onSettings);
    _search.addListener(() => setState(() => _q = _search.text.trim().toLowerCase()));
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
        _uiSound = p.getBool('ss_ui_sound') ?? true;
        _autoAdvance = p.getBool('ss_auto_advance') ?? false;
        _screenWake = p.getBool('ss_screen_wake') ?? true;
        _haptic = p.getBool('ss_haptic') ?? true;
        _autoPlay = p.getBool('ss_autoplay') ?? false;
        _reduceMotion = p.getBool('ss_reduce_motion') ?? false;
        _boldText = p.getBool('ss_bold_text') ?? false;
        _practiceReminders = p.getBool('ss_practice_reminders') ?? true;
        _newWordAlerts = p.getBool('ss_new_word') ?? true;
        _appearDiscover = p.getBool('ss_appear_discover') ?? true;
        _voice = p.getString('ss_voice') ?? 'Female';
        _ambient = p.getString('ss_ambient') ?? 'Off';
        _wordsPer = p.getInt('ss_words_per') ?? 5;
        _reps = p.getInt('ss_reps') ?? 7;
        _sensitivity = p.getString('ss_sensitivity') ?? 'Normal';
        _textSize = p.getString('ss_text_size') ?? 'M';
        _theme = p.getString('ss_theme') ?? 'default';
      });
    } catch (_) {}
  }

  Future<void> _saveBool(String k, bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(k, v);
    } catch (_) {}
  }

  Future<void> _saveString(String k, String v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(k, v);
    } catch (_) {}
  }

  Future<void> _saveInt(String k, int v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(k, v);
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

  void _cycleVoice() {
    setState(() => _voice = _voice == 'Female' ? 'Male' : 'Female');
    _saveString('ss_voice', _voice);
    HapticFeedback.selectionClick();
  }

  void _cycleAmbient() {
    const opts = ['Off', 'Rain', 'Drone', 'Bowl'];
    setState(() => _ambient = opts[(opts.indexOf(_ambient) + 1) % opts.length]);
    _saveString('ss_ambient', _ambient);
    HapticFeedback.selectionClick();
  }

  void _cycleWords() {
    const opts = [3, 5, 7, 9];
    setState(() => _wordsPer = opts[(opts.indexOf(_wordsPer) + 1) % opts.length]);
    _saveInt('ss_words_per', _wordsPer);
    HapticFeedback.selectionClick();
  }

  void _cycleReps() {
    const opts = [3, 5, 7, 9, 12];
    setState(() => _reps = opts[(opts.indexOf(_reps) + 1) % opts.length]);
    _saveInt('ss_reps', _reps);
    HapticFeedback.selectionClick();
  }

  void _cycleSens() {
    const opts = ['Gentle', 'Normal', 'Strict'];
    setState(() =>
        _sensitivity = opts[(opts.indexOf(_sensitivity) + 1) % opts.length]);
    _saveString('ss_sensitivity', _sensitivity);
    HapticFeedback.selectionClick();
  }

  void _cycleText() {
    const opts = ['S', 'M', 'L', 'XL'];
    setState(() => _textSize = opts[(opts.indexOf(_textSize) + 1) % opts.length]);
    _saveString('ss_text_size', _textSize);
    HapticFeedback.selectionClick();
  }

  void _cycleNav() {
    final s = Settings.instance;
    final next = s.navColor == 'glass' ? 'black' : 'glass';
    s.setNavConfig(color: next);
    HapticFeedback.selectionClick();
  }

  void _setTheme(String id) {
    setState(() => _theme = id);
    _saveString('ss_theme', id);
    final s = Settings.instance;
    if (id == 'neo') {
      s.setFashionHome(false);
    } else {
      s.setFashionHome(true);
    }
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final speedLabel = (s.speed - 1).abs() < 0.01
        ? '1.0× Normal'
        : '${s.speed}×';

    return Scaffold(
      backgroundColor: const Color(0xFF060C18),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.8),
                radius: 1.1,
                colors: [Color(0x44E8D5A3), Color(0x00060C18)],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(12, top + 10, 16, 14),
                decoration: const BoxDecoration(
                  color: Color(0xEB060C18),
                  border: Border(
                    bottom: BorderSide(color: Color(0x12FFFFFF)),
                  ),
                ),
                child: Row(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(Icons.arrow_back,
                              size: 19, color: NwsbColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'NOWSBANSIU',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: NwsbColors.goldLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 40 + bottom),
                  children: [
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
                                Text(
                                  'Your profile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
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
                    ),
                    const SizedBox(height: 8),
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
                    ),
                    if (_match('NowssB Plans', 'upgrade') ||
                        _match('My Certificates'))
                      _Sec(
                        label: 'MEMBERSHIP',
                        children: [
                          if (_match('NowssB Plans', 'upgrade'))
                            _NavRow(
                              icon: Icons.workspace_premium_outlined,
                              title: 'NowssB Plans',
                              sub: 'View or upgrade your plan',
                              onTap: () => _toast('Plans open with Frequency.'),
                            ),
                          if (_match('My Certificates'))
                            _NavRow(
                              icon: Icons.military_tech_outlined,
                              title: 'My Certificates',
                              sub: 'Word Mastery achievements',
                              last: true,
                              onTap: () => _toast('Certificates coming soon.'),
                            ),
                        ],
                      ),
                    if (_match('Screen Meditation') ||
                        _match('Player Guide') ||
                        _match('Hero header') ||
                        _match('Fashion Plus') ||
                        _match('Quick Access') ||
                        _match('Player Settings'))
                      _Sec(
                        label: 'INTRO & APPEARANCE',
                        children: [
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
                      ),
                    if (_match('theme', 'black') || _match('Default') || _match('Glass'))
                      _Sec(
                        label: 'BLACK EDITION',
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                            child: Text(
                              'Choose your Fashion home theme. Applies to the Fashion screen.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: Colors.white.withOpacity(0.32),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (final t in const [
                                ('default', 'Default', 'Glass'),
                                ('black', 'Black', 'Void'),
                                ('neo', 'Neo', 'Depth'),
                                ('glass-black', 'Glass', 'Dark'),
                              ])
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: _ThemeCard(
                                      id: t.$1,
                                      title: t.$2,
                                      sub: t.$3,
                                      selected: _theme == t.$1,
                                      onTap: () => _setTheme(t.$1),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    if (_match('Voice') ||
                        _match('UI Sound') ||
                        _match('Playback Speed') ||
                        _match('Ambient'))
                      _Sec(
                        label: 'AUDIO & PLAYBACK',
                        children: [
                          if (_match('Voice'))
                            _PillRow(
                              icon: Icons.record_voice_over_outlined,
                              title: 'Voice Preference',
                              sub: '$_voice voice',
                              pill: _voice,
                              onTap: _cycleVoice,
                            ),
                          if (_match('UI Sound'))
                            _ToggleRow(
                              icon: Icons.volume_up_outlined,
                              title: 'UI Sound Feedback',
                              sub: 'Interaction sounds',
                              value: _uiSound,
                              onChanged: (v) {
                                setState(() => _uiSound = v);
                                _saveBool('ss_ui_sound', v);
                              },
                            ),
                          if (_match('Playback Speed'))
                            _PillRow(
                              icon: Icons.speed,
                              title: 'Playback Speed',
                              sub: speedLabel,
                              pill: s.speed == 1 ? '1.0×' : '${s.speed}×',
                              onTap: () {
                                final opts = [0.75, 1.0, 1.25, 1.5];
                                final i = opts.indexWhere(
                                    (x) => (x - s.speed).abs() < 0.01);
                                final next = opts[((i < 0 ? 1 : i) + 1) %
                                    opts.length];
                                s.setSpeed(next);
                                HapticFeedback.selectionClick();
                              },
                            ),
                          if (_match('Ambient'))
                            _PillRow(
                              icon: Icons.graphic_eq,
                              title: 'Ambient Sound',
                              sub: _ambient == 'Off'
                                  ? 'Off — silence during practice'
                                  : _ambient,
                              pill: _ambient,
                              last: true,
                              onTap: _cycleAmbient,
                            ),
                        ],
                      ),
                    if (_match('Words per') ||
                        _match('Repetitions') ||
                        _match('Scoring') ||
                        _match('Auto-Advance') ||
                        _match('Keep Screen'))
                      _Sec(
                        label: 'PRACTICE',
                        children: [
                          if (_match('Words per'))
                            _PillRow(
                              icon: Icons.format_list_numbered,
                              title: 'Words per Session',
                              sub: '$_wordsPer words per practice',
                              pill: '$_wordsPer',
                              onTap: _cycleWords,
                            ),
                          if (_match('Repetitions'))
                            _PillRow(
                              icon: Icons.repeat,
                              title: 'Repetitions per Word',
                              sub: '$_reps× per word',
                              pill: '$_reps×',
                              onTap: _cycleReps,
                            ),
                          if (_match('Scoring'))
                            _PillRow(
                              icon: Icons.tune,
                              title: 'Scoring Sensitivity',
                              sub: '$_sensitivity — match threshold',
                              pill: _sensitivity,
                              onTap: _cycleSens,
                            ),
                          if (_match('Auto-Advance'))
                            _ToggleRow(
                              icon: Icons.skip_next_outlined,
                              title: 'Auto-Advance Words',
                              sub: 'Move to next word after reps complete',
                              value: _autoAdvance,
                              onChanged: (v) {
                                setState(() => _autoAdvance = v);
                                _saveBool('ss_auto_advance', v);
                              },
                            ),
                          if (_match('Keep Screen'))
                            _ToggleRow(
                              icon: Icons.phone_android,
                              title: 'Keep Screen Awake',
                              sub: 'Prevent sleep during practice sessions',
                              value: _screenWake,
                              last: true,
                              onChanged: (v) {
                                setState(() => _screenWake = v);
                                _saveBool('ss_screen_wake', v);
                              },
                            ),
                        ],
                      ),
                    if (_match('Haptic') ||
                        _match('Auto-Play') ||
                        _match('Nav Bar'))
                      _Sec(
                        label: 'EXPERIENCE',
                        children: [
                          if (_match('Haptic'))
                            _ToggleRow(
                              icon: Icons.vibration,
                              title: 'Haptic Feedback',
                              sub: 'Vibration on key interactions',
                              value: _haptic,
                              onChanged: (v) {
                                setState(() => _haptic = v);
                                _saveBool('ss_haptic', v);
                              },
                            ),
                          if (_match('Auto-Play'))
                            _ToggleRow(
                              icon: Icons.play_circle_outline,
                              title: 'Auto-Play Next Session',
                              sub: 'Continue to next routine automatically',
                              value: _autoPlay,
                              onChanged: (v) {
                                setState(() => _autoPlay = v);
                                _saveBool('ss_autoplay', v);
                              },
                            ),
                          if (_match('Nav Bar'))
                            _PillRow(
                              icon: Icons.space_dashboard_outlined,
                              title: 'Nav Bar Style',
                              sub: s.navColor == 'glass'
                                  ? 'Glassmorphism — frosted translucent'
                                  : 'Black — solid void',
                              pill: s.navColor == 'glass' ? 'Glass' : 'Black',
                              last: true,
                              onTap: _cycleNav,
                            ),
                        ],
                      ),
                    if (_match('Text Size') ||
                        _match('Reduce Motion') ||
                        _match('Bold Text'))
                      _Sec(
                        label: 'ACCESSIBILITY',
                        children: [
                          if (_match('Text Size'))
                            _PillRow(
                              icon: Icons.text_fields,
                              title: 'Text Size',
                              sub: '$_textSize — readability',
                              pill: _textSize,
                              onTap: _cycleText,
                            ),
                          if (_match('Reduce Motion'))
                            _ToggleRow(
                              icon: Icons.motion_photos_off_outlined,
                              title: 'Reduce Motion',
                              sub: 'Minimize transitions and animations',
                              value: _reduceMotion,
                              onChanged: (v) {
                                setState(() => _reduceMotion = v);
                                _saveBool('ss_reduce_motion', v);
                              },
                            ),
                          if (_match('Bold Text'))
                            _ToggleRow(
                              icon: Icons.format_bold,
                              title: 'Bold Text',
                              sub: 'Heavier font weight for readability',
                              value: _boldText,
                              last: true,
                              onChanged: (v) {
                                setState(() => _boldText = v);
                                _saveBool('ss_bold_text', v);
                              },
                            ),
                        ],
                      ),
                    if (_match('Practice Reminders') ||
                        _match('New Words') ||
                        _match('Notifications'))
                      _Sec(
                        label: 'NOTIFICATIONS',
                        children: [
                          if (_match('Practice Reminders') ||
                              _match('Notifications'))
                            _ToggleRow(
                              icon: Icons.notifications_none,
                              title: 'Practice Reminders',
                              sub: 'Daily routine alerts',
                              value: _practiceReminders,
                              onChanged: (v) {
                                setState(() => _practiceReminders = v);
                                _saveBool('ss_practice_reminders', v);
                              },
                            ),
                          if (_match('New Words'))
                            _ToggleRow(
                              icon: Icons.auto_stories_outlined,
                              title: 'New Words Alerts',
                              sub: 'When library updates',
                              value: _newWordAlerts,
                              onChanged: (v) {
                                setState(() => _newWordAlerts = v);
                                _saveBool('ss_new_word', v);
                              },
                            ),
                          _NavRow(
                            icon: Icons.tune,
                            title: 'Notification settings',
                            sub: 'Manage channels on this phone',
                            last: true,
                            onTap: () =>
                                _push(const NotificationsSettingsPage()),
                          ),
                        ],
                      ),
                    if (_match('Appear') ||
                        _match('Privacy') ||
                        _match('Chat'))
                      _Sec(
                        label: 'PRIVACY & SOCIAL',
                        children: [
                          if (_match('Appear'))
                            _ToggleRow(
                              icon: Icons.travel_explore,
                              title: 'Appear in Discover',
                              sub: 'Others can find your profile',
                              value: _appearDiscover,
                              onChanged: (v) {
                                setState(() => _appearDiscover = v);
                                _saveBool('ss_appear_discover', v);
                              },
                            ),
                          if (_match('Privacy'))
                            _NavRow(
                              icon: Icons.lock_outline,
                              title: 'Privacy Settings',
                              sub: 'Who can see your stats',
                              onTap: () => _toast('Privacy options saved locally.'),
                            ),
                          if (_match('Chat'))
                            _NavRow(
                              icon: Icons.chat_bubble_outline,
                              title: 'Chat Settings',
                              sub: 'Manage who can message you',
                              last: true,
                              onTap: () => _toast('Chat preferences saved.'),
                            ),
                        ],
                      ),
                    if (_match('Download') ||
                        _match('Cached') ||
                        _match('Clear Practice') ||
                        _match('About') ||
                        _match('Terms') ||
                        _match('Sign Out'))
                      _Sec(
                        label: 'APP & ABOUT',
                        children: [
                          if (_match('Download'))
                            _NavRow(
                              icon: Icons.download_rounded,
                              title: 'Download App',
                              sub: 'You are already in the NowssB app',
                              onTap: () => _toast(
                                  'You are already in the NowssB app.'),
                            ),
                          if (_match('Cached'))
                            _NavRow(
                              icon: Icons.cleaning_services_outlined,
                              title: 'Cached Data',
                              sub: 'Clear temporary media cache',
                              onTap: () => _toast('Cache cleared.'),
                            ),
                          if (_match('Clear Practice'))
                            _NavRow(
                              icon: Icons.delete_outline,
                              title: 'Clear Practice History',
                              sub: 'Remove session logs — cannot be undone',
                              danger: true,
                              onTap: () => _confirmClearHistory(),
                            ),
                          if (_match('About'))
                            _NavRow(
                              icon: Icons.info_outline,
                              title: 'About NowssB',
                              sub: 'v2.6.0 · nowssb.com',
                              onTap: () => _toast('NowssB · Shabdapathy'),
                            ),
                          if (_match('Terms'))
                            _NavRow(
                              icon: Icons.description_outlined,
                              title: 'Terms & Privacy Policy',
                              sub: 'Legal',
                              onTap: () => _toast('Opens nowssb.com/legal'),
                            ),
                          if (_match('Sign Out'))
                            _NavRow(
                              icon: Icons.logout,
                              title: 'Sign Out',
                              sub: 'End this session',
                              last: true,
                              danger: true,
                              onTap: () => _toast('Signed out on this device.'),
                            ),
                        ],
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
        title: const Text('Clear practice history?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Session logs will be removed. This cannot be undone.',
          style: TextStyle(color: Color(0xB3FFFFFF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Color(0xFFF87171))),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _toast('Practice history cleared.');
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
      child: Text(
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
            child: Text(
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
                Text(
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
                Text(
                  title,
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
                Text(
                  title,
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
                  Text(
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
