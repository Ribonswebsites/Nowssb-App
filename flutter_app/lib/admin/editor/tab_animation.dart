/// Drawer tabs of things to drag onto the page, each playing live:
///   Effects — how a section or element appears, how it moves for ever
///             after, how a sideways section turns its pages, and whether
///             it turns by itself;
///   Orbs, Loaders, Backgrounds, Particles, Celebrate — the animation
///             library (layout/anims), placed exactly where they are
///             dropped as their own element on the page. A thinking orb
///             can also go on the Loaders target to set the orb every
///             loader uses.
/// Nothing here is a switch or a slider.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../layout/anims/anim_library.dart';
import '../layout/anims/effects.dart';
import '../layout/carousel_fx.dart';
import '../layout/layout_sections.dart';
import '../template/slot_keys.dart';
import 'editor_controller.dart';
import 'glass.dart';
import 'preview.dart' show AnimDrop, FxDrop;

/// Entrances offered in the drawer (see anims/effects.dart).
const kEntrances = kEntranceNames;


/// "Turns by itself" speeds, as effects: (label, interval ms or null = off).
const kAutoSpeeds = <(String, int?)>[
  ('Stay still', null),
  ('Slow', 6500),
  ('Steady', 4000),
  ('Quick', 2500),
];

const _caption = Padding(
  padding: EdgeInsets.only(top: 2, bottom: 6),
  child: Row(children: [
    Icon(Icons.pan_tool_alt_rounded, color: kGold, size: 18),
    SizedBox(width: 8),
    Expanded(
      child: Text('Hold one and drag it onto the page',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    ),
  ]),
);

class EffectsTab extends StatefulWidget {
  const EffectsTab({super.key, required this.c});
  final EditorController c;

  @override
  State<EffectsTab> createState() => _EffectsTabState();
}

class _EffectsTabState extends State<EffectsTab> with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  EditorController get c => widget.c;

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The picked section's current effects are ringed.
    final cur = c.sectionPicked ? c.current : null;
    final props = cur?.entry.props ?? const <String, dynamic>{};
    final fx = cur == null ? null : '${props['transition'] ?? ''}';
    final ent = cur == null ? null : '${props['entrance'] ?? 'none'}';
    final loop = cur == null ? null : '${props['loop'] ?? 'none'}';
    final interval = cur == null
        ? -1
        : (props['autoRotate'] == true ? (props['interval'] is num ? (props['interval'] as num).toInt() : 4000) : null);
    // Grids, built lazily: only tiles on screen exist and play.
    return CustomScrollView(
      slivers: [
        const SliverPadding(padding: EdgeInsets.fromLTRB(14, 0, 14, 0), sliver: SliverToBoxAdapter(child: _caption)),
        _group('Appear', [
          for (final e in kEntrances.entries)
            DragTile(
              c: c,
              data: FxDrop(e.value, {'entrance': e.key == 'none' ? null : e.key}),
              label: e.value,
              selected: ent == e.key,
              child: kClassicEntrances.contains(e.key) || e.key == 'none'
                  ? AnimatedBuilder(
                      animation: _loop,
                      builder: (_, __) {
                        final t = (_loop.value * 1.6).clamp(0.0, 1.0);
                        return entranceTransform(e.key, Curves.easeOutCubic.transform(t), const _MiniCard(color: kGold));
                      },
                    )
                  : EntranceFx(kind: e.key, repeat: true, child: const _MiniCard(color: kGold)),
            ),
        ]),
        _group('Keep moving', [
          for (final e in kLoopNames.entries)
            DragTile(
              c: c,
              data: FxDrop(e.value, {'loop': e.key == 'none' ? null : e.key}),
              label: e.value,
              selected: loop == e.key,
              child: LoopFx(kind: e.key, child: const _MiniCard(color: kMint)),
            ),
        ]),
        _group('Page turn — sections that slide sideways', [
          for (final e in kCarouselTransitions.entries)
            DragTile(
              c: c,
              data: FxDrop(e.value, {'transition': e.key.isEmpty ? null : e.key}, carouselOnly: true),
              label: e.value,
              selected: fx == e.key,
              child: AnimatedBuilder(animation: _loop, builder: (_, __) => _FxDemo(fx: e.key, t: _loop.value)),
            ),
        ]),
        _group('Turns by itself', [
          for (final (label, ms) in kAutoSpeeds)
            DragTile(
              c: c,
              data: FxDrop(label, {'autoRotate': ms == null ? null : true, 'interval': ms}, carouselOnly: true),
              label: label,
              selected: interval == ms,
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, __) => _FxDemo(fx: '', t: ms == null ? 0 : (_loop.value * 4000 / ms) % 1),
              ),
            ),
        ]),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _group(String title, List<Widget> tiles) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        sliver: SliverMainAxisGroup(slivers: [
          SliverToBoxAdapter(child: Eyebrow(title)),
          SliverGrid.builder(
            gridDelegate: _tileGrid,
            itemCount: tiles.length,
            itemBuilder: (_, i) => tiles[i],
          ),
        ]),
      );
}

