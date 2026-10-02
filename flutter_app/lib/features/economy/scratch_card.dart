/// A NowssB scratch coupon. The foil is painted here: black, white, gold.
/// The disc on it is the app logo. No borrowed scratch artwork.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/nwsb_coin_fly.dart';

class NwsbScratchCard extends StatefulWidget {
  const NwsbScratchCard({
    super.key,
    required this.prize,
    required this.onCleared,
    this.height = 168,
  });

  final Widget prize;
  final VoidCallback onCleared;
  final double height;

  @override
  State<NwsbScratchCard> createState() => _NwsbScratchCardState();
}

class _NwsbScratchCardState extends State<NwsbScratchCard> {
  final List<Offset> _cuts = [];
  var _opened = false;

  void _add(Offset point) {
    setState(() => _cuts.add(point));
    if (_cuts.length % 8 == 0) HapticFeedback.selectionClick();
    if (!_opened && _cuts.length > 36) _finish();
  }

  void _finish() {
    if (_opened) return;
    _opened = true;
    HapticFeedback.mediumImpact();
    widget.onCleared();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _add(d.localPosition),
      onPanUpdate: (d) => _add(d.localPosition),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF0A0A0A)),
              Center(child: widget.prize),
              if (!_opened)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _FoilPainter(_cuts),
                    child: const SizedBox.expand(),
                  ),
                ),
              if (!_opened)
                const IgnorePointer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Logo(),
                      SizedBox(height: 8),
                      Text(
                        'SCRATCH TO REVEAL',
                        style: TextStyle(
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_opened)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Center(
                    child: TextButton(
                      onPressed: _finish,
                      child: const Text(
                        'REVEAL FOR ME',
                        style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w800, letterSpacing: 1.1, fontSize: 11),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
        child: Image.asset(
          NwsbCoinFly.disc,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Text(
            'N',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 22),
          ),
        ),
      ),
    );
  }
}

class _FoilPainter extends CustomPainter {
  _FoilPainter(this.cuts);
  final List<Offset> cuts;

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
    final erase = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 42
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < cuts.length; i++) {
      canvas.drawLine(cuts[i - 1], cuts[i], erase);
    }
    for (final cut in cuts) {
      canvas.drawCircle(cut, 22, erase);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FoilPainter old) => old.cuts.length != cuts.length;
}
