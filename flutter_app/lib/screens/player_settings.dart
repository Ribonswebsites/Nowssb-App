/// Native counterpart of the AURA `player-settings.html` settings page.
library;

import '../widgets/glass_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings.dart';
import '../data/word_voice.dart';
import '../theme/player_aura.dart';
import '../widgets/colored_split_promo_banner.dart';
import '../admin/template/editable.dart';
import '../admin/layout/layout_sections.dart';

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  Settings get s => Settings.instance;

  static const _boostOptions = ['Off', '+6 dB', '+12 dB'];
  static const _sleepOptions = ['Off', '15 Min', '30 Min', '45 Min', '1 Hour'];
  static const _nowPlayingOptions = ['On', 'Off'];

  String get _boostLabel => switch (s.voiceBoost) { 6 => '+6 dB', 12 => '+12 dB', _ => 'Off' };

  void _setBoost(String label) {
    final db = switch (label) { '+6 dB' => 6, '+12 dB' => 12, _ => 0 };
    s.setVoiceBoost(db);
    WordVoice.instance.applyBoost(db);
  }

  @override
  void initState() {
    super.initState();
    s.addListener(_refresh);
  }

  @override
  void dispose() {
    s.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _choose(String title, List<String> options, String current,
      ValueChanged<String> onPick) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: const Color(0xFF14171E),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title.toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF8B919A),
                      fontSize: 12,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              for (final option in options)
                ListTile(
                  title: Text(option,
                      style: const TextStyle(
                          color: Colors.white, letterSpacing: .8)),
                  trailing: option.toLowerCase() == current.toLowerCase()
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                  onTap: () {
                    onPick(option);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // Shared player shell (Saved words / Library uses the same one).
    return PlayerAuraPage(
      slot: 'player_settings.PlayerSettingsScreen',
      title: 'MUSIC PLAYER\nSETTINGS',
      body: ListView(
        padding: EdgeInsets.fromLTRB(22, 0, 16, 28 + bottomInset),
        // Server-driven order (Admin → UI Editor); bundled order by default.
        children: [
          ...layoutChildren(context, 'player.settings', [
          LSection(
              'voiceboost',
              'Voice boost',
              _nav(Icons.volume_up_rounded, 'Voice Boost', _boostLabel,
                  () => _choose('Voice Boost', _boostOptions, _boostLabel, _setBoost))),
          LSection(
              'sleep',
              'Sleep timer',
              _nav(
                  Icons.timer_outlined,
                  'Sleep Timer',
                  s.sleepTimer,
                  () => _choose('Sleep Timer', _sleepOptions, s.sleepTimer,
                      s.setSleepTimer))),
          LSection(
              'nowplaying',
              'Mini player',
              _nav(
                  Icons.picture_in_picture_alt_rounded,
                  'Mini Player',
                  s.nowPlaying == 'Off' ? 'Off' : 'On',
                  () => _choose('Mini Player', _nowPlayingOptions, s.nowPlaying == 'Off' ? 'Off' : 'On',
                      s.setNowPlaying),
                  last: true)),
          ]),
          SizedBox(height: 12 + bottomInset),
        ],
      ),
    );
  }

  Widget _nav(IconData icon, String label, String value, VoidCallback onTap,
          {bool last = false}) =>
      GlassItemCard(icon: icon, overline: 'Player', title: label, pill: value, pillSub: 'Tap to change', onTap: onTap);
}
