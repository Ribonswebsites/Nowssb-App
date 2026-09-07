/// Aura clock dial + preview settings — matches the target mock.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings.dart';
import 'player_settings.dart';

class PlayerDial extends StatefulWidget {
  const PlayerDial({
    super.key,
    required this.word,
    this.playing = false,
    this.onPlay,
    this.onClose,
    this.onSettings,
  });
  final String word;
  final bool playing;
  final VoidCallback? onPlay;
  final VoidCallback? onClose;
  final VoidCallback? onSettings;

  @override
  State<PlayerDial> createState() => _PlayerDialState();
}

class _PlayerDialState extends State<PlayerDial> with SingleTickerProviderStateMixin {
  Timer? _tick;
  DateTime _now = DateTime.now();
  late final AnimationController _spin;
  int? _batteryPct;

  Settings get s => Settings.instance;

  static const _eqOptions = ['Flat', 'Bass', 'Treble', 'Vocal', 'Electronic'];
  static const _qualityOptions = ['Low', 'Normal', 'High', 'Lossless'];
  static const _speedOptions = ['0.5x', '0.75x', 'Normal', '1.25x', '1.5x', '2x'];
  static const _crossfadeOptions = ['Off', '3 Sec', '5 Sec', '8 Sec', '12 Sec'];
  static const _sleepOptions = ['Off', '15 Min', '30 Min', '45 Min', '1 Hour'];
  static const _viewOptions = ['Classic', 'Minimal', 'Grid'];

