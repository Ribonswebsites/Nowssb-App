/// NowssB Edition — "Frequency tuner": the three real plans are stations on
/// a tuning band; a needle drifts to the plan you are looking at and the
/// Join button names that plan and its Google Play price.
///
/// Data:
/// * Plans are the real Play subscriptions (data/billing_config.dart
///   kPlayPlans): Resonance, Frequency, Frequency X (tier keys resonance /
///   frequency / frequencyX).
/// * [prices] — tier key → Play's monthly price string (₹ for Indian
///   buyers), wired as
///   `{for (p in NEdition.plans) p.$1: PlaySubscriptions.instance.priceFor(playPlanFor(p.$1, yearly: false)!.productId)}`
///   (ProductDetails.price). Nothing in the repo sets a price.
/// * [playAvailable] — `PlaySubscriptions.instance.available`: null while
///   Play is being checked / products load (a loading shimmer is shown),
///   false when Play is unreachable (then, and only then, "Price on Google
///   Play"). Rebuild on the PlaySubscriptions ChangeNotifier.
/// * [currentTier] — the user's active tier key (PlaySubscriptions owned), or
///   null when they have no plan; never a hard-coded label.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'surface.dart';

class NEdition extends StatefulWidget {
  const NEdition({super.key, required this.onJoin, required this.prices, required this.playAvailable, this.currentTier, this.initial = 'frequency'});
  final void Function(String tier) onJoin;
  final Map<String, String?> prices;
  final bool? playAvailable;
  final String? currentTier;
  final String initial;
  static const plans = [('resonance', 'Resonance'), ('frequency', 'Frequency'), ('frequencyX', 'Frequency X')];
  @override
  State<NEdition> createState() => _NEditionState();
}

class _NEditionState extends State<NEdition> with SingleTickerProviderStateMixin, NormalLoop {
  late String _sel = widget.initial;
  @override
  Duration get period => const Duration(seconds: 4);
  @override
  Widget build(BuildContext context) {
    final idx = NEdition.plans.indexWhere((p) => p.$1 == _sel);
    final name = NEdition.plans[idx].$2;
    final price = widget.prices[_sel];
    final cur = widget.currentTier;
    final curName = cur == null ? null : NEdition.plans.firstWhere((p) => p.$1 == cur, orElse: () => (cur, cur)).$2;
    return Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 10), child: Container(
      decoration: neu(r: 28), padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(curName == null ? 'Tune your plan' : 'You are on $curName', style: nHello),
        const Text('NowssB Edition', style: nTitle),
        const SizedBox(height: 14),
        // tuning band. Tab labels stay at full size (B012): when the widest
        // one does not fit a third of the band, the tabs stack instead.
        LayoutBuilder(builder: (c, k) {
          final ts = MediaQuery.textScalerOf(c);
          final bold = DefaultTextStyle.of(c).style.merge(nSub.copyWith(fontWeight: FontWeight.w800));
          final widest = NEdition.plans.map((p) => (TextPainter(text: TextSpan(text: p.$2, style: bold),
              textDirection: TextDirection.ltr, textScaler: ts)..layout()).width).reduce(math.max);
          final inner = k.maxWidth - 20;
          final stacked = widest + 12 > inner / 3;
          Widget tab((String, String) p) => Semantics(button: true, selected: p.$1 == _sel, label: p.$2,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(() => _sel = p.$1),
                child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 44), child: Container(
                  alignment: Alignment.center,
                  decoration: stacked && p.$1 == _sel ? neu(r: 14) : null,
                  child: Text(p.$2, textAlign: TextAlign.center, style: nSub.copyWith(
                      color: p.$1 == _sel ? nInk : nSubInk, fontWeight: p.$1 == _sel ? FontWeight.w800 : FontWeight.w400))))));
          return Container(decoration: neu(r: 20, pressed: true), padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(height: 54, child: AnimatedBuilder(animation: loop, builder: (_, __) => Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _Band(t: loop.value))),
                if (!stacked)
                  AnimatedPositioned(duration: const Duration(milliseconds: 420), curve: Curves.easeOutBack,
                    left: (inner / 3) * (idx + .5) - 1.5, top: 0, bottom: 0, width: 3,
                    child: Container(decoration: BoxDecoration(color: const Color(0xFFE0553A), borderRadius: BorderRadius.circular(2)))),
              ]))),
              if (stacked)
                for (final p in NEdition.plans) tab(p)
              else
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final p in NEdition.plans) Expanded(child: tab(p))]),
            ]));
        }),
        const SizedBox(height: 10),
        // The user's own plan: no price above Manage.
        if (cur == _sel)
          const SizedBox.shrink()
        // non-breaking spaces keep "Google Play" / "/ month" together at 320
        else if (price != null)
          Text('$name · $price\u00A0/\u00A0month', key: const ValueKey('edition-price'), style: nSub.copyWith(color: nInk, fontWeight: FontWeight.w700))
        else if (widget.playAvailable == false)
          Text('$name · Price\u00A0on\u00A0Google\u00A0Play', style: nSub)
        else
          // price still loading: no '·' until it arrives
          Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(name, style: nSub),
            AnimatedBuilder(animation: loop, builder: (_, __) => Container(width: 74, height: 12,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: LinearGradient(
                begin: Alignment(-1 + 3 * loop.value - 1, 0), end: Alignment(3 * loop.value - 1, 0),
                colors: const [Color(0xFFDCE0EA), Color(0xFFF4F5F9), Color(0xFFDCE0EA)])))),
          ]),
        const SizedBox(height: 12),
        // the real Join control
        Semantics(button: true, label: 'Join $name', child: Material(color: nInk, borderRadius: BorderRadius.circular(16),
          child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => widget.onJoin(_sel),
            child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 48, minWidth: double.infinity),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Center(child: Text(cur == _sel ? 'Manage $name' : 'Join $name', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)))))))),
      ]),
    ));
  }
}

/// Radio-dial tick marks with a slow signal shimmer.
class _Band extends CustomPainter {
  _Band({required this.t});
  final double t;
  @override
  void paint(Canvas c, Size s) {
    final h = s.height - 4;
    for (var x = 0.0; x <= s.width; x += 6) {
      final major = (x / 6).round() % 5 == 0;
      final f = ((x / s.width) - t).abs();
      final lit = (1 - (f * 5).clamp(0.0, 1.0));
      c.drawLine(Offset(x, h), Offset(x, h - (major ? 26 : 14) - lit * 10),
          Paint()..strokeWidth = major ? 1.6 : 1..color = Color.lerp(const Color(0xFFA9AFBF), nLink, lit)!);
    }
  }
  @override
  bool shouldRepaint(_Band o) => o.t != t;
}
