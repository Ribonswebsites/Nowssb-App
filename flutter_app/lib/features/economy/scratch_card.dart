/// A NowssB scratch coupon. The foil is painted here: black, white, gold.
/// The disc on it is the app logo. No borrowed scratch artwork.
library;

import 'package:flutter/material.dart';

import '../../widgets/nwsb_coin_fly.dart';

class NwsbScratchCard extends StatefulWidget {
  const NwsbScratchCard({
    super.key,
    required this.prize,
    required this.onCleared,
  });

  final Widget prize;
  final VoidCallback onCleared;

  @override
  State<NwsbScratchCard> createState() => _NwsbScratchCardState();
}

class _NwsbScratchCardState extends State<NwsbScratchCard> {
  final List<Offset> _cuts = [];
  var _opened = false;

  void _add(Offset point) {
    setState(() => _cuts.add(point));
    if (!_opened && _cuts.length > 36) {
      _opened = true;
      widget.onCleared();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _add(d.localPosition),
      onPanUpdate: (d) => _add(d.localPosition),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF0A0A0A)),
              Center(child: widget.prize),
              if (!_opened)
                CustomPaint(
                  painter: _FoilPainter(_cuts),
                  child: const SizedBox.expand(),
                ),
              if (!_opened)
                IgnorePointer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _Logo(),
                      const SizedBox(height: 8),
                      Text(
                        'SCRATCH',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
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
      canvas.drawCircle(cut, 8, Paint()..color = const Color(0xFF8A6A22));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FoilPainter old) => old.cuts.length != cuts.length;
}