  @override
  void initState() {
    super.initState();
    s.addListener(_on);
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 32))..repeat();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
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
    _tick?.cancel();
    _spin.dispose();
    s.removeListener(_on);
    super.dispose();
  }

  void _on() {
    if (mounted) setState(() {});
  }

  void _openFullSettings() {
    HapticFeedback.lightImpact();
    if (widget.onSettings != null) {
      widget.onSettings!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PlayerSettingsScreen()),
    );
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
    final t = s.speed == s.speed.roundToDouble()
        ? '${s.speed.toInt()}x'
        : '${s.speed}x';
    return t;
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

  Future<void> _choose(
    String title,
    List<String> options,
    String current,
    ValueChanged<String> onPick,
  ) async {
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
              Text(
                title.toUpperCase(),
                style: const TextStyle(color: Color(0xFF8B919A), fontSize: 12, letterSpacing: 2),
              ),
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
    final h12 = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final hh = h12.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    final ap = _now.hour >= 12 ? 'PM' : 'AM';
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    final date = '${_now.day.toString().padLeft(2, '0')} ${months[_now.month - 1]} ${_now.year}';
    final weekday = days[_now.weekday - 1];
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final batt = _batteryPct ?? 52;

    return ColoredBox(
      color: const Color(0xFF1B1E27),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -280) _openFullSettings();
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: Row(
                    children: [
                      _CircleBackButton(
                        onTap: widget.onClose ?? () => Navigator.maybePop(context),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _openFullSettings,
                        tooltip: 'Player settings',
                        icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = math.min(constraints.maxWidth, constraints.maxHeight);
                      return Center(
                        child: SizedBox(
                          width: side,
                          height: side * 0.92,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AnimatedBuilder(
                                animation: _spin,
                                builder: (_, __) => CustomPaint(
                                  painter: _AuraDialPainter(turn: _spin.value),
                                ),
                              ),
                              Align(
                                alignment: const Alignment(-0.12, 0.05),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      hh,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 72,
                                        fontWeight: FontWeight.w300,
                                        height: 0.9,
                                        letterSpacing: -1.5,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      height: 42,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(color: const Color(0xD1F2F2EF), width: 1.2),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            mm,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w400,
                                              fontFeatures: [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(width: 1, height: 15, color: const Color(0x99F2F2EF)),
                                          const SizedBox(width: 8),
                                          Text(
                                            ap,
                                            style: const TextStyle(
                                              color: Color(0xE6FFFFFF),
                                              fontSize: 11,
                                              letterSpacing: 1.6,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: const Alignment(0.92, 0.18),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        letterSpacing: 2.6,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(width: 120, height: 1, color: const Color(0x85F2F2EF)),
                                    const SizedBox(height: 10),
                                    Text(
                                      weekday,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        letterSpacing: 3.2,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _openFullSettings,
                      child: const Text(
                        'MUSIC PLAYER SETTINGS',
                        style: TextStyle(
                          color: Color(0x99B3BDCA),
                          fontSize: 11,
                          letterSpacing: 2.8,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(22, 0, 16, 8 + bottomInset),
                    children: [
                      _row(
                        Icons.tune,
                        'EQUALIZER',
                        _eqLabel.toUpperCase(),
                        () => _choose('Equalizer', _eqOptions, _eqLabel, _setEq),
                      ),
                      _row(
                        Icons.graphic_eq,
                        'AUDIO QUALITY',
                        s.quality.toUpperCase(),
                        () => _choose('Audio Quality', _qualityOptions, s.quality, s.setQuality),
                      ),
                      _row(
                        Icons.speed,
                        'PLAYBACK SPEED',
                        _speedLabel.toUpperCase(),
                        () => _choose('Playback Speed', _speedOptions, _speedLabel, _setSpeed),
                      ),
                      _row(
                        Icons.compare_arrows,
                        'CROSSFADE',
                        s.crossfade.toUpperCase(),
                        () => _choose('Crossfade', _crossfadeOptions, s.crossfade, s.setCrossfade),
                      ),
                      _row(
                        Icons.timer_outlined,
                        'SLEEP TIMER',
                        s.sleepTimer.toUpperCase(),
                        () => _choose('Sleep Timer', _sleepOptions, s.sleepTimer, s.setSleepTimer),
                      ),
                      _row(
                        Icons.queue_music,
                        'NOW PLAYING VIEW',
                        s.playlist.toUpperCase(),
                        () => _choose('Now Playing View', _viewOptions, s.playlist, s.setPlaylist),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'SWIPE UP FOR MORE',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0x47FFFFFF), fontSize: 10, letterSpacing: 2.2),
                      ),
                      SizedBox(height: 18 + bottomInset * 0.25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.battery_full, size: 14, color: Colors.white.withOpacity(0.55)),
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
                      ),
                      SizedBox(height: math.max(12.0, bottomInset)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
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
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2),
              ),
            ),
            Text(
              value,
              style: const TextStyle(color: Color(0x99B3BDCA), fontSize: 11, letterSpacing: 1.4),
            ),
            const Icon(Icons.chevron_right, color: Color(0x73B3BDCA), size: 18),
          ],
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.chevron_left_rounded, color: Color(0xFF202731), size: 28),
        ),
      ),
    );
  }
}

/// Arc dial matching the target mock: C-shaped ticks labeled 15–60.
class _AuraDialPainter extends CustomPainter {
  _AuraDialPainter({required this.turn});
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.42, size.height * 0.52);
    final r = size.width * 0.46;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(turn * 2 * math.pi);
    canvas.translate(-c.dx, -c.dy);

    final tick = Paint()..strokeCap = StrokeCap.butt;
    // Outer arc ~48° to ~333° (C opening on the right/bottom-right).
    const start = 48.0;
    const span = 285.0;
    const count = 72;
    for (var i = 0; i < count; i++) {
      final t = count == 1 ? 0.0 : i / (count - 1);
      final deg = start + t * span;
      final major = i % 6 == 0;
      final mid = !major && i % 3 == 0;
      final len = major ? 18.0 : mid ? 11.0 : 6.0;
      final a = deg * math.pi / 180;
      tick
        ..strokeWidth = major ? 1.5 : 1.1
        ..color = Colors.white.withOpacity(major ? 0.95 : mid ? 0.72 : 0.42);
      final outer = r + (major ? 2.2 : mid ? 0.6 : 0);
      final p1 = c + Offset(math.cos(a) * outer, math.sin(a) * outer);
      final p2 = c + Offset(math.cos(a) * (outer - len), math.sin(a) * (outer - len));
      final mx = (p1.dx + p2.dx) / 2;
      final my = (p1.dy + p2.dy) / 2;
      // Keep ticks clear of the time lockup.
      if (mx > c.dx - 20 && mx < c.dx + 110 && my > c.dy - 40 && my < c.dy + 40) continue;
      canvas.drawLine(p1, p2, tick);
    }

    // Inner secondary arc.
    const innerCount = 48;
    const innerStart = 62.0;
    const innerSpan = 255.0;
    final innerR = r * 0.63;
    for (var i = 0; i < innerCount; i++) {
      final t = innerCount == 1 ? 0.0 : i / (innerCount - 1);
      final deg = innerStart + t * innerSpan;
      final major = i % 6 == 0;
      final mid = !major && i % 2 == 0;
      final len = major ? 12.0 : mid ? 7.0 : 4.5;
      final a = deg * math.pi / 180;
      tick
        ..strokeWidth = major ? 1.3 : 1.0
        ..color = Colors.white.withOpacity(major ? 0.75 : mid ? 0.45 : 0.28);
      final p1 = c + Offset(math.cos(a) * innerR, math.sin(a) * innerR);
      final p2 = c + Offset(math.cos(a) * (innerR - len), math.sin(a) * (innerR - len));
      final mx = (p1.dx + p2.dx) / 2;
      final my = (p1.dy + p2.dy) / 2;
      if (mx > c.dx - 10 && mx < c.dx + 100 && my > c.dy - 36 && my < c.dy + 36) continue;
      canvas.drawLine(p1, p2, tick);
    }
    canvas.restore();

    // Labels sit outside the rotating group so they stay readable.
    const labels = <(int, double, double, double)>[
      // n, xFrac, yFrac, fontSize — relative to dial center/radius
      (60, -0.92, -0.02, 18),
      (55, -0.78, -0.72, 13),
      (50, -0.18, -0.92, 14),
      (45, -0.48, -0.58, 12),
      (40, 0.78, -0.62, 14),
      (35, 0.02, 0.55, 12),
      (30, -0.68, 0.38, 13),
      (25, 0.58, 0.78, 12),
      (20, -0.28, 0.95, 12),
      (15, -0.90, 0.78, 12),
    ];
    for (final (n, xf, yf, fs) in labels) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$n',
          style: TextStyle(
            color: Colors.white.withOpacity(n == 60 ? 0.95 : 0.78),
            fontSize: fs,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = c + Offset(xf * r, yf * r);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _AuraDialPainter old) => old.turn != turn;
}
