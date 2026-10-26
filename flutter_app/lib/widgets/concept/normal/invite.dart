/// Invite a friend — "Tear-off ticket": a perforated ticket; the stub is the
/// friend's actual reward (or your code once you have one). A light sheen
/// runs along the perforation; the stub never peels.
///
/// Data: [wordPct], [wordFirstN], [subscriptionPct] come from the server
/// config `config.reference.friendDiscount` (functions/_lib/economy/config.js:
/// wordPct 10, wordFirstN 3, subscriptionPct 20) read on the phone through
/// `EconomyMirror.instance.summary['config']['reference']['friendDiscount']`.
/// [code] is the signed-in user's referral code (runtime, null hides it).
library;

import 'package:flutter/material.dart';
import 'surface.dart';

class NInvite extends StatefulWidget {
  const NInvite({super.key, required this.onInvite, required this.wordPct, required this.wordFirstN,
      required this.subscriptionPct, this.code});
  final VoidCallback onInvite;
  /// Null while the config has not loaded; the line that needs it is hidden.
  final int? wordPct, wordFirstN, subscriptionPct;
  final String? code;
  @override
  State<NInvite> createState() => _NInviteState();
}

class _NInviteState extends State<NInvite> with SingleTickerProviderStateMixin, NormalLoop {
  @override
  Duration get period => const Duration(milliseconds: 4200);
  @override
  Widget build(BuildContext context) {
    final sp = widget.subscriptionPct, wp = widget.wordPct, wn = widget.wordFirstN;
    final parts = [if (sp != null) '$sp% off a first plan', if (wp != null && wn != null) '$wp% off $wn words'];
    final offer = parts.isEmpty ? null : 'Friends get ${parts.join(' and ')}.';
    final copy = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Invite a friend', style: nHello),
      const Text('They save. You earn.', style: nTitle),
      const SizedBox(height: 6),
      if (offer != null) Text(offer, style: nSub),
      const SizedBox(height: 10),
      const Text('Share your link  →', style: nLinkStyle),
    ]);
    final stub = Column(mainAxisSize: MainAxisSize.min, children: [
      if (sp != null) Text('$sp%', style: nTitle.copyWith(color: const Color(0xFF7A4A12))),
      if (sp != null) Text('off a plan', textAlign: TextAlign.center, style: nSub.copyWith(color: const Color(0xFF6B4A1E))),
      if (widget.code != null) ...[
        const SizedBox(height: 6),
        Text(widget.code!, style: nSub.copyWith(color: nInk, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      ],
    ]);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: NPress(label: 'Invite a friend', onTap: widget.onInvite, child: LayoutBuilder(builder: (c, k) {
        final narrow = k.maxWidth / MediaQuery.textScalerOf(c).scale(1) < 330;
        const stubSize = 96.0;
        return AnimatedBuilder(animation: loop, builder: (_, __) => ClipPath(
          clipper: _Ticket(stub: stubSize, vertical: !narrow),
          child: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white, nBase])),
            child: narrow
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Padding(padding: const EdgeInsets.all(18), child: copy),
                    CustomPaint(size: const Size(double.infinity, 2), painter: _Perf(t: loop.value, vertical: false)),
                    Container(color: const Color(0xFFF7EEDC), padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const NLottie('assets/home/nm-anim-gift.json', size: 44), const SizedBox(width: 10), stub])),
                  ])
                : IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: Padding(padding: const EdgeInsets.all(18), child: copy)),
                    CustomPaint(size: const Size(2, double.infinity), painter: _Perf(t: loop.value, vertical: true)),
                    Container(width: stubSize, color: const Color(0xFFF7EEDC), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const NLottie('assets/home/nm-anim-gift.json', size: 48), stub])),
                  ])),
          ),
        ));
      })),
    );
  }
}

/// Ticket outline with two half-moon notches at the perforation.
class _Ticket extends CustomClipper<Path> {
  _Ticket({required this.stub, required this.vertical});
  final double stub;
  final bool vertical;
  @override
  Path getClip(Size s) {
    final p = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(22)));
    final notches = Path();
    if (vertical) {
      final x = s.width - stub - 1;
      notches..addOval(Rect.fromCircle(center: Offset(x, 0), radius: 10))..addOval(Rect.fromCircle(center: Offset(x, s.height), radius: 10));
    }
    return Path.combine(PathOperation.difference, p, notches);
  }
  @override
  bool shouldReclip(_Ticket o) => o.vertical != vertical;
}

/// Perforation dots; a soft light travels along them.
class _Perf extends CustomPainter {
  _Perf({required this.t, required this.vertical});
  final double t;
  final bool vertical;
  @override
  void paint(Canvas c, Size s) {
    final len = vertical ? s.height : s.width;
    for (var d = 12.0; d < len - 8; d += 9) {
      final f = (d / len - t).abs();
      final lit = (1 - (f * 6).clamp(0.0, 1.0));
      c.drawCircle(vertical ? Offset(1, d) : Offset(d, 1), 1.6 + lit,
          Paint()..color = Color.lerp(const Color(0xFFB8BDCB), nGold, lit)!);
    }
  }
  @override
  bool shouldRepaint(_Perf o) => o.t != t;
}