const _tileGrid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 96,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  childAspectRatio: 0.92,
);

class AnimGridTab extends StatelessWidget {
  const AnimGridTab({super.key, required this.c, required this.category, this.footer});
  final EditorController c;
  final AnimCategory category;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final specs = animsIn(category);
    final sel = c.selectedOrb;
    final picked = sel == null ? null : c.orbById(sel.$1, sel.$2)?.animId;
    // Carried over the page it already shows the ink the page will use.
    final pageInk = AnimInk(onLight: Theme.of(context).brightness == Brightness.light);
    return CustomScrollView(
      key: PageStorageKey('anim-grid-${category.name}'),
      slivers: [
        const SliverPadding(padding: EdgeInsets.fromLTRB(14, 0, 14, 0), sliver: SliverToBoxAdapter(child: _caption)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          sliver: SliverGrid.builder(
            gridDelegate: _tileGrid,
            itemCount: specs.length,
            itemBuilder: (context, i) {
              final s = specs[i];
              return DragTile(
                key: ValueKey('anim-tile-${s.id}'),
                c: c,
                data: AnimDrop(s.id),
                label: s.name,
                selected: picked == s.id,
                feedback: AnimView(spec: s, size: 72, ink: pageInk),
                child: AnimView(spec: s, size: 54, ink: const AnimInk(lite: true), fps: 30),
              );
            },
          ),
        ),
        if (footer != null) SliverPadding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 24), sliver: SliverToBoxAdapter(child: footer)),
      ],
    );
  }
}

class OrbsTab extends StatelessWidget {
  const OrbsTab({super.key, required this.c});
  final EditorController c;

  @override
  Widget build(BuildContext context) => AnimGridTab(c: c, category: AnimCategory.orbs, footer: _LoadersOrb(c: c));
}

/// A drawer tile: plays its effect; hold it and drag it onto the page. It
/// is carried by the point under the finger, so it lands exactly there.
class DragTile extends StatelessWidget {
  const DragTile({
    super.key,
    required this.c,
    required this.data,
    required this.label,
    required this.selected,
    required this.child,
    this.feedback,
  });
  final EditorController c;
  final Object data;
  final String label;
  final bool selected;
  final Widget child;
  final Widget? feedback;

