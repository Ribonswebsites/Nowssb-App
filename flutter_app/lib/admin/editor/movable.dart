/// The + and the folded pill can be dragged out of the way of the page;
/// where they were left is remembered on this phone.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'glass.dart';

/// Preferences keys: where the + and the folded pill were left, as
/// fractions of the screen ("x,y" of the top-left corner).
const kAddSpotKey = 'ui_editor_add_spot';
const kHandleSpotKey = 'ui_editor_handle_spot';

Future<Offset?> loadSpot(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    final parts = raw?.split(',');
    if (parts == null || parts.length != 2) return null;
    final x = double.tryParse(parts[0]), y = double.tryParse(parts[1]);
    if (x == null || y == null) return null;
    return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  } catch (_) {
    return null;
  }
}

Future<void> saveSpot(String key, Offset frac) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, '${frac.dx.toStringAsFixed(4)},${frac.dy.toStringAsFixed(4)}');
  } catch (_) {}
}

/// Puts [child] (of [size]) at [frac] of the area it fills, or at
/// [initial] until moved; a drag moves it (kept on screen), a tap still
/// reaches the child. Only the child takes touches.
class DraggableSpot extends StatefulWidget {
  const DraggableSpot({
    super.key,
    required this.frac,
    required this.size,
    required this.initial,
    required this.onMoved,
    required this.child,
    this.margin = const EdgeInsets.all(8),
  });

  final Offset? frac;
  final Size size;
  final Offset Function(Size area) initial;
  final ValueChanged<Offset> onMoved;
  final EdgeInsets margin;
  final Widget child;

  @override
  State<DraggableSpot> createState() => _DraggableSpotState();
}

class _DraggableSpotState extends State<DraggableSpot> {
  Offset? _live;
  bool _held = false;

  Offset _clamp(Offset p, Size area) => Offset(
        p.dx.clamp(widget.margin.left, (area.width - widget.size.width - widget.margin.right).clamp(widget.margin.left, double.infinity)),
        p.dy.clamp(widget.margin.top, (area.height - widget.size.height - widget.margin.bottom).clamp(widget.margin.top, double.infinity)),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final area = box.biggest;
        final f = widget.frac;
        final at = _clamp(_live ?? (f == null ? widget.initial(area) : Offset(f.dx * area.width, f.dy * area.height)), area);
        return Stack(children: [
          AnimatedPositioned(
            duration: _held ? Duration.zero : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            left: at.dx,
            top: at.dy,
            width: widget.size.width,
            height: widget.size.height,
            child: GestureDetector(
              onPanStart: (_) {
                bigFeel();
                setState(() {
                  _held = true;
                  _live = at;
                });
              },
              onPanUpdate: (d) => setState(() => _live = _clamp((_live ?? at) + d.delta, area)),
              onPanEnd: (_) {
                final p = _live ?? at;
                actFeel();
                setState(() {
                  _held = false;
                  _live = null;
                });
                widget.onMoved(Offset(p.dx / area.width, p.dy / area.height));
              },
              child: AnimatedScale(
                duration: const Duration(milliseconds: 160),
                scale: _held ? 1.12 : 1,
                child: widget.child,
              ),
            ),
          ),
        ]);
      });
}
