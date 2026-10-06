/// Animation tab: a drawer of effects, each playing live. Drag one onto the
/// phone to put it on that section — how it appears, how a sideways section
/// turns its pages, whether it turns by itself, and which thinking orb its
/// loaders use. No switches or sliders: the orb is resized by pinching it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../layout/carousel_fx.dart';
import '../layout/layout_sections.dart';
import '../template/slot_keys.dart';
import 'editor_controller.dart';
import 'glass.dart';
import 'preview.dart' show FxDrop;

const kEntrances = <String, String>{
  'none': 'None',
  'fadeUp': 'Fade up',
  'slide': 'Slide in',
  'scale': 'Grow in',
  'blur': 'Blur in',
  'fade': 'Fade',
};

const kOrbNames = <OrbState, String>{
  OrbState.composing: 'Composing',
  OrbState.listening: 'Listening',
  OrbState.solving: 'Solving',
  OrbState.working: 'Working',
  OrbState.searching: 'Searching',
  OrbState.shaping: 'Shaping',
};

/// "Turns by itself" speeds, as effects: (label, interval ms or null = off).
const kAutoSpeeds = <(String, int?)>[
  ('Stay still', null),
  ('Slow', 6500),
  ('Steady', 4000),
  ('Quick', 2500),
];

void _setOrb(EditorController c, String key, String? orb) => c.patchStyle(key, SlotType.orb, 'random', {'orb': orb});

class AnimationTab extends StatefulWidget {
  const AnimationTab({super.key, required this.c});
  final EditorController c;

  @override
  State<AnimationTab> createState() => _AnimationTabState();
}

class _AnimationTabState extends State<AnimationTab> with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  EditorController get c => widget.c;

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  Widget _row(List<Widget> tiles) => SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tiles.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => SizedBox(width: 88, child: tiles[i]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cur = c.current;
    final props = cur?.entry.props ?? const <String, dynamic>{};
    final fx = '${props['transition'] ?? ''}';
    final ent = '${props['entrance'] ?? 'none'}';
    final interval =
        props['autoRotate'] == true ? (props['interval'] is num ? (props['interval'] as num).toInt() : 4000) : null;
    // Same key the loaders read: SectionScope's page is the layout page
    // ('<page>.<tab>' on pages with tabs), not the editor's page id.
    final orbKey = cur == null ? 'orb.all' : 'orb.${c.layoutPage}.${cur.id}';
    final orbPick = '${c.overrideOf(orbKey)?.style['orb'] ?? ''}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2, bottom: 6),
          child: Row(children: [
            Icon(Icons.pan_tool_alt_rounded, color: kGold, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text('Hold an effect and drag it onto the phone',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        if (cur != null) ...[
          const Eyebrow('Appear'),
          _row([
            for (final e in kEntrances.entries)
              _DragFx(
                drop: FxDrop(e.value, {'entrance': e.key == 'none' ? null : e.key}),
                label: e.value,
                selected: ent == e.key,
                  child: AnimatedBuilder(
                    animation: _loop,
                    builder: (_, __) {
                      final t = (_loop.value * 1.6).clamp(0.0, 1.0);
                      return entranceTransform(e.key, Curves.easeOutCubic.transform(t), const _MiniCard(color: kGold));
                    },
                  ),
                ),
            ],
          ),
          // Page turns only mean something on a section that scrolls
          // sideways; they are only offered while one is on the phone.
          if (cur.carousel) ...[
            const Eyebrow('Page turn'),
            _row([
              for (final e in kCarouselTransitions.entries)
                _DragFx(
                  drop: FxDrop(e.value, {'transition': e.key.isEmpty ? null : e.key}, carouselOnly: true),
                  label: e.value,
                  selected: fx == e.key,
                    child: AnimatedBuilder(
                      animation: _loop,
                      builder: (_, __) => _FxDemo(fx: e.key, t: _loop.value),
                    ),
                  ),
              ],
            ),
            const Eyebrow('Turns by itself'),
            _row([
              for (final (label, ms) in kAutoSpeeds)
                _DragFx(
                  drop: FxDrop(label, {'autoRotate': ms == null ? null : true, 'interval': ms}, carouselOnly: true),
                  label: label,
                  selected:
                      interval == ms || (ms == 4000 && interval != null && !kAutoSpeeds.any((s) => s.$2 == interval)),
                  child: AnimatedBuilder(
                    animation: _loop,
                    builder: (_, __) => _FxDemo(fx: '', t: ms == null ? 0 : (_loop.value * 4000 / ms) % 1),
                  ),
                ),
            ]),
          ],
        ],
        const Eyebrow('Thinking orb'),
        _row([
          _DragFx(
            drop: FxDrop('As designed', const {}, apply: (c, s) => _setOrb(c, 'orb.${c.layoutPage}.${s.id}', null)),
            label: 'As designed',
            selected: orbPick.isEmpty,
            child: const Icon(Icons.shuffle_rounded, color: kDim, size: 28),
          ),
          for (final e in kOrbNames.entries)
            _DragFx(
              drop: FxDrop(e.value, const {}, apply: (c, s) => _setOrb(c, 'orb.${c.layoutPage}.${s.id}', e.key.name)),
              label: e.value,
              selected: orbPick == e.key.name,
              orb: e.key,
              child: ThinkingOrb(state: e.key, size: 40, theme: OrbTheme.dark),
            ),
        ]),
        const SizedBox(height: 10),
        _WholeAppOrb(c: c),
      ],
    );
  }
}

/// A drawer tile: plays its effect; hold and drag it onto the phone.
class _DragFx extends StatelessWidget {
  const _DragFx({required this.drop, required this.label, required this.selected, required this.child, this.orb});
  final FxDrop drop;
  final String label;
  final bool selected;
  final Widget child;
  final OrbState? orb;

  @override
  Widget build(BuildContext context) {
    final tile = _FxTile(label: label, selected: selected, onTap: tapFeel, child: child);
    return LongPressDraggable<Object>(
      data: orb == null ? drop : (drop, orb),
      delay: const Duration(milliseconds: 120),
      hapticFeedbackOnStart: true,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 92, height: 92, child: Opacity(opacity: 0.9, child: tile)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: tile),
      child: tile,
    );
  }
}

/// Drop an orb here to use it in every loader of the app. The orb shown
/// is the whole-app one: pinch it to resize, tap it for the black circle.
class _WholeAppOrb extends StatefulWidget {
  const _WholeAppOrb({required this.c});
  final EditorController c;

  @override
  State<_WholeAppOrb> createState() => _WholeAppOrbState();
}

class _WholeAppOrbState extends State<_WholeAppOrb> {
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
      onWillAcceptWithDetails: (d) =>
          d.data is (FxDrop, OrbState) || (d.data is FxDrop && (d.data as FxDrop).label == 'As designed'),
      onAcceptWithDetails: (d) {
        bigFeel();
        final o = d.data;
        _patch({'orb': o is (FxDrop, OrbState) ? o.$2.name : null});
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
            child: Text('Whole app — drop an orb here.\nPinch it to resize, tap for the circle.',
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
