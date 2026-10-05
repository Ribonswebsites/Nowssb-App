/// Native counterpart of the AURA `player-settings.html` settings page.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings.dart';
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
  int? _batteryPct;

  static const _eqOptions = ['Flat', 'Bass', 'Treble', 'Vocal', 'Electronic'];
  static const _qualityOptions = ['Low', 'Normal', 'High', 'Lossless'];
  static const _crossfadeOptions = ['Off', '3 Sec', '5 Sec', '8 Sec', '12 Sec'];
  static const _sleepOptions = ['Off', '15 Min', '30 Min', '45 Min', '1 Hour'];
  static const _playlistOptions = ['Classic', 'Grid', 'Compact'];
  static const _nowPlayingOptions = ['On', 'Mini Only', 'Off'];
  static const _viewOptions = ['Classic', 'Minimal', 'Grid'];

  @override
  void initState() {
    super.initState();
    s.addListener(_refresh);
    _readBattery();
  }

  Future<void> _readBattery() async {
    try {
      const ch = MethodChannel('nowssb/device');
      final level = await ch.invokeMethod<num>('batteryLevel');
      if (mounted && level != null) {
        setState(() => _batteryPct = level.round().clamp(0, 100));
      }
    } catch (_) {
      if (mounted) setState(() => _batteryPct = 52);
    }
  }

  @override
  void dispose() {
    s.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String get _eqLabel => switch (s.eq) {
        'deep' => 'Bass',
        'bright' => 'Treble',
        'focus' => 'Vocal',
        'custom' => 'Electronic',
        _ => 'Flat',
      };

  void _setEq(String label) {
    final key = switch (label) {
      'Bass' => 'deep',
      'Treble' => 'bright',
      'Vocal' => 'focus',
      'Electronic' => 'custom',
      _ => 'flat',
    };
    s.setEq(key);
  }

  Future<void> _choose(String title, List<String> options, String current,
      ValueChanged<String> onPick) async {
    await showModalBottomSheet<void>(
      context: context,
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
    final batt = _batteryPct ?? 52;

    // Shared player shell (Saved words / Library uses the same one).
    return PlayerAuraPage(
      slot: 'player_settings.PlayerSettingsScreen',
      title: 'MUSIC PLAYER\nSETTINGS',
      body: ListView(
        padding: EdgeInsets.fromLTRB(22, 0, 16, 28 + bottomInset),
        // Server-driven order (Admin → UI Editor); bundled order by default.
        children: layoutChildren(context, 'player.settings', [
          const SizedBox(height: 4),
          LSection(
              'promo',
              'Promo banner',
              ColoredSplitPromoBanner(
                spec: const SplitPromoSpec(
                  title: 'Unlock every\ntone and plan.',
                  cta: 'View plans',
                  leftColor: Color(0xFF1A2744),
                  rightColor: Color(0xFFC9A227),
                  art: SplitPromoArts.pose09,
                ),
                margin: EdgeInsets.zero,
              )),
          const SizedBox(height: 8),
          LSection(
              'eq',
              'Equalizer',
              _nav(Icons.tune, 'Equalizer', _eqLabel,
                  () => _choose('Equalizer', _eqOptions, _eqLabel, _setEq))),
          LSection(
              'quality',
              'Audio quality',
              _nav(
                  Icons.graphic_eq,
                  'Audio Quality',
                  s.quality,
                  () => _choose('Audio Quality', _qualityOptions, s.quality,
                      s.setQuality))),
          LSection(
              'bass',
              'Bass boost',
              _toggle(Icons.multitrack_audio, 'Bass Boost', s.bassBoost,
                  s.toggleBass)),
          LSection(
              'crossfade',
              'Crossfade',
              _nav(
                  Icons.compare_arrows,
                  'Crossfade',
                  s.crossfade,
                  () => _choose('Crossfade', _crossfadeOptions, s.crossfade,
                      s.setCrossfade))),
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
              'download',
              'Download only',
              _toggle(Icons.download_outlined, 'Download Only', s.downloadOnly,
                  s.toggleDownloadOnly)),
          LSection(
              'nowview',
              'Now playing view',
              _nav(
                  Icons.queue_music,
                  'Now Playing View',
                  s.playlist,
                  () => _choose('Now Playing View', _viewOptions, s.playlist,
                      s.setPlaylist))),
          LSection(
              'playlist',
              'Playlist view',
              _nav(
                Icons.view_list_outlined,
                'Playlist View',
                s.playlist == 'Classic' ||
                        s.playlist == 'Grid' ||
                        s.playlist == 'Compact'
                    ? s.playlist
                    : 'Classic',
                () => _choose('Playlist View', _playlistOptions, s.playlist,
                    s.setPlaylist),
              )),
          LSection(
              'nowplaying',
              'Now playing',
              _nav(
                  Icons.notifications_none,
                  'Now Playing',
                  s.nowPlaying,
                  () => _choose('Now Playing', _nowPlayingOptions, s.nowPlaying,
                      s.setNowPlaying),
                  last: true)),
          const SizedBox(height: 24),
          LSection(
              'battery',
              'Battery note',
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.battery_full,
                      size: 14, color: Colors.white.withOpacity(0.55)),
                  const SizedBox(width: 6),
                  Text(
                    '$batt%',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              )),
          SizedBox(height: 12 + bottomInset),
        ]),
      ),
    );
  }

  Widget _nav(IconData icon, String label, String value, VoidCallback onTap,
          {bool last = false}) =>
      InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(bottom: BorderSide(color: Color(0x24F2F4F7))),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, letterSpacing: 2),
                ),
              ),
              if (value.isNotEmpty)
                Text(
                  value.toUpperCase(),
                  style: const TextStyle(
                      color: Color(0x99B3BDCA),
                      fontSize: 11,
                      letterSpacing: 1.4),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  color: Color(0x73B3BDCA), size: 18),
            ],
          ),
        ),
      );

  Widget _toggle(IconData icon, String label, bool value, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x24F2F4F7))),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, letterSpacing: 2),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: (_) => onTap(),
                activeColor: Colors.white,
              ),
            ],
          ),
        ),
      );
}
