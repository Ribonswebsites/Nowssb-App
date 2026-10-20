/// Rebuilt Settings: four sections, every row works. Editing toggles (hero
/// header layout, quick-access layout) were removed per Ribon.
library;

import 'package:flutter/material.dart';

import 'ms_glass.dart';
import 'ms_guide.dart';

/// Everything Settings can do; wired by AppSettingsScreen, faked in tests.
class MsSettingsActions {
  const MsSettingsActions({
    required this.openPlayer,
    required this.openNotifications,
    required this.screenAwake,
    required this.setScreenAwake,
    required this.motionBackground,
    required this.setMotionBackground,
    required this.navGlass,
    required this.setNavGlass,
    required this.openBackgroundPicker,
    required this.appearInDiscover,
    required this.setAppearInDiscover,
    required this.openProfile,
    required this.openPrivacy,
    required this.openTerms,
    required this.signOut,
    required this.deleteAccount,
    required this.clearCache,
    required this.clearHistory,
    required this.openPlayerGuide,
    required this.requestWords,
    required this.openAbout,
    this.isAdmin = false,
    this.openAdmin,
    this.version = '',
  });
  final VoidCallback openPlayer, openNotifications, openBackgroundPicker, openProfile,
      openPrivacy, openTerms, signOut, deleteAccount, clearCache, clearHistory,
      openPlayerGuide, requestWords, openAbout;
  final bool Function() screenAwake, motionBackground, navGlass, appearInDiscover;
  final ValueChanged<bool> setScreenAwake, setMotionBackground, setNavGlass, setAppearInDiscover;
  final bool isAdmin;
  final VoidCallback? openAdmin;
  final String version;
}

class MsSettingsPage extends StatefulWidget {
  const MsSettingsPage({super.key, required this.actions, this.showGuide = true});
  final MsSettingsActions actions;
  final bool showGuide;
  @override
  State<MsSettingsPage> createState() => _MsSettingsPageState();
}

class _MsSettingsPageState extends State<MsSettingsPage> {
  MsSettingsActions get a => widget.actions;

  @override
  void initState() {
    super.initState();
    if (widget.showGuide) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showMsGuideOnce(context);
      });
    }
  }

  void _go(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return MsScaffold(
      title: 'Settings',
      subtitle: 'Only what helps your practice.',
      children: [
        MsSection(title: 'Sound & practice', rows: [
          MsRow(key: const Key('ms_player'), icon: Icons.tune_rounded, title: 'Player', subtitle: 'Equalizer, quality, sleep timer', onTap: a.openPlayer),
          MsRow(key: const Key('ms_notifications'), icon: Icons.notifications_none_rounded, title: 'Reminders', subtitle: 'Daily words and streak', onTap: a.openNotifications),
          MsRow(key: const Key('ms_awake'), icon: Icons.light_mode_outlined, title: 'Keep screen awake', subtitle: 'While you practise',
              toggle: a.screenAwake(), onTap: () => setState(() => a.setScreenAwake(!a.screenAwake()))),
        ]),
        MsSection(title: 'Look', rows: [
          MsRow(key: const Key('ms_look'), icon: Icons.blur_on_rounded, title: 'Background & look', subtitle: 'Motion background, nav bar',
              onTap: () => _go(MsLookPage(actions: a))),
        ]),
        MsSection(title: 'Privacy & account', rows: [
          MsRow(key: const Key('ms_profile'), icon: Icons.person_outline_rounded, title: 'Profile', subtitle: 'Name, plan, photo', onTap: a.openProfile),
          MsRow(key: const Key('ms_discover'), icon: Icons.travel_explore, title: 'Appear in Discover', subtitle: 'Others can find your profile',
              toggle: a.appearInDiscover(), onTap: () => setState(() => a.setAppearInDiscover(!a.appearInDiscover()))),
          MsRow(key: const Key('ms_data'), icon: Icons.cleaning_services_outlined, title: 'Storage & history', subtitle: 'Clear cache or practice history',
              onTap: () => _go(MsDataPage(actions: a))),
          MsRow(key: const Key('ms_privacy'), icon: Icons.lock_outline, title: 'Privacy policy', action: 'Read', onTap: a.openPrivacy),
          MsRow(key: const Key('ms_terms'), icon: Icons.description_outlined, title: 'Terms of service', action: 'Read', onTap: a.openTerms),
          MsRow(key: const Key('ms_signout'), icon: Icons.logout_rounded, title: 'Sign out', action: 'Sign out',
              onTap: a.signOut),
          MsRow(key: const Key('ms_delete'), icon: Icons.person_remove_outlined, title: 'Delete account', action: 'Delete', danger: true,
              onTap: a.deleteAccount),
        ]),
        MsSection(title: 'Help', rows: [
          MsRow(key: const Key('ms_guide_row'), icon: Icons.self_improvement_rounded, title: 'Quick guide', subtitle: 'Three calm steps', action: 'Show', onTap: () => showMsGuide(context)),
          MsRow(key: const Key('ms_player_guide'), icon: Icons.menu_book_outlined, title: 'Player guide', onTap: a.openPlayerGuide),
          MsRow(key: const Key('ms_request'), icon: Icons.edit_note_outlined, title: 'Request words', action: 'Ask', onTap: a.requestWords),
          MsRow(key: const Key('ms_about'), icon: Icons.info_outline, title: 'About NowssB', subtitle: a.version.isEmpty ? null : a.version, onTap: a.openAbout),
        ]),
        if (a.isAdmin && a.openAdmin != null)
          MsSection(title: 'Admin', rows: [
            MsRow(key: const Key('ms_admin'), icon: Icons.admin_panel_settings_outlined, title: 'Admin', subtitle: 'Words, quotes, editor', onTap: a.openAdmin),
          ]),
      ],
    );
  }
}

