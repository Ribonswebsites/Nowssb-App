/// Physical settings dial — SVG-style CustomPaint metal, six live buttons,
/// knurl winds like a watch crown with haptic ticks.
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
  const PlayerDial({
    super.key,
    required this.word,
    this.playing = false,
    this.onPlay,
  });
  final String word;
  final bool playing;
  final VoidCallback? onPlay;

  @override
  State<PlayerDial> createState() => _PlayerDialState();
}

class _PlayerDialState extends State<PlayerDial> {
  String? _hud;
  double _turn = 0;
  String _arm = 'volume';
  double? _lastAng;
  double _acc = 0;

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
    if (p == 'shuffle') {
      setState(() => _hud = 'Shuffle');
      Future<void>.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _hud = null);
      });
      return;
    }
    if (p == 'output') {
      final next = s.cycleOutput();
      setState(() => _hud = next[0].toUpperCase() + next.substring(1));
      Future<void>.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _hud = null);
      });
      return;
    }
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

  void _flash(String msg) {
    setState(() => _hud = msg);
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _hud = null);
    });
  }

  void _tick(int dir) {
    HapticFeedback.selectionClick();
    if (_arm == 'volume') {
      s.setVolume((s.volume + dir * 0.02).clamp(0, 1));
      _flash('Volume · ${(s.volume * 100).round()}');
    } else if (_arm == 'speed') {
      s.setSpeed((s.speed + dir * 0.05).clamp(0.7, 1.5));
      _flash('Speed · ${s.speed.toStringAsFixed(2)}×');
    } else {
      s.setReps((s.reps + dir).clamp(1, 99));
      _flash('Reps · ${s.reps}×');
    }
  }

  double _ang(Offset local, Size size) {
    return math.atan2(local.dy - size.height / 2, local.dx - size.width / 2);
  }

  @override
  Widget build(BuildContext context) {
    const acts = <(String, IconData, String)>[
      ('voice', Icons.graphic_eq, 'Voice'),
      ('eq', Icons.tune, 'Equalizer'),
      ('loop', Icons.repeat, 'Loop'),
      ('reps', Icons.exposure, 'Reps'),
      ('speed', Icons.speed, 'Speed'),
      ('volume', Icons.volume_up, 'Volume'),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF050506)),
        CustomPaint(painter: _GhostRingsPainter(), size: Size.infinite),
        Align(
          alignment: const Alignment(0, -0.08),
          child: FractionallySizedBox(
            widthFactor: 0.92,
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, box) {
                  final size = box.maxWidth;
                  final r = size * 0.318;
                  return GestureDetector(
                    onPanStart: (d) {
                      _lastAng = _ang(d.localPosition, Size.square(size));
                      _acc = 0;
                    },
                    onPanUpdate: (d) {
                      if (_lastAng == null) return;
                      final next = _ang(d.localPosition, Size.square(size));
                      var delta = next - _lastAng!;
                      if (delta > math.pi) delta -= math.pi * 2;
                      if (delta < -math.pi) delta += math.pi * 2;
                      _lastAng = next;
                      setState(() => _turn += delta);
                      _acc += delta * 180 / math.pi;
                      while (_acc >= 5) {
                        _acc -= 5;
                        _tick(1);
                      }
                      while (_acc <= -5) {
                        _acc += 5;
                        _tick(-1);
                      }
                    },
                    onPanEnd: (_) => _lastAng = null,
                    onPanCancel: () => _lastAng = null,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size.square(size),
                          painter: _DialPainter(turn: _turn, playing: widget.playing),
                        ),
                        for (var i = 0; i < acts.length; i++)
                          () {
                            final a = -math.pi / 2 + i * (math.pi / 3);
                            final id = acts[i].$1;
                            final armed = id == _arm;
                            final on = id == 'loop' && s.loop != 'off';
                            return Positioned(
                              left: size / 2 + math.cos(a) * r - 26,
                              top: size / 2 + math.sin(a) * r - 26,
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  if (id == 'loop') {
                                    _open('loop');
                                    return;
                                  }
                                  if (id == 'volume' || id == 'speed' || id == 'reps') {
                                    setState(() => _arm = id);
                                  }
                                  _open(id);
                                },
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Center(
                                    child: id == 'reps'
                                        ? Text(
                                            '${s.reps}×',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              shadows: [
                                                Shadow(
                                                  color: armed
                                                      ? const Color(0xE6FFFFFF)
                                                      : const Color(0x66FFFFFF),
                                                  blurRadius: armed ? 12 : 6,
                                                ),
                                              ],
                                            ),
                                          )
                                        : Icon(
                                            acts[i].$2,
                                            color: Colors.white,
                                            size: 22,
                                            shadows: [
                                              Shadow(
                                                color: on || armed
                                                    ? const Color(0xE6FFFFFF)
                                                    : const Color(0x66FFFFFF),
                                                blurRadius: on || armed ? 12 : 6,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            );
                          }(),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onPlay?.call();
                            },
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              _open('settings');
                            },
                            child: Container(
                              width: size * 0.32,
                              height: size * 0.148,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF5A5A62), Color(0xFF1C1C20), Color(0xFF0A0A0C)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.playing
                                        ? const Color(0xA6FFFFFF)
                                        : const Color(0x9EFFFFFF),
                                    blurRadius: widget.playing ? 22 : 14,
                                  ),
                                ],
                                border: Border.all(color: const Color(0xA6FFFFFF), width: 1.2),
                              ),
                              child: const Icon(Icons.settings, color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          left: 56,
          right: 56,
          top: 48,
          child: Column(
            children: [
              Text(
                widget.word,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.playing ? 'PLAYING' : 'WIND THE RING · TAP A CONTROL',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  color: Color(0x61FFFFFF),
                ),
              ),
            ],
          ),
        ),
        if (_hud != null)
          Positioned(
            top: 64,
            left: 0,
            right: 0,
            child: Center(
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
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GhostRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12;
    void ring(Offset c, double r) {
      for (var i = 0; i < 180; i++) {
        final a = i / 180 * math.pi * 2;
        paint.color = Color.fromARGB(40, 40 + (i % 4) * 16, 40 + (i % 4) * 16, 44);
        canvas.drawLine(
          Offset(c.dx + math.cos(a) * r * 0.86, c.dy + math.sin(a) * r * 0.86),
          Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
          paint..strokeWidth = i.isEven ? 2.2 : 1.1,
        );
      }
    }
    ring(Offset(-size.width * 0.15, size.height * 0.12), size.width * 0.72);
    ring(Offset(size.width * 1.05, size.height * 0.92), size.width * 0.68);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.turn, required this.playing});
  final double turn;
  final bool playing;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    for (var i = 0; i < 240; i++) {
      final a = turn + i / 240 * math.pi * 2;
      final shade = 14 + (i % 4) * 18;
      final p = Paint()
        ..color = Color.fromARGB(255, shade, shade, shade + 2)
        ..strokeWidth = i.isEven ? 2.0 : 1.05
        ..strokeCap = StrokeCap.butt;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * r * 0.705, c.dy + math.sin(a) * r * 0.705),
        Offset(c.dx + math.cos(a) * r * 0.995, c.dy + math.sin(a) * r * 0.995),
        p,
      );
    }

    final lip = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3A3A40), Color(0xFF111114), Color(0xFF050506)],
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.70));
    canvas.drawCircle(c, r * 0.70, lip);

    final face = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.24, -0.4),
        colors: [Color(0xFF2A2A30), Color(0xFF121214), Color(0xFF070708)],
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.63));
    canvas.drawCircle(c, r * 0.63, face);

    for (var i = 0; i < 72; i++) {
      final a = -math.pi / 2 + i * (math.pi * 2 / 72);
      final major = i % 6 == 0;
      final p = Paint()
        ..color = Colors.white.withValues(alpha: major ? 0.5 : 0.18)
        ..strokeWidth = major ? 1.4 : 0.8;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * r * 0.585, c.dy + math.sin(a) * r * 0.585),
        Offset(c.dx + math.cos(a) * r * (major ? 0.535 : 0.555), c.dy + math.sin(a) * r * (major ? 0.535 : 0.555)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.turn != turn || old.playing != playing;
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
