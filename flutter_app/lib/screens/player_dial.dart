/// Aura clock dial + preview settings — matches the target mock.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings.dart';
import '../theme/player_aura.dart';
import '../widgets/colored_split_promo_banner.dart';
import 'player_settings.dart';

class PlayerDial extends StatefulWidget {
  const PlayerDial({
    super.key,
    required this.word,
    this.playing = false,
    this.onPlay,
    this.onClose,
    this.onSettings,
    this.onLibrary,
  });
  final String word;
  final bool playing;
  final VoidCallback? onPlay;
  final VoidCallback? onClose;
  final VoidCallback? onSettings;
  final VoidCallback? onLibrary;

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

    return PlayerAuraBackdrop(
      film: kPlayerPageFilm,
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
                      PlayerAuraBackButton(
                        onTap: widget.onClose ?? () => Navigator.maybePop(context),
                      ),
                      const Spacer(),
                      if (widget.onLibrary != null)
                        IconButton(
                          onPressed: widget.onLibrary,
                          tooltip: 'Library',
                          icon: const Icon(Icons.queue_music_outlined, color: Colors.white, size: 22),
                        ),
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
                      final side = math.min(
                        constraints.maxWidth - 8,
                        constraints.maxHeight - 8,
                      );
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: side,
                            height: side * 0.82,
                            child: _GlassCircle(
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
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          hh,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 64,
                                            fontWeight: FontWeight.w200,
                                            height: 0.92,
                                            letterSpacing: -2.0,
                                            fontFeatures: [FontFeature.tabularFigures()],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          height: 36,
                                          padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(99),
                                            border: Border.all(
                                              color: const Color(0xD9F2F2EF),
                                              width: 1.15,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                mm,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 21,
                                                  fontWeight: FontWeight.w400,
                                                  fontFeatures: [FontFeature.tabularFigures()],
                                                ),
                                              ),
                                              const SizedBox(width: 9),
                                              Container(
                                                width: 1,
                                                height: 14,
                                                color: const Color(0x99F2F2EF),
                                              ),
                                              const SizedBox(width: 9),
                                              Text(
                                                ap,
                                                style: const TextStyle(
                                                  color: Color(0xE6FFFFFF),
                                                  fontSize: 11,
                                                  letterSpacing: 1.8,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _GlassDatePill(date: date, weekday: weekday),
                        ],
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
                      const SizedBox(height: 12),
                      ColoredSplitPromoBanner(
                        spec: SplitPromoExtras.at(9),
                        margin: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 8),
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

/// Full circular dial inside the glass wrapper. Date lives below, not in a C-gap.
class _AuraDialPainter extends CustomPainter {
  _AuraDialPainter({required this.turn});
  final double turn;

  static const _labels = <(int, double)>[
    (15, 0),
    (20, 30),
    (25, 60),
    (30, 90),
    (35, 120),
    (40, 150),
    (45, 180),
    (50, 210),
    (55, 240),
    (60, 270),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.5);
    final r = math.min(size.width, size.height) * 0.36;
    final tick = Paint()..strokeCap = StrokeCap.butt;

    bool hitsTime(Offset p) {
      return (p - c).distance < r * 0.42;
    }

    bool hitsLabel(Offset p) {
      for (final (_, deg) in _labels) {
        final a = deg * math.pi / 180;
        final lp = c + Offset(math.cos(a) * (r + 16), math.sin(a) * (r + 16));
        if ((p - lp).distance < 14) return true;
      }
      return false;
    }

    void drawArc({
      required double radius,
      required double startDeg,
      required double spanDeg,
      required int count,
      required int everyMajor,
      required int everyMid,
      required double lenMajor,
      required double lenMid,
      required double lenMin,
      required double opacityScale,
    }) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(turn * 2 * math.pi);
      canvas.translate(-c.dx, -c.dy);
      for (var i = 0; i < count; i++) {
        final t = count == 1 ? 0.0 : i / count;
        final deg = startDeg + t * spanDeg;
        final major = i % everyMajor == 0;
        final mid = !major && i % everyMid == 0;
        final len = major ? lenMajor : mid ? lenMid : lenMin;
        final a = deg * math.pi / 180;
        tick
          ..strokeWidth = major ? 1.45 : 1.05
          ..color = Colors.white.withOpacity((major ? 0.95 : mid ? 0.70 : 0.40) * opacityScale);
        final outer = radius + (major ? 1.5 : 0);
        final p1 = c + Offset(math.cos(a) * outer, math.sin(a) * outer);
        final p2 = c + Offset(math.cos(a) * (outer - len), math.sin(a) * (outer - len));
        final midP = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        if (hitsTime(midP) || hitsLabel(midP)) continue;
        canvas.drawLine(p1, p2, tick);
      }
      canvas.restore();
    }

    drawArc(
      radius: r,
      startDeg: 0,
      spanDeg: 360,
      count: 72,
      everyMajor: 6,
      everyMid: 3,
      lenMajor: 14,
      lenMid: 8,
      lenMin: 4.5,
      opacityScale: 1,
    );
    drawArc(
      radius: r * 0.72,
      startDeg: 0,
      spanDeg: 360,
      count: 36,
      everyMajor: 6,
      everyMid: 2,
      lenMajor: 8,
      lenMid: 5,
      lenMin: 3,
      opacityScale: 0.72,
    );

    for (final (n, deg) in _labels) {
      final a = deg * math.pi / 180;
      final lp = c + Offset(math.cos(a) * (r + 16), math.sin(a) * (r + 16));
      final x = lp.dx.clamp(16.0, size.width - 16.0);
      final y = lp.dy.clamp(16.0, size.height - 16.0);
      final tp = TextPainter(
        text: TextSpan(
          text: '$n',
          style: TextStyle(
            color: Colors.white.withOpacity(n == 60 ? 0.95 : 0.82),
            fontSize: n == 60 ? 16 : 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _AuraDialPainter old) => old.turn != turn;
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x22FFFFFF),
              border: Border.all(color: const Color(0x73FFFFFF), width: 1.2),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassDatePill extends StatelessWidget {
  const _GlassDatePill({required this.date, required this.weekday});
  final String date;
  final String weekday;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x73FFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Container(
                width: 1,
                height: 11,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: const Color(0x73FFFFFF),
              ),
              Text(
                weekday,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 2.8,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
