/// The look of whatever was touched, one small panel at a time: chips up
/// top (Colour · Font · Shadow · Shape for words; Replace · Crop · Corners ·
/// Shadow for pictures; Background · Corners · Shadow for a section), each
/// opening a row of big tiles. Size is a pinch on the page, not a slider.
library;

import 'package:flutter/material.dart';

import '../layout/template_sections.dart' show NetPicture;
import '../media_upload.dart';
import '../template/slot_keys.dart';
import '../template/style_apply.dart';
import '../template/ui_overrides.dart';
import 'editor_controller.dart';
import 'glass.dart';
import 'preview.dart';

/// Ready-made two-colour blends for words and section backgrounds.
const kLookGradients = <List<int>>[
  [0xFFF6E7B0, 0xFFB8904A],
  [0xFF7CFFCB, 0xFF2CB1FF],
  [0xFFFF4D8D, 0xFF7F5AF0],
  [0xFFFFC857, 0xFFFF7A59],
  [0xFF0F1828, 0xFF2A3B5C],
  [0xFFFFFFFF, 0xFFE8D5A3],
];

/// Pictures that ship with the app, ready as section backgrounds.
const kLookPictures = <String>[
  'assets/banners/stories/aura.png',
  'assets/banners/stories/prana.png',
  'assets/banners/stories/soma.png',
  'assets/banners/stories/pitta.png',
];

const kLookCorners = <int>[0, 8, 16, 24, 40];
const kLookLifts = <(int, String)>[(0, 'None'), (6, 'Soft'), (14, 'Lifted'), (26, 'Floating')];

/// Text shadows: (name, colour, blur, drop).
const kLookTextShadows = <(String, int?, int, int)>[
  ('None', null, 0, 0),
  ('Soft', 0x99000000, 8, 2),
  ('Glow', 0xAAE8D5A3, 14, 0),
  ('Neon', 0xCC34D399, 18, 0),
  ('Hard', 0xFF000000, 0, 3),
];

class LookSheet extends StatefulWidget {
  const LookSheet({super.key, required this.c, required this.onReplace, this.onMore});
  final EditorController c;
  final VoidCallback onReplace;
  final VoidCallback? onMore;

  @override
  State<LookSheet> createState() => _LookSheetState();
}

class _LookSheetState extends State<LookSheet> {
  String? _panel;
  double? _progress;

  EditorController get c => widget.c;

  /// One tap = one undo step.
  void _step(VoidCallback f) {
    actFeel();
    c.endStep();
    f();
    c.endStep();
  }

