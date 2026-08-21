/// Physical settings dial — knurled aluminium ring, six glowing icons,
/// pill gear in the centre. Same instrument as the HTML player.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings.dart';
import '../media/nwsb_image.dart';
import '../theme/tokens.dart';

const _cyan = Color(0xFFD7F2FF);
const _metal = Color(0xFF050506);

class PlayerDial extends StatefulWidget {
  const PlayerDial({super.key, required this.word});
  final String word;

  @override
  State<PlayerDial> createState() => _PlayerDialState();
}

class _PlayerDialState extends State<PlayerDial> {
  String? _hud;

  Settings get s => Settings.instance;

  @override
  void initState() {
    super.initState();
    s.addListener(_on);
  }

  @override
  void dispose() {
    s.removeListener(_on);
    super.dispose();
  }

  void _on() {
    if (mounted) setState(() {});
  }

  void _open(String p) {
    HapticFeedback.lightImpact();
    if (p == 'loop') {
      final next = s.cycleLoop();
      setState(() => _hud = 'Loop · ${next[0].toUpperCase()}${next.substring(1)}');
      Future<void>.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _hud = null);
      });
      return;
    }
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: const Color(0xF2050506),
      pageBuilder: (ctx, _, __) => _DialOverlay(
        word: widget.word,
        initial: p,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const ClipOval(
                child: NwsbImage(
                  'assets/player/dial-hero.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              for (var i = 0; i < 6; i++)
                _IconSlot(
                  index: i,
                  on: i == 2 && s.loop != 'off',
                  child: i == 3
                      ? Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _metal,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${s.reps}×',
                            style: const TextStyle(
                              color: _cyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  onTap: () => _open(
                    ['voice', 'eq', 'loop', 'reps', 'speed', 'volume'][i],
                  ),
                ),
              GestureDetector(
                onTap: () => _open('settings'),
                child: Container(
                  width: 84,
                  height: 44,
                  color: Colors.transparent,
                ),
              ),
              if (_hud != null)
                Positioned(
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _hud!,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: _cyan,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'VOICE  ·  EQ  ·  LOOP  ·  REPS  ·  SPEED  ·  VOLUME',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
            color: Color(0x80D7F2FF),
          ),
        ),
      ],
    );
  }
}

class _IconSlot extends StatelessWidget {
  const _IconSlot({
    required this.index,
    required this.child,
    required this.onTap,
    this.on = false,
  });
  final int index;
  final Widget child;
  final VoidCallback onTap;
  final bool on;

