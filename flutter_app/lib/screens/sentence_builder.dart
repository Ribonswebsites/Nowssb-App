/// Sentence builder — Customized-language glass full page (Flutter surface).
///
/// Black top banner, then "Building your sentence", then heavy glass
/// combine studio with Owned / Not owned glass tabs. Word chips live
/// BELOW the banner (never mixed into banner action rows). No emoji.
/// No background video/image in the combine area.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/content.dart';
import '../data/store_catalog.dart';
import '../widgets/black_glass_banner.dart';
import '../widgets/nwsb_icon.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';
import '../widgets/app_thinking_loader.dart';
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
  /// 0 = Owned, 1 = Not owned
  int _wordTab = 0;
  late final AnimationController _pulse;
  late final AnimationController _reveal;
  final _combineKey = GlobalKey();

  int get _max => sentenceTierMaxWords(tier: widget.tier);

  static const _seedOwned = <String>[
    'Peace', 'Breath', 'Light', 'Heart', 'Flow', 'Calm', 'Truth', 'Heal',
    'Dawn', 'Grace', 'Pulse', 'Still',
  ];

  List<String> get _owned {
    final lib = ContentStore.instance.library;
    if (lib.isNotEmpty) {
      return lib
          .map((w) => w.word)
          .where((s) => s.trim().isNotEmpty)
          .take(48)
          .toList();
    }
    return _seedOwned;
  }

  List<String> get _notOwned {
    final ownedLower = _owned.map((e) => e.toLowerCase()).toSet();
    final fromCatalog = <String>[];
    final seen = <String>{};
    for (final cat in kRmCategories) {
      for (final e in cat.words) {
        final raw = e.word.trim();
        if (raw.isEmpty) continue;
        final key = raw.toLowerCase();
        if (ownedLower.contains(key) || seen.contains(key)) continue;
        seen.add(key);
        fromCatalog.add(raw[0].toUpperCase() + raw.substring(1));
        if (fromCatalog.length >= 48) break;
      }
      if (fromCatalog.length >= 48) break;
    }
    if (fromCatalog.isNotEmpty) return fromCatalog;
    return const [
      'Vitality', 'Balance', 'Clarity', 'Harmony', 'Courage', 'Wisdom',
      'Nourish', 'Restore', 'Awaken', 'Ground', 'Radiance', 'Presence',
    ].where((w) => !ownedLower.contains(w.toLowerCase())).toList();
  }

  List<String> get _activeWords => _wordTab == 0 ? _owned : _notOwned;

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listen opens from your owned words in Practice.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _scrollToCombine() {
    final ctx = _combineKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    }
  }

  void _openRequest() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestCustomSheet(
        initialWords: _selected.toList(),
        onSubmitted: (text) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(
                text.trim().isEmpty
                    ? 'Request saved. Frequency X unlocks team-crafted words.'
                    : 'Rewrite and Request sent.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final owned = _owned;
    final notOwned = _notOwned;
    final active = _activeWords;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF060C18),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.55, -0.7),
                radius: 1.15,
                colors: [Color(0x66A78BFA), Color(0x00060C18)],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.9, 0.85),
                radius: 1.05,
                colors: [Color(0x44C8E8F5), Color(0x00060C18)],
              ),
            ),
          ),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: const ColoredBox(color: Color(0x55060C18)),
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
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + bottom),
                    children: [
                      // 1) Black top banner — actions only, no word chips
                      CustomizeBlackBanner(
                        title: 'Build your\nsentence',
                        subtitle: 'Combine owned words into one healing line',
                        onTap: _scrollToCombine,
                      ),
                      // Quick actions stay under the banner as nested rows
                      // (not mixed with word select)
                      NestedDarkWrap(
                        onTap: _listen,
                        child: _ActionRow(
                          mark: NwsbMarks.play,
                          title: 'Listen',
                          sub: 'Hear the words before you combine',
                        ),
                      ),
                      NestedDarkWrap(
                        onTap: _openRequest,
                        child: _ActionRow(
                          mark: NwsbMarks.features,
                          title: 'Request customized words',
                          sub: 'Rewrite and Request for your practice',
                        ),
                      ),
                      NestedDarkWrap(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const WordAtelierScreen(),
                            ),
                          );
                        },
                        child: _ActionRow(
                          mark: NwsbMarks.bag,
                          title: 'Buy / Shop words',
                          sub: 'Grow your library in the Store',
                        ),
                      ),
                      // 2) Heading BELOW the black banner
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 10, 4, 12),
                        child: Text(
                          'Building your sentence',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.35,
                          ),
                        ),
                      ),
                      // 3) Word select / combine studio — stronger glass
                      KeyedSubtree(
                        key: _combineKey,
                        child: HeavyGlassPanel(
                          margin: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NestedDarkWrap(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 14, 12, 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A0A12),
                                        borderRadius: BorderRadius.circular(11),
                                        border: Border.all(
                                          color: const Color(0x38FFFFFF),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: NwsbIcon(
                                        NwsbMarks.features,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Combine studio',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Pick words · weave · speak as one breath',
                                            style: TextStyle(
                                              color: Color(0x8CFFFFFF),
                                              fontSize: 11,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
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
                              ),
                              // Owned / Not owned glass tabs
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _WordPoolTab(
                                        label: 'Owned',
                                        count: owned.length,
                                        selected: _wordTab == 0,
                                        onTap: () =>
                                            setState(() => _wordTab = 0),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _WordPoolTab(
                                        label: 'Not owned',
                                        count: notOwned.length,
                                        selected: _wordTab == 1,
                                        onTap: () =>
                                            setState(() => _wordTab = 1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Active pool panel (glass)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(
                                    sigmaX: kHeavyGlassSigma,
                                    sigmaY: kHeavyGlassSigma,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0x18FFFFFF),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0x2EFFFFFF),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _wordTab == 0
                                              ? 'Owned words'
                                              : 'Not owned words',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _wordTab == 0
                                              ? 'Select at least 2 owned words. Your subconscious tier allows up to $_max.'
                                              : 'Preview shop words. Tap Buy / Shop words to unlock them for combining.',
                                          style: const TextStyle(
                                            color: Color(0x8CFFFFFF),
                                            fontSize: 12,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        if (active.isEmpty)
                                          const Text(
                                            'No words in this pool yet.',
                                            style: TextStyle(
                                              color: Color(0x73FFFFFF),
                                              fontSize: 12,
                                            ),
                                          )
                                        else
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              for (final w in active)
                                                _WordChip(
                                                  label: w,
                                                  selected:
                                                      _selected.contains(w),
                                                  locked: _wordTab == 1,
                                                  onTap: () {
                                                    if (_wordTab == 1) {
                                                      HapticFeedback
                                                          .selectionClick();
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Unlock this word in the Store to combine it.'),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          duration: Duration(
                                                              seconds: 2),
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    _toggle(w);
                                                  },
                                                ),
                                            ],
                                          ),
                                        if (_wordTab == 0) ...[
                                          const SizedBox(height: 18),
                                          AnimatedBuilder(
                                            animation: _pulse,
                                            builder: (context, child) {
                                              final glow =
                                                  0.35 + 0.25 * _pulse.value;
                                              final enabled =
                                                  _selected.length >= 2 &&
                                                      !_building;
                                              return GestureDetector(
                                                onTap:
                                                    enabled ? _combine : null,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 220),
                                                  height: 54,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    color: enabled
                                                        ? Colors.white
                                                        : const Color(
                                                            0x22FFFFFF),
                                                    boxShadow: enabled
                                                        ? [
                                                            BoxShadow(
                                                              color: Color
                                                                  .fromRGBO(
                                                                      255,
                                                                      255,
                                                                      255,
                                                                      glow *
                                                                          0.45),
                                                              blurRadius: 22,
                                                              spreadRadius: 1,
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                  child: _building
                                                      ? const AppThinkingLoader(size: 28, state: OrbState.composing, circlePad: 6)
                                                      : Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            NwsbIcon(
                                                              NwsbMarks
                                                                  .enterArrow,
                                                              size: 14,
                                                              viewBox: 12,
                                                              color: enabled
                                                                  ? const Color(
                                                                      0xFF0A0A12)
                                                                  : const Color(
                                                                      0x66FFFFFF),
                                                              strokeWidth: 1.9,
                                                              cap: 'square',
                                                            ),
                                                            const SizedBox(
                                                                width: 10),
                                                            Text(
                                                              'Combine into sentence',
                                                              style: TextStyle(
                                                                color: enabled
                                                                    ? const Color(
                                                                        0xFF0A0A12)
                                                                    : const Color(
                                                                        0x66FFFFFF),
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                letterSpacing:
                                                                    0.4,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_sentence != null)
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
                                    child: NestedDarkWrap(
                                      margin: const EdgeInsets.only(top: 10),
                                      padding: const EdgeInsets.all(16),
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
                                          const SizedBox(height: 14),
                                          GestureDetector(
                                            onTap: _openRequest,
                                            child: Container(
                                              height: 48,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: const Text(
                                                'Rewrite and Request',
                                                style: TextStyle(
                                                  color: Color(0xFF0A0A12),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
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

class _WordPoolTab extends StatelessWidget {
  const _WordPoolTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: kNotifGlassSigma,
            sigmaY: kNotifGlassSigma,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0x28FFFFFF)
                  : const Color(0x10FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? const Color(0x55FFFFFF)
                    : const Color(0x24FFFFFF),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xB8FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count words',
                  style: const TextStyle(
                    color: Color(0x73FFFFFF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.mark,
    required this.title,
    required this.sub,
  });
  final String mark;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0x38FFFFFF)),
          ),
          alignment: Alignment.center,
          child: NwsbIcon(mark, size: 18, color: Colors.white),
        ),
        Container(
          width: 1,
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: const Color(0x33FFFFFF),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(
                  color: Color(0x73FFFFFF),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x33FFFFFF)),
            color: const Color(0x14FFFFFF),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _RequestCustomSheet extends StatefulWidget {
  const _RequestCustomSheet({
    required this.initialWords,
    required this.onSubmitted,
  });
  final List<String> initialWords;
  final ValueChanged<String> onSubmitted;

  @override
  State<_RequestCustomSheet> createState() => _RequestCustomSheetState();
}

class _RequestCustomSheetState extends State<_RequestCustomSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialWords.isEmpty
          ? ''
          : 'Rewrite with: ${widget.initialWords.join(', ')}',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: HeavyGlassPanel(
        margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + safe),
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomizeBlackBanner(
              title: 'Request customized\nwords',
              subtitle: 'Tuned to your practice · Frequency X',
              margin: const EdgeInsets.only(bottom: 12),
            ),
            NestedDarkWrap(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Describe the words you need',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ctrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Organ focus, feeling, language…',
                      hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
                      filled: true,
                      fillColor: const Color(0x14FFFFFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0x99E8D5A3)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onSubmitted(_ctrl.text);
              },
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Rewrite and Request',
                  style: TextStyle(
                    color: Color(0xFF0A0A12),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
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
    this.locked = false,
  });
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : locked
                  ? const Color(0x12FFFFFF)
                  : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white
                : locked
                    ? const Color(0x22FFFFFF)
                    : const Color(0x33FFFFFF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF0A0A12)
                : locked
                    ? const Color(0x88FFFFFF)
                    : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
