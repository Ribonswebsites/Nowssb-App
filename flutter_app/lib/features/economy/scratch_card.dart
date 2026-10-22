/// A NowssB scratch coupon. The foil is painted here: black, white, gold.
/// The disc on it is the app logo. No borrowed scratch artwork.
///
/// Real scratch-to-reveal: the finger erases the foil, gold flakes fall
/// from the finger, coverage is measured on a grid and the card opens by
/// itself past [revealAt]. On open the foil fades away, the rarity glows
/// and Epic+ throws confetti. The prize itself is decided by the server
/// (the card is sealed when it is issued); this widget only uncovers it.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/nwsb_coin_fly.dart';
import 'reward_fx.dart';
import '../../admin/template/editable.dart';

class NwsbScratchCard extends StatefulWidget {
  const NwsbScratchCard({
    super.key,
    required this.prize,
    required this.onCleared,
    this.height = 168,
    this.rarity,
    this.onFirstTouch,
    this.revealAt = 0.55,
    this.enabled = true,
    this.oddsNote,
  });

  final Widget prize;
  final VoidCallback onCleared;
  final double height;

  /// Rarity of the sealed card (shown as the frame glow once open).
  final String? rarity;

  /// Called on the first scratch (e.g. to ask the server to open the seal).
  final VoidCallback? onFirstTouch;
  final double revealAt;
  final bool enabled;

  /// Short odds line shown under the "i" button.
  final String? oddsNote;

  @override
  State<NwsbScratchCard> createState() => _NwsbScratchCardState();
}

class _NwsbScratchCardState extends State<NwsbScratchCard> with TickerProviderStateMixin {
  static const _cols = 24, _rows = 12;
  final List<List<Offset>> _strokes = [];
  final Set<int> _cells = {};
  final List<_Flake> _flakes = [];
  final _rnd = math.Random();
  late final AnimationController _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..addListener(_tick);
  late final AnimationController _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  var _opened = false;
  var _touched = false;
  Size _size = Size.zero;

  void _tick() {
    if (_flakes.isEmpty) return;
    setState(() {
      for (final f in _flakes) {
        f.vy += 0.6;
        f.p += Offset(f.vx, f.vy);
        f.life -= 0.035;
      }
      _flakes.removeWhere((f) => f.life <= 0);
    });
    if (_flakes.isEmpty) _ticker.stop();
  }

  void _start(Offset p) {
    if (!widget.enabled || _opened) return;
    if (!_touched) {
      _touched = true;
      widget.onFirstTouch?.call();
    }
    _strokes.add([p]);
    _mark(p);
  }

  void _add(Offset p) {
    if (!widget.enabled || _opened) return;
    if (_strokes.isEmpty) _strokes.add([]);
    setState(() => _strokes.last.add(p));
    _mark(p);
  }

  void _mark(Offset p) {
    if (_size.isEmpty) return;
    const r = 22.0;
    final cw = _size.width / _cols, ch = _size.height / _rows;
    final before = _cells.length;
    for (var cx = ((p.dx - r) / cw).floor(); cx <= ((p.dx + r) / cw).floor(); cx++) {
      for (var cy = ((p.dy - r) / ch).floor(); cy <= ((p.dy + r) / ch).floor(); cy++) {
        if (cx < 0 || cy < 0 || cx >= _cols || cy >= _rows) continue;
        _cells.add(cy * _cols + cx);
      }
    }
    if (_cells.length ~/ 12 != before ~/ 12) HapticFeedback.selectionClick();
    for (var i = 0; i < 3; i++) {
      _flakes.add(_Flake(p, (_rnd.nextDouble() - 0.5) * 3, -_rnd.nextDouble() * 2, 1.5 + _rnd.nextDouble() * 2.5));
    }
    if (!_ticker.isAnimating) _ticker.repeat();
    if (_cells.length / (_cols * _rows) >= widget.revealAt) _finish();
  }

