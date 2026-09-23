/// Subscription Today's offer.
///
/// Card 1 is the two black banners with the four tiers and a progress line
/// between them. Cards 2–5 are one tier each, with no progress line.
/// Fashion uses glass only. Normal uses neumorphism only.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import 'app_thinking_loader.dart';
import 'glass_wrap.dart';
import 'neumorphic.dart';
import 'scroll_progress_rail.dart';

const _flutterTest = bool.fromEnvironment('FLUTTER_TEST');

class _Tier {
  const _Tier({
    required this.name,
    required this.detail,
    required this.badge,
    required this.now,
    required this.was,
    required this.cta,
    required this.benefits,
  });

  final String name;
  final String detail;
  final String badge;
  final String now;
  final String was;
  final String cta;
  final List<String> benefits;
}

const _tiers = <_Tier>[
  _Tier(
    name: 'Free',
    detail: 'The first tier. No card to start.',
    badge: 'Free',
    now: '30 days free',
    was: '',
    cta: 'Start free',
    benefits: [
      '30-day free trial',
      'Daily word discovery',
      'Essential meanings',
      'Try every frequency',
    ],
  ),
  _Tier(
    name: 'Resonance',
    detail: 'A deeper daily practice.',
    badge: '50% off',
    now: r'$2.49 / month',
    was: r'$4.99',
    cta: 'Claim 50% off',
    benefits: [
      'Unlimited word practice',
      'Resonance sound sessions',
      'Pronunciation scoring',
      'Personal practice history',
    ],
  ),
  _Tier(
    name: 'Frequency',
    detail: 'Every word and frequency.',
    badge: '50% off',
    now: r'$4.99 / month',
    was: r'$9.99',
    cta: 'Claim 50% off',
    benefits: [
      'Everything in Resonance',
      'Full frequency library',
      'Custom healing routines',
      'Advanced word meanings',
    ],
  ),
  _Tier(
    name: 'Frequency X',
    detail: 'The complete NowssB experience.',
    badge: '50% off',
    now: r'$9.99 / month',
    was: r'$19.99',
    cta: 'Claim 50% off',
    benefits: [
      'Everything in Frequency',
      'Priority Personal Coach',
      'Exclusive signature words',
      'Complete NowssB access',
    ],
  ),
];

class SubscriptionTodayOffer extends StatefulWidget {
  const SubscriptionTodayOffer({
    super.key,
    this.onClaim,
    this.neumorphic = false,
  });

  final VoidCallback? onClaim;

  /// Normal home only. Fashion must stay glass — never a white neu shadow.
  final bool neumorphic;

  @override
  State<SubscriptionTodayOffer> createState() => _SubscriptionTodayOfferState();
}

class _SubscriptionTodayOfferState extends State<SubscriptionTodayOffer> {
  late final PageController _pager;
  late final ScrollController _rail;
  Timer? _auto;
  var _page = 0;
  var _userPaging = false;

  @override
  void initState() {
    super.initState();
    _pager = PageController(viewportFraction: 0.92);
    _rail = ScrollController();
    if (_flutterTest) return;
    _auto = Timer.periodic(const Duration(milliseconds: 4800), (_) {
      if (!mounted || _userPaging) return;
      if (!TickerMode.of(context)) return;
      if (!_pager.hasClients) return;
      final next = (_page + 1) % 5;
      _pager.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pager.dispose();
    _rail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 540,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _userPaging = true;
          } else if (n is ScrollEndNotification) {
            _userPaging = false;
          }
          return false;
        },
        child: PageView(
          controller: _pager,
          onPageChanged: (i) => _page = i,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: _shell(0, _overview()),
            ),
            for (var i = 0; i < _tiers.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: _shell(i + 1, _tierCard(_tiers[i])),
              ),
          ],
        ),
      ),
    );
  }

  /// Same home language on every card. Radius and elevation change so the
  /// wrappers are not copies of each other.
  Widget _shell(int i, Widget child) {
    if (widget.neumorphic) {
      return NeuCard(
        padding: const EdgeInsets.all(8),
        radius: 16 + (i % 3) * 4,
        elevation: i.isEven ? NwsbElevation.md : NwsbElevation.sm,
        child: child,
      );
    }
    return GlassWrap(
      margin: EdgeInsets.zero,
      radius: i.isEven ? 18 : 26,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: child,
    );
  }

  Widget _overview() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14121A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _head(
              title: "Today's offer",
              sub: 'First tier free. Every other tier is 50% off.',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScrollProgressRail(controller: _rail),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListView(
                      controller: _rail,
                      primary: false,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        for (final tier in _tiers) _tierLine(tier),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _foot("try 30 day's Free trials today"),
          ],
        ),
      ),
    );
  }

  Widget _tierCard(_Tier tier) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14121A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _head(title: "Today's offer", sub: tier.detail, name: tier.name),
            const SizedBox(height: 10),
            Row(
              children: [
                _badge(tier),
                const SizedBox(width: 8),
                if (tier.was.isNotEmpty)
                  Text(
                    tier.was,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0x88FFFFFF),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Color(0x88FFFFFF),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tier.now,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                primary: false,
                physics: const ClampingScrollPhysics(),
                children: [
                  for (final line in tier.benefits)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xE6FFFFFF),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _foot(tier.cta),
          ],
        ),
      ),
    );
  }

  Widget _tierLine(_Tier tier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tier.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _badge(tier),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            tier.was.isEmpty ? tier.now : '${tier.now}  ·  was ${tier.was}',
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            tier.detail,
            style: const TextStyle(color: Color(0x88FFFFFF), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _badge(_Tier tier) {
    final free = tier.badge == 'Free';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: free ? const Color(0xFF7E57C2) : const Color(0xFFE8D5A3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tier.badge,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: free ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _head({required String title, required String sub, String? name}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const AppThinkingLoader(
            size: 36,
            state: OrbState.composing,
            blackCircle: true,
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 36, color: const Color(0x33FFFFFF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE8D5A3),
                  ),
                ),
                if (name != null)
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                Text(
                  sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xB3FFFFFF),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _foot(String label) {
    return GestureDetector(
      onTap: widget.onClaim,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const AppThinkingLoader(
              size: 28,
              state: OrbState.composing,
              blackCircle: true,
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 22, color: const Color(0x33FFFFFF)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE8D5A3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