  @override
  Widget build(BuildContext context) {
    final tile = _FxTile(label: label, selected: selected, onTap: tapFeel, child: child);
    final carried = feedback ?? SizedBox(width: 88, height: 88, child: Opacity(opacity: 0.9, child: tile));
    final size = feedback == null ? 88.0 : 72.0;
    return LongPressDraggable<Object>(
      data: data,
      delay: const Duration(milliseconds: 120),
      hapticFeedbackOnStart: true,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => c.setFxDragging(true),
      onDragEnd: (_) => c.setFxDragging(false),
      feedback: Material(
        color: Colors.transparent,
        // Centred on the finger.
        child: Transform.translate(offset: Offset(-size / 2, -size / 2), child: carried),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }
}

/// Drop an orb here to use it in every loader of the app. Pinch it to
/// resize, tap it for the black circle.
class _LoadersOrb extends StatefulWidget {
  const _LoadersOrb({required this.c});
  final EditorController c;

  @override
  State<_LoadersOrb> createState() => _LoadersOrbState();
}

class _LoadersOrbState extends State<_LoadersOrb> {
  double _base = 72;
  static const _key = 'orb.all';

  EditorController get c => widget.c;

  void _patch(Map<String, dynamic> p) => c.patchStyle(_key, SlotType.orb, 'random', p);

  @override
  Widget build(BuildContext context) {
    final st = c.overrideOf(_key)?.style ?? const <String, dynamic>{};
    final pick = OrbState.values.where((o) => o.name == st['orb']).firstOrNull;
    final size = st['orbSize'] is num ? (st['orbSize'] as num).toDouble() : 72.0;
    final circle = st['orbCircle'] is bool ? st['orbCircle'] as bool : true;
    return DragTarget<Object>(
      // Only the thinking orbs can be the loaders' orb.
      onWillAcceptWithDetails: (d) => d.data is AnimDrop && thinkingOrbOf((d.data as AnimDrop).id) != null,
      onAcceptWithDetails: (d) {
        bigFeel();
        _patch({'orb': thinkingOrbOf((d.data as AnimDrop).id)!.name});
      },
      builder: (context, cand, _) => Glass(
        radius: 18,
        padding: const EdgeInsets.all(12),
        edge: cand.isNotEmpty ? kGold : kGlassEdge,
        glow: cand.isNotEmpty ? kGold.withValues(alpha: 0.3) : null,
        child: Row(children: [
          GestureDetector(
            onTap: () {
              tapFeel();
              _patch({'orbCircle': !circle});
            },
            onLongPress: () => _patch({'orb': null}),
            onScaleStart: (_) {
              c.endStep();
              _base = size;
            },
            onScaleUpdate: (d) {
              if (d.pointerCount < 2) return;
              _patch({'orbSize': (_base * d.scale).clamp(16.0, 120.0).roundToDouble()});
            },
            onScaleEnd: (_) => c.endStep(),
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              child: Container(
                width: size * 0.75 + 8,
                height: size * 0.75 + 8,
                alignment: Alignment.center,
                decoration: circle ? const BoxDecoration(color: Colors.black, shape: BoxShape.circle) : null,
                child: pick == null
                    ? Icon(Icons.shuffle_rounded, color: kDim, size: size * 0.4)
                    : ThinkingOrb(state: pick, size: size * 0.75, theme: OrbTheme.dark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Loaders everywhere — drop an orb here.\nPinch to resize · tap for the circle · hold to reset.',
                style: TextStyle(color: kDim, fontSize: 12, height: 1.35)),
          ),
        ]),
      ),
    );
  }
}

class _FxTile extends StatelessWidget {
  const _FxTile({required this.label, required this.selected, required this.onTap, required this.child, this.enabled = true});
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Glass(
        radius: 16,
        padding: const EdgeInsets.all(6),
        edge: selected ? kGold : kGlassEdge,
        glow: selected ? kGold.withValues(alpha: 0.4) : null,
        onTap: enabled ? onTap : null,
        child: Column(children: [
          Expanded(child: ClipRect(child: Center(child: child))),
          const SizedBox(height: 4),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: selected ? kGold : Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
          borderRadius: BorderRadius.circular(7),
        ),
      );
}

/// Three little cards turning with transition [fx], at loop time [t].
class _FxDemo extends StatelessWidget {
  const _FxDemo({required this.fx, required this.t});
  final String fx;
  final double t;

  static const _colors = [kGold, kMint, Color(0xFF7F5AF0)];

  @override
  Widget build(BuildContext context) {
    // page position 0 → 1 → 2 → 0, easing between, holding at each.
    final phase = (t * 3) % 3;
    final base = phase.floor();
    final frac = Curves.easeInOutCubic.transform(((phase - base) * 1.6 - 0.6).clamp(0.0, 1.0));
    final page = base + frac;
    const w = 56.0;
    return SizedBox(
      width: w,
      height: 40,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        for (var i = 0; i < 4; i++)
          Builder(builder: (_) {
            final d = i - page;
            if (d.abs() > 1.2) return const SizedBox.shrink();
            final card = _MiniCard(color: _colors[i % 3]);
            final framed = fx.isEmpty || fx == 'slide' ? card : carouselFxFrame(fx, d, card);
            return Positioned(
              left: (w - 44) / 2 + (fx == 'stack' && d > 0 ? d * 44 * 0.15 : d * w),
              top: 4,
              child: framed,
            );
          }),
      ]),
    );
  }
}