  @override
  Widget build(BuildContext context) {
    final key = c.selectedSlot;
    final type = c.selectedType;
    if (key != null && type != null && type != SlotType.orb) {
      final def = c.selectedDefault;
      final st = c.overrideOf(key)?.style ?? const <String, dynamic>{};
      void patch(Map<String, dynamic> p) => _step(() => c.patchStyle(key, type, def, p));
      final text = type == SlotType.text;
      final chips = text
          ? const [('colour', 'Colour', Icons.palette_rounded), ('font', 'Font', Icons.font_download_rounded),
              ('shadow', 'Shadow', Icons.blur_on_rounded), ('shape', 'Shape', Icons.crop_16_9_rounded)]
          : const [('crop', 'Crop', Icons.crop_rounded), ('corners', 'Corners', Icons.rounded_corner_rounded),
              ('lift', 'Shadow', Icons.layers_rounded)];
      final panel = chips.any((x) => x.$1 == _panel) ? _panel! : chips.first.$1;
      int? col(String k) => st[k] is num ? (st[k] as num).toInt() : null;
      double n(String k, double d) => st[k] is num ? (st[k] as num).toDouble() : d;
      return _frame(
        title: slotFriendly(key, type, def),
        reset: st.isEmpty
            ? null
            : () => _step(() => c.setStyle(key, type, def, {
                  // Placement stays; only the look goes.
                  for (final k in const ['dx', 'dy', 'scale', 'size', 'hidden', 'entrance', 'loop'])
                    if (st[k] != null) k: st[k],
                })),
        chips: [
          if (!text) _Chip(id: 'replace', label: 'Replace', icon: Icons.photo_library_rounded, selected: false, onTap: widget.onReplace),
          for (final (id, label, icon) in chips)
            _Chip(id: id, label: label, icon: icon, selected: panel == id, onTap: () => setState(() => _panel = id)),
          if (text && widget.onMore != null)
            _Chip(id: 'more', label: 'More', icon: Icons.tune_rounded, selected: false, onTap: widget.onMore!),
        ],
        body: switch (panel) {
          'colour' => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ColorRow(value: col('color'), onPick: (v) => patch({'color': v, 'gradient': null})),
              const SizedBox(height: 12),
              _Tiles(children: [
                for (var i = 0; i < kLookGradients.length; i++)
                  _Tile(
                    id: 'look-grad-$i',
                    selected: '${st['gradient']}' == '${kLookGradients[i]}',
                    onTap: () => patch({'gradient': kLookGradients[i], 'color': null}),
                    child: Text('Aa',
                        style: applyTextLook(const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                            {'gradient': kLookGradients[i]})),
                  ),
              ]),
              const _Note('Pinch the words on the page to resize.'),
            ]),
          'font' => Wrap(spacing: 8, runSpacing: 8, children: [
              Pill('As designed', dense: true, selected: st['font'] == null, onTap: () => patch({'font': null})),
              for (final f in {...kBundledFonts, ...kGoogleFonts})
                _Tile(
                  id: 'look-font-$f',
                  wide: true,
                  selected: st['font'] == f,
                  onTap: () => patch({'font': f}),
                  child: Text(f, maxLines: 1, style: applyTextLook(const TextStyle(color: Colors.white, fontSize: 14), {'font': f})),
                ),
            ]),
          'shadow' => _Tiles(children: [
              for (final (name, colour, blur, dy) in kLookTextShadows)
                _Tile(
                  id: 'look-tshadow-$name',
                  label: name,
                  selected: colour == null ? st['shadow'] == null : col('shadow') == colour,
                  onTap: () => patch({
                    'shadow': colour,
                    'shadowBlur': colour == null ? null : blur,
                    'shadowDy': colour == null ? null : dy,
                  }),
                  child: Text('Aa',
                      style: applyTextLook(const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                          {if (colour != null) 'shadow': colour, 'shadowBlur': blur, 'shadowDy': dy})),
                ),
            ]),
          'shape' => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Tiles(children: [
                for (final (id, label, r) in const [('none', 'None', -1.0), ('pill', 'Pill', 99.0), ('rounded', 'Rounded', 10.0), ('circle', 'Circle', 99.0)])
                  _Tile(
                    id: 'look-shape-$id',
                    label: label,
                    selected: (st['shape'] ?? 'none') == id,
                    onTap: () => id == 'none'
                        ? patch({'shape': null, 'bg': null, 'bg2': null, 'border': null, 'glow': null, 'glass': null})
                        : patch({'shape': id, if (st['bg'] == null) 'bg': 0xFFB8904A}),
                    child: Container(
                      width: id == 'circle' ? 30 : 40,
                      height: id == 'circle' ? 30 : 22,
                      decoration: BoxDecoration(
                        borderRadius: r < 0 ? null : BorderRadius.circular(r),
                        border: Border.all(color: r < 0 ? const Color(0x55FFFFFF) : kGold, width: 2),
                      ),
                    ),
                  ),
              ]),
              if ((st['shape'] ?? 'none') != 'none') ...[
                const SizedBox(height: 12),
                ColorRow(value: col('bg'), onPick: (v) => patch({'bg': v})),
              ],
            ]),
          'crop' => _CropPad(
              zoom: n('cropZoom', 1),
              x: n('cropX', 0),
              y: n('cropY', 0),
              onStart: c.endStep,
              onChanged: (z, x, y) => c.patchStyle(key, type, def, {
                'cropZoom': z <= 1.001 ? null : double.parse(z.toStringAsFixed(3)),
                'cropX': x.abs() < 0.005 ? null : double.parse(x.toStringAsFixed(3)),
                'cropY': y.abs() < 0.005 ? null : double.parse(y.toStringAsFixed(3)),
              }),
              onEnd: c.endStep,
              onReset: () => patch({'cropZoom': null, 'cropX': null, 'cropY': null}),
            ),
          'corners' => _corners(n('round', 0), (r) => patch({'round': r == 0 ? null : r})),
          _ => _lifts(n('lift', 0), (v) => patch({'lift': v == 0 ? null : v})),
        },
      );
    }
    final cur = c.current;
    if (c.sectionPicked && cur != null) {
      final entry = c.entries.where((e) => e.id == cur.id).firstOrNull;
      final p = entry?.props ?? const <String, dynamic>{};
      void patch(Map<String, dynamic> m) => _step(() => c.patchProps(cur.id, m));
      double n(String k) => p[k] is num ? (p[k] as num).toDouble() : 0;
      const chips = [('fill', 'Background', Icons.format_color_fill_rounded), ('corners', 'Corners', Icons.rounded_corner_rounded),
          ('lift', 'Shadow', Icons.layers_rounded)];
      final panel = chips.any((x) => x.$1 == _panel) ? _panel! : chips.first.$1;
      const lookKeys = ['fill', 'fill2', 'fillImage', 'fillVideo', 'corner', 'lift'];
      return _frame(
        title: cur.title,
        reset: lookKeys.any((k) => p[k] != null) ? () => patch({for (final k in lookKeys) k: null}) : null,
        chips: [
          for (final (id, label, icon) in chips)
            _Chip(id: id, label: label, icon: icon, selected: panel == id, onTap: () => setState(() => _panel = id)),
        ],
        body: switch (panel) {
          'fill' => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ColorRow(
                value: p['fill2'] == null && p['fill'] is num ? (p['fill'] as num).toInt() : null,
                onPick: (v) => patch({'fill': v, 'fill2': null}),
              ),
              const SizedBox(height: 12),
              _Tiles(children: [
                for (var i = 0; i < kLookGradients.length; i++)
                  _Tile(
                    id: 'look-fill-grad-$i',
                    selected: p['fill'] == kLookGradients[i][0] && p['fill2'] == kLookGradients[i][1],
                    onTap: () => patch({'fill': kLookGradients[i][0], 'fill2': kLookGradients[i][1]}),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(colors: [Color(kLookGradients[i][0]), Color(kLookGradients[i][1])]),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              _Tiles(children: [
                for (final a in kLookPictures)
                  _Tile(
                    id: 'look-fill-pic-${kLookPictures.indexOf(a)}',
                    selected: p['fillImage'] == a,
                    onTap: () => patch({'fillImage': a, 'fillVideo': null}),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(width: 48, height: 48, child: NetPicture(url: a)),
                    ),
                  ),
                _Tile(
                  id: 'look-fill-upload',
                  label: 'Picture',
                  selected: false,
                  onTap: () => _upload(cur.id, PickKind.image),
                  child: const Icon(Icons.add_photo_alternate_rounded, color: kGold),
                ),
                _Tile(
                  id: 'look-fill-clip',
                  label: 'Clip',
                  selected: '${p['fillVideo'] ?? ''}'.isNotEmpty,
                  onTap: () => _upload(cur.id, PickKind.video),
                  child: const Icon(Icons.video_call_rounded, color: kGold),
                ),
                if (p['fillImage'] != null || p['fillVideo'] != null)
                  _Tile(
                    id: 'look-fill-clear',
                    label: 'None',
                    selected: false,
                    onTap: () => patch({'fillImage': null, 'fillVideo': null}),
                    child: const Icon(Icons.hide_image_outlined, color: kDim),
                  ),
              ]),
              if (_progress != null)
                Padding(padding: const EdgeInsets.only(top: 10), child: LinearProgressIndicator(value: _progress, color: kGold)),
            ]),
          'corners' => _corners(n('corner'), (r) => patch({'corner': r == 0 ? null : r})),
          _ => _lifts(n('lift'), (v) => patch({'lift': v == 0 ? null : v})),
        },
      );
    }
    return const Hint('Touch something on the page, then open its look.');
  }

  Future<void> _upload(String id, PickKind kind) async {
    final f = await pickMedia(context, kind);
    if (f == null || !mounted) return;
    setState(() => _progress = 0);
    try {
      final up = await uploadToR2(f, 'ui', 'tpl~$id', kind,
          onProgress: (p) => mounted ? setState(() => _progress = p) : null);
      UiOverrides.instance.primeFile(up.url, f);
      _step(() => c.patchProps(id, kind == PickKind.video ? {'fillVideo': up.url} : {'fillImage': up.url, 'fillVideo': null}));
    } catch (err) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('Upload failed: $err')));
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  Widget _corners(double now, ValueChanged<int> pick) => _Tiles(children: [
        for (final r in kLookCorners)
          _Tile(
            id: 'look-corner-$r',
            label: r == 0 ? 'Square' : '$r',
            selected: now.round() == r,
            onTap: () => pick(r),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r * 0.45),
                border: Border.all(color: kGold, width: 2),
              ),
            ),
          ),
      ]);

  Widget _lifts(double now, ValueChanged<int> pick) => _Tiles(children: [
        for (final (v, name) in kLookLifts)
          _Tile(
            id: 'look-lift-$v',
            label: name,
            selected: now.round() == v,
            onTap: () => pick(v),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5A3),
                borderRadius: BorderRadius.circular(8),
                boxShadow: v == 0 ? null : [BoxShadow(color: const Color(0xCC000000), blurRadius: v * 0.8, offset: Offset(0, v / 4))],
              ),
            ),
          ),
      ]);

  Widget _frame({required String title, required VoidCallback? reset, required List<Widget> chips, required Widget body}) {
    return ListView(
      key: const ValueKey('look-sheet'),
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [
        // All chips in view: they wrap rather than scroll away.
        Wrap(runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          ...chips,
          if (reset != null)
            IconButton(
              key: const ValueKey('look-reset'),
              tooltip: 'Reset look',
              onPressed: reset,
              icon: const Icon(Icons.restart_alt_rounded, color: kDim, size: 20),
            ),
        ]),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a), child: child),
          ),
          child: KeyedSubtree(key: ValueKey('$title/${_panel ?? ''}'), child: body),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.id, required this.label, required this.icon, required this.selected, required this.onTap});
  final String id;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Pill(label, key: ValueKey('look-chip-$id'), icon: icon, selected: selected, onTap: () {
          tapFeel();
          onTap();
        }),
      );
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, runSpacing: 10, children: children);
}

