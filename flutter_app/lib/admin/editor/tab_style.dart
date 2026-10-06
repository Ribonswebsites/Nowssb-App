/// Style sheet (opened from a touched element): the look of the picked text or button — colour, font,
/// weight, spacing, italic, gradient ink, shadow/glow — plus a wrapper
/// shape around a button/CTA/chip label (circle, pill, rounded, none) with
/// its own fill, gradient, border, glow and glass. Ready-made looks up top.
/// Size is not here: pinch the words on the page.
library;

import 'package:flutter/material.dart';

import '../template/slot_keys.dart';
import '../template/style_apply.dart';
import 'editor_controller.dart';
import 'glass.dart';
import 'preview.dart';

class StyleTab extends StatelessWidget {
  const StyleTab({super.key, required this.c});
  final EditorController c;

  @override
  Widget build(BuildContext context) {
    final key = c.selectedSlot;
    final type = c.selectedType;
    if (key == null || type == null) {
      return const Hint('Tap a heading, a line of text or a button label on the page to style it.');
    }
    if (type == SlotType.image || type == SlotType.video) {
      return const Hint('Pictures and clips have no text style.\nTap Replace on the strip to change one.',
          icon: Icons.image_outlined);
    }
    if (type == SlotType.orb) {
      return const Hint('Orbs come from the + drawer: drag one onto the page.', icon: Icons.blur_circular_rounded);
    }
    final def = c.selectedDefault;
    final st = c.overrideOf(key)?.style ?? const <String, dynamic>{};
    void patch(Map<String, dynamic> p) => c.patchStyle(key, type, def, p);
    double n(String k, double d) => st[k] is num ? (st[k] as num).toDouble() : d;
    int? col(String k) => st[k] is num ? (st[k] as num).toInt() : null;
    final grad = st['gradient'] is List ? (st['gradient'] as List).whereType<num>().map((e) => e.toInt()).toList() : <int>[];
    final sample = slotFriendly(key, type, def);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      children: [
        Eyebrow('Styling: “$sample”',
            trailing: Pill('Reset look', dense: true, icon: Icons.restart_alt_rounded,
                onTap: st.isEmpty ? null : () => c.setStyle(key, type, def, const {}))),
        const Text('Ready-made text looks', style: TextStyle(color: kDim, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final e in kTextPresets.entries)
              _PresetCard(
                name: e.key,
                look: e.value,
                sample: sample.length > 14 ? sample.substring(0, 14) : sample,
                onTap: () {
                  actFeel();
                  final keepBox = {for (final k in st.keys) if (!_textish(k)) k: st[k]};
                  c.setStyle(key, type, def, {...keepBox, ...e.value});
                },
              ),
          ]),
        ),
        const Eyebrow('Text'),
        const Text('Colour', style: TextStyle(color: kDim, fontSize: 12)),
        const SizedBox(height: 6),
        ColorRow(value: col('color'), onPick: (v) => patch({'color': v, 'gradient': null})),
        const SizedBox(height: 10),
        const Text('Font', style: TextStyle(color: kDim, fontSize: 12)),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Pill('As designed', dense: true, selected: st['font'] == null, onTap: () => patch({'font': null})),
            ),
            for (final f in {...kBundledFonts, ...kGoogleFonts})
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () {
                    tapFeel();
                    patch({'font': f});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: st['font'] == f ? kGold : const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0x2EFFFFFF)),
                    ),
                    child: Text(f,
                        style: applyTextLook(
                          TextStyle(color: st['font'] == f ? kInk : Colors.white, fontSize: 13),
                          {'font': f},
                        )),
                  ),
                ),
              ),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Size: pinch the words on the page.', style: TextStyle(color: kDim, fontSize: 12)),
        ),
        LabeledSlider(
          label: 'Weight',
          value: n('weight', 400),
          min: 100,
          max: 900,
          divisions: 8,
          onChanged: (v) => patch({'weight': v.round()}),
          onReset: st['weight'] == null ? null : () => patch({'weight': null}),
        ),
        LabeledSlider(
          label: 'Letter spacing',
          value: n('spacing', 0),
          min: -2,
          max: 8,
          format: (v) => v.toStringAsFixed(1),
          onChanged: (v) => patch({'spacing': double.parse(v.toStringAsFixed(1))}),
          onReset: st['spacing'] == null ? null : () => patch({'spacing': null}),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Pill('Italic', icon: Icons.format_italic_rounded, dense: true, selected: st['italic'] == true,
              onTap: () => patch({'italic': st['italic'] == true ? null : true})),
          Pill('Gradient ink', icon: Icons.gradient_rounded, dense: true, selected: grad.length >= 2,
              onTap: () => patch({'gradient': grad.length >= 2 ? null : [0xFFF6E7B0, 0xFFB8904A]})),
          Pill('Shadow / glow', icon: Icons.blur_on_rounded, dense: true, selected: st['shadow'] != null,
              onTap: () => patch({'shadow': st['shadow'] != null ? null : 0xAAE8D5A3, 'shadowBlur': st['shadow'] != null ? null : 14})),
        ]),
        if (grad.length >= 2) ...[
          const SizedBox(height: 10),
          const Text('Gradient from', style: TextStyle(color: kDim, fontSize: 12)),
          const SizedBox(height: 6),
          ColorRow(value: grad[0], allowClear: false, onPick: (v) => patch({'gradient': [v!, grad[1]]})),
          const SizedBox(height: 6),
          const Text('…to', style: TextStyle(color: kDim, fontSize: 12)),
          const SizedBox(height: 6),
          ColorRow(value: grad[1], allowClear: false, onPick: (v) => patch({'gradient': [grad[0], v!]})),
        ],
        if (st['shadow'] != null) ...[
          const SizedBox(height: 10),
          const Text('Shadow colour', style: TextStyle(color: kDim, fontSize: 12)),
          const SizedBox(height: 6),
          ColorRow(value: col('shadow'), allowClear: false, onPick: (v) => patch({'shadow': v})),
          LabeledSlider(label: 'Softness', value: n('shadowBlur', 8), min: 0, max: 40, onChanged: (v) => patch({'shadowBlur': v.round()})),
          LabeledSlider(label: 'Drop', value: n('shadowDy', 2), min: -10, max: 10, onChanged: (v) => patch({'shadowDy': v.round()})),
        ],
        const Eyebrow('Button / chip wrapper'),
        const Text('Put a shape around it — for CTA labels, chips and buttons',
            style: TextStyle(color: kDim, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final e in kBoxPresets.entries)
              _PresetCard(
                name: e.key,
                look: e.value,
                sample: 'Go',
                onTap: () {
                  actFeel();
                  c.setStyle(key, type, def, {...st, ...e.value});
                },
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (id, label, icon) in const [
            ('none', 'None', Icons.block_rounded),
            ('pill', 'Pill', Icons.crop_16_9_rounded),
            ('rounded', 'Rounded', Icons.crop_square_rounded),
            ('circle', 'Circle', Icons.circle_outlined),
          ])
            Pill(label,
                icon: icon,
                dense: true,
                selected: (st['shape'] ?? 'none') == id,
                onTap: () => id == 'none'
                    ? patch({'shape': null, 'bg': null, 'bg2': null, 'border': null, 'glow': null, 'glass': null})
                    : patch({'shape': id})),
        ]),
        if ((st['shape'] ?? 'none') != 'none') ...[
          const SizedBox(height: 10),
          const Text('Fill', style: TextStyle(color: kDim, fontSize: 12)),
          const SizedBox(height: 6),
          ColorRow(value: col('bg'), onPick: (v) => patch({'bg': v})),
          const SizedBox(height: 6),
          const Text('Blend fill into (gradient)', style: TextStyle(color: kDim, fontSize: 12)),
          const SizedBox(height: 6),
          ColorRow(value: col('bg2'), onPick: (v) => patch({'bg2': v})),
          const SizedBox(height: 6),
          const Text('Border', style: TextStyle(color: kDim, fontSize: 12)),
          const SizedBox(height: 6),
          ColorRow(value: col('border'), onPick: (v) => patch({'border': v})),
          if (st['border'] != null)
            LabeledSlider(label: 'Border width', value: n('borderW', 1), min: 0.5, max: 4, format: (v) => v.toStringAsFixed(1),
                onChanged: (v) => patch({'borderW': double.parse(v.toStringAsFixed(1))})),
          const SizedBox(height: 6),
          const Text('Glow', style: TextStyle(color: kDim, fontSize: 12)),
          const SizedBox(height: 6),
          ColorRow(value: col('glow'), onPick: (v) => patch({'glow': v})),
          if (st['glow'] != null)
            LabeledSlider(label: 'Glow size', value: n('glowBlur', 18), min: 4, max: 48, onChanged: (v) => patch({'glowBlur': v.round()})),
          if (st['shape'] == 'rounded')
            LabeledSlider(label: 'Corner', value: n('radius', 14), min: 0, max: 30, onChanged: (v) => patch({'radius': v.round()})),
          LabeledSlider(label: 'Side space', value: n('padH', 16), min: 0, max: 40, onChanged: (v) => patch({'padH': v.round()})),
          LabeledSlider(label: 'Top/bottom space', value: n('padV', 8), min: 0, max: 24, onChanged: (v) => patch({'padV': v.round()})),
          Pill('Frosted glass', icon: Icons.blur_circular_rounded, dense: true, selected: st['glass'] == true,
              onTap: () => patch({'glass': st['glass'] == true ? null : true})),
        ],
      ],
    );
  }
}

bool _textish(String k) =>
    const {'color', 'font', 'size', 'weight', 'spacing', 'italic', 'gradient', 'shadow', 'shadowBlur', 'shadowDx', 'shadowDy'}
        .contains(k);

/// A live sample of a ready-made look.
class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.name, required this.look, required this.sample, required this.onTap});
  final String name;
  final Map<String, dynamic> look;
  final String sample;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      sample.isEmpty ? 'Aa' : sample,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: applyTextLook(const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600), {
        ...look,
        if (look['size'] is num) 'size': ((look['size'] as num).toDouble()).clamp(10, 20),
      }),
    );
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Glass(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: onTap,
        child: SizedBox(
          width: 118,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(child: Center(child: FittedBox(child: applyTextDecor(text, look)))),
            const SizedBox(height: 4),
            Text(name, style: const TextStyle(color: kDim, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
