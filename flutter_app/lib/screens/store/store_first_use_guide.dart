/// One-time, dismissable first-use guide for Store, Word Atelier and
/// Meaning Store. Shown once per [guideKey]; the "?" button reopens it.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreGuideStep {
  const StoreGuideStep(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const storeGuideSteps = <StoreGuideStep>[
  StoreGuideStep(Icons.storefront_rounded, 'Welcome to the Store',
      'Browse words, meanings, signature words and e-books. Prices show in your local currency.'),
  StoreGuideStep(Icons.auto_awesome_rounded, 'Word Atelier',
      'Open a word to see its levels and details before you buy.'),
  StoreGuideStep(Icons.menu_book_rounded, 'Meaning Store',
      'Unlock deeper meanings for words you love.'),
  StoreGuideStep(Icons.shopping_bag_rounded, 'Your bag',
      'Tap the bag at the top to review items and check out.'),
];

class StoreFirstUseGuide extends StatefulWidget {
  const StoreFirstUseGuide({
    super.key,
    required this.guideKey,
    required this.child,
    this.steps = storeGuideSteps,
    this.helpButton = true,
  });

  /// False when the page puts a [StoreGuideButton] in its own header.
  final bool helpButton;

  final String guideKey;
  final Widget child;
  final List<StoreGuideStep> steps;

  static String prefKey(String k) => 'guide_seen_$k';

  @override
  State<StoreFirstUseGuide> createState() => StoreFirstUseGuideState();
}

class StoreFirstUseGuideState extends State<StoreFirstUseGuide> {
  bool _show = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!(p.getBool(StoreFirstUseGuide.prefKey(widget.guideKey)) ?? false) && mounted) {
        setState(() => _show = true);
      }
    } catch (_) {}
  }

  void open() => setState(() {
        _step = 0;
        _show = true;
      });

  Future<void> _dismiss() async {
    setState(() => _show = false);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(StoreFirstUseGuide.prefKey(widget.guideKey), true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final s = steps[_step.clamp(0, steps.length - 1)];
    final last = _step >= steps.length - 1;
    return Stack(children: [
      widget.child,
      if (widget.helpButton)
      Positioned(
        bottom: MediaQuery.paddingOf(context).bottom + 96,
        left: 8,
        child: Semantics(
          button: true,
          label: 'Open store guide',
          child: IconButton(
            key: const Key('storeGuideHelp'),
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
            onPressed: open,
          ),
        ),
      ),
      if (_show)
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0x66000000),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      key: const Key('storeGuideCard'),
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0x55FFFFFF)),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(s.icon, color: Colors.white, size: 44),
                        const SizedBox(height: 14),
                        Semantics(
                          header: true,
                          child: Text(s.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 8),
                        Text(s.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
                        const SizedBox(height: 14),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (var i = 0; i < steps.length; i++)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _step ? Colors.white : const Color(0x66FFFFFF),
                              ),
                            ),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          TextButton(
                            key: const Key('storeGuideSkip'),
                            onPressed: _dismiss,
                            child: const Text('Skip', style: TextStyle(color: Color(0xCCFFFFFF))),
                          ),
                          const Spacer(),
                          FilledButton(
                            key: const Key('storeGuideNext'),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: const StadiumBorder()),
                            onPressed: last ? _dismiss : () => setState(() => _step++),
                            child: Text(last ? 'Got it' : 'Next'),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

extension StoreGuideWrap on Widget {
  Widget withStoreGuide([String key = 'store_home', bool helpButton = true]) =>
      StoreFirstUseGuide(guideKey: key, helpButton: helpButton, child: this);
}

/// Header "?" that reopens the nearest first-use guide.
class StoreGuideButton extends StatelessWidget {
  const StoreGuideButton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Open store guide',
        excludeSemantics: true,
        onTap: () => context.findAncestorStateOfType<StoreFirstUseGuideState>()?.open(),
        child: IconButton(
          key: const Key('storeGuideHelp'),
          icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
          onPressed: () => context.findAncestorStateOfType<StoreFirstUseGuideState>()?.open(),
        ),
      );
}
