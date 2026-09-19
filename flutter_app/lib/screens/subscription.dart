import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../media/nwsb_video.dart';
import '../media/video_pool.dart';
import '../theme/tokens.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool yearly = false;
  int selected = 0;
  late final PageController planController;

  @override
  void initState() {
    super.initState();
    planController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    planController.dispose();
    super.dispose();
  }

  static const plans = <_Plan>[
    _Plan(
      name: 'Free',
      detail: 'NowssB Edition',
      monthly: 'Free',
      yearly: 'Free',
      cta: 'Start free trial',
      front: 'assets/subscription/tier-blazer-front.png',
      back: 'assets/subscription/tier-blazer-back.png',
      features: [
        '30-day free trial',
        'Daily word discovery',
        'Essential meanings',
        'Try every frequency',
      ],
    ),
    _Plan(
      name: 'Resonance',
      detail: 'A deeper daily practice',
      monthly: r'$4.99',
      yearly: r'$41.90',
      cta: 'Subscribe monthly',
      front: 'assets/subscription/tier-sun-front.png',
      back: 'assets/subscription/tier-sun-back.png',
      features: [
        'Unlimited word practice',
        'Resonance sound sessions',
        'Pronunciation scoring',
        'Personal practice history',
        'Pause or cancel anytime',
      ],
    ),
    _Plan(
      name: 'Frequency',
      detail: 'Every word and frequency',
      monthly: r'$9.99',
      yearly: r'$83.90',
      cta: 'Subscribe monthly',
      front: 'assets/subscription/tier-bag-front.png',
      back: 'assets/subscription/tier-bag-back.png',
      features: [
        'Everything in Resonance',
        'Full frequency library',
        'Custom healing routines',
        'Advanced word meanings',
        'Priority support',
      ],
    ),
    _Plan(
      name: 'Frequency X',
      detail: 'The complete NowssB experience',
      monthly: r'$19.99',
      yearly: r'$167.90',
      cta: 'Get inquiry',
      front: 'assets/subscription/tier-nile-front.png',
      back: 'assets/subscription/tier-nile-back.png',
      features: [
        'Everything in Frequency',
        'Priority Personal Coach',
        'Exclusive signature words',
        'Complete NowssB access',
        '1:1 monthly session',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF05070C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: NwsbVideo(
                asset: 'assets/video/subscription-join-nowssb.mp4',
                poster: 'assets/video/subscription-join-nowssb-poster.webp',
                priority: ClipPriority.feature,
                fit: BoxFit.cover,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xE005070C),
                      Color(0xB305070C),
                      Color(0xF205070C),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 28),
                      children: [
                        _headline(),
                        _billing(),
                        const SizedBox(height: 18),
                        _carousel(),
                        const SizedBox(height: 14),
                        _dots(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            const Text(
              'Subscription',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
      );

  Widget _headline() => const Padding(
        padding: EdgeInsets.fromLTRB(22, 8, 22, 16),
        child: Column(
          children: [
            _PricingPill(),
            SizedBox(height: 14),
            Text(
              'Simple plans, straight to your growth.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.6,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Subscription for your daily practice. Custom when you need more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      );

  Widget _billing() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: Row(children: [
            _billingButton('Monthly', false),
            _billingButton('Yearly · Save 30%', true),
          ]),
        ),
      );

  Widget _billingButton(String label, bool value) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => yearly = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: yearly == value ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: yearly == value ? NwsbColors.deep : Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );

  Widget _carousel() => SizedBox(
        height: 438,
        child: PageView.builder(
          controller: planController,
          itemCount: plans.length,
          onPageChanged: (i) => setState(() => selected = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _TierCard(
              plan: plans[i],
              yearly: yearly,
              active: selected == i,
            ),
          ),
        ),
      );

  Widget _dots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < plans.length; i++)
            GestureDetector(
              onTap: () => planController.animateToPage(
                i,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: i == selected ? 8 : 7,
                height: i == selected ? 8 : 7,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == selected
                      ? Colors.white
                      : const Color(0x4DFFFFFF),
                ),
              ),
            ),
        ],
      );
}

class _Plan {
  const _Plan({
    required this.name,
    required this.detail,
    required this.monthly,
    required this.yearly,
    required this.cta,
    required this.front,
    required this.back,
    required this.features,
  });

  final String name, detail, monthly, yearly, cta, front, back;
  final List<String> features;
}

class _PricingPill extends StatelessWidget {
  const _PricingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: const Text(
        'Pricing',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.plan,
    required this.yearly,
    required this.active,
  });

  final _Plan plan;
  final bool yearly;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final price = yearly ? plan.yearly : plan.monthly;
    final unit = plan.monthly == 'Free'
        ? ''
        : (yearly ? ' / year' : ' / month');
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x2EFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? const Color(0x99FFFFFF) : const Color(0x40FFFFFF),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: _FlipPhoto(
                    front: plan.front,
                    back: plan.back,
                    title: plan.name,
                    price: '$price$unit',
                    active: active,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 12,
                  child: _Included(
                    features: plan.features,
                    cta: plan.cta,
                    inverted: plan.name == 'Frequency X',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Included extends StatelessWidget {
  const _Included({
    required this.features,
    required this.cta,
    required this.inverted,
  });

  final List<String> features;
  final String cta;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            "What's Included",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final f in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.check_circle, size: 14, color: Color(0xFFE23D3D)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    f,
                    style: const TextStyle(
                      color: Color(0xF2FFFFFF),
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            decoration: BoxDecoration(
              color: inverted ? Colors.white : const Color(0xFF111111),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    cta,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: inverted ? NwsbColors.deep : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: inverted ? NwsbColors.deep : Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlipPhoto extends StatefulWidget {
  const _FlipPhoto({
    required this.front,
    required this.back,
    required this.title,
    required this.price,
    required this.active,
  });

  final String front, back, title, price;
  final bool active;

  @override
  State<_FlipPhoto> createState() => _FlipPhotoState();
}

class _FlipPhotoState extends State<_FlipPhoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _auto;
  bool _back = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    if (widget.active) _schedule();
  }

  @override
  void didUpdateWidget(covariant _FlipPhoto old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _schedule();
    if (!widget.active && old.active && _back) _flip();
  }

  void _schedule() {
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
        builder: (_, __) {
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
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xCC000000),
                ],
                stops: [0, 0.52, 1],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
