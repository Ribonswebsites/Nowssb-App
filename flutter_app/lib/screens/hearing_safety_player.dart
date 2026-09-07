/// Auris-inspired hearing-safety expanded player (NowssB branded).
///
/// Quiet → Loud → Danger tiers driven by estimated dB from the volume
/// slider. NIOSH-ish safe-listening time: 85 dB / 8h, +3 dB halves time.
library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/playback_session.dart';
import '../theme/tokens.dart';

class HearingSafetyPlayerScreen extends StatefulWidget {
  const HearingSafetyPlayerScreen({super.key});

  @override
  State<HearingSafetyPlayerScreen> createState() => _HearingSafetyPlayerScreenState();
}

class _HearingSafetyPlayerScreenState extends State<HearingSafetyPlayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _eq;
  late final AnimationController _dangerPulse;

  @override
  void initState() {
    super.initState();
    PlaybackSession.instance.expand();
    _eq = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _dangerPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    PlaybackSession.instance.addListener(_onSession);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncDangerAnim());
  }

  void _onSession() {
    if (!mounted) return;
    setState(() {});
    _syncDangerAnim();
  }

  void _syncDangerAnim() {
    final danger = PlaybackSession.instance.tier == HearingTier.danger;
    if (danger) {
      if (!_dangerPulse.isAnimating) _dangerPulse.repeat(reverse: true);
    } else {
      _dangerPulse.stop();
      _dangerPulse.value = 0;
    }
  }

  @override
  void dispose() {
    PlaybackSession.instance.removeListener(_onSession);
    _eq.dispose();
    _dangerPulse.dispose();
    // Leaving expanded UI returns to the floating pill if session still live.
    if (PlaybackSession.instance.active) {
      PlaybackSession.instance.minimize();
    }
    super.dispose();
  }

  Color get _accent {
    switch (PlaybackSession.instance.tier) {
      case HearingTier.quiet:
        return const Color(0xFF3DDC97);
      case HearingTier.loud:
        return const Color(0xFFFF8A3D);
      case HearingTier.danger:
        return const Color(0xFFFF3B4E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = PlaybackSession.instance;
    if (!session.active || session.word == null) {
      return Scaffold(
        backgroundColor: NwsbColors.deep,
        appBar: AppBar(backgroundColor: NwsbColors.deep, foregroundColor: Colors.white),
        body: const Center(
          child: Text('No active session', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final accent = _accent;
    final art = session.artwork;
    final word = session.word!;
    final dangerShake = session.tier == HearingTier.danger;

    return Scaffold(
        backgroundColor: const Color(0xFF050507),
        body: AnimatedBuilder(
          animation: _dangerPulse,
          builder: (context, child) {
            final shake = dangerShake ? math.sin(_dangerPulse.value * math.pi * 2) * 2.2 : 0.0;
            final glow = dangerShake ? 0.18 + _dangerPulse.value * 0.22 : 0.0;
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF050507),
                boxShadow: dangerShake
                    ? [BoxShadow(color: accent.withOpacity(glow), blurRadius: 40, spreadRadius: 8)]
                    : null,
              ),
              child: Transform.translate(offset: Offset(shake, 0), child: child),
            );
          },
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                      ),
                      const Expanded(
                        child: Text(
                          'NOWSSB',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: const Color(0x44FFFFFF)),
                        ),
                        child: const Text(
                          'HI-RES',
                          style: TextStyle(color: Color(0xFFCFCFD2), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 72,
                              height: 72,
                              child: art.isEmpty
                                  ? const ColoredBox(color: Color(0xFF1A1A1E))
                                  : art.startsWith('http')
                                      ? Image.network(art, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1A1E)))
                                      : Image.asset(art, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1A1E))),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word.word,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  session.title.isEmpty ? 'NowssB · Practice' : session.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF9A9AA0), fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _EqBars(controller: _eq, playing: session.playing, color: accent),
                                    const SizedBox(width: 8),
                                    Text(
                                      session.playing ? 'PLAYING NOW' : 'PAUSED',
                                      style: TextStyle(color: accent.withOpacity(.9), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _Transport(session: session, accent: accent),
                      const SizedBox(height: 22),
                      _HearingSafetyCard(session: session, accent: accent),
                      const SizedBox(height: 18),
                      _DoseBar(session: session, accent: accent),
                      const SizedBox(height: 16),
                      _VolumeDangerSlider(session: session, accent: accent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _Transport extends StatelessWidget {
  const _Transport({required this.session, required this.accent});
  final PlaybackSession session;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => session.setLoop(!session.loop),
          icon: Icon(Icons.shuffle_rounded, color: session.loop ? accent : const Color(0xFF8E8E93)),
        ),
        IconButton(
          onPressed: () => session.previous(),
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 32),
        ),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => session.togglePlay(),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(
                session.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFF111114),
                size: 34,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () => session.next(),
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
        ),
        IconButton(
          onPressed: () => session.setLoop(!session.loop),
          icon: Icon(Icons.repeat_rounded, color: session.loop ? accent : const Color(0xFF8E8E93)),
        ),
      ],
    );
  }
}

