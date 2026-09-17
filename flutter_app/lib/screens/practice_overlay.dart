/// Glassmorphism practice lab opened from the NowssB player.
///
/// This is intentionally a sheet rather than a separate route so the player
/// remains visible underneath a real-time blur while the user drills one word.

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/models.dart';

class PracticeLabSheet extends StatefulWidget {
  const PracticeLabSheet({
    super.key,
    required this.word,
    required this.onSpeak,
    required this.onClose,
    this.accent = const Color(0xFFE8D5A3),
  });

  final Word word;
  final Future<void> Function() onSpeak;
  final VoidCallback onClose;
  final Color accent;

  @override
  State<PracticeLabSheet> createState() => _PracticeLabSheetState();
}

class _PracticeLabSheetState extends State<PracticeLabSheet>
    with TickerProviderStateMixin {
  late final AnimationController _ripple;
  late final AnimationController _entry;
  var _activePart = 0;
  var _showScience = true;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _ripple.dispose();
    _entry.dispose();
    super.dispose();
  }

  List<WordPart> get _parts => widget.word.parts;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xF20A0B0E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            border: Border.all(color: Colors.white.withOpacity(.14)),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(.12),
                blurRadius: 50,
                spreadRadius: -8,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: AnimatedBuilder(
              animation: _entry,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, 28 * (1 - _entry.value)),
                child: Opacity(opacity: _entry.value, child: child),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18, 12, 18, 24 + bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.24),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _topBar(),
                    const SizedBox(height: 12),
                    _hero(),
                    const SizedBox(height: 14),
                    _wordIdentity(),
                    const SizedBox(height: 14),
                    _partBreakdown(),
                    const SizedBox(height: 14),
                    _scienceCard(),
                    const SizedBox(height: 14),
                    _practiceControls(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRACTICE LAB',
                style: TextStyle(
                  color: Color(0xFF9C9CA2),
                  fontSize: 10,
                  letterSpacing: 2.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Sound • Breath • Meaning',
                style: TextStyle(
                  color: Color(0xFFF5F5F7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _CircleButton(icon: Icons.close_rounded, onTap: widget.onClose),
      ],
    );
  }

  Widget _hero() {
    return Container(
      height: 246,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18212A), Color(0xFF07080B)],
        ),
        border: Border.all(color: Colors.white.withOpacity(.13)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AmbientLinesPainter(progress: _ripple.value),
            ),
          ),
          AnimatedBuilder(
            animation: _ripple,
            builder: (context, _) => CustomPaint(
              size: const Size(230, 230),
              painter: _RipplePainter(progress: _ripple.value),
              child: SizedBox(
                width: 126,
                height: 126,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: widget.accent.withOpacity(.20),
                        blurRadius: 34,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: SvgPicture.asset(
                      'assets/icons/icon_01.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF111217),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 16,
            child: _GlassLabel(
              icon: Icons.graphic_eq_rounded,
              text: 'LIVE RIPPLE',
            ),
          ),
          Positioned(
            right: 18,
            bottom: 16,
            child: _GlassLabel(
              icon: Icons.waves_rounded,
              text: '${_parts.length} PARTS',
            ),
          ),
        ],
      ),
    );
  }

  Widget _wordIdentity() {
    final meaning = widget.word.meaning.trim();
    final organ = widget.word.organ.trim();
    final deva = widget.word.deva.trim();
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  widget.word.word,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.2,
                    height: 1,
                  ),
                ),
              ),
              if (deva.isNotEmpty)
                Text(
                  deva,
                  style: TextStyle(
                    color: widget.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (organ.isNotEmpty) _MetaPill(label: organ.toUpperCase()),
              if (organ.isNotEmpty && meaning.isNotEmpty)
                const SizedBox(width: 8),
              if (meaning.isNotEmpty)
                Expanded(
                  child: Text(
                    meaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xB8FFFFFF),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _partBreakdown() {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            label: 'WORD BREAKDOWN',
            icon: Icons.account_tree_rounded,
          ),
          const SizedBox(height: 12),
          if (_parts.isEmpty)
            const Text(
              'No syllable data available for this word.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _parts.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _activePart = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: i == _activePart
                            ? Colors.white
                            : Colors.white.withOpacity(.055),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: i == _activePart
                              ? Colors.white
                              : Colors.white.withOpacity(.10),
                        ),
                      ),
                      child: Text(
                        _parts[i].roman.isNotEmpty
                            ? _parts[i].roman
                            : _parts[i].deva,
                        style: TextStyle(
                          color: i == _activePart ? Colors.black : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          if (_parts.isNotEmpty) ...[
            const SizedBox(height: 14),
            _detailRow('ACTIVE SOUND', _displayPart(_parts[_activePart])),
            const SizedBox(height: 8),
            _detailRow(
              'HOLD',
              '${_parts[_activePart].hold.toStringAsFixed(1)} sec',
            ),
          ],
        ],
      ),
    );
  }

  String _displayPart(WordPart part) {
    if (part.roman.isNotEmpty && part.deva.isNotEmpty) {
      return '${part.roman}  ·  ${part.deva}';
    }
    return part.roman.isNotEmpty ? part.roman : part.deva;
  }

  Widget _scienceCard() {
    final tip = widget.word.tip.trim();
    return _GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showScience = !_showScience),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accent.withOpacity(.12),
                      border: Border.all(color: widget.accent.withOpacity(.28)),
                    ),
                    child: Icon(
                      Icons.spa_rounded,
                      color: widget.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHY THIS SOUND',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Pronunciation guidance & body focus',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showScience
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          if (_showScience)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0x14FFFFFF), height: 1),
                  const SizedBox(height: 12),
                  Text(
                    tip.isEmpty
                        ? 'Say the sound gently on the exhale. Let the final resonance settle before moving to the next part.'
                        : tip,
                    style: const TextStyle(
                      color: Color(0xBFFFFFFF),
                      fontSize: 12,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _practiceControls() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.replay_rounded,
            label: 'REPLAY',
            onTap: () => widget.onSpeak(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _ActionButton(
            icon: Icons.graphic_eq_rounded,
            label: 'PRACTICE SOUND',
            filled: true,
            onTap: () => widget.onSpeak(),
          ),
        ),
      ],
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide * .29;
    for (var i = 0; i < 6; i++) {
      final t = (progress + i / 6) % 1.0;
      final radius = base + t * size.shortestSide * .40;
      final opacity = (1 - t) * .25;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + (1 - t) * 1.6
        ..color = Colors.white.withOpacity(opacity);
      canvas.drawOval(
        Rect.fromCenter(
          center: c,
          width: radius * 2.0,
          height: radius * (1.0 + .18 * math.sin(t * math.pi)),
        ),
        paint,
      );
    }

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE8F5FF)
          .withOpacity(.18 + .10 * math.sin(progress * math.pi * 2));
    canvas.drawCircle(
      c,
      base * (1.06 + .04 * math.sin(progress * math.pi * 2)),
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AmbientLinesPainter extends CustomPainter {
  const _AmbientLinesPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(.035);
    for (var row = 0; row < 7; row++) {
      final path = Path();
      for (var x = -20.0; x <= size.width + 20; x += 8) {
        final y =
            size.height * (.25 + row * .08) +
            math.sin(x / 38 + progress * math.pi * 2 + row) * (3 + row * .7);
        if (x == -20) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientLinesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.055),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(.105)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(.10)),
      ),
      child: Icon(icon, color: Colors.white70, size: 19),
    ),
  );
}

class _GlassLabel extends StatelessWidget {
  const _GlassLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(.28),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withOpacity(.10)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.07),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withOpacity(.10)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 8.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: Colors.white54),
      const SizedBox(width: 7),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.7,
        ),
      ),
    ],
  );
}

class _detailRow extends StatelessWidget {
  const _detailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 100,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 54,
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.white.withOpacity(.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(filled ? .9 : .12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: filled ? Colors.black : Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.black : Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    ),
  );
}
