/// Animation library: every animation the UI Editor can apply, each playing
/// live and large — entrances, page turns, auto-rotate at the chosen speed,
/// and the thinking orbs (every OrbState). Orbs open the full picker so
/// Set writes server-side for all users. Lottie/Rive gallery assets are
/// wired in a follow-up once copied into the admin bundle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../layout/carousel_fx.dart';
import '../layout/layout_sections.dart';
import '../layout/scopes.dart';
import '../template/slot_keys.dart';
import 'editor_controller.dart';
import 'glass.dart';
import 'tab_animation.dart' show kEntrances;
import '../orb_picker.dart';

Future<void> openAnimationLibrary(BuildContext context, EditorController c) {
  return Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => AnimationLibrary(c: c),
    transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
  ));
}

class AnimationLibrary extends StatefulWidget {
  const AnimationLibrary({super.key, required this.c});
  final EditorController c;
  @override
  State<AnimationLibrary> createState() => _AnimationLibraryState();
}

class _AnimationLibraryState extends State<AnimationLibrary> with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  double _speed = 1;
  String _tab = 'entrance';

  EditorController get c => widget.c;

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  void _setSpeed(double s) {
    setState(() => _speed = s);
    _loop.duration = Duration(milliseconds: (2400 / s).round());
    _loop.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final cur = c.current;
    final props = cur?.entry.props ?? const <String, dynamic>{};
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xF2060C18),
      body: Padding(
        padding: EdgeInsets.only(top: top),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ANIMATION LIBRARY', style: TextStyle(color: kGold, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  Text(cur == null ? 'Whole page' : 'For “${cur.title}”', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white)),
            ]),
          ),
          SizedBox(
            height: 36,
            child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, children: [
              for (final t in const {'entrance': 'Entrances', 'turn': 'Page turns', 'auto': 'Auto-rotate', 'orb': 'Orbs'}.entries)
                Padding(padding: const EdgeInsets.only(right: 6), child: Pill(t.value, selected: _tab == t.key, dense: true, onTap: () => setState(() => _tab = t.key))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(children: [
              const Text('Speed', style: TextStyle(color: kDim, fontSize: 12)),
              const SizedBox(width: 8),
              for (final s in const [0.5, 1.0, 2.0])
                Padding(padding: const EdgeInsets.only(right: 6), child: Pill('${s}x', dense: true, selected: _speed == s, onTap: () => _setSpeed(s))),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(child: _body(cur, props)),
        ]),
      ),
    );
  }

  Widget _grid(List<Widget> tiles) => GridView.count(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
        children: tiles,
      );

  Widget _body(SectionInfo? cur, Map<String, dynamic> props) {
    switch (_tab) {
      case 'turn':
        final fx = '${props['transition'] ?? ''}';
        return _grid([
          for (final e in kCarouselTransitions.entries)
            _BigTile(
              label: e.value,
              selected: fx == e.key,
              enabled: cur?.carousel == true,
              onTap: () => c.patchProps(cur!.id, {'transition': e.key.isEmpty ? null : e.key}),
              child: AnimatedBuilder(animation: _loop, builder: (_, __) => _Turn(fx: e.key, t: _loop.value)),
            ),
        ]);
      case 'auto':
        final interval = props['interval'] is num ? (props['interval'] as num).toDouble() : 4000.0;
        final on = props['autoRotate'] == true;
        return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 30), children: [
          _BigTile(
            label: on ? 'Turning every ${(interval / 1000).toStringAsFixed(1)}s' : 'Off — tap to turn on',
            selected: on,
            enabled: cur?.carousel == true,
            height: 220,
            onTap: () => c.patchProps(cur!.id, {'autoRotate': on ? null : true}),
            child: _AutoRotateDemo(interval: Duration(milliseconds: (interval / _speed).round()), fx: '${props['transition'] ?? ''}'),
          ),
          const SizedBox(height: 10),
          if (cur?.carousel == true)
            LabeledSlider(
              label: 'Every',
              value: interval / 1000,
              min: 1.5,
              max: 12,
              format: (v) => '${v.toStringAsFixed(1)}s',
              onChanged: (v) => c.patchProps(cur!.id, {'interval': (v * 1000).round()}),
            )
          else
            const Hint('Pick a sideways (carousel) section in the page picker to auto-rotate it.'),
        ]);
      case 'orb':
        // Full picker: every OrbState.values, live grid, Set/Undo server-side.
        final key = c.current == null
            ? 'orb.all'
            : 'orb.${c.pageId}.${c.current!.id}';
        final pick = '${c.overrideOf(key)?.style['orb'] ?? c.overrideOf('orb.all')?.style['orb'] ?? ''}';
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Glass(
              radius: 14,
              padding: const EdgeInsets.all(12),
              onTap: () => openOrbPicker(context, slot: key),
              child: const Row(children: [
                Icon(Icons.open_in_full_rounded, color: kGold, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Open full orb picker — Set saves for all users, with Undo',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
          Expanded(
            child: _grid([
              for (final s in OrbState.values)
                _BigTile(
                  label: orbLabel(s),
                  selected: pick == s.name,
                  onTap: () => openOrbPicker(context, slot: key),
                  child: Container(
                    width: 100,
                    height: 100,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: ThinkingOrb(state: s, size: 80, theme: OrbTheme.dark),
                  ),
                ),
            ]),
          ),
        ]);
      default:
        final ent = '${props['entrance'] ?? 'none'}';
        return _grid([
          for (final e in kEntrances.entries)
            _BigTile(
              label: e.value,
              selected: ent == e.key,
              enabled: cur != null,
              onTap: () => c.patchProps(cur!.id, {'entrance': e.key == 'none' ? null : e.key}),
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, __) {
                  final t = (_loop.value * 1.6).clamp(0.0, 1.0);
                  return entranceTransform(e.key, Curves.easeOutCubic.transform(t), const _Card(w: 110, h: 76, color: kGold));
                },
              ),
            ),
        ]);
    }
  }
}

