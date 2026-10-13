/// Rebuilt Partner hub (spec Part C "Partner Program", motif 5), behind
/// `newui_partner`. Page-local glass widgets; swap to Bug Hunter's kit later.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/economy/money.dart';
import '../../features/programs/partner_program.dart';
import 'partner_models.dart';
import 'payout_provider.dart';

class PartnerHomePage extends StatefulWidget {
  const PartnerHomePage(
      {super.key, this.repository = const MirrorPartnerRepository(), this.countryCode, this.onOpenEarnings});

  final PartnerRepository repository;

  /// Overrides the device region (tests, admin preview).
  final String? countryCode;
  final VoidCallback? onOpenEarnings;

  @override
  State<PartnerHomePage> createState() => _PartnerHomePageState();
}

class _PartnerHomePageState extends State<PartnerHomePage> {
  late Future<PartnerData> _future = widget.repository.load();

  void _retry() => setState(() {
        _future = widget.repository.load();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140F2B),
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white, title: const Text('Partner')),
      body: Stack(children: [
        const Positioned.fill(child: _CalmBackdrop()),
        FutureBuilder<PartnerData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(key: Key('partner-loading')));
            }
            if (snap.hasError) {
              final offline = snap.error is PartnerOfflineException;
              return _Message(
                key: Key(offline ? 'partner-offline' : 'partner-error'),
                title: offline ? 'You are offline' : 'Something went wrong',
                body: offline
                    ? 'Your partner progress will appear when you reconnect.'
                    : 'We could not load your partner progress.',
                action: 'Try again',
                onTap: _retry,
              );
            }
            final d = snap.data!;
            return _Hub(data: d, countryCode: widget.countryCode, onOpenEarnings: widget.onOpenEarnings);
          },
        ),
      ]),
    );
  }
}

class _Hub extends StatelessWidget {
  const _Hub({required this.data, this.countryCode, this.onOpenEarnings});
  final PartnerData data;
  final String? countryCode;
  final VoidCallback? onOpenEarnings;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final cc = countryCode ?? locale.countryCode ?? 'US';
    final payout = payoutInfoFor(cc);
    final localeTag = '${locale.languageCode}_$cc';
    return ListView(
      key: const Key('partner-hub'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _Glass(
          child: Row(children: [
            const SizedBox(width: 96, height: 96, child: _OrbitRings()),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.tier, style: const TextStyle(color: Color(0xFFD9CCFF), fontWeight: FontWeight.w600)),
                Text('${data.points}',
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                const Text('partner points', style: TextStyle(color: Colors.white70)),
                if (data.toNextTier > 0)
                  Text('${data.toNextTier} more subscriptions to the next level',
                      style: const TextStyle(color: Colors.white70)),
              ]),
            ),
          ]),
        ),
        if (data.isEmpty) ...[
          const SizedBox(height: 12),
          const _Glass(
            key: Key('partner-empty'),
            child: Text('Pick a target, share your link, and points appear here when friends complete paid purchases.',
                style: TextStyle(color: Colors.white)),
          ),
        ],
        const _Head('Pick a target'),
        for (final t in data.targets) _TargetCard(t),
        const _Head('Perks'),
        const _Glass(
            child: Text('Coins · gifts · coupons · early access. Perks have no cash value.',
                style: TextStyle(color: Colors.white))),
        const _Head('Share your link'),
        _Glass(
          child: Row(children: [
            Expanded(
              child: Text(data.referralLink.isEmpty ? 'Your link is being prepared' : data.referralLink,
                  style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
            ),
            TextButton(
              key: const Key('partner-copy'),
              onPressed: data.referralLink.isEmpty
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: data.referralLink));
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Link copied')));
                    },
              child: const Text('Copy'),
            ),
          ]),
        ),
        if (data.buyerDiscountUsdCents > 0) ...[
          const SizedBox(height: 12),
          _Glass(
            key: const Key('partner-discount'),
            child: Text(
              'Buyers through your link get ${FxBook.instance.formatCents(data.buyerDiscountUsdCents, locale: localeTag)} off',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        const _Head('Leaderboard'),
        if (data.leaders.isEmpty)
          const _Glass(
              child: Text('The leaderboard opens once partners start earning points.',
                  style: TextStyle(color: Colors.white70)))
        else
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.leaders.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _Glass(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('#${i + 1} ${data.leaders[i].name}', style: const TextStyle(color: Colors.white)),
                  Text('${data.leaders[i].points} pts', style: const TextStyle(color: Color(0xFFD9CCFF))),
                ]),
              ),
            ),
          ),
        const _Head('Cash earnings'),
        _Glass(
          key: const Key('partner-payout'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Partner perks are not cash. Cash commissions from Earn are paid out in your local currency through '
              '${payout.provider.label}, which runs the identity and tax checks for your country (${payout.countryCode}).',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 6),
            for (final c in payout.checks) Text('• $c', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (onOpenEarnings != null) TextButton(onPressed: onOpenEarnings, child: const Text('Open Earnings')),
          ]),
        ),
        const SizedBox(height: 12),
        const Text(kPartnerDisclaimer, style: TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard(this.t);
  final PartnerTarget t;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _Glass(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${t.goal} ${t.label.toLowerCase()}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                  value: t.progress, minHeight: 6, color: const Color(0xFFB79CFF), backgroundColor: Colors.white12),
            ),
            const SizedBox(height: 4),
            Text('${t.done} / ${t.goal} · ${t.reward}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
      );
}

class _Head extends StatelessWidget {
  const _Head(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
      );
}

/// Page-local glass card; swap for the kit's GlassWrapper (14.2) when it lands.
class _Glass extends StatelessWidget {
  const _Glass({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: child,
      );
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.title, required this.body, required this.action, required this.onTap});
  final String title, body, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _Glass(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              TextButton(onPressed: onTap, child: Text(action)),
            ]),
          ),
        ),
      );
}

class _CalmBackdrop extends StatelessWidget {
  const _CalmBackdrop();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
              center: Alignment(-0.6, -0.8), radius: 1.4, colors: [Color(0xFF3B2A78), Color(0xFF140F2B)]),
        ),
      );
}

/// Motif 5: two interlocking glass rings around a small sun. Procedural,
/// no bundled assets. Respects reduced-motion.
class _OrbitRings extends StatefulWidget {
  const _OrbitRings();
  @override
  State<_OrbitRings> createState() => _OrbitRingsState();
}

class _OrbitRingsState extends State<_OrbitRings> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 14));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
      child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _RingsPainter(_c.value))));
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2.6;
    canvas.drawCircle(
        c,
        r * 0.28,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0xFFFFE9A8), Color(0x00FFC86B)])
              .createShader(Rect.fromCircle(center: c, radius: r * 0.5)));
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xCCD9CCFF);
    for (final phase in [0.0, math.pi / 2]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(t * 2 * math.pi + phase);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 0.9), ring);
      final a = t * 4 * math.pi + phase;
      canvas.drawCircle(Offset(math.cos(a) * r, math.sin(a) * r * 0.45), 2.5, Paint()..color = Colors.white);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t;
}
