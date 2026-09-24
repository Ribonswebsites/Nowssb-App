/// 3×3 colour grid of the portraits.
///
/// Sits under the horizontal routine row. Fashion wraps it in glass,
/// Normal in neumorphism. A drawn mark sits on each cell, with a short
/// rule between the cells. Scrolling the home tilts the grid.
library;

import 'package:flutter/material.dart';

import 'glass_wrap.dart';
import 'home_skin.dart';
import 'neumorphic.dart';
import 'nwsb_icon.dart';

class PromoColorGrid extends StatefulWidget {
  const PromoColorGrid({super.key, required this.onOpen});

  final void Function(String id) onOpen;

  @override
  State<PromoColorGrid> createState() => _PromoColorGridState();
}

class _Cell {
  const _Cell(this.id, this.label, this.color, this.art, this.mark);
  final String id;
  final String label;
  final Color color;
  final String art;
  final String mark;
}

const _cells = <_Cell>[
  _Cell('practice', 'Practice', Color(0xFFE07A32), 'assets/banners/promo/pose-01.png', NwsbMarks.play24),
  _Cell('library', 'Library', Color(0xFF7C4DFF), 'assets/banners/promo/pose-02.png', NwsbMarks.sound),
  _Cell('store', 'Store', Color(0xFF2EC4B6), 'assets/banners/promo/pose-03.png', NwsbMarks.bag),
  _Cell('reader', 'Reader', Color(0xFFE85D9A), 'assets/banners/promo/pose-04.png', NwsbMarks.reader),
  _Cell('healing', 'Healing', Color(0xFF3D8BDB), 'assets/banners/promo/pose-05.png', NwsbMarks.wishlist),
  _Cell('subscription', 'Subscribe', Color(0xFFD4A017), 'assets/banners/promo/pose-06.png', NwsbMarks.crown),
  _Cell('player', 'Player', Color(0xFF27AE60), 'assets/banners/promo/pose-07.png', NwsbMarks.play),
  _Cell('progress', 'Progress', Color(0xFF9B59B6), 'assets/banners/promo/pose-08.png', NwsbMarks.bars),
  _Cell('quotes', 'Quotes', Color(0xFFE67E22), 'assets/banners/promo/pose-09.png', NwsbMarks.word),
];

class _PromoColorGridState extends State<PromoColorGrid> {
  ScrollPosition? _pos;
  double _shift = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next == _pos) return;
    _pos?.removeListener(_onScroll);
    _pos = next;
    _pos?.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final dy = box.localToGlobal(Offset.zero).dy;
    final shift = ((360 - dy) / 700).clamp(-1.0, 1.0);
    if ((shift - _shift).abs() < 0.01) return;
    setState(() => _shift = shift);
  }

  @override
  void dispose() {
    _pos?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fashion = HomeSkinScope.of(context) == HomeSkin.fashion;
    final ink = fashion ? Colors.white : const Color(0xFF2B2D33);
    final rule = fashion ? const Color(0x66FFFFFF) : const Color(0x552B2D33);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Open a door',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink),
          ),
        ),
        for (var r = 0; r < 3; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var c = 0; c < 3; c++) ...[
                  if (c > 0)
                    SizedBox(
                      width: 14,
                      child: Center(
                        child: Container(width: 1, height: 36, color: rule),
                      ),
                    ),
                  Expanded(child: _tile(_cells[r * 3 + c], r)),
                ],
              ],
            ),
          ),
      ],
    );
    if (fashion) {
      return GlassWrap(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
        child: body,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: NeuCard(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
        radius: 22,
        elevation: NwsbElevation.md,
        child: body,
      ),
    );
  }

  Widget _tile(_Cell cell, int row) {
    final tilt = Matrix4.identity()
      ..setEntry(3, 2, 0.002)
      ..rotateX(_shift * 0.22)
      ..translateByDouble(0, _shift * (8 + row * 6), 0, 1);
    return GestureDetector(
      onTap: () => widget.onOpen(cell.id),
      child: AspectRatio(
        aspectRatio: 1,
        child: Transform(
          alignment: Alignment.center,
          transform: tilt,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: cell.color,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 26, 2, 20),
                    child: Image.asset(
                      cell.art,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: NwsbIcon(cell.mark, size: 16, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 6,
                    child: Text(
                      cell.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
