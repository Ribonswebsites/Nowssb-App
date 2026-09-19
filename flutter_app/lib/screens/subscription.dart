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
      monthly: '30 days free',
      yearly: '30 days free',
      accent: Color(0xFFF1F1F4),
      front: 'assets/subscription/tier-blazer-front.png',
      back: 'assets/subscription/tier-blazer-back.png',
      benefits: [
        '30-day free trial',
        'Daily word discovery',
        'Essential meanings',
        'Try every frequency',
      ],
    ),
    _Plan(
      name: 'Resonance',
      detail: 'A deeper daily practice',
      monthly: r'$4.99 / month',
      yearly: r'$41.90 / year',
      accent: NwsbColors.mist,
      front: 'assets/subscription/tier-sun-front.png',
      back: 'assets/subscription/tier-sun-back.png',
      benefits: [
        'Unlimited word practice',
        'Resonance sound sessions',
        'Pronunciation scoring',
        'Personal practice history',
      ],
    ),
    _Plan(
      name: 'Frequency',
      detail: 'Every word and frequency',
      monthly: r'$9.99 / month',
      yearly: r'$83.90 / year',
      accent: NwsbColors.goldLight,
      front: 'assets/subscription/tier-bag-front.png',
      back: 'assets/subscription/tier-bag-back.png',
      benefits: [
        'Everything in Resonance',
        'Full frequency library',
        'Custom healing routines',
        'Advanced word meanings',
      ],
    ),
    _Plan(
      name: 'Frequency X',
      detail: 'The complete NowssB experience',
      monthly: r'$19.99 / month',
      yearly: r'$167.90 / year',
      accent: Color(0xFFF1F1F4),
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

  void _subscribe(_Plan plan) {
    // Same no-op hook the page already used — IAP is wired here later.
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
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
                      Color(0xB0060C18),
                      Color(0x66060C18),
                      Color(0xF0060C18),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: CustomScrollView(slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                  title: const Text('Subscription',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  centerTitle: true,
                ),
                SliverToBoxAdapter(child: _videoBanner()),
                SliverToBoxAdapter(child: _billing()),
                SliverToBoxAdapter(child: _horizontalPlans()),
              ]),
            ),
          ],
        ),
      );

  Widget _videoBanner() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: const AspectRatio(
            aspectRatio: 16 / 9,
            child: NwsbVideo(
              asset: 'assets/video/subscription-banner.mp4',
              poster: 'assets/video/subscription-banner-poster.webp',
              priority: ClipPriority.feature,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );

  Widget _billing() => Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: const Color(0xFF151D2B),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white12)),
          child: Row(children: [
            _billingButton('Monthly', false),
            _billingButton('Yearly · Save 30%', true)
          ])));

  Widget _billingButton(String label, bool value) => Expanded(
      child: GestureDetector(
          onTap: () => setState(() => yearly = value),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: yearly == value
                      ? NwsbColors.goldLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999)),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: yearly == value ? NwsbColors.deep : Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)))));

  Widget _horizontalPlans() => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 20, 18, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose your frequency',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          SizedBox(
            height: 438,
            child: PageView.builder(
              controller: planController,
              itemCount: plans.length,
              onPageChanged: (i) => setState(() => selected = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
                child: _TierCard(
                  plan: plans[i],
                  yearly: yearly,
                  active: selected == i,
                  onSubscribe: () => _subscribe(plans[i]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
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
          ),
          const SizedBox(height: 28),
        ],
      );
}

class _Plan {
  const _Plan({
    required this.name,
    required this.detail,
    required this.monthly,
    required this.yearly,
    required this.accent,
    required this.front,
    required this.back,
    required this.benefits,
  });

  final String name, detail, monthly, yearly, front, back;
  final Color accent;
  final List<String> benefits;
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.plan,
    required this.yearly,
    required this.active,
    required this.onSubscribe,
  });

  final _Plan plan;
  final bool yearly;
  final bool active;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x2EFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? plan.accent.withValues(alpha: 0.7)
                  : const Color(0x40FFFFFF),
            ),
            boxShadow: [
              BoxShadow(
                color: plan.accent.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              const BoxShadow(
                color: Color(0x33FFFFFF),
                blurRadius: 8,
                spreadRadius: -4,
                offset: Offset(0, 1),
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
                    price: yearly ? plan.yearly : plan.monthly,
                    active: active,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 12,
                  child: _Included(
                    plan: plan,
                    onSubscribe: onSubscribe,
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
  const _Included({required this.plan, required this.onSubscribe});

  final _Plan plan;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final cta = plan.name == 'Free'
        ? 'Start your 30-day free trial'
        : 'Subscribe to ${plan.name}';
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
        for (final f in plan.benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.check_circle, size: 14, color: plan.accent),
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: plan.accent,
              foregroundColor: NwsbColors.deep,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    cta,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 15),
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
                    fontSize: 16,
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