  void _finish() {
    if (_opened) return;
    _opened = true;
    RewardHaptics.rarity(widget.rarity);
    _fade.forward();
    widget.onCleared();
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _showOdds() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const EditableLabel('scratch_card.NwsbScratchCard', 'Odds', style: TextStyle(color: Colors.white)),
        content: Text(widget.oddsNote ?? 'Every card is sealed by the server when it is issued. The odds for each card are listed in Coupons → Rules and Odds.', style: const TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const EditableLabel('scratch_card.NwsbScratchCard', 'OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.rarity == null ? null : rarityColor(widget.rarity);
    return LayoutBuilder(builder: (context, c) {
      _size = Size(c.maxWidth.isFinite ? c.maxWidth : 320, widget.height);
      return GestureDetector(
        onPanStart: (d) => _start(d.localPosition),
        onPanUpdate: (d) => _add(d.localPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: _opened && glow != null ? [BoxShadow(color: glow.withValues(alpha: 0.55), blurRadius: 28, spreadRadius: 1)] : null,
            border: _opened && glow != null ? Border.all(color: glow, width: 1.4) : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFF0A0A0A)),
                  Center(
                    child: AnimatedScale(
                      scale: _opened ? 1 : 0.92,
                      duration: const Duration(milliseconds: 480),
                      curve: Curves.easeOutBack,
                      child: widget.prize,
                    ),
                  ),
                  if (_opened && rarityParty(widget.rarity)) Positioned.fill(child: ConfettiBurst(color: glow ?? NwsbColorsFallback.gold, count: 60)),
                  FadeTransition(
                    opacity: ReverseAnimation(_fade),
                    child: IgnorePointer(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(painter: _FoilPainter(_strokes, _cells.length)),
                          if (!_touched)
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _Logo(),
                                SizedBox(height: 8),
                                EditableLabel('scratch_card.NwsbScratchCard',
                                  'SCRATCH TO REVEAL',
                                  style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w800, letterSpacing: 1.4, fontSize: 12),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  IgnorePointer(child: CustomPaint(painter: _FlakePainter(_flakes))),
                  if (!_opened)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 6,
                      child: Center(
                        child: TextButton(
                          onPressed: widget.enabled
                              ? () {
                                  if (!_touched) {
                                    _touched = true;
                                    widget.onFirstTouch?.call();
                                  }
                                  _finish();
                                }
                              : null,
                          child: const EditableLabel('scratch_card.NwsbScratchCard',
                            'REVEAL FOR ME',
                            style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w800, letterSpacing: 1.1, fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _showOdds,
                      icon: Icon(Icons.info_outline, size: 18, color: _opened ? Colors.white54 : const Color(0xFF111111)),
                      tooltip: 'Odds',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class NwsbColorsFallback {
  static const gold = Color(0xFFC8A96E);
}

class _Flake {
  _Flake(this.p, this.vx, this.vy, this.size);
  Offset p;
  double vx, vy, size;
  double life = 1;
}

class _FlakePainter extends CustomPainter {
  _FlakePainter(this.flakes);
  final List<_Flake> flakes;
  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flakes) {
      canvas.drawCircle(f.p, f.size, Paint()..color = const Color(0xFFE4C56A).withValues(alpha: f.life.clamp(0.0, 1.0)));
    }
  }

  @override
  bool shouldRepaint(_FlakePainter old) => true;
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: ClipOval(
        child: EditableImage.asset(
          NwsbCoinFly.disc,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const EditableLabel('scratch_card.Logo',
            'N',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 22),
          ),
          slot: 'scratch_card.Logo',
        ),
      ),
    );
  }
}

class _FoilPainter extends CustomPainter {
  _FoilPainter(this.strokes, this.version);
  final List<List<Offset>> strokes;
  final int version;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    final foil = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF6E7B2), Color(0xFFE4C56A), Color(0xFF8A6A22), Color(0xFFF6E7B2)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, foil);
    // fine sheen lines so it reads as foil
    final sheen = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), sheen);
    }
    final erase = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 44
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, erase);
      canvas.drawCircle(s.first, 22, erase..style = PaintingStyle.fill);
      erase.style = PaintingStyle.stroke;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FoilPainter old) => true;
}