/// A big touch target showing what it does; a word under it at most.
class _Tile extends StatelessWidget {
  const _Tile({required this.id, required this.selected, required this.onTap, required this.child, this.label, this.wide = false});
  final String id;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String? label;
  final bool wide;

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: ValueKey(id),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: wide ? null : 68,
          height: wide ? 40 : 72,
          padding: wide ? const EdgeInsets.symmetric(horizontal: 14) : const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? const Color(0x33E8D5A3) : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? kGold : const Color(0x22FFFFFF), width: selected ? 2 : 1),
          ),
          child: wide
              ? Center(widthFactor: 1, child: child)
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Expanded(child: Center(child: child)),
                  if (label != null)
                    Text(label!, maxLines: 1, style: const TextStyle(color: kDim, fontSize: 10.5, fontWeight: FontWeight.w700)),
                ]),
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(children: [
          const Icon(Icons.pinch_rounded, color: kDim, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(color: kDim, fontSize: 12))),
        ]),
      );
}

/// Pinch to zoom in, drag to move the frame; the page above shows it live.
class _CropPad extends StatefulWidget {
  const _CropPad({
    required this.zoom,
    required this.x,
    required this.y,
    required this.onStart,
    required this.onChanged,
    required this.onEnd,
    required this.onReset,
  });
  final double zoom, x, y;
  final VoidCallback onStart;
  final void Function(double zoom, double x, double y) onChanged;
  final VoidCallback onEnd;
  final VoidCallback onReset;