/// Sub-page: Background & look (merges Fashion Plus + Nav bar).
class MsLookPage extends StatefulWidget {
  const MsLookPage({super.key, required this.actions});
  final MsSettingsActions actions;
  @override
  State<MsLookPage> createState() => _MsLookPageState();
}

class _MsLookPageState extends State<MsLookPage> {
  @override
  Widget build(BuildContext context) {
    final a = widget.actions;
    return MsScaffold(title: 'Background & look', subtitle: 'Calm, still or moving.', children: [
      MsSection(title: 'Background', rows: [
        MsRow(key: const Key('ms_motion'), icon: Icons.movie_filter_outlined, title: 'Motion background', subtitle: 'Slow film behind every page',
            toggle: a.motionBackground(), onTap: () => setState(() => a.setMotionBackground(!a.motionBackground()))),
        MsRow(key: const Key('ms_pick_bg'), icon: Icons.image_outlined, title: 'Choose background', action: 'Choose', onTap: a.openBackgroundPicker),
      ]),
      MsSection(title: 'Navigation bar', rows: [
        MsRow(key: const Key('ms_nav'), icon: Icons.space_dashboard_outlined, title: 'Glass nav bar', subtitle: 'Off = solid black',
            toggle: a.navGlass(), onTap: () => setState(() => a.setNavGlass(!a.navGlass()))),
      ]),
    ]);
  }
}

/// Sub-page: Storage & history (merges Clear cache + Clear history).
class MsDataPage extends StatelessWidget {
  const MsDataPage({super.key, required this.actions});
  final MsSettingsActions actions;
  @override
  Widget build(BuildContext context) => MsScaffold(title: 'Storage & history', subtitle: 'Free space or start fresh.', children: [
        MsSection(title: 'On this phone', rows: [
          MsRow(key: const Key('ms_cache'), icon: Icons.cleaning_services_outlined, title: 'Clear cached media', subtitle: 'Downloads again when needed',
              action: 'Clear', onTap: actions.clearCache),
          MsRow(key: const Key('ms_history'), icon: Icons.history_toggle_off_rounded, title: 'Clear practice history', subtitle: 'Asks before erasing',
              action: 'Clear', danger: true, onTap: actions.clearHistory),
        ]),
      ]);
}
