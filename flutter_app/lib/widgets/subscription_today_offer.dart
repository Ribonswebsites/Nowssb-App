/// Subscription Today's offer.
///
/// Card 1 is the two black banners with the four tiers and a progress line
/// between them. Cards 2–5 are one tier each, with no progress line.
/// Fashion uses glass only. Normal uses neumorphism only.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_thinking_orbs/flutter_thinking_orbs.dart';

import 'app_thinking_loader.dart';
import 'glass_wrap.dart';
import 'neumorphic.dart';
import '../admin/template/editable.dart';
import '../data/billing_config.dart';
import '../data/play_subscriptions.dart';

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
    required this.front,
    required this.back,
  });

  final String name;
  final String detail;
  final String badge;
  final String now;
  final String was;
  final String cta;
  final List<String> benefits;
  final String front;
  final String back;
}

/// A bundled tier with today's real Google Play price (and Play's own
/// offer, when this account is eligible). Nothing is invented: with no
/// Play price yet the card says so.
_Tier _live(_Tier t) {
  final tier = tierForPlanName(t.name);
  if (tier == null) return t;
  final plan = playPlanFor(tier, yearly: false);
  if (plan == null) return t;
  final base = PlaySubscriptions.instance.priceFor(plan.productId);
  final offer = PlaySubscriptions.instance.offerFor(plan.productId);
  return _Tier(
    name: t.name,
    detail: t.detail,
    badge: offer != null ? 'Play offer' : t.badge,
    now: offer != null ? '$offer first' : (base != null ? '$base / month' : t.now),
    was: offer != null && base != null ? '$base / month' : '',
    cta: offer != null ? 'Claim the Play offer' : t.cta,
    benefits: t.benefits,
    front: t.front,
    back: t.back,
  );
}