class _HearingSafetyCard extends StatelessWidget {
  const _HearingSafetyCard({required this.session, required this.accent});
  final PlaybackSession session;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'HEARING SAFETY',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withOpacity(.14),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: accent.withOpacity(.45)),
              ),
              child: Text(
                '• ${session.tierLabel}',
                style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 148,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x22FFFFFF)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF121218),
                    Color.lerp(const Color(0xFF0C0C10), accent, 0.12)!,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 18,
                    top: 16,
                    child: Text(
                      session.sceneLabel,
                      style: TextStyle(color: accent.withOpacity(.85), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 18,
                    child: Text(
                      '${session.db.round()} dB',
                      style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: -1.2, height: 1),
                    ),
                  ),
                  Positioned(
                    right: 22,
                    top: 28,
                    bottom: 18,
                    child: _SceneIcon(tier: session.tier, accent: accent),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          session.safeListenHeadline,
          style: const TextStyle(color: Color(0xFF9A9AA0), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          session.safeListenLabel,
          style: TextStyle(color: accent, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.05),
        ),
        const SizedBox(height: 6),
        Text(
          session.safeListenSubcopy,
          style: const TextStyle(color: Color(0xFF7A7A80), fontSize: 12, height: 1.35),
        ),
      ],
    );
  }
}

class _SceneIcon extends StatelessWidget {
  const _SceneIcon({required this.tier, required this.accent});
  final HearingTier tier;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    switch (tier) {
      case HearingTier.quiet:
        icon = Icons.headphones_rounded;
        break;
      case HearingTier.loud:
        icon = Icons.speaker_group_rounded;
        break;
      case HearingTier.danger:
        icon = Icons.tornado_rounded;
        break;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(.12),
            boxShadow: [BoxShadow(color: accent.withOpacity(.28), blurRadius: 24)],
          ),
          child: Icon(icon, color: accent, size: 44),
        ),
      ],
    );
  }
}

class _DoseBar extends StatelessWidget {
  const _DoseBar({required this.session, required this.accent});
  final PlaybackSession session;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = session.dosePercent / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Color(0xFF9A9AA0), fontSize: 12),
            children: [
              const TextSpan(text: "Today's dose "),
              TextSpan(
                text: '${session.dosePercent.round()}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0x22FFFFFF)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: p.clamp(0.0, 1.0),
                  child: ColoredBox(color: accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VolumeDangerSlider extends StatelessWidget {
  const _VolumeDangerSlider({required this.session, required this.accent});
  final PlaybackSession session;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dangerT = ((PlaybackSession.dangerDb - PlaybackSession.minDb) /
            (PlaybackSession.maxDb - PlaybackSession.minDb))
        .clamp(0.0, 1.0);
    return Row(
      children: [
        Icon(Icons.volume_up_rounded, color: accent.withOpacity(.85), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final dangerX = w * dangerT;
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: accent,
                  inactiveTrackColor: const Color(0x33FFFFFF),
                  thumbColor: accent,
                  overlayColor: accent.withOpacity(.2),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: dangerX,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0x00FF3B4E),
                                Color(0x66FF3B4E),
                                accent.withOpacity(.55),
                              ],
                            ),
                          ),
                          child: CustomPaint(painter: _HatchPainter(color: const Color(0x88FF3B4E))),
                        ),
                      ),
                    ),
                    Positioned(
                      left: dangerX - 0.5,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 1, height: 14, color: const Color(0xAAFFFFFF)),
                            const SizedBox(height: 2),
                            const Text('85 dB', style: TextStyle(color: Color(0xFFB0B0B5), fontSize: 8, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    Slider(
                      min: PlaybackSession.minDb,
                      max: PlaybackSession.maxDb,
                      value: session.db.clamp(PlaybackSession.minDb, PlaybackSession.maxDb),
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        session.setDb(v);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${session.volumePercent.round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _HatchPainter extends CustomPainter {
  _HatchPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (var x = -size.height; x < size.width + size.height; x += 6) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter oldDelegate) => oldDelegate.color != color;
}

class _EqBars extends StatelessWidget {
  const _EqBars({required this.controller, required this.playing, required this.color});
  final AnimationController controller;
  final bool playing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = playing ? controller.value : 0.15;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final h in [8.0, 14.0, 10.0, 16.0])
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Container(
                  width: 2.5,
                  height: h * (0.45 + t * 0.55) * (playing ? 1 : 0.5),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
              ),
          ],
        );
      },
    );
  }
}
