/// The admin look: black, the app's own Fashion film behind frosted glass,
/// gold for actions, mint for "changed". Shared by the admin home and the
/// UI Editor.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


const kGold = Color(0xFFE8D5A3);
const kMint = Color(0xFF34D399);
const kInk = Color(0xFF060C18);
const kGlassFill = Color(0x14FFFFFF);
const kGlassEdge = Color(0x24FFFFFF);
const kDim = Color(0x99FFFFFF);
const kFaint = Color(0x55FFFFFF);

void tapFeel() => HapticFeedback.selectionClick();
void actFeel() => HapticFeedback.lightImpact();
void bigFeel() => HapticFeedback.mediumImpact();

/// The Admin app's own backdrop — deep night blue with a gold and a violet
/// glow, nothing from the member app's film — and its veil, behind every
/// admin page. Static, so it never takes a video decoder.
class AdminBackdrop extends StatelessWidget {
  const AdminBackdrop({super.key, required this.child, this.dim = 0.35});
  final Widget child;
  final double dim;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(children: [
        const Positioned.fill(child: AdminAurora()),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 0.9,
                  colors: [
                    Colors.black.withValues(alpha: dim * 0.4),
                    Colors.black.withValues(alpha: dim),
                    Colors.black.withValues(alpha: (dim + 0.35).clamp(0, 1)),
                  ],
                  stops: const [0.2, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ]),
    );
  }
}

/// Night-blue field with soft gold (top left) and violet (bottom right) light.
class AdminAurora extends StatelessWidget {
  const AdminAurora({super.key});
  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1426), Color(0xFF070B16), Color(0xFF04060C)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(children: [
          Positioned(left: -120, top: -140, child: _Glow(color: Color(0x40E8D5A3), size: 420)),
          Positioned(right: -150, bottom: -120, child: _Glow(color: Color(0x33B79CFF), size: 460)),
          Positioned(right: -80, top: 220, child: _Glow(color: Color(0x1A34D399), size: 260)),
        ]),
      );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );
}

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.fill = kGlassFill,
    this.edge = kGlassEdge,
    this.blur = 18,
    this.glow,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color fill;
  final Color edge;
  final double blur;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget body = ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: r,
            border: Border.all(color: edge),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (glow != null) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: [BoxShadow(color: glow!, blurRadius: 24, spreadRadius: -4)],
        ),
        child: body,
      );
    }
    if (onTap == null) return body;
    return _Pressable(onTap: onTap!, child: body);
  }
}

/// Springs down a touch when pressed.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          tapFeel();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      );
}

/// A small rounded pill: a label, optional icon, selected = gold.
class Pill extends StatelessWidget {
  const Pill(
    this.label, {
    super.key,
    this.icon,
    this.selected = false,
    this.onTap,
    this.tooltip,
    this.color = kGold,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? kInk : (onTap == null ? kFaint : Colors.white);
    Widget p = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 14, vertical: dense ? 6 : 9),
      decoration: BoxDecoration(
        color: selected ? color : const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: selected ? color : const Color(0x2EFFFFFF)),
        boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14)] : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: dense ? 14 : 16, color: fg),
          const SizedBox(width: 6),
        ],
        Text(label,
            style: TextStyle(color: fg, fontSize: dense ? 11.5 : 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
      ]),
    );
    if (onTap != null) {
      p = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          tapFeel();
          onTap!();
        },
        child: p,
      );
    }
    if (tooltip != null) p = Tooltip(message: tooltip!, child: p);
    return p;
  }
}