class _BigTile extends StatelessWidget {
  const _BigTile({required this.label, required this.selected, required this.onTap, required this.child, this.enabled = true, this.height});
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;
  final double? height;
  @override
  Widget build(BuildContext context) => Opacity(
        opacity: enabled ? 1 : 0.4,
        child: SizedBox(
          height: height,
          child: Glass(
            radius: 20,
            padding: const EdgeInsets.all(10),
            edge: selected ? kGold : kGlassEdge,
            glow: selected ? kGold.withValues(alpha: 0.35) : null,
            onTap: enabled
                ? () {
                    actFeel();
                    onTap();
                  }
                : null,
            child: Column(children: [
              Expanded(child: ClipRect(child: Center(child: child))),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (selected) const Icon(Icons.check_circle_rounded, color: kGold, size: 14),
                if (selected) const SizedBox(width: 4),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? kGold : Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5))),
              ]),
            ]),
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.w, required this.h, required this.color});
  final double w;
  final double h;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withValues(alpha: 0.45)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16)],
        ),
      );
}

const _colors = [kGold, kMint, Color(0xFF7F5AF0), Color(0xFFFF7A90)];

class _Turn extends StatelessWidget {
  const _Turn({required this.fx, required this.t});
  final String fx;
  final double t;
  @override
  Widget build(BuildContext context) {
    final phase = (t * 3) % 3;
    final base = phase.floor();
    final frac = Curves.easeInOutCubic.transform(((phase - base) * 1.6 - 0.6).clamp(0.0, 1.0));
    return _Strip(page: base + frac, fx: fx);
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.page, required this.fx});
  final double page;
  final String fx;
  @override
  Widget build(BuildContext context) {
    const w = 130.0;
    const cw = 100.0;
    return SizedBox(
      width: w,
      height: 80,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        for (var i = 0; i < 5; i++)
          Builder(builder: (_) {
            final d = i - page;
            if (d.abs() > 1.2) return const SizedBox.shrink();
            final card = _Card(w: cw, h: 70, color: _colors[i % _colors.length]);
            final framed = fx.isEmpty || fx == 'slide' ? card : carouselFxFrame(fx, d, card);
            return Positioned(left: (w - cw) / 2 + (fx == 'stack' && d > 0 ? d * cw * 0.15 : d * w), top: 5, child: framed);
          }),
      ]),
    );
  }
}

/// A real auto-advancing strip at the chosen interval and transition.
class _AutoRotateDemo extends StatefulWidget {
  const _AutoRotateDemo({required this.interval, required this.fx});
  final Duration interval;
  final String fx;
  @override
  State<_AutoRotateDemo> createState() => _AutoRotateDemoState();
}

class _AutoRotateDemoState extends State<_AutoRotateDemo> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  int _page = 0;
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    while (_alive) {
      await Future<void>.delayed(widget.interval);
      if (!_alive || !mounted) return;
      await _a.forward(from: 0);
      if (!mounted) return;
      setState(() => _page = (_page + 1) % 4);
      _a.value = 0;
    }
  }

  @override
  void dispose() {
    _alive = false;
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _a,
          builder: (_, __) => Transform.scale(scale: 1.4, child: _Strip(page: _page + Curves.easeInOutCubic.transform(_a.value), fx: widget.fx)),
        ),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 4; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(color: i == _page ? kGold : kFaint, borderRadius: BorderRadius.circular(99)),
            ),
        ]),
      ]);
}
