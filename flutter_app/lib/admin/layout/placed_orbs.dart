/// Thinking orbs the owner dropped onto a page in the UI Editor.
///
/// Each one belongs to the section it was dropped on and is saved in that
/// section's layout props (`props.orbs`), so it goes through the normal
/// draft → Publish → `ui_layouts` path and shows for everyone at the same
/// spot. x is a fraction of the section's width (so it holds on any phone),
/// y is points from the section's top; both are the orb's centre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

class PlacedOrb {
  const PlacedOrb({
    required this.id,
    required this.orb,
    required this.x,
    required this.y,
    this.size = kDefaultSize,
    this.circle = false,
  });

  static const kDefaultSize = 72.0;
  static const kMinSize = 24.0;
  static const kMaxSize = 420.0;

  final String id;

  /// OrbState name.
  final String orb;
  final double x;
  final double y;
  final double size;

  /// Black disc behind the orb.
  final bool circle;

  OrbState get state => OrbState.values.firstWhere((s) => s.name == orb, orElse: () => OrbState.composing);

  static PlacedOrb? from(dynamic m) {
    if (m is! Map) return null;
    final id = '${m['id'] ?? ''}';
    if (id.isEmpty) return null;
    double d(dynamic v, double f) => v is num ? v.toDouble() : f;
    return PlacedOrb(
      id: id,
      orb: '${m['orb'] ?? OrbState.composing.name}',
      x: d(m['x'], 0.5).clamp(0.0, 1.0),
      y: d(m['y'], 0),
      size: d(m['size'], kDefaultSize).clamp(kMinSize, kMaxSize),
      circle: m['circle'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orb': orb,
        'x': double.parse(x.toStringAsFixed(4)),
        'y': y.roundToDouble(),
        'size': size.roundToDouble(),
        if (circle) 'circle': true,
      };

  PlacedOrb copyWith({String? orb, double? x, double? y, double? size, bool? circle}) => PlacedOrb(
        id: id,
        orb: orb ?? this.orb,
        x: x ?? this.x,
        y: y ?? this.y,
        size: size ?? this.size,
        circle: circle ?? this.circle,
      );

  /// Where it is drawn inside a section of [sectionSize].
  Rect rectIn(Size sectionSize) =>
      Rect.fromCenter(center: Offset(x * sectionSize.width, y), width: size, height: size);
}

/// The orbs saved on a section's props.
List<PlacedOrb> placedOrbsOf(Map<String, dynamic> props) {
  final raw = props['orbs'];
  if (raw is! List) return const [];
  return [
    for (final m in raw)
      if (PlacedOrb.from(m) case final o?) o,
  ];
}

/// [props] patch that saves [orbs] (null removes the key when empty).
Map<String, dynamic> orbsPatch(List<PlacedOrb> orbs) => {'orbs': orbs.isEmpty ? null : [for (final o in orbs) o.toJson()]};

/// One placed orb as it is drawn.
class PlacedOrbView extends StatelessWidget {
  const PlacedOrbView({super.key, required this.orb});
  final PlacedOrb orb;

  @override
  Widget build(BuildContext context) {
    final inner = ThinkingOrb(state: orb.state, size: orb.circle ? orb.size * 0.78 : orb.size, theme: OrbTheme.dark);
    if (!orb.circle) return SizedBox.square(dimension: orb.size, child: Center(child: inner));
    return Container(
      width: orb.size,
      height: orb.size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
      child: inner,
    );
  }
}

/// Draws a section's placed orbs over it. They may hang over its edges.
class PlacedOrbLayer extends StatelessWidget {
  const PlacedOrbLayer({super.key, required this.orbs, required this.child});
  final List<PlacedOrb> orbs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (orbs.isEmpty) return child;
    return Stack(clipBehavior: Clip.none, children: [
      child,
      for (final o in orbs)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomSingleChildLayout(
              delegate: _OrbAt(o),
              child: PlacedOrbView(key: ValueKey('orb-${o.id}'), orb: o),
            ),
          ),
        ),
    ]);
  }
}

class _OrbAt extends SingleChildLayoutDelegate {
  _OrbAt(this.o);
  final PlacedOrb o;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => BoxConstraints.tight(Size.square(o.size));

  @override
  Offset getPositionForChild(Size size, Size childSize) => o.rectIn(size).topLeft;

  @override
  bool shouldRelayout(_OrbAt old) => old.o.x != o.x || old.o.y != o.y || old.o.size != o.size;
}