/// Two-way pill switch (Normal home | Fashion home).
class PillSwitch extends StatelessWidget {
  const PillSwitch({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: kGlassEdge),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < labels.length; i++)
          GestureDetector(
            onTap: () {
              if (i == index) return;
              tapFeel();
              onChanged(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: i == index ? kGold : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                    color: i == index ? kInk : kDim,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  )),
            ),
          ),
      ]),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Row(children: [
          Expanded(
            child: Text(text.toUpperCase(),
                style: const TextStyle(color: kGold, fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

class Hint extends StatelessWidget {
  const Hint(this.text, {super.key, this.icon = Icons.touch_app_rounded});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(children: [
          Icon(icon, color: kFaint, size: 30),
          const SizedBox(height: 8),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: kDim, fontSize: 13, height: 1.4)),
        ]),
      );
}

/// A labelled slider with its value.
class LabeledSlider extends StatelessWidget {
  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.format,
    this.onReset,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? format;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 92, child: Text(label, style: const TextStyle(color: kDim, fontSize: 12))),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: kGold,
            inactiveTrackColor: const Color(0x33FFFFFF),
            thumbColor: kGold,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
      ),
      SizedBox(
        width: 44,
        child: Text(format?.call(value) ?? value.toStringAsFixed(0),
            textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
      if (onReset != null)
        IconButton(
          tooltip: 'Back to original',
          visualDensity: VisualDensity.compact,
          onPressed: onReset,
          icon: const Icon(Icons.restart_alt_rounded, size: 16, color: kFaint),
        ),
    ]);
  }
}

/// The colour swatches + a custom picker (hue / lightness / opacity).
const kPalette = <int>[
  0xFFFFFFFF, 0xFF000000, 0xFFE8D5A3, 0xFFB8904A, 0xFF34D399, 0xFF7CFFCB,
  0xFF2CB1FF, 0xFF7F5AF0, 0xFFFF4D8D, 0xFFFF7A59, 0xFFFFC857, 0xFF0F1828,
  0x66FFFFFF, 0x33000000,
];

class ColorRow extends StatelessWidget {
  const ColorRow({super.key, required this.value, required this.onPick, this.allowClear = true});
  final int? value;
  final ValueChanged<int?> onPick;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        if (allowClear)
          _Swatch(
            color: null,
            selected: value == null,
            onTap: () => onPick(null),
          ),
        for (final c in kPalette)
          _Swatch(color: Color(c), selected: value == c, onTap: () => onPick(c)),
        GestureDetector(
          onTap: () async {
            tapFeel();
            final v = await pickCustomColor(context, value ?? 0xFFE8D5A3);
            if (v != null) onPick(v);
          },
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red,
              ]),
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.onTap});
  final Color? color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          tapFeel();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.transparent,
            border: Border.all(color: selected ? kGold : const Color(0x44FFFFFF), width: selected ? 2.5 : 1),
          ),
          child: color == null ? const Icon(Icons.block_rounded, size: 16, color: kFaint) : null,
        ),
      );
}

Future<int?> pickCustomColor(BuildContext context, int start) {
  var hsl = HSLColor.fromColor(Color(start));
  var alpha = Color(start).a;
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    backgroundColor: const Color(0xF20B1120),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        final c = hsl.toColor().withValues(alpha: alpha);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: kGlassEdge)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Custom colour',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: kInk),
                onPressed: () => Navigator.of(ctx).pop(c.toARGB32()),
                child: const Text('Use it'),
              ),
            ]),
            const SizedBox(height: 12),
            LabeledSlider(
              label: 'Colour',
              value: hsl.hue,
              min: 0,
              max: 360,
              onChanged: (v) => set(() => hsl = hsl.withHue(v)),
            ),
            LabeledSlider(
              label: 'Strength',
              value: hsl.saturation * 100,
              min: 0,
              max: 100,
              onChanged: (v) => set(() => hsl = hsl.withSaturation(v / 100)),
            ),
            LabeledSlider(
              label: 'Lightness',
              value: hsl.lightness * 100,
              min: 0,
              max: 100,
              onChanged: (v) => set(() => hsl = hsl.withLightness(v / 100)),
            ),
            LabeledSlider(
              label: 'See-through',
              value: (1 - alpha) * 100,
              min: 0,
              max: 100,
              onChanged: (v) => set(() => alpha = 1 - v / 100),
            ),
          ]),
        );
      },
    ),
  );
}

/// Asks "are you sure?" in plain words.
Future<bool> confirmAction(BuildContext context, String title, String body, {String yes = 'Yes'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF0F1828),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(body, style: const TextStyle(color: kDim)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: kInk),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return r == true;
}
