/// Native counterpart of the exact AURA `player-settings.html` page.
library;

import 'package:flutter/material.dart';

import '../data/settings.dart';

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  Settings get s => Settings.instance;

  static const _eqOptions = ['Flat', 'Bass', 'Treble', 'Vocal', 'Electronic'];
  static const _qualityOptions = ['Low', 'Normal', 'High', 'Lossless'];
  static const _speedOptions = ['0.5x', '0.75x', 'Normal', '1.25x', '1.5x', '2x'];
  static const _crossfadeOptions = ['Off', '3 Sec', '5 Sec', '8 Sec', '12 Sec'];
  static const _sleepOptions = ['Off', '15 Min', '30 Min', '45 Min', '1 Hour'];
  static const _playlistOptions = ['Classic', 'Grid', 'Compact'];
  static const _nowPlayingOptions = ['On', 'Mini Only', 'Off'];

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
    if (s.speed == 1) return 'Normal';
    return '${s.speed}x';
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
                  trailing: option == current ? const Icon(Icons.check, color: Colors.white) : null,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFF2F2EF)),
                  ),
                  const Spacer(),
                  const Text('AURA', style: TextStyle(color: Color(0xFFF2F2EF), fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Text('MUSIC PLAYER\nSETTINGS', style: TextStyle(color: Color(0xFFF2F2EF), fontSize: 26, fontWeight: FontWeight.w300, letterSpacing: 3.5, height: 1.25)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 28),
                children: [
                  _nav(Icons.tune, 'Equalizer', _eqLabel, () => _choose('Equalizer', _eqOptions, _eqLabel, _setEq)),
                  _nav(Icons.graphic_eq, 'Audio Quality', s.quality, () => _choose('Audio Quality', _qualityOptions, s.quality, s.setQuality)),
                  _toggle(Icons.multitrack_audio, 'Bass Boost', s.bassBoost, s.toggleBass),
                  _nav(Icons.speed, 'Playback Speed', _speedLabel, () => _choose('Playback Speed', _speedOptions, _speedLabel, _setSpeed)),
                  _nav(Icons.compare_arrows, 'Crossfade', s.crossfade, () => _choose('Crossfade', _crossfadeOptions, s.crossfade, s.setCrossfade)),
                  _nav(Icons.timer_outlined, 'Sleep Timer', s.sleepTimer, () => _choose('Sleep Timer', _sleepOptions, s.sleepTimer, s.setSleepTimer)),
                  _toggle(Icons.download_outlined, 'Download Only', s.downloadOnly, s.toggleDownloadOnly),
                  _nav(Icons.queue_music, 'Playlist View', s.playlist, () => _choose('Playlist View', _playlistOptions, s.playlist, s.setPlaylist)),
                  _nav(Icons.notifications_none, 'Now Playing', s.nowPlaying, () => _choose('Now Playing', _nowPlayingOptions, s.nowPlaying, s.setNowPlaying)),
                  _nav(Icons.more_horiz, 'Additional Settings', '', () {}),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: const Color(0x12FFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x10FFFFFF))),
                child: Row(
                  children: [
                    Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF161920), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.graphic_eq, color: Colors.white70)),
                    const SizedBox(width: 10),
                    const Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NOWSSB PLAYER', style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 1.6, fontWeight: FontWeight.w600)), Text('AURA', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 10, letterSpacing: 1.4))])),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous, color: Colors.white)),
                    Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white70)), child: const Icon(Icons.play_arrow, color: Colors.white, size: 20)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nav(IconData icon, String label, String value, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

