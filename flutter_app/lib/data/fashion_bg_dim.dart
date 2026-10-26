import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/concept/doors/film_dial.dart';

/// How much the Fashion background video is dimmed, 0 (film as-is) … 1
/// (black), so the cards on top stay readable. Saved under
/// [prefKey]; [value] updates live while a slider drags.
class FashionBgDim extends ValueNotifier<double> {
  FashionBgDim._() : super(defaultDim);
  static final FashionBgDim instance = FashionBgDim._();

  static const prefKey = 'nwsb_fashplus_bg_dim';
  static const defaultDim = 0.45;

  /// Called with every change (drag frames included) — for analytics or a
  /// redesigned control that wants to mirror the value.
  static final List<ValueChanged<double>> onDimChanged = [];

  /// Fallback switch: true shows the stock slider instead of [FilmDial].
  static bool useSlider = false;

  /// Freezes the dial's spark orbit (tests and shots only).
  static double? debugDialPhase;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      value = (p.getDouble(prefKey) ?? defaultDim).clamp(0.0, 1.0);
    } catch (_) {}
  }

  /// Live update; [persist] writes the pref (sliders persist on release).
  Future<void> set(double v, {bool persist = true}) async {
    final next = v.clamp(0.0, 1.0);
    if (next != value) {
      value = next;
      for (final f in List.of(onDimChanged)) {
        f(next);
      }
    }
    if (persist) {
      try {
        final p = await SharedPreferences.getInstance();
        await p.setDouble(prefKey, next);
      } catch (_) {}
    }
  }
}

/// The dark layer over the Fashion background video. Ignores taps.
class FashionBgDimOverlay extends StatelessWidget {
  const FashionBgDimOverlay({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ValueListenableBuilder<double>(
          valueListenable: FashionBgDim.instance,
          builder: (_, v, __) => ColoredBox(
            key: const ValueKey('fashion-bg-dim'),
            color: Colors.black.withValues(alpha: v),
          ),
        ),
      );
}

/// The dim control: the designer's [FilmDial], which shows how much film
/// shows (film = 1 - dim; the stored dim and its 0.45 default are unchanged,
/// so the dial opens at 55%). Live on drag, saved on release or an a11y step. Falls back to [FashionBgDimSlider] when
/// [FashionBgDim.useSlider] is set or there is no room for the dial.
class FashionBgDimControl extends StatelessWidget {
  const FashionBgDimControl({super.key});

  /// Narrowest width the dial is drawn at; below it the slider is used.
  static const minDial = 200.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        if (FashionBgDim.useSlider || !w.isFinite || w < minDial) return const FashionBgDimSlider();
        return ValueListenableBuilder<double>(
          valueListenable: FashionBgDim.instance,
          builder: (context, v, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Background film',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              const Text('How much of the video shows behind the cards',
                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
              const SizedBox(height: 12),
              FilmDial(
                key: const ValueKey('fashion-bg-dim-dial'),
                value: 1 - v,
                size: w < 250 ? w : 250,
                debugPhase: FashionBgDim.debugDialPhase,
                onChanged: (film) => FashionBgDim.instance.set(1 - film, persist: false),
                onChangeEnd: (film) => FashionBgDim.instance.set(1 - film),
              ),
            ],
          ),
        );
      });
}

/// Fallback control (stock slider), also in film % (1 - dim).
class FashionBgDimSlider extends StatelessWidget {
  const FashionBgDimSlider({super.key, this.onDimChanged});
  final ValueChanged<double>? onDimChanged;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: FashionBgDim.instance,
        builder: (context, v, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                child: Text('Background film',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Text('${((1 - v) * 100).round()}%',
                  key: const ValueKey('fashion-bg-dim-value'),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
            const Text('How much of the video shows behind the cards',
                style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
            Slider(
              key: const ValueKey('fashion-bg-dim-slider'),
              value: 1 - v,
              divisions: 20,
              label: '${((1 - v) * 100).round()}%',
              activeColor: Colors.white,
              inactiveColor: const Color(0x55FFFFFF),
              onChanged: (film) {
                FashionBgDim.instance.set(1 - film, persist: false);
                onDimChanged?.call(1 - film);
              },
              onChangeEnd: (film) => FashionBgDim.instance.set(1 - film),
            ),
          ],
        ),
      );
}
