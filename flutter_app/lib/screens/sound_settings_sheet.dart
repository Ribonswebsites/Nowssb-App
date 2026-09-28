import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/settings.dart';
import '../widgets/colored_split_promo_banner.dart';
import '../admin/template/editable.dart';

/// Equalizer, boost, presets, and the on-device spatial voice.
/// Opened from the player settings button and from Equalizer in Music Player Settings.
Future<void> showSoundSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0C0C10),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: const SoundSettingsSheet(),
      );
    },
  );
}

class SoundSettingsSheet extends StatefulWidget {
  const SoundSettingsSheet({super.key});

  @override
  State<SoundSettingsSheet> createState() => _SoundSettingsSheetState();
}

class _SoundSettingsSheetState extends State<SoundSettingsSheet> {
  final FlutterTts _preview = FlutterTts();
  var _busy = false;

  static const _presets = [
    ('Flat', 'flat'),
    ('Bass', 'deep'),
    ('Vocal', 'focus'),
    ('Bright', 'bright'),
    ('Wide', 'custom'),
  ];

  static const _bands = ['Low', 'Low-mid', 'Mid', 'High', 'Air'];

  @override
  void dispose() {
    _preview.stop();
    super.dispose();
  }

  Future<void> _hear() async {
    if (_busy) return;
    setState(() => _busy = true);
    final prefs = Settings.instance;
    final bands = prefs.eqBands;
    var pitch = 1.0;
    var rate = 0.42;
    if (bands.length >= 5) {
      pitch *= 1 + bands[4] * 0.22 - bands[0] * 0.2;
      rate = (rate * (1 + bands[2] * 0.12)).clamp(0.2, 0.85);
    }
    if (prefs.bassBoost) pitch *= 0.86;
    var volume = prefs.bassBoost ? 1.0 : 0.85;
    try {
      await _preview.awaitSpeakCompletion(true);
      await _preview.setLanguage('en-US');
      await _preview.setSpeechRate(rate);
      await _preview.setPitch(pitch.clamp(0.5, 2.0));
      await _preview.setVolume(volume);
      await _preview.stop();
      await _preview.speak('NowssB');
      if (prefs.spatialAudio) {
        await _preview.setPitch((pitch * 1.16).clamp(0.5, 2.0));
        await _preview.setVolume(0.4);
        await _preview.speak('NowssB');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: EditableLabel('sound_settings_sheet.SoundSettingsSheet', 'Voice preview needs speech on this phone.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _how() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14121A),
        title: const EditableLabel('sound_settings_sheet.SoundSettingsSheet',
          'Sounds Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const EditableLabel('sound_settings_sheet.SoundSettingsSheet',
          'Flat, Bass, Vocal, Bright, and Wide are starting points. Drag a fader to shape that band. Boost makes the voice louder and deeper. Spatial plays the word, then a softer reflection on this phone.',
          style: TextStyle(color: Color(0xCCFFFFFF), height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const EditableLabel('sound_settings_sheet.SoundSettingsSheet', 'Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Settings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final bands = s.eqBands;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredSplitPromoBanner(
                  margin: EdgeInsets.zero,
                  height: 118,
                  spec: SplitPromoSpec(
                    title: 'Sounds\nSettings',
                    cta: 'How it works',
                    leftColor: const Color(0xFF1A2744),
                    rightColor: const Color(0xFF7C4DFF),
                    art: SplitPromoArts.redHairBlazer,
                    onTap: _how,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final preset = _presets[i];
                      final on = s.eq == preset.$2;
                      return GestureDetector(
                        onTap: () => s.setEq(preset.$2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on ? const Color(0xFF2EC4B6) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            preset.$1,
                            style: TextStyle(
                              color: on ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 168,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Expanded(
                          child: _Fader(
                            label: _bands[i],
                            value: (i < bands.length ? bands[i] : 0).toDouble(),
                            onChanged: (v) {
                              final next = [...s.eqBands];
                              while (next.length < 5) {
                                next.add(0);
                              }
                              next[i] = v;
                              s.setEqBands(next);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const EditableLabel('sound_settings_sheet.SoundSettingsSheet', 'Boost sound', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  subtitle: const EditableLabel('sound_settings_sheet.SoundSettingsSheet', 'Louder, deeper voice', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                  value: s.bassBoost,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFFE8D5A3),
                  onChanged: (_) => s.toggleBass(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const EditableLabel('sound_settings_sheet.SoundSettingsSheet', 'Spatial audio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  subtitle: const EditableLabel('sound_settings_sheet.SoundSettingsSheet',
                    'Tap How it works on the banner.',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                  ),
                  value: s.spatialAudio,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFFE8D5A3),
                  onChanged: s.setSpatial,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8D5A3),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _busy ? null : _hear,
                  child: Text(_busy ? 'Playing…' : 'Preview this sound'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Fader extends StatelessWidget {
  const _Fader({required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final h = box.maxHeight;
              final t = ((value + 1) / 2).clamp(0.0, 1.0);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (d) {
                  final next = (1 - (d.localPosition.dy / h)) * 2 - 1;
                  onChanged(next.clamp(-1.0, 1.0));
                },
                onTapDown: (d) {
                  final next = (1 - (d.localPosition.dy / h)) * 2 - 1;
                  onChanged(next.clamp(-1.0, 1.0));
                },
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 3,
                          height: h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3A40),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 3,
                            height: h * t,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8D5A3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: (h - 18) * t,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8D5A3),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1A1408), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        EditableLabel('sound_settings_sheet.Fader', label, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 10)),
      ],
    );
  }
}
