/// Rebuilt Signature Words page (spec 14 "Signature Words", 19).
/// Behind flag `newui_signature` via the shared kit (NewUi / AppRoutes).
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'signature_models.dart';
import '../../nowssb_ui/nowssb_ui.dart' hide Rarity;
import 'signature_widgets.dart';
import '../../widgets/nwsb_coin_fly.dart' show NwsbCoinDisc;

class SignatureWordsPage extends StatefulWidget {
  const SignatureWordsPage({super.key, this.source = const DemoSignatureSource(), this.reduceEffects = false});
  final SignatureSource source;
  final bool reduceEffects;
  @override
  State<SignatureWordsPage> createState() => _SignatureWordsPageState();
}

enum _Status { loading, ready, error, offline }

class _SignatureWordsPageState extends State<SignatureWordsPage> {
  _Status _status = _Status.loading;
  List<SignatureWord> _words = const [];
  bool _ownedOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _Status.loading);
    try {
      final w = await widget.source.load();
      if (!mounted) return;
      setState(() {
        _words = w;
        _status = _Status.ready;
      });
    } on OfflineException {
      if (mounted) setState(() => _status = _Status.offline);
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = widget.reduceEffects || MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Signature Words'),
        actions: [
          IconButton(key: const Key('sig-help'), tooltip: 'Help', icon: const Icon(Icons.help_outline), onPressed: () => _help(context)),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: NAppBackdrop(child: SafeArea(child: _body(reduce))),
    );
  }

  Widget _body(bool reduce) {
    switch (_status) {
      case _Status.loading:
        return const Center(child: CircularProgressIndicator(key: Key('sig-loading'), color: NTokens.gold));
      case _Status.error:
        return _Message(key: const Key('sig-error'), icon: Icons.error_outline, text: 'Something went wrong loading Signature Words.', action: 'Try again', onTap: _load);
      case _Status.offline:
        return _Message(key: const Key('sig-offline'), icon: Icons.wifi_off_rounded, text: "You're offline. Connect to see the latest drops.", action: 'Retry', onTap: _load);
      case _Status.ready:
        break;
    }
    final list = _ownedOnly ? _words.where((w) => w.owned).toList() : _words;
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _Hero(reduce: reduce)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(key: const Key('sig-all'), label: const Text('All'), selected: !_ownedOnly, onSelected: (_) => setState(() => _ownedOnly = false)),
            ChoiceChip(key: const Key('sig-owned'), label: const Text('My collection'), selected: _ownedOnly, onSelected: (_) => setState(() => _ownedOnly = true)),
          ]),
        ),
      ),
      if (list.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: _Message(
            key: const Key('sig-empty'),
            icon: Icons.auto_awesome,
            text: _ownedOnly ? 'No signature words yet. Collect your first rare word.' : 'No signature words right now. New drops are coming.',
            action: _ownedOnly ? 'Browse all' : 'Refresh',
            onTap: _ownedOnly ? () => setState(() => _ownedOnly = false) : _load,
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          sliver: SliverList.separated(
            itemCount: list.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (c, i) => i == 0
                ? const Padding(
                    padding: EdgeInsets.only(left: 4, top: 4),
                    child: Text('SIGNATURE WORDS', style: TextStyle(color: NTokens.mint, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w800)),
                  )
                : SignatureCard(word: list[i - 1], index: _words.indexOf(list[i - 1]), onTap: () => _open(list[i - 1], reduce)),
          ),
        ),
    ]);
  }

  void _open(SignatureWord w, bool reduce) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: NGlass(
          accent: kitRarity(w.rarity).color,
          blur: 16,
          child: Container(
            key: const Key('sig-detail'),
                        padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircleImage(image: NCircles.at(_words.indexOf(w)), size: 110, ring: kitRarity(w.rarity).color),
              const SizedBox(height: 8),
              Text(w.locked ? 'Locked drop' : w.word, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('${w.rarity.label} · ${w.sound}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 6),
              TextButton.icon(
                key: const Key('sig-rarity-info'),
                onPressed: () => _rarityInfo(context),
                icon: const Icon(Icons.info_outline, size: 16, color: Colors.white54),
                label: const Text('What does rarity mean?', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              const SizedBox(height: 10),
              if (w.locked)
                const Text('This word unlocks at its drop date.', style: TextStyle(color: NTokens.gold))
              else if (w.owned)
                const Text('In your collection', style: TextStyle(color: NTokens.gold))
              else ...[
                Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, children: [
                  const NwsbCoinDisc(size: 22),
                  GlassPill(
                    key: const Key('sig-buy'),
                    label: 'Collect for ${w.priceCoins} coins',
                    style: PillStyle.white,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ]),
                const SizedBox(height: 6),
                const Text('Coins are taken from your balance after you confirm.', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ])),
          ),
        ),
      ),
    );
  }

  void _rarityInfo(BuildContext context) {
    showGlassPopup<void>(
      context,
      builder: (c) => Column(key: const Key('sig-rarity-dialog'), mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Rarity', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        const Text(
          'Rarity is a label for how special a word is: Common, Rare, Epic or Legendary. '
          'You always pick the exact word you collect and see its fixed price first. There are no random draws.',
          style: TextStyle(color: NTokens.textLo, height: 1.4),
        ),
        const SizedBox(height: 14),
        Align(alignment: Alignment.centerRight, child: GlassPill(label: 'Got it', style: PillStyle.white, dense: true, onTap: () => Navigator.of(c).pop())),
      ]),
    );
  }

  void _help(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(16),
        child: NGlass(
          blur: 16,
          child: Column(key: Key('sig-help-sheet'), mainAxisSize: MainAxisSize.min, children: [
            Text('How it works', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Text('1. Rare words\n2. Your own signature sound\n3. Collect them', style: TextStyle(color: Colors.white70, height: 1.6)),
          ]),
        ),
      ),
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero({required this.reduce});
  final bool reduce;
  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  final _pc = PageController(viewportFraction: 0.86);
  int _i = 0;
  static const _slides = [
    ('Rare words', 'Each Signature word is one of a few special words, chosen for you to keep.', 'lotus'),
    ('Your own signature sound', 'Every word comes with its own calm sound to practise and make yours.', 'singing_bowl'),
    ('Collect them', 'Pick the exact word you want at a fixed price. No random draws.', 'milky_way'),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    final n = (_i + 1) % _slides.length;
    if (widget.reduce) {
      _pc.jumpToPage(n);
    } else {
      _pc.animateToPage(n, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 400,
        child: PageView.builder(
          key: const Key('sig-hero'),
          controller: _pc,
          itemCount: _slides.length,
          onPageChanged: (i) => setState(() => _i = i),
          itemBuilder: (c, i) {
            final s = _slides[i];
            return Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: MeditationCard(
                title: s.$1,
                subtitle: s.$2,
                image: NCircles.of(s.$3),
                secondary: 'Skip',
                cta: 'Next',
                onCta: _next,
                dots: _slides.length,
                dotIndex: i,
              )),
            );
          },
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.icon, required this.text, required this.action, required this.onTap});
  final IconData icon;
  final String text;
  final String action;
  final FutureOr<void> Function() onTap;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: NTokens.gold, size: 44),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onTap, child: Text(action)),
          ]),
        ),
      );
}
