/// Animation tab: how a sideways section turns its pages (with live
/// previews), whether it turns by itself, how a section enters the screen,
/// and which thinking orb the loaders use.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../layout/carousel_fx.dart';
import '../layout/layout_sections.dart';
import '../template/slot_keys.dart';
import 'animation_library.dart';
import 'editor_controller.dart';
import 'glass.dart';

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

class AnimationTab extends StatefulWidget {
  const AnimationTab({super.key, required this.c});
  final EditorController c;

  @override
  State<AnimationTab> createState() => _AnimationTabState();
}

class _AnimationTabState extends State<AnimationTab> with SingleTickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  bool _allLoaders = false;

  EditorController get c => widget.c;

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cur = c.current;
    final props = cur?.entry.props ?? const <String, dynamic>{};
    final fx = '${props['transition'] ?? ''}';
    final ent = '${props['entrance'] ?? 'none'}';
    final auto = props['autoRotate'] == true;
    final interval = props['interval'] is num ? (props['interval'] as num).toDouble() : 4000.0;
    final orbKey = _allLoaders || cur == null ? 'orb.all' : 'orb.${c.pageId}.${cur.id}';
    final orbStyle = c.overrideOf(orbKey)?.style ?? const <String, dynamic>{};
    final orbPick = '${orbStyle['orb'] ?? ''}';
    final orbSize = orbStyle['orbSize'] is num ? (orbStyle['orbSize'] as num).toDouble() : 72.0;
    final orbCircle = orbStyle['orbCircle'] is bool ? orbStyle['orbCircle'] as bool : true;
    void orbPatch(Map<String, dynamic> p) => c.patchStyle(orbKey, SlotType.orb, 'random', p);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Glass(
            radius: 18,
            padding: const EdgeInsets.all(12),
            glow: kGold.withValues(alpha: 0.12),
            onTap: () {
              tapFeel();
              openAnimationLibrary(context, c);
            },
            child: const Row(children: [
              Icon(Icons.animation_rounded, color: kGold),
              SizedBox(width: 10),
              Expanded(
                child: Text('Animation library — every entrance, page turn, auto-rotate and orb, playing large',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.open_in_full_rounded, color: kGold, size: 18),
            ]),
          ),
        ),
        if (cur == null)
          const Hint('This page is one block for now — only the orb choice applies.')
        else ...[
          Eyebrow(cur.carousel ? 'Page turn — “${cur.title}”' : 'Page turn'),
          if (!cur.carousel)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('This section does not scroll sideways. Pick a carousel section to change how it turns.',
                  style: TextStyle(color: kDim, fontSize: 12)),
            ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.05,
            children: [
              for (final e in kCarouselTransitions.entries)
                _FxTile(
                  label: e.value,
                  selected: fx == e.key,
                  enabled: cur.carousel,
                  onTap: () => c.patchProps(cur.id, {'transition': e.key.isEmpty ? null : e.key}),
                  child: AnimatedBuilder(
                    animation: _loop,
                    builder: (_, __) => _FxDemo(fx: e.key, t: _loop.value),
                  ),
                ),
            ],
          ),
          if (cur.carousel) ...[
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: auto,
              activeThumbColor: kGold,
              title: const Text('Turn pages by itself', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('Where the carousel supports it', style: TextStyle(color: kDim, fontSize: 11.5)),
              onChanged: (v) {
                tapFeel();
                c.patchProps(cur.id, {'autoRotate': v ? true : null});
              },
            ),
            if (auto)
              LabeledSlider(
                label: 'Every',
                value: interval / 1000,
                min: 1.5,
                max: 12,
                format: (v) => '${v.toStringAsFixed(1)}s',
                onChanged: (v) => c.patchProps(cur.id, {'interval': (v * 1000).round()}),
              ),
          ],
          Eyebrow('Entrance — how “${cur.title}” appears'),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.05,
            children: [
              for (final e in kEntrances.entries)
                _FxTile(
                  label: e.value,
                  selected: ent == e.key,
                  onTap: () => c.patchProps(cur.id, {'entrance': e.key == 'none' ? null : e.key}),
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
        ],
        Eyebrow('Thinking orb',
            trailing: PillSwitch(
              labels: const ['This section', 'Whole app'],
              index: _allLoaders || cur == null ? 1 : 0,
              onChanged: (i) => setState(() => _allLoaders = i == 1),
            )),
        const Text('The loaders in the chosen place use this orb. "As designed" keeps the built-in mix.',
            style: TextStyle(color: kDim, fontSize: 12)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: [
            _FxTile(
              label: 'As designed',
              selected: orbPick.isEmpty,
              onTap: () => orbPatch({'orb': null}),
              child: const Icon(Icons.shuffle_rounded, color: kDim, size: 28),
            ),
            for (final e in kOrbNames.entries)
              _FxTile(
                label: e.value,
                selected: orbPick == e.key.name,
                onTap: () => orbPatch({'orb': e.key.name}),
                child: Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: orbCircle ? const BoxDecoration(color: Colors.black, shape: BoxShape.circle) : null,
                  child: ThinkingOrb(state: e.key, size: 44, theme: OrbTheme.dark),
                ),
              ),
          ],
        ),
        LabeledSlider(
          label: 'Orb size',
          value: orbSize,
          min: 16,
          max: 120,
          onChanged: (v) => orbPatch({'orbSize': v.roundToDouble()}),
          onReset: orbStyle['orbSize'] == null ? null : () => orbPatch({'orbSize': null}),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: orbCircle,
          activeThumbColor: kGold,
          title: const Text('Black circle behind the orb', style: TextStyle(color: Colors.white, fontSize: 14)),
          onChanged: (v) {
            tapFeel();
            orbPatch({'orbCircle': v});
          },
        ),
      ],
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
