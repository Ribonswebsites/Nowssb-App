/// Native counterpart of the AURA `player-settings.html` settings page.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings.dart';

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
  static const _speedOptions = ['0.5x', '0.75x', 'Normal', '1.25x', '1.5x', '2x'];
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

  String get _speedLabel {
    if ((s.speed - 1).abs() < 0.01) return 'Normal';
    return s.speed == s.speed.roundToDouble() ? '${s.speed.toInt()}x' : '${s.speed}x';
  }

  void _setSpeed(String label) {
    final value = switch (label) {
      '0.5x' => .5,
      '0.75x' => .75,
      '1.25x' => 1.25,
      '1.5x' => 1.5,
      '2x' => 2.0,
      _ => 1.0,
    };
    s.setSpeed(value);
  }

  Future<void> _choose(String title, List<String> options, String current, ValueChanged<String> onPick) async {
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
              Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF8B919A), fontSize: 12, letterSpacing: 2)),
              const SizedBox(height: 8),
              for (final option in options)
                ListTile(
                  title: Text(option, style: const TextStyle(color: Colors.white, letterSpacing: .8)),
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

    return Scaffold(
      backgroundColor: const Color(0xFF202731),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 16, 4),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: Colors.black54,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.chevron_left_rounded, color: Color(0xFF202731), size: 28),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'AURA',
                    style: TextStyle(color: Color(0xFFF2F2EF), fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 18, 24, 28),
                child: Text(
                  'MUSIC PLAYER\nSETTINGS',
                  style: TextStyle(
                    color: Color(0xFFF2F2EF),
                    fontSize: 29,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4.0,
                    height: 1.28,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 28 + bottomInset),
                children: [
                  _nav(Icons.tune, 'Equalizer', _eqLabel, () => _choose('Equalizer', _eqOptions, _eqLabel, _setEq)),
                  _nav(Icons.graphic_eq, 'Audio Quality', s.quality, () => _choose('Audio Quality', _qualityOptions, s.quality, s.setQuality)),
                  _toggle(Icons.multitrack_audio, 'Bass Boost', s.bassBoost, s.toggleBass),
                  _nav(Icons.speed, 'Playback Speed', _speedLabel, () => _choose('Playback Speed', _speedOptions, _speedLabel, _setSpeed)),
                  _nav(Icons.compare_arrows, 'Crossfade', s.crossfade, () => _choose('Crossfade', _crossfadeOptions, s.crossfade, s.setCrossfade)),
                  _nav(Icons.timer_outlined, 'Sleep Timer', s.sleepTimer, () => _choose('Sleep Timer', _sleepOptions, s.sleepTimer, s.setSleepTimer)),
                  _toggle(Icons.download_outlined, 'Download Only', s.downloadOnly, s.toggleDownloadOnly),
                  _nav(Icons.queue_music, 'Now Playing View', s.playlist, () => _choose('Now Playing View', _viewOptions, s.playlist, s.setPlaylist)),
                  _nav(Icons.view_list_outlined, 'Playlist View', s.playlist == 'Classic' || s.playlist == 'Grid' || s.playlist == 'Compact' ? s.playlist : 'Classic', () => _choose('Playlist View', _playlistOptions, s.playlist, s.setPlaylist)),
                  _nav(Icons.notifications_none, 'Now Playing', s.nowPlaying, () => _choose('Now Playing', _nowPlayingOptions, s.nowPlaying, s.setNowPlaying)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.battery_full, size: 14, color: Colors.white.withOpacity(0.55)),
                      const SizedBox(width: 6),
                      Text(
                        '$batt%',
                        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, letterSpacing: 0.6),
                      ),
                    ],
                  ),
                  SizedBox(height: 12 + bottomInset),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nav(IconData icon, String label, String value, VoidCallback onTap) => InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 56,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x24F2F4F7))),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(icon, color: Colors.white.withOpacity(.9), size: 20),
                const SizedBox(width: 14),
                Expanded(child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2))),
                if (value.isNotEmpty) Text(value.toUpperCase(), style: const TextStyle(color: Color(0xFF8B919A), fontSize: 12, letterSpacing: 1.4)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: Color(0x738B919A), size: 18),
              ],
            ),
          ),
        ),
      );

  Widget _toggle(IconData icon, String label, bool value, VoidCallback onTap) => InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 56,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x24F2F4F7))),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(icon, color: Colors.white.withOpacity(.9), size: 20),
                const SizedBox(width: 14),
                Expanded(child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 2))),
                Switch.adaptive(value: value, onChanged: (_) => onTap(), activeColor: Colors.white),
              ],
            ),
          ),
        ),
      );
}
