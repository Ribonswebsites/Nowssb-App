/// Rebuilt Signature Words page (spec 14 "Signature Words", 19).
/// Behind flag `newui_signature`; see signature_flag.dart.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'mandala_painter.dart';
import 'signature_models.dart';
import 'signature_widgets.dart';

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
      backgroundColor: const Color(0xFF120B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Signature Words'),
        actions: [
          IconButton(key: const Key('sig-help'), tooltip: 'Help', icon: const Icon(Icons.help_outline), onPressed: () => _help(context)),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF241A5C), Color(0xFF120B2E), Color(0xFF0A0720)],
          ),
        ),
        child: SafeArea(child: _body(reduce)),
      ),
    );
  }

  Widget _body(bool reduce) {
    switch (_status) {
      case _Status.loading:
        return const Center(child: CircularProgressIndicator(key: Key('sig-loading'), color: kGold));
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
          child: Row(children: [
            ChoiceChip(key: const Key('sig-all'), label: const Text('All'), selected: !_ownedOnly, onSelected: (_) => setState(() => _ownedOnly = false)),
            const SizedBox(width: 8),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 3 / 4.6),
            delegate: SliverChildBuilderDelegate(
              (c, i) => SignatureCard(word: list[i], onTap: () => _open(list[i])),
              childCount: list.length,
            ),
          ),
        ),
    ]);
  }

  void _open(SignatureWord w) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: SigGlass(
          glow: rarityGlow(w.rarity),
          child: Container(
            key: const Key('sig-detail'),
            color: Colors.black.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(w.locked ? 'Locked drop' : w.word, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('${w.rarity.label} · ${w.sound}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              if (w.locked)
                const Text('This word unlocks at its drop date.', style: TextStyle(color: kGold))
              else if (w.owned)
                const Text('In your collection', style: TextStyle(color: kGold))
              else ...[
                FilledButton(
                  key: const Key('sig-buy'),
                  style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Collect for ${w.priceCoins} coins'),
                ),
                const SizedBox(height: 6),
                const Text('Coins are taken from your balance after you confirm.', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  void _help(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(16),
        child: SigGlass(
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

class _Hero extends StatelessWidget {
  const _Hero({required this.reduce});
  final bool reduce;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SigGlass(
          glow: kGold,
          child: Row(children: [
            MandalaLoop(size: 96, animate: !reduce),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Signature Words', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Rare words, each with its own sound. Collect them.', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
          ]),
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
            Icon(icon, color: kGold, size: 44),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onTap, child: Text(action)),
          ]),
        ),
      );
}