  @override
  State<_CropPad> createState() => _CropPadState();
}

class _CropPadState extends State<_CropPad> {
  double _z0 = 1;
  late double _z = widget.zoom, _x = widget.x, _y = widget.y;

  @override
  void didUpdateWidget(_CropPad old) {
    super.didUpdateWidget(old);
    _z = widget.zoom;
    _x = widget.x;
    _y = widget.y;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = w * 9 / 16;
        // The visible window inside the whole picture.
        final vw = w / _z, vh = h / _z;
        final left = (w - vw) / 2 * (1 + _x), top = (h - vh) / 2 * (1 + _y);
        return GestureDetector(
          key: const ValueKey('look-crop-pad'),
          onScaleStart: (_) {
            _z0 = _z;
            widget.onStart();
          },
          onScaleUpdate: (d) {
            setState(() {
              _z = (_z0 * d.scale).clamp(1.0, 4.0);
              if (_z > 1.001) {
                _x = (_x + d.focalPointDelta.dx / ((w - vw) / 2).clamp(1, double.infinity)).clamp(-1.0, 1.0);
                _y = (_y + d.focalPointDelta.dy / ((h - vh) / 2).clamp(1, double.infinity)).clamp(-1.0, 1.0);
              }
            });
            widget.onChanged(_z, _x, _y);
          },
          onScaleEnd: (_) {
            actFeel();
            widget.onEnd();
          },
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Stack(children: [
              Positioned(
                left: left,
                top: top,
                width: vw,
                height: vh,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: kGold, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0x22E8D5A3),
                  ),
                ),
              ),
              const Center(child: Icon(Icons.pinch_rounded, color: kDim, size: 30)),
            ]),
          ),
        );
      }),
      const SizedBox(height: 8),
      Row(children: [
        Text('${_z.toStringAsFixed(1)}×', style: const TextStyle(color: kGold, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (_z > 1.001) Pill('Whole picture', dense: true, icon: Icons.fit_screen_rounded, onTap: widget.onReset),
      ]),
    ]);
  }
}
