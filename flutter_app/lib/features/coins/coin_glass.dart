/// Shared black-glass pieces for the Free coins, Coinback and Multiplier
/// pages. Every number shown comes from the economy summary; nothing here
/// grants or computes a reward.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../economy/economy_api.dart';
import '../programs/program_kit.dart';

/// Loads the server summary once (or uses [preset] in tests) and builds.
class CoinSummaryScaffold extends StatefulWidget {
  const CoinSummaryScaffold({super.key, required this.title, required this.builder, this.preset, this.info, this.accent = NwsbColors.goldLight});
  final String title;
  final Color accent;
  final String? info;
  final Map<String, dynamic>? preset;
  final List<Widget> Function(BuildContext context, Map<String, dynamic> s) builder;

  @override
  State<CoinSummaryScaffold> createState() => _CoinSummaryScaffoldState();
}

class _CoinSummaryScaffoldState extends State<CoinSummaryScaffold> {
  Map<String, dynamic>? _s;
  Object? _err;

  @override
  void initState() {
    super.initState();
    if (widget.preset != null) {
      _s = widget.preset;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final s = await EconomyApi.summary();
      if (mounted) setState(() => _s = s);
    } catch (e) {
      if (mounted) setState(() => _err = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Stack(fit: StackFit.expand, children: [
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [NwsbColors.deep, NwsbColors.plate]))),
      const DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x55000000), Color(0x99000000), Color(0xDD000000)]))),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: NwsbColors.goldLight,
          title: Text(widget.title, style: const TextStyle(fontSize: 16, letterSpacing: 1.2, fontWeight: FontWeight.w500)),
          actions: [
            if (widget.info != null)
              IconButton(
                tooltip: 'About',
                icon: const Icon(Icons.info_outline_rounded, size: 20),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: NwsbColors.plate,
                  builder: (_) =>
                      Padding(padding: const EdgeInsets.fromLTRB(24, 28, 24, 40), child: Text(widget.info!, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 13, height: 1.5))),
                ),
              ),
          ],
        ),
        body: s == null
            ? Center(
                child: _err == null
                    ? const CircularProgressIndicator(color: NwsbColors.gold, strokeWidth: 2)
                    : Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('Couldn\u2019t connect', textAlign: TextAlign.center, style: TextStyle(color: NwsbColors.mist)),
                          const SizedBox(height: 14),
                          TextButton(
                              onPressed: () {
                                setState(() => _err = null);
                                _load();
                              },
                              child: const Text('Try again', style: TextStyle(color: NwsbColors.gold))),
                        ]),
                      ),
              )
            : RefreshIndicator(
                color: NwsbColors.gold,
                onRefresh: widget.preset != null ? () async {} : _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                  children: widget.builder(context, s),
                ),
              ),
      ),
    ]);
  }
}

/// Dark glass hero holding the page's one big number.
class GlassHero extends StatelessWidget {
  const GlassHero({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: const Color(0x66000000),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: child,
          ),
        ),
      );
}

/// Coloured image promo card: short title + value left, render right.
class PromoCard extends StatelessWidget {
  const PromoCard({super.key, required this.image, required this.title, required this.value, this.onTap});
  final VoidCallback? onTap;
  final String image;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 150,
          margin: const EdgeInsets.only(top: 18),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.white.withValues(alpha: 0.06), border: Border.all(color: NwsbColors.gold.withValues(alpha: 0.30))),
          child: Row(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(title, maxLines: 2, style: const TextStyle(color: NwsbColors.goldLight, fontSize: 18, fontWeight: FontWeight.w600, height: 1.15)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: NwsbColors.gold)),
                    child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
            SizedBox(width: 150, child: Image.asset(image, fit: BoxFit.cover, alignment: const Alignment(0, -0.6))),
          ]),
        ),
      );
}

/// Small spaced caps label above a section.
class GlassEyebrow extends StatelessWidget {
  const GlassEyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 40, bottom: 14, left: 4),
        child: Text(text.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, letterSpacing: 2.4)),
      );
}

/// A title-only black tile with a gold value on the right.
class OfferStrip extends StatelessWidget {
  const OfferStrip({super.key, required this.title, required this.value, this.dim = false, this.accent = NwsbColors.goldLight, this.onTap});
  final VoidCallback? onTap;
  final Color accent;
  final String title;
  final String value;
  final bool dim;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: dim ? 0.45 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0x8C000000),
              border: Border.all(color: Colors.white.withValues(alpha: dim ? 0.06 : 0.12)),
            ),
            child: Row(children: [
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE6E6E6), fontSize: 15))),
              const SizedBox(width: 12),
              Text(value, style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w600)),
              if (onTap != null) ...[const SizedBox(width: 8), Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white.withValues(alpha: 0.55))],
            ]),
          ),
        ),
      );
}

String coinNum(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// Re-export for pages.
Map<String, dynamic> cMap(Object? v) => sMap(v);
