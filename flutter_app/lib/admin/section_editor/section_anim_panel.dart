/// CS-7 animation controls: overlay (orb / Lottie), entry, scroll.
library;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import '../../widgets/sections/section_config.dart';
import '../editor/glass.dart';
import '../orb_picker.dart' show loadOrbGallery, OrbGalleryItem, orbLabel;

class SectionAnimPanel extends StatefulWidget {
  const SectionAnimPanel({
    super.key,
    required this.config,
    required this.onChanged,
    this.busy = false,
  });

  final SectionConfig config;
  final ValueChanged<SectionConfig> onChanged;
  final bool busy;

  @override
  State<SectionAnimPanel> createState() => _SectionAnimPanelState();
}

class _SectionAnimPanelState extends State<SectionAnimPanel> {
  List<OrbGalleryItem> _lottie = const [];

  @override
  void initState() {
    super.initState();
    loadOrbGallery().then((items) {
      if (mounted) setState(() => _lottie = items);
    });
  }

  SectionAnimation get _a => widget.config.animation;

  void _set(SectionAnimation a) =>
      widget.onChanged(widget.config.copyWith(animation: a));

  @override
  Widget build(BuildContext context) {
    final overlay = _a.overlay;
    return Glass(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Animation',
            style: TextStyle(color: kGold, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Entry', style: TextStyle(color: kDim, fontSize: 11)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in SectionEntryAnim.values)
                ChoiceChip(
                  label: Text(e.name),
                  selected: _a.entry == e,
                  onSelected: widget.busy
                      ? null
                      : (_) => _set(_a.copyWith(entry: e)),
                  selectedColor: kGold,
                  labelStyle: TextStyle(
                    color: _a.entry == e ? const Color(0xFF060C18) : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: const Color(0xFF121826),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Scroll', style: TextStyle(color: kDim, fontSize: 11)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final s in SectionScrollAnim.values)
                ChoiceChip(
                  label: Text(s.name),
                  selected: _a.scroll == s,
                  onSelected: widget.busy
                      ? null
                      : (_) => _set(_a.copyWith(scroll: s)),
                  selectedColor: kGold,
                  labelStyle: TextStyle(
                    color: _a.scroll == s ? const Color(0xFF060C18) : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: const Color(0xFF121826),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text('Overlay', style: TextStyle(color: kDim, fontSize: 11)),
              ),
              TextButton(
                onPressed: widget.busy || overlay == null
                    ? null
                    : () => _set(_a.copyWith(clearOverlay: true)),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            overlay == null
                ? 'None'
                : '${overlay.kind.name}${overlay.asset.isEmpty ? '' : ': ${overlay.asset}'}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text('Orbs', style: TextStyle(color: kGold, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in OrbState.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(orbLabel(s), style: const TextStyle(fontSize: 11)),
                      onPressed: widget.busy
                          ? null
                          : () => _set(_a.copyWith(
                                overlay: SectionOverlayAnim(
                                  kind: SectionOverlayKind.orb,
                                  asset: s.name,
                                ),
                              )),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Lottie', style: TextStyle(color: kGold, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: _lottie.isEmpty
                ? const Text('Loading…', style: TextStyle(color: kDim, fontSize: 11))
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final item in _lottie.take(24))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(item.label, style: const TextStyle(fontSize: 11)),
                            onPressed: widget.busy
                                ? null
                                : () => _set(_a.copyWith(
                                      overlay: SectionOverlayAnim(
                                        kind: SectionOverlayKind.lottie,
                                        asset: item.asset,
                                      ),
                                    )),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
