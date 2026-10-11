/// Tablet layout. A phone is unchanged.
///
/// On a tablet the page is not one stretched column. Sections keep a phone
/// width and sit in two or three columns, so the width is used by the real
/// sections instead of making every section bigger.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Material's tablet breakpoint: shortest side, so a landscape phone stays
/// a phone.
bool nwsbTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

/// One section inside [TabletBoard].
class TabletPiece extends StatelessWidget {
  const TabletPiece({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class TabletBoard extends StatelessWidget {
  const TabletBoard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth.isFinite && box.maxWidth > 0
          ? box.maxWidth
          : MediaQuery.sizeOf(context).width;
      const gap = 16.0;
      const minCell = 332.0;
      const maxCell = 420.0;
      var cols = 1;
      if (width >= minCell * 3 + gap * 2) {
        cols = 3;
      } else if (width >= minCell * 2 + gap) {
        cols = 2;
      }
      final raw = (width - gap * (cols - 1)) / cols;
      final cellW = math.min(maxCell, cols == 1 ? width : raw);
      final gridW = cols == 1 ? cellW : cellW * cols + gap * (cols - 1);

      final pieces = <Widget>[
        for (final w in children)
          if (!_blank(w)) w,
      ];
      if (pieces.isEmpty) return const SizedBox.shrink();

      final mq = MediaQuery.of(context);
      Widget cell(Widget w) {
        return SizedBox(
          width: cellW,
          child: MediaQuery(
            data: mq.copyWith(size: Size(cellW, mq.size.height)),
            child: w,
          ),
        );
      }

      final rows = <Widget>[];
      for (var i = 0; i < pieces.length; i += cols) {
        final slice = pieces.skip(i).take(cols).toList();
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < slice.length; c++) ...[
                if (c > 0) const SizedBox(width: gap),
                cell(slice[c]),
              ],
            ],
          ),
        ));
      }

      return Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: math.min(gridW, width),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      );
    });
  }
}

bool _blank(Widget w) {
  final child = w is TabletPiece ? w.child : w;
  if (child is SizedBox && child.child == null) {
    final h = child.height ?? 0;
    final ww = child.width ?? 0;
    return h <= 28 && ww <= 1;
  }
  if (child is Padding && child.child != null) return _blank(child.child!);
  return false;
}
