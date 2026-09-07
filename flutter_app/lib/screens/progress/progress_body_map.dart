/// Body & Mind — photoreal glass/cyan anatomical torso + organ hotspots.
///
/// Uses the website HBM asset (committed as assets/progress/glass-body-map.png)
/// with the same organ positions / chips as app/js/part035.js. No abstract SVG.
library;

import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/practice_progress.dart';
import 'progress_tokens.dart';

const kGlassBodyMapAsset = 'assets/progress/glass-body-map.png';
/// Same CDN URL the website HBM controller uses (runtime fallback).
const kGlassBodyMapUrl =
    'https://media.nowssb.com/migrated-images/83d9cdabd5ddf999_file_0000000046b07246a11b7146b9ae4c88_oj8ke2.png';

class _Organ {
  const _Organ({
    required this.key,
    required this.name,
    required this.color,
    required this.labels,
    required this.x,
    required this.y,
    required this.w,
  });
  final String key;
  final String name;
  final Color color;
  final List<String> labels;
  final double x; // percent
  final double y;
  final double w;
}

const _organs = <_Organ>[
  _Organ(key: 'brain', name: 'Brain & Mind', color: Color(0xFFBFE8FF), labels: ['Brain', 'Mind', 'Mind · Emotions'], x: 50, y: 14, w: 26),
  _Organ(key: 'lungs', name: 'Lungs & Breath', color: Color(0xFF9FE0FF), labels: ['Lungs · Heart', 'Lung', 'Lungs · Joints', 'Lungs'], x: 50, y: 56, w: 42),
  _Organ(key: 'heart', name: 'Heart & Energy', color: Color(0xFFFF9D9D), labels: ['Heart · Energy', 'Heart'], x: 53, y: 58, w: 16),
  _Organ(key: 'stomach', name: 'Core & Digestion', color: Color(0xFFFFD79C), labels: ['Solar Plexus', 'Liver · Digestion', 'Gut'], x: 55, y: 69, w: 18),
  _Organ(key: 'liver', name: 'Liver & Detox', color: Color(0xFFD9A8FF), labels: ['Liver', 'Liver · Detox'], x: 45, y: 71, w: 20),
  _Organ(key: 'immune', name: 'Immune System', color: Color(0xFF9DFFC6), labels: ['Immune System', 'Immune · Vitality'], x: 37, y: 63, w: 13),
  _Organ(key: 'nerves', name: 'Nervous System', color: Color(0xFFF7F0A0), labels: ['Nervous System'], x: 50, y: 51, w: 9),
  _Organ(key: 'skin', name: 'Skin & Eyes', color: Color(0xFFFFCAA0), labels: ['Eyes · Skin', 'Skin & Glow'], x: 50, y: 27, w: 16),
  _Organ(key: 'vitality', name: 'Vitality & Hormones', color: Color(0xFFF0A0FF), labels: ['Vitality', 'Testosterone & Hormones', 'Reproductive'], x: 50, y: 87, w: 24),
  _Organ(key: 'joints', name: 'Joints & Mobility', color: Color(0xFFA8C8FF), labels: ['Joints'], x: 50, y: 46, w: 48),
];

String? _matchOrganKey(String organStr) {
  final s = organStr.toLowerCase();
  for (final o in _organs) {
    for (final label in o.labels) {
      final l = label.toLowerCase();
      if (s.contains(l) || l.contains(s)) return o.key;
    }
  }
  return null;
}

class ProgressBodyMap extends StatefulWidget {
  const ProgressBodyMap({super.key, required this.progress, required this.words});
  final PracticeProgress progress;
  final List<Word> words;

  @override
  State<ProgressBodyMap> createState() => _ProgressBodyMapState();
}

class _ProgressBodyMapState extends State<ProgressBodyMap> {
  String? _tipKey;

  Map<String, int> _counts() {
    final counts = {for (final o in _organs) o.key: 0};
    final practiced = widget.progress.sessionsSnapshot
        .map((s) => '${s['word'] ?? ''}')
        .where((w) => w.isNotEmpty)
        .toList();
    final byWord = {for (final w in widget.words) w.word: w.organ};
    for (final word in practiced) {
      final organ = byWord[word];
      if (organ == null || organ.isEmpty) continue;
      final key = _matchOrganKey(organ);
      if (key != null) counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  void _showTip(String key) {
    setState(() => _tipKey = key);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && _tipKey == key) setState(() => _tipKey = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts();
    final activated = counts.values.where((c) => c > 0).length;
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final tip = _tipKey == null ? null : _organs.firstWhere((o) => o.key == _tipKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Healing Body Map',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MpColors.white),
            ),
            const Spacer(),
            Text(
              '$activated organs · $total activations',
              style: const TextStyle(fontSize: 11, color: Color(0xBFFFFFFF)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ProgressGlass(
          radius: 25,
          child: SizedBox(
            height: 360,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 56),
                    child: Image.asset(
                      kGlassBodyMapAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.network(
                        kGlassBodyMapUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.accessibility_new, color: Color(0x66FFFFFF), size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
                // Hotspots over the figure (percent of the image box).
                Positioned(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: 56,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return Stack(
                        children: [
                          for (final o in _organs)
                            Positioned(
                              left: (o.x / 100) * c.maxWidth - (o.w / 100) * c.maxWidth / 2,
                              top: (o.y / 100) * c.maxHeight - 10,
                              width: (o.w / 100) * c.maxWidth,
                              height: 22,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _showTip(o.key),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (counts[o.key] ?? 0) > 0
                                          ? o.color.withOpacity(0.9)
                                          : Colors.white.withOpacity(0.18),
                                      boxShadow: (counts[o.key] ?? 0) > 0
                                          ? [BoxShadow(color: o.color.withOpacity(0.55), blurRadius: 10)]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                if (tip != null)
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 64,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xE6050607),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tip.color.withOpacity(0.45)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tip.name, style: TextStyle(color: tip.color, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(
                              (counts[tip.key] ?? 0) > 0
                                  ? 'Activated ${counts[tip.key]} time${counts[tip.key] == 1 ? '' : 's'}'
                                  : 'Not yet activated — practice words that target this organ',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFBFC3C4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Text(
                    'Explore the areas you want to understand and improve through your practice.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, height: 1.55, color: Color(0xFFA2A7A8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in _organs)
              _Chip(
                label: o.name,
                color: o.color,
                count: counts[o.key] ?? 0,
                onTap: () => _showTip(o.key),
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.count,
    required this.onTap,
  });
  final String label;
  final Color color;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lit = count > 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x7A000000),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: lit ? color.withOpacity(0.45) : const Color(0x1AFFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lit ? color : const Color(0xFF606365),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                lit ? '$label · $count' : label,
                style: TextStyle(
                  fontSize: 10,
                  color: lit ? MpColors.white : const Color(0xFFBFC3C4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