  @override
  Widget build(BuildContext context) {
    const r = 89.0;
    final a = (index * 60 - 90) * math.pi / 180;
    return Transform.translate(
      offset: Offset(math.cos(a) * r, math.sin(a) * r),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: on
                  ? const [BoxShadow(color: Color(0x88D7F2FF), blurRadius: 14)]
                  : null,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _DialOverlay extends StatefulWidget {
  const _DialOverlay({required this.word, required this.initial});
  final String word;
  final String initial;

  @override
  State<_DialOverlay> createState() => _DialOverlayState();
}

class _DialOverlayState extends State<_DialOverlay> {
  late String panel = widget.initial;
  Settings get s => Settings.instance;

  static const _hz = ['60', '150', '400', '1k', '2.4k', '6k', '14k'];

  @override
  void initState() {
    super.initState();
    s.addListener(_on);
  }

  @override
  void dispose() {
    s.removeListener(_on);
    super.dispose();
  }

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final title = {
      'voice': 'Voice',
      'eq': 'Equalizer',
      'reps': 'Repetitions',
      'speed': 'Speed',
      'volume': 'Volume',
      'settings': 'Settings',
      'update': 'Update',
    }[panel] ?? panel;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          const Positioned.fill(
            child: Opacity(
              opacity: 0.45,
              child: NwsbImage(
                'assets/player/dial-knurl.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                if (panel != 'update') ...[
                  const Text(
                    'PLAYER',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 3,
                      color: _cyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (panel == 'voice') _voice(),
                if (panel == 'eq') _eq(),
                if (panel == 'reps') _reps(),
                if (panel == 'speed') _speed(),
                if (panel == 'volume') _volume(),
                if (panel == 'settings') _settings(),
                if (panel == 'update') _update(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, VoidCallback? onTap, bool on = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xB8141824),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: on ? const Color(0x80D7F2FF) : const Color(0x24C8E8FF),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _voice() {
    const voices = [
      ('female', 'Female', 'Clear mid, the default teaching voice'),
      ('male', 'Male', 'Lower chest resonance'),
      ('resonance', 'Resonance', 'Studio master, held longer'),
      ('night', 'Night', 'Soft, for late practice'),
    ];
    return Column(
      children: [
        for (final v in voices)
          _card(
            on: s.voice == v.$1,
            onTap: () => s.setVoice(v.$1),
            child: Row(
              children: [
                const Icon(Icons.graphic_eq, color: _cyan, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      Text(v.$3, style: const TextStyle(color: Color(0x8CFFFFFF), fontSize: 12)),
                    ],
                  ),
                ),
                if (s.voice == v.$1)
                  const Text('LIVE', style: TextStyle(color: _cyan, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Tap a voice to set it for ${widget.word}.',
            style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _eq() {
    return Column(
      children: [
        _card(
          child: SizedBox(
            height: 180,
            child: Row(
              children: [
                for (var i = 0; i < s.bands.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              ),
                              child: Slider(
                                value: s.bands[i],
                                min: -12,
                                max: 12,
                                activeColor: _cyan,
                                onChanged: (v) => s.setBand(i, v),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          _hz[i],
                          style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in ['flat', 'focus', 'deep', 'bright', 'custom'])
              ChoiceChip(
                label: Text(p),
                selected: s.eq == p,
                selectedColor: Colors.white,
                labelStyle: TextStyle(
                  color: s.eq == p ? NwsbColors.ink : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                backgroundColor: const Color(0x14FFFFFF),
                onSelected: (_) => s.setEq(p),
              ),
          ],
        ),
      ],
    );
  }

  Widget _reps() {
    const presets = [1, 3, 5, 7, 10];
    final custom = !presets.contains(s.reps);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final n in presets)
          _num(n, s.reps == n, () => s.setReps(n)),
        GestureDetector(
          onTap: () async {
            final ctrl = TextEditingController(text: '${s.reps}');
            final n = await showDialog<int>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF0E1524),
                title: const Text('Custom repetitions', style: TextStyle(color: Colors.white)),
                content: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  autofocus: true,
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
                    child: const Text('Set'),
                  ),
                ],
              ),
            );
            if (n != null && n > 0 && n <= 99) s.setReps(n);
          },
          child: Container(
            width: 88,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0x2E0E1524),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: custom ? const Color(0x80D7F2FF) : const Color(0x24FFFFFF)),
            ),
            child: Text(
              'Custom',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: custom ? _cyan : Colors.white70,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _num(int n, bool on, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0x2E0E1524),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? const Color(0x80D7F2FF) : const Color(0x24FFFFFF)),
        ),
        child: Text(
          '$n×',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: on ? _cyan : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _speed() {
    return _card(
      child: Column(
        children: [
          Text(
            '${s.speed.toStringAsFixed(2)}×',
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: _cyan),
          ),
          const Text('0.70× slow hold — 1.50× fluent', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
          Slider(value: s.speed, min: 0.7, max: 1.5, onChanged: s.setSpeed, activeColor: _cyan),
        ],
      ),
    );
  }

  Widget _volume() {
    return Column(
      children: [
        _card(
          child: Column(
            children: [
              Text(
                '${(s.volume * 100).round()}',
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: _cyan),
              ),
              Slider(value: s.volume, min: 0, max: 1, onChanged: s.setVolume, activeColor: _cyan),
            ],
          ),
        ),
        for (final o in ['speaker', 'earpiece', 'bluetooth'])
          _card(
            on: s.output == o,
            onTap: () => s.setOutput(o),
            child: Text(
              o[0].toUpperCase() + o.substring(1),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }

  Widget _row(String k, String v, VoidCallback onTap) {
    return _card(
      onTap: onTap,
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 14)),
          const Spacer(),
          Text(v, style: const TextStyle(color: _cyan, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _settings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6, left: 4),
          child: Text('PLAYBACK', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0x66FFFFFF), fontWeight: FontWeight.w800)),
        ),
        _row('Voice', s.voice, () => setState(() => panel = 'voice')),
        _row('Speed', '${s.speed.toStringAsFixed(2)}×', () => setState(() => panel = 'speed')),
        _row('Reps', '${s.reps}×', () => setState(() => panel = 'reps')),
        _row('Loop', s.loop, () => s.cycleLoop()),
        _row('Equalizer', s.eq, () => setState(() => panel = 'eq')),
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 6, left: 4),
          child: Text('AUDIO QUALITY', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0x66FFFFFF), fontWeight: FontWeight.w800)),
        ),
        _row('Render', s.qualityHigh ? 'High' : 'Standard', s.toggleQuality),
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 6, left: 4),
          child: Text('DISPLAY & ANIMATION', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0x66FFFFFF), fontWeight: FontWeight.w800)),
        ),
        _row('Motion', s.animationOn ? 'On' : 'Off', s.toggleAnimation),
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 6, left: 4),
          child: Text('NOTIFICATIONS', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0x66FFFFFF), fontWeight: FontWeight.w800)),
        ),
        _row('Practice reminders', s.notifyOn ? 'On' : 'Off', s.toggleNotify),
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 6, left: 4),
          child: Text('ABOUT', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0x66FFFFFF), fontWeight: FontWeight.w800)),
        ),
        _row('Version', '9.6.0', () {}),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => setState(() => panel = 'update'),
          style: FilledButton.styleFrom(backgroundColor: _cyan, foregroundColor: NwsbColors.ink),
          child: const Text('Check for updates'),
        ),
      ],
    );
  }

  Widget _update() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0x33D7F2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('NEW', style: TextStyle(color: _cyan, letterSpacing: 2, fontWeight: FontWeight.w800, fontSize: 10)),
          ),
          const SizedBox(height: 10),
          const Text('Update available', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('NowssB 9.6.0', style: TextStyle(color: Color(0x8CFFFFFF))),
          const SizedBox(height: 12),
          const Text(
            'Physical settings dial. Voice, equalizer, loop, reps, speed and volume now live on the player.',
            style: TextStyle(height: 1.5, color: Color(0xCCFFFFFF)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Later'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(backgroundColor: _cyan, foregroundColor: NwsbColors.ink),
                  child: const Text('Update now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
