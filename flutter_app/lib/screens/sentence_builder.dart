/// Sentence builder — glassmorphic full page (Flutter surface).
///
/// Mirrors website/WebView `#sub-sentence-builder`: black glass banners with
/// white-circle SVG icons on the right, owned-word combine flow gated by
/// subconscious tier (2…6 words), Notifications-level backdrop blur.
/// No emoji.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../widgets/black_glass_banner.dart';
import '../widgets/nwsb_icon.dart';
import 'store.dart';
import 'store/word_atelier.dart';

/// Subconscious tier → max words selectable when combining.
/// Starts at 2 (free); highest tier caps at 6.
int sentenceTierMaxWords({String? tier}) {
  switch ((tier ?? 'free').toLowerCase()) {
    case 'frequencyx':
    case 'elite_x':
      return 6;
    case 'frequency':
    case 'elite':
      return 5;
    case 'resonance':
    case 'pro':
      return 4;
    case 'trial':
      return 3;
    default:
      return 2;
  }
}

class SentenceBuilderScreen extends StatefulWidget {
  const SentenceBuilderScreen({super.key, this.tier});

  /// Optional plan tier override (resonance / frequency / frequencyX).
  final String? tier;

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen>
    with TickerProviderStateMixin {
  final Set<String> _selected = {};
  String? _sentence;
  bool _building = false;
  late final AnimationController _pulse;
  late final AnimationController _reveal;

  int get _max => sentenceTierMaxWords(tier: widget.tier);

  static const _seed = <String>[
    'Peace', 'Breath', 'Light', 'Heart', 'Flow', 'Calm', 'Truth', 'Heal',
    'Dawn', 'Grace', 'Pulse', 'Still',
  ];

  List<String> get _owned {
    final lib = ContentStore.instance.library;
    if (lib.isNotEmpty) {
      return lib.map((w) => w.word).where((s) => s.trim().isNotEmpty).take(48).toList();
    }
    return _seed;
  }

  @override
  void initState() {
    super.initState();
    ContentStore.instance.start();
    ContentStore.instance.addListener(_onContent);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
  }

  void _onContent() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    _pulse.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _toggle(String w) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(w)) {
        _selected.remove(w);
      } else if (_selected.length < _max) {
        _selected.add(w);
      } else {
        HapticFeedback.heavyImpact();
      }
      _sentence = null;
      _reveal.value = 0;
    });
  }

  Future<void> _combine() async {
    if (_selected.length < 2 || _building) return;
    setState(() => _building = true);
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    final words = _selected.toList();
    // Local polished compose — AI path lives on web; Flutter stays offline-safe.
    final woven = _composeLocal(words);
    if (!mounted) return;
    setState(() {
      _sentence = woven;
      _building = false;
    });
    _reveal
      ..reset()
      ..forward();
  }

  String _composeLocal(List<String> words) {
    if (words.length == 2) {
      return 'With ${words[0]} and ${words[1]}, the body remembers how to soften.';
    }
    if (words.length == 3) {
      return '${words[0]} meets ${words[1]}, and ${words[2]} closes the circle.';
    }
    final head = words.sublist(0, words.length - 1).join(', ');
    final last = words.last;
    return 'From $head to $last — one healing sentence, spoken as one breath.';
  }

  void _listen() {
    HapticFeedback.selectionClick();
    // Play through existing practice entry when available.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listen opens from your owned words in Practice.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owned = _owned;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFF060C18),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft radial glass backdrop (Notifications-level language).
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.75),
                radius: 1.1,
                colors: [Color(0x55E8D5A3), Color(0x00060C18)],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.85, 0.9),
                radius: 1.0,
                colors: [Color(0x44C8E8F5), Color(0x00060C18)],
              ),
            ),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: const ColoredBox(color: Color(0x66060C18)),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 16, 8),
                  child: Row(
                    children: [
                      _RoundBack(onTap: () => Navigator.of(context).maybePop()),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Sentence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      Text(
                        'TIER · $_max',
                        style: const TextStyle(
                          color: Color(0x99E8D5A3),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + MediaQuery.paddingOf(context).bottom),
                    children: [
                      BlackGlassBanner(
                        title: 'Build your sentence',
                        subtitle: 'Combine owned words into one healing line',
                        mark: NwsbMarks.sound,
                        margin: const EdgeInsets.only(bottom: 14),
                      ),
                      BlackGlassBanner(
                        title: 'All words owned',
                        subtitle: '${owned.length} words ready to weave',
                        mark: NwsbMarks.book,
                        onTap: () => setState(() {}),
                      ),
                      BlackGlassBanner(
                        title: 'Listen',
                        subtitle: 'Hear the words before you combine',
                        mark: NwsbMarks.play,
                        onTap: _listen,
                      ),
                      BlackGlassBanner(
                        title: 'Request customized words',
                        subtitle: 'Ask for words tuned to your practice',
                        mark: NwsbMarks.features,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Custom word requests open with Frequency X.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      BlackGlassBanner(
                        title: 'Buy / Shop words',
                        subtitle: 'Grow your library in the Store',
                        mark: NwsbMarks.bag,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const WordAtelierScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      NotifGlassPanel(
                        margin: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Combine words',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_selected.length} / $_max',
                                  style: const TextStyle(
                                    color: Color(0xB8FFFFFF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Select at least 2 owned words. Your subconscious tier allows up to $_max.',
                              style: const TextStyle(
                                color: Color(0x8CFFFFFF),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final w in owned)
                                  _WordChip(
                                    label: w,
                                    selected: _selected.contains(w),
                                    onTap: () => _toggle(w),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (context, child) {
                                final glow = 0.35 + 0.25 * _pulse.value;
                                final enabled = _selected.length >= 2 && !_building;
                                return GestureDetector(
                                  onTap: enabled ? _combine : null,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    height: 52,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: enabled
                                          ? Colors.white
                                          : const Color(0x22FFFFFF),
                                      boxShadow: enabled
                                          ? [
                                              BoxShadow(
                                                color: Color.fromRGBO(
                                                    255, 255, 255, glow * 0.45),
                                                blurRadius: 22,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: _building
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Color(0xFF0A0A12),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              NwsbIcon(
                                                NwsbMarks.enterArrow,
                                                size: 14,
                                                viewBox: 12,
                                                color: enabled
                                                    ? const Color(0xFF0A0A12)
                                                    : const Color(0x66FFFFFF),
                                                strokeWidth: 1.9,
                                                cap: 'square',
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Combine into sentence',
                                                style: TextStyle(
                                                  color: enabled
                                                      ? const Color(0xFF0A0A12)
                                                      : const Color(0x66FFFFFF),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              },
                            ),
                            if (_sentence != null) ...[
                              const SizedBox(height: 16),
                              FadeTransition(
                                opacity: _reveal,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.12),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: _reveal,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: ScaleTransition(
                                    scale: Tween<double>(begin: 0.96, end: 1)
                                        .animate(CurvedAnimation(
                                      parent: _reveal,
                                      curve: Curves.easeOutBack,
                                    )),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xCC000000),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0x33FFFFFF),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'YOUR SENTENCE',
                                            style: TextStyle(
                                              color: Color(0xFFE8D5A3),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.8,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            _sentence!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500,
                                              height: 1.45,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: math.max(12, top * 0.05)),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const StoreScreen(),
                          ),
                        ),
                        child: const Text(
                          'Open full Store',
                          style: TextStyle(color: Color(0xB8FFFFFF)),
                        ),
                      ),
                    ],
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

class _RoundBack extends StatelessWidget {
  const _RoundBack({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: NwsbIcon(
              '<path d="M15 6l-6 6 6 6"/>',
              size: 18,
              color: const Color(0xFF0A0A12),
              strokeWidth: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.white : const Color(0x33FFFFFF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF0A0A12) : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

