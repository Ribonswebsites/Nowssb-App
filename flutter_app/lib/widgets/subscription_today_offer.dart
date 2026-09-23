/// Four Today's-offer cards, one subscription tier each.
///
/// Free is free. Resonance, Frequency and Frequency X are 50% off.
/// Each card has its own wrapper and the row auto-rotates.
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
  const SubscriptionTodayOffer({super.key, this.onClaim});

  final VoidCallback? onClaim;

  @override
  State<SubscriptionTodayOffer> createState() => _SubscriptionTodayOfferState();
}

class _SubscriptionTodayOfferState extends State<SubscriptionTodayOffer> {
  late final PageController _pager;
  late final List<ScrollController> _rails;
  Timer? _auto;
  var _page = 0;
  var _userPaging = false;

  @override
  void initState() {
    super.initState();
    _pager = PageController(viewportFraction: 0.9);
    _rails = List.generate(_tiers.length, (_) => ScrollController());
    if (_flutterTest) return;
    _auto = Timer.periodic(const Duration(milliseconds: 4800), (_) {
      if (!mounted || _userPaging) return;
      if (!TickerMode.of(context)) return;
      if (!_pager.hasClients) return;
      final next = (_page + 1) % _tiers.length;
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
    for (final c in _rails) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _userPaging = true;
          } else if (n is ScrollEndNotification) {
            _userPaging = false;
          }
          return false;
        },
        child: PageView.builder(
          controller: _pager,
          itemCount: _tiers.length,
          onPageChanged: (i) => _page = i,
          itemBuilder: (context, i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: _shell(i, _card(_tiers[i], _rails[i])),
            );
          },
        ),
      ),
    );
  }

  Widget _shell(int i, Widget child) {
    switch (i) {
      case 0:
        return GlassWrap(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: child,
        );
      case 1:
        return NeuCard(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          radius: 22,
          color: const Color(0xFFF4F1EA),
          child: child,
        );
      case 2:
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          decoration: BoxDecoration(
            color: const Color(0xF2141018),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8D5A3), width: 1.4),
          ),
          child: child,
        );
      default:
        return GlassWrap(
          margin: EdgeInsets.zero,
          radius: 28,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: child,
        );
    }
  }

  Widget _card(_Tier tier, ScrollController rail) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14121A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const AppThinkingLoader(
                    size: 40,
                    state: OrbState.composing,
                    blackCircle: false,
                  ),
                  const SizedBox(width: 8),
                  Container(
                      width: 1, height: 36, color: const Color(0x33FFFFFF)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's offer",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE8D5A3),
                          ),
                        ),
                        Text(
                          tier.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tier.detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xB3FFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScrollProgressRail(controller: rail),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ListView(
                      controller: rail,
                      primary: false,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(right: 4, bottom: 8),
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: tier.badge == 'Free'
                                    ? const Color(0xFF7E57C2)
                                    : const Color(0xFFE8D5A3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tier.badge,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: tier.badge == 'Free'
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (tier.was.isNotEmpty)
                              Text(
                                tier.was,
                                style: const TextStyle(
                                  fontSize: 12,
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
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final line in tier.benefits)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              line,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xE6FFFFFF),
                                height: 1.25,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.onClaim,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0B12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Today's offer",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE8D5A3),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8D5A3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tier.cta,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
