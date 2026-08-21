/// Clock player settings — live local time, moving second ring, swipe up.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings.dart';

class PlayerDial extends StatefulWidget {
  const PlayerDial({
    super.key,
    required this.word,
    this.playing = false,
    this.onPlay,
    this.onClose,
  });
  final String word;
  final bool playing;
  final VoidCallback? onPlay;
  final VoidCallback? onClose;

  @override
  State<PlayerDial> createState() => _PlayerDialState();
}

class _PlayerDialState extends State<PlayerDial> {
  Timer? _tick;
  DateTime _now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  bool _expanded = false;
  bool _bass = false;
  bool _download = false;
  int _crossfade = 5;
  int _sleep = 0;
  String _view = 'CLASSIC';

  Settings get s => Settings.instance;

  @override
  void initState() {
    super.initState();
    s.addListener(_on);
    _tick = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    s.removeListener(_on);
    super.dispose();
  }

  void _on() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final hh = h.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    final ap = _now.hour >= 12 ? 'PM' : 'AM';
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    const days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    final date = '${_now.day.toString().padLeft(2, '0')} ${months[_now.month - 1]} ${_now.year}';
    final weekday = days[_now.weekday - 1];
    final sweep = (_now.second + _now.millisecond / 1000) * 6;
    final speed = s.speed == 1 ? 'NORMAL' : '${s.speed.toStringAsFixed(2)}×';
    final eq = s.eq == 'flat' ? 'NORMAL' : s.eq.toUpperCase();

    return ColoredBox(
      color: const Color(0xFF1B1E27),
      child: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: (d) {
            if (d.delta.dy < -6) setState(() => _expanded = true);
            if (d.delta.dy > 6) setState(() => _expanded = false);
          },
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: widget.onClose ?? () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              if (!_expanded)
                SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      Positioned(
                        left: -140,
                        top: -40,
                        width: 460,
                        height: 460,
                        child: CustomPaint(painter: _ClockPainter(sweep)),
                      ),
                      Positioned(
                        left: 20,
                        top: 118,
                        right: 16,
                        child: Row(
                          children: [
                            Text(hh, style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w500, height: 0.9, fontFeatures: [FontFeature.tabularFigures()])),
                            const SizedBox(width: 10),
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: Colors.white70, width: 1.4),
                              ),
                              child: Row(
                                children: [
                                  Text(mm, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])),
                                  const SizedBox(width: 8),
                                  Container(width: 1, height: 16, color: Colors.white38),
                                  const SizedBox(width: 8),
                                  Text(ap, style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(date, style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 2.4)),
                                const SizedBox(height: 8),
                                Container(width: 88, height: 1, color: Colors.white24),
                                const SizedBox(height: 8),
                                Text(weekday, style: const TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 2.4)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(22, _expanded ? 8 : 6, 22, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MUSIC PLAYER SETTINGS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(_expanded ? 1 : 0.55),
                      fontSize: _expanded ? 26 : 11,
                      letterSpacing: _expanded ? 3 : 2.8,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                  children: [
                    _row(Icons.tune, 'EQUALIZER', eq, () {}),
                    _row(Icons.graphic_eq, 'AUDIO QUALITY', s.qualityHigh ? 'HIGH' : 'STANDARD', s.toggleQuality),
                    _row(Icons.speed, 'PLAYBACK SPEED', speed, () {}),
                    _row(Icons.repeat, 'CROSSFADE', '$_crossfade SEC', () {
                      const xf = [0, 2, 5, 8, 12];
                      setState(() => _crossfade = xf[(xf.indexOf(_crossfade) + 1) % xf.length]);
                    }),
                    _row(Icons.timer_outlined, 'SLEEP TIMER', _sleep == 0 ? 'OFF' : '$_sleep MIN', () {
                      const sl = [0, 5, 15, 30, 45, 60];
                      setState(() => _sleep = sl[(sl.indexOf(_sleep) + 1) % sl.length]);
                    }),
                    _row(Icons.queue_music, 'NOW PLAYING VIEW', _view, () {
                      setState(() => _view = _view == 'CLASSIC' ? 'MINIMAL' : 'CLASSIC');
                    }),
                    if (_expanded) ...[
                      _toggle(Icons.surround_sound, 'BASS BOOST', _bass, () => setState(() => _bass = !_bass)),
                      _toggle(Icons.download, 'DOWNLOAD ONLY', _download, () => setState(() => _download = !_download)),
                      _row(Icons.more_horiz, 'ADDITIONAL SETTINGS', '', () {}),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _expanded ? 'SWIPE DOWN FOR THE CLOCK' : 'SWIPE UP FOR MORE',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0x47FFFFFF), fontSize: 10, letterSpacing: 2.2),
                    ),
                  ],
                ),
              ),
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x14FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: const Color(0xFF0C0E14), borderRadius: BorderRadius.circular(10)),
                          child: Text(widget.word.isEmpty ? 'N' : widget.word[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.word.toUpperCase(), style: const TextStyle(color: Colors.white, letterSpacing: 1.6, fontSize: 12, fontWeight: FontWeight.w600)),
                              const Text('NOWSSB', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 10, letterSpacing: 1.4)),
                            ],
                          ),
                        ),
                        IconButton(onPressed: widget.onPlay, icon: const Icon(Icons.skip_previous, color: Colors.white, size: 20)),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white70)),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: widget.onPlay,
                            icon: Icon(widget.playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
                          ),
                        ),
                        IconButton(onPressed: widget.onPlay, icon: const Icon(Icons.skip_next, color: Colors.white, size: 20)),
                      ],
                    ),
                  ),
                ),
            ],
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
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2))),
            Text(value, style: const TextStyle(color: Color(0x73FFFFFF), fontSize: 11, letterSpacing: 1.6)),
            const Icon(Icons.chevron_right, color: Color(0x73FFFFFF), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _toggle(IconData icon, String label, bool on, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2))),
            Switch.adaptive(value: on, onChanged: (_) => onTap(), activeColor: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.sweep);
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final tick = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      tick
        ..strokeWidth = major ? 1.8 : 1
        ..color = Colors.white.withOpacity(major ? 0.92 : 0.28);
      final a = (i * 6 - 90) * math.pi / 180;
      final i1 = major ? 0.78 : 0.84;
      final i2 = 0.94;
      canvas.drawLine(
        c + Offset(math.cos(a) * r * i1, math.sin(a) * r * i1),
        c + Offset(math.cos(a) * r * i2, math.sin(a) * r * i2),
        tick,
      );
    }
    const labels = [15, 20, 25, 30, 35, 40, 45, 50, 55, 60];
    for (final n in labels) {
      final a = (n * 6 - 90) * math.pi / 180;
      final tp = TextPainter(
        text: TextSpan(
          text: '$n',
          style: TextStyle(
            color: Colors.white.withOpacity(n % 15 == 0 || n == 60 ? 0.95 : 0.62),
            fontSize: n % 15 == 0 || n == 60 ? 14 : 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = c + Offset(math.cos(a) * r * 0.62, math.sin(a) * r * 0.62);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
    final handA = (sweep - 90) * math.pi / 180;
    final hand = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, c + Offset(math.cos(handA) * r * 0.82, math.sin(handA) * r * 0.82), hand);
    canvas.drawCircle(c, 2.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) => old.sweep != sweep;
}