const _tiers = <_Tier>[
  _Tier(
    name: 'Free',
    detail: 'The first tier. No card to start.',
    badge: 'Free',
    now: '30 days free',
    was: '',
    cta: 'Start free',
    front: 'assets/subscription/tier-blazer-front.png',
    back: 'assets/subscription/tier-blazer-back.png',
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
    badge: 'Monthly',
    now: 'Google Play price',
    was: '',
    cta: 'See the plan',
    front: 'assets/subscription/tier-sun-front.png',
    back: 'assets/subscription/tier-sun-back.png',
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
    badge: 'Monthly',
    now: 'Google Play price',
    was: '',
    cta: 'See the plan',
    front: 'assets/subscription/tier-bag-front.png',
    back: 'assets/subscription/tier-bag-back.png',
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
    badge: 'Monthly',
    now: 'Google Play price',
    was: '',
    cta: 'See the plan',
    front: 'assets/subscription/tier-nile-front.png',
    back: 'assets/subscription/tier-nile-back.png',
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
  Timer? _auto;
  var _page = 0;
  var _userPaging = false;

  @override
  void initState() {
    super.initState();
    _pager = PageController(viewportFraction: 0.92);
    if (_flutterTest) return;
    unawaited(PlaySubscriptions.instance.start());
    _auto = Timer.periodic(const Duration(milliseconds: 4800), (_) {
      if (!mounted || _userPaging) return;
      if (!TickerMode.of(context)) return;
      if (!_pager.hasClients) return;
      final next = (_page + 1) % 6;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: PlaySubscriptions.instance,
        builder: (context, _) => _build(context),
      );

  Widget _build(BuildContext context) {
    final tiers = [for (final t in _tiers) _live(t)];
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
          physics: const ClampingScrollPhysics(),
          onPageChanged: (i) {
            if (_page == i) return;
            setState(() => _page = i);
          },
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: _shell(0, _intro()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: _shell(1, _overview()),
            ),
            for (var i = 0; i < tiers.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: _shell(i + 2, _tierCard(tiers[i], i + 2)),
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

  Widget _intro() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EditableLabel('subscription_today_offer.SubscriptionTodayOffer',
              'Subscription',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.02,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const EditableLabel('subscription_today_offer.SubscriptionTodayOffer',
              'First tier free. Every other tier is half off today.',
              style: TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: ClipRect(
                child: EditableImage.asset(
                  'assets/banners/point-subscribe.jpg',
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.bottomRight,
                  width: double.infinity,
                  height: double.infinity,
                  slot: 'subscription_today_offer.SubscriptionTodayOffer',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: EditableLabel('subscription_today_offer.SubscriptionTodayOffer',
                    'Join today',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClaim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const EditableLabel('subscription_today_offer.SubscriptionTodayOffer',
                      'Subscribe',
                      style: TextStyle(
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _overview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 136,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EditableLabel('subscription_today_offer.SubscriptionTodayOffer',
                        'NowssB',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 6),
                      EditableLabel('subscription_today_offer.SubscriptionTodayOffer',
                        'Subscription',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 124,
                height: 136,
                child: EditableImage.asset(
                  'assets/subscription/sub-hero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  slot: 'subscription_today_offer.SubscriptionTodayOffer',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _tiers.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Expanded(child: _tierBox(_live(_tiers[i]))),
        ],
      ],
    );
  }

  Widget _tierBox(_Tier tier) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tier.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tier.was.isEmpty ? tier.now : '${tier.now}  ·  was ${tier.was}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
          _badge(tier),
        ],
      ),
    );
  }

  Widget _tierCard(_Tier tier, int page) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF14121A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 74),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 11,
                      child: _OfferFlip(
                        front: tier.front,
                        back: tier.back,
                        title: tier.name,
                        price: tier.now,
                        active: _page == page,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 13,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _badge(tier),
                              const SizedBox(width: 8),
                              if (tier.was.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    tier.was,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0x88FFFFFF),
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Color(0x88FFFFFF),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tier.now,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            // Fits the card: no inner scroll to trap a thumb.
                            child: SingleChildScrollView(
                              primary: false,
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final line in tier.benefits)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Text(
                                      line,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xE6FFFFFF),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            ),
                          ),
                          _foot(tier.cta),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _head(title: "Today's offer", sub: tier.detail),
                ],
              ),
            ),
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
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
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
                EditableLabel('subscription_today_offer.SubscriptionTodayOffer',
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
                EditableLabel('subscription_today_offer.SubscriptionTodayOffer',
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
              child: EditableLabel('subscription_today_offer.SubscriptionTodayOffer',
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

/// Same left-side flip the subscription plan cards use. Offer price is the
/// discounted line, not the full plan price.
class _OfferFlip extends StatefulWidget {
  const _OfferFlip({
    required this.front,
    required this.back,
    required this.title,
    required this.price,
    required this.active,
  });

  final String front;
  final String back;
  final String title;
  final String price;
  final bool active;

  @override
  State<_OfferFlip> createState() => _OfferFlipState();
}

class _OfferFlipState extends State<_OfferFlip> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _auto;
  var _back = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
    if (widget.active) _schedule();
  }

  @override
  void didUpdateWidget(covariant _OfferFlip old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _schedule();
    if (!widget.active && old.active && _back) _flip();
  }

  void _schedule() {
    if (_flutterTest) return;
    _auto?.cancel();
    _auto = Timer(const Duration(milliseconds: 700), () {
      if (mounted && widget.active && !_back) _flip();
    });
  }

  void _flip() {
    if (_back) {
      _c.reverse();
    } else {
      _c.forward();
    }
    _back = !_back;
  }

  @override
  void dispose() {
    _auto?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          final ang = t * math.pi;
          final showBack = t > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateY(ang),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _face(widget.back),
                  )
                : _face(widget.front),
          );
        },
      ),
    );
  }

  Widget _face(String asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          EditableImage.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
            slot: 'subscription_today_offer.OfferFlip',
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xB3000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xCC000000),
                ],
                stops: [0, 0.28, 0.55, 1],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 8,
            top: 28,
            child: EditableLabel('subscription_today_offer.OfferFlip',
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.05,
                shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 10,
            child: Text(
              widget.price,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
